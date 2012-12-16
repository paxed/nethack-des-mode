;;; nethack-des-mode.el --- major mode for NetHack special level .des -files
;;
;; Author: Pasi Kallinen <paxed@alt.org>
;; Created: 20030724
;; Modified: 20070727
;; Version: 0.007
;; License: Same as NetHack itself
;;
;;
;;
;; Put the following lines into your ~/.emacs
;; Replace ~/.elisp with the path where you placed this file.
;;
;; (add-to-list 'load-path "~/.elisp")
;; (require 'nethack-des-mode)
;;
;;
;;
;; TODO:
;; - nethack-des-insert-map should offer a default width & height.
;; - draw a rectangle on a map (room using | and -, or any mapchar)
;; - command reference lookup and inserting command templates.
;;   eg. https://github.com/emacsmirror/pov-mode/blob/master/pov-mode.el
;;   (see defun pov-keyword-help)
;;   (see INSERT MENU SUPPORT)
;; - MAP lines should all be the same length - visually show this
;; - BUG: keyword completion doesn't work in emacs 21.x
;; - see "Major Mode Conventions" in elisp manual.
;; - see M-x apropos RET nethack-des RET and document all undocumented stuff.
;; - paren matching in map still happens until you do nethack-des-fontify-map
;;   or nethack-des-fontify-toggle once.
;; - tweak the default face colors.
;; - nethack-des-point-in-map is buggy.
;; - should fontify whole ranges of mapchars instead of one at a time.
;; - fix nethack-des-map-{end,beginning}:
;;     - should return the end/begin point of the map
;;     - shouldn't consider MAP or ENDMAP as being part of the map
;;     - NOMAP? LEVEL?
;; - nethack-des-fontify-map (&optional begin, end)
;; - look into picture-mode for inspiration for editing the maps.
;; - MAPs can also contain 0-9, even though those aren't allowed map chars;
;;   those are "line numbers"
;; - ( and ) are hilighted erroneously, eg. in (center, center)
;; - should be able to turn on font-locking automagically...
;; - font-locking should have 4 modes: off, keywords, maps, all.
;;   keywords wouldn't hilight maps, maps hilights only inside maps.
;;
;;
;;
;; DONE:
;; v0.007
;; - keyword completion (borrowed from Alex Shinn's css-mode)  (C-c TAB)
;; - changed some defvars to defconsts
;; - added nethack-des-map-size  (C-c i)
;; - added nethack-des-coord-to-map  (C-c c)
;; - added nethack-des-map-to-coord  (C-c v)
;; - added missing map character 'B'
;; - hilight illegal characters inside MAP-ENDMAP
;; - changed font-locking, so you can have both maps and keywords
;;   hilighted at the same time.
;; - hilight unknown keywords
;;
;; - fixed nethack-des-map-end
;; - added hook that gets called when buffer leaves nethack-des-mode.
;;   (this clears the text properties)
;; - characters inserted into map now are hilighted correctly, if
;;   map syntax coloring is on.
;; v0.006
;; - shouldn't do paren matching inside map.
;; v0.005
;; - fontifying the maps doesn't change undo buffer, and doesn't set
;;   the buffer modified.
;; - nethack-des-point-in-map
;; - create nethack-des-mapchars-escaped from nethack-des-mapchar-faces
;; v0.004
;; - faster nethack-des-fontify-mapchar-at
;; v0.003
;; - moving to beginning and end of map.
;; - toggling font-lock mode between keywords and map.
;; v0.002
;; - font-locking inside MAP-ENDMAP should use the colors in nethack,
;;   eg.'L', which is lava, should be red.
;; v0.001
;; - registers always have [x] after them, x = 0..9
;; - '"' shouldn't be interpreted as a string start/end, eg.
;;   OBJECT:'"',"amulet of reflection", ...
;; - some commands, like OBJECT can have optional % chance, eg.
;;   OBJECT[10%]: blahblah...  fix the font-locking regex.
;; - include sign and % in numbers.
;;
;;

(defvar nethack-des-mapchar-hwall-face 'nethack-des-mapchar-hwall-face
  "Face to use for NetHack-des-mode horizontal walls.")
(defvar nethack-des-mapchar-vwall-face 'nethack-des-mapchar-vwall-face
  "Face to use for NetHack-des-mode vertical walls.")
(defvar nethack-des-mapchar-moat-face 'nethack-des-mapchar-moat-face
  "Face to use for NetHack-des-mode moats.")
(defvar nethack-des-mapchar-lava-face 'nethack-des-mapchar-lava-face
  "Face to use for NetHack-des-mode lavapools.")
(defvar nethack-des-mapchar-secret-door-face 'nethack-des-mapchar-secret-door-face
  "Face to use for NetHack-des-mode secret doors.")
(defvar nethack-des-mapchar-door-face 'nethack-des-mapchar-door-face
  "Face to use for NetHack-des-mode doors.")
(defvar nethack-des-mapchar-air-face 'nethack-des-mapchar-air-face
  "Face to use for NetHack-des-mode air.")
(defvar nethack-des-mapchar-cloud-face 'nethack-des-mapchar-cloud-face
  "Face to use for NetHack-des-mode clouds.")
(defvar nethack-des-mapchar-fountain-face 'nethack-des-mapchar-fountain-face
  "Face to use for NetHack-des-mode fountains.")
(defvar nethack-des-mapchar-throne-face 'nethack-des-mapchar-throne-face
  "Face to use for NetHack-des-mode thrones.")
(defvar nethack-des-mapchar-kitchen-sink-face 'nethack-des-mapchar-kitchen-sink-face
  "Face to use for NetHack-des-mode sinks.")
(defvar nethack-des-mapchar-pool-face 'nethack-des-mapchar-pool-face
  "Face to use for NetHack-des-mode pools.")
(defvar nethack-des-mapchar-ice-face 'nethack-des-mapchar-ice-face
  "Face to use for NetHack-des-mode ice.")
(defvar nethack-des-mapchar-water-face 'nethack-des-mapchar-water-face
  "Face to use for NetHack-des-mode water.")
(defvar nethack-des-mapchar-tree-face 'nethack-des-mapchar-tree-face
  "Face to use for NetHack-des-mode trees.")
(defvar nethack-des-mapchar-ironbars-face 'nethack-des-mapchar-ironbars-face
  "Face to use for NetHack-des-mode ironbars.")
(defvar nethack-des-mapchar-stone-face 'nethack-des-mapchar-stone-face
  "Face to use for NetHack-des-mode stone.")
(defvar nethack-des-mapchar-corridor-face 'nethack-des-mapchar-corridor-face
  "Face to use for NetHack-des-mode corridors.")
(defvar nethack-des-mapchar-room-face 'nethack-des-mapchar-room-face
  "Face to use for NetHack-des-mode rooms.")
(defvar nethack-des-mapchar-error-face 'nethack-des-mapchar-error-face
  "Face to use for erroneous characters in maps for NetHack-des-mode.")

(defface nethack-des-mapchar-hwall-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "grey"))
    (((class color) (background dark))     (:foreground "grey"))
    (t (:underline t)))
  "Highlights horizontal walls in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-vwall-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "grey"))
    (((class color) (background dark))     (:foreground "grey"))
    (t (:underline t)))
  "Highlights vertical walls in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-moat-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "Blue"))
    (((class color) (background dark))     (:foreground "Blue"))
    (t (:underline t)))
  "Highlights moats in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-lava-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "Red"))
    (((class color) (background dark))     (:foreground "Red"))
    (t (:underline t)))
  "Highlights lavapools in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-secret-door-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "DarkOrange2"))
    (((class color) (background dark))     (:foreground "DarkOrange2"))
    (t (:underline t)))
  "Highlights secret doors in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-door-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "DarkOrange2"))
    (((class color) (background dark))     (:foreground "DarkOrange2"))
    (t (:underline t)))
  "Highlights doors in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-air-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "Cyan"))
    (((class color) (background dark))     (:foreground "Cyan"))
    (t (:underline t)))
  "Highlights air in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-cloud-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "white"))
    (((class color) (background dark))     (:foreground "white"))
    (t (:underline t)))
  "Highlights clouds in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-fountain-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "blue"))
    (((class color) (background dark))     (:foreground "blue"))
    (t (:underline t)))
  "Highlights fountains in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-throne-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "yellow"))
    (((class color) (background dark))     (:foreground "yellow"))
    (t (:underline t)))
  "Highlights thrones in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-kitchen-sink-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "grey"))
    (((class color) (background dark))     (:foreground "grey"))
    (t (:underline t)))
  "Highlights sinks in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-pool-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "blue"))
    (((class color) (background dark))     (:foreground "blue"))
    (t (:underline t)))
  "Highlights pools in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-ice-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "Cyan"))
    (((class color) (background dark))     (:foreground "Cyan"))
    (t (:underline t)))
  "Highlights ice in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-water-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "blue"))
    (((class color) (background dark))     (:foreground "blue"))
    (t (:underline t)))
  "Highlights water in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-tree-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "green"))
    (((class color) (background dark))     (:foreground "green"))
    (t (:underline t)))
  "Highlights trees in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-ironbars-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "Cyan"))
    (((class color) (background dark))     (:foreground "Cyan"))
    (t (:underline t)))
  "Highlights iron bars in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-stone-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "black"))
    (((class color) (background dark))     (:foreground "black"))
    (t (:underline t)))
  "Highlights stone in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-corridor-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "grey"))
    (((class color) (background dark))     (:foreground "grey"))
    (t (:underline t)))
  "Highlights corridors in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-room-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "grey"))
    (((class color) (background dark))     (:foreground "grey"))
    (t (:underline t)))
  "Highlights rooms in nethack-des-mode."
  :group 'nethack-des-faces)
