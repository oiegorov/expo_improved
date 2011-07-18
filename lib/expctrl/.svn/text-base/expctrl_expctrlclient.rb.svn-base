require 'resctrl'
require 'expctrl/expctrl_expctrlresponse'
require 'expctrl/expctrl_service'
require 'thread'

module Expo

$RMI_COMMANDS_EXPCTRL = [
    ['create_experiment'],
    ['add_command','experiment_number','command_number'],
    ['add_commands','experiment_number','command_numbers'],
    ['add_reservation','experiment_number','reservation_number'],
    ['add_nodes','experiment_number','nodes_name','nodes'],
    ['get_nodes','experiment_number','nodes_name'],
    ['get_all_nodes','experiment_number'],
    ['get_all_commands','experiment_number'],
    ['get_all_reservations','experiment_number'],
    ['experiment_info','experiment_number'],
    ['delete_command','experiment_number','command_number']
]


class ExpCtrlClientDrbDriver 
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
class ExpCtrlClientXMLRPCDriver 
	def initialize(server)
		@xmlrpc_client = XMLRPC::Client.new(server, "/expo", 2000)
	end

	def method_missing(method_id, *args)
		response = @_xmlrpc_client.call(method_id.id2name, *args)
		return response
	end
end

require 'rctrl/rctrl_service'
class ExpCtrlClientNoneDriver < ExpCtrlService
        def initialize(server)
                super(nil,nil)
        end
end


