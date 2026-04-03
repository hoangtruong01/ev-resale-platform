<template>
  <div 
    :class="tabsListClasses"
    class="inline-flex h-10 items-center justify-center rounded-md bg-muted p-1 text-muted-foreground"
  >
    <slot />
  </div>
</template>

<script>
export default {
  name: 'UiTabsList',
  props: {
    class: {
      type: String,
      default: ''
    }
  },
  computed: {
    tabsListClasses() {
      return this.class || ''
    }
  }
}
</script>