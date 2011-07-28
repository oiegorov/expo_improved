require 'rubygems'
require 'pp'
require 'restfully'
require 'g5k_parallel'
require 'thread'

# default options of an experiment.
# can be modified in g5k_init() from an experiment specification file
#
# g5k_init (
#   :site => "grenoble",
#   :resources => "nodes=1"
#   )
@options = {
  :restfully_config => File.expand_path(
    ENV['RESTFULLY_CONFIG'] || "~/.restfully/api.grid5000.fr.yml"
  ),
  :logger => Logger.new(STDERR),
  :site => "lille",
  :resources => "nodes=1",
  :environment => "lenny-x64-base",
  :types => ["allow_classic_ssh"],
  :name => "to_try",
  :walltime => 300,
  :no_deploy => false,
  :no_submit => false,
  :no_cleanup => false,
  :polling_frequency => 10,
  :submission_timeout => 5*60 #time we wait till state of the job is 'running'
}


def g5k_init(experim_params)
  # make logger easier to access
  @logger = @options[:logger]
  
  # DO WE NEED IT???
  @nodes = []

  @resources = {}

  @jobs = []
  @mutex = Mutex.new

  experim_params.each { |attribute, value|
    @options[attribute.to_sym] = value
  }
end

def g5k_run

  # where to reserve?
  if ["all", "any"].include?(@options[:site].to_s)
    status = how_many?
    @logger.info "Status=#{status.inspect}"
    case @options[:site].to_s
    when "all"
      @sites = status.keys
    when "any"
      @sites = [status.sort_by{|k,v| v}.last[0]]
    end
  else
    @sites = [@options[:site]].flatten
  end

  @options[:parallel_reserve] = parallel

  # launch parallel reservations on all the @options[:site]
  @sites.each do |uid|
    @options[:parallel_reserve].add(@options.merge(:site => uid)) do |env|
      g5k_reserve(env)
    end
  end

  @options[:parallel_reserve].loop!
 
  #puts "\n\nnew resources: " 
  #pp @resources


  #puts "all the resources (ready to be converted to $all)"
  #pp @resources
  #
  # We call the method from module Expo
  Expo.extract_resources_new(@resources)

end

# reserve the remote nodes with parameters specified in @options
def g5k_reserve(options)

  logger = @logger

  # payload is a hash contatining all the params of the job to submit
  payload = {
    :command => "sleep #{@options[:walltime]}"
    #:command => "sleep 1"
    #:command => "uname -a"
  }.merge(options.reject { |k,v| !valid_job_key?(k) }) #sort out valid payload
  
  payload[:resources] = [
    options[:resources], "walltime=#{oar_walltime(options)}"
  ].join(",")

  # job submission
  job = synchronize {
    @connection.root.sites[options[:site].to_sym].jobs.submit(payload)
  }


  if job.nil?
    if options[:no_submit]
      options[:no_submit] = false
      # if a new job has to be submitted,
      # a new deployment must also be submitted
      options[:no_deploy] = false
      g5k_reserve(options)
    else
      logger.error "[#{options[:site]}] Cannot get a job"
      nil
    end
  else
    sleep 1
    job.reload
    synchronize { @jobs.push(job) }
    logger.info "[#{options[:site]}] Got the following job: #{job.inspect}"
    logger.info "[#{options[:site]}] Waiting for state=running for job ##{job['uid']} (expected start time=\"#{Time.at(job['scheduled_at']) rescue "unknown"}\")..."

      Timeout.timeout(@options[:submission_timeout]) do
        while job.reload['state'] != 'running'
          # while testing jobs can be really quick, like "uname" or "ls"
          # so we have to check if at the moment it is already finished
          if job.reload['state'] == 'terminated'
            puts "hehe, your job was so quick!"
            break
          end
          sleep options[:polling_frequency]
        end
      end

    logger.info "[#{options[:site]}] Job is running: #{job.inspect}"

    # DO WE NEED THIS??
    synchronize {
      job['assigned_nodes'].each {|node|
          @nodes.push(node)
      }
    }
    # 

    subhash = convert_to_resource(job, options[:site])
    synchronize {
      @resources.merge!(subhash)
    }
  end

end

def convert_to_resource(job, site)

  #gateway = "frontend."+site+".grid5000.fr"
  
  job_name = job['name']
  job_nodes = job['assigned_nodes']
  # job_id will be the same for all the clusters of one site
  job_id = job['uid']

  clusters = []

  regexp = /(\w*)-\w*/
  job_nodes.each { |node|
    cl = regexp.match(node)
    clusters.push(cl[1])
  }

  clusters.uniq!

  # will contain hash like
  # {
  #   "paradent" => {
  #     345212 => {
  #       "name" => "job_name",
  #       "nodes" => [ "paradent-1", "paradent-12"
  #     }
  #   }
  #   "parapluie" => {
  #     345212 => ...
  clusters_hash = {} 

  clusters.each { |cluster|
    #first sub-hash 
    uid_hash = {}
    #second sub-hash
    nodes_hash = {}

    nodes_hash["name"] = job_name 
    #nodes_hash["gateway"] = gateway 

    job_nodes.each { |node|

      #sort out the cluster to which this node belongs
      if node =~ /#{cluster}\w*/

        #if there are already nodes in this cluster - add in array
        if nodes_hash.has_key?("nodes")
          #nodes_array = [ nodes_hash["nodes"] ]
          nodes_hash["nodes"].push(node)

        #if this node is the first in this cluster - create an array
        #of nodes with this node and add the array to hash
        else
          nodes_array = []
          nodes_array.push(node)
          nodes_hash["nodes"] = nodes_array
        end 
      end 
    }

    uid_hash[job_id] = nodes_hash
    if !(clusters_hash.has_key?(cluster))
      clusters_hash[cluster] = uid_hash
    end 

  }
   
  clusters_hash
