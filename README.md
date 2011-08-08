# Expo
Expo helps you to run the experiments on Grid5000.

With Expo you can easily:

* reserve nodes;
* deploy environments;
* do whatever you want with the reserved nodes;

To run the simplest experiments it will be sufficient just to understand
the examples presented below. However, in order to happily use all the
Expo functionality you are recommended to have at least basic knowledge
of [Grid5000 API](https://api.grid5000.fr/) and such tools as [OAR](http://oar.imag.fr/), [Kadeploy](http://www.grid5000.fr/mediawiki/index.php/Kadeploy-v3) and [Taktuk](http://taktuk.gforge.inria.fr/).

The new version of Expo uses the Restfully http://github.com/crohr/restfully ruby gem to reserve and deploy the nodes using the Grid5000 API

If the Restfully gem is not yet installed:

    $ gem install restfully

## Installation

You can work with Expo in two modes:

1. On the frontend.
2. On your local machine. However, the Expo server should be started on
the frontend and SSH tunnel should be established (explained below).

In both cases the first thing to do:

    $ git clone git://github.com/oiegorov/expo_improved.git

Then

    $ export RUBYLIB=your_path/expo_improved/lib

### (Case 1) Run Expo exclusively on the frontend

    $ mkdir ~/.restfully 
    $ echo "base_uri: https://api.grid5000.fr/2.0/grid5000" > ~/.restfully/api.grid5000.fr.yml

And you are ready to go:

    $ your_path/expo_improved/bin/expo.rb path_to_your_test_file

### (Case 2) Run Expo from your local machine 

You have to configure both your machine (for expo client) and the frontend (for expo
server).

The following command should be executed on your machine as well as on the
frontend:

    $ echo "---
    rmi_protocol: soap
    port: 15789" > ~/.expctrl_server

Now execute on your local machine (specifying your Grid5000 login and
password):

    $ mkdir ~/.restfully
    $ echo "
    username: USER_NAME
    password: GRID5000PASSWORD
    base_uri: https://api.grid5000.fr/2.0/grid5000
    " > ~/.restfully/api.grid5000.fr.yml
    $ chmod 0600 ~/.restfully/api.grid5000.fr.yml

And the last thing is to establish an SSH tunnel from your local machine:

    $ ssh -f USER_NAME@access.YOUR_FRONTEND.grid5000.fr -L 15789:frontend:15789 -N

specifying your USER_NAME and YOUR_FRONTEND where you will launch expo
server.

Now you run expo server on the frontend
  
    $ your_path/expo_improved/bin/expctrl_server.rb

And start the experiment on your local machine:

    $ your_path/expo_improved/bin/expo.rb path_to_your_test_file

## Usage

Expo uses Domain Specific Language (DSL) based on Ruby language to describe the
experiments.

Let's consider several examples.

### The simplest test

We want to reserve 2 nodes in Lille, 3 nodes in Grenoble and execute
"uname -a" command on each node:

    require 'g5k_api'
    
    g5k_init(                                                                   
      :site => ["lille", "grenoble"], 
      :resources => ["nodes=2", "nodes=3"], 
      :walltime => 100 
    )
    g5k_run                     # run the reservation     
    
    check $all                  # check that all the nodes were properly reserved          
    
    $all.each { |node|          # $all contains a set of reserved nodes
      task node, "uname -a"     # execute command "uname -a" on each and wait till it finishes
    }     

As you can see, an experiment specification can be divided into two parts:

I. Describe all your requirements (sites, nodes, environments, walltime, etc. -- for the full list see Appendix below) and run reservation (+ deployment if :types => ["deploy"] was specified)

II. Do whatever you want with reserved nodes (using $all variable to address nodes and Expo's DSL commands: task, atask, ptask, etc.)

### More specific reservation

As Expo uses OAR2 to reserve the nodes, most of the parameters you specify in *g5k_init()* have the same semantics as in OAR. Thus, if we want to reserve 2 nodes in Lyon, on Sagittaire cluster with 8192KB of CPU cache we will have the following test file:

    require 'g5k_api'                                                               

    g5k_init( 
      :site => ["lyon", "grenoble"], 
      :resources => ["{cluster='sagittaire' and memcpu=8192}/nodes=2", "nodes=1"] 
    )
    g5k_run

    check $all

    #copy a tarball from the frontend to the nodes and output the text
    #file from the tarball
    $all.uniq.each { |node| 
      copy "~/tars/simple.tar", node, :path => "/home/oiegorov/hello/"
      task node, "tar xvf /home/oiegorov/hello/simple.tar -C /home/oiegorov/hello"
      task node, "cat /home/oiegorov/hello/readmeplz"
      task node, "rm /home/oiegorov/hello/*"
    }

To check all possible resource requests using OAR2: [this link](http://oar.imag.fr/user-usecases/#index5h1)

### Deployment

All you have to do to deploy an environment(s) on the reserved nodes is

* list the environments and the number of nodes to deploy
* add :types => ["deploy"] as a parameter to g5k_init()

Let's consider the following situation. You want to deploy "lenny-x64-base" environment on 1 node in Lyon and "squeeze-x64-base" on 1 node in Lyon as well as on 2 nodes in Grenoble. After the deployment is finished, you don't want to close the experiment, but display all the nodes with deployed environment on them to be able to connect to them manually afterwards.

    require 'g5k_api'                                                               

    g5k_init( 
      :site => ["lyon", "grenoble"], 
      :resources => ["nodes=2", "nodes=2"], 
      :environment => {"lenny-x64-base" => 1, "squeeze-x64-base" => 3}, 
      :walltime => 1800,
      :types => ["deploy"]
      :no_cleanup => true                       # don't delete the experiment after the test is finished
    )
    g5k_run

    $all.each { |node|
      puts "Node: #{node.properties[:name]}; environment: #{node.properties[:environment]}"
    }


### More specific deployment

Consider now the following case. You want to deploy two environments: one is a server environment and another one is a client environment. The server one should be deployed on 1 node. The client one should be deployed on 10 nodes. All from the same cluster.
After the deployment is finished you want to start a server application on the server node. After the server is waiting for requests, you want to start a client application on all the client nodes. 

    require 'g5k_api'

    g5k_init( 
      :site => ["lille"], 
      :resources => ["cluster=1/nodes=10"], 
      :environment => {"server_environment" => 1, "client_environment" => 3}, 
      :walltime => 1800,
      :types => ["deploy"]
    )
    g5k_run

    server = $all.select_resource(:environment => "lenny-x64-base")          #select a server node                
    task "root@#{server.name}", "./run_server"                              #run a server 

    clients = $all.select(:node, :environment => "squeeze-x64-base")         #select all client nodes
    clients.each { |client|
      atask "root@#{client.name}", "./run_client"                            #run a client 
    }

    barrier                                  # wait till all tasks are finished

As you can see from these examples there is a direct correspondence in the order of sites, the number of nodes to reserve on each site, and the number of the nodes where the environment will be deployed.

## Appendix A. List of g5k_init parameters 

* **:site => ["lille", "grenoble", ...]**          reserve on specific sites <br>
  **:site => "all"**                               reserve on all Grid5000 sites <br>
  **:site => "any"**                               reserve on a site with the max number of available nodes
* **:resources => ["nodes=1", "nodes=5"]**         reserve one node on the first site from :site, 5 nodes on the second site<br>
  **:resources => ["cluster=2/nodes=3"]**          reserve 3 nodes in 2 different clusters <br>
  **:resources => ["{cluster='sagittaire' and memcpu=8192}/nodes=2"]**   reserve 2 nodes with properties 
* **:environment => {"env1" => 2}**                 deploy env1 environment on the first 2 nodes from resources array <br>
  **:environment => {"env1" => 1, "env2" => 2}**    deploy env1 on the first node and env2 on the second and third nodes 
* **:walltime => 1800**                             set the experiment duration to 1800 seconds
* **:types => ["deploy"]**                          specify reservation type to "deploy". The default one is "allow_classic_ssh". Can be also "besteffort"
* **:name => "experiment_name"**                    the name of your experiment
* **:no_cleanup => false**                          if false (default) - the experiment will be deleted after the Expo returns
* **:deployment_max_attempts => 1**                 how many times we want to redeploy a node if the deployment fails
* **:submission_timeout => 5*60**                   for how long we wait for the reservation to be finished
* **:deployment_timeout => 15*60**                  for how long we wait for the deployment to be finished

The default values are: <br>
:site => ["lille"] <br>
:resources => ["nodes=1"] <br>
:environment => "lenny-x64-base" <br>
:walltime => 3600 <br>
:types => ["allow_classic_ssh"] <br>
:no_cleanup => false <br>
:deployment_max_attempts => 1 <br>
:submission_timeout => 5*60 <br>
:deployment_timeout => 15*60 <br>

## Appendix B. Expo commands and global variables

* **$all** is a ResourceSet where each reserved node is a Resource. <br>
available methods of the ResourceSet and Resource classes can be checked in lib/resourceset.rb
* **task**
* **atask**
* **barrier**
* **ptask**
* **patask**
* copy
* parallel_section ??
* check