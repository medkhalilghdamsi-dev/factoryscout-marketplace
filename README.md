# FactoryScout Marketplace

FactoryScout is a pre-launch B2B apparel-manufacturing sourcing marketplace. It is being built for international brands that want to discover manufacturers, compare capabilities, send structured RFQs to multiple suppliers, receive quotations and communicate in one workspace.

**Launch policy:** Do not acquire buyers or publicly launch until the acceptance gates in [docs/LAUNCH_READINESS.md](docs/LAUNCH_READINESS.md) are passed. Current supplier records are research leads and are not independently verified.

## Product capabilities

### Public marketplace
- Responsive manufacturer directory with keyword, category and location filters.
- Dedicated supplier storefront routes.
- Product catalogue and product discovery filters.
- Supplier comparison and saved-supplier shortlist.
- Public supplier enquiry and multi-supplier RFQ entry points.
- Evidence labels and explicit limitations on supplier-published information.

### Buyer workspace
- Supabase Auth signup, email confirmation, sign-in and sign-out.
- Buyer profile created by the database auth trigger.
- Saved manufacturers.
- Authenticated RFQ submission and RFQ/quotation tracking.
- Private RFQ conversations and messaging with assigned suppliers.

### Supplier workspace
- Supplier account application and pending-review state.
- Admin approval creates a linked manufacturer listing.
- Approved suppliers can submit product listings and upload product images for moderation.
- Assigned RFQs and quotation submission.
- Private RFQ conversations and messaging with buyers.

### Admin foundation
- Supplier application review, approval/rejection and existing-profile claims.
- Private buyer-enquiry and RFQ inboxes with status management.
- Supplier prospect pipeline with official-source links and onboarding statuses.
- Manufacturer evidence review and product moderation.
- Audit history for supplier, product, manufacturer, enquiry and RFQ status changes.
- Admin supplier-quote visibility guarded by an admin-only RLS policy.

## Architecture

- Frontend: React 19, TypeScript, Vite.
- API: Express.
- Database and authentication: Supabase Postgres, Auth, Row Level Security and Storage.
- Hosting: Render Node web service, Frankfurt region.
- Source control and CI: GitHub; CI typechecks/builds and runs Playwright responsive browser tests.

The frontend uses the Supabase publishable key only. The Express API currently uses `SUPABASE_URL` and `SUPABASE_ANON_KEY`; database access is constrained by the project's grants and RLS. Never expose a Supabase service-role key in browser code or Vite environment variables.

## Local development

Requirements: Node.js 22+ and npm.

```bash
npm install
cp .env.example .env
npm run dev
```

Required local environment variables for the API:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Required Vite variables for authenticated browser features:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`

Without Supabase configuration, the public directory falls back to clearly labelled demonstration/research profiles. Authenticated workflows require a configured Supabase project.

## Database

The live Supabase project contains the marketplace schema and recorded migrations. For a fresh project, review and apply the SQL files under `supabase/` in version order; do not assume the initial schema file alone represents the current live database. The first owner must create and confirm their Auth account, then run `supabase/bootstrap_first_admin.sql` manually in the Supabase SQL Editor. See [docs/ADMIN_BOOTSTRAP.md](docs/ADMIN_BOOTSTRAP.md).

Core data includes:
- Manufacturers and products.
- Buyer profiles and supplier accounts/applications.
- RFQs and RFQ supplier targets.
- Supplier quotations.
- Saved manufacturers.
- RFQ conversations and messages.
- Enquiries and moderation records.

RLS is enabled on the marketplace tables. Before launch, test every read/write path as anonymous, buyer, supplier A, supplier B and admin identities. Do not treat the presence of a policy as proof that a complete workflow is secure.

## Browser tests

The GitHub Actions workflow installs Playwright and Chromium, then runs the responsive and interaction regression suite:

```bash
npm install
npm install --no-save @playwright/test
npx playwright install chromium
npx playwright test
```

The suite covers homepage overflow and visibility at mobile, tablet and desktop widths, mobile navigation, supplier storefront and product detail routes, global material search, product-specific RFQ handoff, RFQ eligibility gating, enquiry routing copy, API security headers and public submission rate limits. Authenticated buyer/supplier/admin end-to-end tests with separate test identities are still required.

## Deployment

Render deploys the Express/Vite application using `render.yaml`. The health endpoint is:

```
GET /api/health
```

Production launch requires a custom domain, transactional email, monitoring/alerting, backup and restore validation, shared rate limiting, bot/abuse protection, documented rollback and privacy/legal pages.

## Trust and supplier verification

A published profile is not automatically a verified factory. Before any supplier is labelled verified, retain evidence for:
- Legal business identity and official website/contact details.
- Actual production facility and relevant manufacturing capabilities.
- MOQ, production capacity, lead time and sample process.
- Export experience and destination markets.
- Certification scope, issuer, validity and verification date.
- Permission to publish supplier identity, brand assets, photographs and claims.

Never invent products, factory photographs, certifications, reviews, capacity, prices or export claims. Clearly label supplier-published claims and missing information.

## Pre-launch checklist

The full acceptance plan, technical audit findings and launch gates are maintained in [docs/LAUNCH_READINESS.md](docs/LAUNCH_READINESS.md). Supplier prospects are tracked in [docs/SUPPLIER_PIPELINE.md](docs/SUPPLIER_PIPELINE.md); the verification and contact workflow is in [docs/SUPPLIER_ONBOARDING_PLAYBOOK.md](docs/SUPPLIER_ONBOARDING_PLAYBOOK.md).
