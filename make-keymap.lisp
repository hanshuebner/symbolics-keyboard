;; -*- Lisp -*-

;; Layout generation tools for Symbolics kbdbabel.

;; MAKE-KEYMAP generates a keymap suitable to be included in the kbdbabel assembler source
;; DRAW-KEYBOARD generates a PDF file documenting the mapping as generated

;; Depends on :CL-PDF, :ALEXANDRIA and :CL-PPCRE

;; Written 2008 by Hans Huebner
;; Placed in the public domain

(in-package :cl-user)

(defpackage :symbolics-keyboard
  (:nicknames "SKBD")
  (:use :cl :alexandria))

(in-package :symbolics-keyboard)

(defparameter *key-map*
  '(("Select" 		"F1")
    ("Network" 		"F2")
    ("Function" 	"F3")
    ("Suspend" 		"F4")
    ("Resume" 		"F5")
    ("Abort" 		"F6")
    ("SuperL" 		"F7")
    ("HyperL" 		"F8")
    ("Scroll" 		"F9" 	"PgDn")
    ("ClearInput" 	"F10")
    ("SymbolR" 		"KP5" 	"Up")
    ("Scroll" 		"KP3"	"Scroll")
    ("RubOut" 		"Del")
    ("Complete" 	"F11"	"Home")
    ("Help" 		"F12")
    ("End" 		"KP1" 	"End")
    ("MetaL" 		"AltL")
    ("MetaR" 		"AltGr"	"Left")
    ("SuperR" 		"KP." 	"Down")
    ("HyperR" 		"KP+" 	"Right")
    ("Repeat" 		"KP/" 	"PgUp")
    ("ControlL" 	"CtrlL")
    ("ControlR" 	"CtrlR")
    ("(" 		"[")
    (")" 		"]")
    ("Triangle"		"KP2")
    ("Circle"		"KP3")
    ("Square"		"KP4")
    ("Refresh"		"KP0")
    ("Page"		"KP6")
    ("Line"		"KP7")
    ("SymbolL"		"KP8")
    ("|"		"KP-")
    (":"		"KP*")
    ("CapsLock"		"Caps"))
  "Mappings for keys.  By default, Symbolics keys which have the same
  name (keycap label) as a PS/2 key are mapped to that corresponding
  key.  Before the default mapping is considered, this list of lists
  is checked for an explicit definition.  Each list consists
  of (KEYNAME PS2-KEYNAME [ F-MODE-PS2-KEYNAME ] ) with KEYNAME being
  the name of the Symbolics key, PS2-KEYNAME the name of the PS/2 key
  name whose PS/2 scancode should be sent and F-MODE-PS2-KEYNAME being
  the name of the PS/2 key whose PS/2 scancode should be sent in
  F-mode.  PS2-KEYNAME may be NIL to indicate that no PS/2 scancode is
  associated to the key when not in F-Mode.  F-MODE-PS2-KEYNAME
  defaults to PS2-KEYNAME if not specified.")

