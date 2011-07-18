require 'expo_g5k'

#Reservation
oargridsub :res => "capricorne:rdef=\"/nodes=2\":type=deploy, gdx:rdef=\"/nodes=2\":type=deploy" #, queue => "deploy"

check $all

ids = akadeploy $all, :env => "sid-x64-base-1.0"

while true do
  done = 0
  res = kadeploy_advancement
  ids.each{ |id|
    puts res.inspect
    res.each { |ident, data|
      done += 1 if id == ident and ( data.last and data.last.first == "<Completed>" )
    }
  }
  sleep 10
  break if done == ids.size
end


ids.each { |id|
  puts $akadeploys[id]['stderr']
}

