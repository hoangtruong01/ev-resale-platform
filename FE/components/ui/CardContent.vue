<template>
  <div :class="contentClasses">
    <slot />
  </div>
</template>

<script>
export default {
  name: 'UiCardContent',
  props: {
    class: {
      type: String,
      default: ''
    }
  },
  computed: {
    contentClasses() {
      const baseClasses = 'p-6 pt-0'
      return this.class ? `${baseClasses} ${this.class}` : baseClasses
    }
  }
}
</script>