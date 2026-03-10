import { test, expect } from "@playwright/test";

test.describe("Delete Row", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/examples/delete-row");
    await expect(page.locator("table")).toBeVisible();
  });

  test("displays contacts", async ({ page }) => {
    // Check that at least one row with a Delete button exists
    const rows = page.locator("tbody tr");
    await expect(rows.first()).toBeVisible({ timeout: 5000 });
    const count = await rows.count();
    expect(count).toBeGreaterThan(0);
  });

  test("delete removes a row", async ({ page }) => {
    const rows = page.locator("tbody tr");
    const initialCount = await rows.count();

    // Accept the confirm dialog
    page.on("dialog", (dialog) => dialog.accept());
    await rows.first().locator("button").click();

    await expect(rows).toHaveCount(initialCount - 1);
  });
});
