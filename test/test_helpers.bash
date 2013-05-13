#!/usr/bin/env bash

# Create an empty skeleton Redmine plugin. It's given the name redmine_$1.
mk_standard_plugin() {
  local name="redmine_$1"
  mkdir plugins/$name
  cd plugins/$name

  echo "Redmine::Plugin.register(:$name) { name '$name' }" > init.rb

  cd ../..
  echo "Created a standard redmine plugin: $name"
}

# Create a plugin which uses the redmine_acts_as_taggable_on gem properly.
mk_proper_plugin() {
  mk_standard_plugin "$1" >/dev/null
  local name="redmine_$1"
  cd plugins/$name

  echo "source 'https://rubygems.org'
gem 'redmine_acts_as_taggable_on',
  :path => '$redmine_acts_as_taggable_on_path'" > Gemfile

  echo "require 'redmine_acts_as_taggable_on/initialize'
Redmine::Plugin.register(:$name) { requires_acts_as_taggable_on }" \
    > init.rb

  mkdir -p db/migrate
  echo "class AddTagsAndTaggings < RedmineActsAsTaggableOn::Migration; end" \
    > db/migrate/001_add_tags_and_taggings.rb

  bundle --gemfile="$PWD/Gemfile">/dev/null

  cd ../..
  echo "Created a redmine plugin using redmine_acts_as_taggable_on: $name"
}

# Create a plugin which uses redmine_acts_as_taggable_on but without the
# declaration in init.rb
mk_plugin_missing_declaration() {
  mk_proper_plugin "$1" >/dev/null
  local name="redmine_$1"
  cd plugins/$name

  echo "require 'redmine_acts_as_taggable_on/initialize'
Redmine::Plugin.register(:$name) { name '$name' }" > init.rb

  cd ../..
  echo "Created a redmine plugin using redmine_acts_as_taggable_on"
  echo "  (but without the declaration): $name"
}

# Create a plugin which uses acts-as-taggable-on directly, and which expects
# you to do rails g acts_as_taggable_on:migration yourself.
mk_old_style_plugin() {
  mk_standard_plugin "$1" >/dev/null
  local name="redmine_$1"
  cd plugins/$name

  echo "source 'https://rubygems.org'
gem 'acts-as-taggable-on'" > Gemfile
  bundle --gemfile="$PWD/Gemfile">/dev/null

  cd ../..
  echo "Created a plugin using acts-as-taggable-on without the embedded"
  echo "  migration: $name"
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

assert_contain() {
  echo -n "Checking whether a string contains '$1'... "
  if [[ "$2" == *"$1"* ]]; then
      echo "Yep."
  else
      echo "Nope."
      return 1
  fi
}
