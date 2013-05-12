#!/usr/bin/env bash

# Create a plugin which uses the gem properly. It's given the name redmine_$1
mk_proper_plugin() {
  local name="redmine_$1"
  mkdir plugins/$name
  cd plugins/$name

  echo "gem 'redmine_acts_as_taggable_on',
  :path => '$redmine_acts_as_taggable_on_path'" > Gemfile

  echo "require 'redmine_acts_as_taggable_on/initialize'
Redmine::Plugin.register(:$name) { requires_acts_as_taggable_on }" \
    > init.rb

  mkdir -p db/migrate
  echo "class AddTagsAndTaggings < RedmineActsAsTaggableOn::Migration; end" \
    > db/migrate/001_add_tags_and_taggings.rb

  bundle >/dev/null

  cd ../..
}

db_query() {
  # use -init to ensure ~/.sqliterc isn't read
  sqlite3 -init "" db/redmine.sqlite3 "$1"
}

db_table_exists() {
  db_query "SELECT 'it exists'
  FROM sqlite_master
  WHERE type='table' AND name='$1'" | grep 'it exists' >/dev/null

  exists="$?"
  if [ "$exists" -eq 1 ]; then
      echo "Database table $1 exists."
  else
      echo "Database table $1 does not exist."
  fi

  return $exists
}
