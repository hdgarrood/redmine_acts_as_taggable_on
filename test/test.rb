require 'tmpdir'
require 'fileutils'

module RedmineActsAsTaggableOn::TestHelpers
  def assert_system(*args)
    expect(system(*args)).to eq(true)
  end

  def redmine_svn_root
    "http://svn.redmine.org/redmine"
  end

  def database_yml_data
    %q{---
development:
  adapter: sqlite3
  database: db/redmine.sqlite3
}
  end

  def remove_all_plugins!
    FileUtils.rm_rf 'plugins/*'
  end

  def recreate_db
    assert_system "rake db:drop db:create db:migrate"
  end

  def make_temporary_redmine_installation
    dir = Dir.mktmpdir('redmine_acts_as_taggable_on_test_')
    Dir.chdir(dir)

    assert_system "svn checkout #{redmine_svn_root}/trunk redmine >/dev/null"

    Dir.chdir("redmine")
    File.open("config/database.yml", "w") do |f|
      f.write database_yml_data
    end

    assert_system "bundle install --without development test ldap openid rmagick >/dev/null"
    assert_system "rake generate_secret_token >/dev/null"
    assert_system "rake db:migrate >/dev/null"
    dir
  end

  def migrate_plugin(name, direction = :up)
    cmd = "rake redmine:plugins:migrate NAME=#{name}"
    cmd << " VERSION=0" if direction == :down

    assert_system cmd
  end

  def migrate_all_plugins(direction = :up)
    cmd = "rake redmine:plugins:migrate"
    cmd << " VERSION=0" if direction == :down

    assert_system cmd
  end

  # a SQLite3::Database object
  def database
    @database ||= SQLite3::Database.open('db/redmine.sqlite3')
  end

  def table_exists?(name)
    database.get_first_value(
      "SELECT 1 FROM sqlite_master WHERE name=? AND type='table'",
      name) == 1
  end
end

describe RedmineActsAsTaggableOn do
  include RedmineActsAsTaggableOn::TestHelpers
  before(:all)  { @temporary_dir = make_temporary_redmine_installation }
  after(:all)   { FileUtils.rm_rf @temporary_dir }
  before(:each) { remove_all_plugins; recreate_db }

  it "should migrate upwards" do
    NewStylePlugin.create('redmine_foo')
    migrate_plugin('redmine_foo')
    expect(table_exists?('tags')).to eq(true)
  end

  it "should migrate downwards" do
    NewStylePlugin.create('redmine_foo')
    migrate_plugin('redmine_foo')
    migrate_plugin('redmine_foo', :down)
    expect(table_exists?('tags')).to eq(false)
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
