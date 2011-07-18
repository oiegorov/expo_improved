#!/usr/bin/ruby 

[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }
[ '../bin', 'bin' ].each { |d| $:.unshift(d) if File::directory?(d) }

$RMI = 'none'
$POLLING = false

require 'expctrl'
require 'test/unit'
require 'test_reservation'

include Expo

PORT = 0
PORT2 = 6

class ExpCtrlTest < Test::Unit::TestCase

  def test_open_close_experiment
    client = ExpCtrlClient::new
    assert(!client.experiment_number["experiment_number"])
    experiment_number = client.open_experiment["experiment_number"]
    assert(client.experiment_number["experiment_number"])
    client.close_experiment
    assert(!client.experiment_number["experiment_number"])
  end

  def test_commands_1
    client = ExpCtrlClient::new
    client.open_experiment
    client.command('echo "toto1"')
    client.command('echo "toto2"')
    client.command('echo "toto3"')
    result = client.commands
    assert(result["commands"].length == 3)
    client.close_experiment
  end

  def test_commands_2
    client = ExpCtrlClient::new
    client.command('echo "toto1"')
    client.command('echo "toto2"')
    client.command('echo "toto3"')
    result = client.commands
    assert(result["commands"].length == 3)
  end

  def test_nodes_1
    client = ExpCtrlClient::new
    client.open_experiment
    client.nodes("toto",["titi","tutu","tata"])
    client.nodes("zozo",["vivi","vuvu"])
    result = client.nodes("toto")
    assert( result["nodes"] == ["titi","tutu","tata"] )
    result = client.nodes
    assert( result["nodes"] == {"toto" => ["titi","tutu","tata"], "zozo" => ["vivi","vuvu"] })
    client.close_experiment
  end  

  def test_nodes_2
    client = ExpCtrlClient::new
    client.nodes("toto",["titi","tutu","tata"])
    client.nodes("zozo",["vivi","vuvu"])
    result = client.nodes("toto")
    assert( result["nodes"] == ["titi","tutu","tata"] )
    result = client.nodes
    assert( result["nodes"] == {"toto" => ["titi","tutu","tata"], "zozo" => ["vivi","vuvu"] })
  end  

  def test_reservations_1
    client = ExpCtrlClient::new
    client.open_experiment
    client.new_reservation("test", nil)
    client.new_reservation("test", nil)
    client.new_reservation("test", nil)
    result = client.reservations
    assert( result["reservations"].length == 3 )
    client.close_experiment
  end

  def test_reservations_2
    client = ExpCtrlClient::new
    client.new_reservation("test", nil)
    client.new_reservation("test", nil)
    client.new_reservation("test", nil)
    result = client.reservations
    assert( result["reservations"].length == 3 )
  end
 
  def test_command_1
    client = ExpCtrlClient::new
    result = client.command('echo "toto"')
    assert(result["stdout"] == "toto\n")
    assert(result["stderr"] == "")
    assert(result["exit_status"] == 0)
    result2 = client.command_info(result["command_number"])
    assert(result2["started"])
    assert(result2["finished"])
    assert( ! result2["scheduled"])
    assert(result2.started)
    assert(result2.finished)
    assert( ! result2.scheduled)
    begin
      response = client.command_info(result["command_number"]+1)
      assert(false)
    rescue => detail
      assert(detail.to_s == "Invalid command number")
    end
  end
  
  def test_recursive_command_1
    client = ExpCtrlClient::new
    params2 = CommandParameters::new("date")
    params1 = RecursiveCommandParameters::new(nil,'command',params2)
    result = client.recursive_command(nil, 'recursive_command', params1)
    assert(result["command_result"]["command_result"]["stdout"])
  end
  
  def test_recursive_command_2
    client = ExpCtrlClient::new
    params2 = CommandParameters::new("date")
    params1 = RecursiveCommandParameters::new(nil,'command',params2)
    begin
      response = client.recursive_command(nil, 'recursive_command', params1)
      assert( false )
    rescue => details
      assert(true)
    end

  end

  def test_delayed_command
    client = ExpCtrlClient::new

    expected_results = Array::new
    command_numbers = Array::new 
    obtained_results = Array::new

    n=150

    0.upto(n) { |x|
      expected_results.push(DateTime::now + (rand(10) +rand)/(24*60*60))
      result = client.delayed_command("date",expected_results[x])
      command_numbers.push(result["command_number"])
    }

    sleep(15)

    0.upto(n) { |x|
      result = client.command_info(command_numbers[x])
      obtained_results.push(result["start_time"])
    }
      
    0.upto(n) { |x|
      delta = ( ( obtained_results[x] - expected_results[x] ) * 24.0*60.0*60.0 )
      assert( delta < 0.1 )
    }
  end

  def test_command_wait_1
    client = ExpCtrlClient::new
    result = client.asynchronous_command("sleep 5")
    info = client.command_wait(result["command_number"],1)
    assert(info["finished"])
  end

  def test_command_wait_2
    a = nil
    client = ExpCtrlClient::new
    result = client.asynchronous_command("sleep 5")
    client.command_wait(result["command_number"],1) { |info|
      assert(info["finished"])
      a = true
    }
    sleep 7
    assert(a)
  end

  def test_command_wait_3
    client = ExpCtrlClient::new
    result = client.delayed_command("sleep 5",DateTime::now + 3.0/(24*60*60))
    info = client.command_wait(result["command_number"],1)
    assert(info["finished"])
  end

  def test_command_wait_4
    a = nil
    b = nil
    client = ExpCtrlClient::new
    result = client.delayed_command("sleep 5",DateTime::now + 3.0/(24*60*60))
    client.command_wait(result["command_number"],1) {
      a = true
    }
    result = client.delayed_command("sleep 5",DateTime::now + 2.0/(24*60*60))
    client.command_wait(result["command_number"],1) {
      b = true
    }
    sleep 10
    assert(a)
    assert(b)
  end

  def test_command_wait_5
    a = nil
    client = ExpCtrlClient::new
    result = client.asynchronous_command("sleep 5")
    client.command_wait(result["command_number"],1) {
      a = true
      result = client.delayed_command('echo "toto"',DateTime::now + 2.0/(24*60*60))
    }
    sleep 11
    result = client.command_result(result["command_number"])
    assert(result["stdout"] == "toto\n")
    assert(a)
  end

  def test_bulk_commands
    commands = [['asynchronous_command',['date']],
                ['delayed_command',['date',DateTime::now + 2.0/(24*60*60)]],
                ['asynchronous_command',['uname -a']]]
    client = ExpCtrlClient::new
    result = client.bulk_commands(commands)
    assert( result.length == 3 )
    sleep 5
    result.each { |number,res|
      assert( client.command_result(res["command_number"])["exited"] )
    }
  end

  def test_bulk_command_infos
    commands = [['asynchronous_command',['date']],
                ['delayed_command',['date',DateTime::now + 2.0/(24*60*60)]],
                ['asynchronous_command',['uname -a']]]
    client = ExpCtrlClient::new
    result = client.bulk_commands(commands)
    sleep 5
    command_numbers = Array::new
    command_numbers.push(result[0]["command_number"]).push(result[1]["command_number"]).push(result[2]["command_number"])
    infos = client.bulk_command_infos(command_numbers)
    infos.each_value{ |i|
      assert( i["finished"] )
    }
  end
  
  def test_bulk_command_results
    commands = [['asynchronous_command',['date']],
                ['delayed_command',['date',DateTime::now + 2.0/(24*60*60)]],
                ['asynchronous_command',['uname -a']]]
    client = ExpCtrlClient::new
    result = client.bulk_commands(commands)
    sleep 5
    command_numbers = Array::new
    command_numbers.push(result[0]["command_number"]).push(result[1]["command_number"]).push(result[2]["command_number"])
    results = client.bulk_command_results(command_numbers)
    results.each_value{ |r|
      assert( r["stdout"] )
    }
  end

  def test_ruby_command_1
    s = "i = 3\n"
    s += 'puts "toto #{i}"'
    client = ExpCtrlClient::new
    result = client.ruby_command(s)
    assert(result["stdout"] == "toto 3\n")
    result2 = client.command_info(result["command_number"])
    assert( result2["command_line"] == nil )
    assert( result2["ruby_command"] )
    assert( result2["ruby_script"] == s )
  end
  
  def test_ruby_command_2
    s = "i = 3\n"
    s += 'result = command("echo toto #{i}")
