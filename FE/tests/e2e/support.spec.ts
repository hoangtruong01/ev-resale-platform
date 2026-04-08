import { test, expect } from "@playwright/test";

test("support form submits and resets", async ({ page }) => {
  await page.goto("/support");

  const nameInput = page.locator('input[placeholder="Nhập họ tên"]');
  const emailInput = page.locator('input[placeholder="Nhập email"]');
  const subjectInput = page.locator('input[placeholder="Tiêu đề yêu cầu"]');
  const messageInput = page.locator(
    'textarea[placeholder="Mô tả chi tiết vấn đề cần hỗ trợ"]',
  );

  await nameInput.fill("Test User");
  await emailInput.fill("test.user@example.com");
  await subjectInput.fill("Support request");
  await messageInput.fill("Please help with my listing.");

  await page.locator('button[type="submit"]').click();

  await expect(nameInput).toHaveValue("");
  await expect(emailInput).toHaveValue("");
  await expect(subjectInput).toHaveValue("");
  await expect(messageInput).toHaveValue("");
});