(defparameter *ps2-map*
  '(("F9"		#x01)
    ("F5"	 	#x03)
    ("F3"		#x04)
    ("F1"		#x05)
    ("F2"		#x06)
    ("F12"		#x07)
    ("F10"		#x09)
    ("F8"		#x0a)
    ("F6"		#x0b)
    ("F4"		#x0c)
    ("Tab"		#x0d)
    ("`"		#x0e)
    ("AltL"		#x11)
    ("ShiftL"		#x12)
    ("CtrlL"		#x14)
    ("Q"		#x15)
    ("1"		#x16)
    ("Z"		#x1a)
    ("S"		#x1b)
    ("A"		#x1c)
    ("W"		#x1d)
    ("2"		#x1e)
    ("C"		#x21)
    ("X"		#x22)
    ("D"		#x23)
    ("E"		#x24)
    ("4"		#x25)
    ("3"		#x26)
    ("Space"		#x29)
    ("V"		#x2a)
    ("F"		#x2b)
    ("T"		#x2c)
    ("R"		#x2d)
    ("5"		#x2e)
    ("N"		#x31)
    ("B"		#x32)
    ("H"		#x33)
    ("G"		#x34)
    ("Y"		#x35)
    ("6"		#x36)
    ("M"		#x3a)
    ("J"		#x3b)
    ("U"		#x3c)
    ("7"		#x3d)
    ("8"		#x3e)
    (","		#x41)
    ("K"		#x42)
    ("I"		#x43)
    ("O"		#x44)
    ("0"		#x45)
    ("9"		#x46)
    ("."		#x49)
    ("/"		#x4a)
    ("L"		#x4b)
    (";"		#x4c)
    ("P"		#x4d)
    ("-"		#x4e)
    ("KP0"		#x70)
    ("["		#x54)
    ("="		#x55)
    ("Caps"		#x58)
    ("ShiftR"		#x59)
    ("'y"		#x52)
    ("Return"		#x5a)
    ("]"		#x5b)
    ("\\"		#x5d)
    ("BackSpace"	#x66)
    ("KP1"		#x69)
    ("KP4"		#x6b)
    ("KP7"		#x6c)
    ("KP0"		#x70)
    ("KP."		#x71)
    ("KP2"		#x72)
    ("KP5"		#x73)
    ("KP6"		#x74)
    ("KP8"		#x75)
    ("Escape"		#x76)
    ("NumLock"		#x77)
    ("F11"		#x78)
    ("KP+"		#x79)
    ("KP3"		#x7a)
    ("KP-"		#x7b)
    ("KP*"		#x7c)
    ("KP9"		#x7d)
    ("Scroll"		#x7e)
    ("F7"		#x83)
    ("AltGr"		#xe0 #x11)
    ("CtrlR"		#xe0 #x14)
    ("KP/"		#xe0 #x4a)
    ("KPEnter"		#xe0 #x5a)
    ("End"		#xe0 #x69)
    ("Left"		#xe0 #x6b)
    ("Home"		#xe0 #x6c)
    ("Ins"		#xe0 #x70)
    ("Del"		#xe0 #x71)
    ("Down"		#xe0 #x72)
    ("Right"		#xe0 #x74)
    ("Up"		#xe0 #x75)
    ("PgDn"		#xe0 #x7a)
    ("PgUp"		#xe0 #x7d)))

(defparameter *symbolics-map*
  '(("Function"		#x43	0 5 2)
    ("Escape"		#x6f	1 5 2)
    ("Refresh"		#x70	2 5 2)
    ("Square"		#x71	3 5 2)
    ("Circle"		#x72	4 5 2)
    ("Triangle"		#x73	5 5 2)
    ("ClearInput"	#x74	6 5 2)
    ("Suspend"		#x75	7 5 2)
    ("Resume"		#x76	8 5 2)
    ("Abort"		#x1e	9 5 2)
    ("Network"		#x38	0 4 2)
    (":"		#x59	1 4)
    (("1" "!")		#x64	2 4)
    (("2" "@")		#x5a	3 4)
    (("3" "#")		#x65	4 4)
    (("4" "$")		#x5b	5 4)
    (("5" "%")		#x66	6 4)
    (("6" "^")		#x5c	7 4)
    (("7" "&")		#x67	8 4)
    (("8" "*")		#x5d	9 4)
    (("9" "(")		#x68	10 4)
    (("0" ")")		#x5e	11 4)
    (("-" "_")		#x69	12 4)
    (("=" "+")		#x5f	13 4)
    (("`" "~")		#x6a	14 4)
    (("\\" "{")		#x60	15 4)
    (("|" "}")		#x6b	16 4)
    ("Help"		#x29	17 4 2)
    ("Local"		#x01	0 3 2)
    ("Tab"		#x4e	1 3 1.5)
    ("Q"		#x4f	2 3)
    ("W"		#x44	3 3)
    ("E"		#x50	4 3)
    ("R"		#x45	5 3)
    ("T"		#x51	6 3)
    ("Y"		#x46	7 3)
    ("U"		#x52	8 3)
    ("I"		#x47	9 3)
    ("O"		#x53	10 3)
    ("P"		#x48	11 3)
    (("(" "[")		#x54	12 3)
    ((")" "]")		#x49	13 3)
    ("BackSpace"	#x55	14 3)
    ("Page"		#x4a	15 3 1.5)
    ("Complete"		#x34	16 3 2)
    ("Select"		#x0c	0 2 2)
    ("RubOut"		#x2d	1 2 1.75)
    ("A"		#x39	2 2)
    ("S"		#x2e	3 2)
    ("D"		#x3a	4 2)
    ("F"		#x2f	5 2)
    ("G"		#x3b	6 2)
    ("H"		#x30	7 2)
    ("J"		#x3c	8 2)
    ("K"		#x31	9 2)
    ("L"		#x3d	10 2)
    ((";" ":")		#x32	11 2)
    (("'" "\"")		#x3e	12 2)
    ("Return"		#x33	13 2 2)
    ("Line"		#x3f	14 2 1.25)
    ("End"		#x13	15 2 2)
    ("CapsLock"		#x02	0 1)
    ("SymbolL"		#x0d	1 1 1.25)
    ("ShiftL"		#x22	2 1 2)
    ("Z"		#x17	3 1)
    ("X"		#x23	4 1)
    ("C"		#x18	5 1)
    ("V"		#x24	6 1)
    ("B"		#x19	7 1)
    ("N"		#x25	8 1)
    ("M"		#x1a	9 1)
    (("," "<")		#x26	10 1)
    (("." ">")		#x1b	11 1)
    (("/" "?")		#x27	12 1)
    ("ShiftR"		#x1c	13 1 2)
    ("SymbolR"		#x28	14 1 1.25)
    ("Repeat"		#x1d	15 1 1.25)
    ("ModeLock"		#x08	16 1 1.25)
    ("HyperL"		#x03	0 0)
    ("SuperL"		#x0e	1 0)
    ("MetaL"		#x04	2 0)
    ("ControlL"		#x0f	3 0 2)
    ("Space"		#x10	4 0 8.5)
    ("ControlR"		#x05	5 0 2)
    ("MetaR"		#x11	6 0)
    ("SuperR"		#x06	7 0)
    ("HyperR"		#x12	8 0)
    ("Scroll"		#x07	9 0 1.5))
  "Definition of Symbolics keyboard scan codes.  One list (NAME
  SCANCODE XPOS YPOS [ SIZE ] ) for each key.  NAME is the name of the
  key, as printed on the key cap.  SCANCODE is the scan code.  XPOS is
  the relative X position of the key, counted from the left.  YPOS is
  the relative Y position of the key, counted from the bottom row.
  SIZE is the size of the key relative to a letter key, which has size
  1 and is the default.")

(defun key-labels (entry)
  (if (listp (first entry))
      (first entry)
      (list (first entry))))

(defun key-name (entry)
  (if (listp (first entry))
      (first (first entry))
      (first entry)))

(defun key-scancode (entry)
  (second entry))

(defun key-x (entry)
  (third entry))

(defun key-y (entry)
  (fourth entry))

(defun key-width (entry)
  (or (fifth entry) 1))

(defun group-on (list &key (test #'eql) (key #'identity) (include-key t))
  (let ((hash (make-hash-table :test test))
        keys)
    (dolist (el list)
      (let ((key (funcall key el)))
        (unless (nth-value 1 (gethash key hash))
          (push key keys))
        (push el (gethash key hash))))    
    (mapcar (lambda (key) (let ((keys (nreverse (gethash key hash))))
                            (if include-key
                                (cons key keys)
                                keys)))
            (nreverse keys))))

(defun find-explicit-mapping (symbolics-keyname &optional f-mode-p)
  (let ((mapping-entry (assoc symbolics-keyname *key-map* :test #'equal)))
    (when mapping-entry
      (let ((mapping (nth (if f-mode-p 2 1) mapping-entry)))
        (cond
          ((listp mapping)
           mapping)
          ((or (symbolp mapping)
               (stringp mapping))
           (or (assoc mapping *ps2-map* :test #'equal)
               (error "invalid special key map entry  ~S, PS/2 key ~A not found"
                      mapping-entry mapping)))
          (t
           (error "unexpected mapping value in map definition entry ~S" mapping-entry)))))))

(defun find-direct-mapping (symbolics-keyname)
  (assoc symbolics-keyname *ps2-map* :test #'equal))

;; bit definitions for flag map

(defconstant +e0-escape+ 1)
(defconstant +prtscr-escape+ 2)
(defconstant +pause+ 4)
(defconstant +key-is-switch+ 8)
(defconstant +f-mode-switch+ 128)

(defun dump-map (map prefix &optional flagsp)
  (dotimes (row 8)
    (format t "~A~A	DB	" prefix row)
    (dotimes (col 16)
      (let ((symbolics-scancode (+ (* row 16) col)))
        (format t (if (or flagsp
                          (find symbolics-scancode *symbolics-map* :test #'eql :key #'second))
                      "~2,'0Xh~@[,  ~]"
                      "~2,' Xh~@[,  ~]")
                (aref map symbolics-scancode) (not (eql col 15)))))
    (terpri))
  (terpri))

(defun define-key (symbolics-scancode ps2-keycode map flag-map &optional f-mode-p)
  (let ((e0-escape-flag (ash +e0-escape+ (if f-mode-p 4 0))))
    (cond
      ((eql #xe0 (car ps2-keycode))
       (setf (aref flag-map symbolics-scancode)
             (logior e0-escape-flag (aref flag-map symbolics-scancode)))
       (setf ps2-keycode (cdr ps2-keycode)))
      (t
       (setf (aref flag-map symbolics-scancode)
             (logand (lognot e0-escape-flag) (aref flag-map symbolics-scancode)))))
  (setf (aref map symbolics-scancode) (car ps2-keycode))))

(defun map-symbolics-key (symbolics-keyname &optional f-mode)
  "Given the name of a symbolics key, return the corresponding PS/2 scan code(s) as a list."
  (cdr (or (when f-mode
             (find-explicit-mapping symbolics-keyname t))
           (find-explicit-mapping symbolics-keyname)
           (find-direct-mapping symbolics-keyname))))

(defun f-mode-key-p (symbolics-key-entry)
  "Return a true value if the key desribed by SYMBOLICS-KEY-ENTRY is a F-mode switch."
  (member (key-name symbolics-key-entry) '("Local" "ModeLock") :test #'equal))

(defun make-keymap ()
  "Print mapping definition arrays in assembler format to
  *standard-output*.  The labels are chosen so that the tables can be
  copied into the kbdlabel assembler source."
  (let ((normal-map (make-array 128 :initial-element 0))
        (f-mode-map (make-array 128 :initial-element 0))
        (flag-map (make-array 128 :initial-element 0))
        unmapped-symbolics-keys
        (unmapped-ps2-keys *ps2-map*))
    (dolist (symbolics-key-entry *symbolics-map*)
      (destructuring-bind (symbolics-keyname symbolics-scancode &rest geometry-info) symbolics-key-entry
        (declare (ignore geometry-info))
        (cond
          ((f-mode-key-p symbolics-key-entry)
           (setf (aref flag-map symbolics-scancode) +f-mode-switch+))
          (t
           (let* ((ps2-keycode (map-symbolics-key symbolics-keyname))
                  (f-mode-ps2-keycode (map-symbolics-key symbolics-keyname t)))
             (cond
               ((or ps2-keycode f-mode-ps2-keycode)
                (when ps2-keycode
                  (setf unmapped-ps2-keys (remove ps2-keycode unmapped-ps2-keys :key #'cdr :test #'equal))
                  (define-key symbolics-scancode ps2-keycode normal-map flag-map))
                (when f-mode-ps2-keycode
                  (setf unmapped-ps2-keys (remove f-mode-ps2-keycode unmapped-ps2-keys :key #'cdr :test #'equal))
                  (define-key symbolics-scancode f-mode-ps2-keycode f-mode-map flag-map t)))
               (t
                (push symbolics-keyname unmapped-symbolics-keys))))))))
    (dump-map normal-map "Symbolics2ATXlt")
    (dump-map f-mode-map "Symbolics2ATXltF")
    (dump-map flag-map "Symbolics2ATXlte" t)
    (when unmapped-symbolics-keys
      (format t "Unmapped Symbolics keys: ~S~%" unmapped-symbolics-keys))
    (when unmapped-ps2-keys
      (format t "Unmapped PS/2 keys: ~S~%" (mapcar #'car unmapped-ps2-keys)))))

(defun draw-keyboard (&optional (label-function #'key-name))
  (pdf:with-saved-state
    (pdf:translate 70 0)
    (pdf:scale 25 25)
    (pdf:set-line-width .05)
    (pdf:set-rgb-stroke 0.2 0.2 0.2)
    (let ((keys (sort (group-on *symbolics-map*
                                :test #'eql
                                :key #'key-y
                                :include-key nil)
                      #'> :key (compose #'key-y #'car)))
          (helvetica (pdf:get-font "Helvetica")))
      (do* ((y 0 (incf y)))
           ((> y 5))
        (let ((row (nth (- 5 y) keys)))
          (pdf:move-to 0 y)
          (pdf:line-to 20 y)
          (do* ((i 0 (incf i))
                (entry (nth i row) (nth i row))
                (x 0))
               ((null (nth i row)))
            (pdf:move-to x y)
            (pdf:line-to x (+ y 1))
            (pdf:stroke)
            (pdf:in-text-mode
              (pdf:set-font helvetica 0.3)
              (pdf:move-text (+ x 0.1) (+ y 0.6))
              (let ((label-text (funcall label-function entry)))
                (cond
                  ((null label-text))
                  ((= 1 (length label-text))
                   (pdf:move-text 0 -0.4)
                   (pdf:draw-text (first label-text)))
                  ((= 2 (length label-text))
                   (pdf:draw-text (first label-text))
                   (pdf:move-text 0 -0.4)
                   (pdf:draw-text (second label-text)))
                  (t
                   (error "unexpected number of elements in labels list ~S returned by label function for entry ~S"
                          label-text entry)))))
            (incf x (key-width entry)))))
      (pdf:move-to 0 6)
      (pdf:line-to 20 6)
      (pdf:stroke)
      (pdf:move-to 20 6)
      (pdf:line-to 20 0)
      (pdf:stroke))))

(defun split-label (string)
  "Split camel case label into multiple words."
  (cl-ppcre:split "(?<=[a-z])(?=[A-Z])" string))

(defun format-key-name (entry)
  "Given a Symbolics key definition entry, return one or two strings
to be used as label for the key."
  (if (= 1 (length (key-labels entry)))
      (split-label (key-name entry))
      (reverse (key-labels entry))))

(defun format-key-scancodes (entry)
  "Given a Symbolics key definition entry, return one or two strings
representing the PS/2 scan code of the key."
  (list (format nil "~{~2,'0X~^ ~}" (map-symbolics-key (key-name entry)))
        (format nil "~{~2,'0X~^ ~}" (map-symbolics-key (key-name entry) t))))

(defun format-key-ps2-name (entry &optional f-mode)
  (cond
    ((equal "ModeLock" (car entry))
     '("F-Mode" "Lock"))
    ((equal "Local" (car entry))
     '("F-Mode"))
    (t
     (let ((scan-codes (map-symbolics-key (key-name entry) f-mode)))
       (split-label (or (car (find scan-codes *ps2-map* :key #'cdr :test #'equal))
                        ""))))))

(defun draw-label (x y text &key (size 12) (font-name "Helvetica-Bold"))
  (let ((helvetica (pdf:get-font font-name)))
    (pdf:in-text-mode
      (pdf:set-font helvetica size)
      (pdf:move-text x y)
      (pdf:draw-text text))))

(defun draw-layout (&optional (pathname #P"layout.pdf"))
  (pdf:with-document ()
    (pdf:with-page ()
      (pdf:with-outline-level ("Symbolics keyboard layout" (pdf:register-page-reference))
        (draw-label 70 800 "kbdbabel-symbolics Symbolics to PS/2 Adapter key code mapping" :size 14)
        (draw-label 240 10 "kbdbabel for Symbolics keyboard - by Alexander Kurz and Hans Hübner - http://kbdbabel.net/"
                    :size 8 :font-name "Helvetica")
        (draw-label 70 35 "PS/2 scan codes (top: standard, bottom: F-mode)")
        (pdf:translate 0 50)
        (draw-keyboard #'format-key-scancodes)
        (draw-label 70 175 "F-Mode mapping")
        (pdf:translate 0 190)
        (draw-keyboard (rcurry #'format-key-ps2-name t))
        (draw-label 70 175 "Standard mapping")
        (pdf:translate 0 190)
        (draw-keyboard #'format-key-ps2-name)
        (draw-label 70 175 "Key caps")
        (pdf:translate 0 190)
        (draw-keyboard #'format-key-name)))
    (pdf:write-document pathname)))