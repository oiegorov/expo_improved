#!/usr/bin/env ruby
require 'karo'

class Karo
#the effective steps to execute
	def phase0(rset,*params)
		puts "phase0 !do nothing"
	end

	def phase1(rset,*params)
		puts "phase1 !"
		r = ptask "uname -a", rset
		p r.cmd_result
	end

	def phase2(rset,*params)
		puts "phase2 !"
		result = ptaskfoorand "foo", rset
		return result
	end

	def phase3(rset,*params)
		puts "phase3 !"
		result = ptaskfoorand "foo", rset
		return result
	end

	def error_yop(rset,*params)
			puts "error"
			r = Result.new
	 		r.rset_bad = rset
			r
	end

end


##
## history_watcher
## Define an optional call back function triggered after each step execution
## Can be use to follow the all automaton's execution process 
##
class History
	def history_watcher
		@logger.log("***** Number of results: #{@trace.length}")
	end
end

puts "\n** Instantiate Automaton **\n\n"
##
## Automaton's description
##

automaton = Karo.new do
	step :multiphase
	step :phase3, :nb_retry => 1

	#composed step
	multiphase do
  	step :phase1
		step :phase2, :on_error => :error_yop 
	end
end


#create a resource set
rset = ResourceSet::new()
rset.properties[:history] = []
#add some resources
rset.push(Resource.new(:node,:name => 'localhost'))
rset.push(Resource.new(:node,:name => 'B'))
rset.push(Resource.new(:node,:name => 'C'))

##
## Launch the automaton
##
puts "** Lanuch Automaton**"
puts "*********************"
automaton.launch(rset)
puts "*********************"

#display final good and bad resources
automaton.display_results

#puts "\n** Generatte Automaton's Diagram **\n\n"
#generate a dot file of automaton (/tmp/karo.svg)
#automaton.dot

#WILL generate a dot file of execution's graph (/tmp/karo_history.svg)
automaton.history.dot

