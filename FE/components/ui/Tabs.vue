<template>
  <div 
    :class="tabsClasses"
    class="w-full"
  >
    <slot />
  </div>
</template>

<script>
export default {
  name: 'UiTabs',
  provide() {
    return {
      activeTab: this.value,
      setActiveTab: this.setActiveTab
    }
  },
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
  emits: ['update:value'],
  computed: {
    tabsClasses() {
      return this.class || ''
    }
  },
  methods: {
    setActiveTab(tab) {
      this.$emit('update:value', tab)
    }
  }
}
</script>