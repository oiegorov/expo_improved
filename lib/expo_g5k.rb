require 'thread'

module Expo

$reservation_type = "oargrid2"

def determine_oargridsub_version
   command_result = $client.asynchronous_command("oargridsub -V")
   $client.command_wait(command_result["command_number"],1)
   result = $client.command_result(command_result["command_number"])
   stdout = result["stdout"]
   version_number = stdout.scan(/OARGRID version : (\d)./).first.first
   puts "OARGRID version : #{version_number}"
   if version_number == "1" then
     $reservation_type = "oargrid"
   elsif version_number == "2" then
     $reservation_type = "oargrid2"
   else
     $reservation_type = "oargrid"
   end
end


determine_oargridsub_version

$akadeploys_mutex = Mutex::new
$akadeploys = Hash::new

$reservation_ids = Array::new

opts = OptionParser::new
opts.on("-t","--reservation_type VAL", String) { |val| $reservation_type = val }
opts.on("-i","--id VAL",Integer) { |val| $reservation_ids.push(val) }
$rest = opts.parse(*$rest)

def oargrid_gw
  command_result = $client.asynchronous_command("oargridstat -Y --list_aliases")
  $client.command_wait(command_result["command_number"],1)
  result = $client.command_result(command_result["command_number"])
  tree = YAML::load( result["stdout"] )
  $oargrid_gw = Hash::new
  tree.each { |key,value|
    $oargrid_gw[key] = value["gateway"]
  }
end

if $reservation_type == "oargrid2" || $reservation_type == "oargrid" then
  oargrid_gw
end

require "#{$reservation_type}_structures"

def extract_resources(result)
  if($reservation_type == "oargrid2") then

    result["resources"].each { |key,value|
      #----key - it's the name of cluster, value - all the nodes
      #----reserved on this cluster
      cluster = key
      value.each { |key,value|
        #----key - the job number, value - hash of 'name'=>"" and all
        #----the names of reserved nodes
        jobname = key
        resource_set = ResourceSet::new
        resource_set.name = jobname #$namer.get_name(cluster)
        #----$oargrid_gw is a hash of 'cluster name'=>'frontend name'
        resource_set.properties[:gateway] = $oargrid_gw[cluster]
        resource_set.properties[:alias] = cluster
        value.each { |key,value|
          jobid = key
          resource_set.properties[:id] = jobid
          value.each { |node|
            resource = Resource::new(:node, nil, node)
            resource.properties[:gateway] = $oargrid_gw[cluster]
            resource_set.push(resource)
          }
        }
        #----so we put in $all a hash of all reserved nodes (in all
        #----clusters)
        $all.push(resource_set)
      }
    }
  elsif ($reservation_type == "oargrid") then
    result["resources"].each { |key,value|
      cluster = key
      value.each { |key,value|
        resource_set = ResourceSet::new
	resource_set.name = $namer.get_name(cluster)
	resource_set.gateway = $oargrid_gw[cluster]
        resource_set.properties[:id] = key
        value.each { |node|
          resource = Resource::new(:node, nil, node)
	  resource_set.push(resource)
        }
	$all.push(resource_set)
      }
    }
  end
  return nil
end

def oargridconnect(id)
  puts "connecting to : #{id}"
  reservation = $client.open_reservation($reservation_type,id)
  info = $client.reservation_info(reservation["reservation_number"])
#  ssh_key = info["misc_data"]["SSH KEY"]

#  if ssh_key then
#    result = $client.command("ssh-add #{ssh_key}")
#    puts result["stdout"]
#    puts result["stderr"]
#    puts
#  end

  $client.reservation_wait(reservation["reservation_number"])
  result = $client.reservation_resources(reservation["reservation_number"])
  puts "connection success"
  extract_resources(result)
  return nil

end

def oargridsub(params)
  if $reservation_type == "oargrid" then
    parameters = OargridsubParameters::new(nil,params[:queue],nil,params[:walltime],nil,nil,nil,nil,params[:res])
  elsif $reservation_type == "oargrid2" then
    params[:type] = "allow_classic_ssh"
    #----create new hash and put known values of :type and :res there
    parameters = OargridsubParameters::new(params[:start_date],params[:queue],params[:type],params[:program],params[:directory],params[:walltime],params[:force],params[:verbose],params[:file],params[:res])
  end
  #----$client was created in expo.rb
  #----next command actually does the reservation
  reservation = $client.new_reservation($reservation_type,parameters)
  info = $client.reservation_info(reservation["reservation_number"])
  id = info["id"]

  trap(:INT) {
    r = $client.delete_reservation(reservation["reservation_number"])
    r = $client.command_result(r["delete_command_number"])
    puts r["stdout"]
    exit
  }

  at_exit {
    r = $client.delete_reservation(reservation["reservation_number"])
    r = $client.command_result(r["delete_command_number"])
    puts r["stdout"]
  }

  puts "Oargrid id : "+id
#  ssh_key = info["misc_data"]["SSH KEY"]

#  if $reservation_type == "oargrid2" then
#    $ssh_connector = " -c \"ssh -l oar -o StrictHostKeyChecking=no -o BatchMode=yes\""
#    $scp_connector = " -S \"ssh -l oar -o StrictHostKeyChecking=no -o BatchMode=yes\""
#  end
#  if ssh_key then
#    result = $client.command("ssh-add #{ssh_key}")
#    puts result["stdout"]
#    puts result["stderr"]
#    puts
#  end

  $client.reservation_wait(reservation["reservation_number"])

  result = $client.reservation_resources(reservation["reservation_number"])
#  puts result["resources"].inspect
  extract_resources(result)

  return nil

