import { test, expect } from "@playwright/test";

test.describe("TodoMVC", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/examples/todo");
    // Wait for initial load
    await expect(page.locator("#todo-actions")).toBeVisible({ timeout: 5000 });
    // Reset to known state
    await page.locator("button", { hasText: "Reset" }).click();
    await expect(page.locator("#todo-list li")).toHaveCount(4, {
      timeout: 5000,
    });
  });

  test("displays initial todos", async ({ page }) => {
    await expect(page.locator("#todo-list")).toContainText(
      "Learn any backend language",
    );
    await expect(page.locator("#todo-list")).toContainText("Learn Datastar");
    await expect(page.locator("#todo-list")).toContainText("Profit");
    await expect(page.locator("#todo-actions")).toContainText("3");
  });

  test("add a todo item", async ({ page }) => {
    const input = page.locator("#new-todo");
    await input.fill("Buy milk");
    await input.press("Enter");

    await expect(page.locator("#todo-list")).toContainText("Buy milk", {
      timeout: 5000,
    });
    await expect(page.locator("#todo-actions")).toContainText("4");
  });

  test("toggle a todo item", async ({ page }) => {
    // Toggle "Learn Datastar" to done
    await page
      .locator(".todo-item")
      .filter({ hasText: "Learn Datastar" })
      .locator('input[type="checkbox"]')
      .click();
    // Pending count should drop from 3 to 2
    await expect(page.locator("#todo-actions strong")).toHaveText("2", {
      timeout: 5000,
    });
  });

  test("filter pending", async ({ page }) => {
    await page.locator("button", { hasText: "Pending" }).click();
    // "Learn any backend language" is completed, should be hidden
    await expect(page.locator("#todo-list")).not.toContainText(
      "Learn any backend language",
      { timeout: 5000 },
    );
    await expect(page.locator("#todo-list li")).toHaveCount(3);
  });

  test("filter completed", async ({ page }) => {
    await page.locator("button", { hasText: "Completed" }).click();
    await expect(page.locator("#todo-list li")).toHaveCount(1, {
      timeout: 5000,
    });
    await expect(page.locator("#todo-list")).toContainText(
      "Learn any backend language",
    );
  });

  test("delete completed", async ({ page }) => {
    await page.locator("#todo-actions button", { hasText: "Delete" }).click();
    // "Learn any backend language" (completed) should be gone
    await expect(page.locator("#todo-list")).not.toContainText(
      "Learn any backend language",
      { timeout: 5000 },
    );
    await expect(page.locator("#todo-list li")).toHaveCount(3);
  });

  test("reset restores defaults", async ({ page }) => {
    // Delete a todo first
    await page.locator("#todo-actions button", { hasText: "Delete" }).click();
    await expect(page.locator("#todo-list li")).toHaveCount(3, {
      timeout: 5000,
    });
    // Reset
    await page.locator("button", { hasText: "Reset" }).click();
    await expect(page.locator("#todo-list li")).toHaveCount(4, {
      timeout: 5000,
    });
  });
});
