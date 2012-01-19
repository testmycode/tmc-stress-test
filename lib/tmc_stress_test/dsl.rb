
require 'active_support/all'
require 'thread'
require 'tmc_stress_test/tasks'

class Dsl
  def initialize(env)
    @env = env
    @task_specs = []
  end
  
  attr_reader :task_specs
  
  def evaluate_script(script = nil, &block)
    if script
      instance_eval(script)
    else
      instance_eval(&block)
    end
  end
  
  def method_missing(name, *args, &block)
    ts = TaskSpec.new(@env, name)
    @task_specs << ts.send(name, *args, &block)
    ts
  end
  
  class TaskSpec
    def initialize(env, name)
      @env = env
      @label = 'stresstest'
      @tasks = Tasks.new(@env)
      @initial_delay = 0.seconds
      @time = 1.second
      @repeats = 1
      @callable = Proc.new {}
    end
    
    attr_reader :label, :tasks, :initial_delay, :time, :repeats, :callable
    
    def after(delay, &block)
      @initial_delay = delay
      @callable = block if block
      self
    end
    
    def with_label(label, &block)
      @label = label.gsub(/\s/, '_')
      @callable = block if block
      self
    end
    
    def repeat(count, &block)
      @repeats = count
      @callable = block if block
      self
    end
    
    def times(&block) # cosmetic
      @callable = block if block
      self
    end
    
    def regularly(&block) # changes nothing yet
      @callable = block if block
      self
    end
    
    def over(time, &block)
      @time = time
      @callable = block if block
      self
    end
  end
end
