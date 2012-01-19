require 'pathname'
require 'yaml'

class TestConfig
  def initialize
    @config = YAML.load_file(self.class.default_config_file_path)
    if self.class.config_file_path.exist?
      @config.merge!(YAML.load_file(self.class.config_file_path))
    end
  end

  def [](name)
    @config[name]
  end

private
  def self.default_config_file_path
    Paths.root_path + 'config.defaults.yml'
  end
  
  def self.config_file_path
    Paths.root_path + 'config.yml'
  end
end
