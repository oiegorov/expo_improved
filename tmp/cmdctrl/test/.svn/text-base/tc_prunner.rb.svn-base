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
#!/usr/bin/ruby -w

[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }

require 'cmdctrl/prunner'
require 'test/unit'

include CmdCtrl::Commands
include CmdCtrl

class PRunnerTest < Test::Unit::TestCase
  def test_prun_simple
    t = []
    5.times do
      t << CommandBufferer::new(Command::new('echo blop1; sleep 0.5; echo blop2 > /dev/stderr; exit 1'))
    end
    pr = ParallelRunner::new
    pr.commands = t
    pr.run
    tstart = Time::new
    tstop = nil
    finished = false
    pr.on_exit do |res|
      finished = true
      tstop = Time::new
    end
    assert(!pr.finished?)
    sleep 1
    assert(pr.finished?)
    assert(finished)
    pr.results.each_pair do |k,v|
      assert_equal(1, v.status.exitstatus)
      assert_equal("blop1\n", v.stdout)
      assert_equal("blop2\n", v.stderr)
    end
    assert(tstop - tstart > 0.5 && tstop - tstart < 1)
  end

  def test_prun_window_inf
    t = []
    4.times do
      t << CommandBufferer::new(Command::new('sleep 0.5'))
    end
    # first test with no window
    pr = ParallelRunner::new
    pr.commands = t
    tstart = Time::new
    pr.run
    tstop = nil
    mutex = Mutex::new
    cond = ConditionVariable::new
    pr.on_exit do |res|
      tstop = Time::new
      mutex.synchronize do
        cond.signal
      end
    end
    mutex.synchronize do
      cond.wait(mutex)
    end
    assert(pr.finished?)
    assert(tstop - tstart > 0.5 && tstop - tstart < 0.7)
  end

  # 2nd test with window = 2
  def test_prun_window_2
    t = []
    6.times do
      t << CommandBufferer::new(Command::new('sleep 0.5; echo plop'))
    end
    pr = ParallelRunner::new
    pr.commands = t
    pr.window = 2
    tstart = Time::new
    pr.run
    tstop = nil
    pr.on_exit do |res|
      tstop = Time::new
    end
    while not pr.finished?
      sleep 0.1
    end
    assert(tstop - tstart > 1.5 && tstop - tstart < 1.8)
  end

  # test with window = 16
  def test_prun_window_16
    t = []
    64.times do
      t << CommandBufferer::new(Command::new('sleep 0.5; echo plop'))
    end
    pr = ParallelRunner::new
    pr.commands = t
    pr.window = 16
    tstart = Time::new
    pr.run
    tstop = nil
    pr.on_exit do |res|
      tstop = Time::new
    end
    while not pr.finished?
      sleep 0.05
    end
    assert(tstop - tstart > 2 && tstop - tstart < 3.0)
  end

  def test_wait
    t = []
    t << CommandBufferer::new(Command::new('sleep 0.5'))
    pr = ParallelRunner::new
    pr.commands = t
    tstart = Time::new
    pr.run
    pr.wait
    tstop = Time::new
    assert(pr.finished?)
    assert(tstop - tstart > 0.5 && tstop - tstart < 0.7)
  end

  def test_prun_groupresults
    t = []
    t << CommandBufferer::new(Command::new('echo blop ; exit 1'))
    t << CommandBufferer::new(Command::new('echo blop ; exit 2'))
    t << CommandBufferer::new(Command::new('echo blop > /dev/stderr; exit 1'))
    t << CommandBufferer::new(Command::new('echo blop ; exit 1'))
    t << CommandBufferer::new(Command::new('echo blop2 ; exit 1'))
    t << CommandBufferer::new(Command::new('echo blop ; echo blopstderr > /dev/stderr; exit 1'))
    t << CommandBufferer::new(Command::new('echo -n blop ; exit 1'))
    pr = ParallelRunner::new
    pr.commands = t
    pr.run
    pr.wait
    rgs = pr.group_results.sort
    assert_equal(6, rgs.length)
#    rgs.each { |rg| puts rg }
  end

  def test_prun_timeout_1
    t = []
    t << CommandBufferer::new(Command::new('sleep 2'))
    t << CommandBufferer::new(Command::new('sleep 1.8'))
    t << CommandBufferer::new(Command::new('sleep 1.6'))
    t << CommandBufferer::new(Command::new('sleep 1.4'))
    t << CommandBufferer::new(Command::new('sleep 1.2'))
    t << CommandBufferer::new(Command::new('sleep 1'))
    pr = ParallelRunner::new
    pr.commands = t
    pr.timeout = 1.5
    pr.run
    pr.wait
    rgs = pr.group_results.sort
    assert_equal(2, rgs.length)
    assert_equal(3, rgs[0].commands.length)
    assert_equal(3, rgs[1].commands.length)
  end
end
