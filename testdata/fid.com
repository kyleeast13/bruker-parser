#!/bin/csh

bruk2pipe -in ./ser \
 -bad 0.0 -ext -aswap -AMX -decim 2080 -dspfvs 20 -grpdly 68 \
 -xN 	1024 -yN 	512 \
 -xT 	512 -yT 	256 \
 -xMODE 	DQD -yMODE 	Echo-AntiEcho \
 -xSW 	9615.38461538461 -ySW 	2433.0900243309 \
 -xOBS 	600.132820611 -yOBS 	60.8179420643744 \
 -xCAR 	4.770 -yCAR 	120.090  \
 -xLAB 	1H -yLAB 	15N \
 -ndim 	 2 -aq2D 	 States \
 -out ./test.fid -verb -ov

sleep 5