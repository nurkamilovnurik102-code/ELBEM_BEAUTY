-- EL BEM 2: run ONLY on fresh EL BEM 2 database after 001 and 002.
-- Expand audio upload limit; storage upload remains restricted to authorized admins.
update storage.buckets set file_size_limit=20971520,allowed_mime_types=array['image/jpeg','image/png','image/webp','image/gif','image/avif','audio/mpeg','audio/wav','audio/x-wav','audio/ogg','audio/mp4','audio/x-m4a'] where id='site-media';
-- Realtime for bookings: subscriptions are still governed by RLS.
do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='bookings') then
   alter publication supabase_realtime add table public.bookings;
 end if;
end $$;
-- Telegram without a bot cannot receive automatic messages from the website.
-- Booking details remain securely in bookings and are manually shared by an admin.
-- No notification queue, email provider or bot tokens are required.
