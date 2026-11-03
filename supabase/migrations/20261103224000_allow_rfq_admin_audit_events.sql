alter table public.admin_review_events
 drop constraint if exists admin_review_events_entity_type_check;
alter table public.admin_review_events
 add constraint admin_review_events_entity_type_check
 check(entity_type in ('supplier_account','product','manufacturer','buyer_enquiry','rfq'));
