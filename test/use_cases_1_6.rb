require 'g5k_api'
require 'pp'

g5k_init (
  :site => ["lyon", "lille"],
  :resources => ["nodes=4", "nodes=5"],
  :walltime => 200)
g5k_run

#Check all nodes (which is default test ?)
check $all

#execute tasks in parallel
parallel_section do

  #each sequential sections creates a new thread
  sequential_section do
    #ptask $all.gw, $all, "date"
    ptask $all.gw, $all, "sleep $[ ( $RANDOM % 5 )  + 1 ]s"
    res = ptask $all.gw, $all, "date"
    res.each do |t|
      pp t
    end 
  end

  sequential_section do
    #task $all.first, "ls -al"
    ptask $all.gw, $all, "sleep $[ ( $RANDOM % 5 )  + 1 ]s"
    res2 = ptask $all.gw, $all, "uname -a"
    res2.each do |t|
      pp t
    end 
  end

end


