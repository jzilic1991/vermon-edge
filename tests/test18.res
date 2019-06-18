The analyzed formula is:
  S(a,b,c) AND a = b + 2
The sequence of free variables is: (a,b,c)
At time point 0:
@100. (time point 0): ((10,8,0))
At time point 1:
@200. (time point 1): ()
-----
The analyzed formula is:
  S(a,b,c) AND a = (1 + b) + 2
The sequence of free variables is: (a,b,c)
At time point 0:
@100. (time point 0): ((10,7,0))
At time point 1:
@200. (time point 1): ()
-----
The analyzed formula is:
  S(a,b,c) AND a + 1 = 1 + b
The sequence of free variables is: (a,b,c)
At time point 0:
@100. (time point 0): ((10,10,1))
At time point 1:
@200. (time point 1): ()
-----
The analyzed formula is:
  S(a,b,c) AND a = b + c
The sequence of free variables is: (a,b,c)
At time point 0:
@100. (time point 0): ((10,4,6))
At time point 1:
@200. (time point 1): ()
-----
The analyzed formula is:
  S(a,b,c) AND a + c = b + a
The sequence of free variables is: (a,b,c)
At time point 0:
@100. (time point 0): ((10,3,3))
At time point 1:
@200. (time point 1): ()
-----
The analyzed formula is:
  S(a,b,c) AND x = (1 + b) + c
The sequence of free variables is: (a,b,c,x)
At time point 0:
@100. (time point 0): ((10,1,2,4),(10,3,3,7),(10,4,6,11),(10,7,0,8),(10,8,0,9),(10,10,1,12))
At time point 1:
@200. (time point 1): ((10,0,1,2))
-----
The analyzed formula is:
  S(a,b,c) AND x = (a + b) + c
The sequence of free variables is: (a,b,c,x)
At time point 0:
@100. (time point 0): ((10,1,2,13),(10,3,3,16),(10,4,6,20),(10,7,0,17),(10,8,0,18),(10,10,1,21))
At time point 1:
@200. (time point 1): ((10,0,1,11))
-----
The analyzed formula is:
  S(a,b,c) AND x + 1 = b + c
The sequence of free variables is: (a,b,c,x)
The analyzed formula is NOT monitorable, because of the subformula:
  S(a,b,c) AND x + 1 = b + c
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  S(a,b,c) AND x = ((a * a) - (2 * b)) + c
The sequence of free variables is: (a,b,c,x)
At time point 0:
@100. (time point 0): ((10,1,2,100),(10,3,3,97),(10,4,6,98),(10,7,0,86),(10,8,0,84),(10,10,1,81))
At time point 1:
@200. (time point 1): ((10,0,1,101))
-----
The analyzed formula is:
  S(a,b,c) AND x = a / b
The sequence of free variables is: (a,b,c,x)
At time point 0:
@100. (time point 0): ((10,1,2,10),(10,3,3,3),(10,4,6,2),(10,7,0,1),(10,8,0,1),(10,10,1,1))
At time point 1:
-----
The analyzed formula is:
  S(a,b,c) AND NOT a = b + 2
The sequence of free variables is: (a,b,c)
At time point 0:
@100. (time point 0): ((10,1,2),(10,3,3),(10,4,6),(10,7,0),(10,10,1))
At time point 1:
@200. (time point 1): ((10,0,1))
-----
