require 'expo_g5k'
require 'pp'

oargridsub :res => "rennes:rdef=\"/nodes=1\":type=deploy"
#oargridsub :res => "lille:rdef=\"/nodes=2\",grenoble:rdef=\"/nodes=2\""
#oargridsub :res => "lille:rdef=\"/nodes=2\""

check $all

#node_set hash will contain "node_address => frontend_address" pairs
node_set = Hash.new
$all.flatten(:node).resources.each { |resource|
  node_set[resource.properties[:name]] = resource.properties[:gateway]
}
pp node_set

#----deploy an environment on all the reserved nodes
kadeploy $all.flatten(:node), :env => "lenny-x64-base"


#----ssh to each reserved node as a root and do smth
#for each node
#   ssh to it using corresponding gateway

#try with atask + barrier!!
#modify to pass a program name as a parameter!

#install the software on each node
node_set.each { |node, gw| 
  result = task $all.gw, "./install_toexec.sh #{node} gnuplot"
  pp result
}

