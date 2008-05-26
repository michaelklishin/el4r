#    el4r - EmacsLisp for Ruby 
#    Copyright (C) 2005 rubikitch <rubikitch@ruby-lang.org>
#    Version: $Id: test-el4r.rb 1328 2006-08-14 21:10:57Z rubikitch $

#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require 'test/unit'

require 'tempfile'
require 'tmpdir'
require 'pathname'
require 'fileutils'
class << Tempfile
  def path(content, dir=Dir.tmpdir)
    x = Tempfile.open("content", dir)
    x.write content
    x.close
    x.open
    x.path
  end

  def pathname(content, dir=Dir.tmpdir)
    Pathname.new(path(content, dir=Dir.tmpdir))
  end
end


# El4r self test.
## (eevnow "cat `buffer-file-name` | awk '/  def test_/{print $2}'|result-long")
class TestEl4r < Test::Unit::TestCase
  # ElMixin is already included/extended.
  # So we can write EmacsRuby in this class.

  # Testing ELListCell#to_ary.
  # This method enables us to multiple assignment.
  def test_to_ary
    list = el4r_lisp_eval(%q((list 1 2)))
    one, two = list

    assert_equal(list.to_a, list.to_ary)
    assert_equal(1, one)
    assert_equal(2, two)
  end

  # Testing with and match-string.
  def test_match_string
    lisp = %q((progn
                (switch-to-buffer "a")

              (save-excursion
                (insert "abcdefg\n")
                (goto-char 1)
                (re-search-forward "^\\\\(.+\\\\)$")
                )
              (match-string 1)))

    ruby = lambda{
##### [with]
      with(:save_excursion) do
        goto_char 1
        re_search_forward('^\\(.+\\)$')
      end
      match_string 1
##### [/with]
    }
    assert_equal(el4r_lisp_eval(lisp), ruby[])

  end


  # helper method:
  # execute a block with temporary buffer.
  # and return the contents of buffer.
  def with_temp_buffer_string(&block)
    with(:with_temp_buffer){
      self.instance_eval(&block)
      buffer_string
    }
  end

  # this test was in test.el
  def test_test_el__debug_ruby_eval_report
    actual = with_temp_buffer_string {
      el4r_lisp_eval %q((progn
(el4r-debug-ruby-eval-report "nil")
(el4r-debug-ruby-eval-report "true")
(el4r-debug-ruby-eval-report "false")
(el4r-debug-ruby-eval-report "1 + 6")
(el4r-debug-ruby-eval-report "\"String\"")
))
    }
    expected = <<EOB
nil
  => nil
true
  => t
false
  => nil
1 + 6
  => 7
"String"
  => "String"
