import { test, expect } from "@playwright/test";

test.describe("Edit Row", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/examples/edit-row");
    await expect(page.locator("table")).toBeVisible({ timeout: 5000 });
  });

  test("displays contacts table", async ({ page }) => {
    const rows = page.locator("tbody tr");
    await expect(rows).toHaveCount(4);
    await expect(rows.first().locator("td").nth(2)).toContainText("Edit");
  });

  test("edit and save a row", async ({ page }) => {
    // Click Edit on first row
    await page.locator("tbody tr").first().locator("button", { hasText: "Edit" }).click();
    // Form replaces entire #demo
    await expect(page.locator('input[type="text"]')).toBeVisible({
      timeout: 5000,
    });

    const nameInput = page.locator('input[type="text"]');
    await nameInput.clear();
    await nameInput.type("Updated Name");

    await page.locator("button", { hasText: "Save" }).click();
    // Table reappears with updated name
    await expect(page.locator("table")).toContainText("Updated Name", {
      timeout: 5000,
    });
  });

  test("edit and cancel reverts", async ({ page }) => {
    // Get current first row name before editing
    const originalName = await page
      .locator("tbody tr")
      .first()
      .locator("td")
      .first()
      .textContent();

    await page.locator("tbody tr").first().locator("button", { hasText: "Edit" }).click();
    await expect(page.locator('input[type="text"]')).toBeVisible({
      timeout: 5000,
    });

    const nameInput = page.locator('input[type="text"]');
    await nameInput.clear();
    await nameInput.type("Should Not Save");

    await page.locator("button", { hasText: "Cancel" }).click();
    await expect(page.locator("table")).toContainText(originalName!, {
      timeout: 5000,
    });
    await expect(page.locator("table")).not.toContainText("Should Not Save");
  });
});
