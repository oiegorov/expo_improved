#########################################################
# Example 2: as example 1 but with iteration on nodes set
#
require 'expo_g5k'

#Check all nodes (which is default test ?)
check $all

#launch parallel tasks
id, res = ptask $all.gw, $all.uniq, "date"
id, res = ptask $all.gw, $all, "sleep 1"

res.each { |r| puts r.duration }

puts "moyenne : " + res.duration.to_s
