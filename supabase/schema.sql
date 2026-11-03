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
grant insert on public.rfqs, public.rfq_targets to anon;

drop policy if exists "Public can view published product listings" on public.products;
create policy "Public can view published product listings"
 on public.products for select to anon using (
  status = 'published' and exists (
   select 1 from public.manufacturers m
   where m.id = products.manufacturer_id and m.is_published = true
  )
);
drop policy if exists "Public can submit new RFQs" on public.rfqs;
create policy "Public can submit new RFQs"
 on public.rfqs for insert to anon with check (status = 'new');
drop policy if exists "Public can target published manufacturers" on public.rfq_targets;
create policy "Public can target published manufacturers"
 on public.rfq_targets for insert to anon
 with check (
  exists (select 1 from public.manufacturers m where m.id = rfq_targets.manufacturer_id and m.is_published = true)
 );


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
grant execute on function public.submit_rfq(text,text,text,text,integer,text,text,text,boolean,date,text[]) to anon;
grant insert on public.rfqs, public.rfq_targets to anon;
revoke insert on public.rfqs, public.rfq_targets from authenticated;
