require 'expo_g5k'

#Reservation
oargridsub :res => "capricorne:rdef=\"/nodes=1\":type=deploy, edel:rdef=\"/nodes=1\":type=deploy" #, queue => "deploy"

check $all

#----ids will contain the id numbers of commands - one for each gateway
ids = akadeploy $all, :env => "lenny-x64-base"

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

