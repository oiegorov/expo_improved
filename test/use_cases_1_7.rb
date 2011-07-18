require 'expo_g5k'

#Reservation
#---- --type=deploy will note that program is run on DEPLOY_HOSTNAME 
#----and not on the first reserved node
oargridsub :res => "edel:rdef=\"/nodes=2\":type=deploy" #, queue => "deploy"
puts $all.inspect
puts
check $all
results = kadeploy $all.flatten(:node), :env => "lenny-x64-base"
results.each { |id,res|
#puts res.inspect
  puts "Deployed nodes"
  p res.first["deployed_nodes"]
  puts "Failed nodes"
  p res.first["failed_nodes"]
}

