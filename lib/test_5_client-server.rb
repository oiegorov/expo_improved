require 'g5k_api'
require 'pp'

g5k_init( 
#  :site => ["lille", "lyon"], 
  :site => ["lille"], 
  :resources => ["cluster=1/nodes=4"], 
  :environment => {"lenny-x64-base" => 1, "squeeze-x64-base" => 3},
#  :resources => ["nodes=1", "nodes=5"], 
#  :environment => {"lenny-x64-base" => 1, "squeeze-x64-base" => 15},
  :walltime => 1800,
  :types => ["deploy"]
        )
g5k_run

server = $all.select_resource(:environment => "lenny-x64-base") 
task "root@#{server.name}", "date"  

clients = $all.select(:node, :environment => "squeeze-x64-base")
clients.each { |client|
  atask "root@#{client.name}", "uname -a"
}

barrier




=begin

$all.each { |node|
  location = "root@#{node.properties[:name]}"
  if node.properties[:environment] == "lenny-x64-base"
    task location, "date"
  end
}

$all.each { |node|
  location = "root@#{node.properties[:name]}"
  if node.properties[:environment] == "squeeze-x64-base"
    atask location, "uname"
  end
}
barrier

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
$all.each { |node|
  node_name = node.properties[:name]
  gw_name = node.properties[:gateway]
  result = atask gw_name, "sh ~/install_toexec.sh #{node_name} gnuplot"
}

barrier
=end
