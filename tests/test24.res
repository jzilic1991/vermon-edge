The analyzed formula is:
  0 = 0 UNTIL[0,0] r()
The sequence of free variables is: ()
At time point 0:
At time point 1:
@0. (time point 0): true
At time point 2:
At time point 3:
@2. (time point 1): false
@2. (time point 2): false
-----
The analyzed formula is:
  (NOT 0 = 0) UNTIL[0,0] r()
The sequence of free variables is: ()
At time point 0:
At time point 1:
@0. (time point 0): true
At time point 2:
At time point 3:
@2. (time point 1): false
@2. (time point 2): false
-----
The analyzed formula is:
  (NOT NEXT[0,0] NEXT[0,0] s()) UNTIL[0,0] r()
The sequence of free variables is: ()
At time point 0:
At time point 1:
At time point 2:
@0. (time point 0): true
At time point 3:
@2. (time point 1): false
@2. (time point 2): false
-----
The analyzed formula is:
  (NOT NEXT[0,0] (s() OR NEXT[0,0] r())) UNTIL[0,0] r()
The sequence of free variables is: ()
At time point 0:
At time point 1:
At time point 2:
@0. (time point 0): true
At time point 3:
@2. (time point 1): false
@2. (time point 2): false
-----
The input formula is:
  (NOT ((NEXT[0,0] r()) OR NEXT[0,0] s())) UNTIL[0,0] r()
The analyzed formula is:
  ((NOT NEXT[0,0] r()) AND NOT NEXT[0,0] s()) UNTIL[0,0] r()
The sequence of free variables is: ()
At time point 0:
At time point 1:
@0. (time point 0): true
At time point 2:
At time point 3:
@2. (time point 1): false
@2. (time point 2): false
-----
