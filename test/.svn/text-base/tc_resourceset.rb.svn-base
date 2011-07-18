#!/usr/bin/ruby -w

[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }

require 'resourceset'
require 'test/unit'
require 'yaml'

class ResourceSetTest < Test::Unit::TestCase

  def test_yaml
          res = YAML::load_file("resource_set2.yaml")
  end
  
  def test_select
          resources = YAML::load_file("resource_set2.yaml")
          r1 = resources.select(:node, {:name => "tutu"})
          r2 = resources.select(:node, {:name => lambda { |x| x=="tutu" } } )
          assert( YAML::dump(r1) == YAML::dump(r2) )
          assert( r1 == r2 )
          assert( !(r1 != r2 ) )
          r1 = resources.select(:node, {:name => "titi"})
          r2 = resources.select(:node, {:name => lambda { |x| x=="tutu" } } )
          assert( YAML::dump(r1) != YAML::dump(r2) )
          assert(  !( r1 == r2 ) )
          assert( r1 != r2 )
  end

  def test_flatten
          resources = YAML::load_file("resource_set2.yaml")
          r1 = resources.select(:node, {:name => "tutu"}).flatten(:node)
          r2 = resources.flatten(:node).select(:node, {:name => "tutu"})
          assert( YAML::dump(r1) == YAML::dump(r2) )
          assert( r1 == r2 )
  end

  def test_iterator
          resource_set = YAML::load_file("resource_set2.yaml")
          it = ResourceSetIterator::new(resource_set,:node)
          count = 0
          while it.resource do
                  #puts YAML::dump(it.resource)
                  it.next
                  count += 1
          end
          assert( count == 2 )
          it = ResourceSetIterator::new(resource_set,:node)
          assert( it.resource == resource_set.resources[0] )
          it.next
          assert( it.resource == resource_set.resources[1].resources[0] )
          it = ResourceSetIterator::new(resource_set,:resource_set)
          assert( it.resource == resource_set.resources[1] )
  end

  def test_each
          resource_set = YAML::load_file("resource_set2.yaml")
          count = 0
          resource_set.each(:node) { |n|
                  name = n.properties[:name]
                  assert( (( name=="titi" ) or ( name =="tutu" )) )
                  count += 1
          }
          assert(count == 2)
          count = 0
          resource_set.each(:resource_set) { |s|
                  name = s.properties[:name]
                  assert( name=="tata" )
                  count += 1
          }
          assert(count == 1)
  end

  def test_uniq
          resource_set = YAML::load_file("resource_set2.yaml")
          resource_set.resources.push(Resource::new(:node, { :name => "titi" } ) )
          rs2 = resource_set.select( :node, { :name => "titi" } )
          count = 0
          rs2.each(:node) { |n|
                  count += 1
          }
          assert(count == 2)
          rs2 = resource_set.uniq.select( :node, { :name => "titi" } )
          count = 0
          rs2.each(:node) { |n|
                  count += 1
          }
          assert(count == 1)
  end

  def test_make_taktuk_command
          resource_set = YAML::load_file("resource_set3.yaml")
          assert( resource_set.make_taktuk_command("date") == " -m tyty -[ -m tutu -[ -m tutu downcast exec [ date ] -] -] -m tyty -[ -m titi downcast exec [ date ] -]")
  end

end
