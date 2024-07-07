SHELL  := /bin/bash

init: up
	git submodule init && git submodule update
restart: kill up status
kill:
	docker-compose kill && docker-compose rm -vf
up:
	docker-compose up -d --remove-orphans
status:
	docker-compose ps && docker-compose logs --tail=100
logs:
	docker-compose logs -f
pull:
	docker-compose pull
nginx-conf-reload:
	docker-compose exec nginx bash -c 'nginx -t && nginx -s reload'

php-bash:
	docker-compose exec php bash
laravel-init: laravel-create-project laravel-add-env laravel-generate-key laravel-fix-permissions restart  laravel-clear-all laravel-migrate
laravel-create-project:
	docker-compose exec php bash -c 'composer create-project laravel/laravel $$PHP_PROJECT_NAME'
laravel-clear-cache:
	docker-compose exec php bash -c 'cd laravel && php artisan cache:clear'
laravel-clear-config-cache:
	docker-compose exec php bash -c 'cd laravel && php artisan config:clear && php artisan config:cache'
laravel-clear-all:
	docker-compose exec php bash -c 'cd laravel && php artisan config:clear && php artisan cache:clear && php artisan route:clear && php artisan view:clear && php artisan optimize:clear'
laravel-fix-permissions:
	docker-compose exec php bash -c 'composer update'
	sudo chown -R $$USER:www-data ./source/laravel/
	sudo find ./source/laravel/ -type f -exec chmod 644 {} \;
	sudo find ./source/laravel/ -type d -exec chmod 755 {} \;
	sudo chmod -R 777 ./source/laravel/storage ./source/laravel/bootstrap/cache
laravel-generate-key:
	docker-compose exec php bash -c 'cd laravel && php artisan key:generate && php artisan config:cache'
laravel-add-env:
	sudo rm ./source/laravel/.env
	sudo cp .env ./source/laravel/.env
	sudo chown $$USER:www-data ./source/laravel/.env
	sudo chmod 644 ./source/laravel/.env
laravel-migrate:
	docker-compose exec php bash -c 'cd laravel && php artisan migrate'
supervisor-cli:
	docker-compose exec php supervisorctl
redis-cli:
	docker-compose exec redis redis-cli

mysql-cli:
	docker exec -it `docker-compose ps -q mysql` bash -c 'export MYSQL_PWD=$$MYSQL_ROOT_PASSWORD; mysql -uroot'
mysql-dump:
	docker exec -i `docker-compose ps -q mysql` bash -c 'export MYSQL_PWD=$$MYSQL_ROOT_PASSWORD; mysqldump --force --opt --comments=false --quote-names --single_transaction --routines --events -uroot -h mysql $$MYSQL_DATABASE' | gzip -c > dump.sql.gz
mysql-import:
	gzip -dc dump.sql.gz | docker exec -i `docker-compose ps -q mysql` bash -c 'export MYSQL_PWD=$$MYSQL_ROOT_PASSWORD; mysql -uroot -h mysql $$MYSQL_DATABASE'
