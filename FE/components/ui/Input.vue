<template>
  <input
    :class="inputClasses"
    :value="modelValue"
    :placeholder="placeholder"
    :disabled="disabled"
    @input="handleInput"
    @keypress="handleKeyPress"
  />
</template>

<script>
export default {
  name: 'UiInput',
  props: {
    modelValue: {
      type: String,
      default: ''
    },
    placeholder: {
      type: String,
      default: ''
    },
    disabled: {
      type: Boolean,
      default: false
    },
    class: {
      type: String,
      default: ''
    }
  },
  emits: ['update:modelValue', 'keypress'],
  computed: {
    inputClasses() {
      const baseClasses = 'flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50'
      return this.class ? `${baseClasses} ${this.class}` : baseClasses
    }
  },
  methods: {
    handleInput(event) {
      this.$emit('update:modelValue', event.target.value)
    },
    handleKeyPress(event) {
      this.$emit('keypress', event)
    }
  }
}
</script>
