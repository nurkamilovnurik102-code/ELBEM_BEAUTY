-- Apply AFTER 001-007 on the clean EL BEM 2.0 project.
-- The owner can provide independent Kyrgyz/English translations of catalog records.
alter table public.services add column if not exists localized jsonb not null default '{}'::jsonb;
alter table public.masters add column if not exists localized jsonb not null default '{}'::jsonb;
alter table public.products add column if not exists localized jsonb not null default '{}'::jsonb;
alter table public.catalog_categories add column if not exists localized jsonb not null default '{}'::jsonb;
alter table public.reviews add column if not exists localized jsonb not null default '{}'::jsonb;
