-- Apply after 001_initial.sql. The bucket is publicly readable for published salon photos;
-- uploading, overwriting and removing files is restricted to authenticated administrators.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('site-media', 'site-media', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=excluded.public, file_size_limit=excluded.file_size_limit, allowed_mime_types=excluded.allowed_mime_types;

create policy "EL BEM media public read" on storage.objects
for select to anon, authenticated using (bucket_id='site-media');
create policy "EL BEM admin uploads" on storage.objects
for insert to authenticated with check (bucket_id='site-media' and public.is_elbem_admin());
create policy "EL BEM admin changes" on storage.objects
for update to authenticated using (bucket_id='site-media' and public.is_elbem_admin()) with check (bucket_id='site-media' and public.is_elbem_admin());
create policy "EL BEM admin deletes" on storage.objects
for delete to authenticated using (bucket_id='site-media' and public.is_elbem_admin());
