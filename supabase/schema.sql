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
