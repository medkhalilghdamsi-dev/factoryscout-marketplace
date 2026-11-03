import express, { type Request, type Response, type NextFunction } from "express";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createServer as createViteServer } from "vite";

const app = express();
const port = Number(process.env.PORT || 3000);
const root = path.dirname(fileURLToPath(import.meta.url));
app.set("trust proxy", 1);
app.use(express.json({ limit: "24kb" }));

type Manufacturer = {
  id: string; name: string; region: string; category: string[]; summary: string;
  capabilities: string[]; moq: string; leadTime: string; evidence: string;
  evidenceNote: string; exportMarkets: string[]; status: string; rfqEnabled: boolean; website?: string;
};
const seed: Manufacturer[] = [
  {id:"les-ateliers-bs",name:"Les Ateliers BS",region:"La Soukra, Ariana",category:["Premium ready-to-wear","Woven","Denim"],summary:"Tunisian garment workshop with a sample room and capabilities across premium ready-to-wear, woven garments and selected embellishment work.",capabilities:["Pattern and sample room","Woven garments","Denim","Pleating","Embroidery"],moq:"100–20,000 pieces (supplier-published range)",leadTime:"Approximately 8 weeks after sample approval (published)",evidence:"Supplier-published",evidenceNote:"Capabilities and figures are based on public supplier information; facility, current capacity and commercial terms have not been independently audited.",exportMarkets:["International export"],status:"Review required",rfqEnabled:false},
  {id:"subli-tunis",name:"SubliTunis",region:"Sousse",category:["Sportswear","Swimwear","Workwear"],summary:"Garment and sublimation workshops with stated experience in sportswear, swimwear, workwear and medical clothing.",capabilities:["Sublimation printing","Sportswear","Swimwear","Leggings","Workwear"],moq:"Not publicly confirmed",leadTime:"Not publicly confirmed",evidence:"Supplier-published",evidenceNote:"Workshop and staffing details are supplier-published. MOQ, sample process, current capacity and certifications require direct confirmation.",exportMarkets:["Export-oriented (supplier-stated)"],status:"Review required"},
  {id:"goldtex",name:"Goldtex",region:"Bizerte",category:["Fashion apparel","Sportswear","Technical apparel"],summary:"Tunisian apparel manufacturer publicly describing fashion, sportswear and technical garment production.",capabilities:["Fashion apparel","Sportswear","Technical apparel"],moq:"Not publicly confirmed",leadTime:"Not publicly confirmed",evidence:"Supplier-published",evidenceNote:"Production scale and certification claims require documentary review. No independent factory audit has been completed by FactoryScout.",exportMarkets:["Not confirmed"],status:"Review required"},
  {id:"atll",name:"ATLL",region:"Casablanca, Morocco",category:["Streetwear","Hoodies","Apparel"],summary:"Moroccan apparel manufacturer included as a regional comparison option, not a Tunisian factory listing.",capabilities:["Hoodies","Embroidery","Garment production"],moq:"200 pieces per model (published)",leadTime:"Not publicly confirmed",evidence:"Supplier-published",evidenceNote:"Public website claims require direct confirmation; no independent audit has been completed by FactoryScout.",exportMarkets:["Not confirmed"],status:"Regional comparison",rfqEnabled:false}
];
const supabaseUrl = process.env.SUPABASE_URL?.replace(/\/$/, "");
const publicApiKey = process.env.SUPABASE_ANON_KEY;
// The anon key is intentionally constrained by Supabase RLS policies.
const databaseReady = Boolean(supabaseUrl && publicApiKey);
const rateBuckets = new Map<string, { count: number; resetAt: number }>();

