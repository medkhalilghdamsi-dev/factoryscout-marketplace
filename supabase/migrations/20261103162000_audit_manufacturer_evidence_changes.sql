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
 else
   return new;
 end if;
 insert into public.admin_review_events(entity_type,entity_id,action,actor_id,previous_state,new_state)
 values(v_entity_type,v_entity_id,v_action,(select auth.uid()),v_old,v_new);
 return new;
end;
$$;
revoke all on function private.audit_factoryscout_review_event() from public,anon,authenticated;
