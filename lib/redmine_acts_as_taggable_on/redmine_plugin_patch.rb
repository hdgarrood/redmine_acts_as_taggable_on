module RedmineActsAsTaggableOn::RedminePluginPatch
  def requires_acts_as_taggable_on
    @requires_acts_as_taggable_on = true
  end

  def requires_acts_as_taggable_on?
    return true if @requires_acts_as_taggable_on

    # Safety net: If the plugin uses the acts-as-taggable-on gem the old way,
    # assume that it requires the tables.
    if File.exist?(gemfile_path)
      if File.read(gemfile_path).include? 'acts-as-taggable-on'
        warn_about_acts_as_taggable_on
        return true
      end
    end

    false
  end

  def using_acts_as_taggable_on_tables?
    return false unless requires_acts_as_taggable_on?
    return false if Redmine::Plugin::Migrator.current_version(self) == 0
    true
  end

  private
  def gemfile_path
    File.join(self.directory, 'Gemfile')
  end

  def warn_about_acts_as_taggable_on
    unless @already_warned_about_acts_as_taggable_on
      msg = "\nWARNING: The plugin #{self.id} is using 'acts-as-taggable-on',\n"
      msg << "which means that it might accidentally delete some of your data\n"
      msg << "when you uninstall it. You should badger its maintainer to switch\n"
      msg << "to https://github.com/hdgarrood/redmine_acts_as_taggable_on.\n\n"
      $stderr.write msg
    end
    @already_warned_about_acts_as_taggable_on = true
  end
end
