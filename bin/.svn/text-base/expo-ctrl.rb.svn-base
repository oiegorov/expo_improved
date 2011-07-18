#!/usr/bin/ruby

require 'socket'
require 'optparse'
require 'yaml'
require 'thread'
require 'monitor'
require 'webrick'
require 'xmlrpc/server'

RUNNING = 'R'
TERMINATED = 'T'
TERMINATING = 't'
ERROR = 'E'
LOADED = 'L'

$SOCKET_TYPE = 'UNIX'
#$SOCKET_TYPE = 'FIFO'

$verbose = false

$port = 2001
$fifo_expo_client = {} 
$expe_list = {}

$thread_eo = []

Struct.new("Experiment", :id, :file, :program, :state, :lock_eo, :buffer_stdout, :buffer_stderr )

def hello(args)
	"hello: #{args}"
end


def load_experiment(expe_args)
	puts 'load_experiment'
	expe_id = expe_args['expe_id']
	if !$expe_list[expe_id].nil?
		#MUST BE COMPLETED (error retun
		#return "Error expe_id already exists #{expe_id}"
		#MUST test if expe is in Running state
		puts "Warning we delete expe entry: #{expe_id} with state: #{$expe_list[expe_id].state}"
		$expe_list.delete(expe_id)
	end

	expe_file = expe_args['expe_file']
	expe_program = File.read(expe_file)

	$expe_list[expe_id] = Struct::Experiment.new(expe_id,expe_file,expe_program,'loaded', Monitor.new,"","")

	return(expe_program)
end

def launch_experiment(expe_args)
	puts 'launch_experiment'
	puts "expe args"
	p expe_args
	expe_id = expe_args['expe_id']

	if $expe_list[expe_id].nil?
		#MUST BE COMPLETED (error retun
		return "Error experiment doesn't exist, with expe_id  :#{expe_id}"	
	else
		expe = $expe_list[expe_id]
		p expe

		options = ''
		options = "-- #{expe_args['options']}" if  !expe_args['options'].nil?

		p "expo-server.rb -e #{expe.id} #{options} #{expe.file} &" 
		#system("ruby -d /home/auguste/Prog/rctrl/bin/expo-server.rb -e #{expe.id} #{expe.file} &" ) 

		system("expo-server.rb -e #{expe.id} #{options} #{expe.file} &" ) 

#		system("ruby -d /home/auguste/Prog/rctrl/bin/expo-server.rb -e #{expe.id} #{options} #{expe.file} &")


		$fifo_expo_client[expe.id] = FifoExpoClient.new(expe.id)

		expe.state = RUNNING 


		puts "#########################################"
		$thread_eo << Thread.new{monitor_stdout(expe)}
		$thread_eo << Thread.new{monitor_stderr(expe)}


		return "ok"
	end
end

def monitor_experiment(expe_args)
	expe_id = expe_args['expe_id']
	expe = $expe_list[expe_id]
	response = {}

	if expe.nil?
		return {'err' => "Error experiment doesn't exist, with expe_id  :#{expe_id}"}
		#MUST BE COMPLETED (return error code and message accordingly)
	else
		if expe_args['cmd'] == 'get_action_status'

			puts 'get_action_status......waiting'

			expe_args.delete('expe_id')
			response = $fifo_expo_client[expe_id].fifo_generic_cmd(expe_args)

			puts 'get_action_status......reponse'
			p response		
	
		end

		response['stdout']=''
		response['stderr']=''
		#new stdout/stderr ?
		expe.lock_eo.synchronize do
			if expe.buffer_stdout.length > 0

				puts "-------------------" 
				puts expe.buffer_stdout
				puts "-------------------" 

				response['stdout'] = expe.buffer_stdout
				expe.buffer_stdout = ''
			end
			if expe.buffer_stderr.length > 0
				response['stderr'] = expe.buffer_stderr
				expe.buffer_stderr = ''
			end
		end
		return response
	end
end


def fifo_generic_cmd_expo(expe_args)
	expe_id = expe_args['expe_id']
	if $expe_list[expe_id].nil?
		return "Error experiment doesn't exist, with expe_id  :#{expe_id}"	
		#MUST BE COMPLETED (error retun
	else
		expe_args.delete('expe_id')
		response = $fifo_expo_client[expe_id].fifo_generic_cmd(expe_args)
		puts "fifo_generic_cmd_expo response"
		p response
		return response
	end
end


