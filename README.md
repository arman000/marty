[![Build Status](https://travis-ci.org/arman000/marty.svg)](https://travis-ci.org/arman000/marty)
# Marty

Marty is a framework for viewing and reporting on versioned data.
Marty provides its own scripting environment.  Scripts can also be
verioned.  RESTful APIs are provided for accessing and executing
vesioned scripts.

Marty also provides user authentication and session support.
Currently, only LDAP-based authentication is supported.  There's also
support for role-based authorization.

# Rake tasks

The Marty framework provides several rake tasks to manage its database tables
and delorean scripts.

To create the correct migrations for a Marty-based application (see below for
getting the internal dummy application to work):

```
$ rake marty:install:migrations
```

The Marty database needs to be seeded with specific configuration
information. Before running your Marty application for the first time you will
need to run:

```
$ rake marty:seed
```

If you are using Delorean scripts in your application you can load them
with a rake task. By default these scripts will be picked up from
`app/delorean_scripts`. To load scripts:

```
$ rake marty:load_scripts
```

You can override the default directory by setting the `LOAD_DIR` environment
variable:

```
$ LOAD_DIR=<delorean script directory> marty:load_scripts
```

To delete scripts:

```
$ rake marty:delete_scripts
```

# Dummy Application & Testing

Make sure that extjs is installed (or symbolically linked) in the
dummy app at spec/dummy/public.

Docker doesn't support symlinks, so in order to run it in Docker you will have to copy extjs files.

```bash
$ cp -r PATH/TO/YOUR/EXTJS/FILES spec/dummy/public/extjs
```

You can run it with docker:

```bash
$ make dummy-app-initialise-docker

$ make dummy-app-start
```

To run tests:

```bash
$ make dummy-app-bash

$ HEADLESS=true rspec
```

To run without docker:

Marty currently only runs with postgresql. To be able to run the tests
you will first need to create a `database.yml` file in `spec/dummy/config`.
You can use the example file by doing:

```bash
$ cp spec/dummy/config/database.yml.example spec/dummy/config/database.yml
```

To initialize the dummy application for a demo run:

```bash
$ bundle install
$ bundle exec rake db:create db:migrate db:seed app:marty:load_scripts
$ cd spec/dummy
$ rails s
```

The marty dummy app should now be accessible in your browser:
`localhost:3000`

You can log in using `marty` as both user and password.

To create the test database in prepartion to run your tests:

```bash
$ RAILS_ENV=test bundle exec rake db:create
```

Then to run the tests:

```bash
$ bundle exec rspec
```

# History & Status

Marty was originally part of a much larger project internal to
PennyMac.  We have split Marty from its original home with the goal of
making it generally available as a platform for working with versioned
data and scripts. However, some rspec and cucumber tests are still in
the parent and have yet to be ported. Also, documentation is sorely
lacking. Hopefully, this will be rectified soon.