function rateLimit(req: Request, res: Response, next: NextFunction) {
  const key = req.ip || "unknown";
  const now = Date.now();
  const current = rateBuckets.get(key);
  if (!current || current.resetAt <= now) rateBuckets.set(key, { count: 1, resetAt: now + 15 * 60 * 1000 });
  else if (current.count >= 8) return res.status(429).json({ error: "Too many submissions. Please try again later." });
  else current.count++;
  next();
}
async function supabase(table: string, options: { method?: string; query?: string; body?: unknown }) {
  if (!databaseReady) throw new Error("Database is not configured");
  const response = await fetch(`${supabaseUrl}/rest/v1/${table}${options.query ? `?${options.query}` : ""}`, {
    method: options.method || "GET",
    headers: { apikey: publicApiKey!, Authorization: `Bearer ${publicApiKey}`, "Content-Type": "application/json", Prefer: "return=representation" },
    ...(options.body ? { body: JSON.stringify(options.body) } : {})
  });
  if (!response.ok) {
    const detail = await response.text();
    console.error(`Supabase ${table} request failed:`, response.status, detail.slice(0, 500));
    throw new Error("Database request failed");
  }
  const raw = await response.text();
  return raw ? JSON.parse(raw) : null;
}
function textField(value: unknown, max: number) {
  return typeof value === "string" && value.trim().length > 0 && value.trim().length <= max;
}
function optionalText(value: unknown, max: number) {
  return value == null || (typeof value === "string" && value.trim().length <= max);
}
function mapManufacturer(row: any): Manufacturer {
  return { id: row.id, name: row.name, region: row.region, category: row.category || [], summary: row.summary || "",
    capabilities: row.capabilities || [], moq: row.moq || "Not publicly confirmed", leadTime: row.lead_time || "Not publicly confirmed",
    evidence: row.evidence || "Supplier-published", evidenceNote: row.evidence_note || "", exportMarkets: row.export_markets || [],
    status: row.status || "Review required", rfqEnabled: (Array.isArray(row.supplier_accounts) ? row.supplier_accounts : row.supplier_accounts ? [row.supplier_accounts] : []).some((account: any) => account.status === "approved"), ...(row.website ? { website: row.website } : {}) };
}
app.get("/api/health", (_req, res) => res.json({ status: "ok", service: "FactoryScout Marketplace", version: "0.2.0", database: databaseReady ? "configured" : "not_configured" }));
app.get("/api/manufacturers", async (_req, res) => {
  if (!databaseReady) return res.json(seed);
  try {
    const rows = await supabase("manufacturers", { query: "select=*,supplier_accounts(status)&is_published=eq.true&order=name.asc" });
    return res.json(Array.isArray(rows) ? rows.map(mapManufacturer) : []);
  } catch { return res.status(503).json({ error: "Manufacturer directory is temporarily unavailable." }); }
});
app.post("/api/enquiries", rateLimit, async (req, res) => {
  const { manufacturerId, name, email, company, product, quantity, details, website } = req.body ?? {};
  if (website) return res.status(201).json({ ok: true });
  if (!textField(manufacturerId, 100) || !textField(name, 120) || !textField(email, 254) || !textField(product, 160) ||
      !optionalText(company, 160) || !optionalText(quantity, 80) || !optionalText(details, 3000) ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) return res.status(400).json({ error: "Please check the required fields and try again." });
  if (!databaseReady) return res.status(503).json({ error: "Enquiry service is not configured yet. Your details have not been stored." });
  try {
    const rows = await supabase("manufacturers", { query: `select=id&id=eq.${encodeURIComponent(manufacturerId.trim())}&is_published=eq.true` });
    if (!Array.isArray(rows) || rows.length === 0) return res.status(400).json({ error: "This manufacturer is not currently accepting enquiries." });
    const inserted = await supabase("enquiries", { method: "POST", body: { manufacturer_id: manufacturerId.trim(), name: name.trim(), email: email.trim(),
      company: String(company || "").trim(), product: product.trim(), quantity: String(quantity || "").trim(), details: String(details || "").trim() } });
    const record = Array.isArray(inserted) ? inserted[0] : null;
    return res.status(201).json({ ok: true, id: record?.id });
  } catch { return res.status(503).json({ error: "We could not save your enquiry. Please try again later." }); }
});
app.get("/api/products", async (_req, res) => {
  if (!databaseReady) return res.json([]);
  try {
    const rows = await supabase("products", { query: "select=*,manufacturers(name,region)&status=eq.published&manufacturers.is_published=eq.true&order=created_at.desc" });
    return res.json(Array.isArray(rows) ? rows : []);
  } catch { return res.status(503).json({ error: "Product catalogue is temporarily unavailable." }); }
});
app.post("/api/supplier-applications", rateLimit, async (req, res) => {
  const { company, website, location, products, moq, leadTime, evidence, contactPage, contactName, honeypot } = req.body ?? {};
  if (honeypot) return res.status(201).json({ ok: true });
  if (!textField(company, 180) || !textField(location, 160) || !textField(products, 3000) || !optionalText(website, 300) ||
      !optionalText(moq, 120) || !optionalText(leadTime, 120) || !optionalText(evidence, 3000) ||
      !optionalText(contactPage, 300) || !optionalText(contactName, 120)) return res.status(400).json({ error: "Please complete the required fields and check their length." });
  if (!databaseReady) return res.status(503).json({ error: "Supplier applications are not configured yet. Your details have not been stored." });
  try {
    await supabase("supplier_applications", { method: "POST", body: { company: company.trim(), website: String(website || "").trim() || null,
      location: location.trim(), products: products.trim(), moq: String(moq || "").trim() || null, lead_time: String(leadTime || "").trim() || null,
      evidence: String(evidence || "").trim() || null, contact_page: String(contactPage || "").trim() || null, contact_name: String(contactName || "").trim() || null } });
    return res.status(201).json({ ok: true, message: "Your listing request has been submitted for review." });
  } catch { return res.status(503).json({ error: "We could not save your application. Please try again later." }); }
});
async function start() {
  if (process.env.RENDER === "true" || process.env.NODE_ENV === "production") {
    const dist = path.resolve(process.cwd(), "dist");
    app.use(express.static(dist));
    app.get("*", (_req, res) => res.sendFile(path.join(dist, "index.html")));
  } else {
    const vite = await createViteServer({ server: { middlewareMode: true }, appType: "spa" });
    app.use(vite.middlewares);
  }
  app.listen(port, "0.0.0.0", () => console.log(`FactoryScout listening on ${port}`));
}
start().catch(error => { console.error(error); process.exit(1); });
