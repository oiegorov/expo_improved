require 'rctrl'
require 'resctrl/resctrl_resctrlresponse'

module Expo

$RMI_COMMANDS.concat( [
        ['new_reservation', 'type', 'description'],
        ['open_reservation', 'type', 'id'],
        ['reservation_info','reservation_number'],
        ['reservation_stats', 'type', 'parameters'],
        ['reservation_resources', 'reservation_number'],
        ['reservation_jobs', 'reservation_number'],
        ['reservation_job', 'reservation_number', 'job_name', 'cluster_name'],
        ['delete_reservation', 'reservation_number']
]
)


Expo.send(:remove_const, :RCtrlClientNoneDriver) 

require 'resctrl/resctrl_service'

class ResCtrlService < RCtrlService
end

class RCtrlClientNoneDriver < ResCtrlService
        def initialize(server)
                super(nil,nil)
        end
end

class ResCtrlClient < RCtrlClient

  def initialize(server=nil)
    super(server)
#    add_method('new_reservation', 'type', 'description')
#    add_method('open_reservation', 'type', 'id')
#    add_method('reservation_info','reservation_number')
#    add_method('reservation_stats', 'type', 'parameters')
#    add_method('reservation_resources', 'reservation_number')
#    add_method('reservation_jobs', 'reservation_number')
#    add_method('reservation_job', 'reservation_number', 'job_name', 'cluster_name')
#    add_method('delete_reservation', 'reservation_number')
  end

  def reservation_wait(reservation_number, polling_time = 10, delay = 0, &block)
    raise "Polling_time cannot be 0" if polling_time == 0
    info = reservation_info(reservation_number).result
    response = ReservationWaitResponse::new
    if block
      t = Thread::new {
        info = internal_reservation_wait(reservation_number, delay, polling_time, info)
        block.call(info)
      }
      response.result = info
      return response
    else
      response.result = internal_reservation_wait(reservation_number, delay, polling_time, info)
      return response
    end
  end

  private

  def internal_reservation_wait(reservation_number, delay, polling_time, info)
    sleep(delay)
    while not info["started"]
      sleep(polling_time)
      info = reservation_info(reservation_number).result
    end
    return info
  end

end
end
