require 'generators/acts_as_taggable_on/migration/templates/active_record/migration'
require 'redmine_acts_as_taggable_on/schema_check'

class RedmineActsAsTaggableOn::Migration < ActsAsTaggableOnMigration
  def up
    enforce_declarations!
    check_for_old_style_plugins

    if ok_to_go_up?
      super
    else
      say 'Not creating "tags" and "taggings" because they already exist'
    end
  end

  def down
    enforce_declarations!

    if ok_to_go_down?
      super
    else
      say 'Not dropping "tags" and "taggings" because they\'re still needed by'
      say 'the following plugins:'
      plugins_still_using_tables.each { |p| say p.id, true }
    end
  end

  private
  def enforce_declarations!
    unless current_plugin_declaration_made?
      msg = "You have to declare that you need redmine_acts_as_taggable_on inside\n"
      msg << "init.rb. See https://github.com/hdgarrood/redmine_acts_as_taggable_on\n"
      msg << "for more details.\n\n"
      fail msg
    end
  end

  def current_plugin_declaration_made?
    current_plugin.requires_acts_as_taggable_on?
  end

  def current_plugin
    Redmine::Plugin::Migrator.current_plugin
  end

  # Check if any plugins are using acts-as-taggable-on directly; the purpose of
  # this is only to print a warning if so.
  def check_for_old_style_plugins
    Redmine::Plugin.all.each { |p| p.requires_acts_as_taggable_on? }
    nil
  end

  def ok_to_go_up?
    if tables_already_exist?
      check_schema!
      return false
    end
    true
  end

  def tables_already_exist?
    %w(tags taggings).any? do |table|
      ActiveRecord::Base.connection.table_exists? table
    end
  end

  def allow_extra_columns?
    ENV[allow_extra_columns_env_var_name]
  end

  def allow_extra_columns_env_var_name
    'SCHEMA_CHECK_ALLOW_EXTRA_COLUMNS'
  end

  def check_schema!
    check = RedmineActsAsTaggableOn::SchemaCheck.new(
      :allow_extra_columns => allow_extra_columns?)
    fail failure_message unless check.pass?
  end

  def failure_message
    msg = "A plugin is already using the \"tags\" or \"taggings\" tables, and\n"
    msg << "the structure of the table does not match the structure expected\n"
    msg << "by #{current_plugin.id}.\n\n"

    if allow_extra_columns?
      msg << "You can allow extra columns by setting the environment variable\n"
      msg << "#{allow_extra_columns_env_var_name}.\n\n"
    end
  end

  # A list of plugins which are using the acts_as_taggable_on tables (excluding
  # the current one)
  def plugins_still_using_tables
    Redmine::Plugin.all.
      select(&:using_acts_as_taggable_on_tables?).
      reject {|p| p == Redmine::Plugin::Migrator.current_plugin }
  end

  def ok_to_go_down?
    plugins_still_using_tables.empty?
  end
end
