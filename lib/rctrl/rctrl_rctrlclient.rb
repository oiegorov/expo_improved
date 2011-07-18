require 'rctrl/rctrl_namespace'
require 'rctrl/rctrl_rctrlresponse'
require 'date'
module Expo
$RMI_COMMANDS = [
  #run an asynchonous command on the server, return the command number
  ['asynchronous_command','command_line'],
  #run a command on the server
  ['command','command_line'],
  ['command_delete','command_number'],
  ['command_archive','command_number'],
  #get info from a command having command_number number
  #raises "Invalid command number"
  ['command_info','command_number'],
  #input something on the stdin of the command command_number
  #raises "Invalid command number"
  ['command_input','command_number','input'],
  #get results from the command command_number
  #raises "Invalid command number"
  ['command_result','command_number'],
  #get inputs submited to a command
  #raises "Invalid command number"
  ['get_command_inputs','command_number'],
  #runs a command that should interact with a user
  ['interactive_command','command_line'],
  #runs a command on the remote server server_name
  #command is one of the commands a remote control server supports, like "command_result",
  #for parameters see rctrl_structures
  ['recursive_command','server_name', 'command', 'parameters'],
  #runs a command at the given date
  ['delayed_command','command_line','date'],
  #rewind the input and output buffers of a command for reading them again
  #raises "Invalid command number"
  ['command_rewind','command_number'],
  #runs a ruby command on the server, in the server context
  ['ruby_command','ruby_script'],
  #runs a ruby command on the server, at the given date in the server context
  ['ruby_delayed_command','ruby_script','date'],
  #runs an asynchronous ruby command on the server, in the server context
  ['ruby_asynchronous_command','ruby_script'],
  #runs multiple commands in bulk on the server
  ['bulk_commands','commands'],
  ['bulk_command_results','command_numbers'],
  ['bulk_command_infos','command_numbers']
]

require 'drb'
class RCtrlClientDrbDriver 
	def initialize(server)
		DRb.start_service()
		@drb_client = DRbObject.new(nil, server) 
	end
		
	def method_missing(method_id, *args)
		response = @drb_client.send(method_id.id2name, *args)
		return response
	end
end

require 'xmlrpc/client'
class RCtrlClientXMLRPCDriver 
	def initialize(server)
		@xmlrpc_client = XMLRPC::Client.new(server, "/expo", 2000)
	end

	def method_missing(method_id, *args)
		response = @_xmlrpc_client.call(method_id.id2name, *args)
		return response
	end
end

require 'rctrl/rctrl_service'
class RCtrlService
end
class RCtrlClientNoneDriver < RCtrlService
        def initialize(server)
                super(nil,nil)
        end
end

class RCtrlClient
 
	def initialize(server=nil)
		if !(server=~ /^http:\/\/|^druby:\/\//)
			server = "druby://" + server if 	$RMI == 'drb'
			server = "http://" + server if 	$RMI == 'soap'
		end

                @rctrl_client = nil
		if $RMI == 'soap'
                        require 'soap/rpc/driver'
                        @rctrl_client = SOAP::RPC::Driver::new(server,NS)
                        $RMI_COMMANDS.each {|command| @rctrl_client.add_method(*command)}
		elsif $RMI == 'xmlrpc'
			rctrl_client_driver ="RCtrlClientXMLRPCDriver"
                elsif $RMI == 'none'
                        rctrl_client_driver ="RCtrlClientNoneDriver"
		else
			$RMI = 'drb'
			rctrl_client_driver ="RCtrlClientDrbDriver"
		end 

		eval "@rctrl_client = #{rctrl_client_driver}.new(server)" if not @rctrl_client

		connect = false
		i = 1

		while !connect and $POLLING
			begin
				response =@rctrl_client.ruby_command("puts 'hello'")
				connect = true
			rescue
				puts $!
				puts "Can't connect to Server, wait #{i} sec. before retry:" + $!
				sleep i
				i = 2 * i
				raise "Connection to Server Error: " + $!  if i > 60
			end
		end

	end

	def method_missing(method_id, *args)
		response = @rctrl_client.send(method_id.id2name, *args)
		return response
	end

	#waits for a command to end polling the server, can take a block to execute after the command exited
 	#raises "Invalid command number"
 	#raises "Polling_time cannot be 0"
 	def command_wait(command_number, polling_time = 10, delay = 0, &block)

 		raise "Polling_time cannot be 0" if polling_time == 0
		response = command_info(command_number)
		info = response.result
		response = CommandWaitResponse::new
		if block
 	        	t = Thread::new {
            	                info = internal_command_wait(command_number, delay, polling_time, info)
    	                        block.call(info)
  	        	}
          		response.result = info
  		        return response
		else
  	        	response.result = internal_command_wait(command_number, delay, polling_time, info)
          		return response
		end
	end

 	private

 	def internal_command_wait(command_number, delay, polling_time, info)

 		if info["scheduled"]
           		now = DateTime::now
   	        	scheduled_time = info["scheduled_time"]
   		        sleep( (scheduled_time - now) * 60.0 * 60 * 24 ) if (scheduled_time - now) * 60.0 * 60 * 24 > 0.0
 		end
 		sleep(delay)
 		while not info["finished"]
   		        sleep(polling_time)
           		response = command_info(command_number)
   	        	info = response.result
 		end
 		return info
 	end

end
end
