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
  await page.locator(".nav.open a[href='#directory']").click();
  await expect(page).toHaveURL(/#directory$/);
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
