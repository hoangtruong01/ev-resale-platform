<template>
  <div class="min-h-screen bg-background">
    <AppHeader />
    <div class="container mx-auto px-4 py-12">
      <UiCard class="max-w-3xl mx-auto p-8">
        <h1 class="text-3xl font-bold text-foreground mb-4">Contact</h1>
        <p class="text-muted-foreground mb-6">
          Reach our team via hotline or email. We respond within 24 hours.
        </p>
        <div class="space-y-3 text-foreground">
          <div>Hotline: 1800-1234</div>
          <div>Email: support@evnmarket.com</div>
          <div>Address: 123 ABC Street, District 1, HCMC</div>
        </div>
        <div class="mt-6">
          <UiButton variant="outline">
            <NuxtLink to="/support">Send support request</NuxtLink>
          </UiButton>
        </div>
      </UiCard>
    </div>
  </div>
</template>
