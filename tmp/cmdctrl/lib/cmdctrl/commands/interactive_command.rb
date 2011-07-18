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
require 'cmdctrl/commands/command'
require 'pty'
require 'termios'
require 'tmpdir'
require 'thread'
require 'date'

module CmdCtrl
  module Commands

    # Container class representing a command to run or running interactively in a pty
    class InteractiveCommand < Command

      # Creats a new command from the command line
      def initialize(cmd)
        super(cmd)
        @status_mutex = Mutex::new
        @status_condition = ConditionVariable::new
      end

      # Runs the command created
      def run
        @path = tmpfifo
        inited = 0
        inited_mutex = Mutex::new
        inited_condition = ConditionVariable::new
        Thread::new {
            # Spawn the command redirecting the error output to the temporary FIFO created
          PTY::spawn("#{cmd} 2> #{@path}") { |r, w, p|
            begin 
              @stdout,@stdin,@pid = r,w,p
              @stderr = open(@path, 'r')
              # set flags for stdin (see termios(3))
              tio = Termios::getattr(@stdin)
              # set terminal in raw mode
              tio.c_iflag &= ~(Termios::IGNBRK|Termios::BRKINT|Termios::PARMRK|Termios::ISTRIP|Termios::INLCR|Termios::IGNCR|Termios::ICRNL|Termios::IXON)
              tio.c_oflag &= ~(Termios::OPOST)
              tio.c_lflag &= ~(Termios::ECHO|Termios::ECHONL|Termios::ICANON|Termios::ISIG|Termios::IEXTEN)
              tio.c_cflag &= ~(Termios::CSIZE|Termios::PARENB)
              tio.c_cflag |= Termios::CS8
              Termios::setattr(@stdin, Termios::TCSANOW, tio)
              inited_mutex.synchronize do
                inited = 1
                inited_condition.signal
              end
              sleep while true
            rescue PTY::ChildExited => e
              @status_mutex.synchronize do
                @status = e.status
              end
              @status_condition.broadcast
            ensure
              removefifo
            end
          }
        }
        inited_mutex.synchronize do
          if inited == 0
            inited_condition.wait(inited_mutex)
          end
        end
        @pid
      end

      def wait
        raise "Command is not running!" if @pid.nil?
        @status_mutex.synchronize do
          if not @status
            @status_condition.wait(@status_mutex)
          end
        end
        [@pid,@status]
      end

      def wait_no_hang
        raise "Command is not running!" if @pid.nil?
        result = nil
        @status_mutex.lock
        if @status
          result = [@pid,@status]
        end
        @status_mutex.unlock
        result
      end

      def status
        result = nil
        @status_mutex.lock
        result = @status
        @status_mutex.unlock
        result
      end

      private

      # Closes the fifo used for stderr after command exited
      def removefifo
        File.unlink(@path) rescue STDERR.puts("rm <#{ @path }> failed")
        self
      end

      # Creates a temporary FIFO
      def tmpfifo
        path = nil
        50.times do |i|
          tpath = File.join(Dir.tmpdir, "#{ $$ }.#{ rand }.#{ i }")
          system "mkfifo #{ tpath }"
          next unless $? == 0
          path = tpath
          break
        end
        raise "Could not generate tmpfifo" unless path
        path
      end
    end
  end
end
