<template>
  <div 
    :class="avatarClasses"
    class="relative flex shrink-0 overflow-hidden rounded-full"
  >
    <slot />
  </div>
</template>

<script>
export default {
  name: 'UiAvatar',
  props: {
    class: {
      type: String,
      default: ''
    },
    size: {
      type: String,
      default: 'default',
      validator: (value) => ['sm', 'default', 'lg'].includes(value)
    }
  },
  computed: {
    avatarClasses() {
      const sizeClasses = {
        sm: 'h-8 w-8',
        default: 'h-10 w-10',
        lg: 'h-12 w-12'
      }
      const baseClasses = sizeClasses[this.size]
      return this.class ? `${baseClasses} ${this.class}` : baseClasses
    }
  }
}
</script>