import { test, expect } from "@playwright/test";

test("compare loads real data and builds table", async ({ page }) => {
  await page.goto("/compare");

  await page.waitForSelector("select option:nth-child(2)", {
    timeout: 20000,
  });

  const selects = page.locator("select");
  await selects.nth(0).selectOption({ index: 1 });
  await selects.nth(1).selectOption({ index: 1 });

  await expect(page.locator("table")).toBeVisible();
  await expect(page.locator("tbody tr")).toHaveCount(8);
});
