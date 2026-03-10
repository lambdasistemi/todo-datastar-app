import { test, expect } from "@playwright/test";

test.describe("Click to Edit", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/examples/click-to-edit");
    // Wait for data-init to load the view
    await expect(page.locator("#demo strong").first()).toBeVisible({
      timeout: 5000,
    });
  });

  test("displays default contact", async ({ page }) => {
    await expect(page.locator("#demo")).toContainText("John");
    await expect(page.locator("#demo")).toContainText("Doe");
    await expect(page.locator("#demo")).toContainText("john@example.com");
  });

  test("edit and save contact", async ({ page }) => {
    await page.locator("button", { hasText: "Edit" }).click();
    await expect(page.locator('input[type="text"]').first()).toBeVisible({
      timeout: 5000,
    });

    const firstNameInput = page.locator('input[type="text"]').first();
    await firstNameInput.clear();
    await firstNameInput.type("Jane");

    await page.locator("button", { hasText: "Save" }).click();
    await expect(page.locator("#demo")).toContainText("Jane", {
      timeout: 5000,
    });
  });

  test("edit and cancel reverts changes", async ({ page }) => {
    // Reset first to ensure known state
    await page.locator("button", { hasText: "Reset" }).click();
    await expect(page.locator("#demo")).toContainText("John", {
      timeout: 5000,
    });

    await page.locator("button", { hasText: "Edit" }).click();
    await expect(page.locator('input[type="text"]').first()).toBeVisible({
      timeout: 5000,
    });

    const firstNameInput = page.locator('input[type="text"]').first();
    await firstNameInput.clear();
    await firstNameInput.type("Changed");

    await page.locator("button", { hasText: "Cancel" }).click();
    await expect(page.locator("#demo")).toContainText("John", {
      timeout: 5000,
    });
  });

  test("reset restores defaults", async ({ page }) => {
    // Edit and save
    await page.locator("button", { hasText: "Edit" }).click();
    await expect(page.locator('input[type="text"]').first()).toBeVisible({
      timeout: 5000,
    });
    const firstNameInput = page.locator('input[type="text"]').first();
    await firstNameInput.clear();
    await firstNameInput.type("Modified");
    await page.locator("button", { hasText: "Save" }).click();
    await expect(page.locator("#demo")).toContainText("Modified", {
      timeout: 5000,
    });

    // Reset
    await page.locator("button", { hasText: "Reset" }).click();
    await expect(page.locator("#demo")).toContainText("John", {
      timeout: 5000,
    });
  });
});
