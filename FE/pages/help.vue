<template>
  <div class="min-h-screen bg-background">
    <AppHeader />
    <div class="container mx-auto px-4 py-12">
      <UiCard class="max-w-3xl mx-auto p-8">
        <h1 class="text-3xl font-bold text-foreground mb-4">Help center</h1>
        <p class="text-muted-foreground mb-6">
          Here are quick answers for common questions. If you need more help,
          please open a support ticket.
        </p>

        <div class="space-y-4">
          <div class="border rounded-lg p-4">
            <h2 class="font-semibold text-foreground">How to sell?</h2>
            <p class="text-sm text-muted-foreground mt-1">
              Go to Sell Now, fill in product details, and submit for approval.
            </p>
          </div>
          <div class="border rounded-lg p-4">
            <h2 class="font-semibold text-foreground">How to bid?</h2>
            <p class="text-sm text-muted-foreground mt-1">
              Open an auction, check the minimum bid step, and place your bid.
            </p>
          </div>
          <div class="border rounded-lg p-4">
            <h2 class="font-semibold text-foreground">Transaction fees</h2>
            <p class="text-sm text-muted-foreground mt-1">
              Fees are shown before confirming a transaction.
            </p>
          </div>
        </div>

        <div class="mt-6">
          <UiButton>
            <NuxtLink to="/support">Open support ticket</NuxtLink>
          </UiButton>
        </div>
      </UiCard>
    </div>
  </div>
</template>
