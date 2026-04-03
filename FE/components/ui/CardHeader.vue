<template>
  <div :class="headerClasses">
    <slot />
  </div>
</template>

<script>
export default {
  name: 'UiCardHeader',
  props: {
    class: {
      type: String,
      default: ''
    }
  },
  computed: {
    headerClasses() {
      const baseClasses = 'flex flex-col space-y-1.5 p-6'
      return this.class ? `${baseClasses} ${this.class}` : baseClasses
    }
  }
}
</script>