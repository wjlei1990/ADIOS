
!-----------------------------------------------------------------------
!      inuc: nuclear reaction network switch.
!
!          inuc = 0: nuclear reactions (for nse(j) = 0 zones) bypassed.
!          inuc = 1: nuclear reactions (for nse(j) = 0 zones) included.
!
!      itnuc: maximum number of iterations to attempt in order to obtain a convergent solution of
!       the reaction rate equations for the ion abundances (i.e., the xn(j,i)'s) and the temperature
!       in zones not assumed to be in nse. If itnuc = 1, the variables are assumed to have converged
!       after the first iteration attempt.
!
!      ttolnuc: temperature convergence parameter for nuclear reaction rate equations. The criterion
!       for temperature convergence is that
!
!               abs(dt/t) < ttolnuc .
!
!       ytolnuc: ion abundance convergence parameter for nuclear reaction rate equations. The
!        criteria for ion abundance convergence is that
!
!               abs(dy)/(y(i) + ynmin) < ytolnuc .
!-----------------------------------------------------------------------

inuc               0        10                                          inuc

tolnuc                              1.00000000e-06                      ttolnuc
tolnuc                              1.00000000e-06                      ytolnuc
tolnuc                              1.00000000e-01                      ynmin

!-----------------------------------------------------------------------
!        Time step controls
!
!      t_cntl_burn(1): nuclear burn temperature change time step criterion, i.e., the maximum
!       permitted abs( dT_burn(j)/t(j) ), where dT_burn(j) is the nuclear burn temperature
!       change in radial zone j.
!
!      t_cntl_burn(2): nuclear burn composition change time step criterion, i.e., the maximum
!       permitted abs( dyn(j,i)/yn(j,i) ), where dyn(j,i) is the abundance change of specie i in
!       radial zone j.
!-----------------------------------------------------------------------

tcntrl                       1      1.00000000E-02                      t_cntl_burn
tcntrl                       2      1.00000000E-01                      t_cntl_burn

!-----------------------------------------------------------------------
!      iadjst: composition normalization switch; normalizes sum of
!               composition mass fraction  to unity - necessary for the
!               consistent composition advection.
!-----------------------------------------------------------------------

iadjst             1                                                    iadjst

!-----------------------------------------------------------------------
!        Composition data
!-----------------------------------------------------------------------

a_nuc  12C         1      1.20000000E+01      6.00000000E+00      0.00000000E+00
a_nuc  16C         2      1.60000000E+01      8.00000000E+00     -4.73700141E+00
a_nuc  20Ne        3      2.00000000E+01      1.00000000E+01     -7.04193130E+00
a_nuc  24Mg        4      2.40000000E+01      1.20000000E+01     -1.39335679E+01
a_nuc  28Si        5      2.80000000E+01      1.40000000E+01     -2.14927968E+01
a_nuc  56Ni        6      5.60000000E+01      2.80000000E+01     -5.39041100E+01
a_nuc   4He        7      4.00000000E+00      2.00000000E+00      2.42491565E+00
a_nuc   n          8      1.00000000E+00      0.00000000E+00      8.07131710E+00
a_nuc   p          9      1.00000000E+00      1.00000000E+00      7.28897050E+00

nccomp           103  1  0.00000000E+00  2  3.60082516E-05  3  0.00000000E+00  4  1.29596055E-04  5  3.94339868E-01
nccomp           103  6  0.00000000E+00  7  4.78809444E-03  8  0.00000000E+00  9  4.81553165E-03 10  5.95710518E-01
nccomp           104  1  0.00000000E+00  2  6.50962733E-05  3  0.00000000E+00  4  1.40265079E-04  5  4.67718757E-01
nccomp           104  6  0.00000000E+00  7  3.19908956E-03  8  0.00000000E+00  9  3.57291624E-03 10  5.25317281E-01
nccomp           105  1  0.00000000E+00  2  1.18243339E-04  3  0.00000000E+00  4  1.50417725E-04  5  5.49678686E-01
nccomp           105  6  0.00000000E+00  7  1.98771282E-03  8  0.00000000E+00  9  2.43256735E-03 10  4.45661383E-01
nccomp           106  1  0.00000000E+00  2  2.13889303E-04  3  0.00000000E+00  4  1.55850932E-04  5  6.33612027E-01
nccomp           106  6  0.00000000E+00  7  1.15356452E-03  8  0.00000000E+00  9  1.50091250E-03 10  3.63333462E-01
nccomp           107  1  0.00000000E+00  2  3.81427572E-04  3  0.00000000E+00  4  1.56339121E-04  5  7.10514579E-01
nccomp           107  6  0.00000000E+00  7  6.22832215E-04  8  0.00000000E+00  9  8.26579254E-04 10  2.87499744E-01
nccomp           108  1  0.00000000E+00  2  6.62307124E-04  3  0.00000000E+00  4  1.49547257E-04  5  7.73338240E-01
nccomp           108  6  0.00000000E+00  7  3.12212887E-04  8  0.00000000E+00  9  4.04170168E-04 10  2.25173652E-01
nccomp           109  1  0.00000000E+00  2  1.10490880E-03  3  0.00000000E+00  4  1.37732514E-04  5  8.19938897E-01
nccomp           109  6  0.00000000E+00  7  1.45044645E-04  8  0.00000000E+00  9  1.75589946E-04 10  1.78478156E-01
nccomp           110  1  0.00000000E+00  2  1.74536782E-03  3  0.00000000E+00  4  1.19504365E-04  5  8.54266245E-01
nccomp           110  6  0.00000000E+00  7  6.33112230E-05  8  0.00000000E+00  9  6.56367990E-05 10  1.43829163E-01
nccomp           111  1  0.00000000E+00  2  2.58252802E-03  3  0.00000000E+00  4  9.57341814E-05  5  8.80999629E-01
nccomp           111  6  0.00000000E+00  7  2.64244037E-05  8  0.00000000E+00  9  1.72877538E-05 10  1.16339365E-01
nccomp           112  1  0.00000000E+00  2  3.55246659E-03  3  0.00000000E+00  4  7.15320620E-05  5  9.03206498E-01
nccomp           112  6  0.00000000E+00  7  1.05842947E-05  8  0.00000000E+00  9  3.19841647E-06 10  9.31400619E-02
nccomp           113  1  0.00000000E+00  2  4.56120073E-03  3  0.00000000E+00  4  4.99147697E-05  5  9.21222102E-01
nccomp           113  6  0.00000000E+00  7  4.02552051E-06  8  0.00000000E+00  9  5.55897680E-07 10  7.41651301E-02
nccomp           114  1  0.00000000E+00  2  5.52513390E-03  3  0.00000000E+00  4  3.24200634E-05  5  9.35097464E-01
nccomp           114  6  0.00000000E+00  7  1.41603758E-06  8  0.00000000E+00  9  1.11621969E-07 10  5.93176814E-02
nccomp           115  1  0.00000000E+00  2  6.23807522E-03  3  0.00000000E+00  4  1.99958524E-05  5  9.43966265E-01
nccomp           115  6  0.00000000E+00  7  4.90997918E-07  8  0.00000000E+00  9  2.72060356E-08 10  4.97227594E-02
nccomp           116  1  1.43998402E-05  2  4.23971888E-02  3  1.31800337E-05  4  5.53612250E-05  5  9.41313533E-01
nccomp           116  6  0.00000000E+00  7  1.04633209E-05  8  0.00000000E+00  9  4.69497878E-06 10  1.62257364E-02
nccomp           117  1  6.22765685E-05  2  1.01588949E-02  3  6.72123465E-06  4  5.37375093E-05  5  9.87034684E-01
nccomp           117  6  0.00000000E+00  7  5.48772170E-05  8  0.00000000E+00  9  2.02958449E-05 10  2.62760110E-03
nccomp           118  1  6.32553780E-05  2  2.65077531E-02  3  1.33460086E-05  4  5.12037652E-05  5  9.71410517E-01
nccomp           118  6  0.00000000E+00  7  2.16838623E-05  8  0.00000000E+00  9  6.04112015E-06 10  1.94964817E-03
nccomp           119  1  5.04375045E-05  2  4.95190195E-02  3  1.90412382E-05  4  5.87474870E-05  5  9.48722575E-01
nccomp           119  6  0.00000000E+00  7  9.33810739E-06  8  0.00000000E+00  9  2.37424806E-06 10  1.68301030E-03
nccomp           120  1  3.60801132E-05  2  7.14571132E-02  3  2.04622000E-05  4  6.59842337E-05  5  9.26904535E-01
nccomp           120  6  0.00000000E+00  7  3.81120420E-06  8  0.00000000E+00  9  8.61368880E-07 10  1.53816539E-03
nccomp           121  1  2.45519082E-05  2  9.01856329E-02  3  1.95856960E-05  4  7.02126991E-05  5  9.08256177E-01
nccomp           121  6  0.00000000E+00  7  1.55445838E-06  8  0.00000000E+00  9  3.13647804E-07 10  1.45965672E-03
nccomp           122  1  1.62734599E-05  2  1.05529752E-01  3  1.71550251E-05  4  7.22188394E-05  5  8.92985440E-01
nccomp           122  6  0.00000000E+00  7  6.32112925E-07  8  0.00000000E+00  9  1.14229113E-07 10  1.41256598E-03
nccomp           123  1  1.06718154E-05  2  1.18160574E-01  3  1.43976900E-05  4  7.43144933E-05  5  8.80436400E-01
nccomp           123  6  0.00000000E+00  7  2.56907572E-07  8  0.00000000E+00  9  4.18332409E-08 10  1.38339436E-03
nccomp           124  1  7.09387440E-06  2  1.28465490E-01  3  1.17577477E-05  4  7.73893864E-05  5  8.70034208E-01
nccomp           124  6  0.00000000E+00  7  1.04454348E-07  8  0.00000000E+00  9  1.55634455E-08 10  1.36481444E-03
nccomp           125  1  4.96565208E-06  2  1.37252370E-01  3  9.42669360E-06  4  8.06097031E-05  5  8.61351385E-01
nccomp           125  6  0.00000000E+00  7  4.24509680E-08  8  0.00000000E+00  9  5.91844782E-09 10  1.35347624E-03
nccomp           126  1  3.80073758E-06  2  1.44747129E-01  3  7.46543235E-06  4  8.33263985E-05  5  8.53852535E-01
nccomp           126  6  0.00000000E+00  7  1.72432690E-08  8  0.00000000E+00  9  2.30849192E-09 10  1.34579859E-03
nccomp           127  1  3.20661279E-06  2  1.51220727E-01  3  5.86326805E-06  4  8.54165547E-05  5  8.47379273E-01
nccomp           127  6  0.00000000E+00  7  6.99647159E-09  8  0.00000000E+00  9  9.24424256E-10 10  1.34192801E-03
nccomp           128  1  2.91492955E-06  2  1.56958337E-01  3  4.59226778E-06  4  8.70048361E-05  5  8.41641663E-01
nccomp           128  6  0.00000000E+00  7  2.83771335E-09  8  0.00000000E+00  9  3.80140471E-10 10  1.33796760E-03
nccomp           129  1  2.76900000E-06  2  1.62000000E-01  3  3.65900000E-06  4  8.82200000E-05  5  8.36600000E-01
nccomp           129  6  0.00000000E+00  7  1.16600000E-09  8  0.00000000E+00  9  1.61500000E-10 10  1.33600000E-03
a_nucr           103      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           104      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           105      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           106      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           107      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           108      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           109      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           110      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           111      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           112      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           113      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           114      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           115      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           116      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           117      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           118      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           119      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           120      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           121      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           122      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           123      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           124      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           125      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           126      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           127      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           128      5.60000000E+01      2.60000000E+01      4.92300000E+02
a_nucr           129      5.60000000E+01      2.60000000E+01      4.92300000E+02
