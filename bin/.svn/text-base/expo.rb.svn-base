#!/usr/bin/ruby

require 'optparse'
require 'yaml'
require 'resourceset'
require 'taskset'
require 'thread'

port = 15783

include Expo

$RMI = 'none'
$POLLING = false

if File.exist?("#{ENV['HOME']}/.expctrl_server") then
  config = YAML::load(File.open("#{ENV['HOME']}/.expctrl_server"))
  port = config['port'] if config['port']
  $RMI = config['rmi_protocol'] if config['rmi_protocol']
  $POLLING =  config['polling'] if config['polling']
end

opts = OptionParser.new
opts.on("-p","--port VAL", Integer) {|val| port = val }
opts.on("-r","--rmi_protocol VAL", String) {|val| $RMI = val }
opts.on("-w","--polling", "Do polling") {|val| $POLLING = val }
$rest = opts.parse(ARGV)

require 'expctrl'
require 'taktuk_wrapper'

$client = ExpCtrlClient::new("localhost:#{port}")

$client.open_experiment

$namer = NameSet::new

$all = ResourceSet::new

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

def ptask(location, targets, task)
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

load($rest.last)

$client.close_experiment
