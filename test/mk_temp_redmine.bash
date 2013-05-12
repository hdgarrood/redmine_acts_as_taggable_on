#!/usr/bin/env bash
set -e

# makes a new Redmine installation in a temporary directory, using SQLite as
# the database.
make_temp_redmine() {
  local branch="$1"
  [ -z "$branch" ] && branch="trunk"

  # for branches which have slashes in them, like tags/2.3.0
  local branch_filename="${branch//\//-}"
  temp_redmine=`mktemp -d /tmp/redmine_acts_as_taggable_on.$branch_filename.XXXXXXX`
  pushd "$temp_redmine"

  svn checkout "http://svn.redmine.org/redmine/$branch" redmine
  pushd redmine

  echo "production:
  adapter: sqlite3
  database: db/redmine.sqlite3" > config/database.yml

  bundle install \
    --without="postgresql development test mysql rmagick ldap"
  rake generate_secret_token db:create db:migrate

  popd
  popd
}

make_temp_redmine "$1" >/dev/null
echo "$temp_redmine"
