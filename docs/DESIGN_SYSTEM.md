# FactoryScout Premium Minimal Design System

**Status:** Implemented in the application styles and theme controls  
**Product:** International B2B apparel manufacturing discovery and sourcing marketplace  
**Design direction:** Premium minimal; clean, information-rich, evidence-led  
**Signature accent:** Forest green  
**Themes:** Light and dark, user-selectable and persisted in the browser

## 1. Design principles

1. **Clarity before decoration.** Supplier capability, commercial details and evidence status take priority over promotional graphics.
2. **Premium restraint.** Neutral surfaces, controlled green accents, consistent spacing, restrained shadows and clear typography.
3. **Trust is visible.** Supplier-published information must remain distinguishable from independently verified information.
4. **Responsive by default.** Every primary workflow must work from 320px mobile widths through desktop.
5. **Accessible interaction.** Keyboard-visible focus, readable contrast, semantic labels and sufficiently large touch targets.

## 2. Visual tokens

### Colour

| Token | Light theme | Dark theme | Usage |
|---|---|---|---|
| Forest | #174B35 | #174B35 | Primary brand and navigation |
| Forest deep | #102B1D | #102B1D | Hero and footer |
| Forest secondary | #236344 | #236344 | Hover and secondary emphasis |
| Accent | #2F7650 | #8FBD9B | Primary actions and links |
| Accent soft | #E8F1E9 | #20392A | Chips and selected states |
| Page | #F5F7F4 | #101A14 | Main canvas |
| Surface | #FFFFFF | #17251C | Cards and dialogs |
| Text | #18271F | #E7EEE8 | Primary text |
| Muted | #68786D | #A5B4A8 | Supporting text |
| Border | #DFE7E0 | #2B3B30 | Dividers and outlines |

### Shape, depth and layout

- Standard card/dialog radius: 12px (compact controls: 7px).
- Content maximum width: 1,360px.
- Card shadow: subtle green-tinted shadow in light mode; restrained black shadow in dark mode.
- Spacing: 4px base rhythm; section spacing scales with viewport.
- Breakpoints: compact mobile up to 420px; mobile/tablet up to 760px; tablet up to 1,100px; wide desktop above 1,500px.

### Typography

- Primary UI: DM Sans.
- Display and brand headings: Manrope.
- Headings use tight tracking and responsive clamp sizing.
- Labels and evidence metadata use compact uppercase styling with sufficient contrast.

## 3. Component rules

- **Primary button:** forest-green fill, white label, clear hover and disabled states.
- **Secondary button:** transparent or neutral surface with a visible border.
- **Search and filter controls:** consistent heights, neutral surfaces, visible focus and mobile stacking.
- **Supplier card:** illustrative image clearly labelled; location, evidence, categories, status, MOQ, lead time and actions.
- **Evidence pill:** text status is always visible; colour never acts as the only status signal.
- **Product card:** supplier attribution, product type, evidence basis, materials, techniques, MOQ, sample and lead-time details.
- **Dialog/form:** constrained width, scrollable on short screens, one-column form layout on mobile.
- **Shortlist tray:** fixed above mobile safe area, wraps controls and never obscures essential content.
- **Theme switch:** available on marketplace, supplier storefront and product detail navigation; preference is persisted locally.

## 4. Navigation

### Marketplace
- Brand/home
- Global search
- Suppliers
- Products
- How it works
- For manufacturers
- Account
- Theme switch
- Post a request
- Shortlist

A horizontally scrollable category rail provides fast discovery without replacing the main navigation.

### Supplier storefront
- Brand/home
- Back to suppliers
- Theme switch
- Request a quote (only when the supplier is enabled for RFQs)

### Product detail
- Brand/home
- Back to product catalogue
- Theme switch
- Request this product (only when its supplier is enabled for RFQs)

## 5. Page layouts

1. **Marketplace home:** sticky navigation, category rail, sourcing hero/search, sourcing principles, supplier discovery, catalogue, process explanation, manufacturer CTA and footer.
2. **Supplier directory:** searchable/filterable responsive card grid with sort, save and compare actions.
3. **Supplier storefront:** editorial supplier header, capability overview, commercial information, product listings, evidence disclosure and enquiry/RFQ CTA.
4. **Product catalogue:** search, category/sample filters, sort and responsive product grid; honest empty state when no approved products exist.
5. **Product detail:** breadcrumb, product visual, supplier attribution, specifications, materials, techniques, evidence and gated RFQ action.
6. **Account workspaces:** retain the existing buyer/supplier/admin workflows; apply the same tokens, surfaces, typography, focus and responsive rules.
7. **Dialogs:** supplier enquiry, multi-supplier RFQ, supplier application and comparison; forms stack on mobile and retain clear validation states.

## 6. Responsive acceptance criteria

- No horizontal page overflow at 320px.
- Header actions remain reachable; navigation collapses cleanly.
- Search and filter controls stack instead of shrinking below usable widths.
- Supplier and product cards become one column on narrow mobile.
- Comparison and RFQ dialogs fit the viewport and scroll internally.
- Touch targets remain comfortably tappable.
- Theme selection remains consistent when navigating between marketplace, product and supplier routes.

## 7. Trust and content constraints

- Never label a supplier verified or audited unless evidence supports that status.
- Keep supplier-published claims attributed to their source.
- Do not fabricate products, certifications, MOQs, lead times or capacity.
- Keep disabled RFQ actions explicit about supplier onboarding status.
