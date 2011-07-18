#!/usr/bin/ruby 

[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }
[ '../bin', 'bin' ].each { |d| $:.unshift(d) if File::directory?(d) }

at_exit {
  Dir::rmdir("tmp1")
  Dir::rmdir("tmp2")
}

$RMI = 'soap'
$POLLING = false

require 'rctrl'
require 'rctrl_server'
require 'date'
require 'thread'
require 'test/unit'

include Expo

PORT = 20055
PORT2 = 20056

server1 = RCtrlServer.new('rctrl', NS, '0.0.0.0', PORT, 0, "tmp1")
trap(:INT) do 
  server1.shutdown
  exit
end
Thread::new { server1.start }

server2 = RCtrlServer.new('rctrl', NS, '0.0.0.0', PORT2, 0, "tmp2")
trap(:INT) do
  server2.shutdown
  exit
end
Thread::new { server2.start }

class RCtrlTest < Test::Unit::TestCase


  def test_command_1
    client = RCtrlClient::new("localhost:#{PORT}")
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
    client = RCtrlClient::new("localhost:#{PORT}")
    params2 = CommandParameters::new("date")
    params1 = RecursiveCommandParameters::new("localhost:#{PORT}",'command',params2)
    result = client.recursive_command("localhost:#{PORT2}", 'recursive_command', params1)
    assert(result["command_result"]["command_result"]["stdout"])
  end
  
  def test_recursive_command_2
    client = RCtrlClient::new("localhost:#{PORT}")
    params2 = CommandParameters::new("date")
    params1 = RecursiveCommandParameters::new("localhost:#{PORT}",'command',params2)
    begin
      response = client.recursive_command("localhost:#{PORT2+1}", 'recursive_command', params1)
      assert( false )
    rescue => details
      assert(true)
    end

  end

  def test_delayed_command
    client = RCtrlClient::new("localhost:#{PORT}")

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
    client = RCtrlClient::new("localhost:#{PORT}")
    result = client.asynchronous_command("sleep 5")
    info = client.command_wait(result["command_number"],1)
    assert(info["finished"])
  end

  def test_command_wait_2
    a = nil
    client = RCtrlClient::new("localhost:#{PORT}")
    result = client.asynchronous_command("sleep 5")
    client.command_wait(result["command_number"],1) { |info|
      assert(info["finished"])
      a = true
    }
    sleep 7
    assert(a)
  end

  def test_command_wait_3
    client = RCtrlClient::new("localhost:#{PORT}")
    result = client.delayed_command("sleep 5",DateTime::now + 3.0/(24*60*60))
    info = client.command_wait(result["command_number"],1)
    assert(info["finished"])
  end

  def test_command_wait_4
    a = nil
    b = nil
    client = RCtrlClient::new("localhost:#{PORT}")
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
    client = RCtrlClient::new("localhost:#{PORT}")
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

  def test_ruby_command_1
    s = "i = 3\n"
    s += 'puts "toto #{i}"'
    client = RCtrlClient::new("localhost:#{PORT}")
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
    client = RCtrlClient::new("localhost:#{PORT}")
    result = client.ruby_command(s)
    assert(result["stdout"] == "toto 3\n")
  end

  def test_ruby_delayed_command_1
    s = "i = 3\n"
    s += 'puts "toto #{i}"'
    client = RCtrlClient::new("localhost:#{PORT}")
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
    client = RCtrlClient::new("localhost:#{PORT}")
    result = client.ruby_delayed_command(s,DateTime::now + 2.0/(24*60*60))
    client.command_wait(result["command_number"],1)
    result = client.command_result(result["command_number"])
    assert(result["stdout"] == "toto 3\n")
  end

  def test_ruby_asynchronous_command_1
    s = "i = 3\n"
    s += 'puts "toto #{i}"'
    client = RCtrlClient::new("localhost:#{PORT}")
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
    client = RCtrlClient::new("localhost:#{PORT}")
    result = client.ruby_asynchronous_command(s)
    client.command_wait(result["command_number"],1)
    result = client.command_result(result["command_number"])
    assert(result["stdout"] == "toto 3\n")
  end

  def test_command_input
    s = "s1 = gets\n"
    s += "s2 = gets\n"
    s += 'puts "bonjour #{s1} et #{s2}"'
    client = RCtrlClient::new("localhost:#{PORT}")
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

  def test_bulk_commands
    commands = [['asynchronous_command',['date']],
                ['delayed_command',['date',DateTime::now + 2.0/(24*60*60)]],
                ['asynchronous_command',['uname -a']]]
    client = RCtrlClient::new("localhost:#{PORT}")
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
    client = RCtrlClient::new("localhost:#{PORT}")
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
    client = RCtrlClient::new("localhost:#{PORT}")
    result = client.bulk_commands(commands)
    sleep 5
    command_numbers = Array::new
    command_numbers.push(result[0]["command_number"]).push(result[1]["command_number"]).push(result[2]["command_number"])
    results = client.bulk_command_results(command_numbers)
    results.each_value{ |r|
      assert( r["stdout"] )
    }
  end

  def test_command_delete
    client = RCtrlClient::new("localhost:#{PORT}")    
    result = client.asynchronous_command("sleep 5")
    client.command_delete(result["command_number"])
    begin
      response = client.command_info(result["command_number"])
      assert(false)
    rescue => detail
      assert(detail.to_s == "Invalid command number")
    end
  end

end
