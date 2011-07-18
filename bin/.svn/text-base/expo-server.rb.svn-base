#!/usr/bin/ruby

require 'socket'

require 'optparse'
require 'expctrl'
require 'taktuk_wrapper'
require 'yaml'
require 'resourceset'
require 'thread'

include Expo

$port_expctrl = 15783
$SOCKET_TYPE = 'UNIX' 
#$SOCKET_TYPE = 'FIFO'

$RMI = 'none'
$POLLING = false

$experiment_id = "default_#{$$}"

$namer = NameSet::new
$all = ResourceSet::new
$atasks_mutex = Mutex::new
$atasks = Hash::new

# Actions and list of them are used to monitor experiment activity
Struct.new("Action",:id,:type,:progress,:state,:line)
# State for action
RUNNING = 'R'
TERMINATED = 'T'
ERROR = 'E'

$ssh_connector = ""
$scp_connector = ""

class ActionList < Array
def initialize
	@action_mutex = Mutex::new
end

def add(*args)
	a = Struct::Action.new(nil,*args)
#		p caller
#		p caller[1].split(':')[1]
	@action_mutex.synchronize do
		a.id = self.length
		self << a
		a.line = caller[3].split(':')[1].to_i

	#puts "ACTION CALLER"
	#puts caller
	end
#		a.line = caller[1].split(':')[1].to_i
#		a.line = -1	
#		a.line = caller.join("\n")			
	return a
	end
end


class FifoExpoServer
#cf http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/87936
#`mkfifo "#{FIFO_FILE}"` unless test(?e, FIFO_FILE)

def initialize
if $SOCKET_TYPE != 'UNIX' 
			system("mkfifo /tmp/in_expo_#{$experiment_id}")
    	system("mkfifo /tmp/out_expo_#{$experiment_id}")
		end
  end

	def open_named_pipes
		puts "Start fifo_server"
	
		begin #NO REQUIRED FOR IN_EXPO FIFO ???
  		@in_expo = File.open("/tmp/in_expo_#{$experiment_id}",IO::NONBLOCK | IO::RDONLY)
		rescue 
			puts "yop" + $!
			sleep 1
			retry
		end

		begin
			@out_expo = File.open("/tmp/out_expo_#{$experiment_id}",IO::NONBLOCK | IO::WRONLY)
		rescue 
		#		p $!
			sleep 1
			retry
		end
	end

	def open_unix_socket
		puts "open_unix_socket"
		begin
			@in_expo = UNIXServer.open("/tmp/socket_expo_#{$experiment_id}").accept
			@out_expo = @in_expo
		rescue
			puts "expo-server #{$!}"
			sleep 20
		  retry
		end
	end

  def start
	
		$thread_fifo = Thread.new do
			if $SOCKET_TYPE == 'UNIX'
				open_unix_socket
			else
				open_named_pipes
			end
		 	loop do
      	request_yaml_length = @in_expo.sysread(6)
    #  	puts request_yaml_length

     		request_yaml = @in_expo.sysread(request_yaml_length.to_i)
     		request = YAML.load(request_yaml)
      	response = self.send(request['cmd'], request['args'])
				p response
			 	response_yaml = YAML.dump({'res'=>response})

      	@out_expo.syswrite(sprintf("%06d", response_yaml.length))
      	@out_expo.syswrite(response_yaml)
			end
    end
  end

  def hello_world(args)
    response = "hello workd #{args}"
    puts "Response to send #{response}"
    return response
  end

	def get_action_status(args)
		response = []
		if args.nil? || args.length == 0
			$action_list.each do |action|
				response << action.to_a
			end
		else
			args.each do |i|
#				puts "	args.each do |i|: #{i}"
				response << $action_list[i].to_a
			end
			if $action_list.length > args.last-1
			(args.last+1).upto($action_list.length-1) do |i|
				response << $action_list[i].to_a
				end
			end
		end
		puts "get_action_status response: "
		p response
		return response
	end

end

def close_experiment(arg)
	$stdout.close
	$stderr.close
	$client.close_experiment
end

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

	action = $action_list.add('check',0,RUNNING)

  n = nodes.all.resources.uniq
  puts "testing : " + n.inspect
  test_nis = "taktuk2yaml -s"
  test_nis += $ssh_connector
  n.each { |x|
    test_nis += " -m #{x}"
  }
  test_nis += " broadcast exec [ date ]"

	begin
  	command_result = $client.asynchronous_command(test_nis)
  	$client.command_wait(command_result["command_number"],1)
	
  	result = $client.command_result(command_result["command_number"])
	rescue
		puts "Warning, trouble with check: " + $!
	end

  tree = YAML::load( result["stdout"] )
  puts "Failing nodes :"
  tree["connectors"].each_value { |error|
    if error["output"].scan("initialization failed").pop  or error["output"].scan("Name or service not known").pop or error["output"].scan("Permission denied").pop then
      nodes.delete(error["peer"])
      puts error["peer"]+" : "+error["output"]
    end
  }

	action.progress = 100
	action.state = TERMINATED

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
	action = $action_list.add('task',50,RUNNING)
  cmd = "taktuk2yaml -s"
  cmd += $ssh_connector
  cmd += " -m #{location}"
  cmd += " b e [ #{task} ]"
  command_result = $client.asynchronous_command(cmd)
  $client.command_wait(command_result["command_number"],1)
	action.progress = 100
	action.state = TERMINATED
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
  targets.all.resources.each { |node|
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
  targets.all.resources.each { |node|
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
  cmd = "scp"
  cmd += $scp_connector
  cmd += " "
  cmd += "#{params[:location]}:" if ( params[:location] && ( params[:location] != "localhost" ) )
  cmd += "#{file} "
  cmd += "#{destination}:" if ( destination != "localhost" )
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
#REQUIRED ? NOT SURE 
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

if File.exist?("#{ENV['HOME']}/.expctrl_server") then
  config = YAML::load(File.open("#{ENV['HOME']}/.expctrl_server"))
  port = config['port'] if config['port']
  $RMI = config['rmi_protocol'] if config['rmi_protocol']
  $POLLING =  config['polling'] if config['polling']
end

opts = OptionParser.new
opts.on("-p","--port VAL", Integer) {|val| $port_expctrl  = val }
opts.on("-e","--experiment_id VAL", String) {|val| $experiment_id = val }
opts.on("-r","--rmi_protocol VAL", String) {|val| $RMI = val }
#opts.on("-w","--polling VAL", Boolean) {|val| $POLLING = val }

$rest = opts.parse(ARGV)

server = FifoExpoServer.new
server.start

$client = ExpCtrlClient::new("http://localhost:#{$port_expctrl}")
$client.open_experiment

system("rm /tmp/stdout_#{$experiment_id}")
system("rm /tmp/stderr_#{$experiment_id}")
$stdout = File.new("/tmp/stdout_#{$experiment_id}",'w+')
$stderr = File.new("/tmp/stderr_#{$experiment_id}",'w+')

$action_list = ActionList.new

load($rest.last)

$client.close_experiment

#Thread.kill($thread_fifo) if $thread_fifo.alive?

if $SOCKET_TYPE == 'UNIX' 
	system("rm /tmp/socket_expo_#{$experiment_id}")
else
	system("rm /tmp/in_expo_#{$experiment_id}")
	system("rm /tmp/out_expo_#{$experiment_id}")
end
