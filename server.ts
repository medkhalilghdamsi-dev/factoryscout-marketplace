import express from "express";
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";
import { randomUUID } from "node:crypto";
import { createServer as createViteServer } from "vite";

const app = express();
const port = Number(process.env.PORT || 3000);
const root = path.dirname(fileURLToPath(import.meta.url));
const dataDir = path.join(root, "data");
fs.mkdirSync(dataDir, { recursive: true });
app.use(express.json({ limit: "32kb" }));

const manufacturers = [
  {id:"les-ateliers-bs",name:"Les Ateliers BS",region:"La Soukra, Ariana",category:["Premium ready-to-wear","Woven","Denim"],summary:"Tunisian garment workshop with a sample room and capabilities across premium ready-to-wear, woven garments and selected embellishment work.",capabilities:["Pattern and sample room","Woven garments","Denim","Pleating","Embroidery"],moq:"100–20,000 pieces (supplier-published range)",leadTime:"Approximately 8 weeks after sample approval (published)",evidence:"Supplier-published",evidenceNote:"Capabilities and figures are based on public supplier information; facility, current capacity and commercial terms have not been independently audited.",exportMarkets:["International export"],status:"Review required"},
  {id:"subli-tunis",name:"SubliTunis",region:"Sousse",category:["Sportswear","Swimwear","Workwear"],summary:"Garment and sublimation workshops with stated experience in sportswear, swimwear, workwear and medical clothing.",capabilities:["Sublimation printing","Sportswear","Swimwear","Leggings","Workwear"],moq:"Not publicly confirmed",leadTime:"Not publicly confirmed",evidence:"Supplier-published",evidenceNote:"Workshop and staffing details are supplier-published. MOQ, sample process, current capacity and certifications require direct confirmation.",exportMarkets:["Export-oriented (supplier-stated)"],status:"Review required"},
  {id:"goldtex",name:"Goldtex",region:"Bizerte",category:["Fashion apparel","Sportswear","Technical apparel"],summary:"Tunisian apparel manufacturer publicly describing fashion, sportswear and technical garment production.",capabilities:["Fashion apparel","Sportswear","Technical apparel"],moq:"Not publicly confirmed",leadTime:"Not publicly confirmed",evidence:"Supplier-published",evidenceNote:"Production scale and certification claims require documentary review. No independent factory audit has been completed by FactoryScout.",exportMarkets:["Not confirmed"],status:"Review required"},
  {id:"atll",name:"ATLL",region:"Casablanca, Morocco",category:["Streetwear","Hoodies","Apparel"],summary:"Moroccan apparel manufacturer included as a regional comparison option, not a Tunisian factory listing.",capabilities:["Hoodies","Embroidery","Garment production"],moq:"200 pieces per model (published)",leadTime:"Not publicly confirmed",evidence:"Supplier-published",evidenceNote:"Public website claims require direct confirmation; no independent audit has been completed by FactoryScout.",exportMarkets:["Not confirmed"],status:"Regional comparison"}
];

app.get("/api/health", (_req,res)=>res.json({status:"ok",service:"FactoryScout Marketplace",version:"0.1.0"}));
app.get("/api/manufacturers", (_req,res)=>res.json(manufacturers));
app.post("/api/enquiries", (req,res)=>{
  const {manufacturerId,name,email,company,product,quantity,details} = req.body ?? {};
  if (![manufacturerId,name,email,product].every(v=>typeof v==="string" && v.trim().length>0)) return res.status(400).json({error:"Missing required fields"});
  if (!manufacturers.some(m=>m.id===manufacturerId)) return res.status(400).json({error:"Unknown manufacturer"});
  if (name.length>120 || email.length>254 || company?.length>160 || product.length>160 || quantity?.length>80 || details?.length>3000 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return res.status(400).json({error:"Invalid email or field length"});
  const record = {id:randomUUID(),manufacturerId,name:name.trim(),email:email.trim(),company:String(company||"").trim(),product:product.trim(),quantity:String(quantity||"").trim(),details:String(details||"").trim(),createdAt:new Date().toISOString()};
  const file = path.join(dataDir,"enquiries.json");
  let current: unknown[] = [];
  if (fs.existsSync(file)) { try { current = JSON.parse(fs.readFileSync(file,"utf8")); if (!Array.isArray(current)) current=[]; } catch { return res.status(500).json({error:"Enquiry storage is unavailable"}); } }
  current.push(record);
  fs.writeFileSync(file,JSON.stringify(current,null,2),{mode:0o600});
  res.status(201).json({ok:true,id:record.id});
});

async function start() {
  if (process.env.NODE_ENV === "production") {
    const dist = path.join(root,"dist");
    app.use(express.static(dist));
    app.get("*",(_req,res)=>res.sendFile(path.join(dist,"index.html")));
  } else {
    const vite = await createViteServer({server:{middlewareMode:true},appType:"spa"});
    app.use(vite.middlewares);
  }
  app.listen(port,"0.0.0.0",()=>console.log(`FactoryScout listening on ${port}`));
}
start().catch(error=>{console.error(error);process.exit(1);});
