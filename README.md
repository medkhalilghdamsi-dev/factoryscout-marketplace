# FactoryScout Marketplace

A buyer-side apparel sourcing directory for international brands exploring manufacturers in Tunisia and nearby markets.

## MVP
- Responsive manufacturer directory with search and filters.
- Supplier profiles distinguish published claims from independent verification.
- Express API for public directory reads, buyer enquiries and supplier listing applications.
- Supabase/Postgres schema for manufacturers, enquiries and supplier applications.
- Server-side service-role access only; no public table policies.
- GitHub Pages is a static preview only. It does not run the Express API.

## Run locally
Requirements: Node.js 22+ and npm.
```bash
npm install
cp .env.example .env
npm run dev
```
Without Supabase credentials, the directory uses demo profiles. Enquiry and supplier application endpoints return a clear 503 response and do not pretend to store submissions.

## Connect Supabase
1. Create a Supabase project.
2. Run `supabase/schema.sql` in the project's SQL Editor.
3. Set `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in the backend host.
4. Keep the service-role key private. Never add it to Vite variables, frontend code, GitHub Pages, or a committed `.env` file.
5. Deploy this Express application to a Node.js host and point the production domain to that host. GitHub Pages cannot host the API.

The schema enables Row Level Security and deliberately defines no anon/authenticated table policies. The Express server uses the service-role key for limited API operations. Build an authenticated admin workflow before adding management endpoints.

## API
- `GET /api/health` — service status and database configuration.
- `GET /api/manufacturers` — published profiles only.
- `POST /api/enquiries` — validate and store a buyer enquiry.
- `POST /api/supplier-applications` — submit a manufacturer listing request for review.

Submission endpoints apply a basic per-IP in-memory rate limit. Before public traffic, move rate limiting to a shared store, add bot protection, email notifications and abuse monitoring.

## Privacy and trust
- Buyer enquiries and supplier applications are private database records.
- Never expose the Supabase service-role key.
- No profile should be described as audited, certified or independently verified unless evidence has been reviewed and the scope/date recorded.
- Initial profiles are research leads, not endorsements. One regional comparison supplier is outside Tunisia and explicitly labelled.
- Add a privacy notice, retention period, deletion process and responsible contact before accepting real personal data.

## Build
```bash
npm run typecheck
npm run build
NODE_ENV=production npm start
```
