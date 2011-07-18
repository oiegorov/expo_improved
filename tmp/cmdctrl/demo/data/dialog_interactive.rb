#!/usr/bin/ruby

puts "Hello, who are you?"
line = gets
puts "Hello #{line}"
finished = false
while not finished do
  puts "What do you want?"
  line = gets
  puts "OK for #{line}"
  finished =true if line == "exit\n"
end
