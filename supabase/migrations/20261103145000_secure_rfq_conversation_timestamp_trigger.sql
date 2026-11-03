-- The trigger must bump the parent timestamp even though message senders cannot
-- directly update conversation rows. The trigger accepts no caller-controlled ID.
create or replace function public.bump_rfq_conversation_on_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.rfq_conversations
  set updated_at = now()
  where id = new.conversation_id;
  return new;
end;
$$;
revoke all on function public.bump_rfq_conversation_on_message() from public, anon, authenticated;
