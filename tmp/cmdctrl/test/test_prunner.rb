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
#!/usr/bin/ruby

$:.unshift '../lib'

require 'cmdctrl'

def test_command1
  pin = IO::pipe
  pout = IO::pipe
  perr = IO::pipe
  c = CmdCtrl::Command::new('echo blop1; sleep 1; echo blop2 > /dev/stderr')
  c.stdin = pin[0]
  c.stdout = pout[1]
  c.stderr = perr[1]
  puts 'avant démarrage'
  c.run
  puts 'après démarrage, avant wait'
  c.wait
  puts 'après wait'
  puts 'stdout:'
  print pout[0].read
  puts 'stderr:'
  print perr[0].read
end

def test_command2
  pin = IO::pipe
  pout = IO::pipe
  c = CmdCtrl::Command::new('echo blop1; sleep 1; echo blop2 > /dev/stderr')
  c.stdin = pin[0]
  c.stdout = pout[1]
  c.stderr = pout[1]
  puts 'avant démarrage'
  c.run
  puts 'après démarrage, avant wait'
  c.wait
  puts 'après wait'
  puts 'stdout:'
  print pout[0].read
end


def test_prungrp
  cmds = [ 'echo blop ; exit 1', 'echo blop ; exit 2', 'echo blop ; exit 1', 'echo blop2 ; exit 1' ]
  rgs = CmdCtrl::PRunner::prun_groupresult(cmds)
  rgs.each do |rg|
    puts "###############################################"
    puts rg
  end
end

def test_prungrp2
  cmds = [ 'for i in $(seq 1 1000); do echo blop$i; done', 'for i in $(seq 1 1000); do echo blop$i; done', 'for i in $(seq 1 1000); do echo blop$i; done']
  rgs = CmdCtrl::PRunner::prun_groupresult(cmds)
  rgs.each do |rg|
    puts "###############################################"
    puts rg
  end
end

def test_prungrp3
  cmds = []
  (1..200).each do |i|
    cmds << "echo $((#{i} % 10))"
  end
  rgs = CmdCtrl::PRunner::prun_groupresult(cmds)
  rgs.each do |rg|
    puts "###############################################"
    puts rg
  end
end

