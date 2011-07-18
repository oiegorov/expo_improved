require 'date'

module Expo

class ResCtrlReservation

  attr_accessor :type, :id, :command_number, :start_time, :started, :resources, :jobs, :resources_command_number, :resources_command_status, :deleted, :delete_time, :delete_command_number, :delete_command_status, :misc_data
  def initialize(type = nil, id = nil, command_number = nil)
    @started = false
    @start_time = nil
    @type = type
    @id = id
    @command_number = command_number
    @resources_command_number = nil
    @resources = nil
    @resources_command_status = nil
    @jobs = nil
    @deleted = false
    @delete_time = nil
    @delete_command_number = nil
    @delete_command_status = nil
    @misc_data = nil
  end

  def set_start_time
    @start_time = DateTime::now
    @started = true
  end

  def set_resources(resources)
    @resources = resources
  end

  def set_delete_time
    @delete_time = DateTime::now
    @deleted = true
  end

  def set_jobs(jobs)
    @jobs = jobs
  end

  def get_job(job_id)
    if @jobs then
      return jobs[job_id]
    else
      return nil
    end
  end

end
end
