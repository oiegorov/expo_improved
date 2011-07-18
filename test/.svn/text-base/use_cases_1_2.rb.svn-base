#########################################################
# Example 2: as example 1 but with iteration on nodes set
#

require 'expo_g5k'

#Reservation
oargridsub :res => "paravent:rdef=\"/nodes=4\",gdx:rdef=\"/nodes=5\""

#Check all nodes (which is default test ?)
check $all

#Copy data from home directory to tmp on $all gateway (here gdx gw)
#task $all.gw, "scp ~/data  #{$all.first}:/tmp/"
copy "~/data", $all.first, :location => $all.gw, :path => "/tmp/"

#
# Launch successive tests, the size of nset evolve by power of 2
# n0
# n0,n1
# n0,n1,n2,n3
# ...
#
$all.each_slice_power2 do |nset|
	copy nset.nodefile, $all.first
	result = task $all.first, "cat #{nset.nodefile}"
	puts result.inspect
end
