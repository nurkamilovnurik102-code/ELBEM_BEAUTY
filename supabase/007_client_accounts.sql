-- Client self-service accounts: keep guest booking possible (user_id null).
alter table public.bookings add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.orders add column if not exists user_id uuid references auth.users(id) on delete set null;
create index if not exists bookings_client_idx on public.bookings(user_id);
create index if not exists orders_client_idx on public.orders(user_id);
create policy "client read own bookings" on public.bookings for select to authenticated using(user_id=auth.uid());
create policy "client read own orders" on public.orders for select to authenticated using(user_id=auth.uid());
-- Overrides the prior RPCs, setting user_id from auth.uid() on the server; user input is ignored.
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
 insert into public.bookings(id,name,phone,date,time,"serviceIds","masterId",total,status,note,user_id) values(gen_random_uuid(),v_name,v_phone,v_date,v_time,v_ids,v_assigned,v_total,'pending',left(coalesce(payload->>'note',''),500),auth.uid()) returning id into v_id;
 return v_id;
end $$;
create or replace function public.create_order(payload jsonb) returns uuid language plpgsql security definer set search_path=public as $$declare i jsonb; sum_price numeric:=0; pr numeric; v_id uuid;begin
if length(coalesce(payload->>'name',''))<2 or length(coalesce(payload->>'phone',''))<8 then raise exception 'Name and phone required';end if;
for i in select * from jsonb_array_elements(payload->'items') loop select price into pr from public.products where id=i->>'id' and active=true;if pr is null or (i->>'quantity')::int<1 or (i->>'quantity')::int>20 then raise exception 'Invalid item';end if;sum_price:=sum_price+pr*(i->>'quantity')::int;end loop;
if sum_price=0 then raise exception 'Empty order';end if;
insert into public.orders(name,phone,items,total,user_id) values(left(payload->>'name',120),left(payload->>'phone',32),payload->'items',sum_price,auth.uid()) returning id into v_id;return v_id;end $$;
