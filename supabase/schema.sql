-- FactoryScout initial database schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.manufacturers (
 id text primary key, name text not null, region text not null, category text[] not null default '{}',
 summary text not null default '', capabilities text[] not null default '{}', moq text, lead_time text,
 evidence text not null default 'Supplier-published', evidence_note text not null default '',
 export_markets text[] not null default '{}', status text not null default 'Review required',
 website text, is_published boolean not null default false,
 verification_status text not null default 'unverified' check (verification_status in ('unverified','claim_review','evidence_review','independently_verified')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.enquiries (
 id uuid primary key default gen_random_uuid(), manufacturer_id text not null references public.manufacturers(id),
 name text not null, email text not null, company text not null default '', product text not null,
 quantity text not null default '', details text not null default '',
 status text not null default 'new' check (status in ('new','reviewing','forwarded','closed','spam')),
 created_at timestamptz not null default now()
);
create table if not exists public.supplier_applications (
 id uuid primary key default gen_random_uuid(), company text not null, website text, location text not null,
 products text not null, moq text, lead_time text, evidence text, contact_page text, contact_name text,
 status text not null default 'pending' check (status in ('pending','reviewing','approved','rejected')),
 reviewer_notes text, created_at timestamptz not null default now(), reviewed_at timestamptz
);
create index if not exists enquiries_created_at_idx on public.enquiries(created_at desc);
create index if not exists enquiries_manufacturer_idx on public.enquiries(manufacturer_id);
create index if not exists supplier_applications_created_at_idx on public.supplier_applications(created_at desc);
create index if not exists manufacturers_published_idx on public.manufacturers(is_published,name);
alter table public.manufacturers enable row level security;
alter table public.enquiries enable row level security;
alter table public.supplier_applications enable row level security;
revoke all on public.manufacturers from anon, authenticated;
revoke all on public.enquiries from anon, authenticated;
revoke all on public.supplier_applications from anon, authenticated;
insert into public.manufacturers (id,name,region,category,summary,capabilities,moq,lead_time,evidence,evidence_note,export_markets,status,is_published,verification_status) values
('les-ateliers-bs','Les Ateliers BS','La Soukra, Ariana',array['Premium ready-to-wear','Woven','Denim'],'Tunisian garment workshop with a sample room and capabilities across premium ready-to-wear, woven garments and selected embellishment work.',array['Pattern and sample room','Woven garments','Denim','Pleating','Embroidery'],'100–20,000 pieces (supplier-published range)','Approximately 8 weeks after sample approval (published)','Supplier-published','Capabilities and figures are based on public supplier information; facility, current capacity and commercial terms have not been independently audited.',array['International export'],'Review required',true,'unverified'),
('subli-tunis','SubliTunis','Sousse',array['Sportswear','Swimwear','Workwear'],'Garment and sublimation workshops with stated experience in sportswear, swimwear, workwear and medical clothing.',array['Sublimation printing','Sportswear','Swimwear','Leggings','Workwear'],'Not publicly confirmed','Not publicly confirmed','Supplier-published','Workshop and staffing details are supplier-published. MOQ, sample process, current capacity and certifications require direct confirmation.',array['Export-oriented (supplier-stated)'],'Review required',true,'unverified'),
('goldtex','Goldtex','Bizerte',array['Fashion apparel','Sportswear','Technical apparel'],'Tunisian apparel manufacturer publicly describing fashion, sportswear and technical garment production.',array['Fashion apparel','Sportswear','Technical apparel'],'Not publicly confirmed','Not publicly confirmed','Supplier-published','Production scale and certification claims require documentary review. No independent factory audit has been completed by FactoryScout.',array['Not confirmed'],'Review required',true,'unverified'),
('atll','ATLL','Casablanca, Morocco',array['Streetwear','Hoodies','Apparel'],'Moroccan apparel manufacturer included as a regional comparison option, not a Tunisian factory listing.',array['Hoodies','Embroidery','Garment production'],'200 pieces per model (published)','Not publicly confirmed','Supplier-published','Public website claims require direct confirmation; no independent audit has been completed by FactoryScout.',array['Not confirmed'],'Regional comparison',true,'unverified')
on conflict (id) do nothing;

-- Product catalogue and multi-supplier RFQ marketplace layer.
create table if not exists public.products (
 id uuid primary key default gen_random_uuid(),
 manufacturer_id text not null references public.manufacturers(id) on delete cascade,
 name text not null check (char_length(name) between 2 and 180),
 product_type text not null check (char_length(product_type) between 2 and 120),
 description text not null default '' check (char_length(description) <= 3000),
 materials text[] not null default '{}',
 techniques text[] not null default '{}',
 minimum_order integer check (minimum_order is null or minimum_order > 0),
 sample_available boolean not null default false,
 lead_time_days integer check (lead_time_days is null or lead_time_days between 1 and 730),
 image_url text,
 evidence text not null default 'Supplier-published',
 status text not null default 'pending' check (status in ('pending','published','rejected')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists products_published_type_idx on public.products(status, product_type);
create index if not exists products_manufacturer_idx on public.products(manufacturer_id);

create table if not exists public.rfqs (
 id uuid primary key,
 buyer_name text not null check (char_length(buyer_name) between 2 and 120),
 buyer_email text not null check (char_length(buyer_email) between 5 and 254),
 company text not null default '' check (char_length(company) <= 160),
 product_type text not null check (char_length(product_type) between 2 and 160),
 quantity integer not null check (quantity between 1 and 10000000),
 target_price text not null default '' check (char_length(target_price) <= 120),
 delivery_country text not null check (char_length(delivery_country) between 2 and 100),
 material_specs text not null default '' check (char_length(material_specs) <= 3000),
 sample_required boolean not null default false,
 target_date date,
 status text not null default 'new' check (status in ('new','reviewing','matched','closed','spam')),
 created_at timestamptz not null default now()
);
create index if not exists rfqs_created_at_idx on public.rfqs(created_at desc);

create table if not exists public.rfq_targets (
 rfq_id uuid not null references public.rfqs(id) on delete cascade,
 manufacturer_id text not null references public.manufacturers(id),
 created_at timestamptz not null default now(),
 primary key (rfq_id, manufacturer_id)
);
create index if not exists rfq_targets_manufacturer_idx on public.rfq_targets(manufacturer_id);

alter table public.products enable row level security;
alter table public.rfqs enable row level security;
alter table public.rfq_targets enable row level security;
revoke all on public.products, public.rfqs, public.rfq_targets from anon, authenticated;
grant select on public.products to anon;
-- RFQ inserts are restricted to authenticated buyer accounts via the validated RPC.

drop policy if exists "Public can view published product listings" on public.products;
create policy "Public can view published product listings"
 on public.products for select to anon using (
  status = 'published' and exists (
   select 1 from public.manufacturers m
   where m.id = products.manufacturer_id and m.is_published = true
  )
);
-- No anonymous RFQ or RFQ-target insert policies.


-- Keep an RFQ and all supplier targets in one database transaction.
create or replace function public.submit_rfq(
 p_buyer_name text, p_buyer_email text, p_company text, p_product_type text,
 p_quantity integer, p_target_price text, p_delivery_country text,
 p_material_specs text, p_sample_required boolean, p_target_date date,
 p_manufacturer_ids text[]
) returns void
language plpgsql security invoker set search_path = ''
as $$
declare v_rfq_id uuid; v_target_count integer;
begin
 if p_buyer_name is null or char_length(btrim(p_buyer_name)) not between 2 and 120
   or p_buyer_email is null or char_length(btrim(p_buyer_email)) not between 5 and 254
   or btrim(p_buyer_email) !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$'
   or p_product_type is null or char_length(btrim(p_product_type)) not between 2 and 160
   or p_quantity is null or p_quantity not between 1 and 10000000
   or p_delivery_country is null or char_length(btrim(p_delivery_country)) not between 2 and 100
   or char_length(coalesce(p_company,'')) > 160
   or char_length(coalesce(p_target_price,'')) > 120
   or char_length(coalesce(p_material_specs,'')) > 3000
   or p_sample_required is null
   or coalesce(cardinality(p_manufacturer_ids),0) not between 1 and 5
   or (select count(distinct x) from unnest(p_manufacturer_ids) as x) <> cardinality(p_manufacturer_ids)
 then raise exception 'Invalid RFQ fields'; end if;
 select count(*) into v_target_count from public.manufacturers m
 where m.id = any(p_manufacturer_ids) and m.is_published = true;
 if v_target_count <> cardinality(p_manufacturer_ids) then
   raise exception 'One or more selected suppliers are not published';
 end if;
 insert into public.rfqs (
   id,buyer_name,buyer_email,company,product_type,quantity,target_price,
   delivery_country,material_specs,sample_required,target_date,status
 ) values (
   gen_random_uuid(),btrim(p_buyer_name),btrim(p_buyer_email),btrim(coalesce(p_company,'')),
   btrim(p_product_type),p_quantity,btrim(coalesce(p_target_price,'')),
   btrim(p_delivery_country),btrim(coalesce(p_material_specs,'')),
   p_sample_required,p_target_date,'new'
 ) returning id into v_rfq_id;
 insert into public.rfq_targets(rfq_id,manufacturer_id)
 select v_rfq_id, x from unnest(p_manufacturer_ids) as x;
end;
$$;
revoke all on function public.submit_rfq(text,text,text,text,integer,text,text,text,boolean,date,text[]) from public, anon, authenticated;
revoke insert on public.rfqs, public.rfq_targets from anon;
revoke all on function public.submit_rfq(text,text,text,text,integer,text,text,text,boolean,date,text[]) from public, anon, authenticated;


-- Buyer and supplier accounts. The role column is deliberately not user-editable.
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 email text, full_name text not null default '',
 account_type text not null default 'buyer' check (account_type in ('buyer','supplier')),
 role text not null default 'user' check (role in ('user','admin')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
drop policy if exists "Users can read their own profile" on public.profiles;
create policy "Users can read their own profile" on public.profiles
 for select to authenticated using ((select auth.uid()) = id);

create or replace function public.handle_new_factoryscout_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare requested_type text;
begin
 requested_type := case when new.raw_user_meta_data ->> 'account_type' = 'supplier' then 'supplier' else 'buyer' end;
 insert into public.profiles (id,email,full_name,account_type,role)
 values (new.id,new.email,coalesce(new.raw_user_meta_data ->> 'full_name',''),requested_type,'user')
 on conflict (id) do nothing;
 return new;
end;
$$;
revoke all on function public.handle_new_factoryscout_user() from public, anon, authenticated;
drop trigger if exists on_factoryscout_auth_user_created on auth.users;
create trigger on_factoryscout_auth_user_created after insert on auth.users
 for each row execute function public.handle_new_factoryscout_user();

create table if not exists public.supplier_accounts (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null unique references auth.users(id) on delete cascade,
 manufacturer_id text unique references public.manufacturers(id),
 requested_manufacturer_id text references public.manufacturers(id) on delete set null,
 company_name text not null check (char_length(company_name) between 2 and 180),
 slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) between 2 and 90),
 website text, location text not null check (char_length(location) between 2 and 160),
 about text not null default '' check (char_length(about) <= 3000),
 contact_name text, status text not null default 'pending' check (status in ('pending','approved','rejected')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists supplier_accounts_status_idx on public.supplier_accounts(status);
create unique index if not exists supplier_accounts_one_pending_claim_per_manufacturer on public.supplier_accounts(requested_manufacturer_id) where status='pending' and requested_manufacturer_id is not null;
alter table public.supplier_accounts enable row level security;
revoke all on public.supplier_accounts from anon, authenticated;
grant select on public.supplier_accounts to anon, authenticated;
grant insert (owner_id,company_name,slug,website,location,about,contact_name,requested_manufacturer_id) on public.supplier_accounts to authenticated;
grant update (company_name,slug,website,location,about,contact_name,requested_manufacturer_id) on public.supplier_accounts to authenticated;
drop policy if exists "Supplier owners can read their account" on public.supplier_accounts;
create policy "Supplier owners can read their account" on public.supplier_accounts
 for select to authenticated using ((select auth.uid()) = owner_id);
drop policy if exists "Approved supplier storefronts are public" on public.supplier_accounts;
create policy "Approved supplier storefronts are public" on public.supplier_accounts
 for select to anon, authenticated using (status = 'approved');
drop policy if exists "Users can submit a pending supplier account" on public.supplier_accounts;
create policy "Users can submit a pending supplier account" on public.supplier_accounts
 for insert to authenticated with check ((select auth.uid()) = owner_id and status = 'pending' and manufacturer_id is null and (requested_manufacturer_id is null or (exists(select 1 from public.manufacturers m where m.id=supplier_accounts.requested_manufacturer_id and m.is_published=true) and not exists(select 1 from public.supplier_accounts sa where sa.manufacturer_id=supplier_accounts.requested_manufacturer_id and sa.status='approved'))));
drop policy if exists "Owners can edit pending supplier details" on public.supplier_accounts;
create policy "Owners can edit pending supplier details" on public.supplier_accounts
 for update to authenticated using ((select auth.uid()) = owner_id and status = 'pending')
 with check ((select auth.uid()) = owner_id and status = 'pending' and manufacturer_id is null and (requested_manufacturer_id is null or (exists(select 1 from public.manufacturers m where m.id=supplier_accounts.requested_manufacturer_id and m.is_published=true) and not exists(select 1 from public.supplier_accounts sa where sa.manufacturer_id=supplier_accounts.requested_manufacturer_id and sa.status='approved'))));

alter table public.products add column if not exists owner_id uuid references auth.users(id) on delete cascade;
create index if not exists products_owner_idx on public.products(owner_id);
grant select on public.products to authenticated;
grant insert (manufacturer_id,owner_id,name,product_type,description,materials,techniques,minimum_order,sample_available,lead_time_days,image_url,evidence) on public.products to authenticated;
grant update (name,product_type,description,materials,techniques,minimum_order,sample_available,lead_time_days,image_url,evidence) on public.products to authenticated;
drop policy if exists "Authenticated users can view published product listings" on public.products;
create policy "Authenticated users can view published product listings" on public.products
 for select to authenticated using (status = 'published' or owner_id = (select auth.uid()));
drop policy if exists "Approved suppliers can submit their own products" on public.products;
create policy "Approved suppliers can submit their own products" on public.products
 for insert to authenticated with check (
  owner_id = (select auth.uid()) and status = 'pending' and exists (
   select 1 from public.supplier_accounts sa where sa.owner_id = (select auth.uid())
   and sa.status = 'approved' and sa.manufacturer_id = products.manufacturer_id
  )
 );
drop policy if exists "Suppliers can edit their own pending products" on public.products;
create policy "Suppliers can edit their own pending products" on public.products
 for update to authenticated using (owner_id = (select auth.uid()) and status = 'pending')
 with check (owner_id = (select auth.uid()) and status = 'pending' and exists (
  select 1 from public.supplier_accounts sa where sa.owner_id = (select auth.uid())
  and sa.status = 'approved' and sa.manufacturer_id = products.manufacturer_id
 ));


-- Admin moderation. Promote the first platform owner manually after their account exists:
-- update public.profiles set role = 'admin' where email = 'YOUR_REGISTERED_EMAIL';
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;
create or replace function private.is_factoryscout_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
 select exists (select 1 from public.profiles where id = (select auth.uid()) and role = 'admin');
$$;
revoke all on function private.is_factoryscout_admin() from public, anon;
grant execute on function private.is_factoryscout_admin() to authenticated;

drop policy if exists "Admins can read all profiles" on public.profiles;
create policy "Admins can read all profiles" on public.profiles for select to authenticated
 using ((select private.is_factoryscout_admin()));

grant select, update on public.supplier_accounts to authenticated;
drop policy if exists "Admins can review supplier accounts" on public.supplier_accounts;
create policy "Admins can review supplier accounts" on public.supplier_accounts for all to authenticated
 using ((select private.is_factoryscout_admin())) with check ((select private.is_factoryscout_admin()));

grant select, insert, update on public.manufacturers to authenticated;
drop policy if exists "Admins can manage manufacturers" on public.manufacturers;
create policy "Admins can manage manufacturers" on public.manufacturers for all to authenticated
 using ((select private.is_factoryscout_admin())) with check ((select private.is_factoryscout_admin()));

grant select, update on public.products to authenticated;
drop policy if exists "Admins can moderate all products" on public.products;
create policy "Admins can moderate all products" on public.products for all to authenticated
 using ((select private.is_factoryscout_admin())) with check ((select private.is_factoryscout_admin()));

grant select, update on public.supplier_applications to authenticated;
drop policy if exists "Admins can review supplier applications" on public.supplier_applications;
create policy "Admins can review supplier applications" on public.supplier_applications for all to authenticated
 using ((select private.is_factoryscout_admin())) with check ((select private.is_factoryscout_admin()));

grant select, update on public.rfqs to authenticated;
grant select on public.rfq_targets to authenticated;
drop policy if exists "Admins can review RFQs" on public.rfqs;
create policy "Admins can review RFQs" on public.rfqs for all to authenticated
 using ((select private.is_factoryscout_admin())) with check ((select private.is_factoryscout_admin()));
drop policy if exists "Admins can read RFQ targets" on public.rfq_targets;
create policy "Admins can read RFQ targets" on public.rfq_targets for select to authenticated
 using ((select private.is_factoryscout_admin()));

grant select, update on public.enquiries to authenticated;
drop policy if exists "Admins can review enquiries" on public.enquiries;
create policy "Admins can review enquiries" on public.enquiries for all to authenticated
 using ((select private.is_factoryscout_admin())) with check ((select private.is_factoryscout_admin()));

create or replace function public.admin_approve_supplier_account(p_supplier_account_id uuid)
returns text language plpgsql security invoker set search_path=''
as $$
declare v_supplier public.supplier_accounts%rowtype; v_manufacturer_id text;
begin
 if not private.is_factoryscout_admin() then raise exception 'Not authorized'; end if;
 select * into v_supplier from public.supplier_accounts where id=p_supplier_account_id for update;
 if not found then raise exception 'Supplier account not found'; end if;
 if v_supplier.status<>'pending' then raise exception 'Supplier account is not pending'; end if;
 if v_supplier.requested_manufacturer_id is not null then
   select m.id into v_manufacturer_id from public.manufacturers m
   where m.id=v_supplier.requested_manufacturer_id and m.is_published=true for update;
   if not found then raise exception 'The requested manufacturer profile is no longer available'; end if;
   if exists(select 1 from public.supplier_accounts sa where sa.manufacturer_id=v_manufacturer_id and sa.status='approved') then
     raise exception 'This manufacturer profile already has an approved supplier account';
   end if;
   update public.manufacturers
   set website=coalesce(v_supplier.website,website),
       status='Supplier account approved - claims unverified',
       evidence_note=concat_ws(E'\n',nullif(evidence_note,''),'Supplier account owner approved by FactoryScout. Product claims remain supplier-stated until independently reviewed.'),
       updated_at=now()
   where id=v_manufacturer_id;
   update public.supplier_accounts
   set manufacturer_id=v_manufacturer_id,requested_manufacturer_id=null,status='approved',updated_at=now()
   where id=p_supplier_account_id;
   return v_manufacturer_id;
 end if;
 v_manufacturer_id:=v_supplier.slug;
 if exists(select 1 from public.manufacturers where id=v_manufacturer_id) then
   v_manufacturer_id:=v_manufacturer_id||'-'||left(replace(gen_random_uuid()::text,'-',''),8);
 end if;
 insert into public.manufacturers(id,name,region,category,summary,capabilities,evidence,evidence_note,export_markets,status,website,is_published,verification_status)
 values(v_manufacturer_id,v_supplier.company_name,v_supplier.location,array['Apparel'],coalesce(v_supplier.about,''),
   array[]::text[],'Supplier-submitted',
   'Supplier application reviewed by FactoryScout. Factory capabilities, capacity and certifications have not been independently audited.',
   array[]::text[],'Approved listing - claims unverified',v_supplier.website,true,'unverified');
 update public.supplier_accounts set manufacturer_id=v_manufacturer_id,status='approved',updated_at=now()
 where id=p_supplier_account_id;
 return v_manufacturer_id;
end;
$$;
revoke all on function public.admin_approve_supplier_account(uuid) from public,anon;
grant execute on function public.admin_approve_supplier_account(uuid) to authenticated;

-- Public product image storage. Uploads are restricted to approved supplier accounts
-- and each supplier can write only inside their own user-id folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Anyone can view published product images" on storage.objects;
create policy "Anyone can view published product images"
on storage.objects for select to anon, authenticated
using (bucket_id = 'product-images');

drop policy if exists "Approved suppliers can upload product images" on storage.objects;
create policy "Approved suppliers can upload product images"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.supplier_accounts sa
    where sa.owner_id = (select auth.uid()) and sa.status = 'approved'
  )
);

drop policy if exists "Suppliers can replace their own product images" on storage.objects;
create policy "Suppliers can replace their own product images"
on storage.objects for update to authenticated
using (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.supplier_accounts sa
    where sa.owner_id = (select auth.uid()) and sa.status = 'approved'
  )
);

drop policy if exists "Suppliers can delete their own product images" on storage.objects;
create policy "Suppliers can delete their own product images"
on storage.objects for delete to authenticated
using (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.supplier_accounts sa
    where sa.owner_id = (select auth.uid()) and sa.status = 'approved'
  )
);


-- Buyer saved supplier shortlist. Each authenticated user can manage only their own rows.
create table if not exists public.saved_manufacturers (
  user_id uuid not null references auth.users(id) on delete cascade,
  manufacturer_id text not null references public.manufacturers(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, manufacturer_id)
);
alter table public.saved_manufacturers enable row level security;
grant select, insert, delete on public.saved_manufacturers to authenticated;
grant select on public.manufacturers to authenticated;
drop policy if exists "Users can read their own saved manufacturers" on public.saved_manufacturers;
create policy "Users can read their own saved manufacturers" on public.saved_manufacturers for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Users can save manufacturers to their own list" on public.saved_manufacturers;
create policy "Users can save manufacturers to their own list" on public.saved_manufacturers for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "Users can remove manufacturers from their own list" on public.saved_manufacturers;
create policy "Users can remove manufacturers from their own list" on public.saved_manufacturers for delete to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Authenticated users can view published manufacturers" on public.manufacturers;
create policy "Authenticated users can view published manufacturers" on public.manufacturers for select to authenticated using (is_published = true);


-- RFQ ownership, buyer history, supplier conversations and quotations.
alter table public.rfqs add column if not exists buyer_id uuid references auth.users(id) on delete set null;
create index if not exists rfqs_buyer_created_idx on public.rfqs(buyer_id,created_at desc);
grant select,insert,update on public.rfqs to authenticated;
grant select,insert on public.rfq_targets to authenticated;
revoke insert on public.rfqs,public.rfq_targets from anon;
revoke insert on public.rfq_conversations from anon;
drop policy if exists "Buyers can read their own RFQs" on public.rfqs;
create policy "Buyers can read their own RFQs" on public.rfqs for select to authenticated using (buyer_id=(select auth.uid()));
drop policy if exists "Assigned suppliers can read RFQs" on public.rfqs;
create policy "Assigned suppliers can read RFQs" on public.rfqs for select to authenticated using (exists(select 1 from public.rfq_targets t join public.supplier_accounts sa on sa.manufacturer_id=t.manufacturer_id where t.rfq_id=rfqs.id and sa.owner_id=(select auth.uid()) and sa.status='approved'));
drop policy if exists "Authenticated buyers can submit RFQs" on public.rfqs;
create policy "Authenticated buyers can submit RFQs" on public.rfqs for insert to authenticated with check (buyer_id=(select auth.uid()) and status='new' and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer'));
drop policy if exists "Buyers can read targets of own RFQs" on public.rfq_targets;
create policy "Buyers can read targets of own RFQs" on public.rfq_targets for select to authenticated using (rfq_id in(select id from public.rfqs where buyer_id=(select auth.uid())));
drop policy if exists "Buyers can add targets to own RFQs" on public.rfq_targets;
create policy "Buyers can add targets to own RFQs" on public.rfq_targets for insert to authenticated with check (rfq_id in(select r.id from public.rfqs r where r.buyer_id=(select auth.uid())) and manufacturer_id in(select m.id from public.manufacturers m join public.supplier_accounts sa on sa.manufacturer_id=m.id and sa.status='approved' where m.is_published=true) and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer'));
drop policy if exists "Assigned suppliers can read their RFQ targets" on public.rfq_targets;
create policy "Assigned suppliers can read their RFQ targets" on public.rfq_targets for select to authenticated using (manufacturer_id in(select manufacturer_id from public.supplier_accounts where owner_id=(select auth.uid()) and status='approved'));

create table if not exists public.rfq_conversations (
 id uuid primary key default gen_random_uuid(),rfq_id uuid not null,manufacturer_id text not null,
 buyer_id uuid not null references auth.users(id) on delete cascade,
 supplier_owner_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 foreign key(rfq_id,manufacturer_id) references public.rfq_targets(rfq_id,manufacturer_id) on delete cascade,
 unique(rfq_id,manufacturer_id),check(buyer_id<>supplier_owner_id)
);
create index if not exists rfq_conversations_buyer_idx on public.rfq_conversations(buyer_id,updated_at desc);
create index if not exists rfq_conversations_supplier_idx on public.rfq_conversations(supplier_owner_id,updated_at desc);
alter table public.rfq_conversations enable row level security;
revoke all on public.rfq_conversations from anon,authenticated;
grant select,insert on public.rfq_conversations to authenticated;
drop policy if exists "RFQ participants can read conversations" on public.rfq_conversations;
create policy "RFQ participants can read conversations" on public.rfq_conversations for select to authenticated using ((select auth.uid())=buyer_id or (select auth.uid())=supplier_owner_id);
drop policy if exists "RFQ participants can open conversations" on public.rfq_conversations;
create policy "RFQ participants can open conversations" on public.rfq_conversations for insert to authenticated with check (
 (select auth.uid())=buyer_id
 and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer')
 and exists(select 1 from public.rfqs r join public.rfq_targets t on t.rfq_id=r.id join public.supplier_accounts sa on sa.manufacturer_id=t.manufacturer_id
 where r.id=rfq_conversations.rfq_id and r.buyer_id=rfq_conversations.buyer_id and t.manufacturer_id=rfq_conversations.manufacturer_id and sa.owner_id=rfq_conversations.supplier_owner_id and sa.status='approved')
);

create table if not exists public.rfq_messages (
 id uuid primary key default gen_random_uuid(),conversation_id uuid not null references public.rfq_conversations(id) on delete cascade,
 sender_id uuid not null references auth.users(id) on delete cascade,
 body text not null check(char_length(btrim(body)) between 1 and 4000),
 created_at timestamptz not null default now(),read_at timestamptz
);
create index if not exists rfq_messages_conversation_created_idx on public.rfq_messages(conversation_id,created_at);
create index if not exists rfq_messages_sender_idx on public.rfq_messages(sender_id);
create index if not exists rfq_messages_unread_idx on public.rfq_messages(conversation_id,read_at,sender_id);
alter table public.rfq_messages enable row level security;
revoke all on public.rfq_messages from anon,authenticated;
grant select on public.rfq_messages to authenticated;
grant insert (conversation_id,sender_id,body) on public.rfq_messages to authenticated;
grant update (read_at) on public.rfq_messages to authenticated;
drop policy if exists "Conversation participants can read messages" on public.rfq_messages;
create policy "Conversation participants can read messages" on public.rfq_messages for select to authenticated using (exists(select 1 from public.rfq_conversations c where c.id=conversation_id and ((select auth.uid())=c.buyer_id or (select auth.uid())=c.supplier_owner_id)));
drop policy if exists "Participants can send messages" on public.rfq_messages;
create policy "Participants can send messages" on public.rfq_messages for insert to authenticated with check (sender_id=(select auth.uid()) and exists(select 1 from public.rfq_conversations c where c.id=conversation_id and ((select auth.uid())=c.buyer_id or (select auth.uid())=c.supplier_owner_id)));
drop policy if exists "Participants can mark received messages as read" on public.rfq_messages;
create policy "Participants can mark received messages as read" on public.rfq_messages for update to authenticated using (sender_id<>(select auth.uid()) and exists(select 1 from public.rfq_conversations c where c.id=conversation_id and ((select auth.uid())=c.buyer_id or (select auth.uid())=c.supplier_owner_id))) with check (sender_id<>(select auth.uid()) and exists(select 1 from public.rfq_conversations c where c.id=conversation_id and ((select auth.uid())=c.buyer_id or (select auth.uid())=c.supplier_owner_id)));

create or replace function public.submit_rfq_for_buyer(p_buyer_name text,p_buyer_email text,p_company text,p_product_type text,p_quantity integer,p_target_price text,p_delivery_country text,p_material_specs text,p_sample_required boolean,p_target_date date,p_manufacturer_ids text[])
returns uuid language plpgsql security invoker set search_path=''
as $$
declare v_id uuid;
begin
 if (select auth.uid()) is null then raise exception 'Sign in required'; end if;
 if not exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer') then raise exception 'A buyer account is required to submit an RFQ'; end if;
 if p_buyer_name is null or char_length(btrim(p_buyer_name)) not between 2 and 120 or p_buyer_email is null or char_length(btrim(p_buyer_email)) not between 5 and 254 or btrim(p_buyer_email) !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' or char_length(coalesce(p_company,''))>160 or p_product_type is null or char_length(btrim(p_product_type)) not between 2 and 160 or p_quantity is null or p_quantity not between 1 and 10000000 or char_length(coalesce(p_target_price,''))>120 or p_delivery_country is null or char_length(btrim(p_delivery_country)) not between 2 and 100 or char_length(coalesce(p_material_specs,''))>3000 or p_sample_required is null or coalesce(cardinality(p_manufacturer_ids),0) not between 1 and 5 then raise exception 'Invalid RFQ fields'; end if;
 if exists(select 1 from unnest(p_manufacturer_ids) x group by x having count(*)>1) or exists(select 1 from unnest(p_manufacturer_ids) x where x is null or not exists(select 1 from public.manufacturers m join public.supplier_accounts sa on sa.manufacturer_id=m.id and sa.status='approved' where m.id=x and m.is_published=true)) then raise exception 'Selected suppliers are not currently accepting RFQs'; end if;
 if p_target_date is not null and p_target_date<current_date then raise exception 'Target date cannot be in the past'; end if;
 insert into public.rfqs(id,buyer_id,buyer_name,buyer_email,company,product_type,quantity,target_price,delivery_country,material_specs,sample_required,target_date,status)
 values(gen_random_uuid(),(select auth.uid()),btrim(p_buyer_name),btrim(p_buyer_email),btrim(coalesce(p_company,'')),btrim(p_product_type),p_quantity,btrim(coalesce(p_target_price,'')),btrim(p_delivery_country),btrim(coalesce(p_material_specs,'')),p_sample_required,p_target_date,'new') returning id into v_id;
 insert into public.rfq_targets(rfq_id,manufacturer_id) select v_id,x from unnest(p_manufacturer_ids) x;
 insert into public.rfq_conversations(rfq_id,manufacturer_id,buyer_id,supplier_owner_id)
 select v_id,t.manufacturer_id,(select auth.uid()),sa.owner_id from public.rfq_targets t join public.supplier_accounts sa on sa.manufacturer_id=t.manufacturer_id and sa.status='approved' where t.rfq_id=v_id on conflict(rfq_id,manufacturer_id) do nothing;
 return v_id;
end;
$$;
revoke all on function public.submit_rfq_for_buyer(text,text,text,text,integer,text,text,text,boolean,date,text[]) from public,anon;
grant execute on function public.submit_rfq_for_buyer(text,text,text,text,integer,text,text,text,boolean,date,text[]) to authenticated;

create table if not exists public.supplier_quotes (
 id uuid primary key default gen_random_uuid(),rfq_id uuid not null,manufacturer_id text not null,
 supplier_owner_id uuid not null references auth.users(id) on delete cascade,
 unit_price numeric(12,4) not null check(unit_price>0),currency text not null default 'EUR' check(currency in ('EUR','USD','TND','GBP')),
 minimum_order integer check(minimum_order is null or minimum_order>0),lead_time_days integer check(lead_time_days is null or lead_time_days between 1 and 730),
 sample_available boolean not null default false,notes text not null default '' check(char_length(notes)<=2000),
 valid_until date,status text not null default 'submitted' check(status in ('submitted','updated','withdrawn')),
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 foreign key(rfq_id,manufacturer_id) references public.rfq_targets(rfq_id,manufacturer_id) on delete cascade,unique(rfq_id,manufacturer_id)
);
create index if not exists supplier_quotes_owner_idx on public.supplier_quotes(supplier_owner_id,created_at desc);
create index if not exists supplier_quotes_rfq_idx on public.supplier_quotes(rfq_id);
alter table public.supplier_quotes enable row level security;
revoke all on public.supplier_quotes from anon,authenticated;
grant select,insert,update on public.supplier_quotes to authenticated;
drop policy if exists "Quote owners can read their quotes" on public.supplier_quotes;
create policy "Quote owners can read their quotes" on public.supplier_quotes for select to authenticated using(supplier_owner_id=(select auth.uid()));
drop policy if exists "Buyers can read own RFQ quotes" on public.supplier_quotes;
create policy "Buyers can read own RFQ quotes" on public.supplier_quotes for select to authenticated using(rfq_id in(select id from public.rfqs where buyer_id=(select auth.uid())));
drop policy if exists "Only assigned supplier can submit quote" on public.supplier_quotes;
create policy "Only assigned supplier can submit quote" on public.supplier_quotes for insert to authenticated with check(supplier_owner_id=(select auth.uid()) and (rfq_id,manufacturer_id) in(select rfq_id,manufacturer_id from public.rfq_targets) and manufacturer_id in(select manufacturer_id from public.supplier_accounts where owner_id=(select auth.uid()) and status='approved'));

create table if not exists public.rfq_quote_decisions (
 id uuid primary key default gen_random_uuid(),rfq_id uuid not null references public.rfqs(id) on delete cascade,
 manufacturer_id text not null,buyer_id uuid not null references auth.users(id) on delete cascade,
 status text not null default 'selected' check(status in ('selected','not_selected')),
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 foreign key(rfq_id,manufacturer_id) references public.supplier_quotes(rfq_id,manufacturer_id) on delete cascade,
 unique(rfq_id,manufacturer_id)
);
create unique index if not exists rfq_quote_decisions_one_selected_per_rfq on public.rfq_quote_decisions(rfq_id) where status='selected';
create index if not exists rfq_quote_decisions_supplier_idx on public.rfq_quote_decisions(manufacturer_id,updated_at desc);
create index if not exists rfq_quote_decisions_buyer_idx on public.rfq_quote_decisions(buyer_id,updated_at desc);
alter table public.rfq_quote_decisions enable row level security;
revoke all on public.rfq_quote_decisions from anon,authenticated;
grant select,insert,update on public.rfq_quote_decisions to authenticated;
drop policy if exists "Participants can read quote decisions" on public.rfq_quote_decisions;
create policy "Participants can read quote decisions" on public.rfq_quote_decisions for select to authenticated using (
 (buyer_id=(select auth.uid()) and exists(select 1 from public.rfqs r where r.id=rfq_id and r.buyer_id=(select auth.uid())))
 or exists(select 1 from public.supplier_accounts sa where sa.owner_id=(select auth.uid()) and sa.manufacturer_id=rfq_quote_decisions.manufacturer_id and sa.status='approved')
);
drop policy if exists "Buyers can create own quote decisions" on public.rfq_quote_decisions;
create policy "Buyers can create own quote decisions" on public.rfq_quote_decisions for insert to authenticated with check (
 buyer_id=(select auth.uid()) and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer')
 and exists(select 1 from public.rfqs r where r.id=rfq_id and r.buyer_id=(select auth.uid()))
 and exists(select 1 from public.supplier_quotes q where q.rfq_id=rfq_quote_decisions.rfq_id and q.manufacturer_id=rfq_quote_decisions.manufacturer_id and q.status in ('submitted','updated'))
);
drop policy if exists "Buyers can update own quote decisions" on public.rfq_quote_decisions;
create policy "Buyers can update own quote decisions" on public.rfq_quote_decisions for update to authenticated using (
 buyer_id=(select auth.uid()) and exists(select 1 from public.rfqs r where r.id=rfq_id and r.buyer_id=(select auth.uid()))
) with check (
 buyer_id=(select auth.uid()) and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer')
 and exists(select 1 from public.rfqs r where r.id=rfq_id and r.buyer_id=(select auth.uid()))
 and (status='not_selected' or exists(select 1 from public.supplier_quotes q where q.rfq_id=rfq_quote_decisions.rfq_id and q.manufacturer_id=rfq_quote_decisions.manufacturer_id and q.status in ('submitted','updated')))
);
create or replace function public.select_rfq_quote(p_rfq_id uuid,p_manufacturer_id text)
returns void language plpgsql security invoker set search_path=''
as $$
begin
 if (select auth.uid()) is null then raise exception 'Sign in required'; end if;
 if not exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer') then raise exception 'A buyer account is required to select a quotation'; end if;
 if not exists(select 1 from public.rfqs r where r.id=p_rfq_id and r.buyer_id=(select auth.uid())) then raise exception 'RFQ not found for this buyer'; end if;
 if not exists(select 1 from public.supplier_quotes q where q.rfq_id=p_rfq_id and q.manufacturer_id=p_manufacturer_id and q.status in ('submitted','updated')) then raise exception 'This supplier quotation is no longer available'; end if;
 update public.rfq_quote_decisions set status='not_selected',updated_at=now() where rfq_id=p_rfq_id and buyer_id=(select auth.uid()) and status='selected';
 insert into public.rfq_quote_decisions(rfq_id,manufacturer_id,buyer_id,status) values(p_rfq_id,p_manufacturer_id,(select auth.uid()),'selected')
 on conflict(rfq_id,manufacturer_id) do update set status='selected',updated_at=now() where public.rfq_quote_decisions.buyer_id=(select auth.uid());
end;
$$;
revoke all on function public.select_rfq_quote(uuid,text) from public,anon;
grant execute on function public.select_rfq_quote(uuid,text) to authenticated;
drop policy if exists "Assigned suppliers can update own quotes" on public.supplier_quotes;
create policy "Assigned suppliers can update own quotes" on public.supplier_quotes for update to authenticated using (
 supplier_owner_id=(select auth.uid()) and not exists(select 1 from public.rfq_quote_decisions d where d.rfq_id=supplier_quotes.rfq_id and d.manufacturer_id=supplier_quotes.manufacturer_id and d.status='selected')
) with check (
 supplier_owner_id=(select auth.uid())
 and manufacturer_id in(select manufacturer_id from public.supplier_accounts where owner_id=(select auth.uid()) and status='approved')
 and (rfq_id,manufacturer_id) in(select rfq_id,manufacturer_id from public.rfq_targets)
 and not exists(select 1 from public.rfq_quote_decisions d where d.rfq_id=supplier_quotes.rfq_id and d.manufacturer_id=supplier_quotes.manufacturer_id and d.status='selected')
);


-- Expired quotations cannot be selected by buyers.
-- Do not allow buyers to select expired supplier quotations.
create or replace function public.select_rfq_quote(p_rfq_id uuid,p_manufacturer_id text)
returns void
language plpgsql
security invoker
set search_path=''
as $$
begin
 if (select auth.uid()) is null then raise exception 'Sign in required'; end if;
 if not exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer') then
   raise exception 'A buyer account is required to select a quotation';
 end if;
 if not exists(select 1 from public.rfqs r where r.id=p_rfq_id and r.buyer_id=(select auth.uid())) then
   raise exception 'RFQ not found for this buyer';
 end if;
 if not exists(
   select 1 from public.supplier_quotes q
   where q.rfq_id=p_rfq_id and q.manufacturer_id=p_manufacturer_id
     and q.status in ('submitted','updated')
     and (q.valid_until is null or q.valid_until >= current_date)
 ) then
   raise exception 'This quotation is unavailable or has expired';
 end if;
 update public.rfq_quote_decisions
 set status='not_selected',updated_at=now()
 where rfq_id=p_rfq_id and buyer_id=(select auth.uid()) and status='selected';
 insert into public.rfq_quote_decisions(rfq_id,manufacturer_id,buyer_id,status)
 values(p_rfq_id,p_manufacturer_id,(select auth.uid()),'selected')
 on conflict(rfq_id,manufacturer_id)
 do update set status='selected',updated_at=now()
 where public.rfq_quote_decisions.buyer_id=(select auth.uid());
end;
$$;
revoke all on function public.select_rfq_quote(uuid,text) from public,anon;
grant execute on function public.select_rfq_quote(uuid,text) to authenticated;


-- Include evidence URL and reviewer note in manufacturer audit history.
-- Preserve evidence source and reviewer notes in manufacturer verification audit events.
create or replace function private.audit_factoryscout_review_event()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
 v_old jsonb := '{}'::jsonb;
 v_new jsonb := '{}'::jsonb;
 v_entity_type text;
 v_entity_id text;
 v_action text;
begin
 if tg_table_name='supplier_accounts' then
   if old.status is not distinct from new.status and old.manufacturer_id is not distinct from new.manufacturer_id then return new; end if;
   v_entity_type := 'supplier_account';
   v_entity_id := new.id::text;
   v_action := 'supplier_status_changed';
   v_old := jsonb_build_object('status',old.status,'manufacturer_id',old.manufacturer_id);
   v_new := jsonb_build_object('status',new.status,'manufacturer_id',new.manufacturer_id);
 elsif tg_table_name='products' then
   if old.status is not distinct from new.status then return new; end if;
   v_entity_type := 'product';
   v_entity_id := new.id::text;
   v_action := 'product_moderation_changed';
   v_old := jsonb_build_object('status',old.status,'manufacturer_id',old.manufacturer_id);
   v_new := jsonb_build_object('status',new.status,'manufacturer_id',new.manufacturer_id);
 elsif tg_table_name='manufacturers' then
   if old.verification_status is not distinct from new.verification_status
      and old.is_published is not distinct from new.is_published
      and old.evidence is not distinct from new.evidence
      and old.evidence_note is not distinct from new.evidence_note then return new; end if;
   v_entity_type := 'manufacturer';
   v_entity_id := new.id::text;
   v_action := 'manufacturer_verification_changed';
   v_old := jsonb_build_object('verification_status',old.verification_status,'is_published',old.is_published,'evidence',old.evidence,'evidence_note',old.evidence_note);
   v_new := jsonb_build_object('verification_status',new.verification_status,'is_published',new.is_published,'evidence',new.evidence,'evidence_note',new.evidence_note);
 elsif tg_table_name='enquiries' then
   if old.status is not distinct from new.status then return new; end if;
   v_entity_type := 'buyer_enquiry';
   v_entity_id := new.id::text;
   v_action := 'enquiry_status_changed';
   v_old := jsonb_build_object('status',old.status);
   v_new := jsonb_build_object('status',new.status);
 elsif tg_table_name='rfqs' then
   if old.status is not distinct from new.status then return new; end if;
   v_entity_type := 'rfq';
   v_entity_id := new.id::text;
   v_action := 'rfq_status_changed';
   v_old := jsonb_build_object('status',old.status);
   v_new := jsonb_build_object('status',new.status);
 else
   return new;
 end if;
 insert into public.admin_review_events(entity_type,entity_id,action,actor_id,previous_state,new_state)
 values(v_entity_type,v_entity_id,v_action,(select auth.uid()),v_old,v_new);
 return new;
end;
$$;
revoke all on function private.audit_factoryscout_review_event() from public,anon,authenticated;
drop trigger if exists audit_enquiry_status on public.enquiries;
create trigger audit_enquiry_status after update of status on public.enquiries for each row execute function private.audit_factoryscout_review_event();
drop trigger if exists audit_rfq_status on public.rfqs;
create trigger audit_rfq_status after update of status on public.rfqs for each row execute function private.audit_factoryscout_review_event();


-- Admin-only pre-launch supplier prospect pipeline.
create table if not exists public.supplier_prospects (
 id uuid primary key default gen_random_uuid(),
 company_name text not null,
 website text not null unique,
 country text not null default 'Tunisia',
 region text,
 contact_email text,
 contact_phone text,
 capabilities text[] not null default '{}',
 public_claims text[] not null default '{}',
 source_urls text[] not null default '{}',
 research_notes text not null default '',
 status text not null default 'researched'
   check(status in ('researched','contacted','responded','interested','application_pending','onboarded','declined','not_a_fit')),
 last_contacted_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.supplier_prospects enable row level security;
revoke all on public.supplier_prospects from anon,authenticated;
grant select,insert,update,delete on public.supplier_prospects to authenticated;
drop policy if exists "Admins manage supplier prospects" on public.supplier_prospects;
create policy "Admins manage supplier prospects" on public.supplier_prospects
 for all to authenticated using (private.is_factoryscout_admin()) with check (private.is_factoryscout_admin());

insert into public.supplier_prospects(company_name,website,region,contact_email,contact_phone,capabilities,public_claims,source_urls,research_notes,status)
values
('SOCAF Confection','https://socafconfection.com','Moknine, Monastir','contact@socafconfection.com','+216 73 439 209',
 array['Private-label woven garments','Women, men and children apparel'],
 array['Company states it was founded in 2001','Company publishes figures of 250 workers, six production lines, 1,400 m², about 300,000 pieces/year and up to 1,200 pieces/day; all require confirmation'],
 array['https://socafconfection.com/en/about-us/','https://socafconfection.com/en/our-contact/','https://socafconfection.com/services/'],
 'Confirm current facility addresses, active lines, capacity, MOQ by style, sample process, lead times and export references. Public-source prospect only; no outreach or approval yet.','researched'),
('TFH Group','https://tfh.com.tn','Ksar Saïd, La Manouba','contact@tfh.com.tn','+216 71 651 100 / +216 71 651 108',
 array['Woven and knitted ready-to-wear','Workwear and corporate apparel','Technical apparel'],
 array['Company describes four factories and about 1.8 million finished items/year','Company publishes 5–8 day sample lead time and 5–6 week finished-order lead time; all require confirmation'],
 array['https://tfh.com.tn/en/about-us','https://www.tfh.com.tn/en/our-sites-production','https://tfh.com.tn/fr/nos-produits','https://tfh.com.tn/fr/contact'],
 'Confirm which facilities are operating, capacity by line, technical apparel machinery, subcontracting policy, certification scope and expiry dates. Public-source prospect only; no outreach or approval yet.','researched'),
('Jalna Confection','https://jalna.tn','Tunisia Sahel, near Sousse','hanaschaus@jalna.tn','+216 73 298 298 / +216 98 456 225',
 array['Knit leisurewear','Woven leisurewear','Export-oriented apparel'],
 array['Company states it was founded in 1997 and has 180 employees','Website claims ICS audit and OEKO-TEX certification; current certificates and scope must be checked'],
 array['https://jalna.tn/en/','https://jalna.tn/contact-us/'],
 'Contact page also displays a generic contact@example.com address; confirm correct commercial contact before outreach. Verify factory address, product scope, MOQ, sample room, export references and certificate expiry dates. Public-source prospect only; no outreach or approval yet.','researched'),
('King Plus','https://kingplus.tn','Jemmal, Monastir','Amira.Zaag@kingplus.tn','+216 70 256 550',
 array['Vertically integrated apparel production','Export-oriented garment manufacturing'],
 array['Company states it was founded in 2000 and claims 90% vertical integration','Website lists GOTS, GRS, ISO 9001, ICS and BSCI; request current certificates and verify holder/scope/expiry'],
 array['https://kingplus.tn/?lang=en'],
 'Confirm in-house versus subcontracted operations, product specialisms, factory address, current certificate evidence, MOQ, capacity and export documentation. Public-source prospect only; no outreach or approval yet.','researched'),
('DEMCO / DEMCOINTER','https://www.demcointer.com','Moknine, Monastir','', '+216 73 416 144 / +216 70 284 100',
 array['Private-label denim','Knitwear','Jeans, jackets, jersey, fleece, underwear, T-shirts and polos'],
 array['Company describes integrated production and digital product development','Company publishes 3D sample in two working days, physical samples in 10–15 days and bulk in 6–8 weeks; confirm per product and material'],
 array['https://www.demcointer.com/en/faq/','https://www.demcointer.com/en/contact/'],
 'Confirm contracting legal entity, factory operations, denim/knitwear capacity, wash/finishing, fabric sourcing, MOQ, sample charges and current social/environmental certifications. Public-source prospect only; no outreach or approval yet.','researched')
on conflict(website) do nothing;
