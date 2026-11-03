-- ONE-TIME OWNER BOOTSTRAP — run manually in the Supabase SQL Editor.
-- Replace the email below with the exact email used to create the first owner account.
-- Never expose a service-role key or add a public admin-signup endpoint.

do $$
declare
  v_owner_email text := lower(trim('REPLACE_WITH_OWNER_EMAIL'));
  v_owner_id uuid;
  v_owner_name text;
begin
  if v_owner_email = '' or v_owner_email = 'replace_with_owner_email' then
    raise exception 'Replace REPLACE_WITH_OWNER_EMAIL with the owner account email before running this script.';
  end if;

  if exists (select 1 from public.profiles where role = 'admin') then
    raise exception 'An admin already exists. Refusing to bootstrap a second first owner.';
  end if;

  select id, coalesce(raw_user_meta_data->>'full_name','FactoryScout Owner')
    into v_owner_id, v_owner_name
  from auth.users
  where lower(email) = v_owner_email
    and email_confirmed_at is not null;

  if v_owner_id is null then
    raise exception 'No confirmed Supabase Auth user found for %. Create the owner account and confirm its email first.', v_owner_email;
  end if;

  insert into public.profiles(id,email,full_name,account_type,role)
  select id,email,v_owner_name,'buyer','admin'
  from auth.users
  where id = v_owner_id
  on conflict (id) do update
    set role = 'admin',
        updated_at = now();

  raise notice 'FactoryScout first admin bootstrapped for user id %.', v_owner_id;
end
$$;
