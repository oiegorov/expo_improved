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
task2 = Task::new("date", $all.uniq)

ts = TaskSet::new
ts.push(task1).push(task2)


id,res =  ts.execute

print_taktuk_result(res)

ts = TaskStream::new
ts.push(task1).push(task2)

r = ts.execute

r.each { |id,res|
  print_taktuk_result(res)
}
