import { createConfigForNuxt } from '@nuxt/eslint-config/flat'

export default createConfigForNuxt({
  features: {
    typescript: true
  }
}).prepend({
  rules: {
    'vue/max-attributes-per-line': 'off',
    'vue/no-multiple-template-root': 'off',
    'vue/no-restricted-syntax': 'error'
  },
  ignores: [
    'dist',
    'node_modules',
    '.output',
    '.nuxt'
  ]
})