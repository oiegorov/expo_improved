##############################################
#
require 'expo_g5k'

#Reservation
oargridsub :res => "chicon:rdef=\"/nodes=2\""
#oargridsub :res => "chicon:rdef=\"/nodes=2\""

#Check all nodes (which is default test ?)
check $all

ptask $all.gateway, $all, "date"

#id, res = ptask $all["chicon"].gateway, $all["chicon"], "sleep 1"
id, res = ptask $all.gateway, $all, "sleep 1"

#----duration() is defined in expo.rb when we add this method to class
#----TaskResult
res.each { |r| puts r.duration }
puts "moyenne : " + res.mean_duration.to_s
