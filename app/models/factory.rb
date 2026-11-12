module Factory

  def self.use_relative_model_naming?
    true
  end

  def self.table_name_prefix
    'factory_'.freeze
  end

end
