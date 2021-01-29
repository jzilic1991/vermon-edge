Propagation of guarding conjunctions below quantifiers must not capture bound variables.

  $ echo 'P(x, y) AND EXISTS x. NOT Q(x, y)' > test33_1.mfotl
  $ monpoly -sig test33.sig -formula test33_1.mfotl -log test33.log -verbose -nonewlastts
  The input formula is:
    P(x,y) AND (EXISTS x. NOT Q(x,y))
  The analyzed formula is:
    P(x,y) AND (EXISTS _x1. (P(x,y) AND (NOT Q(_x1,y))))
  The sequence of free variables is: (x,y)
  The analyzed formula is NOT monitorable, because of the subformula:
    P(x,y) AND (NOT Q(_x1,y))
  In subformulas of the form phi AND NOT psi, psi SINCE_I phi, and psi UNTIL_I phi, the free variables of psi should be among the free variables of phi.
  The analyzed formula is neither safe-range.
  By the way, the analyzed formula is not TSF safe-range.
