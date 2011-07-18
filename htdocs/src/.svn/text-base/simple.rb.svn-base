require 'expo_g5k'
oargridsub :res => "gdx:nodes=10,helios:nodes=10"
check $all
ptask $all.gateway, $all, "date"
id, res = ptask $all["gdx"].gateway, $all["gdx"], "sleep 1"
res.each { |r| puts r.duration }
puts "mean : " + res.mean_duration
