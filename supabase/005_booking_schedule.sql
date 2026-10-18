-- EL BEM 2 booking scheduling upgrade; apply after 001 (and preferably after 003).
-- NOTE: review existing bookings and real salon working hours before enabling production.
create table if not exists public.master_hours (
 master_id text not null references public.masters(id) on delete cascade,
 weekday integer not null check(weekday between 0 and 6),
 open_at time not null default '09:00', close_at time not null default '19:00',
 is_open boolean not null default true,
 primary key(master_id,weekday),check(close_at>open_at)
);
alter table public.master_hours enable row level security;
create policy "public schedule read" on public.master_hours for select to anon,authenticated using(true);
create policy "admin schedule management" on public.master_hours for all to authenticated using(public.is_elbem_admin()) with check(public.is_elbem_admin());

-- Time slots use Asia/Bishkek date, master-specific duration, and intervals that overlap.
create or replace function public.available_slots(p_date date,p_service_ids text[],p_master text default 'any')
returns text[] language plpgsql stable security definer set search_path=public as $$
declare v_duration int; v_count int; m record; v_minutes int; v_begin time; v_end time; v_start timestamptz; v_finish timestamptz; v_occupied boolean; v_any boolean; v_slots text[]:=array[]::text[];v_weekday int;
begin
 if p_date is null or p_date < (now() at time zone 'Asia/Bishkek')::date or p_date > ((now() at time zone 'Asia/Bishkek')::date+60) or cardinality(p_service_ids) not between 1 and 6 then return v_slots;end if;
 if p_master not in ('any','onsite') and not exists(select 1 from public.masters where id=p_master and active=true) then return v_slots;end if;
 select count(*),coalesce(sum(duration),0) into v_count,v_duration from public.services where id=any(p_service_ids) and active=true;
 if v_count<>cardinality(p_service_ids) then return v_slots;end if;
 v_weekday=extract(dow from p_date)::int;
 for v_minutes in 18..37 loop -- 09:00 through 18:30, 30-minute steps
  v_begin=(time '00:00'+v_minutes*interval '30 minute')::time;
  v_end=(v_begin+v_duration*interval '1 minute')::time;
  if v_end<=v_begin then continue;end if;
  if p_date=(now() at time zone 'Asia/Bishkek')::date and v_begin <= (now() at time zone 'Asia/Bishkek')::time + interval '30 minute' then continue;end if;
  if exists(select 1 from public.blocked_slots where slot=p_date::text||'|'||to_char(v_begin,'HH24:MI')) then continue;end if;
  v_any=false;
  for m in select a.id,coalesce(h.open_at,time '09:00') open_at,coalesce(h.close_at,time '19:00') close_at,coalesce(h.is_open,true) is_open from public.masters a left join public.master_hours h on h.master_id=a.id and h.weekday=v_weekday where a.active=true and a."serviceIds" @> p_service_ids and (p_master in ('any','onsite') or a.id=p_master) loop
   if not m.is_open or v_begin<m.open_at or v_end>m.close_at then continue;end if;
   if exists(select 1 from public.blocked_slots where slot=m.id||'|'||p_date::text||'|'||to_char(v_begin,'HH24:MI')) then continue;end if;
   if exists(select 1 from public.bookings b where b.date=p_date and b.status<>'cancelled' and (b."masterId"=m.id or b."masterId" in ('any','onsite')) and (v_minutes*30 < (split_part(b.time,':',1)::int*60+split_part(b.time,':',2)::int)+(select coalesce(sum(s.duration),30) from public.services s where s.id=any(b."serviceIds"))) and (v_minutes*30+v_duration > split_part(b.time,':',1)::int*60+split_part(b.time,':',2)::int)) then continue;end if;
   v_any=true;exit;
  end loop;
  if v_any then v_slots:=array_append(v_slots,to_char(v_begin,'HH24:MI'));end if;
 end loop;
 return v_slots;
end $$;
revoke all on function public.available_slots(date,text[],text) from public;
grant execute on function public.available_slots(date,text[],text) to anon,authenticated;

create or replace function public.create_booking(payload jsonb) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;v_ids text[];v_total numeric;v_count int;v_date date;v_time text;v_name text;v_phone text;v_master text;v_assigned text;begin
 v_name=left(trim(coalesce(payload->>'name','')),120);v_phone=left(trim(coalesce(payload->>'phone','')),32);v_date=(payload->>'date')::date;v_time=payload->>'time';v_master=coalesce(payload->>'masterId','any');
 if length(v_name)<2 or length(v_phone)<8 or v_time !~ '^([01][0-9]|2[0-3]):(00|30)$' then raise exception 'Invalid booking details';end if;
 select array_agg(value) into v_ids from jsonb_array_elements_text(payload->'serviceIds');
 if coalesce(cardinality(v_ids),0) not between 1 and 6 then raise exception 'Choose 1-6 services';end if;
 select coalesce(sum(price),0),count(*) into v_total,v_count from public.services where id=any(v_ids) and active=true;
 if v_count<>cardinality(v_ids) then raise exception 'Service unavailable';end if;
 -- Serialize booking writes for the entire day; prevents simultaneous overlapping assignments.
 perform pg_advisory_xact_lock(hashtext('elbem-booking-'||v_date::text));
 if not (v_time=any(public.available_slots(v_date,v_ids,v_master))) then raise exception 'Selected time is unavailable';end if;
 -- Stable deterministic staff assignment. Avoid storing "any" as occupied resource.
 select m.id into v_assigned from public.masters m where m.active=true and m."serviceIds" @> v_ids and (v_master in ('any','onsite') or m.id=v_master)
 and v_time=any(public.available_slots(v_date,v_ids,m.id)) order by m.id limit 1;
 if v_assigned is null then raise exception 'No available master';end if;
 insert into public.bookings(id,name,phone,date,time,"serviceIds","masterId",total,status,note) values(gen_random_uuid(),v_name,v_phone,v_date,v_time,v_ids,v_assigned,v_total,'pending',left(coalesce(payload->>'note',''),500)) returning id into v_id;
 return v_id;
end $$;
revoke all on function public.create_booking(jsonb) from public;
grant execute on function public.create_booking(jsonb) to anon,authenticated;
