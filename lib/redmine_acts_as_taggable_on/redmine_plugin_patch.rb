module RedmineActsAsTaggableOn::RedminePluginPatch
  def requires_acts_as_taggable_on
    @requires_acts_as_taggable_on = true
  end

  def requires_acts_as_taggable_on?
    # TODO: grep through Gemfile for acts-as-taggable-on in order to work with
    # plugins which don't use this gem
    !!@requires_acts_as_taggable_on
  end
end
