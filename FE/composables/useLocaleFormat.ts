export type LocaleFormatOptions = {
  date?: Intl.DateTimeFormatOptions;
  time?: Intl.DateTimeFormatOptions;
  dateTime?: Intl.DateTimeFormatOptions;
  number?: Intl.NumberFormatOptions;
  currency?: Intl.NumberFormatOptions;
};

type LocaleEntry = {
  code?: string;
  iso?: string;
};

const resolveLocale = (
  locale: string,
  locales: Array<string | LocaleEntry> | undefined,
) => {
  if (!locales || !Array.isArray(locales)) {
    return locale || "vi-VN";
  }

  const match = locales.find((entry) => {
    if (typeof entry === "string") {
      return entry === locale;
    }
    return entry?.code === locale;
  });

  if (match && typeof match === "object" && match.iso) {
    return match.iso;
  }

  return locale || "vi-VN";
};

export const useLocaleFormat = (options: LocaleFormatOptions = {}) => {
  const { locale, locales } = useI18n({ useScope: "global" });

  const activeLocale = computed(() =>
    resolveLocale(locale.value, locales.value as Array<string | LocaleEntry>),
  );

  const formatNumber = (value: number, override?: Intl.NumberFormatOptions) => {
    const config = override || options.number;
    return new Intl.NumberFormat(activeLocale.value, config).format(value);
  };

  const formatCurrency = (
    value: number,
    currency = "VND",
    override?: Intl.NumberFormatOptions,
  ) => {
    const config: Intl.NumberFormatOptions = {
      style: "currency",
      currency,
      maximumFractionDigits: 0,
      ...options.currency,
      ...override,
    };
    return new Intl.NumberFormat(activeLocale.value, config).format(value);
  };

  const formatDate = (
    value: Date | string | number,
    override?: Intl.DateTimeFormatOptions,
  ) => {
    const date = value instanceof Date ? value : new Date(value);
    if (Number.isNaN(date.getTime())) {
      return "-";
    }
    return date.toLocaleDateString(
      activeLocale.value,
      override || options.date,
    );
  };

  const formatTime = (
    value: Date | string | number,
    override?: Intl.DateTimeFormatOptions,
  ) => {
    const date = value instanceof Date ? value : new Date(value);
    if (Number.isNaN(date.getTime())) {
      return "-";
    }
    return date.toLocaleTimeString(
      activeLocale.value,
      override || options.time,
    );
  };

  const formatDateTime = (
    value: Date | string | number,
    override?: Intl.DateTimeFormatOptions,
  ) => {
    const date = value instanceof Date ? value : new Date(value);
    if (Number.isNaN(date.getTime())) {
      return "-";
    }
    return date.toLocaleString(
      activeLocale.value,
      override || options.dateTime,
    );
  };

  return {
    locale: activeLocale,
    formatNumber,
    formatCurrency,
    formatDate,
    formatTime,
    formatDateTime,
  };
};
