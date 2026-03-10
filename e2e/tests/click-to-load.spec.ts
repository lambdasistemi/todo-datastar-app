import { test, expect } from "@playwright/test";

test.describe("Click to Load", () => {
  test("loads initial rows", async ({ page }) => {
    await page.goto("/examples/click-to-load");
    await expect(page.locator("tbody#rows tr").first()).toBeVisible({
      timeout: 10000,
    });
    await expect(page.locator("tbody#rows tr")).toHaveCount(10);
  });

  test("load more appends rows", async ({ page }) => {
    await page.goto("/examples/click-to-load");
    await expect(page.locator("tbody#rows tr")).toHaveCount(10, {
      timeout: 10000,
    });
    await page.getByRole("button", { name: "Load More" }).click();
    await expect(page.locator("tbody#rows tr")).toHaveCount(20, {
      timeout: 5000,
    });
    await expect(page.locator("tbody#rows")).toContainText("Agent Smith 10");
    await expect(page.locator("tbody#rows")).toContainText("Agent Smith 19");
  });

  test("multiple loads keep appending", async ({ page }) => {
    await page.goto("/examples/click-to-load");
    await expect(page.locator("tbody#rows tr")).toHaveCount(10, {
      timeout: 10000,
    });
    await page.getByRole("button", { name: "Load More" }).click();
    await expect(page.locator("tbody#rows tr")).toHaveCount(20, {
      timeout: 5000,
    });
    await page.getByRole("button", { name: "Load More" }).click();
    await expect(page.locator("tbody#rows tr")).toHaveCount(30, {
      timeout: 5000,
    });
    await expect(page.locator("tbody#rows")).toContainText("Agent Smith 29");
  });
});
