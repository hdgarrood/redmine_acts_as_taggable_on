#!/usr/bin/env bats

load test_helpers

# files which should be backed up and restored to how they were at the start
# between each test
preserved_files=(db/redmine.sqlite3 db/schema.rb)

setup() {
  pushd "$temp_redmine_path/redmine" >/dev/null
  for file in ${preserved_files[@]}; do
      cp $file $file.bak
  done
}

teardown() {
  rm -rf plugins/*
  for file in ${preserved_files[@]}; do
      mv $file.bak $file
  done
  popd >/dev/null
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
  assert_contain 'Not creating "tags" and "taggings"' "$output"

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
  assert_contain 'Not dropping "tags" and "taggings"' "$output"

  # Should say still needed by redmine_bar
  assert_contain '-> redmine_bar' "$output"
  # Should not say still needed by redmine_foo
  ! assert_contain '-> redmine_foo' "$output"

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
  mk_standard_plugin "baz"

  mkdir -p plugins/redmine_baz/db/migrate
  echo "class AddTags < ActiveRecord::Migration
  def up
    create_table :tags do |t|
      t.integer :foo
    end
  end

  def down
    drop_table :tags
  end
end" > plugins/redmine_baz/db/migrate/001_add_tags.rb

  rake redmine:plugins:migrate

  mk_proper_plugin "foo"
  run rake redmine:plugins:migrate
  [ "$status" -ne 0 ]
  assert_contain 'table does not match' "$output"
}

@test "enforces that declarations were made" {
  mk_plugin_missing_declaration "quux"

  run rake redmine:plugins:migrate
  [ "$status" -ne 0 ]
  echo "$output"
  assert_contain 'You have to declare that you need' "$output"
}

@test "warns about acts-as-taggable-on when going up" {
  mk_proper_plugin "foo"
  mk_old_style_plugin "bar"

  run rake redmine:plugins:migrate
  [ "$status" -eq 0 ]
  echo "$output"
  assert_contain "WARNING: The plugin redmine_bar is using 'acts-" "$output"
}

@test "warns about acts-as-taggable-on when going down" {
  mk_proper_plugin "foo"
  mk_old_style_plugin "bar"

  rake redmine:plugins:migrate

  # Note that we have to migrate redmine_foo down so that the
  # RedmineActsAsTaggableOn::Migration class does the migration, because it
  # does the checking. Migrating redmine_bar down would not trigger the
  # warning.
  run rake redmine:plugins:migrate NAME=redmine_foo VERSION=0
  [ "$status" -eq 0 ]
  echo "$output"
  assert_contain "WARNING: The plugin redmine_bar is using 'acts-" "$output"
}
