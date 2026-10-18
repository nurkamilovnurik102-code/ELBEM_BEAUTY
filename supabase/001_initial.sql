-- EL BEM BEAUTY 2.0 - initial clean-project schema. Apply ONLY to a new, empty Supabase project.
-- DO NOT apply blindly to the old EL BEM database.
create extension if not exists pgcrypto;
create table if not exists public.services(id text primary key,name text not null,category text not null,price numeric not null check(price>=0),duration int not null check(duration>0),image text,description text,active boolean not null default true);
create table if not exists public.masters(id text primary key,name text not null,specialty text,image text,"serviceIds" text[] not null default '{}',active boolean not null default true);
create table if not exists public.products(id text primary key,name text not null,category text not null,price numeric not null check(price>=0),image text,description text,active boolean default true,demo boolean default true);
create table if not exists public.bookings(id uuid primary key default gen_random_uuid(),name text not null,phone text not null,date date not null,time text not null,"serviceIds" text[] not null,"masterId" text not null default 'any',total numeric not null,status text not null default 'pending' check(status in ('pending','confirmed','cancelled')),"createdAt" timestamptz not null default now(),note text);
create table if not exists public.orders(id uuid primary key default gen_random_uuid(),name text not null,phone text not null,items jsonb not null default '[]',total numeric not null,date timestamptz not null default now());
create table if not exists public.reviews(id text primary key,name text not null,text text not null,image text);
create table if not exists public.blocked_slots(slot text primary key);
create table if not exists public.site_content(id integer primary key check (id=1),data jsonb not null);
create table if not exists public.admin_users(user_id uuid primary key references auth.users(id) on delete cascade);
-- Row-level security: only public catalog reads; other data restricted to authenticated admins.
do $$ declare t text; begin foreach t in array array['services','masters','products','bookings','orders','reviews','blocked_slots','site_content','admin_users'] loop execute format('alter table public.%I enable row level security',t); end loop; end $$;
create or replace function public.is_elbem_admin() returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from public.admin_users where user_id=auth.uid())$$;
revoke all on function public.is_elbem_admin() from public;
grant execute on function public.is_elbem_admin() to authenticated;
create policy "public services" on public.services for select to anon,authenticated using (true);
create policy "public masters" on public.masters for select to anon,authenticated using (true);
create policy "public products" on public.products for select to anon,authenticated using (true);
create policy "public reviews" on public.reviews for select to anon,authenticated using (true);
create policy "public content" on public.site_content for select to anon,authenticated using (true);
create policy "admin read bookings" on public.bookings for select to authenticated using (public.is_elbem_admin());
create policy "admin write bookings" on public.bookings for all to authenticated using (public.is_elbem_admin()) with check(public.is_elbem_admin());
create policy "admin read orders" on public.orders for select to authenticated using (public.is_elbem_admin());
create policy "admin read blocked" on public.blocked_slots for select to authenticated using (public.is_elbem_admin());
create policy "admin identity" on public.admin_users for select to authenticated using(user_id=auth.uid());
do $$ declare t text; begin foreach t in array array['services','masters','products','reviews','blocked_slots','site_content'] loop execute format('create policy "admin management" on public.%I for all to authenticated using (public.is_elbem_admin()) with check (public.is_elbem_admin())',t); end loop; end $$;
-- DEMONSTRATION ONLY: server validates current prices and current booking conflicts. Real production needs per-master scheduling, slot duration and throttling.
create or replace function public.create_booking(payload jsonb) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_ids text[]; v_price numeric; v_total numeric; v_date date; v_time text; v_name text; v_phone text; v_master text; begin
 v_name=left(trim(coalesce(payload->>'name','')),120);v_phone=left(trim(coalesce(payload->>'phone','')),32);v_date=(payload->>'date')::date;v_time=payload->>'time';v_master=coalesce(payload->>'masterId','any');
 if length(v_name)<2 or length(v_phone)<8 or v_date<current_date or v_time !~ '^([01][0-9]):(00|30)$' then raise exception 'Invalid booking details';end if;
 select array_agg(value::text) into v_ids from jsonb_array_elements_text(payload->'serviceIds');
 if coalesce(cardinality(v_ids),0)=0 or cardinality(v_ids)>6 then raise exception 'Choose services';end if;
 select coalesce(sum(price),0),count(*) into v_total,v_price from public.services where id=any(v_ids) and active=true;
 if v_price<>cardinality(v_ids) then raise exception 'Service not available';end if;
 -- Initial demo-grade conflict checking, serialized per date/master.
 perform pg_advisory_xact_lock(hashtext(v_date::text||v_master));
 if exists(select 1 from public.bookings b where b.date=v_date and b.time=v_time and b.status<>'cancelled' and (b."masterId"=v_master or b."masterId"='any' or v_master='any')) then raise exception 'Selected slot is busy';end if;
 insert into public.bookings(id,name,phone,date,time,"serviceIds","masterId",total,status,note) values(gen_random_uuid(),v_name,v_phone,v_date,v_time,v_ids,v_master,v_total,'pending',left(coalesce(payload->>'note',''),500)) returning id into v_id;return v_id;
end $$;
revoke all on function public.create_booking(jsonb) from public;
grant execute on function public.create_booking(jsonb) to anon,authenticated;
-- Demo checkout stores server-derived amount. Payments are NOT processed.
create or replace function public.create_order(payload jsonb) returns uuid language plpgsql security definer set search_path=public as $$declare i jsonb; sum_price numeric:=0; pr numeric; v_id uuid;begin
if length(coalesce(payload->>'name',''))<2 or length(coalesce(payload->>'phone',''))<8 then raise exception 'Name and phone required';end if;
for i in select * from jsonb_array_elements(payload->'items') loop select price into pr from public.products where id=i->>'id' and active=true;if pr is null or (i->>'quantity')::int<1 or (i->>'quantity')::int>20 then raise exception 'Invalid item';end if;sum_price:=sum_price+pr*(i->>'quantity')::int;end loop;
if sum_price=0 then raise exception 'Empty order';end if;
insert into public.orders(name,phone,items,total) values(left(payload->>'name',120),left(payload->>'phone',32),payload->'items',sum_price) returning id into v_id;return v_id;end $$;
revoke all on function public.create_order(jsonb) from public;
grant execute on function public.create_order(jsonb) to anon,authenticated;
