require 'resourceset'
require 'expolib'

module Expo

class GenericTask
        attr_accessor :type, :properties
        def initialize( type, properties=nil, name=nil )
                @type = type
                @properties = Hash::new
                if properties then
                        @properties.replace(properties)
                end
                if name then
                        @properties[:name] = name
                end
        end

        def name
                return @properties[:name]
        end

        def name=(name)
                @properties[:name] = name
                return self
        end

        def to_s
                return @properties[:name]
        end

        def corresponds( props )
                props.each_pair { |key,value|
                        if value.kind_of?(Proc) then
                                return false if not value.call(@properties[key])
                        else
                                return false if ( @properties[key] != value )
                        end
                }
                return true
        end

        def ==( res )
                @type == res.type and @properties == res.properties
        end

        def eql?( res )
                if self.class == res.class and @type == res.type then
			@properties.each_pair { |key,value|
				return false if res.properties[key] != value
			}
			return true
		else
			return false
		end
        end

end

class Task < GenericTask
        attr_accessor :command, :resources
        def initialize( command = nil, resources = nil, name = nil )
                super( :task, nil, name)
                @command = command
                @resources = resources
        end

        def execute
                cmd = "taktuk2yaml -s"
                cmd += $ssh_connector
                cmd += @resources.make_taktuk_command(self.command)
                command_result = $client.asynchronous_command(cmd)
                $client.command_wait(command_result["command_number"],1)
                return make_taktuk_result(command_result["command_number"])
        end

	def make_taktuk_command
		return @resources.make_taktuk_command(self.command)
	end
end

class TaskSet < GenericTask
        attr_accessor :tasks
        def initialize( name = nil )
                super( :task_set, nil, name )
                @tasks = Array::new
        end

        def push( task )
                @tasks.push( task )
		return self
        end

        def execute
                cmd = "taktuk2yaml -s"
                cmd += $ssh_connector
                @tasks.each { |t|
                        cmd += t.make_taktuk_command
                }
                command_result = $client.asynchronous_command(cmd)
                $client.command_wait(command_result["command_number"],1)
                return make_taktuk_result(command_result["command_number"])
        end

	def make_taktuk_command
		cmd = ""
		@tasks.each { |t|
		        cmd += t.make_taktuk_command
		}
		return cmd
	end
end

class TaskStream < GenericTask
        attr_accessor :tasks
        def initialize( name = nil )
                super( :task_stream, nil, name )
                @tasks = Array::new
        end

        def push( task )
                @tasks.push( task )
		return self
        end

        def execute
		results = Array::new
                @tasks.each { |t|
                        results.push(t.execute)
                }
		return results
        end
end

end
