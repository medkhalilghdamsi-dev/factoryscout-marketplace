-- Let supplier applicants request to claim an existing published manufacturer profile.
alter table public.supplier_accounts
 add column if not exists requested_manufacturer_id text references public.manufacturers(id) on delete set null;
create unique index if not exists supplier_accounts_one_pending_claim_per_manufacturer
 on public.supplier_accounts(requested_manufacturer_id)
 where status='pending' and requested_manufacturer_id is not null;
grant insert (requested_manufacturer_id) on public.supplier_accounts to authenticated;
grant update (requested_manufacturer_id) on public.supplier_accounts to authenticated;

drop policy if exists "Users can submit a pending supplier account" on public.supplier_accounts;
create policy "Users can submit a pending supplier account"
 on public.supplier_accounts for insert to authenticated
 with check (
   (select auth.uid())=owner_id and status='pending' and manufacturer_id is null
   and (requested_manufacturer_id is null or (
     exists(select 1 from public.manufacturers m where m.id=requested_manufacturer_id and m.is_published=true)
     and not exists(select 1 from public.supplier_accounts sa where sa.manufacturer_id=requested_manufacturer_id and sa.status='approved')
   ))
 );
drop policy if exists "Owners can edit pending supplier details" on public.supplier_accounts;
create policy "Owners can edit pending supplier details"
 on public.supplier_accounts for update to authenticated
 using ((select auth.uid())=owner_id and status='pending')
 with check (
   (select auth.uid())=owner_id and status='pending' and manufacturer_id is null
   and (requested_manufacturer_id is null or (
     exists(select 1 from public.manufacturers m where m.id=requested_manufacturer_id and m.is_published=true)
     and not exists(select 1 from public.supplier_accounts sa where sa.manufacturer_id=requested_manufacturer_id and sa.status='approved')
   ))
 );

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
