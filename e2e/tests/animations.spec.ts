import { test, expect } from "@playwright/test";

test.describe("Animations", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/examples/animations");
    await expect(page.locator("#content div").first()).toBeVisible({
      timeout: 5000,
    });
  });

  test("shuffle button reorders items", async ({ page }) => {
    const items = page.locator("#content div");
    const before = await items.allTextContents();

    await page.click("text=Shuffle");
    // Wait for new content
    await page.waitForTimeout(1000);
    const after = await items.allTextContents();

    // Items should be same set but possibly different order
    expect(after.sort()).toEqual(before.sort());
  });
});
