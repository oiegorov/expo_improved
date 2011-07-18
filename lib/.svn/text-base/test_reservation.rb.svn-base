JOBS = { "idpot" => { "zozo" => ["foo","bar"] }, "icluster2" => { "zonzon" => ["toto","tata"] } }
RESOURCES = { "idpot" => {"123" => ["foo","bar"] }, "icluster2" => {"124" => ["toto","tata"] } }
MISCDATA = { "toto" => "tutu", "titi" => "tata" }
RESERVATION_ID = 23
STATS = "Stats."

class TestReservation

  def make_reservation_command_line(parameters)
    command_line = 'echo "toto"'
    return command_line
  end
  
  def get_reservation_id(stdout)
    return RESERVATION_ID
  end

  def get_misc_data(stdout)
    return MISCDATA
  end

  def make_get_resources_command_line(id)
    command_line = 'echo "tata"'
    return command_line
  end

  def get_resources(stdout)
    return RESOURCES
  end

  def get_jobs(stdout)
    return JOBS
  end

  def make_get_reservation_stats_command_line(parameters)
    command_line = 'echo "tutu"'
    return command_line
  end

  def get_reservation_stats(stdout)
    return STATS
  end

  def make_delete_reservation_command_line(id)
    command_line = 'echo "tyty"'
    return command_line
  end
end
