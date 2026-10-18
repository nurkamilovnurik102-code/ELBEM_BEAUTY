-- Apply to EL BEM 2 after 001. Existing category names can be migrated into this table.
create table if not exists public.catalog_categories(id text primary key,name text not null,kind text not null check(kind in ('service','product')),image text not null default '',active boolean not null default true,sort_order int not null default 0);
alter table public.catalog_categories enable row level security;
create unique index if not exists category_name_kind on public.catalog_categories(kind,lower(name));
create policy "public category reads" on public.catalog_categories for select to anon,authenticated using (active=true);
create policy "admin category writes" on public.catalog_categories for all to authenticated using(public.is_elbem_admin()) with check(public.is_elbem_admin());
insert into public.catalog_categories(id,name,kind,sort_order)
select 'service-'||md5(category),category,'service',row_number() over(order by category) from (select distinct category from public.services) t
on conflict do nothing;
insert into public.catalog_categories(id,name,kind,sort_order)
select 'product-'||md5(category),category,'product',row_number() over(order by category) from (select distinct category from public.products) t
on conflict do nothing;
