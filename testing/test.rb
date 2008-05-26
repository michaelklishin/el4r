def assert_fail
  el4r_log(El4r::ErrorUtils.backtrace_message(caller))
  raise("el4r assertion failure.")
end

el4r_lisp_eval(<<'EOF')
  (insert-string (el4r-ruby-eval "\"Hello from ruby from emacs from ruby!\n\""))
EOF
el4r_lisp_eval('t')
insert_string("Hello from ruby!\n")

list = el("'(3 2 1)")
list = cons(4, list)
insert_string(prin1_to_string(list)); newline

ary = []
while list
  ary << car(list)
  list = cdr(list)
end
insert_string(ary.inspect); newline

obj = Object.new
insert_string("Is ruby object passed? ... #{car(cons(obj, nil)) == obj}")
newline

# Using defun ( Proc -> Lambda conversion )
defun(:my_ruby_func) { |a|
  insert_string("String from my_ruby_func: '#{a}'"); newline
}
my_ruby_func("Hello!")

defun(:my_command, :interactive => true) {
  insert_string("My Interactive command from Ruby."); newline
}
call_interactively(:my_command)

defun(:my_command2,
      :interactive => "d", :docstring => "description...") { |point|
  insert_string("Current point is #{point}."); newline
}
nth(1, commandp(:my_command2)) == "d" or assert_fail
documentation(:my_command2) == "description..." or assert_fail
call_interactively(:my_command2)


# Calling lambda
lambda = el4r_lisp_eval("(lambda (i) (+ i 1))")
funcall(lambda, 1) == 2 or assert_fail

# Calling special form like save-excursion
with(:save_excursion) {
  beginning_of_buffer
  insert_string("This is inserted at the beginning of buffer."); newline
}

# ELListCell
cons(1, cons(2, nil)).to_a == [1, 2] or assert_fail

# Accessing to lisp variables with elvar
elvar.myvar = 123
123 == elvar.myvar or assert_fail

# Lisp object GC
100.times {
  el4r_lisp_eval("(cons nil nil)")
}
hash_table_count(el(:el4r_lisp_object_hash)) < 100 or assert_fail
getq(:el4r_lisp_object_gc_trigger_count) > 100 or assert_fail
insert_string("Okay, GC of lisp objects works well!"); newline

# Ruby object GC
100.times {
  el4r_lisp_eval(el4r_ruby2lisp(Object.new))
}
el4r_rubyobj_stock.count_of_stocked_objects < 100 or assert_fail
el4r_rubyobj_stock.gc_trigger_count > 100 or assert_fail
insert_string("Okay, GC of Ruby objects works well!"); newline

# Error passing
begin
  el4r_lisp_eval(<<-'EOF')
    (el4r-ruby-eval "raise \"Is error handled correctly?\""))
  EOF
  raise("Oh, no!")
rescue RuntimeError
end

# let
elvar.testval = 12
testval_in_letblock = nil
let(:testval, 24) {
  testval_in_letblock = elvar.testval
}
testval_in_letblock == 24 or assert_fail
elvar.testval == 12 or assert_fail
insert_string("Ok, let form works well."); newline
