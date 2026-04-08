import { test, expect } from "@playwright/test";

test("home loads and navigates to vehicle detail", async ({ page }) => {
  await page.goto("/");

  await expect(page.locator("section")).toHaveCount(3, { timeout: 20000 });

  const firstVehicleLink = page.locator('a[href^="/vehicles/"]').first();
  await expect(firstVehicleLink).toBeVisible();

  await firstVehicleLink.click();
  await expect(page).toHaveURL(/\/vehicles\//);
});
