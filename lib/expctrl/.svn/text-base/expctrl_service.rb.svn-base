require 'resctrl/resctrl_service'
require 'expctrl/expctrl_expctrlexperiment'
require 'expctrl/expctrl_expctrlresponse'
require 'thread'

module Expo

#the main service provided by the remote control server
class ExpCtrlService < ResCtrlService 

  #creates a new server
  def initialize(*args)
    super
    @experiment_hash = Hash::new
    @experiment_number = 0
    @experiment_mutex = Mutex::new
  end

private

  #registers new experiments into the Hash table, and affects it the next free experiment number
  def register_experiment(exp)
    experiment_num = 0
    @experiment_mutex.synchronize do
      experiment_num = @experiment_number
      @experiment_hash[@experiment_number] = exp
      @experiment_number += 1
    end
    return experiment_num
  end

  #returns an experiment from it's experiment number
  #raises "Invalid experiment number" if the experiment number is invalid
  def get_experiment(exp_number)
    exp = nil
    @experiment_mutex.synchronize do
      exp = @experiment_hash[exp_number]
    end
    raise "Invalid experiment number" if !exp
    return exp
  end

public

  def create_experiment
    experiment = ExpCtrlExperiment::new
    response = CreateExperimentResponse::new
    response["experiment_number"] = register_experiment( experiment )
    return response
  end

  def add_nodes( experiment_number, nodes_name, nodes )
    experiment = get_experiment( experiment_number )
    experiment.add_nodes( nodes_name, nodes )
    return AddNodesResponse::new
  end

  def add_command( experiment_number, command_number )
    experiment = get_experiment( experiment_number )
    command = get_command( command_number )
    experiment.add_command( command_number )
    return AddCommandResponse::new
  end

  def add_commands( experiment_number, command_numbers )
    experiment = get_experiment( experiment_number )
    command_numbers.each { |n|
      command = get_command( n )
      experiment.add_command( n )
    }
    return AddCommandsResponse::new
  end

  def add_reservation( experiment_number, reservation_number )
    experiment = get_experiment( experiment_number )
    reservation = get_reservation( reservation_number )
    experiment.add_reservation( reservation_number )
    return AddReservationResponse::new
  end

  def get_nodes( experiment_number, nodes_name )
    experiment = get_experiment( experiment_number )
    nodes = experiment.get_nodes( nodes_name )
    response = GetNodesResponse::new
    response["nodes"] = nodes
    return response
  end

  def get_all_nodes( experiment_number )
    experiment = get_experiment( experiment_number )
    nodes = experiment.get_all_nodes
    response = GetAllNodesResponse::new
    response["nodes"] = nodes
    return response
  end

  def get_all_reservations( experiment_number )
    experiment = get_experiment( experiment_number )
    reservations = experiment.get_all_reservations
    response = GetAllReservationsResponse::new
    response["reservations"] = reservations
    return response
  end

  def get_all_commands( experiment_number )
    experiment = get_experiment( experiment_number )
    commands = experiment.get_all_commands
    response = GetAllCommandsResponse::new
    response["commands"] = commands
    return response
  end

  def experiment_info( experiment_number )
    experiment = get_experiment( experiment_number )
    response = ExperimentInfoResponse::new
    response["create_time"] = experiment.create_time
    response["experiment_number"] = experiment_number
    return response
  end

  def delete_command( experiment_number, command_number )
    experiment = get_experiment( experiment_number )
    experiment.delete_command( command_number )
    return DeleteCommandResponse::new
  end

end

end
