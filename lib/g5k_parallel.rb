require 'monitor'
require 'set'
require 'logger'

# This class encapsulates some logic to work with threads.
class Parallel
  attr_reader :logger

  def initialize(options = {})
    @threads = Set.new
    @threads.extend MonitorMixin
    @condition = @threads.new_cond
    @logger = options[:logger] || Logger.new(STDERR)
    @ignore_thread_exceptions = !!options[:ignore_thread_exceptions]
  end

  # Schedules the execution of <tt>block</tt> in its own thread.
  # Call <tt>#loop!</tt> when you have added all the parallel blocks you need and want to run the blocks.
  #
  # Use <tt>#wait!</tt> at a later stage if you want to wait for all threads launched in parallel.
  def add(env, &block)
    synchronize {
      t = Thread.new{
        Thread.current.abort_on_exception = true
        begin
          block.call(env)
        rescue Timeout::Error, StandardError => e
          logger.error "[#{env[:site]}] Received exception: #{e.class.name} - #{e.message}"
          e.backtrace.each {|b| logger.debug b}
          raise e unless @ignore_thread_exceptions
        end
      }
      @threads.add t
    }
    self
  end

  # Loop and call <tt>Thread#join</tt> over all threads registered via <tt>#add</tt>.
  def loop!
    signaled = false
    # Until all threads are finished, regularly check if they are all
    # waiting for each other, and if so, broadcast the signal to unlock
    # them.
    # We do it in the master thread instead of in the <tt>#wait!</tt>
    # method because threads can crash, and then the broadcast would 
    # not occur.
    @threads.each do |t|
      until t.join(1) do   
        synchronize {
          if !signaled && @threads.select{|t| 
            t.alive?
          }.all?{|t| t[:waiting]} then
            @condition.broadcast
            signaled = true
          end
        }
      end
    end
    self
  end

  def synchronize(&block)
    @threads.synchronize(&block)
  end

  # Wait for all other threads before resuming execution of the current thread.
  def wait!
    synchronize {
      if thread = @threads.find{|t| t == Thread.current}
        thread[:waiting] = true
        @condition.wait
        thread[:waiting] = false
      end
    }
    self
  end

end # class Parallel
