#########################################################
# Example 2: as example 1 but with iteration on nodes set
#
require 'expo_g5k'

#Reservation
oargridsub :res => "paravent:rdef=\"/nodes=4\",gdx:rdef=\"/nodes=5\""

#Check all nodes (which is default test ?)
check $all

#launch parallel tasks
id, res = ptask $all.gw, $all.uniq, "date"
id, res = ptask $all.gw, $all, "sleep 1"

res.each { |r| puts r.duration }

puts "moyenne : " + res.duration.to_s
