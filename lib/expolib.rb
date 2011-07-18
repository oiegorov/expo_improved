module Expo


def print_taktuk_result( res )
  res.each { |r|
    puts r['host_name'] + " :"
    puts r['start_time'].to_s + " - " + r['end_time'].to_s 
    puts r['command_line'];
    puts r['stdout'];
    puts r['stderr'];
    puts
  }
end

def make_taktuk_result( id )
  result = $client.command_result( id )


  #----the following cut the message about job deletion
  #    so we won't have an error about unrecognized colomn in YAML::load
  #    while deploying
  ind = result['stdout'].index('[OAR_GRIDDEL]')
  if ind
    result['stdout'] = result['stdout'][0..ind-1]
  end

  tree = YAML::load(result['stdout'])

#p result.inspect
#p tree["connectors"]
#p tree

  res = ExpoResult::new
  tree['hosts'].each_value { |h|
    h['commands'].each_value { |x|
      r = TaskResult::new
      r.merge!( {'host_name' => h['host_name'], 'rank' => h['rank'], 'command_line' => x['command_line'], 'stdout' => x['output'], 'stderr' => x['error'], 'status' => x['status'], 'start_time' => x['start_date'], 'end_time' => x['stop_date'] } )
      res.push(r)
    }
  }

  #----display an output of command!!!
  puts "Command: " + res[0]['command_line']
  puts "Output: "
  if res[0]['stdout']
    puts res[0]['stdout']
  end
  return [id, res]
end

end
