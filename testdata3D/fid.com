#!/bin/csh

bruk2pipe -in ./ser \
 -bad 0.0 -ext -aswap -AMX -decim 2080 -dspfvs 20 -grpdly 68 \
 -xN 	2048 -yN 	40 -zN 	128 \
 -xT 	1024 -yT 	20 -zT 	64 \
 -xMODE 	DQD -yMODE 	Echo-AntiEcho -zMODE 	States-TPPI \
 -xSW 	9615.38461538461 -ySW 	2128.56534695615 -zSW 	8403.36134453781 \
 -xOBS 	600.132820611 -yOBS 	60.817759631 -zOBS 	600.132820611 \
 -xCAR 	4.768 -yCAR 	117.088 -zCAR 	8868878.639 \
 -xLAB 	1Hx -yLAB 	15Ny -zLAB 	1Hz \
 -ndim 	 3 -aq2D 	 States \
 -out ./fid/test%03d.fid -verb -ov

sleep 5