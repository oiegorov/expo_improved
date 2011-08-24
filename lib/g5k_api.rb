require 'rubygems'
require 'pp'
require 'restfully'
require 'g5k_parallel'
require 'thread'

# default options of an experiment.
# can be modified in g5k_init() in your test file
#
# g5k_init (
#   :site => ["grenoble", "lille"],
#   :resources => ["nodes=1", "nodes=3"]
#   )
@options = {
  :restfully_config => File.expand_path(
    ENV['RESTFULLY_CONFIG'] || "~/.restfully/api.grid5000.fr.yml"
  ),
  :logger => Logger.new(STDERR),
  :site => "lille",
  :resources => "nodes=1",
  #:environment => {"lenny-x64-base" => 1},
  :types => ["allow_classic_ssh"], #should be overwritten by "deploy" in case of deployment
  :name => "to_try", #the name of experiment
  :walltime => 3600,
  :no_submit => false,
  #do we need it??
  :no_cleanup => false,
  #
  :polling_frequency => 10,
  :deployment_max_attempts => 1, # we will try to redeploy once if deployment fails
  :submission_timeout => 5*60, #time we wait till state of the job is 'running'
  :deployment_timeout => 15*60,
  :deployment_min_threshold => 100/100
}

# create a connection to Grid5000 API in Restfully way
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

# redefine the options of an experiment
def g5k_init(experim_params)
  # make logger easier to access
  @logger = @options[:logger]
  
  # DO WE NEED IT???
  @nodes = []

  @resources = {}

  @jobs = []
  @deployments = []
  @mutex = Mutex.new

  experim_params.each { |attribute, value|
    @options[attribute.to_sym] = value
  }

  if @options.has_key?(:environment)
    @options[:types].push("deploy")
  end
end

# run reservation and deployment
def g5k_run

  #------------RESERVATION STAGE--------------------------------
  # if :sites == "all" reserve on each site
  # if :sites == "any" - on the site w/ the biggest number of free nodes
  # otherwise reserve on the specified site(s)
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

  # to keep track how many resource on each site to reserve
  @res = [@options[:resources]].flatten

  @options[:parallel_reserve] = parallel

  # launch parallel reservations on all the @options[:site]
  for i in 1..@sites.length
    @options[:parallel_reserve].add(@options.merge(:site => @sites[i-1], :resources => @res[i-1])) do |env|
      g5k_reserve(env)
    end
  end

  # wait till all the reservations complete
  @options[:parallel_reserve].loop!


  #
  # construct $all ResourceSet
  Expo.extract_resources_new(@resources)

  #------------DEPLOYMENT STAGE--------------------------------
  if @options[:types].include?("deploy")

    # create the environment hash: {"environment_1" => ["node_1", ..], ...}
    env_hash = {}
    #all_copy = $all.copy
    all_2 = ResourceSet::new
    i = 0

    @options[:environment].each { |env, nodes_num|
      env_hash[env] = []
      nodes_num.times {
        
        all_check = $all.copy
        # find the node where env should be deployed and delete it
        $all.each { |node|
          if node.corresponds({:site => @options[:site][i]})
            $all.delete(node)
            node.properties[:environment] = env
            all_2.push(node)
            env_hash[env].push(node.properties[:name])
            break
          end
        }

        if all_check == $all        #nothing was deleted from $all
          # take the next site and find again
          i += 1 
          $all.each { |node|
            if node.corresponds({:site => @options[:site][i]})
              $all.delete(node)
              node.properties[:environment] = env
              all_2.push(node)
              env_hash[env].push(node.properties[:name])
              break
            end
          }
        end
      }
    }
    # each resource now has :environment property
    $all = all_2


    # launch parallel deployments for each environment
    @options[:parallel_deploy] = parallel

    # As API deploy the same environment on the same site in parallel, 
    # we submit deployments in
    # "environment_1" => [ .. all the nodes of the site ]
    # for each site

    @options[:site].each { |site|
      
      env_hash.each { |environment, nodes|
        
        @options[:environment] = environment
        # find all the reserved nodes from this site
        @options[:nodes] = nodes.find_all { |node|
          node =~ /\S*.#{site}.\w*/
        }

        if not @options[:nodes].empty?
          @options[:parallel_deploy].add(@options.merge(:site => site)) { |env|
            g5k_deploy(env)
          }
        end
      }
    }

    #wait for all the deployments to finish
    @options[:parallel_deploy].loop!
  end

end

# reserve the remote nodes with parameters specified in @options
def g5k_reserve(options)

  logger = @logger

  # payload is a hash contatining all the params of the job to submit
  payload = {
    :command => "sleep #{@options[:walltime]}"
  }.merge(options.reject { |k,v| !valid_job_key?(k) }) #sort out valid payload
  
  # convert resources to OAR style
  payload[:resources] = [
    options[:resources], "walltime=#{oar_walltime(options)}"
  ].join(",")

  # job submission (using Restfully gem)
  job = synchronize {
    @connection.root.sites[options[:site].to_sym].jobs.submit(payload)
  }


  if job.nil?
    logger.error "[#{options[:site]}] Cannot get a job"
    nil
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

    # to be able to convert later to $all ResourceSet
    subhash = convert_to_resource(job, options[:site])
    synchronize {
      @resources.merge!(subhash)
    }
  end

end

