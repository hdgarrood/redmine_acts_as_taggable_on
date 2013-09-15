class RedmineActsAsTaggableOn::SchemaCheck
  def initialize(opts={})
    @allow_extra_columns = opts[:allow_extra_columns]
  end

  def allow_extra_columns?
    @allow_extra_columns
  end

  def pass?
    tables_to_check.all? do |table|
      actual = obtain_structure(table)
      expected = expected_structures[table]

      structure_ok?(expected, actual)
    end
  end

  private
  def obtain_structure(table_name)
    ActiveRecord::Base.connection.columns(table_name).
      reject { |c| %w(created_at updated_at id).include? c.name }.
      map { |c| [c.name, c.type.to_s] }.
      to_set
  end

  def expected_structures
    {
      'tags' => expected_tags_structure,
      'taggings' => expected_taggings_structure,
    }
  end

  def tables_to_check
    expected_structures.keys
  end

  def expected_tags_structure
    [
      ['name', 'string'],
    ].to_set
  end

  def expected_taggings_structure
    [
      ['tag_id', 'integer'],
      ['taggable_id', 'integer'],
      ['taggable_type', 'string'],
      ['tagger_id', 'integer'],
      ['tagger_type', 'string'],
      ['context', 'string'],
    ].to_set
  end

  def structure_ok?(expected, actual)
    expected.public_send(comparison_method, actual)
  end

  def comparison_method
    allow_extra_columns? ? :== : :subset?
  end
end