'
    s += "puts result[\"stdout\"]"
    client = ExpCtrlClient::new
    result = client.ruby_command(s)
    assert(result["stdout"] == "toto 3\n")
  end

  def test_ruby_delayed_command_1
    s = "i = 3\n"
    s += 'puts "toto #{i}"'
    client = ExpCtrlClient::new
    result = client.ruby_delayed_command(s,DateTime::now + 2.0/(24*60*60))
    client.command_wait(result["command_number"],1)
    result2 = client.command_result(result["command_number"])
    assert(result2["stdout"] == "toto 3\n")
    result3 = client.command_info(result["command_number"])
    assert( result3["command_line"] == nil )
    assert( result3["ruby_command"] )
    assert( result3["ruby_script"] == s )
  end
  
  def test_ruby_delayed_command_2
    s = "i = 3\n"
    s += 'result = command("echo toto #{i}")
'
    s += "puts result[\"stdout\"]"
    client = ExpCtrlClient::new
    result = client.ruby_delayed_command(s,DateTime::now + 2.0/(24*60*60))
    client.command_wait(result["command_number"],1)
    result = client.command_result(result["command_number"])
    assert(result["stdout"] == "toto 3\n")
  end

  def test_ruby_asynchronous_command_1
    s = "i = 3\n"
    s += 'puts "toto #{i}"'
    client = ExpCtrlClient::new
    result = client.ruby_asynchronous_command(s)
    client.command_wait(result["command_number"],1)
    result2 = client.command_result(result["command_number"])
    assert(result2["stdout"] == "toto 3\n")
    result3 = client.command_info(result["command_number"])
    assert( result3["command_line"] == nil )
    assert( result3["ruby_command"] )
    assert( result3["ruby_script"] == s )
  end
  
  def test_ruby_asynchronous_command_2
    s = "i = 3\n"
    s += 'result = command("echo toto #{i}")
