import { test, expect } from "@playwright/test";

test.describe("Active Search", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/examples/active-search");
  });

  test("search filters results", async ({ page }) => {
    const input = page.locator('input[type="search"]');
    await input.fill("joe");

    // Wait for debounced search to return results
    await expect(page.locator("#results")).toContainText("Joe Smith", {
      timeout: 5000,
    });
    await expect(page.locator("#results")).not.toContainText("Angie");
  });

  test("empty search shows all contacts", async ({ page }) => {
    const input = page.locator('input[type="search"]');
    await input.fill("joe");
    await expect(page.locator("#results")).toContainText("Joe Smith", {
      timeout: 5000,
    });

    await input.fill("");
    await expect(page.locator("#results")).toContainText("Angie MacDowell", {
      timeout: 5000,
    });
  });
});
