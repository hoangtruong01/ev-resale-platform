<template>
  <h3 :class="titleClasses">
    <slot />
  </h3>
</template>

<script>
export default {
  name: 'UiCardTitle',
  props: {
    class: {
      type: String,
      default: ''
    }
  },
  computed: {
    titleClasses() {
      const baseClasses = 'text-2xl font-semibold leading-none tracking-tight'
      return this.class ? `${baseClasses} ${this.class}` : baseClasses
    }
  }
}
</script>