require 'generators/acts_as_taggable_on/migration/templates/active_record/migration'

class RedmineActsAsTaggableOn::Migration < ActsAsTaggableOnMigration
  def up
    enforce_declarations!

    if performed?
      say 'Not creating "tags" and "taggings" because they already exist'
    else
      super
    end
  end

  def down
    enforce_declarations!

    if ok_to_go_down?
      super
    else
      say 'Not dropping "tags" and "taggings" because they\'re still needed by'
      say 'the following plugins:'
      requiring_plugins.each { |p| say p.id, true }
    end
  end

  private
  def performed?
    ['tags', 'taggings'].any? do |table|
      ActiveRecord::Base.connection.table_exists? table
    end
  end

  def requiring_plugins
    Redmine::Plugin.all.select(&:requires_acts_as_taggable_on?)
  end

  # if only one plugin requires acts_as_taggable_on and we're trying to migrate
  # down, then that's ok
  def ok_to_go_down?
    requiring_plugins.count <= 1
  end

  def enforce_declarations!
    unless current_plugin_declaration_made?
      msg = "You have to declare that you need redmine_acts_as_taggable_on inside\n"
      msg << "init.rb. See https://github.com/hdgarrood/redmine_acts_as_taggable_on\n"
      msg << "for more details."
      fail msg
    end
  end

  def current_plugin_declaration_made?
    Redmine::Plugin::Migrator.current_plugin.requires_acts_as_taggable_on?
  end
end
