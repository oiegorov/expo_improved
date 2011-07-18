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
[ 'demo/data/', 'data/'].each { |d| DATADIR=d if File::directory?(d) }

require 'cmdctrl/commands'

include CmdCtrl::Commands

# Tests CmdCtrl::Commands::*
def demo_command_bufferer
  # works only because sh doesn't buffer separate commands
  cmd = 'echo blop1; sleep 2; echo blop2; echo blop3 > /dev/stderr'
  puts "Execute : #{cmd}\n and prints output"
  c = CommandBufferer::new(Command::new(cmd))
  c.run
  sleep 1;
  puts c.read_stdout
  c.wait
  puts c.read_stdout
  puts c.read_stderr
end

def demo_command_bufferer_large_output
  number = 5000
  cmd = "for i in $(seq 1 #{number}); do echo \"ABCDEFGHIJKLMNOPQRSTUVWXYZ\"; done"
  puts "Execute : #{cmd}\n and prints output"
  c = CommandBufferer::new(Command::new(cmd))
  c.run
  puts "Command exited?"
  puts c.exited?
  sleep 2
  puts "Command exited?"
  puts c.exited?
  c.wait
  sleep 1
  print c.read_stdout
end

def demo_command_interactivecommand
  puts "External program ask questions and we send answers"
  c = CommandBufferer::new(InteractiveCommand::new(DATADIR + 'dialog.rb'))
  c.run
  (1..5).each do |i|
    sleep 0.1
    puts c.gets_stdout
    c.puts("Answer #{i * 2}")
    sleep 0.1
    puts c.gets
  end
  c.wait
  p c.status
end

def demo_command_interactivecommand_stderr
  puts "External program ask questions on stderr and we send answers"
  c = CommandBufferer::new(InteractiveCommand::new(DATADIR + 'dialog_err.rb'))
  c.run
  (1..5).each do |i|
    sleep 0.1
    puts c.read_stderr
    c.puts("Answer #{i * 2}")
    sleep 0.1
    puts c.gets_stderr
  end
  c.wait
  p c.status
end


def demo_finished
  puts "Executes : sleep 0.5\nand check if program exited"
  c = Command::new("sleep 0.5")
  c.run
  puts "Command exited?"
  puts c.exited?
  sleep 0.6
  puts "Command exited?"
  puts c.exited?
  c.closefds
end

def demo_command_bufferer_user
  puts "Executes an external program to dialog with the user\nexit to quit"
  c = CommandBufferer::new(InteractiveCommand::new(DATADIR + 'dialog_interactive.rb'))
  c.run
  sleep 0.1
  while string = c.gets
    puts string
    c.puts(gets)
    sleep 0.1
    puts c.gets
    sleep 0.1
  end
end

puts "Demo 1"
demo_command_bufferer
sleep 3
puts "\nDemo2"
demo_command_bufferer_large_output
sleep 3
puts "\nDemo3"
demo_command_interactivecommand
sleep 3
puts "\nDemo4"
demo_command_interactivecommand_stderr
sleep 3
puts "\nDemo5"
demo_finished
sleep 3
puts "\nDemo6"
demo_command_bufferer_user

