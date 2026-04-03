<template>
  <div :class="cardClasses">
    <slot />
  </div>
</template>

<script>
export default {
  name: 'UiCard',
  props: {
    class: {
      type: String,
      default: ''
    }
  },
  computed: {
    cardClasses() {
      const baseClasses = 'rounded-lg border bg-card text-card-foreground shadow-sm'
      return this.class ? `${baseClasses} ${this.class}` : baseClasses
    }
  }
}
</script>