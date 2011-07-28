require 'expo_g5k'
require 'pp'

oargridsub :res => "capricorne:rdef=\"/nodes=1\",paradent:rdef=\"/nodes=1\""

check $all

$all.uniq.each { |node| 
  copy "~/tars/simple.tar", node, :location => $all.gw, :path => "/home/oiegorov/hello/"
  task node, "tar xvf /home/oiegorov/hello/simple.tar -C /home/oiegorov/hello"
  task node, "cat /home/oiegorov/hello/readmeplz"
  task node, "rm /home/oiegorov/hello/*"
}
