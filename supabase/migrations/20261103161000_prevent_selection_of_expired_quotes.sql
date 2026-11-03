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
