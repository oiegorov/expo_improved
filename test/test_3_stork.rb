require 'g5k_api'
require 'expo_g5k'
require 'pp'

g5k_init( 
  :site => ["lille", "rennes"], 
  :resources => ["nodes=1", "nodes=1"], 
#  :environment => {"lenny-x64-base" => 1, "squeeze-x64-base" => 1},
  :environment => {"lenny-x64-base" => 2},
  :walltime => 690,
  :deploy => true,
  :types => ["deploy"]
)
g5k_run

$all.each { |node|
  node_name = node.properties[:name]
  gw_name = node.properties[:gateway]
  result = atask gw_name, "sh ~/install_toexec.sh #{node_name} gnuplot"
}

barrier



=begin
# ----------- old version -------------------------
oargridsub :res => "rennes:rdef=\"/nodes=1\":type=deploy"
#oargridsub :res => "lille:rdef=\"/nodes=2\",grenoble:rdef=\"/nodes=2\""
#oargridsub :res => "lille:rdef=\"/nodes=2\""


#node_set hash will contain "node_address => frontend_address" pairs
node_set = Hash.new
$all.flatten(:node).resources.each { |resource|
  node_set[resource.properties[:name]] = resource.properties[:gateway]
}

#----deploy an environment on all the reserved nodes
kadeploy $all.flatten(:node), :env => "lenny-x64-base"

check $all


#----ssh to each reserved node as a root and do smth
#for each node
#   ssh to it using corresponding gateway

#try with atask + barrier!!
#modify to pass a program name as a parameter!

#install the software on each node
node_set.each { |node, gw| 
  #result = task $all.gw, "./install_toexec.sh #{node} gnuplot"
  result = atask $all.gw, "sh ~/simple_script.sh #{node}"
}
=end
