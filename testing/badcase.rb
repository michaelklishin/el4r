#!/usr/bin/env ruby
require 'test/unit'

class Foo
  include ElMixin

  def foo
    bar
  end

  def bar
    baz
  end

  def baz
    el{
      point
      hoge                   # LispError
    }
  end
end


class TestEl4rBadCase < Test::Unit::TestCase
  include ElMixin

  def setup
  end

  def teardown

  end

  def test_1
    el {
      with(:with_current_buffer, "*scratch*"){
        buffer_string 1
      }
    }
  end

  def test_2
    el {
        buffer_string 1
    }
  end



end
