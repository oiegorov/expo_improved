require 'g5k_api'
require 'pp'

g5k_init( 
#  :site => ["lille", "lyon"], 
#  :resources => ["nodes=1", "nodes=1"], 
#  :environment => {"lenny-x64-base" => 1, "squeeze-x64-base" => 1},
  :site => ["lyon", "rennes"], 
#  :resources => ["cluster=\"capricorne\",nodes=1", "nodes=2"], 
  :resources => ["{cluster='sagittaire' and memcpu=8192}/nodes=2", "nodes=1"], 
#  :environment => {"lenny-x64-base" => 1},
  :walltime => 1000
#  :deploy => true
#  :types => ["deploy"]
#  :no_cleanup => true
        )
g5k_run

check $all

$all.uniq.each { |node| 
  copy "~/tars/simple.tar", node, :location => $all.gw, :path => "/home/oiegorov/hello/"
  task node, "tar xvf /home/oiegorov/hello/simple.tar -C /home/oiegorov/hello"
  task node, "cat /home/oiegorov/hello/readmeplz"
  task node, "rm /home/oiegorov/hello/*"
}


=begin
$all.each { |node|
  node_name = node.properties[:name]
  gw_name = node.properties[:gateway]
  result = atask gw_name, "sh ~/install_toexec.sh #{node_name} gnuplot"
}

barrier
=end
