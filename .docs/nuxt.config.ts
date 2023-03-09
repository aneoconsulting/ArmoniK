export default defineNuxtConfig({
  app: {
    baseURL: process.env.NODE_ENV === "production" ? "/ArmoniK/" : "",
  },

  extends: "@aneoconsultingfr/armonik-docs-theme",
});
