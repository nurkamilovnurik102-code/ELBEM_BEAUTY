# EL BEM BEAUTY 2.0 — targeted fixes before Supabase

This is the EXISTING project, not a rewrite. No React route was removed and original SQL tables/RLS are retained.

## Changes made

1. Admin mobile navigation: fixed 52px-height, horizontally scrollable navigation at viewport widths <= 670px. Page content no longer enlarges the dark navigation row. Desktop sidebar layout preserved.
2. Demo photo uploader: image files up to 25 MB are stored locally in **IndexedDB** under a stable `elbem-local-image:` reference, not as base64 in localStorage. The site resolves them into browser blob URLs when rendering. Large photos are optionally downscaled for display, preserving their proportions. JPEG/PNG/WebP/GIF/AVIF supported when the browser can decode them. HEIC may need export to JPEG. These files are PRIVATE to the browser/profile/device: they are NOT uploaded to Supabase until the owner adds/replaces them again after connecting the database.
3. Supabase uploader still uses the existing `site-media` bucket and admin RLS. The existing `003_media_audio_realtime.sql` supports GIF/AVIF in addition to earlier JPEG/PNG/WebP and audio; no secrets added. DB-connected admin can upload image files up to 10 MB (subject to bucket limits).
4. Gallery and all catalog/hero/editor image elements use `MediaImage` to display persistent demo image references after browser reload. Existing CSS framing and image fit remain.
5. Checkout defaults to a WhatsApp order message using the number in Admin > Settings; the existing order is recorded as before. Telegram is additionally shown ONLY when Admin > Settings holds a valid `@username` or `https://t.me/username`. With no bot there is no automatic Telegram transmission: a client opens the chat and manually pastes/sends the order. No Telegram phone-number lookup is promised.
6. Admin > Settings has an independent `addressMapUrl` field for a full `http(s)` map link. On Home and Contacts a conditional 'Open map' link appears only when a valid link is configured. Physical address and work hours still work as before.
7. Removed the unwanted partial hero EL BEM seal overlay (only the overlay, no logo in the header removed).
8. Public Supabase catalog loading no longer fetches private booking/order/blocked-slots records. Once admin authorization succeeds, the admin-only refresh loads those tables. Admin reviews do not send the nonexistent `active` DB column.
9. Files missing from the previous targeted ZIP, including the original `supabase/functions` directory, are preserved from the original source ZIP.

## Verification performed here

- TS/TSX **syntax transpile** via global TypeScript: passed for App.tsx, data.ts, store.ts and media.tsx. This is NOT a full typecheck.
- `npm run check:i18n`: passed (222 KY/EN keys).
- CSS parsed with no syntax errors.
- Chromium **CSS-only isolated layout test** at 320, 375, 393, 430 and 670px: nav height 52px regardless of short/long content; horizontal document overflow absent in the tested page scaffold.
- `npm install`: timeout / dependencies unavailable in this environment. Thus **npm run build and complete rendered-app E2E testing were not completed**.
- End-to-end IndexedDB photo upload test was attempted, but browser execution environment blocked IndexedDB for the opaque test origin; it must be tested in the user's localhost environment.
- No live Supabase project, real Telegram/WhatsApp app, iOS device or Vercel deployment was available to test here.

## Five local checks before starting the database

1. Unpack ZIP to a **new** directory (do not merge old and new `src`). Run `npm install`, then `npm run build`, then `npm run dev`.
2. Chrome device emulator: set iPhone size 393x852, visit Admin > Bookings, Schedule, Masters, Settings. Top dark menu must stay exactly one row. Swipe it horizontally for offscreen sections.
3. Admin > Site content: upload a 2–10 MB JPEG from your device; make sure it appears immediately and still appears after a full refresh. Repeat for a service/product/master image and check at 320px and desktop.
4. Admin > Settings: set WhatsApp and a public Telegram `@username`, and a Google Maps / 2GIS URL. Save. Checkout: WhatsApp is primary, Telegram optional. Remove Telegram and confirm that the Telegram checkout button disappears. Home/Contacts 'Open map' must appear only with a valid map link.
5. Change a photo again, verify crop in its card, verify orders and bookings still work in demo. Test owner password/RLS, cross-device persistence and Storage **after** connecting Supabase.

## Known limits

- `object-fit: cover` prevents stretching but may crop edges of unusually shaped portraits. Use photos composed for the destination frame; guaranteeing the entire original photo is visible requires `contain` with borders or a separate crop-position editor.
- Demo image files remain on the same device/browser profile; a browser-data reset erases them. In Supabase mode, newly uploaded media use Storage URLs and are shared across devices. Demo media are NOT migrated automatically.
- The WhatsApp/Telegram confirmation step is performed by the customer. Without a bot Telegram cannot auto-send on a user's behalf.
- Real launch is not approved before npm build, Supabase integration, RLS, scheduling, spam protection, and multiple-device tests.
