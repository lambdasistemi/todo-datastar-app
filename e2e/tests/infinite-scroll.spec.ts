import { test, expect } from "@playwright/test";

test.describe("Infinite Scroll", () => {
  test("loads initial rows and more on scroll", async ({ page }) => {
    await page.goto("/examples/infinite-scroll");
    await expect(page.locator("#rows tr").first()).toBeVisible({
      timeout: 10000,
    });
    await expect(page.locator("#rows tr")).toHaveCount(20);

    // Scroll sentinel into view to trigger loading more
    await page.locator("#sentinel").scrollIntoViewIfNeeded();
    await expect(page.locator("#rows tr")).toHaveCount(40, { timeout: 5000 });
  });

  test("keeps loading on repeated scrolls", async ({ page }) => {
    await page.goto("/examples/infinite-scroll");
    await expect(page.locator("#rows tr")).toHaveCount(20, { timeout: 10000 });

    await page.locator("#sentinel").scrollIntoViewIfNeeded();
    await expect(page.locator("#rows tr")).toHaveCount(40, { timeout: 5000 });

    await page.locator("#sentinel").scrollIntoViewIfNeeded();
    await expect(page.locator("#rows tr")).toHaveCount(60, { timeout: 5000 });

    await expect(page.locator("#rows")).toContainText("Agent Smith 59");
  });
});
