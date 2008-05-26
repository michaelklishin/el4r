el_require :ruby_mode

define_derived_mode(el(:el4r_mode), el(:ruby_mode), "el4r",
                    "Major mode for typing and evaluating Ruby expressions.")

defun(:el4r_mode_eval_line, :interactive => true,
      :docstring => "Execute current line as Ruby code.") {
  el4r_prin1 el4r_ruby_eval(thing_at_point(:line))
}

defun(:el4r_mode_eval_sentence, :interactive => true,
      :docstring => "Execute current sentence as Ruby code.") {
  el4r_prin1 el4r_ruby_eval(thing_at_point(:sentence))
}

defun(:el4r_mode_eval_line_and_print, :interactive => true,
      :docstring => "Execute current line as Ruby code, print value into current buffer.") {
  result = el4r_ruby_eval(thing_at_point(:line))
  newline
  el4r_prin1(result)
  insert_string(el4r_prin1_to_string(result))
  newline
}
self.el4r_is_debug = true
define_key(:el4r_mode_map, '\C-c\C-e', nil)
define_key(:el4r_mode_map, '\C-c\C-e\C-r', :el4r_ruby_eval_region)
define_key(:el4r_mode_map, '\C-c\C-e\C-b', :el4r_ruby_eval_buffer)
define_key(:el4r_mode_map, '\C-c\C-e\C-s', :el4r_mode_eval_sentence)
define_key(:el4r_mode_map, '\C-c\C-e\C-l', :el4r_mode_eval_line)

buf = get_buffer_create("*ruby-scratch*")
with(:with_current_buffer, buf) {
  el4r_mode
  define_key(current_local_map, '\C-j', :el4r_mode_eval_line_and_print)
}
