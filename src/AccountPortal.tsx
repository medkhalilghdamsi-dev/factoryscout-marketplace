import { useEffect, useState } from "react";
import { createClient, type Session, type User } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const publishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined;
export const supabase = supabaseUrl && publishableKey ? createClient(supabaseUrl, publishableKey, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
}) : null;

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

  const loadAccount = async (current:User|null) => {
    setUser(current);
    setProfile(null);
    setSupplier(null);
    if (!current || !supabase) return;
    const [p,s] = await Promise.all([
      supabase.from("profiles").select("id,email,full_name,account_type,role").eq("id",current.id).maybeSingle(),
      supabase.from("supplier_accounts").select("*").eq("owner_id",current.id).maybeSingle()
    ]);
    if (p.error) setMessage("Your account profile could not be loaded. Please refresh.");
    else setProfile(p.data as Profile|null);
    if (s.error && s.error.code !== "PGRST116") setMessage("Supplier workspace could not be loaded.");
    else setSupplier(s.data as SupplierAccount|null);
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

  const signOut = async () => { if (supabase) await supabase.auth.signOut(); setProfile(null); setSupplier(null); setMessage("You have signed out."); };

  return <>
    <button className="account-trigger" onClick={()=>{setOpen(true);setMessage("");}}>{session ? "My account ↗" : "Sign in / Join ↗"}</button>
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
          {profile?.account_type==="supplier" && !supplier && <>
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
          {profile?.account_type==="supplier" && supplier && <>
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
                <label>Product image URL<input type="url" placeholder="https://" value={product.image_url} onChange={e=>setProduct({...product,image_url:e.target.value})}/></label>
                <label className="account-checkbox"><input type="checkbox" checked={product.sample_available} onChange={e=>setProduct({...product,sample_available:e.target.checked})}/> Samples available</label>
                <button className="button primary full" disabled={busy}>{busy?"Submitting…":"Submit product for review ↗"}</button>
              </form>
            </> : <p className="account-copy">Once your company is approved and connected to its manufacturer record, you can upload products for moderation here.</p>}
          </>}
          {profile?.account_type==="buyer" && <p className="account-copy">Your buyer workspace is ready. Persistent saved suppliers and buyer RFQ history are coming next.</p>}
          <button className="account-switch" onClick={signOut}>Sign out</button>
        </>}
        {message && <p className="account-message" role="status">{message}</p>}
      </section>
    </div>}
  </>;
}
