##############################################
# Example 0: reserve some nodes and check them 
#
require 'expo_g5k'

#Reservation
oargridsub :res => "idpot:rdef=\"/nodes=6\",chti:rdef=\"/nodes=5\""

#Check all nodes (which is default test ?)
check $all

id, res = ptask $all.gw, $all.uniq, "uname -a"
res.each { |r| puts r['stdout'] }
