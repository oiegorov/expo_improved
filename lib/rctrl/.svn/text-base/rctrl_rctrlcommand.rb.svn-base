require 'date'
module Expo
#represents a command as seen by the server
class RCtrlCommand
  
  attr_accessor :cmd, :started, :start_time, :finished, :end_time, :inputs, :interactive, :scheduled, :scheduled_time, :ruby_command, :ruby_script, :recursive, :server_name, :command, :parameters, :command_response, :archived

  #initialize the command with a given command
  def initialize(cmd)
    @cmd = cmd
    @started = false
    @finished = false
    @scheduled = false
    @interactive = false
    @start_time = nil
    @end_time = nil
    @scheduled_time = nil
    @inputs = Array::new
    @ruby_command = false
    @ruby_script = nil
    @recursive = false
    @server_name = nil
    @command = nil
    @parameters = nil
    @command_response = nil
    @archived = false
  end

  #set the ruby script and the ruby_command flag
  def set_ruby_script( ruby_script )
    @ruby_script = ruby_script
    @ruby_command = true
  end

  #set the recursive command flag and the relevant parameters
  def set_recursive( server_name, command, parameters, command_response )
    @server_name = server_name
    @command = command
    @parameters = parameters
    @command_response = command_response
    @recursive = true
  end    

  #set the start time and the start flag
  def set_start_time
    @start_time = DateTime::now
    @started = true
  end

  #set the end time and the finished flag
  def set_end_time
    @end_time = DateTime::now
    @finished = true
  end

  #adds an input line to the inputs array and dates it
  def add_input(input)
    @inputs.push({"date" => DateTime::now, "input" => input })
    return nil
  end

  #returns the inputs array
  def get_inputs
    return @inputs
  end

  def archive(base_file_name)
    if @cmd then
      if not @archived then
        @cmd.save_stdout("#{base_file_name}_stdout")
        @cmd.save_stderr("#{base_file_name}_stderr")
        @archived = true
      end
    end
  end
        
end
end
