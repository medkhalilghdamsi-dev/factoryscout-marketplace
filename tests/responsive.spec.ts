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
