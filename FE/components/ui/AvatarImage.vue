<template>
  <img 
    :src="src"
    :alt="alt"
    class="aspect-square h-full w-full"
  >
</template>

<script>
export default {
  name: 'UiAvatarImage',
  props: {
    src: {
      type: String,
      required: true
    },
    alt: {
      type: String,
      default: ''
    }
  }
}
</script>