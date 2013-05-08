# redmine_acts_as_taggable_on

`redmine_acts_as_taggable_on` is a gem which allows multiple Redmine plugins to
use the tables provided by `acts_as_taggable_on` without stepping on each
others' toes.

## How it works

The problem we ran into when we discovered that both `redmine_tags` and
`redmine_knowledgebase` want to use the `acts_as_taggable_on` gem is that after
either is installed, the migration for the other fails, since the database
tables already exist.

Additionally, the plugins must choose between two less than ideal options when
uninstalling:

* Drop the tables, destroying data which may still be in use by another plugin
* Leave the tables there, violating the user's expectation that the database
  should be back to how it was before the plugin was installed

`redmine_acts_as_taggable_on` fixes this by giving Redmine plugins a mechanism
to declare that they require these tables, and providing intelligent migrations
which only drop the tables when no other plugins are using them.

## Status

**Not ready for production.**

This gem isn't quite there yet.

## Setup

Add it to your plugin's Gemfile:

    gem 'redmine_acts_as_taggable_on', '~> 0.1.0'

Add the migration:

    TODO

Declare that your plugin needs `redmine_acts_as_taggable_on` inside init.rb:

    Redmine::Plugin.register :my_plugin do
      requires_acts_as_taggable_on
      ...

That's it.
