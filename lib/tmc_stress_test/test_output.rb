require 'thread'

# Thread-safe output sink
class TestOutput
  def initialize(sink, error_sink = $stderr)
    @sink = sink
    @error_sink = error_sink
    @mutex = Mutex.new
    
    @sink << "# label  time_finished  time_taken  error\n"
    @sink.flush
  end
  
  def record_event(env, name, time_taken)
    @mutex.synchronize do
      @sink << name << space << time_offset(env, time_taken) << space << time_taken << space << "0\n"
      @sink.flush
    end
  end
  
  def record_error(env, name, time_taken, exception)
    @mutex.synchronize do
      @sink << name << space << time_offset(env, time_taken) << space << time_taken << space << "1\n"
      @sink.flush
      @error_sink << "Error (" << name << "): " << exception.message << "\n  " << exception.backtrace.join("\n  ") << "\n"
      @error_sink.flush
    end
  end
  
private
  def space
    "  "
  end

  def time_offset(env, time_taken)
    (Time.now - env.start_time - time_taken).to_s
  end
end
