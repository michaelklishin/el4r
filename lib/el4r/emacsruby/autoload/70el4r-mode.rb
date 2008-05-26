eval_after_load("ruby-mode") do
  el4r_load "el4r-mode.rb"
end

defun(:el4r_mode__after_init_hook) do
  el_require :ruby_mode if locate_library "ruby-mode"
end

add_hook :after_init_hook, :el4r_mode__after_init_hook
