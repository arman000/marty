Things to remove/deprecate from Gemini

- The duplicate tests from the `marty` spec subdirectories:
  - `lib` - `data_import_spec.rb` needs to remain in Gemini for the time being (see notes in INDEPENDENCE_ISSUES). `data_blame_spec.rb`
  is Gemini-specific and should be moved into the Gemini specs proper. All other specs should be removed.
  - `features/javascript` - this doesn't appear to do anything useful and can probably be removed.
