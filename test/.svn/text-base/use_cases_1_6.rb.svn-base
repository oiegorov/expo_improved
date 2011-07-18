require 'expo_g5k'

#Reservation
oargridsub :res => "paravent:rdef=\"/nodes=4\",gdx:rdef=\"/nodes=5\""

#Check all nodes (which is default test ?)
check $all

#execute tasks in parallel
parallel_section do

  sequential_section do
    ptask $all.gw, $all, "date"
  end

  sequential_section do
    task $all.first, "ls -al"
  end

end


