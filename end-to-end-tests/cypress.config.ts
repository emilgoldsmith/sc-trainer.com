/* eslint-disable import/no-nodejs-modules */
import { defineConfig } from "cypress";
import fs from "fs";

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
  // For @cypress/snapshots package
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  useRelativeSnapshots: true,
  e2e: {
    baseUrl: "http://localhost:4000",
    setupNodeEvents(on) {
      // This task is for the @cypress/snapshot package
      on("task", {
        readFileMaybe(filename) {
          if (fs.existsSync(filename)) {
            return fs.readFileSync(filename, "utf8");
          }

          return null;
        },
      });
    },
  },
});
