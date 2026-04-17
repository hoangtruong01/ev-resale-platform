<template>
  <button
    :class="triggerClasses"
    class="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
    @click="handleClick"
  >
    <slot />
  </button>
</template>

<script>
export default {
  name: 'UiTabsTrigger',
  inject: ['activeTab', 'setActiveTab'],
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
    triggerClasses() {
      const isActive = this.activeTab === this.value
      const activeClasses = isActive 
        ? 'bg-background text-foreground shadow-sm' 
        : 'hover:bg-background/50 hover:text-foreground'
      return this.class ? `${activeClasses} ${this.class}` : activeClasses
    }
  },
  methods: {
    handleClick() {
      this.setActiveTab(this.value)
    }
  }
}
</script>