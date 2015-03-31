Things to remove/deprecate from Gemini

- `spec/job_helper.rb` (it looks like it only appears in Marty specs)
- `db/seed.rb` contains a fair amount of Marty:: class method calls (including stuff that specifically said it belongs with Marty).
