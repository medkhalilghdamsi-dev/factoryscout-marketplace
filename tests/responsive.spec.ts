import { test, expect } from "@playwright/test";

const viewports = [
  { width: 320, height: 740 },
  { width: 375, height: 812 },
  { width: 390, height: 844 },
  { width: 430, height: 932 },
  { width: 640, height: 900 },
  { width: 768, height: 1024 },
  { width: 900, height: 1000 },
  { width: 1280, height: 900 }
];

for (const viewport of viewports) {
  test(`homepage fits ${viewport.width}px viewport`, async ({ page }) => {
    await page.setViewportSize(viewport);
    await page.goto("/");
    await expect(page.locator(".marketplace-global-search")).toBeVisible();
    await expect(page.locator(".marketplace-category-nav")).toBeVisible();
    await expect(page.locator(".hero h1")).toBeVisible();
    if (viewport.width >= 1181) {
      const searchWidth = await page.locator(".marketplace-global-search").evaluate(el => el.getBoundingClientRect().width);
      expect(searchWidth).toBeGreaterThanOrEqual(340);
    }
    const dimensions = await page.evaluate(() => ({
      viewport: window.innerWidth,
      document: document.documentElement.scrollWidth,
      body: document.body.scrollWidth
    }));
    expect(dimensions.document, JSON.stringify(dimensions)).toBeLessThanOrEqual(viewport.width + 1);
    expect(dimensions.body, JSON.stringify(dimensions)).toBeLessThanOrEqual(viewport.width + 1);
    await page.screenshot({ path: `test-results/screenshots/home-${viewport.width}.png`, fullPage: true });
  });
}

test("mobile navigation opens and category navigation remains usable", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  await page.locator(".menu-btn").click();
  await expect(page.locator(".nav.open")).toBeVisible();
  await page.locator(".nav.open a[href='/suppliers']").click();
  await expect(page).toHaveURL(/\/suppliers$/);
});

test("supplier storefront is directly reachable on mobile without horizontal overflow", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/suppliers/les-ateliers-bs");
  await expect(page.getByRole("heading", { name: /Les Ateliers BS/ })).toBeVisible();
  const dimensions = await page.evaluate(() => ({
    viewport: window.innerWidth,
    document: document.documentElement.scrollWidth,
    body: document.body.scrollWidth
  }));
  expect(dimensions.document, JSON.stringify(dimensions)).toBeLessThanOrEqual(391);
  expect(dimensions.body, JSON.stringify(dimensions)).toBeLessThanOrEqual(391);
  await page.screenshot({ path: "test-results/screenshots/storefront-390.png", fullPage: true });
});

test("shareable product detail pages show specifications and prefill a product RFQ", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  const product = {
    id: "test-heavyweight-hoodie",
    manufacturer_id: "les-ateliers-bs",
    name: "Heavyweight Hoodie",
    product_type: "Streetwear",
    description: "A supplier-listed heavyweight cotton hoodie with an embroidered chest mark.",
    materials: ["Organic cotton", "Recycled polyester"],
    techniques: ["Embroidery"],
    minimum_order: 100,
    sample_available: true,
    lead_time_days: 45,
    image_url: null,
    evidence: "Supplier-submitted",
    manufacturers: { name: "Les Ateliers BS", region: "La Soukra, Ariana" }
  };
  await page.route("**/api/manufacturers", route => route.fulfill({
    status: 200,
    contentType: "application/json",
    body: JSON.stringify([{
      id: "les-ateliers-bs",
      name: "Les Ateliers BS",
      region: "La Soukra, Ariana",
      category: ["Premium ready-to-wear"],
      summary: "Approved test supplier.",
      capabilities: ["Woven garments"],
      moq: "100 pieces",
      leadTime: "45 days",
      evidence: "Supplier-published",
      evidenceNote: "Test fixture only.",
      exportMarkets: [],
      status: "Approved supplier account",
      rfqEnabled: true
    }])
  }));
  await page.route("**/api/products", route => route.fulfill({
    status: 200,
    contentType: "application/json",
    body: JSON.stringify([product])
  }));
  await page.goto("/products/test-heavyweight-hoodie");
  await expect(page.getByRole("heading", { name: "Heavyweight Hoodie" })).toBeVisible();
  await expect(page.getByText("Organic cotton")).toBeVisible();
  await expect(page.getByText("100 pieces")).toBeVisible();
  await expect(page.getByRole("button", { name: /Request a quotation/ })).toBeVisible();
  const dimensions = await page.evaluate(() => ({
    viewport: window.innerWidth,
    document: document.documentElement.scrollWidth,
    body: document.body.scrollWidth
  }));
  expect(dimensions.document, JSON.stringify(dimensions)).toBeLessThanOrEqual(391);
  expect(dimensions.body, JSON.stringify(dimensions)).toBeLessThanOrEqual(391);
  await page.getByRole("button", { name: /Request a quotation/ }).click();
  await expect(page.locator(".rfq-modal")).toBeVisible();
  await expect(page.getByLabel("Product type")).toHaveValue("Streetwear");
  await expect(page.locator(".rfq-suppliers input[type='checkbox']").first()).toBeChecked();
});

