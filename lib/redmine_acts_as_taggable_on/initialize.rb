require 'redmine'
require 'acts-as-taggable-on'
require 'redmine_acts_as_taggable_on/migration'
require 'redmine_acts_as_taggable_on/redmine_plugin_patch'

module RedmineActsAsTaggableOn
  def self.initialize
    unless @initialized
      Redmine::Plugin.send(:include,
                           RedmineActsAsTaggableOn::RedminePluginPatch)
    end
    @initialized = true
  end
end

RedmineActsAsTaggableOn.initialize
