=begin
    Copyright (C) 2007  Lucas Nussbaum

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
=end
require 'cmdctrl/commands'
require 'thread'
require 'stringio'

module CmdCtrl

  # This class manages the execution of several commands in parallel. It is
  # highly configurable.
  class ParallelRunner

    # The commands to run (an Array). Shouldn't be modified after 'run' is
    # called.
    attr_accessor :commands

    # The result of the execution. Should only be read after the execution
    # finished. It is an hash of ParallelRunnerResult indexed by
    # CommandBufferer
    attr_reader :results

    # Window: max number of concurrent processes running (nil => unlimited)
    attr_accessor :window

    # Timeout: we consider a command to have failed after that many seconds
    attr_accessor :timeout

    # Create a new instance of ParallelRunner with default values
    def initialize
      @commands = []
      @results = {}
      @window = nil
      @started = 0
      @mutex = Mutex::new
      @exit_block = nil
      @timeout = nil
    end

    # Start the parallel execution of the commands
    def run
      @willingtorun = @commands.clone
      run_next
    end

    # Is the execution finished ?
    def finished?
      @mutex.synchronize do
        return (@started == 0 and @willingtorun.empty?)
      end
    end

    # Defines a block to call at the end of the execution
    def on_exit(&block)
      @exit_block = block
    end
 
    # Wait until the end of the execution
    def wait
      th = Thread.current
      on_exit do
        th.wakeup
      end
      Thread.stop
    end

    # Group identical results together
    def group_results
      raise "No results yet" if @results.empty? or not finished?
      rgs = []
      @results.each_pair do |c, r|
        ok = false
        rgs.each do |rg|
          if rg.same_as(r.stdout, r.stderr, r.status, r.timeout)
            rg.commands << c
            ok = true
            break
          end
        end
        if !ok
          rgs << ParallelRunnerResultGroup::new(r.stdout, r.stderr, r.status, c, r.timeout)
        end
      end
      return rgs
    end

    def ParallelRunner::rungroup(cmds, window = nil)
      pr = ParallelRunner::new
      pr.window = window
      cmds.each do |c|
        pr.commands << CommandBufferer::new(Command::new(c))
      end
      tstart = Time::new
      pr.run
      pr.wait
      tstop = Time::new
      pr.group_results.sort.each do |rg|
        puts rg
      end
      puts sprintf("--- #{pr.commands.length} commands executed in %.2f seconds ---", (tstop - tstart))
    end

    private
    # Run next command to run
    def run_next
      @mutex.synchronize do
        return false if not (@window.nil? or @started < @window)
        return false if @willingtorun.empty?

        c = @willingtorun.shift
        pr = ParallelRunnerResult::new
        pr.command = c
        pr.stdout = ""
        pr.stderr = ""
        pr.status = nil
        pr.timeout = false
        @results[c] = pr
        @started += 1
        # what do we do when it exits ?
        c.on_exit do |status, cmd|
          @results[cmd].status = status
          @mutex.synchronize do
            @started -= 1
          end
          if finished?
            # we are done here
            @exit_block.call(pr) if @exit_block
            @exit_block = nil
          else
            run_next
          end
        end
        # setup timeout
        if @timeout
          tcmd = c
          Thread::new do
            Thread.current.abort_on_exception = true
            sleep @timeout
            @mutex.synchronize do
              if not tcmd.exited?
                @results[tcmd].timeout = true
                @started -= 1
                tcmd.on_exit do |status, cmd|
                  # do nothing
                end
              end
            end
            if finished?
              # we are done here
              @mutex.synchronize do
                @exit_block.call(pr) if @exit_block
                @exit_block = nil
              end
            else
              run_next
            end
          end
        end
        # handling new output
        c.on_output_stdout do |text, cmd|
          @results[cmd].stdout += text
        end
        c.on_output_stderr do |text, cmd|
          @results[cmd].stderr += text
        end
        # starting
        c.run
      end
      run_next
    end
  end

  # The result of the execution of a command
  ParallelRunnerResult = Struct::new(:command, :stdout, :stderr, :status, :timeout)

  # A group of identical results
  class ParallelRunnerResultGroup
    attr_accessor :stdout, :stderr, :status, :commands, :timeout

    def initialize(sout, serr, status, cmd, timeout)
      @stdout = sout
      @stderr = serr
      @status = status
      @commands = [ cmd ]
      @timeout = timeout
    end

    def same_as(stdout, stderr, status, timeout)
      return (status == @status and stdout == @stdout and (@stderr.nil? or stderr == @stderr) and timeout == @timeout)
    end

    def to_s
      s =  "#############################\n"
      s << "Commands: -------------------\n"
      @commands.each { |c| s << " #{c.cmd}\n" }
      s << "TIMED OUT!-------------------\n" if @timeout
      s << "Status: #{@status.exitstatus}\n" if @status
      s << "Stdout: ---------------------\n"
      s << @stdout.chomp + "\n" if @stdout and @stdout != ''
      if @stderr and @stderr != ''
        s << "Stderr: ---------------------\n"
        s << @stderr.chomp + "\n"
      end
      s
    end

    include Comparable
    def <=>(o)
      if o.timeout != @timeout
        return -1 if o.timeout
        return 1 if @timeout
      end
      # reverse order on purpose
      t1 = o.commands.length <=> @commands.length
      return t1 if t1 != 0
      if @status and o.status
        t2 = @status.exitstatus <=> o.status.exitstatus
        return t2 if t2 != 0
      else
        return -1 if @status
        return 1 if o.status
      end
      t3 = @stdout <=> o.stdout
      return t3 if t3 != 0
      return @stderr <=> o.stderr
    end
  end
end
