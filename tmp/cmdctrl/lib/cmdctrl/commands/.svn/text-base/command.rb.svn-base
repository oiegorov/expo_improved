=begin
    Copyright (C) 2007  Brice Videau

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
require 'thread'
require 'date'

module CmdCtrl
  module Commands

    # Container class representing a command to run or running
    class Command

      # File descriptors
      attr_reader :stdin, :stdout, :stderr

      # Command lauched
      attr_reader :cmd

      # PID of command
      attr_reader :pid

      # Exit status of command
      attr_reader :status

      # Creates a command using either a command line to execute or a block
      def initialize(cmd = nil, &block)
        @cmd = cmd
        @block = block
        raise "No command nor block passed to Command::new" if @cmd.nil? and @block.nil?
        raise "command and block passed to Command::new" if not (@cmd.nil? or @block.nil?)
        @status = nil
        @pid = nil
       end

      # Runs the created command
      def run
	@mystdin, @stdin = IO::pipe
        @stdout, @mystdout = IO::pipe
        @stderr, @mystderr = IO::pipe

        @pid = fork do
          close_fds
          @mystdout.sync = true
          @mystderr.sync = true
          STDIN.reopen(@mystdin)
          STDOUT.reopen(@mystdout)
          STDERR.reopen(@mystderr)
          if @cmd
            exec(cmd)
          else # use the block
            v = @block.call
            if v.kind_of?(Integer)
              exit(v)
            else
              exit(0)
            end
          end
        end
        close_internal_fds
        @pid
      end

      def kill( signal )
        raise "Command is not running!" if @pid.nil?
        Process::kill( signal, @pid ) if not exited?
      end

      # Waits for the command to exit end returns [ pid, status ]
      def wait
        raise "Command is not running!" if @pid.nil?
        if not @status
          result = Process::waitpid2(@pid)
          pid, @status = result
        end
        [@pid,@status]
      end

      # Checks if the command exited, returns nil if not and [ pid, status ] if yes
      def wait_no_hang
        raise "Command is not running!" if @pid.nil?
        if not @status
          result = Process::waitpid2(@pid,Process::WNOHANG)
          if result
            pid, @status = result
          end
          return result
        else
          [@pid,@status]
        end
      end

      # Returns true if the command exited false unless
      def exited?
        return wait_no_hang != nil
      end
      
      # Close file descriptors. You need to call this when you have finished
      # reading all pending data.
      def close_fds
        @stdin.close unless @stdin.closed? or @stdin == STDIN
        @stdout.close unless @stdout.closed? or @stdout == STDOUT
        @stderr.close unless @stderr.closed? or @stderr == STDERR
      end

      private

      # Closes the open file descriptors
      def close_internal_fds
        @mystdin.close unless @mystdin.closed? or @mystdin == STDIN
        @mystdout.close unless @mystdout.closed? or @mystdout == STDOUT
        @mystderr.close unless @mystderr.closed? or @mystderr == STDERR
        self
      end
    end
  end
end
