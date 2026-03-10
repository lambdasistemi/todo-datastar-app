import { test, expect } from "@playwright/test";

test.describe("File Upload", () => {
  test("page loads with upload form", async ({ page }) => {
    await page.goto("/examples/file-upload");
    await expect(page.locator('input[type="file"]')).toBeVisible();
  });
});
