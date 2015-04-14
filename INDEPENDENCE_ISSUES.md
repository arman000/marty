# Things that may affect how independent Marty can be as a gem:

* User model tests shouldn't rely on `User.last` as an alternate user type.

## Things pulled from Gemini:

* Some of the category models and migrations. This may be OK since they are
  only used in testing.
* Some/most/all of the models/gemini/extras. Perhaps these are more appropriate
  as Marty items anyway.
* The `DataReport` and `Fields` (only parts) delorean scripts were copied into the dummy job for
  the data_import spec. Currently Gemini won't be using this version of these scripts and the
  data_import spec *must* remain in Gemini somewhere so we don't lose test coverage on what's
  being used in production. This will probably need to remain this way until we have a solution
  for making Marty be the source for these scripts (plus some of the others coming across).
  At that time these scripts should be removed from the dummy job and the tests should refer
  to them in their location in the Marty production code.

  Also, the `Fields` script used here is a small subset of only the stuff needed by `DataReport`.
  When the Marty-specific scripts are moved from Gemini `Fields will need to be broken into it's
  Marty-specific and Gemini-specific parts.
* Along with those Delorean scripts more gemini models were needed (and put into spec/dummy/app/models)
  Amongst them: `LoanProgram`, `*Type`, etc. They also got migrations.
