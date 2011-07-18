require 'cmdctrl'
require 'rctrl/rctrl_rctrlcommand'
require 'rctrl/rctrl_rctrlresponse'
require 'rctrl/rctrl_delayedcommandscheduler'
require 'rctrl/rctrl_rctrlclient'
require 'rctrl/rctrl_namespace'

require 'thread'

#the main service provided by the remote control server
module Expo
class RCtrlService
  @@instance_number = 0

  #creates a new server
  def initialize( archive_level = nil, archive_path = nil )
    #other servers we might know of
    @server_hash = Hash::new
    @server_mutex = Mutex::new
    #hash of the commands that are run or have been run on the server
    @command_hash = Hash::new
    #the first command number
    @command_number = 0
    @command_mutex = Mutex::new
    #a new scheduler for delayed commands
    @command_scheduler = DelayedCommandScheduler::new
    @@instance_number += 1
    @archive = archive_level
    if archive_level then
      if archive_path then
        @save_directory = archive_path
      else
        @save_directory = "rctrl-#{Time::now}-#{Process::pid}-#{@@instance_number}"
      end
      Dir::mkdir(@save_directory)
    end
  end

private

  #registers new commands into the Hash table, and affects it the next free command number
  #registers the command in the scheduler if it is a scheduled command
  def register_command(cmd)
    command_num = 0
    @command_mutex.synchronize do
      command_num = @command_number
      @command_hash[@command_number] = cmd
      @command_number += 1
    end
    if cmd.scheduled then
      @command_scheduler.register_command(cmd)
    end
    return command_num
  end

  #returns a command from it's command number
  #raises "Invalid command number" if the command number is invalid
  def get_command(cmd_number)
    cmd = nil
    @command_mutex.synchronize do
      cmd = @command_hash[cmd_number]
    end
    raise "Invalid command number" if !cmd
    return cmd
  end

  def del_command(cmd_number)
    cmd = get_command(cmd_number)
    @command_mutex.synchronize do
      @command_hash.delete(cmd_number)
    end
    if cmd.scheduled then
      @command_scheduler.del_command(cmd)
    end
  end

  #get a client to comunicate with the server server_name
  def get_server_ref(server_name)
    server = get_server(server_name)
    if not server then
      server = RCtrlClient::new(server_name)
      register_server(server_name, server)
    end
    return server
  end

  #registers a new remote control server
  #associating it's server name with the client to comunicate with it
  def register_server(server_name,server)
    @server_mutex.synchronize do
      @server_hash[server_name] = server
    end
    return nil
  end

  #get a server client reference from it's name
  #nil is returned if the server doesn't exist
  def get_server(server_name)
    server = nil
    @server_mutex.synchronize do
       server = @server_hash[server_name];
    end
    return server
  end