'
    s += "puts result[\"stdout\"]"
    client = ExpCtrlClient::new
    result = client.ruby_asynchronous_command(s)
    client.command_wait(result["command_number"],1)
    result = client.command_result(result["command_number"])
    assert(result["stdout"] == "toto 3\n")
  end

  def test_command_input
    s = "s1 = gets\n"
    s += "s2 = gets\n"
    s += 'puts "bonjour #{s1} et #{s2}"'
    client = ExpCtrlClient::new
    result = client.ruby_asynchronous_command(s)
    client.command_input(result["command_number"], "toto")
    client.command_input(result["command_number"], "tata")
    client.command_wait(result["command_number"],1)
    result2 = client.command_result(result["command_number"])
    assert(result2["stdout"] == "bonjour toto\n et tata\n")
    result3 = client.get_command_inputs(result["command_number"])
    assert(result3["inputs"][0]["input"] == "toto")
    assert(result3["inputs"][1]["input"] == "tata")
  end
 
  def test_command_delete
   client = ExpCtrlClient::new
   result = client.asynchronous_command("sleep 5")
   client.command_delete(result["command_number"])
   begin
     response = client.command_info(result["command_number"])
     assert(false)
   rescue => detail
     assert(detail.to_s == "Invalid command number")
   end
  end
					      
 
  def test_new_reservation_1
    client = ExpCtrlClient::new
    result = client.new_reservation("test", nil)
    result2 = client.reservation_info(result["reservation_number"])
    assert( RESERVATION_ID == result2["id"] )
    assert( MISCDATA == result2["misc_data"] )
  end

  def test_new_reservation_2
    client = ExpCtrlClient::new
    result = client.new_reservation("test", nil)
    client.delete_reservation( result["reservation_number"] )
  end

  def test_open_reservation
    client = ExpCtrlClient::new
    result = client.open_reservation("test", RESERVATION_ID)
    result = client.reservation_info(result["reservation_number"])
    assert( RESERVATION_ID == result["id"] )
  end

  def test_reservation_resources
    client = ExpCtrlClient::new
    result = client.new_reservation("test", nil)
    client.reservation_wait(result["reservation_number"],1,0)
    result = client.reservation_resources(result["reservation_number"])
    assert ( RESOURCES == result["resources"] )
  end

  def test_reservation_jobs
    client = ExpCtrlClient::new
    result = client.new_reservation("test", nil)
    client.reservation_wait(result["reservation_number"],1,0)
    result = client.reservation_jobs(result["reservation_number"])
    assert ( JOBS == result["jobs"] )
  end

  def test_reservation_job
    client = ExpCtrlClient::new
    result = client.new_reservation("test", nil)
    client.reservation_wait(result["reservation_number"],1,0)
    result = client.reservation_job(result["reservation_number"],"zozo",nil)
    assert ( ["foo","bar"] == result["nodes"] )
  end

  def test_reservation_stats
    client = ExpCtrlClient::new
    result = client.reservation_stats("test", nil)
    assert ( STATS == result["stats"] )
  end
 
end

