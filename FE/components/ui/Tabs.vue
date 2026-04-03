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
  provide() {
    return {
      activeTab: this.value,
      setActiveTab: this.setActiveTab
    }
  },
  computed: {
    tabsClasses() {
      return this.class || ''
    }
  },
  methods: {
    setActiveTab(tab) {
      this.$emit('update:value', tab)
    }
  },
  emits: ['update:value']
}
</script>