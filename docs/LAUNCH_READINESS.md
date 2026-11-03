# FactoryScout — Pre-Launch Readiness Plan

**Policy:** No buyer acquisition, paid promotion, or public launch until every launch gate below is passed. The site may be used internally for QA and supplier verification before then.

## Product promise

FactoryScout is an international apparel-manufacturing sourcing marketplace. Buyers discover manufacturers and product capabilities, compare suppliers, send one request to multiple factories, receive comparable quotations, and communicate with suppliers. Suppliers maintain a company storefront, submit products for moderation, receive relevant RFQs, and submit quotations. Administrators verify claims and control marketplace quality.

## Current verified baseline (2026-11-03)

- React 19 + Vite frontend, Express API, Supabase Postgres/Auth/Storage, Render web service.
- Render service: `factoryscout-marketplace`, Frankfurt, free plan; the latest confirmed live deployment at the time of this audit is commit `52d5750` (2026-11-03 16:12 UTC). This includes the supplier prospect pipeline UI. New API middleware hardening and additional tests are on GitHub main after that deployment and are pending a fresh Render deployment confirmation; do not assume they are live until the deployed commit matches.
- GitHub main branch has responsive marketplace shell, supplier storefront route, global search/category navigation and Playwright responsive tests.
- Live Supabase counts: 4 manufacturer rows, 5 researched supplier prospects, 0 products, 0 approved/pending supplier accounts, 0 supplier applications, 0 enquiries, 0 RFQs, 0 supplier quotes and 0 messages. There are also 0 Auth users, 0 profiles and 0 admins; the guarded first-admin bootstrap is prepared in `supabase/bootstrap_first_admin.sql`, but the owner must first create and confirm their account and run it manually. The prospects are private admin research records, not marketplace suppliers.
- All 4 seeded manufacturer profiles are published while marked `unverified`; they are research leads, not verified suppliers. Their public API records correctly expose `rfqEnabled: false`.
- No Supabase Edge Functions are deployed.
- Existing schema includes manufacturer/product catalogue, RFQ/targets, buyer/supplier accounts, saved manufacturers, quotations, moderation and product image storage. Live end-to-end behavior has not yet been proven.

## Audit findings to resolve before launch

1. **RFQ submission permissions and validation are hardened, but the live journey still needs E2E testing.** Anonymous execution of the legacy `submit_rfq` RPC and anonymous inserts into `rfqs`/`rfq_targets` are revoked. The authenticated `submit_rfq_for_buyer` RPC validates request fields, requires a buyer account, validates published supplier targets, and creates RFQ targets/conversations atomically. The required authenticated insert grants are now present and the RLS policies restrict those writes to buyer accounts. Live privilege checks confirm anonymous users cannot insert into RFQ tables or execute either RFQ RPC.
2. **Public enquiry and supplier-application abuse controls remain open.** These routes still accept anonymous submissions under narrowly scoped RLS policies. The Express limiter now has per-IP/per-endpoint 8-per-15-minute limits, `Retry-After`, bounded in-memory storage and honeypot handling; this is not shared across multiple instances or restarts. Add durable/shared rate limiting, bot protection (e.g. verified challenge), email verification where appropriate, and operational monitoring before launch.
3. **Configuration example is aligned.** `.env.example` now documents the server-side `SUPABASE_ANON_KEY` used by `server.ts`; the browser uses only the Vite publishable key. Both remain subject to RLS. Never expose a service-role secret to the browser.
4. **README has been updated** to describe the buyer/supplier portal, product catalogue, RFQs, quotations, messaging, moderation and deployment setup.
5. **Admin review audit trail is implemented.** Database triggers record supplier-account status changes, product moderation changes and manufacturer verification/publication changes. Only admins can read the event log; direct client writes are revoked. The admin workspace displays the latest 30 events with actor, timestamp and before/after state.
6. **Quote selection is now implemented but not E2E-proven.** Buyers can select one supplier from the quotation comparison; the selected factory sees the decision and its quote is locked against edits. Database RLS, unique selection index, and authenticated invoker RPC have been verified.
7. **Messaging is implemented but not launch-proven.** Buyer/supplier inboxes now show supplier names, support sending and manual refresh, and attempt read-receipt updates. Message inserts are limited to conversation ID, sender ID and body; updates are limited to `read_at`. Database participant policies exist. Realtime behavior, read-receipt persistence, unread indicators and full two-account E2E flows still need tests.
8. **Supplier trust is not launch-ready.** Four existing records are unverified, have no website value in the database, and should not be represented as independently verified. Confirm legal identity, working website/contact, facility, product capabilities, MOQ, capacity, lead times, sample process, export experience and certification evidence. Record source, reviewer, date and scope.
9. **Free hosting is a constraint.** Validate cold starts, sleeping behavior, database limits, storage, backups, abuse protection and recovery before choosing the public launch configuration.

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
- [ ] Submit RFQ to 1–5 selected eligible manufacturers with validated quantity/specifications/destination/date using buyer and supplier test identities.
- [ ] Buyer dashboard shows RFQ status, targeted suppliers and received quotations.
- [x] Shareable product detail pages show supplier-published specifications, materials, techniques, MOQ, samples and lead time; product-specific RFQ handoff is covered by a responsive browser test.
- [x] Supplier storefront product listings link to their shareable product detail pages.
- [x] Global search routes matching product-name, material, technique and supplier queries to published product results; other queries filter the supplier directory.
- [x] Buyer can compare quotations and select one supplier; supplier sees the decision and cannot edit the selected quote (database permissions and uniqueness checks passed; E2E still pending).
- [ ] Buyer can communicate with suppliers and confirm next steps.
- [ ] Privacy notice, consent/retention explanation and account deletion/contact process.

