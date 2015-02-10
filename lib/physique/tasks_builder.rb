require 'physique/dsl'
require 'physique/tool_locator'

module Physique
  class TasksBuilder
    include Albacore::Logging
    include Physique::DSL
    include Physique::ToolLocator

    @subclasses = []

    class << self
      attr_reader :subclasses
    end

    def self.inherited(subclass)
      TasksBuilder.subclasses << subclass
    end

    attr_reader :solution

    def self.build_tasks_for(solution)
      TasksBuilder.subclasses.each do |builder_class|
        builder_class.new.build_tasks_for solution
      end
    end

    def build_tasks_for(solution)
      @solution = solution
      build_tasks
    end

    def build_tasks
      raise 'This method must be implemented in your subclass'
    end

    def ensure_output_location(path)
      # Ensure output directory exists
      FileUtils.mkdir_p path
    end

    def namespace(name, &block)
      name = to_string_or_symbol(name)
      Rake.application.in_namespace(name, &block)
    end

    def to_string_or_symbol(name)
      name = name.to_s if name.kind_of?(Symbol)
      name = name.to_str if name.respond_to?(:to_str)
      unless name.kind_of?(String) || name.nil?
        raise ArgumentError, 'Expected a String or Symbol for a namespace name'
      end
      name
    end
  end
end

Gem.find_files('physique/task_builders/*.rb').each { |path| require path }