EOB
    assert_equal(expected, actual)
  end

  def test_test_el__condition_case

    # (mode-info-describe-function 'signal 'elisp)
    # (mode-info-describe-function 'condition-case 'elisp)
    el4r_lisp_eval %q((progn
(put 'test-error
     'error-conditions                        
     '(error test-error))
(put 'test-error 'error-message "Test Error")
    ))
    #'
    el4r_lisp_eval %q((progn
(setq error-desc nil)
(condition-case err
    (signal 'test-error '(123))
  (test-error (setq error-desc (format "Error is passed: %s" err)))
  )
))
    #'
    assert_equal("Error is passed: (test-error 123)", elvar.error_desc)

    el4r_lisp_eval %q((progn
(setq error-desc nil)
(condition-case err
    (el4r-ruby-eval "el4r_lisp_eval(\"(signal 'test-error '(123))\")")
  (test-error (setq error-desc (format "Error is passed: %s" err)))
  )
))
    #'
    assert_equal("Error is passed: (test-error 123)", elvar.error_desc)
  end

  # eval test
  def test_el4r_eval
    result = with_temp_buffer_string{
      el4r_lisp_eval(<<'EOF')
        (insert-string (el4r-ruby-eval "\"Hello from ruby from emacs from ruby!\n\""))
EOF
    }
    assert_equal("Hello from ruby from emacs from ruby!\n", result)
    assert_equal(true, el4r_lisp_eval('t'))
  end


  # list: cons, car/cdr
  def test_list
    list = el("'(3 2 1)")
    list = cons(4, list)
    assert_equal("(4 3 2 1)", prin1_to_string(list))

    ary = []
    while list
      ary << car(list)
      list = cdr(list)
    end
    assert_equal("[4, 3, 2, 1]", ary.inspect)
  end

  # pass a Ruby object to Emacs
  def test_object
    obj = Object.new
    assert_equal("Is ruby object passed? ... true",
                 "Is ruby object passed? ... #{car(cons(obj, nil)) == obj}")
  end    

  

  # Using defun ( Proc -> Lambda conversion )
  def test_defun_function
    defun(:my_ruby_func) { |a|
      0
    }
    # redefine
    defun(:my_ruby_func) { |a|
      "String from my_ruby_func: '#{a}'"
    }
    assert_equal("String from my_ruby_func: 'Hello!'", my_ruby_func("Hello!"))
  end

  # defun a command
  def test_defun_command_1
    defun(:my_command, :interactive => true) {
      insert_string("My Interactive command from Ruby."); newline
    }

    assert_equal("My Interactive command from Ruby.\n",
                 with_temp_buffer_string{ call_interactively(:my_command) })

  end

  # defun a command with docstring
  def test_defun_command_2
##### [my_command2]
    defun(:my_command2,
          :interactive => "d", :docstring => "description...") { |point|
      insert_string("Current point is #{point}."); newline
    }
##### [/my_command2]
    assert_equal("d", nth(1, commandp(:my_command2)))
    assert_equal("description...", documentation(:my_command2))
    assert_equal("Current point is 1.\n",
                 with_temp_buffer_string{ call_interactively(:my_command2) })
  end

  # defun a command with lambda
  def test_defun_command_3
    sum = nil
##### [my_command3]
    interactive_proc = lambda { [1+1, 1] }
    defun(:my_command3,
          :interactive => interactive_proc) { |a, b|
      sum = a + b
    }
##### [/my_command3]
    assert_equal nil, sum
    call_interactively :my_command3
    assert_equal 3, sum
  end

  # defining odd-named function
  def test_defun_oddname
    # Lisp can define `1+1' function! LOL
    defun("1+1"){2}
    assert_equal(2, funcall("1+1"))
  end

  # Calling lambda
  def test_lambda
    lambda = el4r_lisp_eval("(lambda (i) (+ i 1))")
    assert_equal(2, funcall(lambda, 1))
  end

  # Calling special form like save-excursion
  def test_with
    x = with_temp_buffer_string {
      insert_string("a\n")
      with(:save_excursion) {
        beginning_of_buffer
        insert_string("This is inserted at the beginning of buffer."); newline
      }
    }
    assert_equal("This is inserted at the beginning of buffer.\na\n", x)
  end

  # ELListCell
  def test_ELListCell
    assert_equal([1, 2], cons(1, cons(2, nil)).to_a )
    assert_equal([10,20], el4r_lisp_eval(%((list 1 2))).map{|x| x*10})

    assert_equal({'a'=>1, 'b'=>2}, list(cons("a",1), cons("b", 2)).to_hash)
    assert_raises(TypeError){ list(cons("a",1), "b", "c").to_hash }

    assert_equal("ELListCell[1]", list(1).inspect)
    assert_equal("ELListCell[1, 2]", list(1,2).inspect)
  end
  
  # ELConsCell
  def test_ELConsCell
    assert_equal([1,2], el4r_cons_to_rubyary(cons(1,2)))
    assert_equal("ELConsCell[1, 2]", cons(1,2).inspect)

    assert_equal("ELListCell[1, 2, ELConsCell[3, 4]]", list(1,2,cons(3,4)).inspect)
    assert_equal("ELListCell[1, 2]", cons(1, list(2)).inspect)
  end

  # ELVector
  def test_ELVector
    v = el4r_lisp_eval("[1 2]")
    assert( vectorp(v) )
    assert_equal("ELVector[1, 2]", v.inspect)
    assert_equal(1, v[0])
    assert_equal(1, v[-2])
    assert_raises(ArgumentError) { v[2] } # index is too large
    assert_raises(TypeError) { v["X"] }

    assert_equal([1, 2], v[0,2])
    assert_equal([1, 2], v.to_a)

    # Enumerable
    assert_equal(1, v.find{|x| x==1})

    # to_ary
    one, = v
    assert_equal(1, one)

    # aset
    elvar.v = v
    assert_equal(10, v[0]=10)
    assert_equal(10, v[0])
    assert_equal([10,2], v.to_a)
    assert_equal(10, elvar.v[0])
    assert_equal([10,2], elvar.v.to_a)
    assert_raises(ArgumentError) { v[2]=3 } # index is too large
    assert_raises(TypeError) { v["X"]=1 }

    v[-1]=20
    assert_equal([10,20], elvar.v.to_a)
  end

  # Accessing to lisp variables with elvar
  def test_elvar
    elvar.myvar = 123
    assert_equal(123, elvar.myvar)

    elvar["myvar"] = 456
    assert_equal(456, elvar["myvar"])
    
    assert( elvar.myvar == elvar["myvar"] )
  end

  # get/set an odd-named variable
  def test_elvar__oddname
    elvar["*an/odd+variable!*"] = 10
    assert_equal(10, elvar["*an/odd+variable!*"])
  end

  # Error passing
  def test_error
    assert_raises(RuntimeError) {
      el4r_lisp_eval(<<-'EOF')
        (el4r-ruby-eval "raise \"Is error handled correctly?\""))
      EOF
    }
  end

  # let
  def test_let
    elvar.testval = 12
    testval_in_letblock = nil
    let(:testval, 24) {
      testval_in_letblock = elvar.testval
    }

    assert_equal(24, testval_in_letblock)
    assert_equal(12, elvar.testval)
  end

  # Regexp convert: Convert Ruby regexps to MESSY Emacs regexps.
  def test_regexp
