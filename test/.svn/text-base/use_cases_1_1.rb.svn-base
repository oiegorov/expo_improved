######################################################################################
# Example 1: reserve some nodes, check them, copy file in tmp, launch command to test 
#

require 'expo_g5k'

#Reservation
oargridsub :res => "paravent:rdef=\"/nodes=4\""

#Check all nodes
check $all

#Copy data from home directory to tmp on $all gateway (here gdx gw)
#task $all.gw, "scp ~/data  #{$all.first}:/tmp/"
copy "~/data", $all.first, :location => $all.gw, :path => "/tmp/"

#Copy nodes file on first node
copy $all.nodefile, $all.first

#Launch test (kastafior here) on first compute mode
#
#task $all.first, "kastafior -f #{$all.nodefile} -- -i /tmp/data -d /tmp/"


