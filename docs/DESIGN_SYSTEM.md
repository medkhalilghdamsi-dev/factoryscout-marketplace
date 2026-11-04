# FactoryScout Premium Minimal — UI/UX specification

**Status:** Locked design direction  
**Version:** 1.0  
**Product:** FactoryScout international B2B apparel-sourcing marketplace

## Design principles

1. **Trust before decoration.** Supplier claims, verification status, MOQ, lead times and evidence must be legible and attributed. Never imply a supplier or product is independently verified unless the underlying review supports that claim.
2. **Premium minimal, not empty.** Use restrained typography, deliberate whitespace, consistent alignment and quiet surfaces while keeping commercially useful information visible.
3. **One system, two modes.** Light and dark themes share identical spacing, typography, components, interaction states and information hierarchy.
4. **Marketplace clarity.** Buyers should understand what they can discover, compare, shortlist, request and track. Suppliers should understand their review status, listings, RFQs and quotations.
5. **Responsive by design.** Mobile is a first-class layout, not a desktop layout compressed to a narrow screen.
6. **Accessible interaction.** Keyboard-visible focus, semantic controls, labels, readable contrast, reduced-motion support and useful empty/error/loading states.

## Visual tokens

| Token | Light | Dark |
|---|---|---|
| Background | `#F7F8F5` | `#111914` |
| Surface | `#FFFFFF` | `#18221C` |
| Raised surface | `#FFFFFF` | `#1D2921` |
| Muted surface | `#EFF2ED` | `#202D24` |
| Primary text | `#17231C` | `#EDF2ED` |
| Secondary text | `#536258` | `#C0CBC1` |
| Muted text | `#77847A` | `#98A69B` |
| Border | `#E1E7E0` | `#2B3A30` |
| Signature accent | Forest `#28553D` | Sage-green `#8FB69A` |
| Accent soft | `#EAF1EB` | `#263B2D` |

Typography: DM Sans for interface and reading; Manrope for display headings and brand moments. Use a 12-column desktop content grid, fluid spacing, 7px / 12px / 18px corner radii, restrained shadows and a consistent 44px minimum interactive target where practical.

## Component system

- **Navigation:** brand, global search, primary destinations, account entry, theme toggle, RFQ action and shortlist. Mobile navigation becomes a clear, accessible disclosure.
- **Buttons:** primary (forest), secondary (surface + border), tertiary/text, destructive, disabled and loading. One clear primary action per content region.
- **Fields:** consistent label, helper text, error state, focus state, input height and spacing. Do not rely on placeholder text as a label.
- **Cards:** consistent surface, border, radius, content padding and hover behavior. Supplier cards show location, information basis, status, categories, MOQ, lead time and actions.
- **Status/evidence:** neutral labels for supplier-published, review required, pending and independently verified. Color is supplementary; wording always carries meaning.
- **Tables:** clear row/column labels, readable horizontal scrolling on small screens, consistent numeric alignment.
- **Dialogs:** restrained overlay, scrollable content, visible close action, focus-visible states and mobile full-width behavior.
- **Feedback:** inline loading, empty, success and error states. Never communicate success before the server confirms it.
- **Theme control:** persistent light/dark preference, system preference on first visit, accessible label and same control in all primary page headers.

## Navigation and information architecture

### Public marketplace
- Suppliers — search, filters, category shortcuts, sorting, comparison and saved shortlist.
- Products — approved product catalogue, search, material/technique filters and product detail.
- How it works — discovery, comparison, evidence and enquiry process.
- For manufacturers — application and onboarding explanation.
- Global actions — account, theme, shortlist and post an RFQ.

### Buyer workspace
- Overview — buyer identity and account state.
- Saved suppliers — shortlist and supplier profile links.
- RFQs — submitted requests, statuses, supplier targets and quotation comparisons.
- Conversations — private buyer/supplier communication.

