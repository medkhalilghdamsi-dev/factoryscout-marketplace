# FactoryScout — Pre-Launch Readiness Plan

**Policy:** No buyer acquisition, paid promotion, or public launch until every launch gate below is passed. The site may be used internally for QA and supplier verification before then.

## Product promise

FactoryScout is an international apparel-manufacturing sourcing marketplace. Buyers discover manufacturers and product capabilities, compare suppliers, send one request to multiple factories, receive comparable quotations, and communicate with suppliers. Suppliers maintain a company storefront, submit products for moderation, receive relevant RFQs, and submit quotations. Administrators verify claims and control marketplace quality.

## Current verified baseline (2026-11-03)

- React 19 + Vite frontend, Express API, Supabase Postgres/Auth/Storage, Render web service.
- Render service: `factoryscout-marketplace`, Frankfurt, free plan; latest recorded deploy succeeded.
- GitHub main branch has responsive marketplace shell, supplier storefront route, global search/category navigation and Playwright responsive tests.
- Supabase currently contains 4 manufacturer rows and 0 products, profiles, supplier accounts, supplier applications, enquiries, RFQs, RFQ targets, supplier quotes, conversations, messages, or saved suppliers.
- All 4 seeded manufacturers are published while marked `unverified`; they are research leads, not verified suppliers.
- No Supabase Edge Functions are deployed.
- Existing schema includes manufacturer/product catalogue, RFQ/targets, buyer/supplier accounts, saved manufacturers, quotations, moderation and product image storage. Live end-to-end behavior has not yet been proven.

## Audit findings to resolve before launch

1. **RFQ submission security has been hardened.** Anonymous execution of the legacy `submit_rfq` RPC and anonymous inserts into `rfqs`/`rfq_targets` are revoked. The authenticated `submit_rfq_for_buyer` RPC validates request fields, requires a buyer account, validates published supplier targets, and creates RFQ targets/conversations atomically. Live privilege checks confirm anonymous users cannot execute either RFQ RPC or insert into RFQ tables; authenticated users can execute the buyer RPC.
2. **Public enquiry and supplier-application abuse controls remain open.** These routes still accept anonymous submissions under narrowly scoped RLS policies and currently rely on an in-memory Express rate limiter. Add shared rate limiting, bot protection, validation, and operational monitoring before launch.
3. **Configuration example is aligned.** `.env.example` now documents the server-side `SUPABASE_ANON_KEY` used by `server.ts`; the browser uses only the Vite publishable key. Both remain subject to RLS. Never expose a service-role secret to the browser.
4. **README has been updated** to describe the buyer/supplier portal, product catalogue, RFQs, quotations, messaging, moderation and deployment setup.
5. **Messaging is implemented but not launch-proven.** Buyer/supplier inboxes now show supplier names, support sending and manual refresh, and attempt read-receipt updates. Database participant policies exist. Realtime behavior, read-receipt persistence, unread indicators and full two-account E2E flows still need tests.
6. **Supplier trust is not launch-ready.** Four existing records are unverified, have no website value in the database, and should not be represented as independently verified. Confirm legal identity, working website/contact, facility, product capabilities, MOQ, capacity, lead times, sample process, export experience and certification evidence. Record source, reviewer, date and scope.
7. **Free hosting is a constraint.** Validate cold starts, sleeping behavior, database limits, storage, backups, abuse protection and recovery before choosing the public launch configuration.

## Workstreams and acceptance gates

### A. Marketplace UX and discovery
- [ ] Audit every public route and navigation link.
- [ ] Complete category, keyword, location and capability search; filters, sorting, pagination and empty/error/loading states.
- [ ] Complete manufacturer profiles and supplier storefronts with clear evidence labels and contact/quotation calls to action.
- [ ] Complete product cards, detail pages, image gallery, specifications, MOQ, samples, lead time, manufacturer link and RFQ CTA.
- [ ] Verify mobile/tablet/desktop layouts and accessibility (keyboard, focus, labels, contrast, semantic headings).
- [ ] Remove placeholder imagery or label illustrative assets clearly; no fabricated products, factory photos, reviews, certifications or claims.

**Pass condition:** All routes and interactions work at 320px through desktop; no broken links, overflow, dead buttons or misleading content.

### B. Buyer experience
- [ ] Signup, email confirmation, sign-in, sign-out, password reset and session expiry.
- [ ] Buyer profile and company details.
- [ ] Save/unsave suppliers and view shortlist.
- [x] Anonymous RFQ RPC execution and anonymous RFQ table inserts revoked; live privilege checks passed.
- [x] Anonymous RFQ RPC execution and anonymous RFQ table inserts revoked; live privilege checks passed.
- [ ] Submit RFQ to 1–5 selected eligible manufacturers with validated quantity/specifications/destination/date using buyer and supplier test identities.
- [ ] Buyer dashboard shows RFQ status, targeted suppliers and received quotations.
- [ ] Buyer can compare quotes and communicate with suppliers.
- [ ] Privacy notice, consent/retention explanation and account deletion/contact process.

