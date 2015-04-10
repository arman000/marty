Things to remove/deprecate from Gemini

- The duplicate tests from the `marty` spec subdirectories:
  - `factories` - it doesn't look like there's any code used from there so it can probably just be removed.
  - `lib` - `data_import_spec.rb` needs to remain in Gemini for the time being (see notes in INDEPENDENCE_ISSUES). `data_blame_spec.rb`
  is Gemini-specific and should be moved into the Gemini specs proper. All other specs should be removed.
  - `models` - all specs can be removed.
  - `controllers` - all specs can be removed.
  - `features/javascript` - this doesn't appear to do anything useful and can probably be removed.
- `spec/job_helper.rb` (it looks like it only appears in Marty specs)
- `db/seed.rb` contains a fair amount of Marty:: class method calls (including stuff that specifically said it belongs with Marty).