(defface nethack-des-mapchar-error-face
  '((((class grayscale) (background light))(:foreground "DimGray" :underline t))
    (((class grayscale) (background dark)) (:foreground "LightGray" :underline t))
    (((class color) (background light))    (:foreground "yellow"))
    (((class color) (background light))     (:foreground "red"))
    (t (:underline t)))
  "Highlights erroneous characters inside MAPs in nethack-des-mode."
  :group 'nethack-des-faces)

(defconst nethack-des-mapchar-faces
  (list
;; NOTE: char - needs to be first in this list!
   '( ?- . nethack-des-mapchar-hwall-face )
   '( ?| . nethack-des-mapchar-vwall-face )
   '( ?} . nethack-des-mapchar-moat-face )
   '( ?L . nethack-des-mapchar-lava-face )
   '( ?S . nethack-des-mapchar-secret-door-face )
   '( ?+ . nethack-des-mapchar-door-face )
   '( ?A . nethack-des-mapchar-air-face )
   '( ?C . nethack-des-mapchar-cloud-face )
   '( ?{ . nethack-des-mapchar-fountain-face )
   '( ?\\ . nethack-des-mapchar-throne-face )
   '( ?K . nethack-des-mapchar-kitchen-sink-face )
   '( ?P . nethack-des-mapchar-pool-face )
   '( ?I . nethack-des-mapchar-ice-face )
   '( ?W . nethack-des-mapchar-water-face )
   '( ?T . nethack-des-mapchar-tree-face )
   '( ?F . nethack-des-mapchar-ironbars-face )
   '( ?  . nethack-des-mapchar-stone-face )
   '( ?# . nethack-des-mapchar-corridor-face )
   '( ?. . nethack-des-mapchar-room-face )
   '( ?B . nethack-des-mapchar-room-face )
   )
)

