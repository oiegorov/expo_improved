require 'expo_g5k'
require 'pp'

oargridsub :res => "lille:rdef=\"/nodes=1\":type=deploy"
#oargridsub :res => "lille:rdef=\"/nodes=3\""
check $all

node_set = Hash.new                                                                                                                         
$all.flatten(:node).resources.each { |resource|
    node_set[resource.properties[:name]] = resource.properties[:gateway]
}
pp node_set

node_set.each { |node, gw| 
    task $all.gw, "./install_toexec.sh #{node} emacs"
}
