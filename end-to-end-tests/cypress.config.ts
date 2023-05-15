import { defineConfig } from "cypress";
/** It was simply too bothersome to try figuring out adding node
 * types here as then it propagates to all our non node files
 * which was a mess of errors, and we only use a node type in one
 * place here so for now we just hack it
 */
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
// eslint-disable-next-line import/no-nodejs-modules
import fs from "fs";

// eslint-disable-next-line import/no-default-export
export default defineConfig({
  viewportWidth: 375,
  viewportHeight: 667,
  videoUploadOnPasses: false,
  video: false,
  experimentalMemoryManagement: true,
  retries: {
    runMode: 2,
    openMode: 0,
  },
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
