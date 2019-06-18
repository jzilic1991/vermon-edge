The analyzed formula is:
  0 = 0
The sequence of free variables is: ()
At time point 0:
@100. (time point 0): true
At time point 1:
@200. (time point 1): true
-----
The analyzed formula is:
  0 = 1
The sequence of free variables is: ()
At time point 0:
@100. (time point 0): false
At time point 1:
@200. (time point 1): false
-----
The analyzed formula is:
  x = 0
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ((0))
-----
The analyzed formula is:
  0 = x
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ((0))
-----
The analyzed formula is:
  x = x
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  x = x
In input formulas psi of the form t1 = t2 the terms t1 and t2 should be variables or constants and at least one should be a constant.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  x = y
The sequence of free variables is: (x,y)
The analyzed formula is NOT monitorable, because of the subformula:
  x = y
In input formulas psi of the form t1 = t2 the terms t1 and t2 should be variables or constants and at least one should be a constant.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  0 < 0
The sequence of free variables is: ()
The analyzed formula is NOT monitorable, because of the subformula:
  0 < 0
Formulas of the form t1 < t2 and t1 <= t2 are currently considered not monitorable.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  0 < 1
The sequence of free variables is: ()
The analyzed formula is NOT monitorable, because of the subformula:
  0 < 1
Formulas of the form t1 < t2 and t1 <= t2 are currently considered not monitorable.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  x < 0
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  x < 0
Formulas of the form t1 < t2 and t1 <= t2 are currently considered not monitorable.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  x < 5
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  x < 5
Formulas of the form t1 < t2 and t1 <= t2 are currently considered not monitorable.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  0 < x
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  0 < x
Formulas of the form t1 < t2 and t1 <= t2 are currently considered not monitorable.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  x < x
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  x < x
Formulas of the form t1 < t2 and t1 <= t2 are currently considered not monitorable.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  x < y
The sequence of free variables is: (x,y)
The analyzed formula is NOT monitorable, because of the subformula:
  x < y
Formulas of the form t1 < t2 and t1 <= t2 are currently considered not monitorable.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  T() AND 0 = 0
The sequence of free variables is: ()
At time point 0:
@100. (time point 0): true
At time point 1:
@200. (time point 1): false
-----
The analyzed formula is:
  T() AND 0 = 1
The sequence of free variables is: ()
At time point 0:
@100. (time point 0): false
At time point 1:
@200. (time point 1): false
-----
The analyzed formula is:
  T() AND x = 0
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ()
-----
The analyzed formula is:
  T() AND 0 = x
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((0))
At time point 1:
@200. (time point 1): ()
-----
The analyzed formula is:
  T() AND x = x
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND x = x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  T() AND x = y
The sequence of free variables is: (x,y)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND x = y
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  T() AND 0 < 0
The sequence of free variables is: ()
At time point 0:
@100. (time point 0): false
At time point 1:
@200. (time point 1): false
-----
The analyzed formula is:
  T() AND 0 < 1
The sequence of free variables is: ()
At time point 0:
@100. (time point 0): true
At time point 1:
@200. (time point 1): false
-----
The analyzed formula is:
  T() AND x < 0
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND x < 0
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  T() AND x < 1
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND x < 1
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  T() AND 0 < x
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND 0 < x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  T() AND x < x
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND x < x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  T() AND x < y
The sequence of free variables is: (x,y)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND x < y
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  T() AND NOT 0 = 0
The sequence of free variables is: ()
At time point 0:
@100. (time point 0): false
At time point 1:
@200. (time point 1): false
-----
The analyzed formula is:
  T() AND NOT 0 = 1
The sequence of free variables is: ()
At time point 0:
@100. (time point 0): true
At time point 1:
@200. (time point 1): false
-----
The analyzed formula is:
  T() AND NOT x = 0
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND NOT x = 0
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  T() AND NOT 0 = x
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND NOT 0 = x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  T() AND NOT x = x
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND NOT x = x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  T() AND NOT x = y
The sequence of free variables is: (x,y)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND NOT x = y
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  T() AND NOT 0 < 0
The sequence of free variables is: ()
At time point 0:
@100. (time point 0): true
At time point 1:
@200. (time point 1): false
-----
The analyzed formula is:
  T() AND NOT 0 < 1
The sequence of free variables is: ()
At time point 0:
@100. (time point 0): false
At time point 1:
@200. (time point 1): false
-----
The analyzed formula is:
  T() AND NOT x < 0
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND NOT x < 0
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  T() AND NOT x < 1
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND NOT x < 1
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  T() AND NOT 5 < x
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND NOT 5 < x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
However, the input (and also the analyzed) formula is safe-range, 
hence one should be able to rewrite it into a monitorable formula.
By the way, the analyzed formula is TSF safe-range.
-----
The analyzed formula is:
  T() AND NOT x < x
The sequence of free variables is: (x)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND NOT x < x
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  T() AND NOT x < y
The sequence of free variables is: (x,y)
The analyzed formula is NOT monitorable, because of the subformula:
  T() AND NOT x < y
In subformulas of the form psi AND t1 op t2 or psi AND NOT t1 op t2, with op among =, <, <=, either the variables of the terms t1 and t2 are among the free variables of psi or the formula is of the form psi AND x = t or psi AND x = t, and the variables of the term t are among the free variables of psi.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