class ExpCtrlClient

 	def initialize(server=nil)
                @expctrl_client = nil
		
                if !(server=~ /^http:\/\/|^druby:\/\//)
			server = "druby://" + server if 	$RMI == 'drb'
			server = "http://" + server if 	$RMI == 'soap'
		end

		if $RMI == 'soap'
                        require 'soap/rpc/driver'
                        @expctrl_client = SOAP::RPC::Driver::new(server,NS)
                        $RMI_COMMANDS_EXPCTRL.each {|command| @expctrl_client.add_method(*command)}
		elsif $RMI == 'xmlrpc'
			expctrl_client_driver ="ExpCtrlClientXMLRPCDriver"
                elsif $RMI == 'none'
                        expctrl_client_driver ="ExpCtrlClientNoneDriver"
		else
			$RMI = 'drb'
			expctrl_client_driver ="ExpCtrlClientDrbDriver"
		end 

		eval "@expctrl_client = #{expctrl_client_driver}.new(server)" if not @expctrl_client

		connect = false
		i = 1

		while !connect and $POLLING
			begin
				response =@expctrl_client.ruby_command("puts 'hello'")
				connect = true
			rescue
				puts $!
				puts "Can't connect to Server, wait #{i} sec. before retry:" + $!
				sleep i
				i = 2 * i
				raise "Connection to Server Error: " + $!  if i > 60
			end
		end
                if $RMI == 'none'
                        @client = @expctrl_client
                else
                        @client = ResCtrlClient::new(server)
                end
                @experiment_number = nil
                @commands_mutex = Mutex::new
                @commands = Array::new
                @reservations_mutex = Mutex::new
                @reservations = Array::new
                @nodes_mutex = Mutex::new
                @nodes = Hash::new
        end

	def method_missing(method_id, *args)
		response = @expctrl_client.send(method_id.id2name, *args)
		return response
	end

#  def initialize(server)
#    super(server, NS)
#    @client = ResCtrlClient::new(server)
#    @experiment_number = nil
#    @commands_mutex = Mutex::new
#    @commands = Array::new
#    @reservations_mutex = Mutex::new
#    @reservations = Array::new
#    @nodes_mutex = Mutex::new
#    @nodes = Hash::new
#    add_method('create_experiment')
#    add_method('add_command','experiment_number','command_number')
#    add_method('add_commands','experiment_number','command_numbers')
#    add_method('add_reservation','experiment_number','reservation_number')
#    add_method('add_nodes','experiment_number','nodes_name','nodes')
#    add_method('get_nodes','experiment_number','nodes_name')
#    add_method('get_all_nodes','experiment_number')
#    add_method('get_all_commands','experiment_number')
#    add_method('get_all_reservations','experiment_number')
#    add_method('experiment_info','experiment_number')
#    add_method('delete_command','experiment_number','command_number')
#  end

  def experiment_number
    response = ExperimentNumberResponse::new
    response["experiment_number"] = @experiment_number
    return response
  end

  def command_archive(command_number)
    return @client.command_archive(command_number)
  end

  def command_info(command_number)
    return @client.command_info(command_number)
  end

  def bulk_command_infos(command_numbers)
    return @client.bulk_command_infos(command_numbers)
  end

  def command_input(command_number,input)
    return @client.command_input(command_number,input)
  end
 
  def command_result(command_number)
    return @client.command_result(command_number)
  end
  
  def bulk_command_results(command_numbers)
    return @client.bulk_command_results(command_numbers)
  end
  
  def get_command_inputs(command_number)
    return @client.get_command_inputs(command_number)
  end
  
  def command_rewind(command_number)
    return @client.command_rewind(command_number)
  end

#  def command_wait(command_number, polling_time = 10, delay = 0, &block)
#    return @client.command_wait(command_number, polling_time , delay, &block)
#  end

  def reservation_info(reservation_number)
    return @client.reservation_info(reservation_number)
  end

  def reservation_stats(type, parameters)
    return @client.reservation_stats(type, parameters)
  end
  
  def reservation_resources(reservation_number)
    return @client.reservation_resources(reservation_number)
  end
  
  def reservation_jobs(reservation_number)
    return @client.reservation_jobs(reservation_number)
  end

  def reservation_job(reservation_number, job_name, cluster_name)
    return @client.reservation_job(reservation_number, job_name, cluster_name)
  end

  def delete_reservation(reservation_number)
    return @client.delete_reservation(reservation_number)
  end
 
#  def reservation_wait(reservation_number, polling_time = 10, delay = 0, &block)
#    return @client.reservation_wait(reservation_number, polling_time , delay, &block)
#  end

  def open_experiment( experiment_number = nil )
    if experiment_number then
      experiment_info( experiment_number )
      @experiment_number = experiment_number
    else
      result = create_experiment
      @experiment_number = result["experiment_number"]
    end
    response = OpenExperimentResponse::new
    response["experiment_number"] = @experiment_number
    return response
  end

  def new_reservation( type, parameters )
    response = @client.new_reservation( type, parameters )
    if @experiment_number then
      add_reservation( @experiment_number, response["reservation_number"] )
    else
      @reservations_mutex.synchronize { @reservations.push( response["reservation_number"] ) }
    end
    return response
  end

  def open_reservation( type, id )
    response = @client.open_reservation( type, id )
    if @experiment_number then
      add_reservation( @experiment_number, response["reservation_number"] )
    else
      @reservations_mutex.synchronize { @reservations.push( response["reservation_number"] ) }
    end
    return response
  end

  def command( command_line )
    response = @client.command( command_line )
    if @experiment_number then
      add_command( @experiment_number, response["command_number"] )
    else
      @commands_mutex.synchronize { @commands.push( response["command_number"] ) }
    end
    return response
  end

  def command_delete(command_number)
    response = @client.command_delete(command_number)
    if @experiment_number then
      delete_command( @experiment_number, command_number )
    else
      @commands_mutex.synchronize { @commands.delete(command_number) }
    end
    return response
  end

  def asynchronous_command( command_line )
    response = @client.asynchronous_command( command_line )
    if @experiment_number then
      add_command( @experiment_number, response["command_number"] )
    else
      @commands_mutex.synchronize { @commands.push( response["command_number"] ) }
    end
    return response
  end

  def bulk_commands( commands )
    response = @client.bulk_commands( commands )
    if @experiment_number then
      command_numbers = Array::new
      response.each_value { |r|
        command_numbers.push(r["command_number"])
      }
      add_commands( @experiment_number, command_numbers)
    else
      @commands_mutex.synchronize { 
        response.each_value { |r|
          @commands.push( r["command_number"] ) 
        }
      }
    end
    return response
  end

  def interactive_command( command_line )
    response = @client.interactive_command( command_line )
    if @experiment_number then
      add_command( @experiment_number, response["command_number"] )
    else
      @commands_mutex.synchronize { @commands.push( response["command_number"] ) }
    end
    return response
  end

  def delayed_command( command_line, date )
    response = @client.delayed_command( command_line, date )
    if @experiment_number then
      add_command( @experiment_number, response["command_number"] )
    else
      @commands_mutex.synchronize { @commands.push( response["command_number"] ) }
    end
    return response
  end

  def ruby_command( ruby_script )
    response = @client.ruby_command( ruby_script )
    if @experiment_number then
      add_command( @experiment_number, response["command_number"] )
    else
      @commands_mutex.synchronize { @commands.push( response["command_number"] ) }
    end
    return response
  end

  def ruby_asynchronous_command( ruby_script )
    response = @client.ruby_asynchronous_command( ruby_script )
    if @experiment_number then
      add_command( @experiment_number, response["command_number"] )
    else
      @commands_mutex.synchronize { @commands.push( response["command_number"] ) }
    end
    return response
  end

  def ruby_delayed_command( ruby_script, date )
    response = @client.ruby_delayed_command( ruby_script, date )
    if @experiment_number then
      add_command( @experiment_number, response["command_number"] )
    else
      @commands_mutex.synchronize { @commands.push( response["command_number"] ) }
    end
    return response
  end

  def recursive_command( server_name, command, parameters )
    response = @client.recursive_command( server_name, command, parameters )
    if @experiment_number then
      add_command( @experiment_number, response["command_number"] )
    else
      @commands_mutex.synchronize { @commands.push( response["command_number"] ) }
    end
    return response
  end

  def nodes( nodes_name=nil, nds=nil )
    response = nil
    if @experiment_number then
      if nodes_name then
        if nds then
          response = add_nodes( @experiment_number, nodes_name, nds )
        else
          response = get_nodes( @experiment_number, nodes_name )
        end
      else
        response = get_all_nodes( @experiment_number )
      end
    else
      if nodes_name then
        if nds then
          @nodes_mutex.synchronize { @nodes[nodes_name] = nds }
        else
          response = GetNodesResponse::new
          @nodes_mutex.synchronize { response["nodes"] = @nodes[nodes_name] }
          raise "Invalid nodes name" if !response["nodes"]
        end      
      else
        response = GetAllNodesResponse::new
        response["nodes"] = Hash::new
	@nodes_mutex.synchronize { response["nodes"].replace( @nodes ) }
      end
    end
    return response
  end

  def commands
    if @experiment_number then
      response = get_all_commands( @experiment_number )
    else
      response = GetAllCommandsResponse::new
      @commands_mutex.synchronize { response["commands"] = Array::new( @commands ) }
    end
    return response
  end

  def reservations
    if @experiment_number then
      response = get_all_reservations( @experiment_number )
    else
      response = GetAllReservationsResponse::new
      @reservations_mutex.synchronize { response["reservations"] = Array::new( @reservations ) }
    end
    return response
  end

  def all
    response = reservations
    r = response["reservations"]
    response = commands
    c = response["commands"]
    response = nodes
    n = response["nodes"]
    create_time = nil
    h = nil
    info = nil
    if @experiment_number then
      response = experiment_info( @experiment_number )
      info = response.result
    end
    response = GetAllResponse::new
    response.result = { "nodes" => n, "commands" => c, "reservations" => r , "experiment_info" => info  }
    return response
  end

  def dump_commands_memory_friendly(file)
    exp = all.result
 
   
    exp["commands"].each do |cmd_number|
      cmd = Hash::new
      cmd["number"] = cmd_number
      response = command_info( cmd_number )
      cmd["info"] = response.result
      command_rewind( cmd_number )
      response = command_result( cmd_number )
      cmd["result"] = response.result
      response = get_command_inputs( cmd_number )
      cmd["inputs"] = response.result["inputs"]
      file.puts YAML::dump(cmd)
    end

  end

  def dump_experiment
    exp = all.result
 
    res = Hash::new
    exp["reservations"].each do |reservation_number|
      re = Hash::new
      result = reservation_info( reservation_number ).result
      re["info"] = result
      exp["commands"].push result["command_number"] if result["command_number"]
      exp["commands"].push result["resources_command_number"] if result["resources_command_number"]
      exp["commands"].push result["delete_command_number"] if result["delete_command_number"]
      re["resources"] = reservation_resources( reservation_number )["resources"]
      re["jobs"] = reservation_jobs( reservation_number )["jobs"]
      res[reservation_number] = re
    end
    exp["reservations"] = res
    
    cmds = Hash::new
    exp["commands"].each do |cmd_number|
      cmd = Hash::new
      response = command_info( cmd_number )
      cmd["info"] = response.result
      command_rewind( cmd_number )
      response = command_result( cmd_number )
      cmd["result"] = response.result
      response = get_command_inputs( cmd_number )
      cmd["inputs"] = response.result["inputs"]
      cmds[cmd_number] = cmd
    end
    exp["commands"] = cmds

    response = DumpExperimentResponse::new
    response.result = exp
    return response
  end

  def close_experiment
    @experiment_number = nil
    return CloseExperimentResponse::new
  end
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

        def reservation_wait(reservation_number, polling_time = 10, delay = 0, &block)
                raise "Polling_time cannot be 0" if polling_time == 0
                info = reservation_info(reservation_number).result
                response = ReservationWaitResponse::new
                if block
                        t = Thread::new {
                                info = internal_reservation_wait(reservation_number, delay, polling_time, info)
                                block.call(info)
                        }
                        response.result = info
                        return response
                else
                        response.result = internal_reservation_wait(reservation_number, delay, polling_time, info)
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

  def internal_reservation_wait(reservation_number, delay, polling_time, info)
    sleep(delay)
    while not info["started"]
      sleep(polling_time)
      info = reservation_info(reservation_number).result
    end
    return info
  end


end

end
