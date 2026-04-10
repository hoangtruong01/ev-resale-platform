// i18n.config.ts — bundle all locale messages directly (no lazy loading)
// This avoids the /_i18n endpoint issue with @nuxtjs/i18n v10
import vi from './locales/vi.json'
import en from './locales/en.json'
import ja from './locales/ja.json'

export default defineI18nConfig(() => ({
  legacy: false,
  locale: 'vi',
  messages: {
    vi,
    en,
    ja,
  },
  datetimeFormats: {
    vi: { short: { year: 'numeric', month: '2-digit', day: '2-digit' } },
    en: { short: { year: 'numeric', month: '2-digit', day: '2-digit' } },
    ja: { short: { year: 'numeric', month: '2-digit', day: '2-digit' } },
  },
  numberFormats: {
    vi: {
      currency: { style: 'currency', currency: 'VND', maximumFractionDigits: 0 },
    },
    en: {
      currency: { style: 'currency', currency: 'USD', maximumFractionDigits: 0 },
    },
    ja: {
      currency: { style: 'currency', currency: 'JPY', maximumFractionDigits: 0 },
    },
  },
}))
