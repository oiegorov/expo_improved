require 'expo_g5k'
require 'pp'

#Reservation
oargridsub :res => "capricorne:rdef=\"/nodes=4\",edel:rdef=\"/nodes=5\""

#Check all nodes (which is default test ?)
check $all

#execute tasks in parallel
parallel_section do

  #each sequential sections creates a new thread
  sequential_section do
    #ptask $all.gw, $all, "date"
    res = ptask $all.gw, $all, "date"
    res.each do |t|
      pp t
    end 
  end

  sequential_section do
    #task $all.first, "ls -al"
    pp task $all.first, "ls -al"
  end

end


