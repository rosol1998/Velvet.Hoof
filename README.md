# Velvet Hoof

Luxury equestrian storefront for Iraq and international customers. Checkout is **Cash on Delivery only**.

## What's included

- Responsive storefront and shopping bag.
- Supabase-backed catalogue shared across visitors.
- Admin email/password sign-in.
- Admin product create, edit, delete, stock, sizes, colours and image uploads.
- COD order submission to a private database table.
- Admin order inbox and order-status updates.
- GitHub Pages deployment.

## One-time setup (free tiers)

### 1. Create the database

1. Create a free project at https://supabase.com/dashboard.
2. Open **SQL Editor** in your Supabase project.
3. Open this repository's `supabase-setup.sql`, copy all of it, paste it into SQL Editor, and click **Run**.
4. In Supabase, open **Project Settings → API Keys**. Copy the **Project URL** and the **Publishable key** (or legacy anon key).

### 2. Connect the website

1. Open `config.js` in this repository on GitHub.
2. Replace `PASTE_YOUR_SUPABASE_PROJECT_URL_HERE` with your Project URL.
3. Replace `PASTE_YOUR_SUPABASE_PUBLISHABLE_KEY_HERE` with your Publishable key.
4. Commit the change. GitHub Pages will deploy the new version.

The publishable key is intended for browser apps. Never put a Supabase **secret** key or **service_role** key in `config.js`, HTML, or any public repository. The database is protected by Row Level Security policies in the SQL setup.

### 3. Create the store administrator

1. In Supabase, open **Authentication → Users** and click **Add user**.
2. Create the store administrator's email and password. Confirm the user if the dashboard offers that option.
3. Copy that user's UUID from the Users list.
4. Open **SQL Editor** and run this statement, replacing the sample UUID with the user's UUID:

```sql
insert into public.admin_users (user_id)
values ('PASTE-ADMIN-USER-UUID-HERE')
on conflict do nothing;
```

5. Visit the website and click **Admin** in the footer. Sign in with that email and password.

Only user IDs explicitly inserted into `admin_users` have administrator permissions. Do not create a public sign-up form.

## Important operating notes

- Customer checkout creates a COD order request; it does not take online payment.
- Confirm courier availability, shipping cost, delivery time and COD collection manually with each customer before dispatch. International COD is not universally supported.
- The SQL policies allow public visitors to submit orders but do not allow them to read orders. Only authorized admins can view or update orders.
- The image bucket is public so product images can display on the storefront; only authorized admins can upload, change or delete images.
- Before launch, add your real business contact details, shipping/returns policy, privacy notice, and product photography. Test one order and verify it appears in the admin inbox.
- Free-tier quotas and availability are controlled by Supabase and GitHub and may change.

## Public site

https://rosol1998.github.io/Velvet.Hoof/