(defconst nethack-des-commands-no-args
  (list
   "ENDMAP"
   "MAP"
   "NOMAP"
   "RANDOM_CORRIDORS"
   "WALLIFY"
   )
  )

(defconst nethack-des-commands-with-args
  (list
   "ALTAR"
   "BRANCH"
   "CHANCE"
   "CONTAINER"
   "CORRIDOR"
   "DOOR"
   "DRAWBRIDGE"
   "ENGRAVING"
   "FLAGS"
   "FOUNTAIN"
   "GEOMETRY"
   "GOLD"
   "INIT_MAP"
   "LADDER"
   "LEVEL"
   "MAZE"
   "MAZEWALK"
   "MESSAGE"
   "MONSTER"
   "NAME"
   "NON_DIGGABLE"
   "NON_PASSWALL"
   "OBJECT"
   "POOL"
   "PORTAL"
   "RANDOM_MONSTERS"
   "RANDOM_OBJECTS"
   "RANDOM_PLACES"
   "REGION"
   "ROOM"
   "SINK"
   "STAIR"
   "SUBROOM"
   "TELEPORT_REGION"
   "TRAP"
   )
  )

(defconst nethack-des-registers
  (list
   "align"
   "monster"
   "object"
   "place"
   )
  )

(defconst nethack-des-constants
  (list
   "altar"
   "arboreal"
   "asleep"
   "awake"
   "blessed"
   "bottom"
   "broken"
   "burn"
   "center"
   "chaos"
   "closed"
   "coaligned"
   "contained"
   "cursed"
   "down"
   "dust"
   "east"
   "engrave"
   "false"
   "filled"
   "half-left"
   "half-right"
   "hardfloor"
   "hostile"
   "law"
   "left"
   "levregion"
   "lit"
   "locked"
   "mark"
   "m_feature"
   "m_monster"
   "m_object"
   "neutral"
   "noalign"
   "nodoor"
   "nommap"
   "noncoaligned"
   "none"
   "north"
   "noteleport"
   "open"
   "peaceful"
   "random"
   "right"
   "sanctum"
   "shortsighted"
   "shrine"
   "south"
   "top"
   "true"
   "uncursed"
   "unfilled"
   "unlit"
   "up"
   "west"
   )
  )

