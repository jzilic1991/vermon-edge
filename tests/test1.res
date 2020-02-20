The analyzed formula is:
  P(x) AND Q(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((3),(4))
At time point 1:
@110. (time point 1): ((4))
At time point 2:
@120. (time point 2): ((5))
At time point 3:
@130. (time point 3): ()
-----
The analyzed formula is:
  P(x) OR Q(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((2),(3),(4),(6))
At time point 1:
@110. (time point 1): ((2),(3),(4),(6),(7))
At time point 2:
@120. (time point 2): ((2),(3),(5),(6),(8))
At time point 3:
@130. (time point 3): ((3),(5),(6),(9),(12),(14),(16))
-----
The analyzed formula is:
  P(x) OR Q(y)
The sequence of free variables is: (x,y)
The analyzed formula is NOT monitorable, because of the subformula:
  P(x) OR Q(y)
In subformulas of the form phi OR psi, phi and psi should have the same set of free variables.
The analyzed formula is neither safe-range.
By the way, the analyzed formula is not TSF safe-range.
-----
The analyzed formula is:
  (EXISTS b. R(a,b)) AND P(a)
The sequence of free variables is: (a)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ((3))
At time point 2:
@120. (time point 2): ((3),(5))
At time point 3:
@130. (time point 3): ((3),(5))
-----
The analyzed formula is:
  (EXISTS x. (x = 0 AND (EXISTS x. P(x)))) AND P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((2),(3),(4))
At time point 1:
@110. (time point 1): ((3),(4),(7))
At time point 2:
@120. (time point 2): ((3),(5),(8))
At time point 3:
@130. (time point 3): ((3),(5),(6),(9))
-----
The analyzed formula is:
  T()
The sequence of free variables is: ()
At time point 0:
@100. (time point 0): true
At time point 1:
@110. (time point 1): false
At time point 2:
@120. (time point 2): false
At time point 3:
@130. (time point 3): false
-----
The analyzed formula is:
  R(y,x)
The sequence of free variables is: (y,x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ((3,5),(5,0))
At time point 2:
@120. (time point 2): ((3,5),(5,0))
At time point 3:
@130. (time point 3): ((3,5),(5,0))
-----
The analyzed formula is:
  P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((2),(3),(4))
At time point 1:
@110. (time point 1): ((3),(4),(7))
At time point 2:
@120. (time point 2): ((3),(5),(8))
At time point 3:
@130. (time point 3): ((3),(5),(6),(9))
-----
The analyzed formula is:
  NEXT[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
@100. (time point 0): ((3),(4),(7))
At time point 2:
@110. (time point 1): ((3),(5),(8))
At time point 3:
@120. (time point 2): ((3),(5),(6),(9))
-----
The analyzed formula is:
  PREVIOUS[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ((2),(3),(4))
At time point 2:
@120. (time point 2): ((3),(4),(7))
At time point 3:
@130. (time point 3): ((3),(5),(8))
-----
The analyzed formula is:
  NEXT[0,30] NEXT[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
At time point 2:
@100. (time point 0): ((3),(5),(8))
At time point 3:
@110. (time point 1): ((3),(5),(6),(9))
-----
The analyzed formula is:
  NEXT[0,30] PREVIOUS[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
@100. (time point 0): ((2),(3),(4))
At time point 2:
@110. (time point 1): ((3),(4),(7))
At time point 3:
@120. (time point 2): ((3),(5),(8))
-----
The analyzed formula is:
  PREVIOUS[0,30] PREVIOUS[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ()
At time point 2:
@120. (time point 2): ((2),(3),(4))
At time point 3:
@130. (time point 3): ((3),(4),(7))
-----
The analyzed formula is:
  PREVIOUS[0,30] NEXT[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ((3),(4),(7))
At time point 2:
@120. (time point 2): ((3),(5),(8))
At time point 3:
@130. (time point 3): ((3),(5),(6),(9))
-----
The analyzed formula is:
  NEXT[0,30] NEXT[0,30] NEXT[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
At time point 2:
At time point 3:
@100. (time point 0): ((3),(5),(6),(9))
-----
The analyzed formula is:
  NEXT[0,30] NEXT[0,30] PREVIOUS[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
At time point 2:
@100. (time point 0): ((3),(4),(7))
At time point 3:
@110. (time point 1): ((3),(5),(8))
-----
The analyzed formula is:
  NEXT[0,30] PREVIOUS[0,30] NEXT[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
@100. (time point 0): ((3),(4),(7))
At time point 2:
@110. (time point 1): ((3),(5),(8))
At time point 3:
@120. (time point 2): ((3),(5),(6),(9))
-----
The analyzed formula is:
  NEXT[0,30] PREVIOUS[0,30] PREVIOUS[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
@100. (time point 0): ()
At time point 2:
@110. (time point 1): ((2),(3),(4))
At time point 3:
@120. (time point 2): ((3),(4),(7))
-----
The analyzed formula is:
  PREVIOUS[0,30] NEXT[0,30] NEXT[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
At time point 2:
@110. (time point 1): ((3),(5),(8))
At time point 3:
@120. (time point 2): ((3),(5),(6),(9))
-----
The analyzed formula is:
  PREVIOUS[0,30] NEXT[0,30] PREVIOUS[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ((2),(3),(4))
At time point 2:
@120. (time point 2): ((3),(4),(7))
At time point 3:
@130. (time point 3): ((3),(5),(8))
-----
The analyzed formula is:
  PREVIOUS[0,30] PREVIOUS[0,30] NEXT[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ()
At time point 2:
@120. (time point 2): ((3),(4),(7))
At time point 3:
@130. (time point 3): ((3),(5),(8))
-----
The analyzed formula is:
  PREVIOUS[0,30] PREVIOUS[0,30] PREVIOUS[0,30] P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ()
At time point 2:
@120. (time point 2): ()
At time point 3:
@130. (time point 3): ((2),(3),(4))
-----
The analyzed formula is:
  P(x) SINCE[0,30] Q(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((3),(4),(6))
At time point 1:
@110. (time point 1): ((2),(3),(4),(6))
At time point 2:
@120. (time point 2): ((2),(3),(5),(6))
At time point 3:
@130. (time point 3): ((3),(5),(6),(12),(14),(16))
-----
The analyzed formula is:
  P(x) SINCE[1,10] R(y,x)
The sequence of free variables is: (y,x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ()
At time point 2:
@120. (time point 2): ((3,5))
At time point 3:
@130. (time point 3): ((3,5))
-----
The analyzed formula is:
  0 = 0 SINCE[0,*) P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((2),(3),(4))
At time point 1:
@110. (time point 1): ((2),(3),(4),(7))
At time point 2:
@120. (time point 2): ((2),(3),(4),(5),(7),(8))
At time point 3:
@130. (time point 3): ((2),(3),(4),(5),(6),(7),(8),(9))
-----
The analyzed formula is:
  ONCE[0,0] P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((2),(3),(4))
At time point 1:
@110. (time point 1): ((3),(4),(7))
At time point 2:
@120. (time point 2): ((3),(5),(8))
At time point 3:
@130. (time point 3): ((3),(5),(6),(9))
-----
The analyzed formula is:
  ONCE[0,10] P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((2),(3),(4))
At time point 1:
@110. (time point 1): ((2),(3),(4),(7))
At time point 2:
@120. (time point 2): ((3),(4),(5),(7),(8))
At time point 3:
@130. (time point 3): ((3),(5),(6),(8),(9))
-----
The analyzed formula is:
  ONCE[0,*) P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ((2),(3),(4))
At time point 1:
@110. (time point 1): ((2),(3),(4),(7))
At time point 2:
@120. (time point 2): ((2),(3),(4),(5),(7),(8))
At time point 3:
@130. (time point 3): ((2),(3),(4),(5),(6),(7),(8),(9))
-----
The analyzed formula is:
  ONCE[1,10] P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ((2),(3),(4))
At time point 2:
@120. (time point 2): ((3),(4),(7))
At time point 3:
@130. (time point 3): ((3),(5),(8))
-----
The analyzed formula is:
  ONCE[1,9] P(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ()
At time point 2:
@120. (time point 2): ()
At time point 3:
@130. (time point 3): ()
-----
The analyzed formula is:
  NEXT[0,30] (P(x) SINCE[0,30] Q(x))
The sequence of free variables is: (x)
At time point 0:
At time point 1:
@100. (time point 0): ((2),(3),(4),(6))
At time point 2:
@110. (time point 1): ((2),(3),(5),(6))
At time point 3:
@120. (time point 2): ((3),(5),(6),(12),(14),(16))
-----
The analyzed formula is:
  PREVIOUS[0,30] (P(x) SINCE[0,30] Q(x))
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ((3),(4),(6))
At time point 2:
@120. (time point 2): ((2),(3),(4),(6))
At time point 3:
@130. (time point 3): ((2),(3),(5),(6))
-----
The analyzed formula is:
  P(x) SINCE[0,30] NEXT[0,30] Q(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
@100. (time point 0): ((2),(4),(6))
At time point 2:
@110. (time point 1): ((2),(4),(5),(6))
At time point 3:
@120. (time point 2): ((5),(12),(14),(16))
-----
The analyzed formula is:
  P(x) SINCE[0,30] PREVIOUS[0,30] Q(x)
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ((3),(4),(6))
At time point 2:
@120. (time point 2): ((2),(3),(4),(6))
At time point 3:
@130. (time point 3): ((2),(3),(5),(6))
-----
The analyzed formula is:
  PREVIOUS[0,30] PREVIOUS[0,30] (P(x) SINCE[0,30] Q(x))
The sequence of free variables is: (x)
At time point 0:
@100. (time point 0): ()
At time point 1:
@110. (time point 1): ()
At time point 2:
@120. (time point 2): ((3),(4),(6))
At time point 3:
@130. (time point 3): ((2),(3),(4),(6))
-----
The analyzed formula is:
  P(x) UNTIL[0,10] Q(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
At time point 2:
@100. (time point 0): ((2),(3),(4),(6))
At time point 3:
@110. (time point 1): ((2),(4),(6))
-----
The analyzed formula is:
  P(x) UNTIL[1,10] R(x,y)
The sequence of free variables is: (x,y)
At time point 0:
At time point 1:
At time point 2:
@100. (time point 0): ((3,5))
At time point 3:
@110. (time point 1): ((3,5))
-----
The analyzed formula is:
  NEXT[0,30] (P(x) UNTIL[0,10] Q(x))
The sequence of free variables is: (x)
At time point 0:
At time point 1:
At time point 2:
At time point 3:
@100. (time point 0): ((2),(4),(6))
-----
The analyzed formula is:
  NEXT[0,30] NEXT[0,30] (P(x) UNTIL[0,10] Q(x))
The sequence of free variables is: (x)
At time point 0:
At time point 1:
At time point 2:
At time point 3:
-----
The analyzed formula is:
  P(x) UNTIL[1,9] Q(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
@100. (time point 0): ()
At time point 2:
@110. (time point 1): ()
At time point 3:
@120. (time point 2): ()
-----
The analyzed formula is:
  (NOT P(x)) UNTIL[0,10] R(x,y)
The sequence of free variables is: (x,y)
At time point 0:
At time point 1:
At time point 2:
@100. (time point 0): ((5,0))
At time point 3:
@110. (time point 1): ((3,5),(5,0))
-----
The analyzed formula is:
  (NOT P(x)) UNTIL[1,10] R(x,y)
The sequence of free variables is: (x,y)
At time point 0:
At time point 1:
At time point 2:
@100. (time point 0): ((5,0))
At time point 3:
@110. (time point 1): ((5,0))
-----
The analyzed formula is:
  (NOT P(x)) UNTIL[0,9] R(x,y)
The sequence of free variables is: (x,y)
At time point 0:
At time point 1:
@100. (time point 0): ()
At time point 2:
@110. (time point 1): ((3,5),(5,0))
At time point 3:
@120. (time point 2): ((3,5),(5,0))
-----
The analyzed formula is:
  (NOT P(x)) UNTIL[1,9] R(x,y)
The sequence of free variables is: (x,y)
At time point 0:
At time point 1:
@100. (time point 0): ()
At time point 2:
@110. (time point 1): ()
At time point 3:
@120. (time point 2): ()
-----
The analyzed formula is:
  0 = 0 UNTIL[0,0] P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
@100. (time point 0): ((2),(3),(4))
At time point 2:
@110. (time point 1): ((3),(4),(7))
At time point 3:
@120. (time point 2): ((3),(5),(8))
-----
The analyzed formula is:
  EVENTUALLY[0,0] P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
@100. (time point 0): ((2),(3),(4))
At time point 2:
@110. (time point 1): ((3),(4),(7))
At time point 3:
@120. (time point 2): ((3),(5),(8))
-----
The analyzed formula is:
  EVENTUALLY[0,10] P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
At time point 2:
@100. (time point 0): ((2),(3),(4),(7))
At time point 3:
@110. (time point 1): ((3),(4),(5),(7),(8))
-----
The analyzed formula is:
  EVENTUALLY[1,10] P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
At time point 2:
@100. (time point 0): ((3),(4),(7))
At time point 3:
@110. (time point 1): ((3),(5),(8))
-----
The analyzed formula is:
  EVENTUALLY[1,9] P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
@100. (time point 0): ()
At time point 2:
@110. (time point 1): ()
At time point 3:
@120. (time point 2): ()
-----
The analyzed formula is:
  EVENTUALLY[1,10] NEXT[0,*) P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
At time point 2:
@100. (time point 0): ((3),(5),(8))
At time point 3:
@110. (time point 1): ((3),(5),(6),(9))
-----
The analyzed formula is:
  EVENTUALLY[1,10] PREVIOUS[0,*) P(x)
The sequence of free variables is: (x)
At time point 0:
At time point 1:
At time point 2:
@100. (time point 0): ((2),(3),(4))
At time point 3:
@110. (time point 1): ((3),(4),(7))
-----
