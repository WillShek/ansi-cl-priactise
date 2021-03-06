;;;; this source file contains all the demos and exercises in chapter 4

;; 对顺序排列的 vec 进行二叉搜索
(defun bin-search (obj vec)
  (let ((len (length vec)))
    (and (not (zerop len))
         (finder obj vec 0 (- len 1)))))

;; 闭区间[start, end] start and end are indexes
(defun finder (obj vec start end) 
  (let ((range (- end start)))
    (if (zerop range) ; 区间内只有一个元素 base case
        (if (eql obj (svref vec start)) 
            obj
            nil)
        (let ((mid (+ start (round (/ range 2)))))
          (let ((obj2 (svref vec mid)))
            (if (> obj obj2)  ; 其实这里用cond比较好
                (finder obj vec (+ mid 1) end)
                (if (< obj obj2)
                    (finder obj vec start (- mid 1))
                    obj)))))))

;; 针对向量的回文判断 elt版本
(defun mirror? (s)
  (do ((forward 0 (+ forward 1))
       (back (- (length s) 1) (- back 1)))
      ((or (>= forward back)
           (not (eql (elt s forward)
                     (elt s back))))
       (>= forward back))))

;; split a string and get the second word 
(defun second-word (s)
  (let ((p1 (position #\  s))) ; 空格的表示"#\ "
    (if p1
        (subseq s (+ p1 1) (position #\  s :start (+ 1 p1))))))

;;; 下面是解析日期的部分
;; 根据规则将字符串分割 (tokens "30 Nov 2014" #'constituent 0) 
;; => ("30" "Nov" "2014")
(defun tokens (str &optional (test #'constituent) (start 0))
  (let ((p1 (position-if test str :start start)))
    (if p1
        (let ((p2 (position-if #'(lambda (c)
                                   (not (funcall test c)))
                               str :start (+ p1 1))))
          (cons (subseq str p1 p2)
                (if p2
                    (tokens str test p2)))))))
;; 判断字符是不是可以显示的字符，不包含空格
(defun constituent (c)
  (and (graphic-char-p c)
       (not (char= c #\Space)))) ; 空格的表示2种方式"#\ "

;; 日期转换函数，入口 (parse-date "30 Nov 2014") => (30 11 2014)
(defun parse-date (date-str)
  (let ((toks (tokens date-str #'constituent 0)))
    (list (parse-integer (first toks))
          (parse-month (second toks))
          (my-parse-integer (third toks)))))
;; 定义月份的常量向量
(defconstant month-names
  #("jan" "feb" "mar" "apr" "may" "jun"
    "jul" "aug" "sep" "oct" "nov" "dec"))
;; 解析月份 (parse-month "Feb") => 2
(defun parse-month (str) 
  (let ((p (position str month-names :test #'string-equal)))
    (if p
        (incf p)
        nil)))

;; TODO 功能更加强大的整数转化 加入关键字参数，加入进制
;; 加入科学计数表示法，加入+-号
;; 自定义 parse-integer  (my-parse-integer "123") => 123
(defun my-parse-integer (str)
  (and (every #'digit-char-p str)
       (let ((res 0))
         (dotimes (index (length str) res)
           (setf res (+ (* 10 res)
                        (digit-char-p (char str index))))))))



;;; BST -- Binary Search Tree
;; node 
(defstruct (node (:print-function
                  (lambda (node s d) ; 打印函数必须接受三个参数
                    (format s "#<~A>" (node-elt node)))))
  elt
  (l nil)
  (r nil))
;; insert 非平衡的
;; obj---要查入到树中的元素的值
;; bst---二叉搜索树
;; <---表示的是比较函数 不是小于运算符
(defun bst-insert (obj bst <)
  (if (null bst)
      (make-node :elt obj)
      (let ((elt (node-elt bst)))
        (if (eql elt obj) ; 已经存在此元素则不再插入 base case
            bst
            (if (funcall < obj elt)
                (make-node :elt elt
                           :l (bst-insert obj (node-l bst) <)
                           :r (node-r bst))
                (make-node :elt elt
                           :l (node-l bst)
                           :r (bst-insert obj (node-r bst) <)))))))
;; search
(defun bst-find (obj bst <)
  (if bst
      (let ((elt (node-elt bst)))
        (if (eql obj elt)
            bst
            (if (funcall < obj elt)
                (bst-find obj (node-l bst) <)
                (bst-find obj (node-r bst) <))))))
;; min
(defun bst-min (bst)
  (and bst
       (or (bst-min (node-l bst)) bst)))
;; max 
(defun bst-max (bst)
  (and bst
       (or (bst-max (node-r bst)) bst)))
;; remove min
(defun bst-remove-min (bst)
  (if (null (node-l bst))
      (node-r bst)
      (make-node :elt (node-elt bst)
                 :l (bst-remove-min (node-l bst))
                 :r (node-r bst))))
;; remove max 
(defun bst-remove-max (bst)
  (if (null (node-r bst))
      (node-l bst)
      (make-node :elt (node-elt bst)
                 :l (node-l bst)
                 :r (bst-remove-max (node-r bst)))))
;; remove obj from bst
(defun bst-remove (obj bst <)
  (if bst
      (let ((elt (node-elt bst)))
        (if (eql obj elt)
            (percolate bst)
            (if (funcall < obj elt)
                (make-node :elt elt
                           :l (bst-remove obj (node-l bst) <)
                           :r (node-r bst))
                (make-node :elt elt
                           :l (node-l bst)
                           :r (bst-remove obj (node-r bst) <)))))))
(defun percolate (bst)
  (let ((l (node-l bst)) (r (node-r bst)))
    (cond ((null l) r)
          ((null r) l)
          (t (if (zerop (random 2)) ;; 这里随机选择前驱或者是后继
                 (make-node :elt (node-elt (bst-max l))
                            :l (bst-remove-max l)
                            :r r)
                 (make-node :elt (node-elt (bst-max r))
                            :l l
                            :r (bst-remove-min r)))))))
;; print 前序
(defun print-bst (bst)
  (when bst
    (format t "~A <--~A--> ~A~%" (node-l bst) bst (node-r bst))
    (print-bst (node-l bst))
    (print-bst (node-r bst))))
;; 中序输出 排序
(defun bst-traverse (fn bst)
  (when bst
    (bst-traverse fn (node-l bst))
    (funcall fn (node-elt bst))
    (bst-traverse fn (node-r bst))))

;; BST的测试函数
(defun bst-test()
  (let ((nums))
    (progn
      (format t "insert 5 8 4 2 1 9 6 7 3 ...~%")
      (dolist (x '(5 8 4 2 1 9 6 7 3)) ; insert nums 
        (setf nums (bst-insert x nums #'<)))
      (format t "if 12 exists? ~A" 
              (if (bst-find 12 nums #'<) "yes" "no"))
      (format t "~%if 9 exists? ~A" 
              (if (bst-find 9 nums #'<) "yes" "no"))
      (format t "~%min:~t~A" (bst-min nums))
      (format t "~%max:~t~A" (bst-max nums))
      (format t "~%before remove:~%print:~%")
      (print-bst nums)
      (format t "bst-traverse: ")
      (bst-traverse #'(lambda (x) (format t "~A, " x)) nums)
      (setf nums (bst-remove 2 nums #'<))
      (format t "~%after remove 2:~%print:~%")
      (print-bst nums)
      (format t "bst-traverse:~%~T")
      (bst-traverse #'princ nums))))

;; labels
;; return k*n
(defun recursive-times (k n)
  (labels ((temp (n) 
             (if (zerop n) 0 (+ k (temp (1- n))))))
    (temp n)))
;; labels中函数定义不分先后 可相互使用，但是不要死锁！ 
(defun labels-test ()
  (labels ((f2 (c d) (+ (f1 100 c) d))
           (f1 (a b) (+ a b)))
    (+ (f1 2 3) (f2 3 4))))


;; Exercises
;; ex1
;; 这里主要是找到一个规律
;; 在旋转的时候把原来的一个整行当作一个整体考虑
;; 坐标的值：
;;   顺时针旋转一个正方的二维数组的话，原来的列坐标变为现在的行坐标
;; 正方形的行数-1-原来的列坐标变为现在的行坐标 即可 
;; 逆时针则调换上面两条原则即可
(defun quarter-turn (arr)
  (and arr
       (let ((dim (array-dimensions arr)))
         (let ((d (car dim)) (new-arr (make-array dim)))
           (do ((i 0 (incf i))) ((= i d))
             (do ((j 0 (incf j))) ((= j d))
               (setf (aref new-arr j (- d 1 i)) (aref arr i j))))
           new-arr))))

;; ex2
;; a-V1 define copy-list using append 
(defun my-copy-list-append (lst)
  (reduce #'(lambda (lst obj) (append lst (list obj))) 
          lst :initial-value nil))
;; a-V2 define copy-list using cons
(defun my-copy-list-cons (lst)
  (reduce #'cons lst :from-end t :initial-value nil))
;; (reduce #'(lambda (a lst) (cons a lst)) '(a b c) :from-end t :initial-value nil)
;;; 从此处看出，默认是左结合，加入 :from-end t 之后，变为了右结
;;; 合，这时候要一定注意上面lambda中的参数的顺序，左结合的时候上
;;; 次的结果作为第一个参数，右结合的时候作为第二个参数！

;; b define reverse using cons
(defun my-reverse (lst)
  (reduce #'(lambda (lst obj) (cons obj lst)) 
          lst :initial-value nil))

;; ex3 Define a structure to represent a tree where each node 
;; contains some data and has up to three children.  Define 
(defstruct my-node
  elt 
  left
  middle
  right)
;; (a) Define a function to copy such a tree (so that no node 
;; in the copy is eql to a node in the original) 
(defun copy-t (tree)
  (and tree
       (make-my-node :elt (my-node-elt tree)
                     :left (copy-t (my-node-left tree))
                     :middle (copy-t (my-node-middle tree))
                     :right (copy-t (my-node-right tree)))))
;; (b) Define a function that takes an object and such a tree, 
;; and returns true if the object is eql to the data field of 
;; one of the nodes 
(defun value-test (obj tree)
  (if tree
      (or
       (eql (my-node-elt tree) obj)
       (value-test (my-node-left tree) obj)
       (value-test (my-node-middle tree) obj)
       (value-test (my-node-right tree) obj))))

;;; ex4: Define a function that takes a BST and returns a list 
;;; of its elements ordered from greatest to least. 
;; ex4-v1 注意 ex4要求返回的列表是由大到小
(defun bst-ordered-list (bst)
  (if bst
      (append (bst-ordered-list (node-r bst))
              (list (node-elt bst))
              (bst-ordered-list (node-l bst)))))
;;; 练习4的V2和V3版本是在函数的参数中蕴藏玄机，这样子定义的
;;; 递归函数从形参上进行思考就十分的好理解
;; ex4-V2
(defun bst->list (bst0)
  (labels ((rec (bst1 acc)
             (if bst1
                 (rec (node-r bst1) 
                      (cons (node-elt bst1) 
                            (rec (node-l bst1) acc)))
                 acc)))
    (rec bst0 nil)))
;; ex4-V3
(defun bst->lst (bst0)
  (labels ((rec (bst1 acc)
             (if bst1
                 (rec (node-l bst1) 
                      (append (rec (node-r bst1) acc) 
                              (list (node-elt bst1))))
                 acc)))
    (rec bst0 nil)))

;; ex5 上面的 bst-insert 与 bst-adjoin 功能一样
;; ex6
;; a
(defun assoc->hash (a)
  (if a
      (let ((h (make-hash-table)))
        (dolist (e a)
          (setf (gethash (car e) h) (cdr e)))
        h)))
;; b-V1
(defun hash->assoc (h)
  (if h
      (let ((lst nil)) ; (let (lst)
        (maphash #'(lambda (k v)
                     (setf lst (cons (cons k v) lst)))
                 h)
        lst)))
;; b-V2
(defun hash->lst (ht)
  (let ((acc nil)) ; (let (acc)
    (maphash #'(lambda (k v) (push (cons k v) acc)) ht)
    acc))
;; push is more effective than consing a obj to a list

