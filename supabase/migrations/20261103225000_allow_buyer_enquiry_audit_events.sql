-- Allow the admin review log to record public buyer enquiry decisions.
alter table public.admin_review_events
  drop constraint if exists admin_review_events_entity_type_check;

alter table public.admin_review_events
  add constraint admin_review_events_entity_type_check
  check (entity_type = any (array[
    'supplier_account'::text,
    'product'::text,
    'manufacturer'::text,
    'buyer_enquiry'::text,
    'rfq'::text
  ]));
