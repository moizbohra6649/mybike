# MYBIKE ERP

Multi-showroom bike dealership management & accounting ERP.
Flutter (Material 3) + Supabase (Postgres, Auth, RLS, Storage).

## Run

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

Without `env.json` the app starts on **local demo data** — every service in
`lib/core/services/` falls back to seeded showrooms, customers and inventory
when Supabase is unreachable. Fine for UI work, but nothing is saved.

## Connect Supabase

1. Create a project at [supabase.com](https://supabase.com/dashboard) and copy
   **Project URL** and **anon public key** from *Settings → API*.
2. Apply the schema: run `supabase/migrations/01…18` **in order** in the SQL
   editor (or `supabase db push` with the CLI linked). They create the 44 tables
   and their RLS policies; `02_seed_data.sql` seeds roles and permissions.
3. Create the first login — *Authentication → Users → Add user* in the
   dashboard, or the `supabase/functions/create-user` edge function. The account
   also needs a `public.profiles` row plus `user_roles` / `user_showrooms`
   entries, or it will authenticate and then see nothing.
4. `cp env.example.json env.json` and fill in the two values. `env.json` is
   gitignored.
5. Run with `--dart-define-from-file=env.json`.

Start-up logs say which mode you are in:

| Log | Meaning |
| --- | --- |
| `✅ Supabase connected: https://…` | live; the key was verified with a round-trip |
| `❌ Supabase connection FAILED (…)` | key rejected or migrations missing — app is on demo data |
| `🧪 Supabase NOT connected` | no credentials supplied |

`SUPABASE_URL` and `SUPABASE_ANON_KEY` are enough on their own. Set `MYBIKE_ENV`
to `staging` or `production` to pick a preset; it defaults to `development`.

## App name

`MYBIKE ERP` — defined in `AppVersion.appName` and mirrored in
`AndroidManifest.xml`, `ios/Runner/Info.plist`, `web/manifest.json` and
`web/index.html`. (`02_seed_data.sql` seeds a `settings.app_name = 'MYBIKE'` row
for in-app display.)

## Launcher icon

The mark is authored as vector — brand-yellow "M" on brand black — and mirrored
per platform:

| Platform | Files |
| --- | --- |
| Android 8+ | `res/mipmap-anydpi-v26/ic_launcher{,_round}.xml` + `res/drawable/ic_launcher_foreground.xml` |
| Web | `web/favicon.svg` (used by `manifest.json` and `index.html`) |
| Android ≤ 7, iOS | **raster PNGs, still the Flutter defaults** |

Source of truth is `assets/icons/app_icon.svg`. To refresh the raster sets,
export it at 1024×1024 and run `flutter_launcher_icons` (add it as a
dev-dependency, point `image_path` at the export, and let it write
`mipmap-*` and `AppIcon.appiconset`). Kept out of `pubspec.yaml` because the
adaptive-icon XML above already covers Android without it.
