drop policy if exists "Admins can review all supplier quotes" on public.supplier_quotes;
create policy "Admins can review all supplier quotes" on public.supplier_quotes
for select to authenticated using ((select private.is_factoryscout_admin()));