#  (find-node "(emacs-ja)Regexps")
    
    conv = lambda{|from,to| assert_equal(to, el4r_conv_regexp(from)) }
    conv[ //, '' ]
    conv[ /a/, 'a' ]
    conv[ /a./, 'a.' ]
    conv[ /a*/, 'a*' ]
    conv[ /a+/, 'a+' ]
    conv[ /a?/, 'a?' ]
    conv[ /[ab]/, '[ab]' ]
    conv[ /[^ab]/, '[^ab]' ]
    conv[ /^ab/, '^ab' ]
    conv[ /ab$/, 'ab$' ]
    conv[ /a|b/, 'a\|b' ]
    conv[ /(ab)/, '\(ab\)' ]
    conv[ /\As/, '\`s' ]
    conv[ /s\Z/, %q[s\'] ]
    # \=
    conv[ /\bball\B/, '\bball\B']
    # \<
    # \>
    conv[ /\w/, '[0-9A-Za-z_]']
    conv[ /\W/, '[^0-9A-Za-z_]']
    # \sC
    # \SC
    # \D (number)
  end

  # Now you can specify a Ruby regexp to string-match, re-search-forward and so on
  def test_string_match
    s = "a"
    assert_equal(0, string_match("a", s))
    assert_equal(0, string_match(/a/, s))
    assert_equal(0, string_match('\(a\|\b\)', s))
    assert_equal(0, string_match(/a|b/, s))
    assert_equal(0, string_match(/^a/, s))
    assert_equal(0, string_match(/a$/, s))
    assert_equal(0, string_match(/.*/, s))
    assert_equal(nil, string_match(/not-match/, s))
    
  end

  # ElMixin: elisp {}
  def test_elmixin
    eval %{
      class ::Foo
        include ElMixin
        def foo
          elisp {
            [self.class, outer.class]
          }
        end

        def one
          1
        end
      end

    }

    el4r, outer = Foo.new.foo
    assert_equal(El4r::ELInstance, el4r)
    assert_equal(Foo, outer)
  end

  # EL error
  def test_elerror
    errormsg = nil
    begin
      el4r_lisp_eval(%q((defun errorfunc0 ())))
      with(:with_current_buffer, "*scratch*"){
        let(:x, 1) {
          with(:save_excursion){
            errorfunc0 1       # wrong number of argument!!
          }
        }
      }
      flunk
    rescue
      errormsg = $!.to_s
    end

    assert_match(/\n\(errorfunc0.+save-excursion.+let.+with-current-buffer.+$/m, errormsg.to_s) 
  end

  # to_s: Implicitly call prin1_to_string
  def test_to_s
    list = funcall(:list,1)
    assert_equal("(1)", "#{list}")
    assert_equal( prin1_to_string(list), list.to_s)
  end

  # defadvice 1
  def test_defadvice_1
    defun(:adtest1){
      elvar.v = 1
    }
    with(:defadvice, el("adtest1 (after adv activate)")){
      elvar.v = 2
    }
    adtest1

    assert_equal(2, elvar.v)
  end

  # defadvice 2
  def test_defadvice_2
    elvar.w = 0
    elvar.x = 0
    defun(:adtest_2){
      elvar.w += 1
      3
    }
    defadvice(:adtest_2, :around, :adv2, :activate) {
      ad_do_it
      elvar.x = 10
      ad_do_it
    }
    ret = adtest_2()

    assert_equal(2, elvar.w)
    assert_equal(10, elvar.x)
    assert_equal(3, ret)
  end

  # defadvice 3
  def test_defadvice_3
    begin
##### [adtest3]
      # define a function
      defun(:adtest3){ 1 }
##### [/adtest3]
      assert_equal(1, adtest3())
      assert_equal(nil, commandp(:adtest3))

##### [adtest3-advice]
      # now define an advice
      defadvice(:adtest3, :around, :adv3, :activate,
                :docstring=>"test advice", :interactive=>true) {
        ad_do_it
        elvar.ad_return_value = 2
      }
##### [/ad_return_value]
      assert(commandp(:adtest3))
      assert_equal(2, adtest3())
      assert_match(/test advice/, documentation(:adtest3))
    ensure
      ad_deactivate :adtest3
#      fmakunbound :adtest3
    end
  end

  # bufstr
  def test_bufstr
    s = bufstr(newbuf(:name=>"axx", :contents=>"foo!"))
    assert_equal("foo!", s)

    newbuf(:name=>"axxg", :contents=>"bar!", :current=>true)
    s = bufstr 
    assert_equal("bar!", s)
  end

  def xtest_ad_do_it_invalid
    assert_raises(El4r::El4rError){
      ad_do_it
    }
  end

  # el_load
  def test_el_load
    begin
      el = File.expand_path("elloadtest.el")
      open(el, "w"){|w| w.puts(%q((setq elloadtest 100)))}
      el_load(el)
      assert_equal(100, elvar.elloadtest)
    ensure
      File.unlink el
    end
  end

  # equality
  def test_EQUAL
    b1 = current_buffer
    b2 = current_buffer
    assert(b1 == b1)
    assert(b1 == b2)
    assert_equal(b1,b2)
  end

  # test delete-other-windows workaround in xemacs
  def test_delete_other_windows
    w = selected_window
    elvar.window_min_height = 1
    split_window
    split_window 
    delete_other_windows
    assert(one_window_p)
    assert(eq(w, selected_window))
  end

  # Lisp string -> Ruby string  special case
  def test_el4r_lisp2ruby__normal
    cmp = lambda{|str| assert_equal(str, eval(el4r_lisp2ruby(str)))}
# (mode-info-describe-function 'prin1-to-string 'elisp)
# (string= "\021" (el4r-ruby-eval (el4r-lisp2ruby "\021")))

    cmp[ "" ]
    cmp[ "a"*9999 ]
    cmp[ '1' ]
    cmp[ 'a' ]
    cmp[ '\\' ]
    cmp[ '\\\\' ]
    cmp[ '\\\\\\' ]
    cmp[ '""' ]
    cmp[ '"' ]
    cmp[ "''" ]
    cmp[ '#{1}' ]
    cmp[ '\#{1}' ]
    cmp[ '#{\'1\'}' ]
    cmp[ '#@a' ]
    cmp[ "\306\374\313\334\270\354" ]  # NIHONGO in EUC-JP
  end

  def test_el4r_lisp2ruby__treat_ctrl_codes
    cmp = lambda{|str| assert_equal(str, eval(el4r_lisp2ruby(str)))}
    elvar.coding_system_for_write :binary
    elvar.coding_system_for_write :binary
    set_buffer_file_coding_system :binary
    el4r_treat_ctrl_codes { 
      cmp[ "" ]
      cmp[ "a"*9999 ]
      cmp[ '1' ]
      cmp[ 'a' ]
      cmp[ '\\' ]
      cmp[ '\\\\' ]
      cmp[ '\\\\\\' ]
      cmp[ '""' ]
      cmp[ '"' ]
      cmp[ "''" ]
      cmp[ '#{1}' ]
      cmp[ '\#{1}' ]
      cmp[ '#{\'1\'}' ]
      cmp[ '#@a' ]

      cmp[ "\ca" ]
      cmp[ "\cb" ]
      cmp[ "\cc" ]
      cmp[ "\cd" ]
      cmp[ "\ce" ]
      cmp[ "\cf" ]
      cmp[ "\cg" ]
      cmp[ "\ch" ]
      cmp[ "\ci" ]
      cmp[ "\cj" ]
      cmp[ "\ck" ]
      cmp[ "\cl" ]
      # C-m
      # cmp[ "\cn" ]  failed on xemacs
      # cmp[ "\co" ]  failed on xemacs
      cmp[ "\cp" ]
      cmp[ "\cq" ]
      # C-r
      cmp[ "\cs" ]
      cmp[ "\ct" ]
      cmp[ "\cu" ]
      cmp[ "\cv" ]
      cmp[ "\cw" ]
      cmp[ "\cx" ]
      # cmp[ "\cy" ]
      cmp[ "\cz" ]
      cmp[ "\306\374\313\334\270\354" ]  # NIHONGO in EUC-JP
    }
  end

  
  def el4r_load_test_helper(dir)
    begin
      $loaded = nil
      tmpscript = "#{dir}/__testtmp__.rb"
      "$loaded = true".writef(tmpscript)
      el4r_load "__testtmp__.rb"
      assert_equal(true, $loaded)
    ensure
      FileUtils.rm_f tmpscript
    end
  end

  def test_el4r_load__load_path
    begin
      load_path_orig = el4r.conf.el4r_load_path
      tmp = Dir.tmpdir
      load_path = [ tmp, "#{tmp}/a" ]
      el4r.conf.el4r_load_path = load_path
      load_path.each do |dir|
        FileUtils.mkdir_p dir
        el4r_load_test_helper dir
      end
    ensure
      el4r.conf.el4r_load_path = load_path_orig
      FileUtils.rm_rf "#{tmp}/a"
    end
    
  end

  def test_el4r_load__not_exist
    assert_raises(LoadError) { el4r_load "__not_exist.rb" }
    assert_equal(false,  el4r_load("__not_exist.rb", true))
  end

  def test_el4r_load__order
    begin 
      $loaded = nil
      load_path = el4r.conf.el4r_load_path = [ el4r_homedir, el4r.site_dir ]
      FileUtils.mkdir_p load_path
      rb = "__testtmp__.rb"
      home_rb = File.expand_path(rb, el4r_homedir)
      site_rb = File.expand_path(rb, el4r.site_dir)
      "$loaded = :OK".writef(home_rb)
      "$loaded = :NG".writef(site_rb)
      el4r_load rb
      assert_equal(:OK, $loaded)
    ensure
      FileUtils.rm_f [home_rb, site_rb]
    end
  end

  def test_stdlib_loaded
    assert_equal(true, fboundp(:winconf_push))
  end

  def test_winconf
    # make a winconf
    switch_to_buffer "a buffer"
    insert "string"
    pt = point
    # current_window_configuration does not works with xemacs -batch. I do not know why.
    assert( one_window_p )
    buf = current_buffer

    winconf_push

    # alter the winconf
    goto_char 1
    split_window

    winconf_pop

    # revive the winconf
    assert( one_window_p )
    assert_equal(buf, current_buffer)
    assert_equal(pt, point)
  end

  def test_el4r_output
    printf("\t\n\ca!%s!","a")
    print(1)
    assert_equal("\t\n\ca!a!1", bufstr("*el4r:output*"))
  end

  def test_process_autoloads
    begin
      tmp = Dir.tmpdir
      autoload_dir = "#{tmp}/autoload"
      FileUtils.mkdir_p autoload_dir
      $ary = []
      %w[01first.rb 02second.rb 03third.rb].each_with_index do |fn, i|
        open(File.join(autoload_dir, fn), "w"){|f| f.write "$ary << #{i}" }
      end
      el4r_process_autoloads autoload_dir

      assert_equal [0,1,2], $ary
    ensure
      FileUtils.rm_rf autoload_dir
    end
  end

  def test_eval_after_load
    begin
      tmp = Dir.tmpdir
      add_to_list :load_path, tmp
      el = "#{tmp}/hoge.el"
      open(el, "w"){|f| f.write "(setq hoge 100)" }

      elvar.hoge = 1
      eval_after_load("hoge") do
        elvar.hoge = 200
      end
      assert_equal 1, elvar.hoge

      el_load "hoge"
      assert_equal 200, elvar.hoge
    ensure
      FileUtils.rm_f el
    end
  end

  def test_define_derived_mode
    @passed = false
##### [derived]
    define_derived_mode(:foo_mode, :fundamental_mode, "FOO", "doc") do
      @passed = true
    end
##### [/derived]
    assert_equal false, @passed
    foo_mode
    assert_equal true, @passed
    assert_equal "foo-mode", elvar.major_mode.to_s

    @passed = false
    define_derived_mode("bar-mode", el(:foo_mode), "Bar") do
      @passed = true
    end
    assert_equal false, @passed
    bar_mode
    assert_equal true, @passed

    define_derived_mode("baz-mode", el(:bar_mode), "Baz")
    baz_mode
    assert_equal "baz-mode", elvar.major_mode.to_s

  end

  def test_define_minor_mode
    @passed = false
##### [minor-mode]
    define_minor_mode(:a_minor_mode, "test minor mode") do
      @passed = true
    end
##### [/minor-mode]
    assert_equal false, @passed
    a_minor_mode
    assert_equal true, @passed
    assert_equal true, elvar.a_minor_mode
  end

# end of TestEl4r
end

# newbuf examples
class TestNewbuf < Test::Unit::TestCase
  include ElMixin

  def setup
    @bufname = "buffer-does-not-exist!!!"
  end

  def teardown
    kill_buffer(@bufname) if get_buffer(@bufname)
  end

  def setbuf
    set_buffer @x
  end

  def test_create
    @x = newbuf(:name=>@bufname)
    setbuf
    assert_equal(true, bufferp(@x))
    assert_equal(@bufname, buffer_name(@x))
    assert_equal("", buffer_string)

    y = newbuf(:name=>@bufname)
    assert(eq(@x,y))
  end

  def test_contents
    @x = newbuf(:name=>@bufname, :contents=>"foo")
    setbuf
    assert_equal("foo", buffer_string)
    assert_equal(4, "foo".length+1)
    assert_equal(4, point)

    # buffer is erased
    @x = newbuf(:name=>@bufname, :contents=>"bar")
    setbuf
    assert_equal("bar", buffer_string)
  end

  def test_file
    begin
      file = Tempfile.path("abcd")
      @x = newbuf(:file=>file)
      setbuf
      assert_equal(file, buffer_file_name)
      assert_equal("abcd", buffer_string)
    ensure
      kill_buffer nil
      File.unlink file
    end
  end

  def test_name_and_file
    begin
      file1 = Tempfile.path("abcd")
      @x = newbuf(:name=>@bufname, :file=>file1)
      setbuf
      assert_equal(nil, buffer_file_name)
      assert_equal("abcd", buffer_string)

      # buffer is erased
      file2 = Tempfile.path("abcde")
      @x = newbuf(:name=>@bufname, :file=>file2)
      setbuf
      assert_equal("abcde", buffer_string)
 
    ensure
      kill_buffer nil
      File.unlink file1
      File.unlink file2
    end
  end
    

  def test_argerror
    assert_raises(ArgumentError){ newbuf }
    assert_raises(ArgumentError){ newbuf(:name=>nil) }
    assert_raises(ArgumentError){ newbuf(1) }
    assert_raises(ArgumentError){ newbuf("1") } # hmm.
    assert_raises(ArgumentError){ newbuf(:name=>@bufname, :line=>"a") }
    assert_raises(ArgumentError){ newbuf(:name=>@bufname, :point=>"a") }
  end

  def test_current_line
    @x = newbuf(:name=>@bufname, :contents=>"a\nb\nc\nd", :line=>2)
    setbuf
    assert_equal("b", char_to_string(char_after))
  end

  def test_point
    @x = newbuf(:name=>@bufname, :contents=>"abcde", :point=>2)
    setbuf
    assert_equal("b", char_to_string(char_after))
  end

  def test_display
    elvar.pop_up_windows = true
    @x = newbuf(:name=>@bufname, :display=>true)
    assert(get_buffer_window(@x))
    assert_nil(one_window_p)
    assert_nil(eq(selected_window, get_buffer_window(@x)))
  end

  def test_display_pop
    elvar.pop_up_windows = true
    @x = newbuf(:name=>@bufname, :display=>:pop)
    assert(get_buffer_window(@x))
    assert_nil(one_window_p)
    assert(eq(selected_window, get_buffer_window(@x)))
  end

  def test_display_only
    elvar.pop_up_windows = true
    @x = newbuf(:name=>@bufname, :display=>:only)
    assert(get_buffer_window(@x))
    assert(one_window_p)
    assert(eq(selected_window, get_buffer_window(@x)))
  end

  def test_current
    @x = newbuf(:name=>@bufname, :current=>true)
    assert_nil(get_buffer_window(@x))
    assert(eq(current_buffer, @x))
  end

  def test_read_only
    b1 = newbuf(:name=>@bufname, :current=>true, :read_only=>true, :contents=>"a")
    assert(eq(elvar.buffer_read_only, true))
    assert_equal("a", buffer_string)

    b2 = newbuf(:name=>@bufname, :current=>true, :read_only=>true, :contents=>"c")
    assert(eq(b1,b2))
    assert(eq(elvar.buffer_read_only, true))
    assert_equal("c", buffer_string)
  end

  def test_bury
    buf = newbuf(:name=>@bufname, :display=>:pop, :bury=>true)
    assert(eq(buf, (buffer_list nil)[-1]))
  end

  def test_block
    buf = newbuf(:name=>@bufname, :current=>true) {
      text_mode
    }
    mode = with(:with_current_buffer,buf){elvar.major_mode}.to_s
    assert_equal("text-mode", mode)
  end
end

class TestDefunWithinClass < Test::Unit::TestCase

  class Foo
    include ElMixin

    def initialize(x)
      elvar.v = x[:value]
      defun(:twice_v) do
        elvar.v *= 2
      end

      defun(:str0) do
        do_str0 x[:str]
      end
    end

    def do_str0(str)
      (str*2).upcase
    end
  end

  def test0
    Foo.new(:value=>10, :str=>"ab")
    twice_v
    assert_equal(20, elvar.v)
    assert_equal("ABAB", str0)
  end
end

class TestElApp < Test::Unit::TestCase

##### [ElApp]
  class Foo < ElApp
    def initialize(x)
      elvar.v = x[:value]
      defun(:twice_v) do
        elvar.v *= 2
      end

      defun(:str0) do
        do_str0 x[:str]
      end
    end

    def do_str0(str)
      (str*2).capitalize
    end
  end
##### [/ElApp]

  def test0
    Foo.run(:value=>10, :str=>"ab")
    twice_v
    assert_equal(20, elvar.v)
    assert_equal("Abab", str0)
  end
end

class TestSmartDefun < Test::Unit::TestCase
##### [smart_defun]
  class SmartDefunSample < ElApp
    def my_square(x)
      x*x
    end

    defun(:testdefun, :interactive=>true) do |x|
      # This block is evaluated within a context of the SmartDefunSample INSTANCE.
      # Not a context of the SmartDefunSample class!!
      x ||= 16
      elvar.val = my_square(x)  # call an instance method.
    end
  end
##### [/smart_defun]

  def test_defun
    SmartDefunSample.run
    elvar.val = 0
    testdefun(10)
    assert_equal(100, elvar.val)
    call_interactively(:testdefun)
    assert_equal(256, elvar.val)
  end


  class DefvarSample < ElApp
    defvar(:blah_blah, 2)
    defun(:setblah) {|x| elvar.blah_blah = x }
  end

  def test_blah
    DefvarSample.run
    assert_equal 2, el4r_lisp_eval("blah-blah")
    setblah(20)
    assert_equal 20, el4r_lisp_eval("blah-blah")
  end


  class LispEvalSample < ElApp
    el4r_lisp_eval %((setq lisp-eval-sample 9999))
  end

  def test_lisp_eval_sample
    LispEvalSample.run
    assert_equal 9999, elvar.lisp_eval_sample
  end

end
