#!/usr/bin/env bats

load test_helpers

# files which should be backed up and restored to how they were at the start
# between each test
preserved_files=(db/redmine.sqlite3 db/schema.rb)

setup() {
  pushd "$temp_redmine_path/redmine"
  for file in $preserved_files; do
      cp $file $file.bak
  done
}

teardown() {
  rm -rf plugins/*
  for file in $preserved_files; do
      mv $file.bak $file
  done
  popd
}

@test "migrates upwards with solitary proper plugin" {
  mk_proper_plugin "foo"
  rake redmine:plugins:migrate

  db_table_exists 'tags'
  db_table_exists 'taggings'
}

@test "migrates downwards with solitary proper plugin" {
  mk_proper_plugin "foo"
  rake redmine:plugins:migrate
  rake redmine:plugins:migrate NAME=redmine_foo VERSION=0

  ! db_table_exists 'tags'
  ! db_table_exists 'taggings'
}

@test "migrates upwards with two proper plugins" {
  mk_proper_plugin "foo"
  rake redmine:plugins:migrate

  mk_proper_plugin "bar"
  run rake redmine:plugins:migrate
  [ "$status" -eq 0 ]
  [[ "$output" == *'Not creating "tags" and "taggings"'* ]]

  db_table_exists 'tags'
  db_table_exists 'taggings'
}

@test "doesn't drop tables when another proper plugin exists" {
  mk_proper_plugin "foo"
  mk_proper_plugin "bar"

  rake redmine:plugins:migrate

  echo 'Now migrating down...'
  run rake redmine:plugins:migrate NAME=redmine_foo VERSION=0
  [ "$status" -eq 0 ]
  [[ "$output" == *'Not dropping "tags" and "taggings"'* ]]

  # Should say still needed by redmine_bar
  [[ "$output" == *'-> redmine_bar'* ]]
  # Should not say still needed by redmine_foo
  [[ "$output" != *'-> redmine_foo'* ]]

  db_table_exists 'tags'
  db_table_exists 'taggings'
}

@test "migrates downwards with two proper plugins" {
  mk_proper_plugin "foo"
  mk_proper_plugin "bar"

  rake redmine:plugins:migrate
  rake redmine:plugins:migrate NAME=redmine_foo VERSION=0
  rake redmine:plugins:migrate NAME=redmine_bar VERSION=0

  ! db_table_exists 'tags'
  ! db_table_exists 'taggings'
}

@test "schema sanity check when migrating proper plugin up" {
}
