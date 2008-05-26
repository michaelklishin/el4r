#!/usr/bin/env ruby
#    el4r - EmacsLisp for Ruby 
#    Copyright (C) 2005 rubikitch <rubikitch@ruby-lang.org>
#    Version: $Id: exec-el4r.rb 958 2005-11-30 19:17:42Z rubikitch $

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

require 'optparse'
require 'tmpdir'

def exec_el4r(test_mode=true)
  el4r_root = nil
  shellargs = []
  emacs = nil
  ruby = nil
  unittest_args = []
  strip_instance_error = "t"
  load_path = []
  show_only = false
  init = false

  ARGV.options do |o|
    o.on("-Q", "--init", "load site-start.el and .emacs") { init = true }
    o.on("-b", "--batch", "batch mode"){ shellargs << "-batch" }
    o.on("-i", "interactive mode") { shellargs.delete "-batch"}
    o.on("-e EMACS", "--emacs=EMACS", "set emacs binary [default: #{emacs}]") {|v| emacs = v }
    o.on("--ruby=RUBY", "set ruby binary [default: #{ruby}]") {|v| ruby = v }
    o.on("-I load-path", "set load-path") {|v| load_path << v}
    o.on("-r DIR", "--el4r-root=DIR", "el4r package root directory [for debug]") {|v| ENV['EL4R_ROOT'] = el4r_root = File.expand_path(v) }
    if test_mode
      o.on("-n NAME", "--name=NAME", "Runs tests matching NAME.",
           "(patterns may be used).") {|v| unittest_args << "-n" << v}
      o.on("-t TESTCASE", "--testcase=TESTCASE", "Runs tests in TestCases matching TESTCASE.",
           "(patterns may be used).") {|v| unittest_args << "-t" << v}
      o.on("-v", "verbose output"){|v| unittest_args << "-v"}
    end
    o.on("--nw", "don't communicate with X, ignoring $DISPLAY",
         "(emacs -nw)"){|v| shellargs << "--nw"}
    o.on("-d", "--debug", "debug output"){ strip_instance_error = "nil" }
    o.on("-l LOGFILE", "--log=LOGFILE", "Specify a log file.") {|v|
      ENV['EL4R_LOG']=File.expand_path(v);
      ENV['EL4R_PRESERVE_LOG']='1'
    }
    o.on("--show", "Show the test information only, for diagnosis.") { show_only = true}
    o.banner += " file"
    o.parse!
  end

  load "~/.el4rrc.rb"; conf=__conf__
  emacs ||= conf.emacs_program
  ruby ||= conf.ruby_program

  basearg = if init
              []
            else
              if emacs =~ /xemacs/
                ["-no-site-file", "-no-init-file"]
              else
                ["--no-site-file", "--no-init-file"]
              end
            end
  

  if el4r_root
    el4r_el = File.join(el4r_root, conf.el_program_relative)
    el4r_instance = File.join(el4r_root, conf.instance_program_relative)
  else
    el4r_el = conf.el_program
    el4r_instance = conf.instance_program
  end
  unittest_source = ARGV.first    # TODO: multiple sources

  raise "no such file or directory: #{unittest_source}" unless File.exist? unittest_source

  unittest_args_lisp = "'(" + unittest_args.compact.map{|x| x.dump}.join(" ") + ")"
  load_path_lisp = "(setq load-path (append '(" + load_path.map{|x| x.dump}.join(" ") + ") load-path))"

  lisp = format(<<'EOF', el4r_el, ruby, el4r_instance, unittest_source, unittest_args_lisp, strip_instance_error, load_path_lisp)
(when noninteractive
  (defun message (&rest args)))
(defun instantly-kill-emacs ()
  (interactive)
  (kill-emacs 0))

(setq help-msg "q, M-k:quit / C-c: run-test / l, C-l: show-log / SPC,b: scroll")
(defun unittest ()
  (interactive)
  (el4r-run-unittest)
  (or noninteractive (message help-msg)))
  
(define-key global-map "\C-x\C-c" 'instantly-kill-emacs)

(define-derived-mode unittest-mode fundamental-mode "UnitTest"
  ""
  (define-key unittest-mode-map "\M-k" 'instantly-kill-emacs)
  (define-key unittest-mode-map "q" 'instantly-kill-emacs)

  (define-key unittest-mode-map "\C-c" 'unittest)
  (define-key unittest-mode-map "\C-l" 'el4r-show-log)
  (define-key unittest-mode-map "l" 'el4r-show-log)

  (define-key unittest-mode-map "\M-d" 'edebug-defun)
  (define-key unittest-mode-map " " 'scroll-up)
  (define-key unittest-mode-map "b" 'scroll-down)
  )

(fset 'yes-or-no-p 'y-or-n-p)
;(setq debug-on-error t)
;(setq debug-on-signal t)
(setq debug-on-quit t)
(setq pop-up-windows nil)

(load "%s")
(defun el4r-override-variables ()
  (setq el4r-ruby-program "%s")
  (setq el4r-instance-program "%s")
  (setq el4r-unittest-file-name "%s")
  (setq el4r-load-script el4r-unittest-file-name)
  (setq el4r-unittest-args %s)
  (setq el4r-coding-system 'euc-jp-unix)
  )
(defun el4r-load-script ()
  (interactive)
  (el4r-load el4r-load-script))
(el4r-boot t)
(setq el4r-unittest-strip-instance-error %s)
(el4r-ruby-eval "self.el4r_is_debug = true")
(set-buffer "*scratch*")
%s
EOF
#'

  if show_only
    %w[
  ruby emacs el4r_el el4r_instance shellargs basearg
  unittest_source unittest_args load_path ENV['EL4R_ROOT']
  ].each do |varname|
      value = eval(varname).inspect
      puts "#{varname} = #{value}"
    end
    exit
  end


  begin
    el = File.join(Dir.tmpdir, "testrun.el")

    open(el,"w"){|w| w.write lisp}

    shellargs << "-l" << el
    if test_mode
      shellargs << "-f" << "unittest"
    else
      shellargs << "-f" << "el4r-load-script"
    end

    args = [emacs]+basearg+shellargs
    system *args

  ensure
#    File.unlink el
  end

end # /def

exec_el4r(true) if __FILE__ == $0

# Local Variables:
# modes: (ruby-mode emacs-lisp-mode)
# End:
