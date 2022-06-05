import { defineConfig } from 'cypress'

export default defineConfig({
  '//': 'testing',
  viewportWidth: 375,
  viewportHeight: 667,
  videoUploadOnPasses: false,
  video: false,
  retries: {
    runMode: 2,
    openMode: 0,
  },
  e2e: {
    // We've imported your old cypress plugins here.
    // You may want to clean this up later by importing these.
    setupNodeEvents(on, config) {
      return require('./cypress/plugins/index.ts')(on, config)
    },
    baseUrl: 'http://localhost:4000',
    specPattern: 'cypress/tests/**/*.cy.{js,jsx,ts,tsx}',
    excludeSpecPattern: '**/*.helper.ts',
  },
})
