create or replace function public.submit_rfq_for_buyer(
 p_buyer_name text,p_buyer_email text,p_company text,p_product_type text,
 p_quantity integer,p_target_price text,p_delivery_country text,p_material_specs text,
 p_sample_required boolean,p_target_date date,p_manufacturer_ids text[]
) returns uuid
language plpgsql security invoker set search_path=''
as $$
declare v_id uuid;
begin
 if (select auth.uid()) is null then raise exception 'Sign in required'; end if;
 if not exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.account_type='buyer') then
   raise exception 'A buyer account is required to submit an RFQ';
 end if;
 if p_buyer_name is null or char_length(btrim(p_buyer_name)) not between 2 and 120
   or p_buyer_email is null or char_length(btrim(p_buyer_email)) not between 5 and 254
   or btrim(p_buyer_email) !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$'
   or char_length(coalesce(p_company,'')) > 160
   or p_product_type is null or char_length(btrim(p_product_type)) not between 2 and 160
   or p_quantity is null or p_quantity not between 1 and 10000000
   or char_length(coalesce(p_target_price,'')) > 120
   or p_delivery_country is null or char_length(btrim(p_delivery_country)) not between 2 and 100
   or char_length(coalesce(p_material_specs,'')) > 3000
   or p_sample_required is null
   or coalesce(cardinality(p_manufacturer_ids),0) not between 1 and 5
 then raise exception 'Invalid RFQ fields'; end if;
 if exists(select 1 from unnest(p_manufacturer_ids) x group by x having count(*)>1)
   or exists(select 1 from unnest(p_manufacturer_ids) x where not exists(select 1 from public.manufacturers m where m.id=x and m.is_published=true))
 then raise exception 'Invalid supplier selection'; end if;
 if p_target_date is not null and p_target_date < current_date then raise exception 'Target date cannot be in the past'; end if;
 insert into public.rfqs(id,buyer_id,buyer_name,buyer_email,company,product_type,quantity,target_price,delivery_country,material_specs,sample_required,target_date,status)
 values(gen_random_uuid(),(select auth.uid()),btrim(p_buyer_name),btrim(p_buyer_email),btrim(coalesce(p_company,'')),btrim(p_product_type),p_quantity,btrim(coalesce(p_target_price,'')),btrim(p_delivery_country),btrim(coalesce(p_material_specs,'')),p_sample_required,p_target_date,'new')
 returning id into v_id;
 insert into public.rfq_targets(rfq_id,manufacturer_id) select v_id,x from unnest(p_manufacturer_ids) x;
 insert into public.rfq_conversations(rfq_id,manufacturer_id,buyer_id,supplier_owner_id)
 select v_id,t.manufacturer_id,(select auth.uid()),sa.owner_id
 from public.rfq_targets t join public.supplier_accounts sa on sa.manufacturer_id=t.manufacturer_id and sa.status='approved'
 where t.rfq_id=v_id on conflict(rfq_id,manufacturer_id) do nothing;
 return v_id;
end; $$;
revoke all on function public.submit_rfq_for_buyer(text,text,text,text,integer,text,text,text,boolean,date,text[]) from public,anon;
grant execute on function public.submit_rfq_for_buyer(text,text,text,text,integer,text,text,text,boolean,date,text[]) to authenticated;