end

# convert the walltime in seconds into oar-style walltime
# 
def oar_walltime(env)
  walltime = env[:walltime]
  hours = (walltime/3600).floor
  minutes = ((walltime-(hours*3600))/60).floor
  seconds = walltime-hours*3600-minutes*60
  "%02d:%02d:%02d" % [hours, minutes, seconds]
end 


# Used to filter out keys from environment hash when submitting a job.
# @return [Boolean] true if <tt>k</tt> is a valid deployment attribute. 
# 
def valid_job_key?(k)                                                                                                                 
  [:resources, :reservation, :command, :directory, :properties, :types, :queue, :name, :project, :notifications].include?(k)
end

# Primite that returns a new Parallel object.  <tt>Parallel#loop!</tt>
# must be explicitly called to wait for the threads within the
# <tt>Parallel</tt> object.
# 
# @param [Hash] options a hash of additional options to pass.
# 
# If option <tt>:ignore_thread_exceptions</tt> is given and true, then
# standard exceptions (including timeouts) that occur in one of the
# threads will be ignored (only an error log will be displayed). This is
# useful if you are doing multi-site campaigns.
#
def parallel(options = {}, &block)
  p = Parallel.new({:logger => @logger}.merge(options))
  yield p if block_given?
  p
end
  
# Synchronization method
#
def synchronize(&block)
  @mutex.synchronize(&block)
end

# Returns the number of nodes that correspond to the specified state criteria, for each site requested.
# @param [Hash] options the options to filter the result with.
# @option options [String,Array] :hard (:alive) a symbol or array of symbols specifying the hardware status(es) that must be matched by the nodes to be counted.
# @option options [String,Array] :soft ([:free, :besteffort]) a symbol or array of symbols specifying the system status(es) that must be matched by the nodes to be counted.
# @option options [String,Array] :in (all) a symbol or array of symbols specifying the sites of interest.
#
# @example How many nodes are alive && (free || besteffort) in rennes and nancy?
#   how_many?(:hard => :alive, :soft => [:free, :besteffort], :in => [:rennes, :nancy]) # => {:rennes => 40, :nancy => 23}
#
def how_many?(options = {})
  options = {:hard => :alive, :soft => [:free, :besteffort]}.merge(options)
  count = {}

  sites = [options[:in]].flatten.compact.map(&:to_s)
  hard_state = [options[:hard]].flatten.compact.map(&:to_s)
  soft_state = [options[:soft]].flatten.compact.map(&:to_s)

  @connection.root.sites.each do |site|
    next if !sites.empty? && !sites.include?(site['uid'])
    count[site['uid'].to_sym] = site.status.count do |ns|
      hard_state.include?(ns['hardware_state']) &&
      soft_state.include?(ns['system_state'])
    end
  end

  count
end


if File.exist?(@options[:restfully_config]) && 
    File.readable?(@options[:restfully_config]) &&
    File.file?(@options[:restfully_config])

  @connection = Restfully::Session.new( 
    :configuration_file => @options.delete(:restfully_config)
  )   

else
  STDERR.puts "Restfully configuration file cannot be loaded:
  #{@options[:restfully_config].inspect} does not exist or cannot be
  read or is not a file" 
  exit(1)
end

module Expo

# put reserved resources into expo's $all ResourceSet
#
def self.extract_resources_new(result)
    result.each { |key,value|
      # { "cluster" => {...} }
      cluster = key
      value.each { |key,value|
        # { "job_id" => {...} }
        jobid = key
        resource_set = ResourceSet::new
        resource_set.properties[:id] = jobid
        resource_set.properties[:alias] = cluster

        value.each { |key,value|
          # { "name" => "...", "gateway" => "...", "nodes" => "...", 
          case key
          when "name"
            resource_set.name = value
          #when "gateway"
          #  resource_set.properties[:gateway] = value
          when "nodes"
            value.each { |node|
              resource = Resource::new(:node, nil, node)
              # here we must construct gateway's name in place
              gw = /\w*\.(\w+)\.\w*/.match(node) 
              gateway = "frontend."+gw[1]+".grid5000.fr"
              resource.properties[:gateway] = gateway
              resource_set.properties[:gateway] = gateway
              resource_set.push(resource)
            }
          end
        }
        #----so we put in $all a hash of all reserved nodes (in all
        #----clusters)
        $all.push(resource_set)
      }
    }
end 

end # Expo