**Pass condition:** A test buyer can complete the entire sourcing journey without admin/database intervention.

### C. Supplier experience
- [ ] Supplier signup and application; duplicate company/slug handling.
- [ ] Admin review and approval/rejection with notes.
- [ ] Approved supplier can edit company/storefront details and maintain product listings.
- [ ] Product create/edit/archive, image upload/replacement/deletion and moderation.
- [ ] Supplier sees only RFQs assigned to its manufacturer account.
- [x] Supplier can submit, update and withdraw quotations; buyer sees current status and values (database-backed controls; E2E pending).
- [x] Suppliers can set quotation validity dates; buyers see expiry and cannot select an expired quotation (RPC guard added).
- [ ] Automatic buyer/supplier expiry notifications and quote renewal reminders.
- [x] Supplier sees buyer quote-selection decisions and selected quotations are locked against supplier edits (database policy verified).
- [ ] Supplier can respond in private conversation without seeing another supplier's quotes or buyer data beyond what is required.

**Pass condition:** A test supplier can be approved, publish products, receive an assigned RFQ and submit a quote with no privilege escalation.

### D. RFQ, quotations and messaging
- [ ] Verify atomic RFQ + target creation and rollback behavior.
- [ ] Enforce published/eligible supplier selection and prevent duplicate targets.
- [x] Enforce buyer ownership, assigned-supplier access and quote uniqueness at database level for RFQ targets and supplier quotes.
- [x] Enforce one selected supplier per RFQ; selection is transactional and limited to the owning buyer account.
- [ ] Validate quote currency, positive price, MOQ, lead time, validity date, status transitions and input limits.
- [x] Buyer/supplier conversation panel, message persistence UI, manual refresh and read-receipt update UI implemented (not yet E2E verified).
- [x] Conversation/message table access is participant-scoped; message creation and read-receipt updates have column-level grants.
- [ ] Conversation creation/participant authorization, message persistence, unread/read state and realtime or reliable refresh verified with separate test identities.
- [ ] Email notifications for signup, supplier approval, new RFQ, new quote and new message (with retries and opt-out).
- [ ] Abuse controls: shared server-side rate limits, bot protection, request validation and audit trail for public enquiry and supplier-application endpoints. RFQ submission now requires an authenticated buyer.

**Pass condition:** A complete buyer-to-multiple-supplier-to-quote-to-message workflow passes with at least two supplier test accounts.

### E. Administration and trust operations
- [ ] Complete first-owner bootstrap: owner creates and confirms their account, then runs `supabase/bootstrap_first_admin.sql` in the Supabase SQL Editor. Guarded one-time script is prepared; no public role promotion exists.
- [ ] Admin dashboard for supplier verification, supplier applications, products, RFQs, quotes, reports and users.
- [ ] Review log with reviewer, timestamp, evidence source, decision and notes.
- [x] Admin verification queue supports claim review, evidence review and independent-verification decisions; the final status requires a public evidence URL and reviewer note, and changes are recorded in the audit log.
- [ ] Formal verification checklist, evidence expiry/re-review dates and scheduled re-verification.
- [ ] Takedown/report process and moderation status controls.
- [ ] Seed content audit: remove, correct or clearly label every unverified record.

**Pass condition:** Admin can review and moderate every marketplace object; every privileged action is authorized server/database-side and auditable.

### F. Security, privacy and reliability
- [ ] Review RLS and grants for every table, view, RPC and storage policy using buyer, supplier A, supplier B, anonymous and admin test identities.
- [ ] Confirm no service-role key or private secret exists in Git history, client bundle, logs or public endpoints.
- [ ] Validate all API inputs, output redaction, CORS, headers, CSRF/session assumptions and error handling.
- [ ] Replace the in-memory public-form limiter with durable/shared rate limiting; add bot protection, email verification and monitoring.
- [x] Add baseline HTTP security headers (`nosniff`, frame denial, strict-origin referrer policy, restrictive permissions policy), disable Express fingerprinting, and bound in-memory rate-limit bucket growth; regression tests added and awaiting CI/deployment confirmation.
- [ ] Add backup/restore and incident-response procedures; test a restore.
- [ ] Add privacy notice, terms, supplier terms, acceptable-use, cookie/analytics disclosure, data retention and deletion workflow.
- [ ] Run dependency/security audit, database advisors, performance checks and load tests.
- [ ] Reduce the current 529 KB minified application chunk through code splitting and recheck real-device performance.
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
- [ ] Unit/integration tests for API and database RPCs; authenticated RFQ/quote/message journeys still need test identities.
- [ ] E2E tests for buyer, supplier and admin journeys.
- [x] Responsive browser tests across eight mobile/tablet/desktop viewports; product detail, storefront-to-product navigation, global material search and product-specific RFQ handoff are covered.
- [x] API security-header and public-form rate-limit regression tests passed in GitHub Actions.
- [ ] Accessibility audit and browser/device compatibility.
- [ ] Test empty, error, slow-network, expired-session, duplicate-submit and malicious-input cases.
- [ ] Production smoke test after deployment; verify database-backed reads and writes.
- [ ] Domain, SSL, analytics/privacy-safe event tracking, support contact and transactional email configured.
- [ ] Final go/no-go review signed off before any buyer outreach.

## Launch rule

Do not acquire clients until all acceptance gates are passed. Build and test with internal test accounts and consenting supplier partners first. "Ready" means the marketplace can complete the buyer, supplier and admin journeys reliably with real, permissioned supplier data—not merely that the homepage looks finished.
