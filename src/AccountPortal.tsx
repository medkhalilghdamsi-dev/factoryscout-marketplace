import { useEffect, useState } from "react";
import { type Session, type User } from "@supabase/supabase-js";
import { supabase } from "./supabaseClient";
import MessagingPanel from "./MessagingPanel";


type Profile = { id:string; email:string|null; full_name:string; account_type:"buyer"|"supplier"; role:"user"|"admin" };
type SupplierAccount = { id:string; owner_id:string; manufacturer_id:string|null; company_name:string; slug:string; website:string|null; location:string; about:string; status:"pending"|"approved"|"rejected" };

const blankProduct = { name:"", product_type:"Streetwear", description:"", materials:"", techniques:"", minimum_order:"", sample_available:false, lead_time_days:"", image_url:"" };
const slugify = (value:string) => value.toLowerCase().trim().normalize("NFKD").replace(/[\u0300-\u036f]/g,"").replace(/[^a-z0-9]+/g,"-").replace(/^-|-$/g,"").slice(0,90);

export default function AccountPortal() {
  const [session,setSession] = useState<Session|null>(null);
  const [user,setUser] = useState<User|null>(null);
  const [profile,setProfile] = useState<Profile|null>(null);
  const [supplier,setSupplier] = useState<SupplierAccount|null>(null);
  const [open,setOpen] = useState(false);
  const [mode,setMode] = useState<"signin"|"signup">("signin");
  const [busy,setBusy] = useState(false);
  const [message,setMessage] = useState("");
  const [email,setEmail] = useState("");
  const [password,setPassword] = useState("");
  const [fullName,setFullName] = useState("");
  const [accountType,setAccountType] = useState<"buyer"|"supplier">("buyer");
  const [company,setCompany] = useState({company_name:"",website:"",location:"",about:"",contact_name:""});
  const [product,setProduct] = useState(blankProduct);
  const [uploadingImage,setUploadingImage] = useState(false);
  const [adminSuppliers,setAdminSuppliers] = useState<any[]>([]);
  const [adminProducts,setAdminProducts] = useState<any[]>([]);
  const [savedManufacturers,setSavedManufacturers] = useState<any[]>([]);
  const [buyerRfqs,setBuyerRfqs] = useState<any[]>([]);
  const [supplierRfqs,setSupplierRfqs] = useState<any[]>([]);
  const [quoteDrafts,setQuoteDrafts] = useState<Record<string,{unit_price:string;currency:string;minimum_order:string;lead_time_days:string;sample_available:boolean;notes:string}>>({});

  const loadAccount = async (current:User|null) => {
    setUser(current);
    setProfile(null);
    setSupplier(null);
    setSavedManufacturers([]);
    setBuyerRfqs([]);
    setSupplierRfqs([]);
    if (!current || !supabase) return;
    const [p,s,saved] = await Promise.all([
      supabase.from("profiles").select("id,email,full_name,account_type,role").eq("id",current.id).maybeSingle(),
      supabase.from("supplier_accounts").select("*").eq("owner_id",current.id).maybeSingle(),
      supabase.from("saved_manufacturers").select("manufacturer_id,manufacturers(name,region)").eq("user_id",current.id).order("created_at",{ascending:false})
    ]);
    if (p.error) setMessage("Your account profile could not be loaded. Please refresh.");
    else setProfile(p.data as Profile|null);
    if (s.error && s.error.code !== "PGRST116") setMessage("Supplier workspace could not be loaded.");
    else setSupplier(s.data as SupplierAccount|null);
    if (!saved.error) setSavedManufacturers(saved.data || []);
    if (p.data?.account_type === "buyer") {
      const {data,error} = await supabase.from("rfqs").select("*,rfq_targets(manufacturer_id),supplier_quotes(id,manufacturer_id,rfq_targets(manufacturers(name)),unit_price,currency,minimum_order,lead_time_days,sample_available,notes,status,created_at),rfq_quote_decisions(manufacturer_id,status)").eq("buyer_id",current.id).order("created_at",{ascending:false});
      if (!error) setBuyerRfqs(data || []);
    }
    if (s.data?.status === "approved" && s.data?.manufacturer_id) {
      const {data,error} = await supabase.from("rfqs").select("*,rfq_targets!inner(manufacturer_id),rfq_quote_decisions(manufacturer_id,status),supplier_quotes(id,manufacturer_id,unit_price,currency,minimum_order,lead_time_days,sample_available,notes,status,updated_at)").eq("rfq_targets.manufacturer_id",s.data.manufacturer_id).order("created_at",{ascending:false});
      if (!error) setSupplierRfqs(data || []);
    }
  };

  useEffect(() => {
    if (!supabase) return;
    supabase.auth.getSession().then(({data}) => { setSession(data.session); void loadAccount(data.session?.user ?? null); });
    const {data:{subscription}} = supabase.auth.onAuthStateChange((_event,next) => {
      setSession(next);
      void loadAccount(next?.user ?? null);
    });
    return () => subscription.unsubscribe();
  }, []);

  const loadAdminData = async () => {
    if (!supabase) return;
    const [s,p] = await Promise.all([
      supabase.from("supplier_accounts").select("id,company_name,location,website,about,slug,created_at").eq("status","pending").order("created_at",{ascending:true}),
      supabase.from("products").select("id,name,product_type,manufacturer_id,created_at").eq("status","pending").order("created_at",{ascending:true})
    ]);
    if (!s.error) setAdminSuppliers(s.data || []);
    if (!p.error) setAdminProducts(p.data || []);
  };
  useEffect(() => { if (profile?.role === "admin") void loadAdminData(); }, [profile?.id,profile?.role]);

  const approveSupplier = async (id:string) => {
    if (!supabase) return;
    setBusy(true); setMessage("");
    const {error} = await supabase.rpc("admin_approve_supplier_account",{p_supplier_account_id:id});
    if (error) setMessage(error.message);
    else { setMessage("Supplier approved and manufacturer listing created."); await loadAdminData(); }
    setBusy(false);
  };
  const rejectSupplier = async (id:string) => {
    if (!supabase) return;
    setBusy(true);
    const {error} = await supabase.from("supplier_accounts").update({status:"rejected"}).eq("id",id);
    if (error) setMessage(error.message); else { setMessage("Supplier application rejected."); await loadAdminData(); }
    setBusy(false);
  };
  const moderateProduct = async (id:string,status:"published"|"rejected") => {
    if (!supabase) return;
    setBusy(true);
    const {error} = await supabase.from("products").update({status}).eq("id",id);
    if (error) setMessage(error.message); else { setMessage(status==="published"?"Product published.":"Product rejected."); await loadAdminData(); }
    setBusy(false);
  };

  const runAuth = async (event:React.FormEvent) => {
    event.preventDefault();
    if (!supabase) return;
    setBusy(true); setMessage("");
    try {
      if (mode === "signup") {
        const {data,error} = await supabase.auth.signUp({email:email.trim(),password,options:{data:{full_name:fullName.trim(),account_type:accountType}}});
        if (error) throw error;
        if (!data.session) setMessage("Account created. Check your email to confirm your address, then sign in.");
        else setMessage("Your account is ready.");
      } else {
        const {error} = await supabase.auth.signInWithPassword({email:email.trim(),password});
        if (error) throw error;
        setMessage("You're signed in.");
      }
    } catch (e) { setMessage(e instanceof Error ? e.message : "Authentication failed. Please try again."); }
    finally { setBusy(false); }
  };

  const createSupplier = async (event:React.FormEvent) => {
    event.preventDefault();
    if (!supabase || !user) return;
    setBusy(true); setMessage("");
    const slug = slugify(company.company_name);
    if (slug.length < 2) { setMessage("Please use a longer company name."); setBusy(false); return; }
    const {data,error} = await supabase.from("supplier_accounts").insert({
      owner_id:user.id, company_name:company.company_name.trim(), slug,
      website:company.website.trim()||null, location:company.location.trim(),
      about:company.about.trim(), contact_name:company.contact_name.trim()||null
    }).select("*").single();
    if (error) setMessage(error.code === "23505" ? "That company name or storefront address is already in use." : error.message);
    else { setSupplier(data as SupplierAccount); setMessage("Supplier application submitted. Your storefront will be published after review."); }
    setBusy(false);
  };

  const submitProduct = async (event:React.FormEvent) => {
    event.preventDefault();
    if (!supabase || !user || !supplier?.manufacturer_id) return;
    setBusy(true); setMessage("");
    const {error} = await supabase.from("products").insert({
      owner_id:user.id, manufacturer_id:supplier.manufacturer_id,
      name:product.name.trim(), product_type:product.product_type,
      description:product.description.trim(),
      materials:product.materials.split(",").map(x=>x.trim()).filter(Boolean),
      techniques:product.techniques.split(",").map(x=>x.trim()).filter(Boolean),
      minimum_order:product.minimum_order ? Number(product.minimum_order) : null,
      sample_available:product.sample_available,
      lead_time_days:product.lead_time_days ? Number(product.lead_time_days) : null,
      image_url:product.image_url.trim()||null, evidence:"Supplier-submitted"
    });
    if (error) setMessage(error.message);
    else { setProduct(blankProduct); setMessage("Product submitted for moderation. It will appear publicly after approval."); }
    setBusy(false);
  };

  const uploadProductImage = async (event:React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file || !supabase || !user) return;
    if (!["image/jpeg","image/png","image/webp"].includes(file.type)) { setMessage("Choose a JPG, PNG or WEBP image."); event.target.value=""; return; }
    if (file.size > 5 * 1024 * 1024) { setMessage("Product images must be 5 MB or smaller."); event.target.value=""; return; }
    setUploadingImage(true); setMessage("");
    const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g,"-").slice(-100);
    const path = user.id + "/" + Date.now() + "-" + safeName;
    const {error} = await supabase.storage.from("product-images").upload(path,file,{cacheControl:"3600",upsert:false,contentType:file.type});
    if (error) setMessage("Image upload failed: " + error.message);
    else {
      const {data} = supabase.storage.from("product-images").getPublicUrl(path);
      setProduct(current=>({...current,image_url:data.publicUrl}));
      setMessage("Product image uploaded. Save the product listing to attach it.");
    }
    setUploadingImage(false);
    event.target.value="";
  };

  const removeSavedManufacturer = async (manufacturerId:string) => {
    if (!supabase || !user) return;
    const {error} = await supabase.from("saved_manufacturers").delete().eq("user_id",user.id).eq("manufacturer_id",manufacturerId);
    if (error) setMessage("Could not remove saved supplier: " + error.message);
    else setSavedManufacturers(rows=>rows.filter(row=>row.manufacturer_id!==manufacturerId));
  };

  const selectQuote = async (rfqId:string, manufacturerId:string) => {
    if (!supabase || !user) return;
    setBusy(true); setMessage("");
    const {error} = await supabase.rpc("select_rfq_quote",{p_rfq_id:rfqId,p_manufacturer_id:manufacturerId});
    if (error) setMessage("Supplier selection could not be saved: "+error.message);
    else { setMessage("Supplier selected. The chosen factory can see your decision in its workspace."); await loadAccount(user); }
    setBusy(false);
  };

  const submitQuote = async (rfqId:string, manufacturerId:string) => {
    if (!supabase || !user) return;
    const draft = quoteDrafts[rfqId];
    if (!draft?.unit_price || Number(draft.unit_price) <= 0) { setMessage("Enter a valid unit price before submitting."); return; }
    setBusy(true); setMessage("");
    const {error} = await supabase.from("supplier_quotes").upsert({
      rfq_id:rfqId, manufacturer_id:manufacturerId, supplier_owner_id:user.id,
      unit_price:Number(draft.unit_price), currency:draft.currency,
      minimum_order:draft.minimum_order?Number(draft.minimum_order):null,
      lead_time_days:draft.lead_time_days?Number(draft.lead_time_days):null,
      sample_available:draft.sample_available, notes:draft.notes.trim(), status:supplierRfqs.find(r=>r.id===rfqId)?.supplier_quotes?.some((q:any)=>q.manufacturer_id===manufacturerId)?"updated":"submitted", updated_at:new Date().toISOString()
    },{onConflict:"rfq_id,manufacturer_id"});
    if (error) setMessage("Quote could not be submitted: "+error.message);
    else { setMessage("Your quotation has been sent to the buyer."); await loadAccount(user); }
    setBusy(false);
  };

  const withdrawQuote = async (rfqId:string, manufacturerId:string) => {
    if (!supabase || !user) return;
    setBusy(true); setMessage("");
    const {error} = await supabase.from("supplier_quotes").update({status:"withdrawn",updated_at:new Date().toISOString()}).eq("rfq_id",rfqId).eq("manufacturer_id",manufacturerId).eq("supplier_owner_id",user.id);
    if (error) setMessage("Quotation could not be withdrawn: "+error.message);
    else { setMessage("Your quotation has been withdrawn."); await loadAccount(user); }
    setBusy(false);
  };

  const signOut = async () => { if (supabase) await supabase.auth.signOut(); setProfile(null); setSupplier(null); setMessage("You have signed out."); };

  return <>
    <button className="account-trigger" onClick={()=>{setOpen(true);setMessage("");void loadAccount(session?.user ?? null);}}>{session ? "My account ↗" : "Sign in / Join ↗"}</button>
    {open && <div className="account-backdrop" onClick={()=>setOpen(false)}>
      <section className="account-panel" onClick={e=>e.stopPropagation()} role="dialog" aria-modal="true" aria-label="FactoryScout account">
        <button className="account-close" onClick={()=>setOpen(false)} aria-label="Close">×</button>
        <div className="eyebrow dark">FACTORYSCOUT ACCOUNT</div>
        {!supabase ? <><h2>Accounts are<br/><em>being configured.</em></h2><p className="account-copy">The secure account service is not configured in this deployment yet.</p></> :
        !session ? <>
          <h2>{mode==="signin" ? <>Welcome<br/><em>back.</em></> : <>Join the<br/><em>marketplace.</em></>}</h2>
          <p className="account-copy">Create a buyer account to source products, or apply as a manufacturer to open a supplier storefront.</p>
          <form className="account-form" onSubmit={runAuth}>
            {mode==="signup" && <>
              <label>Full name<input required maxLength={120} value={fullName} onChange={e=>setFullName(e.target.value)} /></label>
              <label>Account type<select value={accountType} onChange={e=>setAccountType(e.target.value as "buyer"|"supplier")}><option value="buyer">Buyer / brand</option><option value="supplier">Manufacturer / supplier</option></select></label>
            </>}
            <label>Email<input type="email" required autoComplete="email" value={email} onChange={e=>setEmail(e.target.value)} /></label>
            <label>Password<input type="password" required minLength={8} autoComplete={mode==="signin"?"current-password":"new-password"} value={password} onChange={e=>setPassword(e.target.value)} /></label>
            <button className="button primary full" disabled={busy}>{busy?"Please wait…":mode==="signin"?"Sign in ↗":"Create account ↗"}</button>
          </form>
          <button className="account-switch" onClick={()=>{setMode(mode==="signin"?"signup":"signin");setMessage("");}}>{mode==="signin"?"New to FactoryScout? Create an account":"Already registered? Sign in"}</button>
        </> : <>
          <h2>Your<br/><em>workspace.</em></h2>
          <p className="account-copy">{user?.email}</p>
          <div className="account-status"><b>{profile?.account_type==="supplier"?"Supplier account":"Buyer account"}</b><span>{profile?.role==="admin"?"Administrator": "Standard member"}</span></div>
          {profile?.role==="admin" && <div className="admin-dashboard"><div className="account-status"><b>Admin moderation</b><span>Only accounts explicitly promoted by the platform owner can access these controls.</span></div><h3>Supplier applications ({adminSuppliers.length})</h3>{adminSuppliers.length===0?<p className="account-copy">No supplier applications waiting for review.</p>:adminSuppliers.map(s=><div className="admin-review-item" key={s.id}><b>{s.company_name}</b><span>{s.location} · {s.slug}</span><p>{s.about || "No company description submitted."}</p><div><button disabled={busy} onClick={()=>approveSupplier(s.id)}>Approve & create listing</button><button disabled={busy} onClick={()=>rejectSupplier(s.id)}>Reject</button></div></div>)}<h3>Product listings ({adminProducts.length})</h3>{adminProducts.length===0?<p className="account-copy">No product listings waiting for review.</p>:adminProducts.map(p=><div className="admin-review-item" key={p.id}><b>{p.name}</b><span>{p.product_type} · Manufacturer {p.manufacturer_id}</span><div><button disabled={busy} onClick={()=>moderateProduct(p.id,"published")}>Publish</button><button disabled={busy} onClick={()=>moderateProduct(p.id,"rejected")}>Reject</button></div></div>)}</div>}
          {profile?.role!=="admin" && profile?.account_type==="supplier" && !supplier && <>
            <h3>Set up your supplier profile</h3>
            <form className="account-form" onSubmit={createSupplier}>
              <label>Company name<input required maxLength={180} value={company.company_name} onChange={e=>setCompany({...company,company_name:e.target.value})}/></label>
              <label>Company website<input type="url" placeholder="https://" value={company.website} onChange={e=>setCompany({...company,website:e.target.value})}/></label>
              <label>Factory location<input required maxLength={160} placeholder="City, country" value={company.location} onChange={e=>setCompany({...company,location:e.target.value})}/></label>
              <label>About your factory<textarea rows={3} maxLength={3000} value={company.about} onChange={e=>setCompany({...company,about:e.target.value})}/></label>
              <label>Contact person<input maxLength={120} value={company.contact_name} onChange={e=>setCompany({...company,contact_name:e.target.value})}/></label>
              <button className="button primary full" disabled={busy}>{busy?"Submitting…":"Submit supplier application ↗"}</button>
            </form>
          </>}
          {profile?.role!=="admin" && profile?.account_type==="supplier" && supplier && <>
            <div className="supplier-review-card"><b>{supplier.company_name}</b><span>Storefront handle: {supplier.slug}</span><strong className={supplier.status==="approved"?"approved":""}>{supplier.status==="approved"?"Approved supplier":supplier.status==="rejected"?"Application needs changes":"Awaiting FactoryScout review"}</strong></div>
            {supplier.status==="approved" && supplier.manufacturer_id ? <>
              <h3>Submit a product listing</h3>
              <form className="account-form" onSubmit={submitProduct}>
                <label>Product name<input required minLength={2} maxLength={180} value={product.name} onChange={e=>setProduct({...product,name:e.target.value})}/></label>
                <label>Product category<select value={product.product_type} onChange={e=>setProduct({...product,product_type:e.target.value})}>{["Streetwear","Sportswear","Denim","Workwear","Swimwear","Premium ready-to-wear","Other apparel"].map(x=><option key={x}>{x}</option>)}</select></label>
                <label>Description<textarea rows={3} maxLength={3000} value={product.description} onChange={e=>setProduct({...product,description:e.target.value})}/></label>
                <label>Materials (comma separated)<input value={product.materials} onChange={e=>setProduct({...product,materials:e.target.value})} placeholder="Cotton, recycled polyester"/></label>
                <label>Techniques (comma separated)<input value={product.techniques} onChange={e=>setProduct({...product,techniques:e.target.value})} placeholder="Embroidery, screen printing"/></label>
                <div className="account-form-grid"><label>MOQ (pieces)<input type="number" min="1" value={product.minimum_order} onChange={e=>setProduct({...product,minimum_order:e.target.value})}/></label><label>Lead time (days)<input type="number" min="1" max="730" value={product.lead_time_days} onChange={e=>setProduct({...product,lead_time_days:e.target.value})}/></label></div>
                <label>Product image<input type="file" accept="image/jpeg,image/png,image/webp" disabled={uploadingImage} onChange={uploadProductImage}/><small>JPG, PNG or WEBP · maximum 5 MB. {product.image_url ? "Image uploaded and ready to attach." : "Upload a clear product photo."}</small></label>
                <label className="account-checkbox"><input type="checkbox" checked={product.sample_available} onChange={e=>setProduct({...product,sample_available:e.target.checked})}/> Samples available</label>
                <button className="button primary full" disabled={busy||uploadingImage}>{busy?"Submitting…":uploadingImage?"Uploading image…":"Submit product for review ↗"}</button>
              </form>
            </> : <p className="account-copy">Once your company is approved and connected to its manufacturer record, you can upload products for moderation here.</p>}
          </>}
          {profile?.role!=="admin" && profile?.account_type==="supplier" && supplier?.status==="approved" && <div className="buyer-workspace">
            <h3>RFQs matched to your factory ({supplierRfqs.length})</h3>
            {supplierRfqs.length===0 ? <p className="account-copy">No buyer requests have been assigned to your factory yet.</p> : supplierRfqs.map(r=>{
              const quote=(r.supplier_quotes||[]).find((q:any)=>q.manufacturer_id===supplier.manufacturer_id);
              const draft=quoteDrafts[r.id]||(quote?{unit_price:String(quote.unit_price),currency:quote.currency,minimum_order:quote.minimum_order?String(quote.minimum_order):"",lead_time_days:quote.lead_time_days?String(quote.lead_time_days):"",sample_available:quote.sample_available,notes:quote.notes||""}:{unit_price:"",currency:"EUR",minimum_order:"",lead_time_days:"",sample_available:false,notes:""});
              const decision=(r.rfq_quote_decisions||[]).find((d:any)=>d.manufacturer_id===supplier.manufacturer_id);
              return <div className="admin-review-item" key={r.id}><b>{r.product_type} · {Number(r.quantity).toLocaleString()} units</b><span>{r.delivery_country} · {new Date(r.created_at).toLocaleDateString()}</span>{decision?.status==="selected"?<p className="quote-decision selected">Your quotation has been selected. Contact the buyer through messages to confirm the next steps.</p>:<><p>{r.material_specs||"No additional specifications supplied."}</p><div className="account-form">
                <label>Unit price<input type="number" min="0.0001" step="0.0001" value={draft.unit_price} onChange={e=>setQuoteDrafts(v=>({...v,[r.id]:{...draft,unit_price:e.target.value}}))}/></label>
                <label>Currency<select value={draft.currency} onChange={e=>setQuoteDrafts(v=>({...v,[r.id]:{...draft,currency:e.target.value}}))}><option>EUR</option><option>USD</option><option>TND</option><option>GBP</option></select></label>
                <label>Minimum order<input type="number" min="1" value={draft.minimum_order} onChange={e=>setQuoteDrafts(v=>({...v,[r.id]:{...draft,minimum_order:e.target.value}}))}/></label>
                <label>Lead time (days)<input type="number" min="1" max="730" value={draft.lead_time_days} onChange={e=>setQuoteDrafts(v=>({...v,[r.id]:{...draft,lead_time_days:e.target.value}}))}/></label>
                <label>Notes<textarea rows={2} maxLength={2000} value={draft.notes} onChange={e=>setQuoteDrafts(v=>({...v,[r.id]:{...draft,notes:e.target.value}}))}/></label>
                <label className="account-checkbox"><input type="checkbox" checked={draft.sample_available} onChange={e=>setQuoteDrafts(v=>({...v,[r.id]:{...draft,sample_available:e.target.checked}}))}/> Samples available</label>
                <div className="quote-actions"><button disabled={busy} onClick={()=>submitQuote(r.id,supplier.manufacturer_id!)}>{quote?.status==="withdrawn"?"Resubmit quotation ↗":quote?"Update quotation ↗":"Send quotation ↗"}</button>{quote&&quote.status!=="withdrawn"&&<button className="quote-withdraw-button" disabled={busy} onClick={()=>withdrawQuote(r.id,supplier.manufacturer_id!)}>Withdraw</button>}</div>
              </div></> }</div>;
            })}
          </div>}
          {profile?.role!=="admin" && profile?.account_type==="buyer" && <div className="buyer-workspace">
            <h3>Saved manufacturers ({savedManufacturers.length})</h3>
            {savedManufacturers.length===0 ? <p className="account-copy">Your saved suppliers will appear here. Browse the directory and tap the heart on a factory profile to keep it in your shortlist.</p> : savedManufacturers.map(row=><div className="saved-manufacturer-row" key={row.manufacturer_id}><div><b>{row.manufacturers?.name || row.manufacturer_id}</b><span>{row.manufacturers?.region || "FactoryScout supplier"}</span></div><button disabled={busy} onClick={()=>removeSavedManufacturer(row.manufacturer_id)}>Remove</button></div>)}
            <h3>My requests for quotation ({buyerRfqs.length})</h3>
            {buyerRfqs.length===0 ? <p className="account-copy">Your submitted RFQs and supplier replies will appear here.</p> : buyerRfqs.map(r=><div className="saved-manufacturer-row" key={r.id}><div><b>{r.product_type} · {Number(r.quantity).toLocaleString()} units</b><span>{r.delivery_country} · {new Date(r.created_at).toLocaleDateString()} · {r.status}</span><span>{(r.rfq_targets||[]).length} suppliers contacted · {(r.supplier_quotes||[]).length} quotations received</span>{(r.supplier_quotes||[]).length>0 ? <div className="quote-comparison">
                <h4>Compare supplier quotations</h4>
                <div className="quote-comparison-scroll"><table>
                  <thead><tr><th>Supplier</th><th>Unit price</th><th>MOQ</th><th>Lead time</th><th>Samples</th><th>Status</th></tr></thead>
                  <tbody>{(r.supplier_quotes||[]).map((q:any)=><tr key={q.id}>
                    <td><b>{q.rfq_targets?.manufacturers?.name || q.manufacturer_id}</b>{q.notes&&<small>{q.notes}</small>}</td>
                    <td className="quote-price">{q.currency} {Number(q.unit_price).toFixed(2)}</td>
                    <td>{q.minimum_order ? Number(q.minimum_order).toLocaleString() : "Not specified"}</td>
                    <td>{q.lead_time_days ? `${q.lead_time_days} days` : "Not specified"}</td>
                    <td>{q.sample_available ? "Available" : "Not available"}</td>
                    <td><span className="quote-status">{q.status}</span>{(()=>{const decision=(r.rfq_quote_decisions||[]).find((d:any)=>d.manufacturer_id===q.manufacturer_id);return decision?.status==="selected"?<span className="quote-decision selected">Selected</span>:decision?.status==="not_selected"?<span className="quote-decision">Not selected</span>:<button className="quote-select-button" disabled={busy||q.status==="withdrawn"} onClick={()=>selectQuote(r.id,q.manufacturer_id)}>Select supplier</button>;})()}</td>
                  </tr>)}</tbody>
                </table></div>
              </div> : <small className="quote-waiting">No quotations received yet. Your selected suppliers can respond from their workspaces.</small>}</div></div>)}
          </div>}
          {user && profile && profile.role!=="admin" && <MessagingPanel userId={user.id} accountType={profile.account_type} />}
          <button className="account-switch" onClick={signOut}>Sign out</button>
        </>}
        {message && <p className="account-message" role="status">{message}</p>}
      </section>
    </div>}
  </>;
}
