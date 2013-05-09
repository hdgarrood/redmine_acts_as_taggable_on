require 'tmpdir'
require 'fileutils'

REDMINE_SVN = "http://svn.redmine.org/redmine"
DATABASE_YML = <<END
---
# SQLite3 configuration example
development:
  adapter: sqlite3
  database: db/redmine.sqlite3
END

def assert_system(*args)
  unless system(*args)
    fail "system(#{args.join(', ')}) didn't exit 0 :("
  end
end

module TemporaryRedmineInstallation
  module_function
  def with_a_temporary_redmine_installation
    fail 'need a block' unless block_given?

    dir = Dir.mktmpdir('redmine_acts_as_taggable_on_test_')
    Dir.chdir(dir) do
      assert_system "svn checkout #{REDMINE_SVN}/trunk redmine --quiet"
      puts "checked out redmine trunk"
      Dir.chdir("redmine") do
        File.open("config/database.yml", "w") do |f|
          f.write DATABASE_YML
        end

        # optionally quieten ActiveRecord migrations
        File.open("config/environment.rb", "a") do |f|
          # i'm a bit naughty ;)
          f.puts "if ENV['MIGRATE_QUIETLY']"
          f.puts "  class << ActiveRecord::Migration"
          f.puts "    def verbose; false; end"
          f.puts "    def verbose=(v); v; end"
          f.puts "  end"
          f.puts "end"
        end

        assert_system "bundle install --quiet"
        assert_system "rake generate_secret_token"
        assert_system "rake db:migrate >/dev/null"
        puts "redmine installation all set up!"

        yield
      end
    end
  ensure
    FileUtils.rm_rf(dir)
  end
end

class TestRedminePlugin
  class << self
    private :new
    def create(name)
      new(name)
      nil
    end
  end

  def initialize(name)
    @name = name
    write_plugin_to_disk!
    after_initialize
  end

  private
  attr_reader :name

  # Writes all files for a redmine plugin to disk. Assumes the current
  # directory is the redmine root.
  def write_plugin_to_disk!
    plugin_dir = "plugins/#{name}"
    FileUtils.mkdir_p(plugin_dir)
    Dir.chdir(plugin_dir) do
      files.each do |filename, text|
        FileUtils.mkdir_p(File.dirname(filename))

        File.open(filename, 'w') do |f|
          f.write(text)
        end
      end
    end
  end

  # override this to produce a hash, mapping filenames to the data which should
  # be written to them.
  def files
    raise NotImplementedError, "implement me in subclasses!"
  end

  # a hook
  def after_initialize
  end
end

class NewStylePlugin < TestRedminePlugin
  def files
    {
      'init.rb' => init_rb_data,
      'Gemfile' => gemfile_data,
      'db/migrate/001_add_tags_and_taggings.rb' => migration_data
    }
  end

  def init_rb_data
    <<END
require 'redmine_acts_as_taggable_on/initialize'
Redmine::Plugin.register :#{name} do
  name '#{name}'
  requires_acts_as_taggable_on
end
END
  end

  def gemfile_data
    "gem 'redmine_acts_as_taggable_on'\n"
  end

  def migration_data
    "class AddTagsAndTaggings < RedmineActsAsTaggableOn::Migration; end\n"
  end
end

def run_tests
  TemporaryRedmineInstallation.with_a_temporary_redmine_installation do
    NewStylePlugin.create('redmine_foo')
    system 'bundle install --quiet'
    system 'rake redmine:plugins:migrate'
    puts 'waiting...'
    $stdin.gets
  end
end

if __FILE__ == $0
  run_tests
end