end
=begin
def kadeploy( nodes, params )
  n = ResourceSet::new(nodes.all.resources.uniq)
  copy( n.nodefile, nodes.gw )
  cmd = "taktuk2yaml -s"
  cmd += $ssh_connector
  cmd += " -m #{nodes.gw}"
  cmd += " b e [ cat #{n.nodefile} ], b e [ terminal_emulator kadeploy  -e #{params[:env]} -f #{n.nodefile} ]"
  puts "deploying : " + n.resources.inspect
  command_result = $client.interactive_command(cmd)
  $client.command_wait(command_result["command_number"],1)
  result = $client.command_result(command_result["command_number"])
  tree = YAML::load( result["stdout"] )
  tree['hosts'].each_value { |h|
    puts h['host_name'] + " :"
    h['commands'].each_value { |x| puts x['command_line']; puts x['output']; puts x['error']; puts }
  }
  return tree['hosts']
end
=end

#----old tw from line 200  
#tw = TaktukWrapper::new(\"-s #{$ssh_connector} -m #{nodes.gw} b e [ terminal_emulator kadeploy -e #{params[:env]} -f #{n.nodefile} ]\".split)
def _kadeploy( nodes, params )
  n = nodes.uniq
  copy( n.nodefile, nodes.gw )
  cmd = "require 'taktuk_wrapper'
  require 'yaml'
  tw = TaktukWrapper::new(\"-s #{$ssh_connector} -m #{nodes.gw} b e [ kadeploy3 -e #{params[:env]} -f #{n.nodefile} -k ]\".split)
  tw.at_output { |r,p,l,c,h,e,t|
    rank = r
    pid = p
    line = l
    command = c
    host = h
    eol = e
    type = t
    STDERR.print line+eol
  }
  tw.at_error { |r,p,l,c,h,e,t|
    rank = r
    pid = p
    line = l
    command = c
    host = h
    eol = e
    type = t
    STDERR.print line+eol
  }
  tw.run
  puts YAML.dump({'hosts'=>tw.hosts,'connectors'=>tw.connectors,'errors'=>tw.errors,'infos'=>tw.infos})
  "
  
  puts "deploying : " + n.inspect
  command_result = $client.ruby_asynchronous_command(cmd)
  $client.command_wait(command_result["command_number"],1)

	id, res = make_taktuk_result(command_result["command_number"])

	flag = false
	failed_nodes = []
	deployed_nodes = []

	res.first["stdout"].each do |line|
		if line =~ /--------------------------/
			flag = true
		end
		if flag
			words = line.split
			deployed_nodes << words.first if words[1] == 'deployed'
			failed_nodes << words.first if words[1] == 'error'
		end
	end

	res.first["failed_nodes"] = failed_nodes 
	res.first["deployed_nodes"] = deployed_nodes

  return id, res

end

def kadeploy( nodes, params )
  #----only unique nodes (we have same nodes for diff. cores)
  n = nodes.uniq

  #----read comment in the notebook. Specifies what we do when trying to
  #    access hash value with non-existent key
  gateways = Hash::new { |hash,key|
  	hash[key] = ResourceSet::new
    hash[key].properties[:gateway] = key
    hash[key]
  }

  #----for each gateway - its own set of resources
  n.each(:node) { |resource|
  	gateways[resource.gw].push( resource )
  }
  results = Array::new
  gateways.each_value { |resource_set|
    results.push( _kadeploy( resource_set, params ) )
  }

  return results
end


def _akadeploy( nodes, params )
  n = nodes.uniq
  copy( n.nodefile, nodes.gw )
  cmd = "require 'taktuk_wrapper'
  tw = TaktukWrapper::new(\"-s #{$ssh_connector} -m #{nodes.gw} b e [ kadeploy3 -e #{params[:env]} -f #{n.nodefile} ]\".split)
  tw.at_output { |r,p,l,c,h,e,t|
    rank = r
    pid = p
    line = l
    command = c
    host = h
    eol = e
    type = t
    STDERR.print line+eol
    STDERR.flush
  }
  tw.at_error { |r,p,l,c,h,e,t|
    rank = r
    pid = p
    line = l
    command = c
    host = h
    eol = e
    type = t
    STDERR.print line+eol
    STDERR.flush
  }
  tw.run
  puts YAML.dump({'hosts'=>tw.hosts,'connectors'=>tw.connectors,'errors'=>tw.errors,'infos'=>tw.infos})
  "
#  puts cmd
#  while true do
#    nil
#  end
  puts "deploying : " + n.resources.inspect
  command_result = $client.ruby_asynchronous_command(cmd)
  $akadeploys_mutex.synchronize {
    $akadeploys[command_result["command_number"]] = { 'number' => n.resources.size, 'stderr' => "" }
  }

  #----for use_case_1_8 command_result hash contains only one pair
  #    "command_number"=>some number
  return command_result["command_number"]
end

#----asynchronous deployment
#    the same as kadeploy() but calls _akadeploy instead of _kadeploy
def akadeploy( nodes, params )
  n = nodes.uniq

  gateways = Hash::new { |hash,key|
  	hash[key] = ResourceSet::new
    hash[key].properties[:gateway] = key
    hash[key]
  }

  n.each(:node) { |resource|
  	gateways[resource.gw].push( resource )
  }
  ids = Array::new
  gateways.each_value { |resource_set|
    ids.push( _akadeploy( resource_set, params ) )
  }
  return ids
end


def kadeploy_advancement
  res = Array::new
  $akadeploys_mutex.synchronize {
    #----$akadeploys hash contains pairs of command_number=>( number of
    #    the nodes, stderr)
    $akadeploys.each { |id, h|
      result = $client.command_result( id )
      h['stderr'] += result['stderr']
      tokens = h['stderr'].scan(/(<.*?>)/)
      res.push([id,tokens])
    }
  }
  return res
end

$reservation_ids.each { |id| oargridconnect(id) }

end
