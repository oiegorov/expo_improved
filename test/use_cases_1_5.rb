#########################################################
# Example 2: as example 1 but with iteration on nodes set
#
require 'expo_g5k'
require 'pp'

#Reservation
oargridsub :res => "chicon:rdef=\"/nodes=2\",edel:rdef=\"/nodes=2\""

#Check all nodes (which is default test ?)
check $all

#launch asynchrounous task
patask $all.gw, $all, "uname -a"

#launch parallel tasks
#ptask $all.gw, $all, "date"
#=begin
res = ptask $all.gw, $all, "date"
res.each do |t|
pp t
end 
#=end

#barrier
#=begin
res_bar = barrier
res_bar.each do |t|
pp t
end
#=end
