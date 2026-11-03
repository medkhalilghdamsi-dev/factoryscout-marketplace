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
   check(status in ('researched','contacted','responded','interested','application_pending','approved','declined','not_a_fit')),
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
