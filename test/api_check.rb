require 'g5k_api'
require 'pp'

g5k_init :site => ["lille", "bordeaux"]
nodes = g5k_run

puts "\n\n"
puts "reserved nodes: "
pp nodes
