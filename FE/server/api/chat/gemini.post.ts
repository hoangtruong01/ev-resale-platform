export default defineEventHandler(() => {
  throw createError({
    statusCode: 410,
    statusMessage:
      "Deprecated AI route. Use the shared backend POST /api/ai/chat endpoint.",
  });
});
