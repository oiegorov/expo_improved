require 'expo_g5k'

#Reservation
oargridsub :res => "capricorne:rdef=\"/nodes=2\":type=deploy" #, queue => "deploy"
puts $all.inspect
puts
check $all
results = kadeploy $all.flatten(:node), :env => "sid-x64-base-1.0"
results.each { |id,res|
#puts res.inspect
  puts "Deployed nodes"
  p res.first["deployed_nodes"]
  puts "Failed nodes"
  p res.first["failed_nodes"]
}

