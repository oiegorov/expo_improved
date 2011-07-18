#!/usr/bin/ruby -w

[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }

require 'rctrl/rctrl_heap'
require 'test/unit'

include Expo

class HeapTest < Test::Unit::TestCase

  @@n = 500

  def test_insert_shift
    tas = Heap::new
    a = Array::new
    0.upto(@@n) {
      a.push(rand)
    }
    0.upto(@@n) {
      |i|
      tas.insert(a[i])
    }
    a.sort!
    0.upto(@@n) {
      |i|
      assert_equal( a.shift , tas.shift )
    }
    assert_nil(tas.shift)
  end

  def test_first
    tas = Heap::new
    0.upto(@@n) {
      tas.insert(rand)
    }
    0.upto(@@n) {
      assert_equal( tas.first , tas.shift )
    }
  end

  def test_size
    tas = Heap::new
    0.upto(@@n) {
      tas.insert(rand)
    }
    0.upto(@@n) { |i|
      assert_equal( tas.size , @@n - i + 1)
      tas.shift
    }
  end

  def test_initialize
    tas = Heap::new { |x,y| y <=> x }
    a = Array::new
    0.upto(@@n) {
      a.push(rand)
    }
    0.upto(@@n) {
      |i|
      tas.insert(a[i])
    }
    a.sort! { |x,y| y <=> x }

    0.upto(@@n) {
      |i|
      assert_equal( a.shift , tas.shift )
    }
    assert_nil(tas.shift)
  end

  def test_clear
    tas = Heap::new
    0.upto(@@n) {
      tas.insert(rand)
    }
    tas.clear
    assert_nil(tas.shift)
  end

end
