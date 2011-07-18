#########################################################
# Example 2: as example 1 but with iteration on nodes set
#
require 'expo_g5k'

#Reservation
oargridsub :res => "paravent:rdef=\"/nodes=4\",gdx:rdef=\"/nodes=5\""

#Check all nodes (which is default test ?)
check $all

#launch asynchrounous task
task1 = Task::new("uname -a", $all.uniq)

id,res =  task1.execute

print_taktuk_result(res)

#barrier
#barrier
