##
## It's an expo.rb variant to karo.rb prototype
##

require 'yaml'
require 'resourceset'

$RMI = 'none'
$POLLING = false
$all = nil #default resource set (nil for karo)


require 'expctrl'
require 'taktuk_wrapper'

$client = ExpCtrlClient::new()

$client.open_experiment

$atasks_mutex = Mutex::new
$atasks = Hash::new

$ssh_connector = ""

$scp_connector = "-o StrictHostKeyChecking=no"

class ExpoResult < Array
  def duration
    sum = 0
    time = 0
    self.each { |t| sum += t.duration }
    time = sum / self.length if self.length > 0
    return time
  end
end

class TaskResult < Hash
  def duration
    return self['end_time'] - self['start_time']
  end
end

at_exit {
  barrier
	$client.close_experiment
}

#Check all nodes (what is default test ?)
#check $all

def check( nodes )
  n = nodes.flatten(:node).uniq
  puts "testing : " + n.inspect
  test_nis = "taktuk2yaml -s"
  test_nis += $ssh_connector
  n.each(:node) { |x|
    test_nis += " -m #{x}"
  }
  test_nis += " broadcast exec [ date ]"
  command_result = $client.asynchronous_command(test_nis)
  $client.command_wait(command_result["command_number"],1)
  result = $client.command_result(command_result["command_number"])

  tree = YAML::load( result["stdout"] )
  puts "Failing nodes :"
  tree["connectors"].each_value { |error|

    if error["output"].scan("initialization failed").pop  or error["output"].scan("Name or service not known").pop or error["output"].scan("Permission denied").pop then
      nodes.delete_if {|resource| resource.name == error["peer"] }
      puts error["peer"]+" : "+error["output"]
    end
  }
  puts
  return nil
end

#Copy data from home directory to tmp on $all gateway (here gdx gw)
#task $all.gw, "scp ~/data  #{$all.first}:/tmp/"

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

p tree

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

def task(location, task)
  cmd = "taktuk2yaml -s"
  cmd += $ssh_connector
  cmd += " -m #{location}"
  cmd += " b e [ #{task} ]"
  command_result = $client.asynchronous_command(cmd)
  $client.command_wait(command_result["command_number"],1)
  return make_taktuk_result( command_result["command_number"] )
end

def atask(location, task)
  cmd = "taktuk2yaml -s"
  cmd += $ssh_connector
  cmd += " -m #{location}"
  cmd += " b e [ #{task} ]"
  command_result = $client.asynchronous_command(cmd)
  $atasks_mutex.synchronize {
    $atasks[command_result["command_number"]] = { "location" => location , "task" => task }
  }
end

def barrier
  trees = Array::new
  $atasks_mutex.synchronize {
    $atasks.delete_if { |t, val|
      $client.command_wait(t)
      trees.push( make_taktuk_result(t) )
      true
    }
  }
  return trees
end


def ptaskfoorand(task, rset, *params)
	puts task

	nb_good = rand(rset.resources.length + 1)
	puts "Nb good resources: #{nb_good}"

	#create a resource set
	rset_good = ResourceSet::new()
	rset_good.properties[:history] = 	rset.properties[:history].clone
	
	#create a resource set
	rset_bad = ResourceSet::new()
	rset_bad.properties[:history] = 	rset.properties[:history].clone
	
	rset.resources.each_with_index do |r,i|
		if i < nb_good
			rset_good.push(r)
		else
			rset_bad.push(r)
		end
	end

	r = Result.new(rset)
	r.rset_good = rset_good
	r.rset_bad = rset_bad

	return r
end


