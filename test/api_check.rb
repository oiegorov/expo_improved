require 'g5k_api'
require 'expo_g5k'
require 'pp'

g5k_init :site => ["rennes"], :resources => "nodes=1", :walltime => 3600
g5k_run

check $all

$all.uniq.each { |node| 
  copy "~/tars/simple.tar", node, :location => $all.gw, :path => "/home/oiegorov/hello/"
  task node, "tar xvf /home/oiegorov/hello/simple.tar -C /home/oiegorov/hello"
  task node, "cat /home/oiegorov/hello/readmeplz"
  task node, "rm /home/oiegorov/hello/*"
}

=begin
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
=end
