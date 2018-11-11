dummy-app-build:
	docker-compose --file=docker-compose.dummy.yml build

dummy-app:
	docker-compose --file=docker-compose.dummy.yml up

dummy-app-start:
	docker-compose --file=docker-compose.dummy.yml up app

dummy-app-stop:
	docker-compose --file=docker-compose.dummy.yml stop

dummy-app-down:
	docker-compose --file=docker-compose.dummy.yml down

dummy-app-bash:
	docker-compose --file=docker-compose.dummy.yml run --rm app bash

dummy-app-console:
	docker-compose --file=docker-compose.dummy.yml run --rm app bin/rails c

dummy-app-initialise-docker:
	make dummy-app-install
	make dummy-app-db-prepare

dummy-app-install:
	make dummy-app-install-bundle

dummy-app-install-bundle:
	docker-compose --file=docker-compose.dummy.yml run --rm app bundle

dummy-app-db-drop:
	docker-compose --file=docker-compose.dummy.yml run --rm app rake db:drop

dummy-app-db-prepare:
	cp spec/dummy/config/database.yml.example spec/dummy/config/database.yml
	docker-compose --file=docker-compose.dummy.yml run --rm app bundle exec rake db:create db:migrate db:seed app:marty:load_scripts

dummy-app-db-seed:
	docker-compose --file=docker-compose.dummy.yml run --rm app rake db:seed


