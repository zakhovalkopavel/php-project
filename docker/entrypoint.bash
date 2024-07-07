#!/bin/bash
set -m
php-fpm &
crond -b -l 0 -L /var/log/php/cron.log
fg %1