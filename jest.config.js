const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
  ...jestConfig,

  // ✅ keep your existing setting
  modulePathIgnorePatterns: ["<rootDir>/.localdevserver"],

  // ✅ ADD these for coverage
  collectCoverage: true,
  collectCoverageFrom: [
    "force-app/main/default/lwc/**/*.js",
    "!**/__tests__/**"
  ]
};
