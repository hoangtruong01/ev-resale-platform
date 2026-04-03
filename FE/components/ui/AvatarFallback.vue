<template>
  <span 
    :class="fallbackClasses"
    class="flex h-full w-full items-center justify-center rounded-full bg-muted"
  >
    <slot />
  </span>
</template>

<script>
export default {
  name: 'UiAvatarFallback',
  props: {
    class: {
      type: String,
      default: ''
    }
  },
  computed: {
    fallbackClasses() {
      return this.class || ''
    }
  }
}
</script>