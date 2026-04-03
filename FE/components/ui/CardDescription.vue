<template>
  <p :class="descriptionClasses">
    <slot />
  </p>
</template>

<script>
export default {
  name: 'UiCardDescription',
  props: {
    class: {
      type: String,
      default: ''
    }
  },
  computed: {
    descriptionClasses() {
      const baseClasses = 'text-sm text-muted-foreground'
      return this.class ? `${baseClasses} ${this.class}` : baseClasses
    }
  }
}
</script>