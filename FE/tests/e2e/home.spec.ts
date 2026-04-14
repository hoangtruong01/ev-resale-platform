import { test, expect } from "@playwright/test";

test("home loads and navigates to vehicle detail", async ({ page }) => {
  await page.goto("/");

  const sectionCount = await page.locator("section").count();
  expect(sectionCount).toBeGreaterThan(0);

  const vehiclesCta = page.locator('a[href="/vehicles"]').first();
  await expect(vehiclesCta).toBeVisible();

  await vehiclesCta.click();
  await expect(page).toHaveURL(/\/vehicles/);
});
