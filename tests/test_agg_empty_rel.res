v <- CNT x p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (3)
@30. (time point 2): (0)
-----
v <- CNT y p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (3)
@30. (time point 2): (0)
-----
v <- SUM y p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (6)
@30. (time point 2): (0)
-----
v <- AVG y p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (2)
@30. (time point 2): (0)
WARNING: AVG applied on empty relation at time point 0, timestamp 10.! Resulting value is 0, by (our) convention.
WARNING: AVG applied on empty relation at time point 2, timestamp 30.! Resulting value is 0, by (our) convention.
-----
v <- MED y p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (2)
@30. (time point 2): (0)
WARNING: MED applied on empty relation at time point 0, timestamp 10.! Resulting value is 0, by (our) convention.
WARNING: MED applied on empty relation at time point 2, timestamp 30.! Resulting value is 0, by (our) convention.
-----
v <- MIN y p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (1)
@30. (time point 2): (0)
WARNING: MIN applied on empty relation at time point 0, timestamp 10.! Resulting value is 0, by (our) convention.
WARNING: MIN applied on empty relation at time point 2, timestamp 30.! Resulting value is 0, by (our) convention.
-----
v <- MAX y p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (3)
@30. (time point 2): (0)
WARNING: MAX applied on empty relation at time point 0, timestamp 10.! Resulting value is 0, by (our) convention.
WARNING: MAX applied on empty relation at time point 2, timestamp 30.! Resulting value is 0, by (our) convention.
-----
v <- CNT y; x p(x,y)
@20. (time point 1): (1,b) (2,a)
-----
v <- SUM y; x p(x,y)
@20. (time point 1): (3,a) (3,b)
-----
v <- AVG y; x p(x,y)
@20. (time point 1): (1.5,a) (3,b)
-----
v <- MED y; x p(x,y)
@20. (time point 1): (1.5,a) (3,b)
-----
v <- MIN y; x p(x,y)
@20. (time point 1): (1,a) (3,b)
-----
v <- MAX y; x p(x,y)
@20. (time point 1): (2,a) (3,b)
-----
v <- CNT y ONCE p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (3)
@30. (time point 2): (3)
-----
v <- SUM y ONCE p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (6)
@30. (time point 2): (6)
-----
v <- AVG y ONCE p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (2)
@30. (time point 2): (2)
WARNING: AVG applied on empty relation at time point 0, timestamp 10.! Resulting value is 0, by (our) convention.
-----
v <- MED y ONCE p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (2)
@30. (time point 2): (2)
WARNING: MED applied on empty relation at time point 0, timestamp 10.! Resulting value is 0, by (our) convention.
-----
v <- MIN y ONCE p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (1)
@30. (time point 2): (1)
WARNING: MIN applied on empty relation at time point 0, timestamp 10.! Resulting value is 0, by (our) convention.
-----
v <- MAX y ONCE p(x,y)
@10. (time point 0): (0)
@20. (time point 1): (3)
@30. (time point 2): (3)
WARNING: MAX applied on empty relation at time point 0, timestamp 10.! Resulting value is 0, by (our) convention.
-----
v <- CNT y; x ONCE p(x,y)
@20. (time point 1): (1,b) (2,a)
@30. (time point 2): (1,b) (2,a)
-----
v <- SUM y; x ONCE p(x,y)
@20. (time point 1): (3,a) (3,b)
@30. (time point 2): (3,a) (3,b)
-----
v <- AVG y; x ONCE p(x,y)
@20. (time point 1): (1.5,a) (3,b)
@30. (time point 2): (1.5,a) (3,b)
-----
v <- MED y; x ONCE p(x,y)
@20. (time point 1): (1.5,a) (3,b)
@30. (time point 2): (1.5,a) (3,b)
-----
v <- MIN y; x ONCE p(x,y)
@20. (time point 1): (1,a) (3,b)
@30. (time point 2): (1,a) (3,b)
-----
v <- MAX y; x ONCE p(x,y)
@20. (time point 1): (2,a) (3,b)
@30. (time point 2): (2,a) (3,b)
-----
