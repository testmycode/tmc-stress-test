
# Takes task specs from the DSL and executes them in threads,
# logging to a TestOutput.
class Runner
  def initialize(env)
    @env = env
    @threads = []
  end
  
  def run_task_spec(ts)
    @threads << Thread.start do
      sleep(ts.initial_delay)
      
      threads = []
      start_time = Time.now
      time_for_single_repeat = ts.time / ts.repeats.to_f
      
      repeats_left = ts.repeats
      while repeats_left > 0
        time_left = start_time + ts.time - Time.now
        percent_time_left = time_left / ts.time.to_f
        percent_repeats_left = repeats_left / ts.repeats.to_f
        
        if percent_time_left > percent_repeats_left
          sleep time_for_single_repeat # close enough
        end
        
        threads << run_in_thread_and_log(ts.callable, ts.label)
        
        repeats_left -= 1
      end
      
      threads.each(&:join)
    end
  end
  
  def wait_until_finished
    @threads.each(&:join)
  end
  
private
  def run_in_thread_and_log(callable, label)
    Thread.start do
      call_start = Time.now
      
      begin
        env = @env
        Object.new.instance_eval { callable.call(env) }
      rescue
        error = $!
      else
        error = nil
      end
      
      time_taken = Time.now - call_start
      
      if !error
        @env.output.record_event(@env, label, time_taken)
      else
        @env.output.record_error(@env, label, time_taken, error)
      end
    end
  end
end
