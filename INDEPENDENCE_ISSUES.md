Things that may affect how independent Marty can be as a gem:

* It requires a database.yml file for testing purposes.
  For now that file refers to a postgresql instance but maybe it should be
  a sqlite db instead
* User model tests shouldn't rely on `User.last` as an alternate user type.

## Things pulled from Gemini:

* `load_script_bodies`, `load_scripts`, and `load_a_script` went into `spec/support/script_helpers.rb`
  from `app/controllers/gemini/application_controller.rb` - for api, promise model, and lib specs
* Some of the category models and migrations. This may be OK since they are
  only used in testing.
* Some/most/all of the models/gemini/extras. Perhaps these are more appropriate
  as Marty items anyway.
* The `DataReport` and `Fields` (only parts) delorean scripts were needed for the data_import spec.
* Along with those Delorean scripts more gemini models were needed (and put into spec/dummy/app/models)
  Amongst them: `LoanProgram`, `*Type`, etc. They also got migrations.
