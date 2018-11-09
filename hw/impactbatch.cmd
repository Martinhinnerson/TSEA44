setmode -bs
setcable -port auto
loadcdf -file avnetchain.cdf
setAttribute -position 3 -attr configFileName -value lab0.bit
program -p 3
quit