def ptask(task,*params) 
	# params order: command, [resource_set] , [gateway], [options]

	targets = $all
	location = 'localhost'

	targets = params.shift if !params.nil? && params.first.class == ResourceSet
	location = params.shift if !params.nil? && params.first.class == String

	ssh_connector = $ssh_connector
	taktuk_options = ""
	if !params.nil? && params.length>0
		if params.first.class == Hash
			ssh_connector =  params.first[:ssh_connector] if !params.first[:ssh_connector].nil?
			taktuk_options =  params.first[:taktuk_options] if !params.first[:taktuk_options].nil?
		else
			puts "Error on remains ptask parameters: #{params}"
		end
	end
	cmd = "taktuk2yaml -s"
  cmd += ssh_connector
	cmd += taktuk_options
  cmd += " -m #{location}"
  cmd += " -["
  targets.flatten(:node).each(:node) { |node|
    cmd += " -m #{node}"
  }
  cmd += " downcast exec [ #{task} ]"
  cmd += " -]"
  command_result = $client.asynchronous_command(cmd)
  $client.command_wait(command_result["command_number"],1)
#  return make_taktuk_result(command_result["command_number"])

	result = Result.new
	result.rset = targets
	result.rset_good = targets
	result.cmd_result =   make_taktuk_result(command_result["command_number"])
	result.rset_good = targets #TO MODIFY !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	#result.rset_bad =   #TO MODIFY !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	return result	
end

def ptask_orig(location, targets, task)
  cmd = "taktuk2yaml -s"
  cmd += $ssh_connector
  cmd += " -m #{location}"
  cmd += " -["
  targets.flatten(:node).each(:node) { |node|
    cmd += " -m #{node}"
  }
  cmd += " downcast exec [ #{task} ]"
  cmd += " -]"
  command_result = $client.asynchronous_command(cmd)
  $client.command_wait(command_result["command_number"],1)
  return make_taktuk_result(command_result["command_number"])
end

def patask(location, targets, task)
  cmd = "taktuk2yaml -s"
  cmd += $ssh_connector
  cmd += " -m #{location}"
  cmd += " -["
  targets.flatten(:node).each(:node) { |node|
    cmd += " -m #{node}"
  }
  cmd += " downcast exec [ #{task} ]"
  cmd += " -]"
  command_result = $client.asynchronous_command(cmd)
  $atasks_mutex.synchronize {
    $atasks[command_result["command_number"]] = { "location" => location , "task" => task }
  }
end

class ParallelSection
  def initialize(&block)
    @thread_array = Array::new
    instance_eval(&block)
    @thread_array.each { |t|
      t.join
    }
  end

  def sequential_section(&block)
    t = Thread::new(&block)
    @thread_array.push(t)
  end
  
end

def parallel_section(&block)
  ParallelSection::new(&block)
end

#Copy nodes file on first node
#copy $all.nodefile, $all.first

def copy( file, destination, params = {} )
  if params[:path] then
    path = params[:path]
  else
    path = file
  end
  cmd = "scp "
  cmd += $scp_connector
  cmd += " "
  cmd += "#{params[:location]}:" if ( params[:location] && ( params[:location] != "localhost" ) )
  cmd += "#{file} "
  cmd += "#{destination}:" if ( destination.to_s != "localhost" )
  cmd += "#{path}"
  command_result = $client.asynchronous_command(cmd)
  $client.command_wait(command_result["command_number"],1)
  result = $client.command_result(command_result["command_number"])
  puts cmd
  puts result["stdout"]
  puts result["stderr"]
  puts
end

#copy2 :from=>server_cigri, :to=>"localhost", :from_file=>file, :to_file=>dir_res_dst
def copy2(params)
	if params[:to] then
		to = params[:to]
	else
		to = "localhost"
	end
	if params[:from] then
		from = params[:from]
	else
		puts "ERROR: need :from parameter"
	end
	if params[:from_file] then
		from_file = params[:from_file]
	else
		puts "ERROR: need :from_file parameter"
	end
	if params[:to_file] then
		to_file = params[:to_file]
	else
		to_file = ENV['PWD']
	end

	if to.class == Array
	else
	end
end

