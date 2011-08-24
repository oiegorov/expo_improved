require 'g5k_api'

g5k_init( 
  :site => ["grenoble", "lyon"], 
  :resources => ["nodes=1", "nodes=1"], 
  :environment => {"lenny-x64-base" => 1, "squeeze-x64-base" => 1},
  :walltime => 1800
  #:types => ["deploy"]
)
g5k_run

$all.each { |node|
  dest = "root@#{node.properties[:name]}"
  if node.properties[:environment] == "lenny-x64-base"
    copy "~/install_tocopy.sh", dest 
    atask dest, "sh install_tocopy.sh gnuplot"
  else
    atask dest, "date"
  end
}

barrier