**Pass condition:** A test buyer can complete the entire sourcing journey without admin/database intervention.

### C. Supplier experience
- [ ] Supplier signup and application; duplicate company/slug handling.
- [ ] Admin review and approval/rejection with notes.
- [ ] Approved supplier can edit company/storefront details and maintain product listings.
- [ ] Product create/edit/archive, image upload/replacement/deletion and moderation.
- [ ] Supplier sees only RFQs assigned to its manufacturer account.
- [ ] Supplier submits, updates and withdraws quotations; buyer sees correct status and values.
- [ ] Supplier can respond in private conversation without seeing another supplier's quotes or buyer data beyond what is required.

**Pass condition:** A test supplier can be approved, publish products, receive an assigned RFQ and submit a quote with no privilege escalation.

### D. RFQ, quotations and messaging
- [ ] Verify atomic RFQ + target creation and rollback behavior.
- [ ] Enforce published/eligible supplier selection and prevent duplicate targets.
- [ ] Enforce buyer ownership, assigned-supplier access and quote uniqueness at database level.
- [ ] Validate quote currency, positive price, MOQ, lead time, validity date, status transitions and input limits.
- [x] Buyer/supplier conversation panel, message persistence UI, manual refresh and read-receipt update UI implemented (not yet E2E verified).
- [ ] Conversation creation/participant authorization, message persistence, unread/read state and realtime or reliable refresh verified with separate test identities.
- [ ] Email notifications for signup, supplier approval, new RFQ, new quote and new message (with retries and opt-out).
- [ ] Abuse controls: shared server-side rate limits, bot protection, request validation and audit trail for public enquiry and supplier-application endpoints. RFQ submission now requires an authenticated buyer.

**Pass condition:** A complete buyer-to-multiple-supplier-to-quote-to-message workflow passes with at least two supplier test accounts.

### E. Administration and trust operations
- [ ] Secure first-owner admin bootstrap; no public role promotion.
- [ ] Admin dashboard for supplier verification, supplier applications, products, RFQs, quotes, reports and users.
- [ ] Review log with reviewer, timestamp, evidence source, decision and notes.
- [ ] Supplier verification checklist and evidence expiry/re-review dates.
- [ ] Takedown/report process and moderation status controls.
- [ ] Seed content audit: remove, correct or clearly label every unverified record.

**Pass condition:** Admin can review and moderate every marketplace object; every privileged action is authorized server/database-side and auditable.

### F. Security, privacy and reliability
- [ ] Review RLS and grants for every table, view, RPC and storage policy using buyer, supplier A, supplier B, anonymous and admin test identities.
- [ ] Confirm no service-role key or private secret exists in Git history, client bundle, logs or public endpoints.
- [ ] Validate all API inputs, output redaction, CORS, headers, CSRF/session assumptions and error handling.
- [ ] Add shared rate limiting, bot protection, email verification and monitoring.
- [ ] Add backup/restore and incident-response procedures; test a restore.
- [ ] Add privacy notice, terms, supplier terms, acceptable-use, cookie/analytics disclosure, data retention and deletion workflow.
- [ ] Run dependency/security audit, database advisors, performance checks and load tests.
- [ ] Verify health/readiness endpoints and alerting; document deployment rollback.

**Pass condition:** No unresolved critical/high security issues; access-control tests pass; restore and rollback are demonstrated.

### G. Content and supply readiness (before buyers)
- [ ] Verify every live manufacturer independently to a documented standard.
- [ ] Build a credible initial catalogue: target at least 9 verified manufacturers and 20–30 genuine product/capability listings, with geographic/category coverage.
- [ ] Collect permission to display supplier names, logos, factory/product photos and claims.
- [ ] Confirm MOQ, capacity, lead time, sample policy, payment terms, export destinations and shipping/incoterms where relevant.
- [ ] Ensure each listing has current evidence and a last-confirmed date.
- [ ] Prepare internal sourcing operations: response SLA, supplier matching, quote follow-up and dispute/escalation process.

**Pass condition:** No empty catalogue, no invented information, no supplier represented as verified without evidence, and enough verified supply to fulfill the marketplace promise.

### H. QA and launch
- [ ] Unit/integration tests for API and database RPCs.
- [ ] E2E tests for buyer, supplier and admin journeys.
- [ ] Responsive browser tests across mobile/tablet/desktop.
- [ ] Accessibility audit and browser/device compatibility.
- [ ] Test empty, error, slow-network, expired-session, duplicate-submit and malicious-input cases.
- [ ] Production smoke test after deployment; verify database-backed reads and writes.
- [ ] Domain, SSL, analytics/privacy-safe event tracking, support contact and transactional email configured.
- [ ] Final go/no-go review signed off before any buyer outreach.

## Launch rule

Do not acquire clients until all acceptance gates are passed. Build and test with internal test accounts and consenting supplier partners first. "Ready" means the marketplace can complete the buyer, supplier and admin journeys reliably with real, permissioned supplier data—not merely that the homepage looks finished.
