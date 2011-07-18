#########################################################
# Example 2: as example 1 but with iteration on nodes set
#
require 'expo_g5k'

#Reservation
oargridsub :res => "paravent:rdef=\"/nodes=4\",gdx:rdef=\"/nodes=5\""

#Check all nodes (which is default test ?)
check $all

#launch asynchrounous task
atask $all.gw, "ls -al"

#launch parallel tasks
ptask $all.gw, $all, "date"

#barrier
barrier