def monitor_stdout(expe)
	puts "monitor_stdout #{expe.id}"
  sleep 3
	
	nb_read_bytes = 0

	while expe.state == RUNNING
		File.open("/tmp/stdout_#{expe.id}") do |file|
			file.seek(nb_read_bytes, IO::SEEK_SET)
			while line = file.gets
				puts '°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°'
				puts line
				puts '°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°'
				expe.lock_eo.synchronize{expe.buffer_stdout << line}
				nb_read_bytes += line.length
			end
		end
	end

	puts 'EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEND'
end

def monitor_stderr(expe)
	File.open("/tmp/stderr_#{expe.id}") do |file|
		while line = file.gets
			puts line
			expe.lock_eo.synchronize{expe.buffer_stderr << line}
		end
	end
end

def xmlrpc_server_launching(port)

	xml_servlet = XMLRPC::WEBrickServlet.new

	xml_servlet.add_handler("hello") { |arg| hello(arg) }
	xml_servlet.add_handler("launch_experiment") { |arg| launch_experiment(arg) }
	xml_servlet.add_handler("load_experiment") { |arg| load_experiment(arg) }	
	xml_servlet.add_handler("monitor_experiment") { |arg| monitor_experiment(arg) }

	xml_servlet.add_handler("fifo_generic_cmd_expo") { |arg| fifo_generic_cmd_expo(arg) }

	xml_servlet.add_multicall # Add support for multicall
	server = WEBrick::HTTPServer.new(:Port => port)
	server.mount("/expo", xml_servlet)
	trap("INT"){ server.shutdown }
	server.start
end

class FifoExpoClient
	
	def initialize(expe_id)

		nb_retry = 5
		
		@expe = $expe_list[expe_id]

		if $SOCKET_TYPE == 'UNIX'

			begin
				@in_expo = UNIXSocket.open("/tmp/socket_expo_#{expe_id}")
				@out_expo = @in_expo
			rescue
				puts "expo-ctrl #{$!}"
				sleep 1
				nb_retry = 	nb_retry -1
				exit if nb_retry==0
		  	retry
			end
		else 		
			system("mkfifo /tmp/in_expo_#{expe_id}")
  	  system("mkfifo /tmp/out_expo_#{expe_id}")
			puts expe_id
# ADD begin rescue retry stuff
			@in_expo = File.open("/tmp/in_expo_#{expe_id}","w")
			@out_expo = File.open("/tmp/out_expo_#{expe_id}","r")
		end
	end

	def fifo_generic_cmd(args)

		response = {}
		p args
		#		puts "yop: " + method_id.id2name + "	args: "  
		#		p args
		puts "generic cmd"
		begin
			request = YAML.dump(args)
			@in_expo.syswrite(sprintf("%06d", request.length))
			@in_expo.syswrite(request)
		rescue
			puts "Experiments is terminated ???: #{$!}"
			response['err']= 'NOFIFO'
			@expe.state = TERMINATING
		end
		puts "wait generic commande response"
		response = {}
   	begin
			response_yaml_length = @out_expo.sysread(6) 
	
			puts  "response size:" + response_yaml_length
		
			response_yaml = @out_expo.sysread(response_yaml_length.to_i)
#			puts  "response" 
#			p response_yaml
			
	
			response = YAML.load(response_yaml)

		rescue
			puts "Experiments is terminated ???: #{$!}"
			response['err']= 'NOFIFO'
			@expe.state = TERMINATING
		end

		print "reponse:" 
		p response

    return response 

	end

	def method_missing(method_id, args)
		return fifo_generic_cmd({'cmd'=> method_id.id2name, 'args'=>args})
  end

end

opts = OptionParser.new
opts.on("-p","--port VAL", Integer) {|val| $port = val }

#if false
if true
	xmlrpc_server_launching($port)
else
	expe_id = 'test.rb'
	puts 'load expe'
	p load_experiment({'expe_id'=>expe_id,'expe_file'=>expe_id})
	puts 'launch expe'
	p launch_experiment({'expe_id'=>expe_id})
	sleep 1
	i = 0
	

	2.times do
		puts "send cmd: #{i}"; i = i + 1
		p  fifo_generic_cmd_expo({'expe_id'=>expe_id,'cmd'=> 'hello_world', 'args'=>'poy'})
		sleep 1
	end
	

	10.times do
		puts "send cmd: #{i}"; i = i + 1
	#	p  fifo_generic_cmd_expo({'expe_id'=>expe_id,'cmd'=> 'hello_world', 'args'=>'poy'})
		p  fifo_generic_cmd_expo({'expe_id'=>expe_id,'cmd'=> 'get_action_status'})
		sleep 1
	end
end

