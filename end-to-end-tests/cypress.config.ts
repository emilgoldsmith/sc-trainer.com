import { defineConfig } from "cypress";
import { initPlugin } from "cypress-plugin-snapshots/plugin";

// eslint-disable-next-line import/no-default-export
export default defineConfig({
  viewportWidth: 375,
  viewportHeight: 667,
  videoUploadOnPasses: false,
  video: false,
  retries: {
    runMode: 2,
    openMode: 0,
  },
  e2e: {
    baseUrl: "http://localhost:4000",
    setupNodeEvents(on, config) {
      initPlugin(on, config);
    },
  },
});
