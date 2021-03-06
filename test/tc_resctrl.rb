#!/usr/bin/ruby

[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }
[ '../bin', 'bin' ].each { |d| $:.unshift(d) if File::directory?(d) }

$RMI = 'soap'
$POLLING = false

require 'resctrl'
require 'resctrl_server'
require 'test/unit'
require 'test_reservation'

include Expo

PORT = 20057

server = ResCtrlServer.new('resctrl', NS, '0.0.0.0', PORT)
trap(:INT) do
  server1.shutdown
end
Thread::new { server.start }

class RCtrlTest < Test::Unit::TestCase
  
  def test_new_reservation_1
    client = ResCtrlClient::new("http://localhost:#{PORT}")
    result = client.new_reservation("test", nil)
    result2 = client.reservation_info(result["reservation_number"])
    assert( RESERVATION_ID == result2["id"] )
    assert( MISCDATA == result2["misc_data"] )
  end

  def test_new_reservation_2
    client = ResCtrlClient::new("http://localhost:#{PORT}")
    result = client.new_reservation("test", nil)
    client.delete_reservation( result["reservation_number"] )
  end

  def test_open_reservation
    client = ResCtrlClient::new("http://localhost:#{PORT}")
    result = client.open_reservation("test", RESERVATION_ID)
    result = client.reservation_info(result["reservation_number"])
    assert( RESERVATION_ID == result["id"] )
  end

  def test_reservation_resources
    client = ResCtrlClient::new("http://localhost:#{PORT}")
    result = client.new_reservation("test", nil)
    client.reservation_wait(result["reservation_number"],1,0)
    result = client.reservation_resources(result["reservation_number"])
    assert ( RESOURCES == result["resources"] )
  end

  def test_reservation_jobs
    client = ResCtrlClient::new("http://localhost:#{PORT}")
    result = client.new_reservation("test", nil)
    client.reservation_wait(result["reservation_number"],1,0)
    result = client.reservation_jobs(result["reservation_number"])
    assert ( JOBS == result["jobs"] )
  end

  def test_reservation_job
    client = ResCtrlClient::new("http://localhost:#{PORT}")
    result = client.new_reservation("test", nil)
    client.reservation_wait(result["reservation_number"],1,0)
    result = client.reservation_job(result["reservation_number"],"zozo",nil)
    assert ( ["foo","bar"] == result["nodes"] )
  end

  def test_reservation_stats
    client = ResCtrlClient::new("http://localhost:#{PORT}")
    result = client.reservation_stats("test", nil)
    assert ( STATS == result["stats"] )
  end

end
