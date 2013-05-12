require 'generators/acts_as_taggable_on/migration/templates/active_record/migration'

class RedmineActsAsTaggableOn::Migration < ActsAsTaggableOnMigration
  def up
    enforce_declarations!

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
  def ok_to_go_up?
    %w(tags taggings).all? do |table|
      !(ActiveRecord::Base.connection.table_exists? table)
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

  def enforce_declarations!
    unless current_plugin_declaration_made?
      msg = "You have to declare that you need redmine_acts_as_taggable_on inside\n"
      msg << "init.rb. See https://github.com/hdgarrood/redmine_acts_as_taggable_on\n"
      msg << "for more details.\n\n"
      fail msg
    end
  end

  def current_plugin_declaration_made?
    Redmine::Plugin::Migrator.current_plugin.requires_acts_as_taggable_on?
  end
end