### Supplier workspace
- Overview — application/approval status and storefront identity.
- Storefront — company details, capabilities and published products.
- Products — submit product, image and commercial details for moderation.
- RFQs — assigned buyer briefs and quotation response.
- Conversations — private communication with buyers.

### Admin workspace
- Review queue — supplier applications and product moderation.
- Marketplace operations — buyer RFQs and enquiries.
- Supplier pipeline — researched prospects and onboarding status.
- Verification — evidence URL, reviewer notes and explicit verification status.
- Audit history — review actions and status transitions.

## Page layout specifications

### 1. Homepage
1. Compact, light global header with brand, search, primary navigation and utility actions.
2. Focused hero: one clear sourcing proposition, one prominent search and restrained category suggestions.
3. Three trust principles with explicit evidence language.
4. Supplier discovery preview with search/filter controls and information-rich supplier cards.
5. Product catalogue preview or honest empty state; never fabricate listings.
6. Three-step sourcing explanation.
7. Manufacturer acquisition CTA and concise footer.

### 2. Supplier directory
- Search and filters stay together and remain usable on mobile.
- Result count and sort controls are visible.
- Supplier cards share a fixed information hierarchy and do not hide MOQ/lead time/evidence.
- Compare tray is reachable but does not obscure essential mobile controls.
- Empty results offer a useful filter reset.

### 3. Product catalogue and product detail
- Catalogue cards prioritize real supplier-submitted imagery, product type, supplier, materials, techniques, MOQ and sample availability.
- Product detail uses a two-column desktop layout and stacked mobile layout.
- Commercial data is explicitly supplier-published; missing values say “Confirm with supplier”.
- RFQ action is prominent but disabled unless the supplier is approved and eligible.

### 4. Supplier storefront
- Header with back navigation, theme and RFQ status.
- Hero identifies the supplier, location and evidence status without invented endorsements.
- Sticky/compact section navigation on desktop; stacked section flow on mobile.
- Overview, capabilities, commercial details, published products and evidence/limitations.
- Persistent, contextual enquiry/RFQ action.

### 5. Buyer workspace
- Account identity and role/status first.
- Saved suppliers and RFQ activity are separate, scannable sections.
- Quote comparison is a semantic table on desktop and horizontally scrollable on mobile.
- Empty states explain how to create the first saved supplier or RFQ.

### 6. Supplier workspace
- Approval status and storefront identity first.
- Product submission form is grouped into product details, production details and imagery.
- Assigned RFQs use readable briefs and a clearly separated quotation editor.
- Distinguish draft, submitted, withdrawn and selected quotation states.

### 7. Admin workspace
- Prioritize actionable review queues and clear entity status.
- Separate supplier application, product moderation, RFQ/enquiry, prospect pipeline and evidence review.
- Make verification evidence and reviewer notes visible before the verification action.
- Audit history is readable and never visually confused with pending tasks.

## Responsive behavior

- 320–390px: single-column cards and forms; compact navigation; no horizontal page overflow; tables scroll inside their own region.
- 640–900px: two-column discovery where space allows; filters wrap cleanly; account and navigation actions remain reachable.
- 1024px+: balanced content width, three-column card grids when card minimum width permits, persistent desktop navigation.
- Respect reduced-motion preference. Ensure focus indicators, labels, touch targets and contrast in both themes.

## Acceptance checklist

- [ ] Theme preference persists across reloads and applies to every route and account workspace.
- [ ] No page or component is unreadable in either theme.
- [ ] No horizontal overflow at 320, 375, 390, 430, 640, 768, 900 and 1280px.
- [ ] Navigation, search, filters, compare, shortlist and RFQ entry remain functional.
- [ ] Supplier and product details retain evidence attribution and commercial caveats.
- [ ] Empty, loading, disabled, success and error states use the same component language.
- [ ] Keyboard focus and reduced-motion behavior are preserved.
- [ ] Typecheck, production build and Playwright responsive tests pass.
