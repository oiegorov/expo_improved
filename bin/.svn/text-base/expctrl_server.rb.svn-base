#!/usr/bin/ruby

[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }

require 'optparse'
require 'drb'
require 'soap/rpc/standaloneServer'
require 'soap/marshal'
require 'expctrl/expctrl_service'
require 'yaml'
include SOAP::Mapping

include Expo

class ExpCtrlServerSoapDriver < SOAP::RPC::StandaloneServer
  def initialize(service,namespace,address,port,archive_level=nil,archive_path=nil)
    super(service,namespace,address,port)
    servant = ExpCtrlService::new(archive_level,archive_path)
    add_servant(servant, namespace)
    self.mapping_registry = Registry.new
  end
end

#A remote control server that can be included in a script or run as a stand alone program
class ExpCtrlServerDrbDriver
    def initialize(service,address,port,archive_level=nil,archive_path=nil)
        @address = address
        @port = port
        @servant = ExpCtrlService::new(archive_level,archive_path)
    end
    def shutdown
        exit
    end
    def start
        DRb.start_service("druby://#{@address}:#{@port}", @servant)
        DRb.thread.join 
    end
end

class ExpCtrlServerXMLRPCDriver
    def initialize(service,address,port,archive_level=nil,archive_path=nil)
        @address = address
        @port = port
        @servant = ExpCtrlService::new(archive_level,archive_path)
        puts "Not Yet Implemented"
        exit
    end
end


class ExpCtrlServer
	def initialize(service,namespace,address,port,archive_level=nil,archive_path=nil)
		if $RMI == 'soap'
			@rctrl_server = ExpCtrlServerSoapDriver.new(service,namespace,address,port,archive_level,archive_path)
		elsif $RMI == 'xmlrpc'
			@rctrl_server = ExpCtrlServerXMLRPCDriver.new(service,address,port,archive_level,archive_path)
		else
			$RMI = 'drb'
			@rctrl_server = ExpCtrlServerDrbDriver.new(service,address,port,archive_level,archive_path)
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

  if File.exist?("#{ENV['HOME']}/.expctrl_server") then
    config = YAML::load(File.open("#{ENV['HOME']}/.expctrl_server"))
    port = config['port'] if config['port']
    $RMI = config['rmi_protocol'] if config['rmi_protocol']
    $POLLING =  config['polling'] if config['polling']
  end

  #ssl = false
  opts = OptionParser.new
  opts.on("-p","--port VAL", Integer) {|val| port = val }
  opts.on("-a","--archive_level VAL", Integer) {|val| archive_level = val }
  opts.on("-d","--archive_directory VAL", String) {|val| archive_directory = val }
  opts.on("-r","--rmi_protocol VAL", String) {|val| $RMI = val }
  #opts.on("-s","--ssl", Integer) { ssl = true }
  opts.parse(ARGV)
  server = ExpCtrlServer.new('expctrl', NS, '0.0.0.0', port, archive_level, archive_directory)
  trap(:INT) do 
    server.shutdown
  end
  server.start
end

