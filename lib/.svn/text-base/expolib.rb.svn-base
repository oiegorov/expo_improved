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


  tree = YAML::load(result['stdout'])

#p tree

#p tree["connectors"]

#	p tree

  res = ExpoResult::new
  tree['hosts'].each_value { |h|
    h['commands'].each_value { |x|
      r = TaskResult::new
      r.merge!( {'host_name' => h['host_name'], 'rank' => h['rank'], 'command_line' => x['command_line'], 'stdout' => x['output'], 'stderr' => x['error'], 'status' => x['status'], 'start_time' => x['start_date'], 'end_time' => x['stop_date'] } )
      res.push(r)
    }
  }
  return [id, res]
end

end
