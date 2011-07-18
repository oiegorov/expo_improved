##
# BE CAREFULL upto now automaton instantiation and execution can't be mixed !!! (so, first instanciate all automata).
# We CANNOT instantiate automaton concurrently
#	Reasons:
# * method_missing manipulations/methods different between  automaton instantiation and execution
# * some global variables (like $current.caro) doesn't allow concurrent instanciation, need global mutex
#
# Concurent execution of different automaton must be possible

#
# Step:
#  :nb_retry => x step will be executed x times on bad resources before to execute erro step (default is 0)	
#  :on_error => :method  method to execute for bad resources (defaut is error, a default error is provide, it does nothing)
#



# 
# Resource set properties:
#  * :history => array of results

require 'resourceset'
require 'thread'
require 'monitor'
require 'expo-karo'

$current_karo = nil

# A class logger for to log automoton, one logger per automoton
# Logger will be able to generate graph diagram of execution (history dot) 
class Logger
	def log(str)
		puts(str)
	end
end

#
# Result of step execution
#
class Result
	attr_accessor :rset, :step, :rset_good, :rset_bad, :step_occurence, :cmd_result
	def initialize(rset=nil,step=nil)
		@rset = rset
		@step = step
	end
end

class Step
	attr_accessor :name, :options, :nextstep, :nb_retry, :on_error, :parent_composedstep
	def initialize(name,options=nil)
		@name = name
		if !options.nil?
		if !options[:nb_retry].nil?
			@nb_retry = options[:nb_retry]
			options.delete(:nb_retry)
		end
		if !options[:on_error].nil?
			@on_error = options[:on_error]
			options.delete(:on_error)
		end
		end
		@options = options
	end
end

class Steps < Hash
	attr_accessor :initial_step, :composedstep
	def initialize
		@initial_step = nil
		@composedstep = Hash.new
	end

	def dot(file="/tmp/karo.svg")
		puts "generate #{file}"
		@dot = "digraph G {\n"
		frontier_edges = ""
		step = self[@initial_step]
		
		while step.nextstep != nil
			name = step.name		
			if step.class == Step
				if step.parent_composedstep !=  self[step.nextstep].parent_composedstep
					frontier_edges << "#{name} -> #{step.nextstep}\n"
					@dot << "}\n"
				else
					@dot << "#{name} -> #{step.nextstep}\n"
				end
			else #it's and ComposedStep
				@dot <<  "subgraph cluster_#{name} { \n label = \"#{name}\" \n"
			end
			step = self[step.nextstep]
		end
		@dot << frontier_edges << '}'
		puts @dot
		system("echo \"#{@dot}\" | dot -Tsvg -o #{file}")
	end
end

class History
		
	def initialize(logger)
		self.extend(MonitorMixin)
		@trace= [] #keep result of each steps' execution
		@logger = logger #to have access to logger (usefull for history watcher callback)
	  @step_occurence = {} #to trace the number of execution for each step
	end

	def history_watcher
	end

	def <<(result)
		synchronize do
			if @step_occurence[result.step].nil?
				@step_occurence[result.step] = 1
			else
				@step_occurence[result.step] += 1
			end
			result.step_occurence =	@step_occurence[result.step]  
			@trace << result
			history_watcher
		end
	end

	def display
		@trace.each do |r|
			puts r.step, " ", r.rset.object_id," ",  r.rset_good.object_id," ",  r.rset_bad.object_id
		end
	end

	def dot(file="/tmp/karo_history.svg")
		puts "generate #{file}"
		@dot = "digraph G {\n"

		@trace.each_with_index do |result,i|
			next if i==0
			rset = result.rset
			matching_result = nil
			arc_label = nil
			@trace[0..i-1].reverse_each do |r|
				if rset.object_id  == r.rset_good.object_id 
					matching_result = r
					break
				end
				if rset.object_id  == r.rset_bad.object_id 
					matching_result = r
					arc_label = "bad"
					break
				end
			end

			step_src = "#{matching_result.step}_#{matching_result.step_occurence }"
			step_dst = "#{result.step}_#{result.step_occurence}"

			if arc_label.nil?
				@dot << "#{step_src} -> #{step_dst}\n"
			else
				@dot << "#{step_src} -> #{step_dst} [label= \"#{arc_label}\"]\n"
			end
		end
		@dot << '}'
		#puts @dot
		system("echo \"#{@dot}\" | dot -Tsvg -o #{file}")
	end

end

class ComposedStep
	attr_accessor :name, :nextstep, :parent_composedstep, :next_outstep 
	def initialize(name)
		@name = name
	end
end

def step(name,options=nil)
	$current_karo.step(name,options)
end


#aliasing to allow original method_missing retreiving when necessary
alias orignal_method_missing method_missing

# method_missing to address composedstep instantiation
def method_missing(method_sym,&block)

	puts method_sym
	#TODO test if method_sym is present as nextstep in the list of already registered steps
	$current_karo.composedstep(method_sym,block)
end

alias automaton_creation_method_missing method_missing


class ThreadsCounter < Monitor
	def initialize
		@count = 0
		super
		@cond_var = self.new_cond
	end
	def increment
		synchronize do
			@count += 1
		end
	end
	def decrement
		synchronize do
			@count -= 1
			@cond_var.signal
		end
	end
	def wait_zero
		synchronize do
			@cond_var.wait_while do
					@count > 0
			end
		end
	end	
end


