######################################################################################
# Example 1: reserve some nodes, check them, copy file in tmp, launch command to test 
#

require 'expo_g5k'

#Reservation
oargridsub :res => "edel:rdef=\"/nodes=2\",chicon:rdef=\"/nodes=1\""

#Check all nodes
#----$all is a hash that contains all information about the reserved
#----nodes and their characteristics(gateway, etc.). We initialize it in
#----extract_resources() which is called from oargridsub()
check $all

#Copy data from home directory to tmp on $all gateway (here gdx gw)
#task $all.gw, "scp ~/data_oleg  #{$all.first}:/home/oiegorov/hello/"
#task $all.gw, "scp ~/data_oleg  #{$all.first}:/home/oiegorov/hello/"

#----gw method is defined in ../lib/resourceset.rb:89
#----file=="~/data" $all.first==chicon-1.lille.grid5000.fr it's a destination
#----the last 2 are params. Here location=""
copy "~/data", $all.first, :location => $all.gw, :path => "/tmp/"

#Copy nodes file on first node
copy $all.nodefile, $all.first

#Launch test (kastafior here) on first compute mode
#
#task $all.first, "~/expo/bin/kastafior -f #{$all.nodefile} -- -i /tmp/data -d /tmp/"
task $all.first, "~/expo/bin/kastafior -f #{$all.nodefile} -- -i /tmp/data -d ~/hello/"
#task $all.first, "~/custom_scr.sh"


