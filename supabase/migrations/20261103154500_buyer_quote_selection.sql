-- Buyer quote selection: one chosen supplier per RFQ, visible to both parties.
create table if not exists public.rfq_quote_decisions (
 id uuid primary key default gen_random_uuid(),
 rfq_id uuid not null references public.rfqs(id) on delete cascade,
 manufacturer_id text not null,
 buyer_id uuid not null references auth.users(id) on delete cascade,
 status text not null default 'selected' check (status in ('selected','not_selected')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 foreign key (rfq_id,manufacturer_id) references public.supplier_quotes(rfq_id,manufacturer_id) on delete cascade,
 unique (rfq_id,manufacturer_id)
);
create unique index if not exists rfq_quote_decisions_one_selected_per_rfq
 on public.rfq_quote_decisions(rfq_id) where status='selected';
create index if not exists rfq_quote_decisions_supplier_idx
 on public.rfq_quote_decisions(manufacturer_id,updated_at desc);
alter table public.rfq_quote_decisions enable row level security;
revoke all on public.rfq_quote_decisions from anon,authenticated;
grant select,insert,update on public.rfq_quote_decisions to authenticated;

drop policy if exists "Buyers can read own quote decisions" on public.rfq_quote_decisions;
create policy "Buyers can read own quote decisions"
 on public.rfq_quote_decisions for select to authenticated
 using (buyer_id=(select auth.uid()) and exists(
   select 1 from public.rfqs r where r.id=rfq_id and r.buyer_id=(select auth.uid())
 ));
drop policy if exists "Assigned suppliers can read quote decisions" on public.rfq_quote_decisions;
create policy "Assigned suppliers can read quote decisions"
 on public.rfq_quote_decisions for select to authenticated
 using (exists(
   select 1 from public.supplier_accounts sa
   where sa.owner_id=(select auth.uid()) and sa.manufacturer_id=rfq_quote_decisions.manufacturer_id and sa.status='approved'
 ));
drop policy if exists "Buyers can create own quote decisions" on public.rfq_quote_decisions;
create policy "Buyers can create own quote decisions"
 on public.rfq_quote_decisions for insert to authenticated
 with check (
   buyer_id=(select auth.uid())
   and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer')
   and exists(select 1 from public.rfqs r where r.id=rfq_id and r.buyer_id=(select auth.uid()))
   and exists(select 1 from public.supplier_quotes q where q.rfq_id=rfq_quote_decisions.rfq_id and q.manufacturer_id=rfq_quote_decisions.manufacturer_id and q.status in ('submitted','updated'))
 );
drop policy if exists "Buyers can update own quote decisions" on public.rfq_quote_decisions;
create policy "Buyers can update own quote decisions"
 on public.rfq_quote_decisions for update to authenticated
 using (buyer_id=(select auth.uid()) and exists(select 1 from public.rfqs r where r.id=rfq_id and r.buyer_id=(select auth.uid())))
 with check (
   buyer_id=(select auth.uid())
   and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer')
   and exists(select 1 from public.rfqs r where r.id=rfq_id and r.buyer_id=(select auth.uid()))
   and (
     status='not_selected'
     or exists(select 1 from public.supplier_quotes q where q.rfq_id=rfq_quote_decisions.rfq_id and q.manufacturer_id=rfq_quote_decisions.manufacturer_id and q.status in ('submitted','updated'))
   )
 );

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
 if not exists(select 1 from public.supplier_quotes q where q.rfq_id=p_rfq_id and q.manufacturer_id=p_manufacturer_id and q.status in ('submitted','updated')) then
   raise exception 'This supplier quotation is no longer available';
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

-- A supplier cannot alter a quotation after the buyer has selected it.
drop policy if exists "Assigned suppliers can update own quotes" on public.supplier_quotes;
create policy "Assigned suppliers can update own quotes"
 on public.supplier_quotes for update to authenticated
 using (
   supplier_owner_id=(select auth.uid())
   and not exists(select 1 from public.rfq_quote_decisions d
     where d.rfq_id=supplier_quotes.rfq_id
       and d.manufacturer_id=supplier_quotes.manufacturer_id
       and d.status='selected')
 )
 with check (
   supplier_owner_id=(select auth.uid())
   and manufacturer_id in(select manufacturer_id from public.supplier_accounts where owner_id=(select auth.uid()) and status='approved')
   and (rfq_id,manufacturer_id) in(select rfq_id,manufacturer_id from public.rfq_targets)
   and not exists(select 1 from public.rfq_quote_decisions d
     where d.rfq_id=supplier_quotes.rfq_id
       and d.manufacturer_id=supplier_quotes.manufacturer_id
       and d.status='selected')
 );
