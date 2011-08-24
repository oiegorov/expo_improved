#!/usr/bin/ruby

#require rubygems explicitely to ease the debugging RUBYOPTS=""
require 'rubygems'

require 'optparse'
require 'yaml'
require 'resourceset'
require 'taskset'
require 'thread'

require 'g5k_api' #for cleanup after the experiment is finished

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
#require 'taktuk2yaml'

#----here we initialize some instance vars of $client
$client = ExpCtrlClient::new("localhost:#{port}")

$client.open_experiment

$namer = NameSet::new
#----again, just initialize some stuff (hashes,etc...)
$all = ResourceSet::new

$atasks_mutex = Mutex::new
$atasks = Hash::new

$ssh_connector = ""

$scp_connector = "-o StrictHostKeyChecking=no"

class ExpoResult < Array
  #def duration
  def mean_duration
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

# !! we don't need check anymore. Reservation is checked automatically
# in g5k_run

=begin
def check( nodes )
  n = nodes.flatten(:node).uniq
  puts "testing : " + n.inspect
  #----CHANGED HERE
  #test_nis = "taktuk2yaml -s"
  #test_nis = "ruby taktuk2yaml.rb --connector /usr/bin/oarsh -f $OAR_FILE_NODES -s"
  test_nis = "ruby taktuk2yaml.rb -s"
  
  test_nis += $ssh_connector
  n.each(:node) { |x|
    test_nis += " -m #{x}"
  }
  test_nis += " broadcast exec [ date ]"
  #----for the first test test_nis = taktuk2yaml -s -m bordereau-78.bordeaux.grid5000.fr -m
  #----capricorne-49.lyon.grid5000.fr broadcast exec [ date ]
  command_result = $client.asynchronous_command(test_nis)
  $client.command_wait(command_result["command_number"],1)
  result = $client.command_result(command_result["command_number"])

  tree = YAML::load( result["stdout"] )

  #----for debugging
  #puts "dates :"
  #puts result["stdout"];
  
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
=end

#Copy data from home directory to tmp on $all gateway (here gdx gw)
#task $all.gw, "scp ~/data  #{$all.first}:/tmp/"
def task(location, task)
  #cmd = "taktuk2yaml -s"
  cmd = "ruby taktuk2yaml.rb -s"
  cmd += $ssh_connector
  cmd += " -m #{location}"
  cmd += " b e [ #{task} ]"
  command_result = $client.asynchronous_command(cmd)
  $client.command_wait(command_result["command_number"],1)
  #command_result = $client.command(cmd)
  
  return make_taktuk_result( command_result["command_number"] )
end

def atask(location, task)
  #cmd = "taktuk2yaml -s"
  cmd = "ruby taktuk2yaml.rb -s"
  cmd += $ssh_connector
  cmd += " -m #{location}"
  cmd += " b e [ #{task} ]"
  #----to create an asynch cmd we use generic cmd BUT! we don't wait
  #    till it finishes and continue execution of main process. In case
  #    of asynch cmd, response will contain only cmd id number
  command_result = $client.asynchronous_command(cmd)
  #----means only one atask can be inside this block at a time
  $atasks_mutex.synchronize {
    #----register our asynch cmd with provided params
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
  #cmd = "taktuk2yaml -s"
  #cmd = "ruby taktuk2yaml.rb --connector /usr/bin/oarsh -s"
  cmd = "ruby taktuk2yaml.rb -s"
  cmd += $ssh_connector
  #----means that 'location' node will start all other nodes. For
  #----details see 2.2.2 section of Taktuk manual
  cmd += " -m #{location}"
  cmd += " -["
  targets.flatten(:node).each(:node) { |node|
    cmd += " -m #{node}"
  }
  cmd += " downcast exec [ #{task} ]"
  cmd += " -]"
  command_result = $client.asynchronous_command(cmd)
  $client.command_wait(command_result["command_number"],1)
  #----here we return two values: id of a command and a hash 'res' where
  #----all the info about the command is stored
  return make_taktuk_result(command_result["command_number"])
end

def patask(location, targets, task)
  #cmd = "taktuk2yaml -s"
  #cmd = "ruby taktuk2yaml.rb --connector /usr/bin/oarsh -s"
  cmd = "ruby taktuk2yaml.rb -s"
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
  #----scp works as the following
  #----scp myfile.txt oiegorov@access.lille.grid5000.fr:/home/oiegorov
  #----       ^                     ^                      ^
  #----      file              destination                path
  cmd = "scp "
  #cmd += $scp_connector # == -o StrictHostKeyChecking=no
  cmd += " "
  #here we have params[:location]==localhost for use_case_1_1.rb
  #cmd += "#{params[:location]}:" if ( params[:location] && ( params[:location] != "localhost" ) )
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

if not @options[:no_cleanup]
  # clean up reservations & deployments
  cleanup
end

$client.close_experiment
