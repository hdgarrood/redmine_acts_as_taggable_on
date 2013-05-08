require 'redmine'
require 'acts-as-taggable-on'
require 'redmine_acts_as_taggable_on/migration'
require 'redmine_acts_as_taggable_on/redmine_plugin_patch'

unless Redmine::Plugin.included_modules.include? RedmineActsAsTaggableOn::RedminePluginPatch
  Redmine::Plugin.send(:include, RedmineActsAsTaggableOn::RedminePluginPatch)
end
