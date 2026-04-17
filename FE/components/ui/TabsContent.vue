<template>
  <div 
    v-show="activeTab === value"
    :class="contentClasses"
    class="mt-2 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
  >
    <slot />
  </div>
</template>

<script>
export default {
  name: 'UiTabsContent',
  inject: ['activeTab'],
  props: {
    value: {
      type: String,
      required: true
    },
    class: {
      type: String,
      default: ''
    }
  },
  computed: {
    contentClasses() {
      return this.class || ''
    }
  }
}
</script>