require 'yaml'

module Expo

class OargridReservation

  def make_reservation_command_line(parameters)
    command_line = "oargridsub"
    command_line += " -s \""+parameters.start_date.strftime("%Y-%m-%d %H:%M:%S")+"\"" if parameters.start_date
    command_line += " -q #{parameters.queue}" if parameters.queue
    command_line += " -p #{parameters.program}" if parameters.program
    command_line += " -w #{parameters.walltime}" if parameters.walltime
    command_line += " -d #{parameters.directory}" if parameters.directory
    command_line += " -v" if parameters.verbose
    command_line += " -F" if parameters.force
    command_line += " -f #{parameters.file}" if parameters.file
    command_line += "  #{parameters.description}" if parameters.description
    return command_line
  end
  
  def get_reservation_id(stdout)
    id = stdout.scan(/Grid reservation id = (\d*)/).first.first
    return id
  end

  def get_misc_data(stdout)
    return Hash::new
  end

  def make_get_resources_command_line(id)
    command_line = "oargridstat"
    command_line +=" -l #{id}"
    command_line +=" -w"
    command_line +=" -Y"
    return command_line
  end

  def get_resources(stdout)
    resources = YAML::load(stdout)
    return resources
  end

  def get_jobs(stdout)
    resources = YAML::load(stdout)
    jobs = Hash::new
    resources.each { |key, value|
      cluster = Hash::new
      jobs[key] = cluster
      value.each { |key, value|
        nodes = Array::new
	jobs[key] = nodes
	value.each { |node|
	  nodes.push(node)
	}
      }
    }
    return jobs
  end

  def make_get_reservation_stats_command_line(parameters)
    command_line = "oargridstat"
    if parameters.help then
      command_line += " --help"
    elsif parameters.id then
      if parameters.list_nodes then
        command_line += " --list_nodes #{parameters.id}"
        if parameters.cluster_name then
          command_line += " --cluster #{parameters.cluster_name}"
          if parameters.job_id then
            command_line += " --job #{parameters.job_id}"
          end
        end
      elsif parameters.id then
        command_line += " #{parameters.id}"
      end
      if parameters.xml then
        command_line += " --xml"
      elsif parameters.yaml then
        command_line += " --yaml"
      elsif parameters.dumper then
        command_line += " --dumper"
      end
      if parameters.wait then
        command_line += " --wait"
        if parameters.polling then
          command_line += " --polling #{polling_time}"
        end
        if parameters.max_polling then
          command_line += " --max_polling #{max_polling}"
        end
      end
    elsif parameters.monitor then
      command_line += " --monitor"
      if parameters.cluster_names then
        parameters.cluster_names.each { |cluster_name|
          command_line += " --cluster #{cluster_name}"
        }
      end
    elsif parameters.gantt then
      command_line += " --gant #{parameters.gantt}"
    elsif parameters.list_clusters then
      command_line += " --list_clusters"
    elsif parameters.version then
      command_line += " --version"
    end
    return command_line
  end

  def get_reservation_stats(stdout)
    return(stdout)
  end

  def make_delete_reservation_command_line(id)
    command_line = "oargriddel #{id}"
    return command_line
  end
end

end
