import { test, expect } from "@playwright/test";

test.describe("Progress Bar", () => {
  test("page loads with progress element", async ({ page }) => {
    await page.goto("/examples/progress-bar");
    await expect(page.locator("progress")).toBeVisible({ timeout: 5000 });
    await expect(
      page.locator("button", { hasText: "Start" }).first(),
    ).toBeVisible();
  });
});
