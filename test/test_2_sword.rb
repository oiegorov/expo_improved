require 'g5k_api'

# reserve 2 nodes from sagittaire cluster (Lyon) with 8192KB cpu cache and
# one node from Grenoble
g5k_init( 
  :site => ["lille", "grenoble"], 
  :resources => ["{cluster='sagittaire' and memcpu=8192}/nodes=2", "nodes=1"] 
)
g5k_run

# copy a tarball from the frontend to the nodes and output the text
# file from the tarball
$all.uniq.each { |node| 
  copy "~/tars/simple.tar", node, :path => "/home/oiegorov/hello/"
  task node, "tar xvf /home/oiegorov/hello/simple.tar -C /home/oiegorov/hello"
  task node, "cat /home/oiegorov/hello/readmeplz"
  task node, "rm /home/oiegorov/hello/*"
}
