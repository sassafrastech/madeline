#!/bin/bash

dropdb madeline_migration
createdb madeline_migration
ssh madeline-prod "sudo -u postgres pg_dump madeline_system_production" | psql madeline_migration
bundle exec rake db:migrate

mysqladmin -u root -f drop tww_rails
mysqladmin -u root create tww_rails
echo "Copying legacy database from server"
ssh ubuntu@52.206.58.37 "ssh sassafras@72.32.43.226 \"sudo mysqldump -u root base\"" | mysql -u root tww_rails