(defconst nethack-des-completion-keywords
  (append
   nethack-des-commands-with-args
   nethack-des-commands-no-args
   nethack-des-constants
   nethack-des-registers)
)

(defconst nethack-des-map-max-size (cons 76 21)
  "Maximum dimensions of a MAP-ENDMAP part."
)

;; (font-lock-add-keywords 'nethack-des-mode
;;  `(("^[ \t]*\\(#.*\\)$" . font-lock-comment-face)
;;     ("\\('.'\\)" . font-lock-string-face)
;;     ("\\(\"[^\"]+\"\\)" . font-lock-string-face)
;;     ("\\([+-]?[0-9]+%?\\)" . font-lock-variable-name-face)
;;     (,(concat "\\<\\(" (regexp-opt nethack-des-commands-with-args) "\\)\\>[ \t]*[\\[:]+") (0 font-lock-keyword-face))
;;     (,(concat "\\<\\(" (regexp-opt nethack-des-commands-no-args) "\\)\\>")  (0 font-lock-keyword-face))
;;     (,(concat "\\<\\(" (regexp-opt nethack-des-constants) "\\)\\>") (0 font-lock-constant-face))
;;     (,(concat "\\<\\(" (regexp-opt nethack-des-registers) "\\)\\>\\[[0-9]\\]") (0 font-lock-builtin-face))
;;     )
;; )

(defvar nethack-des-need-fontification nil
  "Buffer needs fontification"
)
(make-variable-buffer-local 'nethack-des-need-fontification)


(defvar nethack-des-mode-map nil
  "Keymap for nethack-des-mode"
)

(if (null nethack-des-mode-map)
    (progn
      (setq nethack-des-mode-map (make-sparse-keymap))
      (define-key nethack-des-mode-map "\C-ca" 'nethack-des-map-beginning)
      (define-key nethack-des-mode-map "\C-ce" 'nethack-des-map-end)
      (define-key nethack-des-mode-map "\C-cm" 'nethack-des-fontify-toggle)
      (define-key nethack-des-mode-map "\C-c\t" 'nethack-des-complete-at-keyword)
      (define-key nethack-des-mode-map "\C-ci" 'nethack-des-map-size)
      (define-key nethack-des-mode-map "\C-cv" 'nethack-des-map-to-coord)
      (define-key nethack-des-mode-map "\C-cc" 'nethack-des-coord-to-map)
      )
)

(defvar nethack-des-mapchars-escaped nil
  "Escaped list of allowed MAP chars."
)
;; create nethack-des-mapchars-escaped from nethack-des-mapchar-faces
(if (null nethack-des-mapchars-escaped)
    (let (
	  (index 0)
	  (tmplst nil)
	  )
      (while (< index (safe-length nethack-des-mapchar-faces))
	(setq tmplst
	      (concat tmplst
		      (regexp-quote
		       (char-to-string (car (nth index nethack-des-mapchar-faces))))))
	(setq index (+ index 1))
      )
      (setq nethack-des-mapchars-escaped tmplst)
    )
)

;; A speed hack.  These are used in the fontification inner loop.
(defconst nethack-des-fontify-regexp-cmd-args
  (concat "\\<\\(" (regexp-opt nethack-des-commands-with-args) "\\)\\>[ \t]*\\(\\[[0-9]+%\\]\\)?[ \t]*:")
)
(defconst nethack-des-fontify-regexp-cmd-noargs
  (concat "\\<\\(" (regexp-opt nethack-des-commands-no-args) "\\)\\>$")
)
(defconst nethack-des-fontify-regexp-const
  (concat "\\<\\(" (regexp-opt nethack-des-constants) "\\)\\>")
)
(defconst nethack-des-fontify-regexp-register
  (concat "\\<\\(" (regexp-opt nethack-des-registers) "\\)\\>\\[[0-9]\\]")
)


(defun nethack-des-mode-exit-hook ()
  "Called when buffer is changed from nethack-des-mode to something else."
  (let* (
	 (mod (buffer-modified-p))
	 (und buffer-undo-list)
	)
    (set-text-properties 1 (buffer-size) nil)
    (setq buffer-undo-list und)
    (set-buffer-modified-p mod)
  )
)

(define-derived-mode nethack-des-mode text-mode
  "NetHack-des"
  "Major mode for editing NetHack .des -files."
;;  (kill-all-local-variables)
  (set (make-local-variable 'comment-start) "#")
  (set (make-local-variable 'font-lock-defaults) '(nil nil nil))
  (set (make-local-variable 'nethack-des-map-fontify-flag) nil)
  (set (make-local-variable 'nethack-des-paren-match) show-paren-mode)
  (set (make-local-variable 'show-paren-mode) show-paren-mode)
  (set (make-local-variable 'show-paren-mode-hook) 'nethack-des-paren-hook)
  (set (make-local-variable 'inhibit-modification-hooks) nil)
  (set (make-local-variable 'after-change-functions) (list 'nethack-des-after-change))
  (set (make-local-variable 'post-command-hook) (list 'nethack-des-post-command-function))
  (set (make-variable-buffer-local 'change-major-mode-hook) 'nethack-des-mode-exit-hook)
  (use-local-map nethack-des-mode-map)
;;  (font-lock-fontify-buffer)
  )


(defun nethack-des-paren-hook ()
  "Called when show-paren-mode is changed."
  (setq nethack-des-paren-match show-paren-mode)
)

(defun nethack-des-enter-map (oldpoint newpoint)
  "Called when point enters a map."
  (setq show-paren-mode nil)
)

(defun nethack-des-leave-map (oldpoint newpoint)
  "Called when point leaves a map."
  (setq show-paren-mode nethack-des-paren-match)
)

(defun nethack-des-fontify-mapchar-at (begin &optional end)
  "Fontify map char."
  (let* (
	(len (if (and (boundp 'end) (numberp end)) (- end begin) 1))
	)
    (while (> len 0)
      (if (not (char-equal (char-after begin) ?\n)) ;; skip newlines
      (let* (
	     (tmpidx (assoc (char-after begin) nethack-des-mapchar-faces))
	    )
	(if (not (null tmpidx)) ;; if the character is legal map character, then
	    (set-text-properties begin (+ begin 1)
				 (list
				  'face (cdr tmpidx)
				  'font-face (cdr tmpidx)
				  'point-entered 'nethack-des-enter-map
				  'point-left 'nethack-des-leave-map
				  'insert-behind-hooks '(list nethack-des-fontify-mapchar-at)
				  'insert-in-front-hooks '(list nethack-des-fontify-mapchar-at)
				  ))
	  ;; else hilight it with error
	  (set-text-properties begin (+ begin 1)
			       (list
				'face nethack-des-mapchar-error-face
				'font-face nethack-des-mapchar-error-face
				'point-entered 'nethack-des-enter-map
				'point-left 'nethack-des-leave-map
				'insert-behind-hooks '(list nethack-des-fontify-mapchar-at)
				'insert-in-front-hooks '(list nethack-des-fontify-mapchar-at)
				))
	  )
	)
      )
      (setq len (- len 1))
      (setq begin (+ begin 1))
      )
    )
  )


;; code below borrowed from css-mode by Alex Shinn
(defun nethack-des-complete-symbol (&optional table predicate prettify)
  (let* ((end (point))
	 (beg (save-excursion
		(skip-syntax-backward "w")
		(point)))
	 (pattern (buffer-substring beg end))
	 (table (or table obarray))
	 (completion (try-completion pattern table predicate)))
    (cond ((eq completion t))
	  ((null completion)
	   (error "Can't find completion for \"%s\"" pattern))
	  ((not (string-equal pattern completion))
	   (delete-region beg end)
	   (insert completion))
	  (t
	   (message "Making completion list...")
	   (let ((list (all-completions pattern table predicate)))
	     (if prettify
		 (setq list (funcall prettify list)))
	     (with-output-to-temp-buffer "*Help*"
	       (display-completion-list list)))
	   (message "Making completion list...%s" "done")))))

(defun nethack-des-complete-at-keyword ()
  "Complete the standard element at point"
  (interactive)
  (let ((completion-ignore-case nil))
    (nethack-des-complete-symbol nethack-des-completion-keywords) ))
;; code above borrowed from css-mode by Alex Shinn


(defun nethack-des-insert-map (&optional width height char)
  "Insert a basic MAP template at after point."
  (interactive "*nWidth: \nnHeight: \ncMapChar: ")
  (if (not (nethack-des-point-in-map))
      (let* (
	     (x (if (and (boundp 'width) (numberp width)) width (car nethack-des-map-max-size)))
	     (y (if (and (boundp 'height) (numberp height)) height (cdr nethack-des-map-max-size)))
	     (ox x)
	     (chr (if (and (boundp 'char) (stringp char)) char ?.))
	    )
	(if (not (bolp)) (list (end-of-line) (insert "\n")))
	(insert "MAP\n")
	(while (> y 0)
	  (while (> x 0)
	    (insert chr)
	    (setq x (- x 1))
	  )
	  (insert "\n")
	  (setq y (- y 1))
	  (setq x ox)
	)
	(insert "ENDMAP")
	(if (not (eolp)) (insert "\n"))
      )
      (message "Point is already inside a map.")
  )
)


(defun nethack-des-map-beginning ()
  "Go to beginning of map, if point is in map."
  (interactive)
  (let (
	(curpoint (point))
	)
     (if (not (string= (thing-at-point 'line) "MAP\n"))
	 (list
	  (skip-chars-backward (concat nethack-des-mapchars-escaped "\r\n\t"))
	  (if (not (string= (thing-at-point 'line) "MAP\n"))
	      (goto-char curpoint)
	      (forward-line)
	  )
	 )
     )
  )
)


(defun nethack-des-map-end ()
  "Go to end of map, if point is in map."
  (interactive)
  (let (
	(curpoint (point))
	)
    (if (not (string= (thing-at-point 'line) "ENDMAP\n"))
	(list
	 (skip-chars-forward (concat nethack-des-mapchars-escaped "\r\n\t"))
	 (if (not (string= (thing-at-point 'line) "ENDMAP\n"))
	     (goto-char curpoint)
	     (forward-char -1)
	 )
	)
    )
  )
)


(defun nethack-des-point-in-map (&optional pos)
 "Returns t if point (or optionally, POS) is in map, nil otherwise."
 (interactive)
 (save-excursion
   (if (and (boundp 'pos) (numberp pos)) (goto-char pos))
   (let (
	 (b 0)
	 (e 0)
	 )
     (nethack-des-map-end)
     (setq e (point))
     (nethack-des-map-beginning)
     (setq b (point))
     (/= b e)
     )
   )
)


(defun nethack-des-map-to-coord (&optional pos)
  "Show map coordinates of current point (or POS) in minibuffer."
  (interactive)
  (save-excursion
   (if (and (boundp 'pos) (numberp pos)) (goto-char pos))
   (if (nethack-des-point-in-map)
   (let (
	 (oldpoint (point))
	 (nx (current-column))
	 (ny 0)
	 )
     (nethack-des-map-beginning)
     (setq ny (count-lines oldpoint (point)))
     (goto-char oldpoint)
     (if (not (bolp)) (setq ny (- ny 1)))
     (message "Coord: (%i, %i)" nx ny)
     (cons nx ny)
   )
   (message "Not inside map.")
   )
   )
)


(defun nethack-des-coord-to-map ()
  "Get coordinate values, in the form of (1,2) or (1,2,3,4) from under point and blink to the map above."
  (interactive)
  (save-excursion
    (let (
	  (wstart (window-start))
	  (swin (selected-window))
	  (tempwin nil)
	  (wpoint (point))
	  (coordata (split-string (buffer-substring-no-properties
				   (+ (point) (skip-chars-backward "0-9, "))
				   (+ (point) (skip-chars-forward  "0-9, "))) ","))
	  (x1 0)
	  (y1 0)
	  (x2 nil)
	  (y2 nil)
	 )
     (setq x1 (nth 0 coordata))
     (setq y1 (nth 1 coordata))
     (setq x2 (nth 2 coordata))
     (setq y2 (nth 3 coordata))

     (if (and (not (null x1)) (not (null y1)))
	 (list
	  (re-search-backward "^MAP$" nil t)
	  (forward-line (+ (string-to-number y1) 1))
	  (forward-char (string-to-number x1))
	  (if (and (not (pos-visible-in-window-p)) (one-window-p))
	      (list ;; temporarily split the window, and show the map in the other one.
	       (setq tempwin (split-window))
	       (set-window-start swin wstart)
	       (set-window-point swin wpoint)
	       (if (not (pos-visible-in-window-p)) (recenter))
	       (select-window tempwin)
	       (recenter)
	       (sit-for 1)
	      )
	      (sit-for 1)
	  )

	  (if (and (not (null x2)) (not (null y2)))
	      (list
	       (re-search-backward "^MAP$" nil t)
	       (forward-line (+ (string-to-number y2) 1))
	       (forward-char (string-to-number x2))
	       (sit-for 1)
	      )
	  )

	  (if (not (null tempwin)) ;; restore the window if we split it above
	    (list
	       (delete-window tempwin)
	       (select-window swin)
	    )
	  )

	  (set-window-start swin wstart) ;; restore viewport
	 )
     )

    )
  )
)


(defun nethack-des-map-size (&optional pos)
  "Show map size in minibuffer."
  (interactive)
  (save-excursion
   (if (and (boundp 'pos) (numberp pos)) (goto-char pos))
   (if (nethack-des-point-in-map)
   (let (
	 (posbegin 0)
	 (posend 0)
	 (nx 0)
	 (ny 0)
	 )
     (nethack-des-map-beginning)
     (setq posbegin (point))
     (nethack-des-map-end)
     (setq posend (point))
     (setq ny (count-lines posbegin posend))
     (setq nx (current-column))
     (message "Map size: (%i, %i)" nx ny)
   )
   (message "Not inside a map.")
   )
   )
)


(defun nethack-des-fontify-maps ()
  "Fontify maps."
  (interactive)
  (let* (
	 (mod (buffer-modified-p))
	 (und buffer-undo-list)
	 )
    (setq buffer-undo-list t)
    (font-lock-mode -1)
    (setq nethack-des-map-fontify-flag t)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^MAP$" nil t)
	(let*
	    (
	     (mapbegin (point))
	     (mapend (- (re-search-forward "^ENDMAP$") 7))
	     )
	  (goto-char mapbegin)
	  (while (< (point) mapend) (nethack-des-fontify-mapchar-at (point)) (forward-char))
	  )
	)
      )
    (setq buffer-undo-list und)
    (set-buffer-modified-p mod)
  )
)

(defun nethack-des-fontify-at (begin &optional end)
  ""
  (save-excursion
    (let* (
	   (nend (line-end-position))
	   (mod (buffer-modified-p))
	   (und buffer-undo-list)
	   (tmp-case-fold case-fold-search)
	  )
          (setq case-fold-search nil)
          (setq inhibit-modification-hooks t)
	  (set-window-point (selected-window) begin)
          (beginning-of-line)
          (while (< (point) nend)
	    (nethack-des-fontify-place)
	  )
          (setq inhibit-modification-hooks nil)
          (setq case-fold-search tmp-case-fold)
	  (setq buffer-undo-list und)
	  (set-buffer-modified-p mod)
    )
  )
)

(defun nethack-des-after-change (begin end size)
  ""
  (if (null nethack-des-need-fontification)
      (setq nethack-des-need-fontification (cons begin end))
;; else
      (if (< begin (car nethack-des-need-fontification))
	  (setq nethack-des-need-fontification (cons begin (cdr nethack-des-need-fontification)))
      )
      (if (> end (cdr nethack-des-need-fontification))
	  (setq nethack-des-need-fontification (cons (car nethack-des-need-fontification) end))
      )
  )
)

(defun nethack-des-post-command-function ()
 "foo"
 (if (eq nethack-des-map-fontify-flag t)
     (when nethack-des-need-fontification
       (nethack-des-fontify-at (car nethack-des-need-fontification) (cdr nethack-des-need-fontification))
       (setq nethack-des-need-fontification nil)
     )
 )
)

(defun nethack-des-fontify-place ()
  "Fontify the current line under point."
  (cond
   ((get-text-property (point) 'point-left) ;; if character under (point) has "point-left" property...
      (nethack-des-fontify-mapchar-at (point) (1+ (point)))
      (forward-char)
   )
   ((looking-at "^MAP$")
      (set-text-properties (point) (match-end 0)
			   (list
			    'face font-lock-keyword-face
			    'font-face font-lock-keyword-face
			   )
      )
      (let*
	  (
	   (mapbegin (+ (point) 3))
	   (mapend (- (re-search-forward "^ENDMAP$") 7))
	  )
	  (goto-char mapbegin)
	  (while (< (point) mapend) (nethack-des-fontify-mapchar-at (point)) (forward-char))
      )
   )
   ((looking-at "^\\([ \t]*#.*\\)$") ;; comments
      (set-text-properties (point) (match-end 1)
            (list
	      'face font-lock-comment-face
	      'font-face font-lock-comment-face
	    )
      )
      (set-window-point (selected-window) (match-end 1))
   )
   ((looking-at "\\('.'\\)") ;; character
      (set-text-properties (point) (match-end 1)
            (list
	      'face font-lock-string-face
	      'font-face font-lock-string-face
	    )
      )
      (set-window-point (selected-window) (match-end 1))
   )
   ((looking-at "\\(\"[^\"\n]+\"\\)") ;; string
      (set-text-properties (point) (match-end 1)
            (list
	      'face font-lock-string-face
	      'font-face font-lock-string-face
	    )
      )
      (set-window-point (selected-window) (match-end 1))
   )
   ((looking-at "\\(([ \t]*[0-9]+[ \t]*,[ \t]*[0-9]+[ \t]*)\\)") ;; coordinate
      (set-text-properties (point) (match-end 1)
            (list
	      'face font-lock-constant-face
	      'font-face font-lock-constant-face
	    )
      )
      (set-window-point (selected-window) (match-end 1))
   )
   ((looking-at "\\(([ \t]*[0-9]+[ \t]*,[ \t]*[0-9]+[ \t]*,[ \t]*[0-9]+[ \t]*,[ \t]*[0-9]+[ \t]*)\\)") ;; region
      (set-text-properties (point) (match-end 1)
            (list
	      'face font-lock-constant-face
	      'font-face font-lock-constant-face
	    )
      )
      (set-window-point (selected-window) (match-end 1))
   )
   ((looking-at "\\([^[][+-]?[0-9]+[^]]\\)") ;; number (not surrounded by [])
      (set-text-properties (point) (match-end 1)
            (list
	      'face font-lock-constant-face
	      'font-face font-lock-constant-face
	    )
      )
      (set-window-point (selected-window) (match-end 1))
   )
   ((looking-at "\\(\\[[0-9]+%?\\]\\)") ;; percentage [XX%], or register index [X]
      (set-text-properties (point) (match-end 1)
            (list
	      'face font-lock-constant-face
	      'font-face font-lock-constant-face
	    )
      )
      (set-window-point (selected-window) (match-end 1))
   )
   ((looking-at "\\([,: \t]+\\)") ;; space characters
      (set-text-properties (point) (match-end 1) nil)
      (set-window-point (selected-window) (match-end 1))
   )
   ((looking-at nethack-des-fontify-regexp-cmd-args)
      (set-text-properties (point) (match-end 1)
            (list
	      'face font-lock-keyword-face
	      'font-face font-lock-keyword-face
	    )
      )
      (set-window-point (selected-window) (match-end 1))
   )
   ((looking-at nethack-des-fontify-regexp-cmd-noargs)
      (set-text-properties (point) (match-end 1)
            (list
	      'face font-lock-keyword-face
	      'font-face font-lock-keyword-face
	    )
      )
      (set-window-point (selected-window) (match-end 1))
   )
   ((looking-at nethack-des-fontify-regexp-const)
      (set-text-properties (point) (match-end 1)
            (list
	      'face font-lock-variable-name-face
	      'font-face font-lock-variable-name-face
	    )
      )
      (set-window-point (selected-window) (match-end 1))
   )
   ((looking-at nethack-des-fontify-regexp-register)
      (set-text-properties (point) (match-end 1)
            (list
	      'face font-lock-builtin-face
	      'font-face font-lock-builtin-face
	    )
      )
      (set-window-point (selected-window) (match-end 1))
   )
   (t
      (set-text-properties (point) (1+ (point))
            (list
	      'face font-lock-warning-face
	      'font-face font-lock-warning-face
	    )
      )
      (forward-char)
   )
  )
)


(defun nethack-des-fontify-buffer ()
  "Fontify whole buffer."
  (interactive)
  (let* (
	 (mod (buffer-modified-p))
	 (und buffer-undo-list)
	 (tmp-case-fold case-fold-search)
	 )
    (setq buffer-undo-list t)
    (font-lock-mode -1)
    (setq case-fold-search nil)
    (setq inhibit-modification-hooks t)
    (setq nethack-des-map-fontify-flag t)
    (setq nethack-des-need-fontification nil)
    (save-excursion
      (goto-char (point-min))
      (set-text-properties (point-min) (point-max) nil)
      (while (< (point) (point-max))
	(nethack-des-fontify-place)
      )
    )
    (setq buffer-undo-list und)
    (set-buffer-modified-p mod)
    (setq case-fold-search tmp-case-fold)
    (setq inhibit-modification-hooks nil)
  )
)



(defun nethack-des-fontify-toggle ()
  "Toggle fontification on and off."
  (interactive)
  (if (eq nethack-des-map-fontify-flag nil)
    (list
     (setq nethack-des-map-fontify-flag t)
     (nethack-des-fontify-buffer)
    )
    (let* (
	   (mod (buffer-modified-p))
	   (und buffer-undo-list)
	  )
	 (setq nethack-des-map-fontify-flag nil)
	 (set-text-properties 1 (buffer-size) nil)
	 (setq nethack-des-need-fontification nil)
	 (setq buffer-undo-list und)
	 (set-buffer-modified-p mod)
    )
  )
)


;; If not associated, then associate *.des to nethack-des-mode
(if (not (assoc "\\.des$" auto-mode-alist))
    (setq auto-mode-alist
	  (append '(("\\.des$" . nethack-des-mode)) auto-mode-alist)))

(provide 'nethack-des-mode)

