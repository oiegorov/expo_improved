##############################################
# Example 0: reserve some nodes and check them 
#

=begin
require 'expo_g5k'
$reservation_type = "oargrid2"

#Reservation
oargridsub :res => "chicon:rdef=\"/nodes=1\",capricorne:rdef=\"/nodes=1\""

#Check all nodes (which is default test ?)
check $all
=end

require 'g5k_api'

g5k_init(
  :site => ["lille", "grenoble", "bordeaux"],
  :resources => "nodes=1"
)
g5k_run

check $all

puts "all.flatten:"
puts $all.flatten(:gateway).uniq.inspect

puts "Gateways :"
$all.each( :resource_set ) { |s|
	puts s.gw
}

