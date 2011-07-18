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
#!/usr/bin/ruby -w

[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }

# search for data files
[ 'test/data/', 'data/'].each { |d| DATADIR=d if File::directory?(d) }

require 'cmdctrl/commands'
require 'test/unit'

include CmdCtrl::Commands

# Tests CmdCtrl::Commands::*
class CommandsTest < Test::Unit::TestCase
  def test_command_bufferer
    # works only because sh doesn't buffer separate commands
    c = CommandBufferer::new(Command::new('echo blop1; sleep 2; echo blop2; echo blop3 > /dev/stderr'))
    c.run
    sleep 1
    assert_equal("blop1\n", c.read_stdout)
    c.wait
    assert_equal("blop2\n", c.read_stdout)
    assert_equal("blop3\n", c.read_stderr)
  end

  def test_command_bufferer_large_output
    number = 5000
    c = CommandBufferer::new(Command::new("for i in $(seq 1 #{number}); do echo \"ABCDEFGHIJKLMNOPQRSTUVWXYZ\"; done"))
    c.run
    assert(!c.exited?)
    sleep 2
    assert(c.exited?)
    c.wait
    assert_equal("ABCDEFGHIJKLMNOPQRSTUVWXYZ\n" * number, c.read_stdout)
  end

  def test_command_interactivecommand
    c = CommandBufferer::new(InteractiveCommand::new(DATADIR + 'dialog.rb'))
    c.run
    (1..5).each do |i|
      sleep 0.1
      assert_equal("Question #{i} ?\n", c.gets_stdout)
      c.puts("Answer #{i * 2}")
      sleep 0.1
      assert_equal("Read: Answer #{i*2}\n", c.gets)
    end
    c.wait
    assert_equal(0, c.status)
  end

  def test_command_interactivecommand_stderr
    c = CommandBufferer::new(InteractiveCommand::new(DATADIR + 'dialog_err.rb'))
    c.run
    (1..5).each do |i|
      sleep 0.1
      assert_equal("Question #{i} ?\n", c.read_stderr)
      c.puts("Answer #{i * 2}")
      sleep 0.1
      assert_equal("Read: Answer #{i*2}\n", c.gets_stderr)
    end
    c.wait
    assert_equal(0, c.status)
  end

  def test_finished
    c = Command::new("sleep 0.5")
    c.run
    assert(!c.exited?)
    sleep 0.6
    assert(c.exited?)
    c.close_fds
  end

  def test_kill
    c = Command::new("sleep 0.5")
    c.run
    assert(!c.exited?)
    c.kill(9)
    sleep 0.1
    assert(c.exited?)
    c.close_fds
  end

  def test_finished_interactive
    c = InteractiveCommand::new("sleep 0.5")
    c.run
    assert(!c.exited?)
    sleep 0.6
    assert(c.exited?)
    c.close_fds
  end

  def test_multi_cmd
    t = []
    5.times do
      t << CommandBufferer::new(Command::new('echo blop1; sleep 0.5; echo blop2 > /dev/stderr; exit 1'))
    end
    tstart = Time::new
    t.each do |i|
      i.run
    end
    t.each do |i|
      i.wait
    end
    tstop = Time::new
    assert( (tstop - tstart) < 1.0)
  end

  def test_multi_cmd_interactive
    t = []
    5.times do
      t << CommandBufferer::new(InteractiveCommand::new('sleep 0.5'))
    end
    tstart = Time::new
    t.each do |i|
      i.run
    end
    t.each do |i|
      i.wait
    end
    tstop = Time::new
    assert((tstop - tstart) < 1.0)
  end

  def test_callbacks_on_exit
    nbth = 5
    t = []
    nbth.times do
      t << CommandBufferer::new(Command::new('sleep 0.5'))
    end
    ncall = 0
    t.each do |c|
      c.on_exit do |status, cmd|
        ncall += 1
      end
    end
    t.each do |c|
      c.run
    end
    sleep 1
    t.each do |c|
      assert(c.exited?)
    end
  end

  def test_callbacks_on_exit_interactive
    nbth = 5
    t = []
    nbth.times do
      t << CommandBufferer::new(InteractiveCommand::new('sleep 0.5'))
    end
    ncall = 0
    t.each do |c|
      c.on_exit do |status, cmd|
        ncall += 1
      end
    end
    t.each do |c|
      c.run
    end
    sleep 1
    t.each do |c|
      assert(c.exited?)
    end
  end

  def test_callbacks_on_output_stdout
    nbth = 5
    t = []
    nbth.times do
      t << CommandBufferer::new(Command::new('sleep 0.5; echo blop; sleep 0.5; echo blop2; sleep 0.5'))
    end
    tstart = Time::new
    m = Mutex::new
    ncall = 0
    t.each do |c|
      c.on_output_stdout do |text, cmd|
        t = Time::new - tstart
        if text == "blop\n"
          assert(t >= 0.5 && t < 0.8)
        elsif text == "blop2\n"
          assert(t >= 1.0 && t < 1.2)
        else
          raise "Unknown text"
        end
        m.synchronize { ncall += 1 }
      end
    end
    t.each do |c|
      c.run
    end
    t.each do |c|
      c.wait
    end
    assert_equal(2*nbth, ncall)
  end

  def test_callbacks_on_output_stderr
    nbth = 5
    t = []
    nbth.times do
      t << CommandBufferer::new(Command::new('sleep 0.5; echo blop > /dev/stderr; sleep 0.5; echo blop2 > /dev/stderr; sleep 0.5'))
    end
    tstart = Time::new
    m = Mutex::new
    ncall = 0
    t.each do |c|
      c.on_output_stderr do |text, cmd|
        t = Time::new - tstart
        if text == "blop\n"
          assert(t >= 0.5 && t < 0.8)
        elsif text == "blop2\n"
          assert(t >= 1.0 && t < 1.2)
        else
          raise "Unknown text"
        end
        m.synchronize { ncall += 1 }
      end
    end
    t.each do |c|
      c.run
    end
    t.each do |c|
      c.wait
    end
    assert_equal(2*nbth, ncall)
  end

  def start_thread
    start_time = Time::new.to_f
    c = CommandBufferer::new(Command::new('sleep 0.5'))
    c.on_exit do
      t = Time::new.to_f - start_time
      assert( t < 0.6 && t >= 0.5)
      @m.synchronize do 
        if @nbth < @nbthmax
          @nbth += 1
          start_thread
        end
      end
    end
    c.run
  end

  def test_callbacks_on_exit_chaining
    simult = 4
    @m = Mutex::new
    @nbth = 0
    @nbthmax = 20
    simult.times do
      @m.synchronize { @nbth += 1 }
      start_thread
    end
    sleep 3
  end

  def test_save_stdout
    c = CommandBufferer::new(Command::new('echo blop1; sleep 2; echo blop2; echo blop3 > /dev/stderr'))
    c.run
    sleep 1
    assert_equal("blop1\n", c.read_stdout)
    c.wait
    c.save_stdout("toto2132154.txt")
    assert_equal("blop2\n", c.read_stdout)
    assert_equal("blop3\n", c.read_stderr)
    assert(File::delete("toto2132154.txt"))
  end

  def test_wait_on_exit
    c = CommandBufferer::new(Command::new("echo blop1"))
    on_exit_done = false
    c.on_exit { on_exit_done = true }
    c.run
    c.wait_on_exit
    assert_equal(true, on_exit_done)
  end
end
