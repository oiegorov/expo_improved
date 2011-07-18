require 'rctrl/rctrl_service'
require 'resctrl/resctrl_resctrlclient'
require 'resctrl/resctrl_resctrlreservation'
require 'resctrl/resctrl_resctrlresponse'
require 'thread'

module Expo

class ResCtrlService < RCtrlService

  def initialize(*args)
    super
    @reservation_hash = Hash::new
    @reservation_mutex = Mutex::new
    @reservation_number = 0
  end

private

  def register_reservation(reservation)
    reservation_number = 0
    @reservation_mutex.synchronize do
      reservation_number = @reservation_number
      @reservation_hash[@reservation_number] = reservation
      @reservation_number += 1
    end
    return reservation_number
  end

  def get_reservation(reservation_number)
    reservation = nil
    @reservation_mutex.synchronize do
      reservation = @reservation_hash[reservation_number]
    end
    raise "Invalid reservation number" if !reservation
    return reservation
  end

  def get_server_ref(server_name)
    server = get_server(server_name)
    if not server then
      server = ResCtrlClient::new(server_name)
      register_server(server_name, server)
    end
    server
  end

public

  def new_reservation( type, parameters )
    reservation_file = type+"_reservation"
    require reservation_file

    reservation_class = type+"Reservation"
    reservation_class[0] = reservation_class[0..0].upcase[0]
    reservation_object = eval(reservation_class+"::new")
    
    command_line = reservation_object.make_reservation_command_line(parameters)
    command_result = command(command_line)
    raise "Reservation Error : #{command_result.inspect}." if command_result["exit_status"] != 0
    id = reservation_object.get_reservation_id(command_result["stdout"])
    command_rewind(command_result["command_number"])

    reservation = ResCtrlReservation::new(type, id, command_result["command_number"])
    reservation.misc_data = reservation_object.get_misc_data(command_result["stdout"])
    reservation_number = register_reservation(reservation)
    response = NewReservationResponse::new
    response["reservation_number"] = reservation_number


    #get reservation resources and set start date

    command_line = reservation_object.make_get_resources_command_line(reservation.id)
    c = RCtrlCommand::new(CmdCtrl::Commands::CommandBufferer::new( CmdCtrl::Commands::Command::new(command_line) ))
    reservation.resources_command_number = register_command(c)
    c.set_start_time
    #set a callback to get the reservation start_time time
    c.cmd.on_exit do |status, cmd|
      c.set_end_time
      reservation.set_resources( reservation_object.get_resources(cmd.read_stdout) )
      cmd.rewind_stdout
      reservation.set_jobs( reservation_object.get_jobs(cmd.read_stdout) )
      cmd.rewind_stdout
      reservation.resources_command_status = status.exitstatus 
      reservation.set_start_time
    end
    #run the command
    c.cmd.run
    return response
  end

  def open_reservation( type, id )
    reservation = ResCtrlReservation::new(type, id)
    reservation_number = register_reservation(reservation)
    response = OpenReservationResponse::new
    response["reservation_number"] = reservation_number

    reservation_file = type+"_reservation"
    require reservation_file
    reservation_class = type+"Reservation"
    reservation_class[0] = reservation_class[0..0].upcase[0]
    reservation_object = eval(reservation_class+"::new")
    reservation.misc_data = reservation_object.get_misc_data("")

    #get reservation resources and set start date
    command_line = reservation_object.make_get_resources_command_line(reservation.id)
    c = RCtrlCommand::new(CmdCtrl::Commands::CommandBufferer::new( CmdCtrl::Commands::Command::new(command_line) ))
    reservation.resources_command_number = register_command(c)
    c.set_start_time
    #set a callback to get the reservation start_time time
    c.cmd.on_exit do |status, cmd|
      c.set_end_time
      reservation.set_resources( reservation_object.get_resources(cmd.read_stdout) )
      cmd.rewind_stdout
      reservation.set_jobs( reservation_object.get_jobs(cmd.read_stdout) )
      cmd.rewind_stdout
      reservation.resources_command_status = status.exitstatus
      reservation.set_start_time
    end
    #run the command
    c.cmd.run

    return response
  end

  def reservation_info(reservation_number)
    reservation = get_reservation(reservation_number)
    response = ReservationInfoResponse::new
    response["id"] = reservation.id
    response["type"] = reservation.type
    response["command_number"] = reservation.command_number
    response["resources_command_number"] = reservation.resources_command_number
    response["start_time"] = reservation.start_time
    response["started"] = reservation.started
    response["resources_command_status"] = reservation.resources_command_status
    response["deleted"] = reservation.deleted
    response["delete_time"] = reservation.delete_time
    response["delete_command_number"] = reservation.delete_command_number
    response["delete_command_status"] = reservation.delete_command_status
    response["misc_data"] = reservation.misc_data
    return response
  end

  def reservation_stats( type, parameters )
    reservation_file = type+"_reservation"
    require reservation_file

    reservation_class = type+"Reservation"
    reservation_class[0] = reservation_class[0..0].upcase[0]
    reservation_object = eval(reservation_class+"::new")
    
    command_line = reservation_object.make_get_reservation_stats_command_line(parameters)
    command_result = command(command_line)
    raise "Reservation Error : #{command_response.inspect}." if command_result["exit_status"] != 0
    stats = reservation_object.get_reservation_stats(command_result["stdout"])

    response = ReservationStatsResponse::new
    response["stats"] = stats
    response["command_number"] = command_result["command_number"]
    return response
  end

  def reservation_job( reservation_number, job_name, cluster_name )
    reservation = get_reservation(reservation_number)
    
    raise "Reservation Error : reservation not started" if not reservation.started
    
    response = ReservationJobResponse::new
    response["command_number"] = reservation.resources_command_number
    
    jobs = reservation.jobs
    if cluster_name then
      cluster = jobs[cluster_name]
      raise "Cluster not found" if not cluster
      response["nodes"] = cluster[job_name]
    else
      jobs.each { |key,value|
        value.each { |key,value|
          if key == job_name then
            response["nodes"] = value
          end
        }
      }
    end
    raise "Job not found" if not response["nodes"]
    return response
  end

  def reservation_jobs( reservation_number )
    reservation = get_reservation(reservation_number)
    
    raise "Reservation Error : reservation not started" if not reservation.started
    
    response = ReservationJobsResponse::new
    response["jobs"] = reservation.jobs
    response["command_number"] = reservation.resources_command_number
    return response

  end

  def reservation_resources( reservation_number )
    reservation = get_reservation(reservation_number)
    
    raise "Reservation Error : reservation not started" if not reservation.started
    
    response = ReservationResourcesResponse::new
    
    response["resources"] = reservation.resources
    response["command_number"] = reservation.resources_command_number
    response["resources_command_status"] = reservation.resources_command_status
    return response

  end

  def delete_reservation(reservation_number)
    reservation = get_reservation(reservation_number)
    reservation_file = reservation.type+"_reservation"
    require reservation_file

    reservation_class = reservation.type+"Reservation"
    reservation_class[0] = reservation_class[0..0].upcase[0]
    reservation_object = eval(reservation_class+"::new")
    
    command_line = reservation_object.make_delete_reservation_command_line(reservation.id)
    command_result = command(command_line)
    reservation.delete_command_status = command_result["exit_status"]
    reservation.delete_command_number = command_result["command_number"]
    reservation.set_delete_time
    command_rewind(command_result["command_number"])
 
    response = DeleteReservationResponse::new
    response["delete_command_number"] = reservation.delete_command_number
    response["delete_command_status"] = reservation.delete_command_status
    return response
  end

end

end