class Karo
	attr_reader :history, :steps 
	def initialize

		#NOT USE UPTO NOW all resource_set are accessible via History
		@resource_sets = {} # keep all generated and used resource sets during execution
		@resource_sets.extend(MonitorMixin) #add monitor and synchronize method

		@error_steps = {} #list of error steps		

		@final_results = [] # keep all final results (to acces final good/bad ressources)
		@final_results.extend(MonitorMixin) #add monitor and synchronize method

		@logger = Logger.new
		@history = History.new(@logger) # history of execution = array of steps' result
		@nb_active_threads = ThreadsCounter.new #to counting and waiting number of active threads which execute concurrent execution paths
		@previous_step = nil
		@initial_step = nil
			@steps = Steps.new  
		$current_karo = self
		@current_parent_composedstep = [nil]
		alias method_missing automaton_creation_method_missing

		#create default error step
		@steps[:error] = Step.new(:error)
		@error_steps[:error] = true
		yield
	end

	def step(name, options=nil)
		@logger.log("register step: #{name}")
		@logger.log("option(s) of #{name} step: #{options}") if !options.nil?

		step = Step.new(name,options)
		@steps[name] = step
		@steps.initial_step = name if @steps.initial_step.nil?
		@steps[@previous_step].nextstep = name if !@previous_step.nil?
		@previous_step = name
		step.parent_composedstep = @current_parent_composedstep.last

		#create specific on_error step if needed
		if !step.on_error.nil?
			@steps[step.on_error] = Step.new(step.on_error,nil) if @steps[step.on_error].nil?
			#register it in error steps list
			@error_steps[step.on_error] = true
		end
	end

	def composedstep(name,block)
		@logger.log("register composedstep: #{name}")
		composedstep = ComposedStep.new(name)
		@steps.initial_step = name if @steps.initial_step.nil?
		@previous_step = name
		#TODO: get parent_composedstep ???
		if !@steps[name].nil?
			composedstep.next_outstep = @steps[name].nextstep
			@steps.delete(name)
		end
		@steps[name] = composedstep
		composedstep.parent_composedstep = @current_parent_composedstep.last
	  @current_parent_composedstep << name
		block.call(self)
		@current_parent_composedstep.delete(name)
		@steps[@previous_step].nextstep = composedstep.next_outstep
	end

	def launch(rset)
		alias method_missing orignal_method_missing
		step = @steps.initial_step
		@logger.log("runing #{step}")
		#go
		run(step,rset)
		#wait the end of all active threads
		@nb_active_threads.wait_zero
		#return the list of terminal ressource_sets (good and bad)
		
	end

	def run(step,rset)

		while !step.nil?
			@logger.log("execute step: #{step}")
			@logger.log("Next step is: #{@steps[step].nextstep}")

			if @steps[step].class == Step
					
				result = self.send(step,rset,@steps[step])

				if result.nil?
					result = Result.new(rset, step)
					result.rset_good = rset
				end

				result.step = step if result.step.nil?

				@logger.log("executed step: #{step}")
			
				@history << result
				rset.properties[:history] << result
				
				if @error_steps[result.step]
					@logger.log("Error step executed: #{result.step}")
 

				elsif !result.rset_bad.nil?
					result.rset_bad.properties[:history] << result
						
					#TODO determine the error_step accordingly to nb_retry, on_error, an rest_bad.properties[:history]
					error_step = :error
					error_step = @steps[step].on_error if !@steps[step].on_error.nil?
			
					if !@steps[step].nb_retry.nil?
						i = 0 
						rset.properties[:history].reverse_each do |r|
							if r.step == step
								i += 1
							else
								break
							end
						end
							if i <= @steps[step].nb_retry
#							puts "retry #{step}"
							error_step = step
						end	
					end

					@nb_active_threads.increment
#					puts "we fork"
					Thread.new(error_step,result.rset_bad) do |e_step,rset_b|
						run(e_step,rset_b)
						@nb_active_threads.decrement
					end

					if !result.rset_good.nil?
#						puts "we continue #{step} next_step:#{@steps[step].nextstep}"
						result.rset_good.properties[:history] << result
						rset = result.rset_good
				
					else
						@logger.log("no good ressources after executing step:#{step}")
						step = nil #to stop this path processing
					end
				end
		
			elsif @steps[step].class == ComposedStep
				@logger.log("enter a composed step: #{step}")
			else
				@logger.log("Warning unknown what do to with step: #{step} class: #{@steps[step].class}")
			end
			#go to the next step
			step = @steps[step].nextstep
			#no more step, save previous result as part of final results
			if step.nil?
				@final_results.synchronize do
					@final_results << result
				end
			end
		end
		@logger.log("no more step to execute")
	end

	def display_results
		puts
		puts "Good resources"
		puts "--------------"

		@final_results.each do |result|
			if !result.rset_good.nil?
				puts "#{result.step} occurence #{result.step_occurence}" if result.rset_good.resources.length > 0
				result.rset_good.each(:node) do |r|
					p r 
				end
			end
		end
		puts "Bad resources"
		puts "-------------"
		@final_results.each do |result|
			if !result.rset_bad.nil? && @error_steps[result.step]
				puts "#{result.step} occurence #{result.step_occurence}" if result.rset_bad.resources.length > 0
				result.rset_bad.each(:node) do |r|
					p r 
				end
			end
		end
	end

	def dot
		@steps.dot
	end

	# default error step
	def error(rset,*params)
		@logger.log("default error step")
		r = Result.new
		r.rset_bad = rset
		return r
	end

end