public

  def generic_command(params)
    c=nil
    response = GenericCommandResponse::new
    
    if params["ruby_command"] then
      c =  RCtrlCommand::new(CmdCtrl::Commands::CommandBufferer::new( CmdCtrl::Commands::Command::new{ eval(params["ruby_script"]) } ) )
      c.set_ruby_script(params["ruby_script"])
    else
      if params["interactive"] then
        c = RCtrlCommand::new(CmdCtrl::Commands::CommandBufferer::new( CmdCtrl::Commands::InteractiveCommand::new(params["command_line"]) ) )
      else
        c =  RCtrlCommand::new(CmdCtrl::Commands::CommandBufferer::new( CmdCtrl::Commands::Command::new(params["command_line"]) ) )
      end
    end

    if params["delayed"] or params["asynchronous"] then
      c.cmd.on_exit do |status, cmd|
        c.set_end_time
        c.archive("#{@save_directory}/#{response["command_number"]}") if @archive == 1
      end
    end

    if params["delayed"] then
      c.scheduled = true
      c.scheduled_time = params["date"]
    end

    response["command_number"] = register_command(c)

    c.archive("#{@save_directory}/#{response["command_number"]}") if @archive == 2

    if not params["delayed"] then
      c.set_start_time
      c.cmd.run
      if not params["asynchronous"] then
        c.cmd.wait
        c.set_end_time
        c.archive("#{@save_directory}/#{response["command_number"]}") if @archive == 1
        response["exit_status"] = c.cmd.status.exitstatus
        response["stdout"] = c.cmd.read_stdout
        response["stderr"] = c.cmd.read_stderr
      end
    end

    return response

  end


  #runs command_line and wait for it to finish, then returns command number, status and outputs
  def command(command_line)
    return generic_command( { "command_line" => command_line } )
  end

  #Creates a new command, command_line, that is run on the server, the command_number is returned
  def asynchronous_command(command_line)
    return generic_command( { "command_line" => command_line, "asynchronous" => true } )
  end

  #runs an interactive command on the server
  def interactive_command(command_line)
    return generic_command( { "command_line" => command_line, "asynchronous" => true, "interactive" => true } )
  end

  #creates a command to be run at the given date
  def delayed_command(command_line, date)
    return generic_command( { "command_line" => command_line, "delayed" => true, "date" => date } )
  end

  #runs the ruby script on the server in the server context
  def ruby_command(ruby_script)
    return generic_command( { "ruby_script" => ruby_script, "ruby_command" => true } )
  end

  #runs a ruby script at the given date in the server context
  def ruby_delayed_command(ruby_script, date)
    return generic_command( { "ruby_script" => ruby_script, "ruby_command" => true, "delayed" => true, "date" => date } )
  end

  #runs a ruby script on the server in the server context
  def ruby_asynchronous_command(ruby_script)
    return generic_command( { "ruby_script" => ruby_script, "ruby_command" => true, "asynchronous" => true } )
  end

  def bulk_commands(commands)
    response = BulkCommandsResponse::new
    commands.each_index { |i|
      command, parameters = commands[i]
      target_method = self.method(command)
      response[i] = target_method.call(*parameters)
    }
    return response
  end

  def bulk_command_results(command_numbers)
    response = BulkCommandResultsResponse::new
    command_numbers.each { |i|
      response[i] = self.command_result(i)
    }
    return response
  end

  def bulk_command_infos(command_numbers)
    response = BulkCommandInfosResponse::new
    command_numbers.each { |i|
      response[i] = self.command_info(i)
    }
    return response
  end

  #returns the status of the command, and the unread outputs so far 
  def command_result(command_number)
    response = CommandResultResponse::new
    c = get_command(command_number)
    if c.cmd then
      response["exited"] = c.cmd.exited?
      if response["exited"] then
        response["exit_status"] = c.cmd.status.exitstatus
      end
      response["stdout"] = c.cmd.read_stdout
      response["stderr"] = c.cmd.read_stderr
    end
    return response
  end

  #send an input to the command command_number
  #raises "Invalid command number"
  def command_input(command_number, input)
    c = get_command(command_number)
    if c.cmd then
      c.add_input(input)
      c.cmd.puts(input)
    end
    return CommandInputResponse::new
  end

  #returns most information about a command registerd in the server, given it's command number.
  #info returned are : the command line, if the command is started, the time it started, if it finisehd, the time it finished, if it is a scheduled command, the time it is scheduled to start, if the command is a ruby command and it's script
  #raises "Invalid command number" if the command number is invalid
  def command_info(command_number)

    #get the command associated with the command number
    #"Invalid command number" is raised if command number is invalid
    c = get_command(command_number)
    response = CommandInfoResponse::new
    if c.cmd then
      response["command_line"] = c.cmd.cmd
      response["started"] = c.started
      response["archived"] = c.archived
    end
    if c.started then
      response["start_time"] = c.start_time
      response["pid"] = c.cmd.pid
    end
    response["finished"] = c.finished
    if c.finished then
      response["end_time"] = c.end_time
    end
    response["scheduled"] = c.scheduled
    if c.scheduled then
      response["scheduled_time"] = c.scheduled_time
    end
    response["ruby_command"] = c.ruby_command
    if c.ruby_command then
      response["ruby_script"] = c.ruby_script
    end
    response["recursive"] = c.recursive
    if c.recursive then
      response["server_name"] = c.server_name
      response["command"] = c.command
      response["parameters"] = c.parameters
      response["command_response"] = c.command_response
    end
    return response
  end

  #get the inputs sent to command command_number
  #raises "Invalid command number"
  def get_command_inputs(command_number)
    c = get_command(command_number)
    response = GetCommandInputsResponse::new
    if c.cmd then
      response["inputs"] =  c.get_inputs
    else
      response["inputs"] = nil
    end
    return response
  end

  #the command is passed to the server_name server which should handle it
  #an exception is raised if the server cannot be contacted
  def recursive_command(server_name, command, parameters)
    server = get_server_ref(server_name)
    response = RecursiveCommandResponse::new
    parameters_array = []
    if $RMI == 'soap'
            parameters.__xmlele.collect { |x, y| parameters_array.push(y) }
    else
            parameters.each { |y| parameters_array.push(y) }
    end
    c = RCtrlCommand::new(nil)
    response["command_number"] = register_command(c)
#    puts "#{command} : #{parameters_array.inspect}"
    response["command_result"] = server.send(command, *parameters_array)
    c.set_recursive(server_name, command, parameters, response["command_result"])
    
#    target_method = server.method(command)
#    parameters_array = []
#    parameters.__xmlele.collect { |x, y| parameters_array.push(y) }
#    c = RCtrlCommand::new(nil)
#    response["command_number"] = register_command(c)
#    response["command_result"] = target_method.call(*parameters_array).result
#    c.set_recursive(server_name, command, parameters, response["command_result"])
    return response
  end

  #rewinds the command outputs to read them again
  #raises "Invalid command number" 
  def command_rewind(command_number)
    c = get_command(command_number)
    if c.cmd then
      c.cmd.rewind_stdout
      c.cmd.rewind_stderr
    end
    return CommandRewindResponse::new
  end

  def command_delete( command_number )
    del_command( command_number )   
    return CommandDeleteResponse::new
  end

  def command_archive( command_number )
    c = get_command(command_number)
    c.archive("#{@save_directory}/#{command_number}") if @archive
    return CommandArchiveResponse::new   
  end


end
end
