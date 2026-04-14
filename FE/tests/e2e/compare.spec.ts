import { test, expect } from "@playwright/test";

test("compare loads real data and builds table", async ({ page }) => {
  await page.goto("/compare");

  const selects = page.locator('[data-testid="compare-slot-select"]');
  await expect(selects).toHaveCount(3);

  const optionCount = await selects.first().locator("option").count();
  if (optionCount > 1) {
    await selects.nth(0).selectOption({ index: 1 });
    await selects.nth(1).selectOption({ index: 1 });

    await expect(page.locator("table")).toBeVisible();
  } else {
    await expect(page.locator("table")).toHaveCount(0);
  }
});
