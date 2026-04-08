<template>
  <div class="min-h-screen bg-background">
    <AppHeader />
    <div class="container mx-auto px-4 py-12">
      <UiCard class="max-w-3xl mx-auto p-8 text-center">
        <h1 class="text-3xl font-bold text-foreground mb-4">Phu kien</h1>
        <p class="text-muted-foreground">
          Danh muc phu kien se som cap nhat. Vui long quay lai sau.
        </p>
        <div class="mt-6">
          <UiButton variant="outline">
            <NuxtLink to="/support">Lien he ho tro</NuxtLink>
          </UiButton>
        </div>
      </UiCard>
    </div>
  </div>
</template>
