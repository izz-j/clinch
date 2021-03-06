;;;; shapes.lisp
;;;; Please see the licence.txt for the CLinch 
;; 
(in-package #:clinch)

(defun make-quad-indices ()
  (make-instance 'clinch:index-buffer :data '(0 1 2 0 2 3)))

(defun make-quad-vertexes (width height &key (center :center))

  (let* ((x/2 (float (/ width 2)))
	 (y/2 (float (/ height 2)))
	 (x)
	 (y) 
	 (-x)
	 (-y))

    (if (typep center 'SIMPLE-ARRAY)
	(let ((x-offset (aref center 0))
	      (y-offset (aref center 1)))
	  (setf x  (+ x/2 x-offset)
		-x (+ (- x/2) x-offset)
		y  (+ y/2 y-offset)
		-y (+ (- y/2) y-offset)))
    (case center
      (:center (setf x  x/2
		     -x (- x/2)
		     y  y/2
		     -y (- y/2)))
      (:top-center (setf x x/2
			 -x (- x/2)
			 y 0.0 
			 -y (- height)))
      (:bottom-center (setf x  x/2
			    -x (- x/2)
			    y  height
			    -y 0.0))
      (:center-left (setf x  width
			  -x 0.0
			  y  y/2
			  -y (- y/2)))
      (:center-right (setf x 0.0
			   -x (- width)
			   y  y/2
			   -y (- y/2)))
      (:top-left (setf x width
		       -x 0.0
		       y 0.0
		       -y (- height)))
      (:bottom-left (setf x width
			  -x 0.0
			  y height
			  -y 0.0))
      (:top-right (setf x 0.0
			-x (- width)
			y 0.0
			-y (- height)))
      
      (:bottom-right (setf x 0.0
			   -x (- width)
			   y height
			   -y 0.0))))
    

    (make-instance 'clinch:buffer 
		   :Stride 3
		   :data (map 'list (lambda (x)
				      (coerce x 'single-float))
			      (list  -x  y 0
				     -x  -y 0
				     x  -y 0
				     x   y 0)))))



(defun make-quad-texture-coordinates ()
  (make-instance 'clinch:buffer 
		 :Stride 2
		 :data (map 'list (lambda (x)
				    (coerce x 'single-float))
			    '(0.0   1.0
			      0.0   0.0
			      1.0   0.0
			      1.0   1.0))))

(defun make-quad (width height &key (center :center) shader-program texture (parent *node*))
  "Creates a quad entity of width and height."
  (make-instance 'clinch:entity
		 :parent parent
		 :shader-program (or shader-program (get-generic-single-texture-shader))
		 :indexes (make-quad-indices)
		 :attributes (copy-list `(("v" . ,(make-quad-vertexes width height :center center))
					  ("tc1" . ,(make-quad-texture-coordinates))))
		 :uniforms (copy-list `(("M" . :model)
					("P" . :projection)
					("t1" . ,(or texture (get-identity-texture)))))))

(defmethod make-quad-for-texture ((this texture) &key width height (center :center) shader-program parent no-parent)
  "Creates a quad for a texture which defaults to texture's width and height."
  (make-quad (or width (width this))
	     (or height (height this))
	     :center center
	     :shader-program shader-program
	     :texture this
	     :parent parent))

(defmethod make-quad-and-texture (width height &key (center :center) shader-program (parent *node*) no-parent)
  (make-quad-for-texture
   (make-instance 'texture :width width :height height)
   :center center :shader-program shader-program :parent parent :no-parent no-parent))


(defun get-default-texture ()
  (unless *texture* 
    (setf *texture* 
	  (make-instance 'texture 
			 :width (width *viewport*)
			 :height (height *viewport*))))
  (unless *entity*
    (setf *entity*
	  (make-quad-for-texture *texture* :parent nil)))
  *texture*)


(defun make-sphere ()
  (multiple-value-bind (verts indices normals) (get-sphere-vertex-normal-and-index-buffers)
    
    (make-instance 'clinch:entity
		   :parent nil
		   :shader-program (get-generic-single-diffuse-light-shader)
		   :indexes indices
		   :attributes (copy-list `(("v" . ,verts)
					    ("n" . ,normals)
					    ("c" . (1.0 1.0 1.0 1.0))
					    ("tc1" . (0 0))))
		   :uniforms (copy-list `(("M" . :model)
					  ("P" . :projection)
					  ("N" . :normal)
					  ("t1" . ,(get-identity-texture))
					  ("ambientLight" . (.2 .2 .2))
					  ("lightDirection" . (0.5772705 -0.5772705 -0.5772705))
					  ("lightIntensity" . (.8 .8 .8)))))))



;; Interesting note: the normals are the same as the vertices.    
(defun get-sphere-vertex-normal-and-index-buffers ()
  (let* ((ICX 0.525731112119133606)
	 (ICZ 0.850650808352039932)
	 (v (make-instance 'buffer :data
			   (map 'list (lambda (x)
					(coerce x 'single-float))
				
				`( ,(- ICX) 0 ,ICZ
				    ,ICX 0 ,ICZ
				    ,(- ICX) 0 ,(- ICZ)
				    ,ICX 0 ,(- ICZ)
				    0 ,ICZ ,ICX
				    0 ,ICZ ,(- ICX)
				    0 ,(- ICZ) ,ICX
				    0 ,(- ICZ) ,(- ICX)
				    ,ICZ ,ICX 0
				    ,(- ICZ) ,ICX 0
				    ,ICZ ,(- ICX) 0
				    ,(- ICZ) ,(- ICX) 0)))))
    (values v 
	    (make-instance 'index-buffer 
			   :data '(0 1 4	  
				   0 4 9
				   9 4 5	
				   4 8 5
				   4 1 8
				   8 1 10
				   8 10 3  
				   5 8 3
				   5 3 2
				   2 3 7
				   7 3 10
				   7 10 6
				   7 6 11
				   11 6 0 
				   0 6 1 	
				   6 10 1
				   9 11 0
				   9 2 11
				   9 5 2	
				   7 11 2))
	    v)))
    

(defun make-box ()
  (multiple-value-bind (verts indices) (get-box-vertex-normal-texture-and-index-buffers)
    
    (make-instance 'clinch:entity
		   :parent nil
		   :shader-program (get-generic-single-color-shader)
		   :indexes indices
		   :attributes (copy-list `(("v" . ,verts)))
		   :uniforms (copy-list `(("M" . :model)
					  ("P" . :projection)
					  ("color" . (1 1 1 1)))))))


(defun get-box-vertex-normal-texture-and-index-buffers ()
  (! (values 
      (make-instance 'clinch:buffer 
		     :Stride 3
		     :data '(-0.5 -0.5  0.5
			     0.5 -0.5  0.5
			     -0.5  0.5  0.5
			     0.5  0.5  0.5
			     -0.5 -0.5 -0.5
			     0.5 -0.5 -0.5
			     -0.5 -0.5  0.5
			     0.5 -0.5  0.5
			     -0.5  0.5 -0.5
			     0.5  0.5 -0.5
			     -0.5 -0.5 -0.5
			     0.5 -0.5 -0.5
			     -0.5  0.5  0.5
			     0.5  0.5  0.5
			     -0.5  0.5 -0.5
			     0.5  0.5 -0.5
			     0.5 -0.5  0.5
			     0.5 -0.5 -0.5
			     0.5  0.5  0.5
			     0.5  0.5 -0.5
			     -0.5 -0.5 -0.5 
			     -0.5 -0.5  0.5 
			     -0.5  0.5 -0.5 
			     -0.5  0.5  0.5))

      (make-instance 'clinch:index-buffer 
		     :data '(0  1  2 
			     2  1  3
			     4  5  6
			     6  5  7
			     8  9 10 
			     10  9 11
			     12 13 14 
			     14 13 15
			     16 17 18 
			     18 17 19
			     20 21 22 
			     22 21 23))


      (make-instance 'clinch:buffer 
		  :data '(0.0 0.0 1.0
			  0.0 0.0 1.0
			  0.0 0.0 1.0
			  0.0 0.0 1.0
			  0.0 -1.0 0.0
			  0.0 -1.0 0.0
			  0.0 -1.0 0.0
			  0.0 -1.0 0.0
			  0.0 0.0 -1.0
			  0.0 0.0 -1.0
			  0.0 0.0 -1.0
			  0.0 0.0 -1.0
			  0.0 1.0 0.0
			  0.0 1.0 0.0
			  0.0 1.0 0.0
			  0.0 1.0 0.0
			  1.0 0.0 0.0
			  1.0 0.0 0.0
			  1.0 0.0 0.0
			  1.0 0.0 0.0
			  -1.0 0.0 0.0
			  -1.0 0.0 0.0
			  -1.0 0.0 0.0
			  -1.0 0.0 0.0))

      (make-instance 'clinch:buffer 
		  :Stride 2
		  :data '(0.0 1.0
			  1.0 1.0
			  0.0 0.0
			  1.0 0.0
			  0.0 1.0
			  1.0 1.0
			  0.0 0.0
			  1.0 0.0
			  0.0 1.0
			  1.0 1.0
			  0.0 0.0
			  1.0 0.0
			  0.0 1.0
			  1.0 1.0
			  0.0 0.0
			  1.0 0.0
			  0.0 1.0
			  1.0 1.0
			  0.0 0.0
			  1.0 0.0
			  0.0 1.0
			  1.0 1.0
			  0.0 0.0
			  1.0 0.0)))))


(defun make-cylinder (&optional (sides 10))
  (multiple-value-bind (verts indices) (get-cylinder-vertex-normal-and-index-buffers sides)
    
    (make-instance 'clinch:entity
		   :parent nil
		   :shader-program (get-generic-single-color-shader)
		   :indexes indices
		   :attributes (copy-list `(("v" . ,verts)))
		   :uniforms (copy-list `(("M" . :model)
					  ("P" . :projection)
					  ("color" . (1 1 1 1)))))))


(defun get-cylinder-vertex-normal-and-index-buffers (sides)
  (multiple-value-bind (v n)
      (loop 
	 for i from 0 below (* 2 pi) by (/ (* 2 pi) sides)
	 for x = (cos i)
	 for y = (sin i)
	 append (list x y  0.5
		      x y -0.5
		      x y  0.5
		      x y -0.5)  into verts
	 append (list x y 0.0
		      0.0 0.0 1.0
		      x y 0.0
		      x y -1.0) into norms
	   
	 finally (return (values verts norms)))
    (setf v (append v '(0.0 0.0 0.5 0.0 0.0 -0.5)))
    (setf n (append n '(0.0 0.0 0.5 0.0 0.0 -0.5)))
    (let* ((len (/ (length v) 3)))
      (values (make-instance 'buffer :data (map 'list (lambda (x) (coerce x 'float)) v))
	      (make-instance 'index-buffer
			     :data (loop for x from 0 below sides
				      append (let ((offset (* x 4)))						     
					       (map 'list (lambda (y)
							    (if (< y 0)
								(+ len y)
								(mod (+ offset y) (- len 2))))
						    `(0 1 4 1 5 4  ; side
							5 1 -1 
							0 4 -2)))))
	      (make-instance 'buffer :data (map 'list (lambda (x) (coerce x 'float)) n))))))
				 
			
	      

(defun random-heightfield (w h)
  (make-array (* w h 3)
	      :element-type 'single-float
	      :initial-contents 
	      (map 'list (lambda (x)
			   (coerce x 'single-float))
		   (loop for i from 0 below w
		      append (loop for j from 0 below h
				append (list j
					     (/ (random 1000) 1000)
					     i))))))


(defun heightmap->buffers (arr w h)
  (let ((tx (/ (1- w)))
	(ty (/ (1- h)))
	(points)
	(normals)
	(tex-coords))
    
  (labels ((get-point (x)
	     (let ((start (* 3 x)))
	       (subseq arr start (+ 3 start))))
	   
	   (make-triangle (a b c)
	     (let ((n (v3:normalize 
		       (v3:cross (v3:- b a) (v3:- c a)))))
	       (values (concatenate 'vector a b c)
		       (concatenate 'vector n n n))))

	   (add-triangle (a)
	     (multiple-value-bind (p n)
		 (apply #'make-triangle 
			(map 'list #'get-point a))
	        (push p points)
	        (push n normals)))

	   (add-tc (x y)
	     (push (v! (* tx x) (* ty y)) tex-coords)
	     (push (v! (* tx (1+ x)) (* ty y)) tex-coords)
	     (push (v! (* tx x) (* ty (1+ y))) tex-coords)

	     (push (v! (* tx (1+ x)) (* ty y)) tex-coords)
	     (push (v! (* tx (1+ x)) (* ty (1+ y))) tex-coords)
	     (push (v! (* tx x) (* ty (1+ y))) tex-coords)))
	     
    (loop for i from 0 below (1- w)
       do (loop for j from 0 below (1- h)
	     for a1 = (+ j (* w i))
	     for a2 = (1+ a1)
	     for b1 = (+ w a1)
	     for b2 = (1+ b1)
	       
	     do (progn (add-triangle (list a1 a2 b1))
		       (add-triangle(list a2 b2 b1))
		       (add-tc i j))))
	
				
    (values (make-instance 'buffer :data (apply #'concatenate 'vector (reverse points)))
	    (make-instance 'index-buffer 
			   :data (loop for i from 0 below (* 3 2 w h)
				    collect i))
	    (make-instance 'buffer :data (apply #'concatenate 'vector (reverse normals)))
	    (make-instance 'buffer :stride 2 :data (apply #'concatenate 'vector (reverse tex-coords)))))))


(defun make-heightmap-entity (height-map w h &optional texture)
  (multiple-value-bind (verts indices normals tex) (heightmap->buffers height-map w h)
    
    (make-instance 'clinch:entity
		   :parent nil
		   :shader-program (get-generic-single-diffuse-light-shader)
		   :indexes indices
		   :attributes (copy-list `(("v" . ,verts)
					    ("n" . ,normals)
					    ("c" . (1.0 1.0 1.0 1.0))
					    ("tc1" . ,tex))) ;;,(or texture-coordinate-buffer '(0 0))))
		   :uniforms (copy-list `(("M" . :model)
					  ("P" . :projection)
					  ("N" . :normal)
					  ("t1" . ,(or texture (get-identity-texture)))
					  ("ambientLight" . (.2 .2 .2))
					  ("lightDirection" . (0.5772705 -0.5772705 -0.5772705))
					  ("lightIntensity" . (.8 .8 .8)))))))



(defun make-dummy-entity (num-points triangles &key texture)
  
    (! (let ((indexes (make-instance 'index-buffer :count (* triangles 3)))
	     (points  (make-instance 'buffer :count (* num-points 3)))
	     (normals (make-instance 'buffer :count (* num-points 3)))
	     (tex-coords (make-instance 'buffer :count (* num-points 2))))

        (make-instance 'clinch:entity
		   :parent nil
		   :shader-program (get-generic-single-diffuse-light-shader)
		   :indexes indexes
		   :attributes (copy-list `(("v" . ,points)
					    ("n" . ,normals)
					    ("c" . (1.0 1.0 1.0 1.0))
					    ("tc1" . ,tex-coords)))
		   :uniforms (copy-list `(("M" . :model)
					  ("P" . :projection)
					  ("N" . :normal)
					  ("t1" . ,(or texture (get-identity-texture)))
					  ("ambientLight" . (.2 .2 .2))
					  ("lightDirection" . (0.5772705 -0.5772705 -0.5772705))
					  ("lightIntensity" . (.8 .8 .8))))))))

(defmethod delete-entity ((this entity) &key)

  (map nil #'unload (attributes this))
  ;;(map nil #'unload (uniforms this))
  (unload (indexes this))
  (unload this)
  nil)

(defun set-point (arr num x y z)
  (setf (elt arr (+ num 0)) x)
  (setf (elt arr (+ num 1)) y)
  (setf (elt arr (+ num 2)) z))

(defmacro average-vectors (&rest v)
  `(map 'list (lambda (x)
		(/ x 4))
	(map 'list #'+
	     ,@v)))

(defun get-point-or-vert (arr x y w h)
  (cond ((< x 0)  nil)
	((>= x w) nil)
	((< y 0)  nil)
	((>= y h) nil)
	(t (let ((pos (* 3 (+ x (* y w)))))
	     
	     (v! (elt arr (+ pos 0))
		 (elt arr (+ pos 1))
		 (elt arr (+ pos 2)))))))


(defun get-middle-square-and-normal (arr x y w h)
  (let* ((bl (get-point-or-vert arr x y w h))
	 (br (get-point-or-vert arr (1+ x) y w h))
	 (tl (get-point-or-vert arr x (1+ y) w h))
	 (tr (get-point-or-vert arr (1+ x) (1+ y) w h))
	 (center (v3:/s (v3:+ (v3:+ (v3:+ bl br) tl) tr)
			4.0))
	 (bl- (v3:- bl center))
	 (br- (v3:- br center))
	 (tl- (v3:- tl center))
	 (tr- (v3:- tr center)))
    (values
     (v3:normalize
      (reduce #'v3:+ 
	      (list (v3:cross br- bl-)
		    (v3:cross bl- tl-)
		    (v3:cross tl- tr-)
		    (v3:cross tr- br-))))
     center)))


(defun get-middle-squares-and-normals (arr w h)
  (let ((tmp (loop for y from 0 below (1- h)
		append (loop for x from 0 below (1- w)
			  collect (multiple-value-bind (a b) 
				      (get-middle-square-and-normal arr x y w h)
				    (list a b (list (/ (+ .5 x) (1- w))
						    (/ (+ .5 y) (1- h)))))))))
    (values (map 'list #'second tmp)  ;; vertexes
	    (map 'list #'first tmp)   ;; normals 
	    (map 'list #'third tmp))));; tex-coords 
	    

(defun get-height-node-normal (arr x y w h)

  (let ((c (get-point-or-vert arr x y w h)))
    (labels ((get-vec-or-none (x y)
	       (let ((p (get-point-or-vert arr x y w h)))
		 (when p 
		   (v3:- p c))))
	     (cross-x (a b)
	       (if (and a b)
		   (v3:cross a b)
		   (v! 0 0 0))))
      
      (let ((l (get-vec-or-none (1- x) y))
	    (r (get-vec-or-none (1+ x) y))
	    (b (get-vec-or-none x (1- y)))
	    (top  (get-vec-or-none x (1+ y))))
	
	(v3:normalize 
	 (reduce #'v3:+ (list 
			 (cross-x l top)
			 (cross-x b l)
			 (cross-x r b)
			 (cross-x top r))))))))

(defun get-height-node-normals (arr w h)
  (loop for y from 0 below h
       append (loop for x from 0 below w
		 collect (get-height-node-normal arr x y w h))))
		     

(defun tst (e arr w h &key texture)
  (let* ((squares (* (1- w) (1- h)))
	 (triangles (* squares 4))
	 (num-points (* triangles 3))
	 (indexes)
	 (points)
	 (normals)
	 (tex-coords))
	
    ;; So processing can be done in another thread...    
    (! 
      ;;(setf e (make-dummy-entity num-points triangles))
      (setf indexes (pullg (indexes e))
	    points  (pullg (attribute e "v"))
	    normals (pullg (attribute e "n"))
	    tex-coords (pullg (attribute e "tc1"))))

    ;; Now create the data...
    (loop for x from 0 below (length arr) 
       do (setf (elt points (* x 3)) 
		(elt arr x)))))



;; :attributes `(("v" . ,verts)
;; 	      ("n" . ,normals))
;; :uniforms `(("M" . :model)
;; 	    ("P" . :projection)
;; 	    ("color" . (1 1 1 1))))))

;; (make-instance 'clinch:entity
;; 	       :parent parent
;; 	       :shader-program (cond (shader-program shader-program)
;; 					      (bones (get-generic-single-diffuse-light-animation-shader))
;; 					      (t (get-generic-single-diffuse-light-shader)))
;; 			:indexes index-buffer
;; 			:attributes `(("v" . ,vertex-buffer)
;; 				      ("n" . ,normal-buffer)
;; 				      ("c" . ,(or vertex-color-buffer '(1.0 1.0 1.0 1.0)))
;; 				      ("tc1" . ,(or texture-coordinate-buffer '(0 0))))
;; 			:uniforms `(("M" . :model)
;; 				    ("P" . :projection)
;; 				    ("N" . :normal)
;; 				    ("t1" . ,(or texture (get-identity-texture)))
;; 				    ("ambientLight" . (.2 .2 .2))
;; 				    ("lightDirection" . (0.5772705 0.5772705 -0.5772705))
;; 				    ("lightIntensity" . (.8 .8 .8))))))

    
;; (setf diamond '(#(0.0  1.0 0.0) #(-0.70710677 0.0 0.70710677) #(0.70710677 0.0 0.70710677)
;; 		#(0.0  1.0 0.0) #(0.9659259 0.0 0.25881892) #(0.25881892 0.0 -0.9659259)
;; 		#(0.0  1.0 0.0) #(-0.25881928 0.0 -0.9659258) #(-0.9659258 0.0 0.25881928)
;; 		#(0.0 -1.0 0.0) #(-0.70710677 0.0 0.70710677) #(0.70710677 0.0 0.70710677)
;; 		#(0.0 -1.0 0.0) #(0.9659259 0.0 0.25881892) #(0.25881892 0.0 -0.9659259)
;; 		#(0.0 -1.0 0.0) #(-0.25881928 0.0 -0.9659258) #(-0.9659258 0.0 0.25881928)))
 
;; (let ((i '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17)))
;;   (make-array (length i) :initial-contents i))

;; (defun subdivide (vectors indexes)
;;   (let ((midpoint (midpoint vectors)))
;;     (values (list (nth 0 vectors)
;; 		  (nth 1 vectors)
;; 		  (nth 2 vectors)
;; 		  midpoint)
;; 	    '((0 1 3) (1 2 3) (2 0 3)))))

;; ;; returns indexes, vertexes, normals, and texcoords in values
;; (defun make-sphere (radius rings sectors)

;;   (let ((vertices  (make-array (* rings sectors 3)))
;; 	(normals   (make-array (* rings sectors 3)))
;; 	(texcoords (make-array (* rings sectors 2)))
;; 	(indices   (make-array (* rings sectors 6)))
;; 	(slice-r (/ (1- rings)))
;; 	(slice-s (/ (1- sectors))))

;;     (loop for r from 0 to (1- rings)
;;        do (loop for s from 0 to (1- sectors)

;; 	     for y = (sin (+ (/ pi -2)
;; 			     (* pi r slice-r)))

;; 	     for x = (* (cos (* pi 2 s slice-s))
;; 			(sin (* pi r slice-r)))

;; 	     for z =  (* (sin (* 2 pi s slice-s))
;; 			 (sin (* pi r slice-r)))

;; 	     do (let* ((triangle (+ (* r sectors) s))
;; 		       (3t (* 3 triangle))
;; 		       (2t (* 2 triangle))
;; 		       (6t (* 6 triangle)))

;; 		  (when (and (< (abs x) .01)
;; 			     (< (abs y) .01)
;; 			     (< (abs z) .01))

;; 		    (format t "~A ~A was all zeros (~A ~A ~A)~%" r s x y z))

;; 		  (setf (aref vertices (+ 3t 0)) (* radius x)
;; 			(aref vertices (+ 3t 1)) (* radius y)
;; 			(aref vertices (+ 3t 2)) (* radius z)

;; 			(aref normals (+ 3t 0)) x
;; 			(aref normals (+ 3t 1)) y
;; 			(aref normals (+ 3t 2)) z

;; 			(aref texcoords (+ 2t 0)) (* s slice-s)
;; 			(aref texcoords (+ 2t 1)) (* r slice-r)

;; 			(aref indices (+ 6t 0)) (+ (* r sectors) s)
;; 			(aref indices (+ 6t 1)) (+ (* r sectors) s 1)
;; 			(aref indices (+ 6t 2)) (+ (* (1+ r) sectors) s 1)

;; 			(aref indices (+ 6t 3)) (+ (* r sectors) s)
;; 			(aref indices (+ 6t 4)) (+ (* (1+ r) sectors) s 1)
;; 			(aref indices (+ 6t 5)) (+ (* (1+ r) sectors) s)))))


;;     (values (coerce indices 'list)
;; 	    (coerce vertices 'list)
;; 	    (coerce normals 'list)
;; 	    (coerce texcoords 'list))))
