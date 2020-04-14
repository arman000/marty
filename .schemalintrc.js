module.exports = {
  connection: {
    host: process.env["POSTGRES_HOST"] || "localhost",
    user: process.env["POSTGRES_USER"] || "postgres",
    password: process.env["POSTGRES_PASSWORD"] || "postgres",
    database: process.env["POSTGRES_DB_NAME"] || "marty_dev",
    charset: "utf8"
  },

  // plugins: ['./custom-rules'],

  rules: {
    "name-casing": ["error", "snake"],
    "name-inflection": ["error", "plural"],
    "prefer-jsonb-to-json": ["error"]
    // FIXME: user varchar with no size limit instead
    // We would need to update lib so it would return column size info
    // And create our own rule that checks that
    // "prefer-text-to-varchar": ["error"]
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
