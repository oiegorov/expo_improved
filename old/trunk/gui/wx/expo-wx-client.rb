require 'xmlrpc/client'
require 'yaml'

CONFIG_FILE = 'expe.yaml'

$expe_list = {}
Struct.new("Experiment", :id, :description, :file, :options, :program, :nb_lines, :state, :action_list, :active_actions, :view, :start, :duration, :gauge)

# Actions and list of them are used to monitor experiment activity
#Struct.new("Action",:id,:type,:progress,:state,:line)
#Struct not use for actions plain array used indeed to limit size of all actions
#index of field
A_ID = 0
A_TYPE = 1
A_PROGRESS = 2
A_STATE = 3
A_LINE = 4

# State for action (like task or expe)
RUNNING = 'R'
TERMINATED = 'T'
TERMINATING = 't'
ERROR = 'E'
LOADED = 'L'

### ????
A_MASK = nil #TODO TOFIX !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
A_MARKER = {RUNNING => MARKER_RUNNING, TERMINATING => MARKER_RUNNING, TERMINATED => MARKER_TERMINATED, ERROR => MARKER_ERROR}


class ExpoClient
	attr_accessor :gui
	@monitor_flag = false

	def initialize(server='localhost',port='2001')
		puts "Connecting to #{server}:#{port}"
		begin
			@expo_server = XMLRPC::Client.new(server, "/expo", port)
		rescue
			puts $!
		end
		p  @expo_server
		response = ""
		begin
			response = @expo_server.call("hello",'yop')
		rescue
			puts $!
		end
		puts "Connected"
		puts "Hello: response: #{response}"
	end

	def load_initial_experiment(config_file=CONFIG_FILE)
		conf = YAML.load(File.open(config_file))

		p conf

		first_expe = ''
		conf['experiments'].each_with_index do |expe_info,i|
			p expe_info
			expe_id = expe_info['name']

			description = '' 
			description = expe_info['desc'] if !expe_info['desc'].nil?

			options = nil
			options = expe_info['options'] if !expe_info['options'].nil?

			first_expe = expe_id if i ==0
			if !$expe_list[expe_id].nil?
				puts "Error experiment_id #{expe_id} already exists"
				exit 1
			end

			if !expe_info['file']
				#TODO
				puts "Error expe without file TODO"

			else
				file = expe_info['file']
				program = @expo_server.call("load_experiment",{'expe_id'=>expe_id,'expe_file'=>file})
#				program = IO::read("kastafior.rb")
				view = ExpeView.new(@gui,expe_id,program)
				$expe_list[expe_id] = Struct::Experiment.new(expe_id,description,file,options,program,program.split(/\n/).length,LOADED,view.task_list.action_list,[0],view,0,0,0)
			end
			#show first expe
			$expe_list[first_expe].view.show
		end
	end


	def start
		monitor
	end

  #DEPRECATED
	def load_experiment(expe_id,file,wx_stc, wx_list_crtl)
		program = @expo_server.call("load_experiment",{'expe_id'=>expe_id,'expe_file'=>file})
		$expe_list[expe_id] = Struct::Experiment.new(expe_id,file,program,LOADED,wx_list_ctrl.action_list,[0],wx_stc,wx_list_ctrl)
		
		return program
	end

	def launch_experiment(expe_id)
		puts "Launching expe"

		expe_args = {}
		expe_args['expe_id'] = expe_id
		expe_args['options'] = $expe_list[expe_id]['options'] if !$expe_list[expe_id]['options'].nil?

		puts @expo_server.call("launch_experiment",expe_args)
		$expe_list[expe_id].state = RUNNING
#		monitor if !@monitor_flag
	end

	def run(expe_id)
		
		if $expe_list[expe_id].state != LOADED
			puts "SORRY RERUN NOT YET IMPLEMENTED"
		else
	  	launch_experiment(expe_id)
			$expe_list[expe_id].state = RUNNING
			$expe_list[expe_id].start = Time.now
		end
	end

	def stop(expe_id)
	end
	
	def kill(expe_id)
	end
	
	def monitor
		Thread.new do
			loop do
				sleep 2 
				puts "Monitor Experience"

				@gui.expe_ctrl_view.update_expe_state

				$expe_list.each do |expe_id,expe|
					if expe.state == RUNNING
#						res_actions_status =	@expo_server.call("fifo_generic_cmd_expo", {'expe_id'=>expe.id,'cmd'=>'get_action_status','args'=>expe.active_actions})
						puts "monitor Experience: #{expe.id}"
						res_actions_status =	@expo_server.call("monitor_experiment", {'expe_id'=>expe.id,'cmd'=>'get_action_status','args'=>expe.active_actions})
						p res_actions_status					

						expe.state = TERMINATING if res_actions_status['err'] == 'NOFIFO'

#						if res_actions_status['err'] == 'NOFIFO'
#							 expe.state = TERMINATING
#						else

						actions_status = res_actions_status['res']
						if !actions_status.nil? 
							expe.active_actions = []
					 		actions_status.each do |action|
								puts "action"
								p action 
								#TODO How to detect expe termination !!!!
							
								if action.length > 0	
									if  expe.action_list[action[0]].nil? || (expe.action_list[action[0]][3] != action[0])
										expe.action_list[action[0]] = action	
										#update (GUI)
										#stc (expe_program)
										#TODO
										expe.view.expe_program.marker_delete_all(action[A_LINE]-1)

										puts "Add marker #{action[A_LINE]-1}"
	
										expe.view.expe_program.marker_add(action[A_LINE]-1,A_MARKER[action[A_STATE]])
										#listctrl (task_list)
										expe.view.task_list.refresh_item(action[A_ID])
									end
									expe.active_actions << action[A_ID] if action[A_STATE] != (TERMINATED||ERROR) 
								else
									puts "WARNING action is void"
								end
							end 
						#ensure_display last active action
							expe.view.task_list.ensure_visible(expe.action_list.last[A_ID]) if expe.action_list.length > 0 
							expe.view.expe_stdeo.append_text(res_actions_status['stdout'])
							expe.view.expe_stdeo.append_text(res_actions_status['stderr'])

							puts "stdout/err"
							puts res_actions_status['stdout']
							puts res_actions_status['stderr']
							puts '---------------------------------------------------------'

						end

					elsif expe.state == TERMINATING
						res_actions_status =	@expo_server.call("monitor_experiment", {'expe_id'=>expe.id,'cmd'=>'get_std_eo','args'=>''})
						expe.view.expe_stdeo.append_text(res_actions_status['stdout'])
						expe.view.expe_stdeo.append_text(res_actions_status['stderr'])

						puts "stdout/err"
						puts res_actions_status['stdout']
						puts res_actions_status['stderr']
						puts 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
						expe.state = TERMINATED
					end
				end
			end
		end

	end

end
