require 'rctrl/rctrl_heap'
require 'thread'
require 'date'

module Expo
#a scheduler to run the delayed commands at the right date
class DelayedCommandScheduler

  def initialize()
    @commands = Heap::new(){ |x, y| x.scheduled_time <=> y.scheduled_time }
    @commands_to_delete = Hash::new
    @scheduler_mutex = Mutex::new
    @stopped = true
    @empty = ConditionVariable::new
    @scheduler_thread = Thread::new do
      scheduler_loop
    end
  end

  #register a command in the scheduler
  def register_command(cmd)
    @scheduler_mutex.synchronize do
      @commands.insert(cmd)
      @stopped = false
      Thread.pass until @scheduler_thread.stop?
      @scheduler_thread.run
      @empty.signal if @commands.size == 1
    end
  end

  def del_command(cmd)
    @scheduler_mutex.synchronize do
      @commands_to_delete[cmd] = true
    end
  end

  private

  def scheduler_loop()
    loop do
      sleep_time = nil
      @scheduler_mutex.synchronize do
        if @stopped then
          @empty.wait(@scheduler_mutex)
        end
        cmd = nil
        now2 = Time::now
        now = DateTime::now
        while cmd = @commands.first() and
              ( sleep_time = ( cmd.scheduled_time - now).to_f * 86400 - ( Time::now - now2 ) ) <= 0.0 do
          cmd = @commands.shift()
	  if @commands_to_delete[cmd] then
	    @commands_to_delete.delete[cmd]
	  else
            cmd.set_start_time
            cmd.cmd.run
	  end
        end
        if not cmd then
          @stopped = true
        end
      end
      if sleep_time and sleep_time > 0 then
        sleep(sleep_time)
      end
    end
  end

end
end
