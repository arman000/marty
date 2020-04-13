module.exports = {
  env: {
    browser: true,
    es6: true
  },
  extends: ["eslint:recommended", "prettier"],
  globals: {
    RailsApp: "writable",
    ActionCable: "readonly",
    Ext: "readonly",
    CodeMirror: "readonly",
    module: "writable",
    process: "readonly"
  },
  parserOptions: {
    ecmaVersion: 6
  },
  plugins: ["prettier"],
  rules: {
    "no-var": ["error"],
    "prefer-const": ["error"],
    "linebreak-style": ["error", "unix"],
    "quotes": [2, "double", { avoidEscape: true }],
    "no-unused-vars": [
      "error",
      { args: "after-used", argsIgnorePattern: "^_" }
    ],
    "object-shorthand": ["error", "always"],
    "no-constant-condition": ["error", { checkLoops: false }]
  }
};
