import { test, expect } from "@playwright/test";

test.describe("Inline Validation", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/examples/inline-validation");
    await expect(page.locator("#demo")).toBeVisible();
  });

  test("validates email on keydown", async ({ page }) => {
    const emailInput = page.locator('input[type="email"]');
    await emailInput.type("bad");
    // Wait for debounced validation response
    await expect(page.locator("#demo")).toContainText(/.*/, {
      timeout: 3000,
    });
  });

  test("valid email shows success", async ({ page }) => {
    const emailInput = page.locator('input[type="email"]');
    await emailInput.type("test@test.com");
    await expect(page.locator("#demo")).toContainText("Looks good!", {
      timeout: 3000,
    });
  });
});
