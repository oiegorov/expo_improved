##############################################
# Example 0: reserve some nodes and check them 
#
require 'expo_g5k'
$reservation_type = "oargrid2"

#Reservation
oargridsub :res => "chicon:rdef=\"/nodes=1\",capricorne:rdef=\"/nodes=1\""

#Check all nodes (which is default test ?)
check $all

puts "all.flatten:"
puts $all.flatten(:gateway).uniq.inspect

puts "Gateways :"
$all.each( :resource_set ) { |s|
	puts s.gw
}

