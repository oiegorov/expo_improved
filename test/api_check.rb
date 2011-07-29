require 'g5k_api'
#require 'expo_g5k'
require 'pp'

g5k_init( :site => ["lille", "rennes"], 
  :resources => ["nodes=3", "nodes=4"], 
  :environment => {"lenny-x64-base" => 1, "squeeze-x64-base" => 6},
  :walltime => 60,
  :deploy => true 
        )
=begin
g5k_init( :site => ["lille"], 
  :resources => ["nodes=3"], 
  :environment => {"lenny-x64-base" => 3},
  :walltime => 3600,
  :deploy => true 
        )
=end

g5k_run

=begin
$all.each { |node|
  pp node.properties[:name]
}
=end



=begin
check $all

$all.uniq.each { |node| 
  copy "~/tars/simple.tar", node, :location => $all.gw, :path => "/home/oiegorov/hello/"
  task node, "tar xvf /home/oiegorov/hello/simple.tar -C /home/oiegorov/hello"
  task node, "cat /home/oiegorov/hello/readmeplz"
  task node, "rm /home/oiegorov/hello/*"
}
=end

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