def g5k_deploy(env)

  logger = @logger

  env[:remaining_attempts] ||= env[:deployment_max_attempts]
  env[:nodes] = [env[:nodes]].flatten.sort
  logger.info "[#{env[:site]}] Launching deployment [no-deploy=#{env[:no_deploy].inspect}]..."


  if env[:remaining_attempts] > 0
    if env[:remaining_attempts] < env[:deployment_max_attempts]
      logger.info "Retrying deployment..."
    end
    env[:remaining_attempts] -= 1
    # environment deployment (using Restfully gem)
    deployment = @connection.root.sites[env[:site].to_sym].deployments.submit({
      :nodes => env[:nodes],
      :notifications => env[:notifications],
      :environment => env[:environment],
      :key => key_for_deployment(env)
    }.merge(env.reject{ |k,v| !valid_deployment_key?(k) }))
  else
    logger.info "[#{env[:site]}] Hit the maximum number of retries. Halting."
    deployment = nil
  end

  if deployment.nil?
    logger.error "[#{env[:site]}] Cannot submit the deployment."
    nil
  else
    deployment.reload
    synchronize { @deployments.push(deployment) }

    logger.info "[#{env[:site]}] Got the following deployment: #{deployment.inspect}"
    logger.info "[#{env[:site]}] Waiting for termination of deployment ##{deployment['uid']} in #{deployment.parent['uid']}..."

      Timeout.timeout(env[:deployment_timeout]) do
        while deployment.reload['status'] == 'processing'
          sleep env[:polling_frequency]
        end
      end

    if deployment_ok?(deployment, env)
      logger.info "[#{env[:site]}] Deployment is terminated: #{deployment.inspect}"
      env[:deployment] = deployment
      yield env if block_given?
      env
    else
      synchronize { @deployments.delete(deployment) }
      logger.error "[#{env[:site]}] Deployment failed: #{deployment.inspect}"
      g5k_deploy(env)
    end
  end
end

#-------------------- Helper routines ----------------------------------
#

# Creating 'resources' from the assigned nodes to put them after into
# $all ResourceSet
def convert_to_resource(job, site)

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

    job_nodes.each { |node|

      #find out the cluster to which this node belongs
      if node =~ /#{cluster}\w*/

        #if there are already nodes in this cluster - add in array
        if nodes_hash.has_key?("nodes")
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

# Used to filter out keys from environment hash when submitting a deployment.
# @return [Boolean] true if <tt>k</tt> is a valid deployment attribute. Otherwise false.
#
def valid_deployment_key?(k)
  [:key, :environment, :notifications, :nodes, :version, :block_device, :partition_number, :vlan, :reformat_tmp, :disable_disk_partitioning, :disable_bootloader_install, :ignore_nodes_deploying].include?(k)
end

# Returns true if the deployment is not in an error state
# AND the number of correctly deployed nodes is greater or
# equal than <tt>env[:deployment_min_threshold]</tt> variable
#
def deployment_ok?(deployment, env = {})
  return false if deployment.nil?
  return false if ["canceled", "error"].include? deployment['status']
  nodes_ok = deployment['result'].values.count{|v|
    v['state'] == 'OK'
  } rescue 0
  nodes_ok.to_f/deployment['nodes'].length >= env[:deployment_min_threshold]
end

# Returns a valid key for the deployment
# If the public_key points to a file, read it
# If the public_key is a URI, fetch it
#
def key_for_deployment(env)
  env[:public_key] = keychain(:public)
  uri = URI.parse(env[:public_key])
  case uri
  when URI::HTTP, URI::HTTPS
    connection.get(uri.to_s).body
  else
    File.read(env[:public_key])
  end
end

# Finds the first SSH key that has both public and private parts in the <tt>~/.ssh</tt> directory.
# @return [Array<String,String>] the public_key_path and private_key_path if <tt>key_type</tt> is <tt>nil</tt>.
# @return [String] the public key if <tt>key_type=:public</tt>, or the private key if <tt>key_type=:private</tt>.
#
def keychain(key_type = nil)
  public_key = nil
  private_key = nil
  Dir[File.expand_path("~/.ssh/*.pub")].each do |file|
    public_key = file
    private_key = File.join(
      File.dirname(public_key),
      File.basename(public_key, ".pub")
    )
    if File.exist?(private_key) && File.readable?(private_key)
      break
    else
      private_key = nil
    end
  end
  case key_type
  when :public
    public_key
  when :private
    private_key
  else
    [public_key, private_key]
  end
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

def cleanup( job = nil, deployment = nil)
  synchronize {
    logger = @logger

    if job.nil? && deployment.nil?
      logger.info "Cleaning up all jobs and deployments..."
      @deployments.each{ |d| d.delete }.clear
      @jobs.each{ |j| j.delete }.clear
    else
      unless deployment.nil?
        logger.info "Cleaning up deployment##{deployment['uid']}..."
        @deployments.delete(deployment) && deployment.delete
      end
      unless job.nil?
        logger.info "Cleaning up job##{job['uid']}..."
        @jobs.delete(job) && job.delete
      end
    end
  }
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
              resource.properties[:site] = gw[1]
              resource_set.properties[:site] = gw[1]
              resource.properties[:gateway] = gateway
              resource_set.properties[:gateway] = gateway
              resource_set.push(resource)
            }
          end
        }

        $all.push(resource_set)
      }
    }
end 

end # Expo

