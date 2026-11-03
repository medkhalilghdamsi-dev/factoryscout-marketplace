-- Immutable admin audit trail for supplier, product and manufacturer review decisions.
create table if not exists public.admin_review_events (
 id uuid primary key default gen_random_uuid(),
 entity_type text not null check (entity_type in ('supplier_account','product','manufacturer')),
 entity_id text not null,
 action text not null,
 actor_id uuid references auth.users(id) on delete set null,
 previous_state jsonb not null default '{}'::jsonb,
 new_state jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create index if not exists admin_review_events_entity_idx
 on public.admin_review_events(entity_type,entity_id,created_at desc);
create index if not exists admin_review_events_actor_idx
 on public.admin_review_events(actor_id,created_at desc);
alter table public.admin_review_events enable row level security;
revoke all on public.admin_review_events from anon,authenticated;
grant select on public.admin_review_events to authenticated;
drop policy if exists "Admins can read review audit events" on public.admin_review_events;
create policy "Admins can read review audit events"
 on public.admin_review_events for select to authenticated
 using ((select private.is_factoryscout_admin()));

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
      and old.is_published is not distinct from new.is_published then return new; end if;
   v_entity_type := 'manufacturer';
   v_entity_id := new.id::text;
   v_action := 'manufacturer_verification_changed';
   v_old := jsonb_build_object('verification_status',old.verification_status,'is_published',old.is_published);
   v_new := jsonb_build_object('verification_status',new.verification_status,'is_published',new.is_published);
 else
   return new;
 end if;
 insert into public.admin_review_events(entity_type,entity_id,action,actor_id,previous_state,new_state)
 values(v_entity_type,v_entity_id,v_action,(select auth.uid()),v_old,v_new);
 return new;
end;
$$;
revoke all on function private.audit_factoryscout_review_event() from public,anon,authenticated;

drop trigger if exists audit_supplier_account_review on public.supplier_accounts;
create trigger audit_supplier_account_review
 after update on public.supplier_accounts
 for each row execute function private.audit_factoryscout_review_event();
drop trigger if exists audit_product_moderation on public.products;
create trigger audit_product_moderation
 after update on public.products
 for each row execute function private.audit_factoryscout_review_event();
drop trigger if exists audit_manufacturer_verification on public.manufacturers;
create trigger audit_manufacturer_verification
 after update on public.manufacturers
 for each row execute function private.audit_factoryscout_review_event();