test("global search finds published products by material", async ({ page }) => {
  const product = {
    id: "test-heavyweight-hoodie",
    manufacturer_id: "les-ateliers-bs",
    name: "Heavyweight Hoodie",
    product_type: "Streetwear",
    description: "A supplier-listed heavyweight cotton hoodie.",
    materials: ["Organic cotton", "Recycled polyester"],
    techniques: ["Embroidery"],
    minimum_order: 100,
    sample_available: true,
    lead_time_days: 45,
    image_url: null,
    evidence: "Supplier-submitted",
    manufacturers: { name: "Les Ateliers BS", region: "La Soukra, Ariana" }
  };
  await page.route("**/api/products", route => route.fulfill({
    status: 200,
    contentType: "application/json",
    body: JSON.stringify([product])
  }));
  await page.goto("/");
  await page.locator("#global-market-search").fill("organic cotton");
  await page.locator(".marketplace-global-search button").click();
  await expect(page.locator("#catalog")).toBeInViewport();
  await expect(page.locator(".product-card h3")).toHaveText("Heavyweight Hoodie");
});

test("supplier storefront product listings open their product detail page", async ({ page }) => {
  const product = {
    id: "test-storefront-product",
    manufacturer_id: "les-ateliers-bs",
    name: "Premium Woven Overshirt",
    product_type: "Premium ready-to-wear",
    description: "A woven overshirt listing from the supplier.",
    materials: ["Cotton twill"],
    techniques: ["Garment dye"],
    minimum_order: 150,
    sample_available: true,
    lead_time_days: 50,
    image_url: null,
    evidence: "Supplier-submitted",
    manufacturers: { name: "Les Ateliers BS", region: "La Soukra, Ariana" }
  };
  await page.route("**/api/manufacturers", route => route.fulfill({
    status: 200,
    contentType: "application/json",
    body: JSON.stringify([{
      id: "les-ateliers-bs",
      name: "Les Ateliers BS",
      region: "La Soukra, Ariana",
      category: ["Premium ready-to-wear"],
      summary: "Approved test supplier.",
      capabilities: ["Woven garments"],
      moq: "100 pieces",
      leadTime: "45 days",
      evidence: "Supplier-published",
      evidenceNote: "Test fixture only.",
      exportMarkets: [],
      status: "Approved supplier account",
      rfqEnabled: true
    }])
  }));
  await page.route("**/api/products", route => route.fulfill({
    status: 200,
    contentType: "application/json",
    body: JSON.stringify([product])
  }));
  await page.goto("/suppliers/les-ateliers-bs");
  await page.getByRole("button", { name: /View product details/ }).click();
  await expect(page).toHaveURL(/\/products\/test-storefront-product$/);
  await expect(page.getByRole("heading", { name: "Premium Woven Overshirt" })).toBeVisible();
});

test("RFQ form blocks manufacturers without approved supplier accounts", async ({ page }) => {
  const manufacturer = {
    id: "onboarding-factory",
    name: "Onboarding Factory",
    region: "Sousse, Tunisia",
    category: ["Sportswear"],
    summary: "A supplier profile awaiting account approval.",
    capabilities: ["Sportswear"],
    moq: "Not confirmed",
    leadTime: "Not confirmed",
    evidence: "Supplier-published",
    evidenceNote: "Awaiting supplier onboarding.",
    exportMarkets: [],
    status: "Review required",
    rfqEnabled: false
  };
  await page.route("**/api/manufacturers", route => route.fulfill({
    status: 200,
    contentType: "application/json",
    body: JSON.stringify([manufacturer])
  }));
  await page.route("**/api/products", route => route.fulfill({
    status: 200,
    contentType: "application/json",
    body: "[]"
  }));
  await page.goto("/");
  await page.getByRole("button", { name: /Describe what you need/ }).click();
  await expect(page.locator(".rfq-no-suppliers")).toBeVisible();
  await expect(page.locator(".rfq-suppliers input[type='checkbox']")).toBeDisabled();
  await expect(page.getByRole("button", { name: /Send RFQ to/ })).toBeDisabled();
});


test("API responses include baseline browser security headers", async ({ request }) => {
  const response = await request.get("/api/health");
  expect(response.ok()).toBeTruthy();
  expect(response.headers()["x-content-type-options"]).toBe("nosniff");
  expect(response.headers()["x-frame-options"]).toBe("DENY");
  expect(response.headers()["referrer-policy"]).toBe("strict-origin-when-cross-origin");
  expect(response.headers()["permissions-policy"]).toContain("camera=()");
  expect(response.headers()["x-powered-by"]).toBeUndefined();
});

test("public enquiry endpoint rate-limits repeated submissions from one client", async ({ request }) => {
  for (let attempt = 0; attempt < 8; attempt++) {
    const response = await request.post("/api/enquiries", { data: {} });
    expect(response.status(), `attempt ${attempt + 1}`).toBe(400);
  }
  const limited = await request.post("/api/enquiries", { data: {} });
  expect(limited.status()).toBe(429);
  expect(Number(limited.headers()["retry-after"])).toBeGreaterThan(0);
});

