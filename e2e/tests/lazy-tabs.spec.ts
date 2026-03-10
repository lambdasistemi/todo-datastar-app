import { test, expect } from "@playwright/test";

test.describe("Lazy Tabs", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/examples/lazy-tabs");
    await expect(page.locator('[role="tablist"]')).toBeVisible();
  });

  test("displays tabs", async ({ page }) => {
    await expect(page.locator('[role="tab"]').first()).toBeVisible();
  });

  test("clicking tab loads content", async ({ page }) => {
    await page.locator('[role="tab"]').nth(1).click();
    await expect(page.locator('[role="tabpanel"]')).toBeVisible({
      timeout: 5000,
    });
  });
});
