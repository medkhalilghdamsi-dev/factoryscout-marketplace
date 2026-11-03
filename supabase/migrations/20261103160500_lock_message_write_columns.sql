-- Conversation membership and message bodies are immutable after creation.
revoke update on public.rfq_conversations from authenticated;
revoke update on public.rfq_messages from authenticated;
grant update (read_at) on public.rfq_messages to authenticated;
revoke insert on public.rfq_messages from authenticated;
grant insert (conversation_id,sender_id,body) on public.rfq_messages to authenticated;
