# redmine_acts_as_taggable_on

`redmine_acts_as_taggable_on` is a gem which allows multiple Redmine plugins to
use the tables provided by `acts-as-taggable-on` without stepping on each
others' toes.

## How it works

The problem we ran into when we discovered that both `redmine_tags` and
`redmine_knowledgebase` want to use the `acts-as-taggable-on` gem is that after
either is installed, the migration for the other fails, since the database
tables already exist.

Additionally, the plugins must choose between two less than ideal options when
uninstalling:

* Drop the tables, destroying data which may still be in use by another plugin
* Leave the tables there, violating the user's expectation that the database
  should be back to how it was before the plugin was installed

`redmine_acts_as_taggable_on` solves this issue by giving Redmine plugins a
mechanism to declare that they require these tables, and providing intelligent
migrations which only drop the tables when no other plugins are using them.

`redmine_acts_as_taggable_on` also provides a limited defence against plugins
which directly depend on `acts-as-taggable-on` by grepping through their
Gemfiles for the string `acts-as-taggable-on`, and treating them the same way
as plugins which use this gem, together with a gentle(-ish) suggestion to
use this gem instead.

## Status

* No known bugs
* Tested with Redmine trunk (as of 2013-09-05) only
* Not yet used by any Redmine plugins in the wild

## Limitations

This plugin cannot currently protect against situations where a plugin directly
using `acts-as-taggable-on` has put the generated migration into its
db/migrate, and the Redmine admin tries to uninstall it.

I'm in two minds about whether to fix this: one the one hand, it would require
some nasty hackery, and it's no worse than the current situation. On the other, 
losing one's data is not fun.

## Setup

Add it to your plugin's Gemfile:

    gem 'redmine_acts_as_taggable_on', '~> 0.1'

Add the migration:

    echo 'class AddTagsAndTaggings < RedmineActsAsTaggableOn::Migration; end' \
        > db/migrate/001_add_tags_and_taggings.rb

Declare that your plugin needs `redmine_acts_as_taggable_on` inside init.rb:

    require 'redmine_acts_as_taggable_on/initialize'

    Redmine::Plugin.register :my_plugin do
      requires_acts_as_taggable_on
      ...

That's it. Your plugin should now migrate up and down intelligently.
