# FactoryScout Marketplace

A free-first B2B discovery marketplace for international buyers sourcing apparel and textile manufacturers in Tunisia and nearby markets.

## Current MVP

- Search and filter supplier profiles by product capability and location.
- Manufacturer profile pages with MOQ, lead-time and evidence notes.
- Clear distinction between supplier-published information and independently verified evidence.
- Structured buyer enquiry form.
- Express API for manufacturer records and enquiries.
- Responsive desktop and mobile layout.
- GitHub Actions build workflow.

## Run locally

Requirements: Node.js 20+ and npm.

```bash
npm install
npm run dev
```

Open http://localhost:3000.

Production build:

```bash
npm run build
NODE_ENV=production npm start
```

## Important data and trust policy

The initial profiles are research leads, not endorsed suppliers. Supplier-published statements are labelled as such. No profile should be described as audited, certified or independently verified unless FactoryScout has reviewed reliable evidence and recorded the scope and date of that review.

The initial directory includes one regional comparison supplier outside Tunisia, explicitly labelled. It is not a Tunisian factory.

## Enquiry storage limitation

The MVP currently writes enquiries to `data/enquiries.json` on the server. This is suitable only for local testing or a controlled demonstration on a persistent disk. It does not send email notifications, provide an admin inbox, or guarantee persistence on ephemeral hosting. Before public launch, connect a managed database, configure access-controlled admin review, add spam protection/rate limits, privacy notice and retention controls, and test backups.

Do not put credentials, API keys, private supplier documents or personal customer data in Git.

## Roadmap

1. Manufacturer claim/listing application and admin approval.
2. Database-backed profiles and enquiry management.
3. Supplier evidence records with source, review date, reviewer and status.
4. Buyer accounts, saved shortlists and comparison exports.
5. Supplier response workflow and quote tracking.
6. Deployment, monitoring, privacy and security hardening.

## Product principle

FactoryScout is not a pay-to-rank directory. Search and comparison should be driven by product fit and transparent evidence. Paid placement, if introduced later, must be disclosed and must not alter verification status.
