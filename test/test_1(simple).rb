require 'g5k_api'

# reserve 2 nodes from Lille and 3 nodes from Grenoble
g5k_init( 
  :site => ["lille", "grenoble"], 
  :resources => ["nodes=2", "nodes=3"] 
)
g5k_run

check $all

# copy a tarball from the frontend to the nodes and output the text
# file from the tarball
$all.uniq.each { |node| 
  copy "~/tars/simple.tar", node, :location => $all.gw, :path => "/home/oiegorov/hello/"
  task node, "tar xvf /home/oiegorov/hello/simple.tar -C /home/oiegorov/hello"
  task node, "cat /home/oiegorov/hello/readmeplz"
  task node, "rm /home/oiegorov/hello/*"
}
