#!/usr/bin/env ruby
require 'tmpdir'
require 'test/unit'

# This test must be performed separately
class TestGC < Test::Unit::TestCase

  def setup
    el4r_rubyobj_stock.gc_trigger_count = 100
    el4r_rubyobj_stock.gc_trigger_increment = 100
    elvar.el4r_lisp_object_gc_trigger_count = 100
    elvar.el4r_lisp_object_gc_trigger_increment = 200
  end

  # Lisp object GC
  def test_lispGC
#     message(hash_table_count(el(:el4r_lisp_object_hash)))
#     message(getq(:el4r_lisp_object_gc_trigger_count))
    100.times {
      el4r_lisp_eval("(cons nil nil)")
    }
#     message(hash_table_count(el(:el4r_lisp_object_hash)))
#     message(getq(:el4r_lisp_object_gc_trigger_count))

    assert( hash_table_count(el(:el4r_lisp_object_hash)) < 100 )
    assert( getq(:el4r_lisp_object_gc_trigger_count) > 100 )
  end

  class Foo < ElApp
    def initialize(x={})
      defun(:f){zero}
    end
    def zero
      0
    end
  end
  
  # Ruby object GC
  def test_rubyGC
    Foo.run
    100.times{
      el4r_lisp_eval(el4r_ruby2lisp(Object.new))
    }
    GC.start
    funcall(:garbage_collect)
    funcall(:garbage_collect)
    funcall(:garbage_collect)
    assert( el4r_rubyobj_stock.count_of_stocked_objects < 100, "count_of_stocked_objects=#{el4r_rubyobj_stock.count_of_stocked_objects}" )
    assert( el4r_rubyobj_stock.gc_trigger_count > 100 )

    assert_equal(0, f)
    funcall(:garbage_collect)
    funcall(:garbage_collect)
    el4r_rubyobj_stock.garbage_collect

    oid2obj = el4r_rubyobj_stock.instance_variable_get(:@oid_to_obj_hash)
    alive_ids = oid2obj.keys
    el4r_log(alive_ids.map{|id| "#{id}:#{oid2obj[id].class}"}.join("\n"))
    begin
      open(File.join(Dir.tmpdir,"el4r-idlst"),"w") {|f|
        f.puts alive_ids
      }
    rescue
    end
  end  

  # Interactive and GC
  # (view-diary "2006-02-24" -1)
  def test_interactive
    defun(:itest, :interactive=>lambda{[1]}){|x| x}
    el4r_garbage_collect
    assert_equal(1, call_interactively(:itest))
  end

  def test_define_key
    define_key(:global_map, "\C-c\C-x") { 1 }
    el4r_garbage_collect
    assert_equal(1, call_interactively(key_binding "\C-c\C-x"))
  end

end
