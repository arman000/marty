module.exports = {
  connection: {
    host: process.env["POSTGRES_HOST"] || "localhost",
    user: process.env["POSTGRES_USER"] || "postgres",
    password: process.env["POSTGRES_PASSWORD"] || "postgres",
    database: process.env["POSTGRES_DB_NAME"] || "marty_dev",
    charset: "utf8"
  },

  plugins: ["./.schemalint-rules"],

  rules: {
    "name-casing": ["error", "snake"],
    "name-inflection": ["error", "plural"],
    "prefer-jsonb-to-json": ["error"],
    "prefer-varchar-without-size-limit": ["error"]
  },

  schemas: [{ name: "public" }],

  ignores: [
    {
      identifierPattern: ".*_rules.computed_guards.*",
      rulePattern: "prefer-jsonb-to-json"
    },
    {
      identifierPattern: ".*_rules.results.*",
      rulePattern: "prefer-jsonb-to-json"
    },
    { identifierPattern: ".*ar_internal_metadata.*", rulePattern: ".*" },
    { identifierPattern: ".*schema_migrations.*", rulePattern: ".*" },
    { identifierPattern: ".*gemini_.*", rulePattern: ".*" },
    { identifierPattern: "entities.*", rulePattern: ".*" },
    { identifierPattern: "groupings.*", rulePattern: ".*" },
    { identifierPattern: "heads.*", rulePattern: ".*" },
    { identifierPattern: "head_versions.*", rulePattern: ".*" }
  ]
};
