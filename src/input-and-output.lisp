(defun pseudo-cat (file)
  (with-open-file (str file :direction :input)
	(do ((line (read-line str nil 'eof)
			   (read-line str nil 'eof)))
		((eql line 'eof))
	  (format t "~A~%" line))))

(defun read-1()
  (type-of (read)))

;; String Substitution -- an execllent example!
(defstruct buf
  vec (start -1) (used -1) (new -1) (end -1))

(defun bref (buf n)
  (svref (buf-vec buf)
		 (mod n (length (buf-vec buf)))))

(defun (setf bref) (val buf n)
  (setf (svref (buf-vec buf)
			   (mod n (length (buf-vec buf))))
		val))

(defun new-buf (len)
  (make-buf :vec (make-array len :initial-element nil)))

(defun buf-insert (x b)
  (setf (bref b (incf (buf-end b))) x))

(defun buf-pop (b)
  (prog1 
	  (bref b (incf (buf-start b)))
	(buf-reset b)))

(defun buf-next (b)
  (when (< (buf-used b) (buf-new b))
	(bref b (incf (buf-used b)))))

(defun buf-reset (b)
  (setf (buf-used b) (buf-start b)
		(buf-new b) (buf-end b)))

(defun buf-clear (b)
  (setf (buf-start b) -1 (buf-used b) -1
		(buf-new b) -1 (buf-end b) -1))

(defun buf-flush (b str)
  (do ((i (1+ (buf-used b)) (1+ i)))
	  ((> i (buf-end b)))
	(princ (bref b i) str)))

(defun file-subst (old new file1 file2)
  (with-open-file (in file1 :direction :input)
	(with-open-file (out file2 :direction :output
						 :if-exists :supersede)
	  (stream-subst old new in out))))

(defun stream-subst (old new in out)
  (let* ((pos 0)
         (len (length old))
         (buf (new-buf len))
         (from-buf nil))
    (do ((c (read-char in nil :eof)
            (or (setf from-buf (buf-next buf))  ;; setf 会返回最后一个参数求值结果
                (read-char in nil :eof))))
        ((eql c :eof))
      (cond ((char= c (char old pos))
             (incf pos)
             (cond ((= pos len)            ; 3 字符相等 并且 现在是全部相等
                    (princ new out)
                    (setf pos 0)
                    (buf-clear buf))
                   ((not from-buf)         ; 2 字符相等又不是从buf中获取的。插入buf中，buf中的标位除了end都不动
                    (buf-insert c buf))))
            ((zerop pos)                   ; 1 字符至今没有匹配上
             (princ c out)
             (when from-buf                ; 如果是从buf中获取的字符，需要pop出并重置
               (buf-pop buf)))
            (t                             ; 4 之前有相等的，但是现在不相等了
             (unless from-buf              ; 如果不是从buf中拿来的字符 需要加入到buf中，修改end
               (buf-insert c buf))         ; 这里就是为了保留火种！很巧妙，现在暂时不相等以后未必不相等，这个字符说不定和old的第一个字符相等
             (princ (buf-pop buf) out)     ; 在这种情况下，需要将buf中的第一个取出来 这个时候buf中一定是有数据的！并且避免了死循环！
             (setf pos 0))))
    (buf-flush buf out)))
;; CL-USER> (file-subst "baro" "baric" "a.txt" "b.txt")


;; Exercises
;; ex1
(defun file-to-lststr(file)
  (let ((acc nil))
	(with-open-file (str file :direction :input)
	  (do ((line (read-line str nil 'eof)
				 (read-line str nil 'eof)))
		  ((eql line 'eof))
		(push line acc)))
	(reverse acc)))
;; ex2
(defun file-to-lstexp(file)
  (let ((acc nil))
	(with-open-file (str file :direction :input)
	  (do ((exp (read str nil 'eof)
				(read str nil 'eof)))
		  ((eql exp 'eof))
		(push exp acc)))
	(reverse acc)))
;; ex3
(defun appendwithoutnotation(file1 file2)
  (with-open-file (in file2 :direction :input)
	(with-open-file (out file1 :direction :output
						 :if-exists :append)
	  (do ((line (read-line in nil :eof)
				 (read-line in nil :eof)))
		  ((eql line :eof))
		(terpri out)
		(princ (subseq line 0 (position #\% line)) out)))))
;; ex4
(defun print-float-array (farr)
  (let ((dimens (array-dimensions farr)))
	(dotimes (i (first dimens))
	  (dotimes (j (second dimens))
		(format t "~10,2,0,,' F" (aref farr i j)))
	  (terpri))))
;; ex5 wildcards "+"   reference the source file input-and-ouput-ex5.lisp
;; ex6 reference the source file input-and-output-ex6.lisp

