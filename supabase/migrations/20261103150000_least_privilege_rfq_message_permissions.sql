-- Remove inherited broad column grants. Message authors can insert and read
-- participant messages; recipients can update only the read receipt column.
revoke all privileges on table public.rfq_messages from anon, authenticated;
grant select, insert on table public.rfq_messages to authenticated;
grant update(read_at) on table public.rfq_messages to authenticated;
