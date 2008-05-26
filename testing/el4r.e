#######
#
# E-scripts about el4r.
#
#######

# (eeindex)
## INDEX
## (to "lisp")
## (to "test about define-derived-mode")
## (to "test-derived")
## (to "test about autoload")
## (to "el4r-mode-with-ruby-mode")
## (to "el4r-mode-without-ruby-mode")
## (to "test about after-init-hook / ruby-mode")
## (to "after-init-hook-test")
## (to "%s")

 (eevnow "cd ~/src/el4r")

#### lisp
#
# (eeb-el4r)
prc = lambda{ ["1","2"] }
defun(:fx, :interactive=>prc){|x,y| message x.class.inspect}
call_interactively :fx
fx(1)
fx(1,2)
#

;;
;; (eeb-eval)
(defun fgg (x)
  (interactive (eval '(list 1)))
  (message "%d" x))
(call-interactively 'fgg)
;;

;;
;; (eeb-eval)
(defun fgh (x)
  (interactive (list "1"))
  (message x))
(call-interactively 'fgh)
;;


#
# (eeb-el4r)

#


#### test about define-derived-mode
# (view-fline "/log/el4rlog")

# define_derived_mode  OK
 (eevnow-at "test-derived")
 (eech "xmake-garbage\n")
xbar-mode
 (eech "xkill-emacs\n")

# with NG!
 (eevnow-at "test-derived")
 (eech "xmake-garbage\n")
xfoo-mode
 (eech "xkill-emacs\n")



#
# test-derived
# (eevnow-bounded)
cd ~/src/el4r
<<'%%%' > $EERUBY
el4r_rubyobj_stock.gc_trigger_count = 10
el4r_rubyobj_stock.gc_trigger_increment = 20


require 'bell'
class << el4r_rubyobj_stock
    def pre_gc_hook
      message "gc start (#{@oid_to_obj_hash.keys.length})"
    end

    def post_gc_hook
      message "gc end (#{count_of_stocked_objects})"
    end
end

$passed = 0
with(:define_derived_mode, el(:foo_mode), el(:fundamental_mode), "Foo") do
  $passed += 1
end

define_derived_mode(:bar_mode, :fundamental_mode, "Bar") do
  $passed += 1000
end

defun(:make_garbage, :interactive=>true) do
  10.times {
    el4r_lisp_eval(el4r_ruby2lisp(Object.new))
  }
end


self.el4r_is_debug = true

%%%
el4r -r. -l /log/el4rlog  $EERUBY
#


#### test about autoload
 (eevnow-at "el4r-mode-with-ruby-mode")
 (eech "xkill-emacs\n")

 (eevnow-at "el4r-mode-without-ruby-mode")
xlanghelp
 (eech "print-length\C-f")
 (eech "l")
 (eech "xkill-emacs\n")


#
# el4r-mode-with-ruby-mode
cd ~/src/el4r
<<'%%%' > $EERUBY
el4r_process_autoloads
add_to_list :load_path, "~/emacs/lisp"
el4r_lisp_eval %((autoload 'ruby-mode "ruby-mode" "" t)) # '
ruby_mode
el4r_mode
%%%
el4r -r. $EERUBY
#

#
# el4r-mode-without-ruby-mode
cd ~/src/el4r
<<'%%%' > $EERUBY
el4r_process_autoloads
# el4r_mode
%%%
el4r -r. $EERUBY
#


#### test about after-init-hook / ruby-mode
 (eevnow-at "after-init-hook-test")
pseudo-home
invoke-emacs
 (eech "\exel4r-mode\n")
 (eech "\exkill-emacs\n")
invoke-emacs-without-ruby-mode
 (eech "\exkill-emacs\n")
restore-home


#
# after-init-hook-test
cd ~/src/el4r

pseudo-home () {
tmpdir
oldhome=$HOME
export HOME=`pwd`
}

restore-home () {
export HOME=$oldhome
tmpdir-clean
}

invoke-emacs () {
el4r-rctool -p ; el4r-rctool -i; cp -a /home/rubikitch/.langhelp/ .; 

<<'%%%' > ~/.emacs
(add-to-list 'load-path "/home/rubikitch/src/el4r/data/emacs/site-lisp/")
(add-to-list 'load-path "/home/rubikitch/emacs/lisp")

(add-to-list 'load-path "/tmp/tmpdir00/elisp")
(require 'el4r)
;; suppress loading ~/.el4r/init.rb
(el4r-boot t)
(el4r-ruby-eval "el4r_process_autoloads")

%%%

emacs -nw -no-site-file
}

invoke-emacs-without-ruby-mode () {
el4r-rctool -p ; el4r-rctool -i; cp -a /home/rubikitch/.langhelp/ .; 

<<'%%%' > ~/.emacs
(add-to-list 'load-path "/home/rubikitch/src/el4r/data/emacs/site-lisp/")

(add-to-list 'load-path "/tmp/tmpdir00/elisp")
(require 'el4r)
;; suppress loading ~/.el4r/init.rb
(el4r-boot t)
(el4r-ruby-eval "el4r_process_autoloads")

%%%

emacs -nw -no-site-file
}


#

cons cell
# (eeel4r "el4r_prin1_to_string(cons(1,2))")
# (eeel4r "cons(1,2).inspect")
# (nth 0 '(1 2))
# (nth 1 '(1 2))
# (cdr '(1 2))

# (nth 0 '(1 . 2))
# (nth 1 '(1 . 2))
# (cdr '(1 . 2))
# '(1 2 . 3)

# (eeel4r "list(1,2,cons(3,4)).inspect")
# (eeel4r "list(1,2,cons(3,4))")
# (eeel4r "cons(1,cons(2,3))")
# (eeel4r "cons(1,cons(2,3)).inspect")
# (cons 1 (cons 2 3 ))
# (el4r-list-to-rubyary (cons 1 (cons 2 3 )))
# (el4r-list-to-rubyary (list 2 3 ))
# (mapconcat 'el4r-lisp2ruby '(1 2) ", ")
# (mapconcat 'el4r-lisp2ruby '(1 . 2) ", ")
# (mapconcat 'el4r-lisp2ruby '(1 2 . 3) ", ")
# (listp '(1 2 . 3))
# (length '(1 2 . 3))
# (safe-length '(1 2 . 3))
# (nthcdr 2 '(1 2 . 3))
# '(1 2 3 . 4)
# (list 1 2 (cons 3 4))
# (eeel4r "el4r_lisp_eval(%!'(1 2 . 3)!).inspect")
# (car '(1 2 . 3))
# (cdr '(1 2 . 3))

pymacs-proper-list-p: nil, proper-list OK / cons NG

# (pymacs-proper-list-p nil)
# (pymacs-proper-list-p '(1 2))
# (pymacs-proper-list-p '(1 . 2))
# (pymacs-proper-list-p '(1 2 . 3))

# (last '(1 2))
# (last '(1 2 . 3))





Local Variables:
truncate-lines: t
ee-anchor-format: "%s"
End:
