import { test, expect } from "@playwright/test";

test.describe("Infinite Scroll", () => {
  test("loads initial rows and more on scroll", async ({ page }) => {
    await page.goto("/examples/infinite-scroll");
    // Wait for initial 20 rows to load via data-on-intersect
    await expect(page.locator("#rows tr").first()).toBeVisible({
      timeout: 10000,
    });
    const initialCount = await page.locator("#rows tr").count();
    expect(initialCount).toBe(20);

    // Scroll sentinel into view to trigger loading more
    await page.locator("#sentinel").scrollIntoViewIfNeeded();
    await expect(page.locator("#rows tr")).toHaveCount(40, { timeout: 5000 });
  });
});
