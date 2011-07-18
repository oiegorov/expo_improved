#!/usr/bin/ruby

[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }

require 'optparse'
require 'drb'
require 'soap/rpc/standaloneServer'
require 'soap/marshal'

require 'rctrl/rctrl_service'

include Expo

class RCtrlServerSoapDriver < SOAP::RPC::StandaloneServer
  include SOAP::Mapping
  def initialize(service,namespace,address,port,archive_level=nil,archive_path=nil)
    super(service,namespace,address,port)
    servant = RCtrlService::new(archive_level,archive_path)
    add_servant(servant, namespace)
    self.mapping_registry = Registry.new
  end
end

#A remote control server that can be included in a script or run as a stand alone program
class RCtrlServerDrbDriver
    def initialize(service,address,port,archive_level=nil,archive_path=nil)
	@address = address
	@port = port
        @servant = RCtrlService::new(archive_level,archive_path)
    end
    def shutdown
	exit
    end
    def start
 	DRb.start_service("druby://#{@address}:#{@port}", @servant)
	DRb.thread.join 
    end
end

class RCtrlServerXMLRPCDriver
	def initialize(service,address,port,archive_level=nil,archive_path=nil)
		@address = address
		@port = port
                @servant = RCtrlService::new(archive_level,archive_path)
		puts "Not Yet Implemented"
		exit
  end
end

class RCtrlServer
 
	def initialize(service,namespace,address,port,archive_level=nil,archive_path=nil)
		if $RMI == 'soap'
			@rctrl_server = RCtrlServerSoapDriver.new(service,namespace,address,port,archive_level,archive_path)
		elsif $RMI == 'xmlrpc'
			@rctrl_server = RCtrlServerXMLRPCDriver.new(service,address,port,archive_level,archive_path)
		else
			$RMI = 'drb'
			@rctrl_server = RCtrlServerDrbDriver.new(service,address,port,archive_level,archive_path)
		end
	end

	def method_missing(method_id, *args)
		response = @rctrl_server.send method_id, *args
		return response
	end
 
end

if $0 == __FILE__
  port = 15783
  archive_level = 0
  archive_directory = nil
  #ssl = false
  opts = OptionParser.new
  opts.on("-p","--port VAL", Integer) {|val| port = val }
  opts.on("-a","--archive_level VAL", Integer) {|val| archive_level = val }
  opts.on("-d","--archive_directory VAL", String) {|val| archive_directory = val }
  opts.on("-r","--rmi_protocol VAL", String) {|val| $RMI = val }

  #opts.on("-s","--ssl", Integer) { ssl = true }
  opts.parse(ARGV)
  server = RCtrlServer.new('rctrl', NS, '0.0.0.0', port, archive_level, archive_directory)
  trap(:INT) do 
    server.shutdown
  end
  server.start
end

 
