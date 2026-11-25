-- Velvet Hoof: run this entire file in Supabase SQL Editor.
-- This creates public products, private customer orders, admin access and public product-image storage.

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_vh_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_vh_admin() from public;
grant execute on function public.is_vh_admin() to authenticated;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  category text not null default 'Accessories',
  price_iqd numeric(12,2) not null default 0 check (price_iqd >= 0),
  image_url text not null default '',
  sizes text[] not null default '{}',
  colors text[] not null default '{}',
  stock integer not null default 0 check (stock >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number bigint generated always as identity unique,
  customer_name text not null,
  phone text not null,
  country text not null,
  address text not null,
  notes text not null default '',
  items jsonb not null,
  subtotal_iqd numeric(12,2) not null check (subtotal_iqd >= 0),
  payment_method text not null default 'Cash on delivery' check (payment_method = 'Cash on delivery'),
  status text not null default 'New' check (status in ('New','Confirmed','Preparing','Shipped','Delivered','Cancelled')),
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;

grant select on public.products to anon, authenticated;
grant insert, update, delete on public.products to authenticated;
grant insert on public.orders to anon, authenticated;
grant select, update on public.orders to authenticated;

drop policy if exists "Admins can view own admin record" on public.admin_users;
create policy "Admins can view own admin record"
on public.admin_users for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Anyone can view active products" on public.products;
create policy "Anyone can view active products"
on public.products for select to anon, authenticated
using (active = true or (select public.is_vh_admin()));

drop policy if exists "Admins can insert products" on public.products;
create policy "Admins can insert products"
on public.products for insert to authenticated
with check ((select public.is_vh_admin()));

drop policy if exists "Admins can update products" on public.products;
create policy "Admins can update products"
on public.products for update to authenticated
using ((select public.is_vh_admin()))
with check ((select public.is_vh_admin()));

drop policy if exists "Admins can delete products" on public.products;
create policy "Admins can delete products"
on public.products for delete to authenticated
using ((select public.is_vh_admin()));

drop policy if exists "Customers can submit COD orders" on public.orders;
create policy "Customers can submit COD orders"
on public.orders for insert to anon, authenticated
with check (
  payment_method = 'Cash on delivery'
  and length(trim(customer_name)) between 2 and 120
  and length(trim(phone)) between 5 and 40
  and length(trim(country)) between 2 and 80
  and length(trim(address)) between 5 and 1000
  and jsonb_typeof(items) = 'array'
  and jsonb_array_length(items) > 0
);

drop policy if exists "Admins can view orders" on public.orders;
create policy "Admins can view orders"
on public.orders for select to authenticated
using ((select public.is_vh_admin()));

drop policy if exists "Admins can update orders" on public.orders;
create policy "Admins can update orders"
on public.orders for update to authenticated
using ((select public.is_vh_admin()))
with check ((select public.is_vh_admin()));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('velvet-hoof-products', 'velvet-hoof-products', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880, allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "Product images are public" on storage.objects;
create policy "Product images are public"
on storage.objects for select
using (bucket_id = 'velvet-hoof-products');

drop policy if exists "Admins upload product images" on storage.objects;
create policy "Admins upload product images"
on storage.objects for insert to authenticated
with check (bucket_id = 'velvet-hoof-products' and (select public.is_vh_admin()));

drop policy if exists "Admins update product images" on storage.objects;
create policy "Admins update product images"
on storage.objects for update to authenticated
using (bucket_id = 'velvet-hoof-products' and (select public.is_vh_admin()))
with check (bucket_id = 'velvet-hoof-products' and (select public.is_vh_admin()));

drop policy if exists "Admins delete product images" on storage.objects;
create policy "Admins delete product images"
on storage.objects for delete to authenticated
using (bucket_id = 'velvet-hoof-products' and (select public.is_vh_admin()));
