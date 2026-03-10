import { test, expect } from "@playwright/test";

test.describe("Bulk Update", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/examples/bulk-update");
    await expect(page.locator("table")).toBeVisible({ timeout: 5000 });
  });

  test("displays contacts table", async ({ page }) => {
    await expect(page.locator("table")).toContainText("Item 1");
    // Status may be Active or Inactive depending on prior test runs
    const statuses = await page.locator("tbody td:nth-child(2)").allTextContents();
    expect(statuses.length).toBeGreaterThan(0);
    for (const s of statuses) {
      expect(["Active", "Inactive"]).toContain(s);
    }
  });

  test("activate all sets all active", async ({ page }) => {
    await page.click("text=Activate All");
    // Wait for first status to become Active
    await expect(page.locator("tbody td:nth-child(2)").first()).toHaveText(
      "Active",
      { timeout: 5000 },
    );
    const statuses = await page.locator("tbody td:nth-child(2)").allTextContents();
    for (const s of statuses) {
      expect(s).toBe("Active");
    }
  });

  test("deactivate all sets all inactive", async ({ page }) => {
    await page.click("text=Deactivate All");
    await expect(page.locator("tbody td:nth-child(2)").first()).toHaveText(
      "Inactive",
      { timeout: 5000 },
    );
    const statuses = await page.locator("tbody td:nth-child(2)").allTextContents();
    for (const s of statuses) {
      expect(s).toBe("Inactive");
    }
  });
});
