require 'expo_g5k'

oargridsub :res => "lille:rdef=\"/nodes=2\":prop=\"memnode=8192 and myri10g='YES'\",grenoble:rdef=\"/nodes=1\""

check $all

$all.uniq.each { |node| 
  copy "~/tars/simple.tar", node, :location => $all.gw, :path => "/home/oiegorov/hello/"
  task node, "tar xvf /home/oiegorov/hello/simple.tar -C /home/oiegorov/hello"
  task node, "cat /home/oiegorov/hello/readmeplz"
  task node, "rm /home/oiegorov/hello/*"
}
