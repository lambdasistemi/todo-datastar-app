import { test, expect } from "@playwright/test";

test.describe("Lazy Load", () => {
  test("loads content on init", async ({ page }) => {
    await page.goto("/examples/lazy-load");
    // Wait for data-init to replace "Loading..."
    await expect(page.locator("#demo")).not.toContainText("Loading...", {
      timeout: 10000,
    });
  });
});
