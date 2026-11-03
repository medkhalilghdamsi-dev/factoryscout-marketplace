-- Secure message read receipts and keep RFQ inbox ordering current.
create index if not exists rfq_messages_unread_idx
  on public.rfq_messages(conversation_id, read_at, sender_id);

grant update(read_at) on public.rfq_messages to authenticated;

drop policy if exists "Participants can mark received messages as read" on public.rfq_messages;
create policy "Participants can mark received messages as read"
on public.rfq_messages
for update
to authenticated
using (
  sender_id <> (select auth.uid())
  and exists (
    select 1 from public.rfq_conversations c
    where c.id = rfq_messages.conversation_id
      and ((select auth.uid()) = c.buyer_id or (select auth.uid()) = c.supplier_owner_id)
  )
)
with check (
  sender_id <> (select auth.uid())
  and exists (
    select 1 from public.rfq_conversations c
    where c.id = rfq_messages.conversation_id
      and ((select auth.uid()) = c.buyer_id or (select auth.uid()) = c.supplier_owner_id)
  )
);

create or replace function public.bump_rfq_conversation_on_message()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.rfq_conversations
  set updated_at = now()
  where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists rfq_message_bumps_conversation on public.rfq_messages;
create trigger rfq_message_bumps_conversation
after insert on public.rfq_messages
for each row execute function public.bump_rfq_conversation_on_message();