test("manufacturer enquiry clearly explains FactoryScout review and follow-up", async ({ page }) => {
  await page.route("**/api/manufacturers", route => route.fulfill({
    status: 200,
    contentType: "application/json",
    body: JSON.stringify([{
      id: "unverified-factory",
      name: "Unverified Factory",
      region: "Sousse, Tunisia",
      category: ["Sportswear"],
      summary: "Supplier profile awaiting onboarding.",
      capabilities: ["Sportswear"],
      moq: "Not confirmed",
      leadTime: "Not confirmed",
      evidence: "Supplier-published",
      evidenceNote: "Awaiting supplier verification.",
      exportMarkets: [],
      status: "Review required",
      rfqEnabled: false
    }])
  }));
  await page.route("**/api/products", route => route.fulfill({
    status: 200, contentType: "application/json", body: "[]"
  }));
  await page.route("**/api/enquiries", route => route.fulfill({
    status: 201, contentType: "application/json", body: JSON.stringify({ ok: true, id: "test-enquiry" })
  }));
  await page.goto("/");
  await page.getByRole("button", { name: "Enquire about Unverified Factory" }).click();
  await expect(page.getByText(/message goes to the FactoryScout team first/i)).toBeVisible();
  await page.getByLabel("Your name").fill("Test Buyer");
  await page.getByLabel("Work email").fill("buyer@example.com");
  await page.getByLabel("Product type").fill("Sportswear set");
  await page.getByRole("button", { name: /Send to FactoryScout/ }).click();
  await expect(page.getByRole("status")).toContainText(/sent to FactoryScout for review/i);
});


test("light and dark themes persist across marketplace and supplier storefront navigation", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  const themeButton = page.locator(".theme-toggle").first();
  await expect(themeButton).toBeVisible();
  await themeButton.click();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  expect(await page.evaluate(() => localStorage.getItem("factoryscout-theme"))).toBe("dark");

  await page.goto("/suppliers/les-ateliers-bs");
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  const storefrontToggle = page.locator(".storefront-nav .theme-toggle");
  await expect(storefrontToggle).toBeVisible();
  await storefrontToggle.click();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
  expect(await page.evaluate(() => localStorage.getItem("factoryscout-theme"))).toBe("light");
});


test("dark theme styles the account workspace instead of leaving a light drawer", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  await page.locator(".theme-toggle").first().click();
  await page.locator(".account-trigger").click();
  const panel = page.locator(".account-panel");
  await expect(panel).toBeVisible();
  const background = await panel.evaluate(el => getComputedStyle(el).backgroundColor);
  expect(background).toBe("rgb(23, 37, 28)");
  const panelText = await panel.innerText();
  expect(panelText.length).toBeGreaterThan(0);
  const panelColor = await panel.locator("h2, h3, h4").first().evaluate(el => getComputedStyle(el).color);
  expect(panelColor).toBe("rgb(231, 238, 232)");
});


test("tablet navigation stays reachable at 768px and 1024px", async ({ page }) => {
  await page.setViewportSize({ width: 768, height: 1024 });
  await page.goto("/");
  const menu = page.locator(".menu-btn");
  await expect(menu).toBeVisible();
  await menu.click();
  await expect(page.locator(".nav.open")).toBeVisible();
  await expect(page.locator(".nav.open a[href='/suppliers']")).toBeVisible();

  await page.setViewportSize({ width: 1024, height: 900 });
  await page.goto("/");
  await expect(page.locator(".topbar>.nav")).toBeVisible();
  await expect(page.locator(".topbar>.nav a[href='/products']")).toBeVisible();
});


test("dedicated marketplace routes render their own page content on direct navigation", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });

  await page.goto("/suppliers");
  await expect(page.locator(".page-content.page-suppliers #directory")).toBeVisible();
  await expect(page.locator(".page-content.page-suppliers .hero")).toBeHidden();
  await expect(page.locator(".page-content.page-suppliers .catalog")).toBeHidden();
  await expect(page.locator('.topbar .nav a[aria-current="page"]')).toHaveText("Suppliers");

  await page.goto("/products");
  await expect(page.locator(".page-content.page-products .catalog")).toBeVisible();
  await expect(page.locator(".page-content.page-products .directory")).toBeHidden();
  await expect(page.locator(".page-content.page-products .catalog-empty")).toBeVisible();

  await page.goto("/how-it-works");
  await expect(page.locator(".page-content.page-how-it-works .how")).toBeVisible();
  await expect(page.locator(".page-content.page-how-it-works .directory")).toBeHidden();

  await page.goto("/for-manufacturers");
  await expect(page.locator(".page-content.page-for-manufacturers .manufacturer-page")).toBeVisible();
  await expect(page.getByRole("heading", { name: /Make your factory easier to discover/i })).toBeVisible();
  await expect(page.locator(".page-content.page-for-manufacturers .list-cta")).toBeVisible();
  await expect(page.locator(".page-content.page-for-manufacturers .how")).toBeHidden();

  await page.goto("/request-quote");
  await expect(page.locator(".rfq-modal")).toBeVisible();
  await expect(page.locator(".page-content.page-request-quote .hero")).toBeHidden();
});
