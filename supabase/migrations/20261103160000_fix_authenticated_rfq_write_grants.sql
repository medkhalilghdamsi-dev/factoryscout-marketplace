-- Restore least-privilege authenticated write grants required by the SECURITY INVOKER RFQ RPC.
grant insert on public.rfqs, public.rfq_targets to authenticated;
revoke insert on public.rfqs, public.rfq_targets from anon;
revoke insert on public.rfq_conversations from anon;

drop policy if exists "Public can submit new RFQs" on public.rfqs;
drop policy if exists "Public can target published manufacturers" on public.rfq_targets;
drop policy if exists "Authenticated buyers can submit RFQs" on public.rfqs;
create policy "Authenticated buyers can submit RFQs"
 on public.rfqs for insert to authenticated
 with check (
   buyer_id=(select auth.uid())
   and status='new'
   and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer')
 );

drop policy if exists "Buyers can add targets to own RFQs" on public.rfq_targets;
create policy "Buyers can add targets to own RFQs"
 on public.rfq_targets for insert to authenticated
 with check (
   rfq_id in(select r.id from public.rfqs r where r.buyer_id=(select auth.uid()))
   and manufacturer_id in(select m.id from public.manufacturers m where m.is_published=true)
   and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer')
 );
