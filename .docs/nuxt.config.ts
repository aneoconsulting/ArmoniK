const baseURL = process.env.NODE_ENV === "production" ? "/ArmoniK/" : "/";

export default defineNuxtConfig({
  app: {
    baseURL: baseURL,
    head: {
      link: [
        {
          rel: 'icon',
          type: 'image/ico',
          href: `${baseURL}favicon.ico`,
        }
      ]
    }
  },

  extends: "@aneoconsultingfr/armonik-docs-theme",
});
