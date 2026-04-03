<template>
  <div 
    :class="progressClasses"
    class="relative h-4 w-full overflow-hidden rounded-full bg-secondary"
  >
    <div 
      class="h-full w-full flex-1 bg-primary transition-all"
      :style="{ transform: `translateX(-${100 - value}%)` }"
    />
  </div>
</template>

<script>
export default {
  name: 'UiProgress',
  props: {
    value: {
      type: Number,
      default: 0,
      validator: (value) => value >= 0 && value <= 100
    },
    class: {
      type: String,
      default: ''
    }
  },
  computed: {
    progressClasses() {
      return this.class || ''
    }
  }
}
</script>