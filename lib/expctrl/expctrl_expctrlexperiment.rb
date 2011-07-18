require 'date'
require 'thread'

module Expo

class ExpCtrlExperiment
  attr_accessor :create_time, :reservations, :commands, :nodes

  def initialize
    @create_time = DateTime::now
    @reservations = Array::new
    @reservations_mutex = Mutex::new
    @commands = Array::new
    @commands_mutex = Mutex::new
    @nodes = Hash::new
    @nodes_mutex = Mutex::new
  end

  def add_reservation( reservation_number )
    @reservations_mutex.synchronize do
      @reservations.push( reservation_number )
    end
  end

  def add_command( command_number )
    @commands_mutex.synchronize do
      @commands.push( command_number )
    end
  end

  def delete_command( command_number )
    @commands_mutex.synchronize do
      @commands.delete( command_number )
    end
  end

  def add_nodes( nodes_name, nodes )
    @nodes_mutex.synchronize do
      @nodes[nodes_name] = nodes
    end
  end

  def get_nodes( nodes_name )
    nodes = nil
    @nodes_mutex.synchronize do
      nodes = @nodes[nodes_name]
    end
    raise "Invalid nodes name" if !nodes
    return nodes
  end

  def get_all_reservations()
    reservations = nil
    @reservations_mutex.synchronize do
      reservations = Array::new(@reservations)
    end
    return reservations
  end

  def get_all_commands()
    commands = nil
    @commands_mutex.synchronize do
      commands = Array::new(@commands)
    end
    return commands
  end

  def get_all_nodes()
    nodes = nil
    @nodes_mutex.synchronize do
      nodes = Hash::new
      nodes = nodes.replace(@nodes)
    end
    return nodes
  end

end

end
