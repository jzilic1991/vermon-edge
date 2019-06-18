The analyzed formula is:
  P(x) AND 0 = 0
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ((1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND 0 = 1
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@200. (time point 1): ()
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND x = 0
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ()
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND 0 = x
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ()
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND x = x
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ((1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND x = y
The sequence of free variables is: (x,y)
At time point 0:
@100. (time point 0): ((0,0))
At time point 1:
@200. (time point 1): ((1,1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND 0 < 0
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@200. (time point 1): ()
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND 0 < 1
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ((1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND x < 0
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@200. (time point 1): ()
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND x < 1
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ()
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND 0 < x
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@200. (time point 1): ((1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND x < x
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@200. (time point 1): ()
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND x < y
The sequence of free variables is: (x,y)
The analyzed formula is NOT monitorable, because of the subformula:
  P(x) AND x < y
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  P(y) AND x = 0
The sequence of free variables is: (y,x)
At time point 0:
@100. (time point 0): ((0,0))
At time point 1:
@200. (time point 1): ((1,0))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(y) AND 0 = x
The sequence of free variables is: (y,x)
At time point 0:
@100. (time point 0): ((0,0))
At time point 1:
@200. (time point 1): ((1,0))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(y) AND x = x
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND x = x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  P(y) AND x = y
The sequence of free variables is: (y,x)
At time point 0:
@100. (time point 0): ((0,0))
At time point 1:
@200. (time point 1): ((1,1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(y) AND x < 0
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND x < 0
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  P(y) AND x < 1
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND x < 1
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  P(y) AND 0 < x
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND 0 < x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  P(y) AND x < x
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND x < x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  P(y) AND x < y
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND x < y
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  P(x) AND NOT 0 = 0
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@200. (time point 1): ()
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND NOT 0 = 1
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ((1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND NOT x = 0
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@200. (time point 1): ((1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND NOT 0 = x
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@200. (time point 1): ((1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND NOT x = x
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@200. (time point 1): ()
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND NOT x = y
The sequence of free variables is: (x,y)
The analyzed formula is NOT monitorable, because of the subformula:
  P(x) AND NOT x = y
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  P(x) AND NOT 0 < 0
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ((1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND NOT 0 < 1
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@200. (time point 1): ()
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND NOT x < 0
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ((1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND NOT x < 1
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@200. (time point 1): ((1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND NOT 0 < x
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ()
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND NOT x < x
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ((1))
At time point 2:
@300. (time point 2): ()
-----
The analyzed formula is:
  P(x) AND NOT x < y
The sequence of free variables is: (x,y)
The analyzed formula is NOT monitorable, because of the subformula:
  P(x) AND NOT x < y
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  P(y) AND NOT x = 0
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND NOT x = 0
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  P(y) AND NOT 0 = x
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND NOT 0 = x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  P(y) AND NOT x = x
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND NOT x = x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  P(y) AND NOT x = y
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND NOT x = y
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  P(y) AND NOT x < 0
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND NOT x < 0
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  P(y) AND NOT x < 1
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND NOT x < 1
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  P(y) AND NOT 0 < x
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND NOT 0 < x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  P(y) AND NOT x < x
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND NOT x < x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  P(y) AND NOT x < y
The sequence of free variables is: (y,x)
The analyzed formula is NOT monitorable, because of the subformula:
  P(y) AND NOT x < y
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
