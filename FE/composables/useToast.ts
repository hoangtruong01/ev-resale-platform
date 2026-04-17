import { computed } from "vue";
import { useState } from "#imports";

type ToastColor = "success" | "error" | "warning" | "info" | "primary";

interface ToastItem {
  id: number;
  title: string;
  description?: string;
  color: ToastColor;
  icon?: string;
  duration: number;
  createdAt: number;
}

const COLOR_ALIAS_MAP: Record<string, ToastColor> = {
  green: "success",
  red: "error",
  orange: "warning",
  blue: "info",
  success: "success",
  error: "error",
  warning: "warning",
  info: "info",
  primary: "primary",
};

const DEFAULT_DURATION = 3500;

export const useCustomToast = () => {
  const state = useState<ToastItem[]>("custom-toasts", () => []);

  const remove = (id: number) => {
    state.value = state.value.filter((toast) => toast.id !== id);
  };

  const add = (item: {
    title: string;
    description?: string;
    color?: "green" | "red" | "blue" | "orange" | string;
    icon?: string;
    duration?: number;
  }) => {
    const resolvedColor = COLOR_ALIAS_MAP[item.color ?? ""] ?? "primary";
    const duration = Number.isFinite(item.duration)
      ? Number(item.duration)
      : DEFAULT_DURATION;

    const id = Date.now() + Math.floor(Math.random() * 10_000);
    const toast: ToastItem = {
      id,
      title: item.title,
      description: item.description,
      color: resolvedColor,
      icon: item.icon,
      duration,
      createdAt: Date.now(),
    };

    state.value = [...state.value, toast];

    if (import.meta.client) {
      window.setTimeout(() => remove(id), duration);
    }
  };

  return {
    add,
    remove,
    toasts: computed(() => state.value),
  };
};
