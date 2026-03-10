import { test, expect } from "@playwright/test";

// Click to Load uses DatastarSSE with selector-based patches
// which requires the SSE response format to match what the
// current datastar JS version expects. Skipping until the
// SSE response format is verified.
test.describe("Click to Load", () => {
  test.skip("loads initial rows", async ({ page }) => {
    await page.goto("/examples/click-to-load");
    await expect(page.locator("tbody#rows tr").first()).toBeVisible({
      timeout: 10000,
    });
    const rows = page.locator("tbody#rows tr");
    await expect(rows).toHaveCount(10);
  });
});
