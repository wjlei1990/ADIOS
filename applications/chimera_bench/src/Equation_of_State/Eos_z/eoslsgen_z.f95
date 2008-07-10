SUBROUTINE eosdtgen_z( k, ki_ray, kj_ray, idd, itt, iyy, ida, ita, iya, sf )
!-----------------------------------------------------------------------
!
!    File:         eoslsgen_y
!    Module:       eosdtgen_z
!    Type:         Subprogram
!    Author:       S. W. Bruenn, Dept of Physics, FAU,
!                  Boca Raton, FL 33431-0991
!
!    Date:         1/04/07
!
!    Purpose:
!      To call subroutine inveos, the Lattimer-Swesty equation
!       of state (or subroutine eos_z, the Cooperstein-BCK equation
!       of state if the independent variables are out of range
!       of the L-S equation of state) and stores the thermodynamic
!       quantities in arrays for interpolation.
!
!    Input arguments:
!
!  k                    : z (azimuthal) zone index.
!  ki_ray               : x (radial) index of a specific z (azimuthaal) ray
!  kj_ray               : y (angular) index of a specific z (azimuthaal) ray
!  idd                  : density grid index
!  itt                  : temperature grid index
!  iyy                  : electron fraction grid index
!  ida                  : equation of state table density index
!  ita                  : equation of state table temperature index
!  iya                  : equation of state table electron fraction index
!
!    Output arguments:
!  sf                   : eos flag
!
!    Variables that must be passed through common:
!
!  nse(k,kj_ray,ki_ray) : nuclear statistical equilibrium flag for radial zone k.
!  dgrid(idty(k,kj_ray,ki_ray)) : number of table entries per decade in rho for zone k.
!  tgrid(idty(k,kj_ray,ki_ray)) : number of table entries per decade in t for zone k.
!  ygrid(idty(k,kj_ray,ki_ray)) : number of table entries in ye between ye = 0.5 and ye = 0 for zone k.
!  idty(k,kj_ray,ki_ray)        : index for dgrid, tgrid, and ygrid for zone k.
!  rhoes(i)             : density boundary between idty=i and idty=i+1
!  estble(i,k,ida,ita,iya,kj_ray,ki_ray)
!                       : equation of state table array.
!  gamhv                : BCK gamma.
!  wnm                  : BCK nucl matter energy; - 16.0 MeV.
!  ws                   : BCK bulk surface coefficient.
!  xk0                  : BCK K_0(x=.5) symmettric matter.
!  xkzafac              : BCK drop in K_0 with x :
!                 k(x) = k(1/2)(1-xkzafac*(1-2x)**2).
!
!    Subprograms called:
!  loadmx               : loads eos data into the LS eos
!  inveos               : invokes the LS eos
!  e_p_eos              : calculates the EOS of electrons and positrons
!  eos_z                : invokes the BCK eos
!
!    Include files:
!  kind_module, numerical_module, physcnst_module
!  edit_module, el_eos_module, eos_bck_module, eos_bck_module,
!  eos_ls_module, eos_m4c_module, eos_snc_z_module
!
!-----------------------------------------------------------------------

USE kind_module, ONLY : single, double
USE numerical_module, ONLY: zero, half, one
USE physcnst_module, ONLY: dmnp, kmev, rmu, cm3fm3, ergmev

USE edit_module, ONLY: nprint, nlog
USE el_eos_module, ONLY: EPRESS, EU, ES, MUSUBE
USE eos_m4c_module, ONLY: inpvar, iflag, forflg, brydns, eosflg, xprev, &
& PTOT, UTOT, STOT, XNUT, XPROT, XH, MUN, MUPROT, A, X, GAM_S
USE eos_bck_module, ONLY: jshel, dbck, tbck, yebck, dtran, ue, xnbck, xpbck, &
& xhbck, ptotbck, uhat, etot, stotbck, un, zabck, ahbck, uea, una, uhata, &
& thetaa, zaa, xaa, dtrana, theta, xabck
USE eos_ls_module, ONLY: inpvars
USE eos_snc_z_module, ONLY: eos_i, idty, dgrid, tgrid, ygrid, eosrho, nse, &
& estble

IMPLICIT none
SAVE

!-----------------------------------------------------------------------
!        Input variables.
!-----------------------------------------------------------------------

INTEGER, INTENT(in)              :: k             ! z (azimuthal) zone index.
INTEGER, INTENT(in)              :: ki_ray        ! x (radial) index of a specific z (azimuthaal) ray
INTEGER, INTENT(in)              :: kj_ray        ! y (angular) index of a specific z (azimuthaal) ray
INTEGER, INTENT(in)              :: idd           ! density index
INTEGER, INTENT(in)              :: itt           ! temperature index
INTEGER, INTENT(in)              :: iyy           ! lepton fraction index
INTEGER, INTENT(in)              :: ida           ! density index in EOS cube array
INTEGER, INTENT(in)              :: ita           ! temperature index in EOS cube array
INTEGER, INTENT(in)              :: iya           ! lepton fraction index in EOS cube array

!-----------------------------------------------------------------------
!        Output variables.
!-----------------------------------------------------------------------

INTEGER, INTENT(out)             :: sf            ! eos_z flag

!-----------------------------------------------------------------------
!        Local variables
!-----------------------------------------------------------------------

LOGICAL                          :: first = .true.

CHARACTER (LEN=1)                :: eos_ii

INTEGER                          :: id            ! density do index
INTEGER                          :: it            ! temperature do index
INTEGER                          :: iy            ! electron fraction do index
INTEGER                          :: ii            ! eos_z dependent variable index

REAL(KIND=single)                :: test_number

REAL(KIND=double)                :: tiny          ! minimum double precision value to be singled

REAL(KIND=double), PARAMETER     :: eost = 0.05d0 ! lower boundary of LS EOS table
REAL(KIND=double), PARAMETER     :: UTOT0 = 8.9d0 ! change in the zero of energy (MeV)
REAL(KIND=double), PARAMETER     :: dt0 = 0.03d+00 ! fraction of t added and subtracted
REAL(KIND=double), PARAMETER     :: dye0 = 0.02d+00 ! electron fraction added and subtracted
REAL(KIND=double)                :: dt            ! fraction of t added and subtracted
REAL(KIND=double)                :: dye           ! electron fraction added and subtracted
REAL(KIND=double), PARAMETER     :: dlrho = 0.05d+00 ! d(ln(rho)) - for computing derivatives wrt density by finite differences 
REAL(KIND=double), PARAMETER     :: dlt = 0.05d+00 ! d(ln(t)) - for computing derivatives wrt temperature by finite differences 

REAL(KIND=double)                :: kfm           ! ( # nucleons/gram )( cm3/fm3 )
REAL(KIND=double)                :: kp            ! ( erg/cm3 ) / ( mev/fm3 )
REAL(KIND=double)                :: ku            ! ( # nucleons/gram )( erg/mev )
REAL(KIND=double)                :: rhod          ! density at the cube corners
REAL(KIND=double)                :: td            ! temperature at the cube corners
REAL(KIND=double)                :: yed           ! electron fraction at the cube corners
REAL(KIND=double)                :: ye            ! electron fraction at the cube corners
REAL(KIND=double)                :: tmev          ! temperature (MeV)

REAL(KIND=double)                :: pe            ! electron pressure (dynes cm^{-2})
REAL(KIND=double)                :: ee            ! electron energy (ergs cm^{-3})
REAL(KIND=double)                :: se            ! electron entropy
REAL(KIND=double)                :: cmpe          ! electron chemical potential (MeV)
REAL(KIND=double)                :: yeplus        ! positron fraction
REAL(KIND=double)                :: rel           ! relativity parameter

REAL(KIND=double)                :: ps            ! pressure
REAL(KIND=double)                :: us            ! energy
REAL(KIND=double)                :: ss            ! entropy
REAL(KIND=double)                :: cmpns         ! neutron chemical potential
REAL(KIND=double)                :: cmpps         ! proton chemical potential
REAL(KIND=double)                :: zs            ! proton number
REAL(KIND=double)                :: dbcks         ! stored value of dbck
REAL(KIND=double)                :: tbcks         ! stored value of tbck
REAL(KIND=double)                :: pp            ! upper value of pressure
REAL(KIND=double)                :: up            ! upper value of internal energy
REAL(KIND=double)                :: pm            ! lower value of pressure
REAL(KIND=double)                :: um            ! lower value of internal energy
REAL(KIND=double)                :: dpddbck       ! derivative of the pressure wrt density
REAL(KIND=double)                :: duddbck       ! derivative of the energy wrt density
REAL(KIND=double)                :: dpdtbck       ! derivative of the pressure wrt temperature
REAL(KIND=double)                :: dudtbck       ! derivative of the energy wrt temperature
REAL(KIND=double)                :: gamma1        ! first adiabatic exponent
REAL(KIND=double)                :: gamma3        ! third adiabatic exponent

REAL(KIND=double)                :: pprev         ! previous value of proton density
REAL(KIND=double)                :: t_old         ! old value of temperature

REAL(KIND=double)                :: cxproton      ! constant

REAL(KIND=double), DIMENSION(12,2,2,2) :: temp_store ! temporary storage for eos_z table entries

  101 FORMAT ('Equation of state identifier does not match either L or B')
 1001 FORMAT (' sf = 0 in eosdtgen_z; k=',i3,' ki_ray=',i3,' kj_ray=',i3, &
& ' rhod=',es10.3,' td=',es10.3,' yed=',es10.3)

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------

!-----------------------------------------------------------------------
!  Examine equation of state identifier
!-----------------------------------------------------------------------

IF ( eos_i /= 'L'  .and.  eos_i /= 'B'  .and.  eos_i /= 'S' ) THEN
  WRITE (nprint,101)
  WRITE (nlog,101)
  STOP
END IF

!-----------------------------------------------------------------------
!  Initialize constants
!-----------------------------------------------------------------------

IF ( first ) THEN

  tiny             = 10.d0**( - RANGE (test_number) )
  kfm              = cm3fm3/rmu    ! ( # nucleons/gram )( cm3/fm3 )
  kp               = ergmev/cm3fm3 ! ( erg/cm3 ) / ( mev/fm3 )
  ku               = ergmev/rmu    ! ( # nucleons/gram )( erg/mev )
  iflag            = 1
  forflg           = 0
  cxproton         = 1.d-2 * dsqrt(10.d0)
  CALL loadmx()
  first            = .false.

END IF ! first

sf                 = 1

!-----------------------------------------------------------------------
!  Compute independent variables at grid point
!-----------------------------------------------------------------------

rhod               = 10.d0**( DBLE(idd)/dgrid(idty(k,kj_ray,ki_ray)) )
td                 = 10.d0**( DBLE(itt)/tgrid(idty(k,kj_ray,ki_ray)) )
yed                = one  - ( DBLE(iyy)/ygrid(idty(k,kj_ray,ki_ray)) )
yed                = DMIN1( yed, one )

!-----------------------------------------------------------------------
!  Convert to independent variables of the Lattimer-Swesty and
!   Cooperstein BCK equation of stat
!-----------------------------------------------------------------------

brydns             = rhod * kfm
tmev               = td * kmev
ye                 = yed

!-----------------------------------------------------------------------
!  Test the low density, low temperature, high ye corner of
!   the unit cell to determine which equation of state to use.
!   The other corners must use the same equation of state.
!
!     If     brydns       > eosrho         and
!            tmev         > eost           and
!            nse(k,kj_ray,ki_ray) = 1      and
!            eos_i        = 'L'
!     then            use Lattimer-Swesty eos
!     otherwise,      use Cooperstein bck eos
!-----------------------------------------------------------------------

IF ( ida == 1  .and.  ita == 1  .and.  iya == 1 ) THEN
  IF ( brydns >= eosrho           .and.        &
&      tmev >= eost               .and.        &
&      nse(k,kj_ray,ki_ray) == 1  .and.        &
&      eos_i /= 'S' )                             THEN
    eos_ii         = 'L'
  ELSE
    eos_ii         = 'B'
  END IF ! brydns > eosrho, tmev > eost, nse(k,kj_ray,ki_ray) = 1, eos_i /= 'S'
END IF ! ida = 1, ita = 1, iya = 1

!-----------------------------------------------------------------------
!
!       \\\\\ CALL THE LATTIMER-SWESTY EQUATION OF STATE /////
!
!-----------------------------------------------------------------------

IF ( eos_ii == 'L' ) THEN

!-----------------------------------------------------------------------
!  Load Lattimer-Swesty equation of state parameters
!-----------------------------------------------------------------------

  DO id = 1,2
    DO it = 1,2
      DO iy = 1,2
        inpvars(k,1,id,it,iy) = ( one - ( DBLE(iyy+iy-1)/ygrid(idty(k,kj_ray,ki_ray)) ) ) * brydns
        inpvars(k,2,id,it,iy) = 0.155d+00
        inpvars(k,3,id,it,iy) = -15.d+00
        inpvars(k,4,id,it,iy) = -10.d+00
      END DO
    END DO
  END DO

!-----------------------------------------------------------------------
!  Call the Lattimer-Swesty equation of state
!-----------------------------------------------------------------------

  pprev            = DMIN1( inpvars(k,1,ida,ita,iya), brydns * ye )
  inpvar(1)        = tmev
  inpvar(2)        = inpvars(k,2,ida,ita,iya)
  inpvar(3)        = inpvars(k,3,ida,ita,iya)
  inpvar(4)        = inpvars(k,4,ida,ita,iya)

  CALL inveos( inpvar, t_old, ye, brydns, iflag, eosflg, forflg, sf, xprev, pprev )

!-----------------------------------------------------------------------
!
!   ||||| If sf /= 0 (LS EOS has converged), proceed normally. |||||
!
!-----------------------------------------------------------------------

  IF ( sf /= 0 ) THEN

!-----------------------------------------------------------------------
!  Store equation of state parameters for zone k
!-----------------------------------------------------------------------

    inpvars(k,1,ida,ita,iya) = pprev
    inpvars(k,2,ida,ita,iya) = inpvar(2)
    inpvars(k,3,ida,ita,iya) = inpvar(3)
    inpvars(k,4,ida,ita,iya) = inpvar(4)

!-----------------------------------------------------------------------
!  Calculate XPROT and XNUT if yed < 0.03
!-----------------------------------------------------------------------

    IF ( yed < 0.03d0 ) THEN
      XPROT        = yed
      XNUT         = one - yed
    END IF

!-----------------------------------------------------------------------
!  Compute electron equation of state
!-----------------------------------------------------------------------

    CALL e_p_eos( brydns, tmev, yed, pe, ee, se, cmpe, yeplus, rel )

!-----------------------------------------------------------------------
!  Convert thermodynamic quantities from units of mev and fm to cgs
!   units and temporarily store table entries.
!-----------------------------------------------------------------------

    temp_store( 1,ida,ita,iya) = ( PTOT - EPRESS + pe ) * kp
    temp_store( 2,ida,ita,iya) = ( UTOT + UTOT0 - EU + ee ) * ku
    temp_store( 3,ida,ita,iya) = STOT - ES + se
    temp_store( 4,ida,ita,iya) = ( MUN - dmnp )
    temp_store( 5,ida,ita,iya) = MUPROT
    temp_store( 6,ida,ita,iya) = cmpe
    temp_store( 7,ida,ita,iya) = XNUT
    temp_store( 8,ida,ita,iya) = XPROT
    temp_store( 9,ida,ita,iya) = XH
    temp_store(10,ida,ita,iya) = A
    temp_store(11,ida,ita,iya) = X * A
    temp_store(12,ida,ita,iya) = GAM_S

  ELSE ! sf = 0

!-----------------------------------------------------------------------
!
!  ||||| If sf = 0 (LS EOS has failed to converge), call the  |||||
!  |||||   Lattimer-Swesty EOS again with temperatures or     |||||
!  |||||   electron fraction on either side of the failed     |||||
!  |||||         attempt and average the results.             |||||
!  
!-----------------------------------------------------------------------

!-----------------------------------------------------------------------
!  Determine the variable increment
!-----------------------------------------------------------------------

    IF ( td < 1.1d+10  .and.  rhod < 2.d+12  .and.  ye > 0.154d0  .and.  ye < 0.172d0 ) THEN
      dye          = dye0
      dt           = zero
    ELSE
      dye          = zero
      dt           = dt0
    END IF

!-----------------------------------------------------------------------
!  Add an increment to the temperature
!-----------------------------------------------------------------------

    pprev          = DMIN1( inpvars(k,1,ida,ita,iya), brydns * ( ye + dye ) )
    inpvar(1)      = ( one + dt ) * tmev
    inpvar(2)      = inpvars(k,2,ida,ita,iya)
    inpvar(3)      = inpvars(k,3,ida,ita,iya)
    inpvar(4)      = inpvars(k,4,ida,ita,iya)

    CALL inveos( inpvar, t_old, ye + dye, brydns, iflag, eosflg, forflg, sf, xprev, pprev )

!-----------------------------------------------------------------------
!  Calculate XPROT and XNUT if yed < 0.03
!-----------------------------------------------------------------------

    IF ( yed < 0.03d0 ) THEN
      XPROT      = yed
      XNUT       = one - yed
    END IF

!-----------------------------------------------------------------------
!  Compute electron equation of state
!-----------------------------------------------------------------------

    CALL e_p_eos( brydns, tmev, yed, pe, ee, se, cmpe, yeplus, rel )

!-----------------------------------------------------------------------
!  Convert thermodynamic quantities from units of mev and fm to cgs
!   units and temporarily store table entries.
!-----------------------------------------------------------------------

    temp_store( 1,ida,ita,iya) = half * ( PTOT - EPRESS + pe ) * kp
    temp_store( 2,ida,ita,iya) = half * ( UTOT + UTOT0 - EU + ee ) * ku
    temp_store( 3,ida,ita,iya) = half * ( STOT - ES + se )
    temp_store( 4,ida,ita,iya) = half * ( MUN - dmnp )
    temp_store( 5,ida,ita,iya) = half * MUPROT
    temp_store( 6,ida,ita,iya) = half * cmpe
    temp_store( 7,ida,ita,iya) = half * XNUT
    temp_store( 8,ida,ita,iya) = half * XPROT
    temp_store( 9,ida,ita,iya) = half * XH
    temp_store(10,ida,ita,iya) = half * A
    temp_store(11,ida,ita,iya) = half * X * A
    temp_store(12,ida,ita,iya) = half * GAM_S

    IF ( sf == 0 ) then
      WRITE (nprint,1001) k, ki_ray, kj_ray, rhod, td, yed
      RETURN
    END IF ! sf = 0

!-----------------------------------------------------------------------
!  Now subtract an increment to the temperature
!-----------------------------------------------------------------------

    pprev          = DMIN1( inpvars(k,1,ida,ita,iya), brydns * ( ye - dye ) )
    inpvar(1)      = ( one - dt ) * tmev
    inpvar(2)      = inpvars(k,2,ida,ita,iya)
    inpvar(3)      = inpvars(k,3,ida,ita,iya)
    inpvar(4)      = inpvars(k,4,ida,ita,iya)

    CALL inveos( inpvar, t_old, ye - dye, brydns, iflag, eosflg, forflg, sf, xprev, pprev )

!-----------------------------------------------------------------------
!  Calculate XPROT and XNUT if yed < 0.03
!-----------------------------------------------------------------------

    IF ( yed < 0.03d0 ) THEN
      XPROT        = yed
      XNUT         = one - yed
    END IF

!-----------------------------------------------------------------------
!  Compute electron equation of state
!-----------------------------------------------------------------------

    CALL e_p_eos( brydns, tmev, yed, pe, ee, se, cmpe, yeplus, rel )
      
!-----------------------------------------------------------------------
!  Convert thermodynamic quantities from units of mev and fm to cgs
!   units and temporarily store table entries.
!-----------------------------------------------------------------------

    temp_store( 1,ida,ita,iya) = temp_store( 1,ida,ita,iya) + half * ( PTOT - EPRESS + pe ) * kp
    temp_store( 2,ida,ita,iya) = temp_store( 2,ida,ita,iya) + half * ( UTOT + UTOT0 - EU + ee ) * ku
    temp_store( 3,ida,ita,iya) = temp_store( 3,ida,ita,iya) + half * ( STOT - ES + se )
    temp_store( 4,ida,ita,iya) = temp_store( 4,ida,ita,iya) + half * ( MUN - dmnp )
    temp_store( 5,ida,ita,iya) = temp_store( 5,ida,ita,iya) + half * MUPROT
    temp_store( 6,ida,ita,iya) = temp_store( 6,ida,ita,iya) + half * cmpe
    temp_store( 7,ida,ita,iya) = temp_store( 7,ida,ita,iya) + half * XNUT
    temp_store( 8,ida,ita,iya) = temp_store( 8,ida,ita,iya) + half * XPROT
    temp_store( 9,ida,ita,iya) = temp_store( 9,ida,ita,iya) + half * XH
    temp_store(10,ida,ita,iya) = temp_store(10,ida,ita,iya) + half * A
    temp_store(11,ida,ita,iya) = temp_store(11,ida,ita,iya) + half * X * A
    temp_store(12,ida,ita,iya) = temp_store(12,ida,ita,iya) + half * GAM_S

    IF ( sf == 0 ) then
      WRITE (nprint,1001) k, ki_ray, kj_ray, rhod, td, yed
      RETURN
    END IF ! sf = 0


  END IF ! original sf = 0

!-----------------------------------------------------------------------
!  Permanently store EOS data if all table entries have been
!   successfully computed.
!-----------------------------------------------------------------------

  IF ( ida == 2  .and.  ita == 2  .and.  iya == 2 ) THEN
    DO iy = 1,2
      DO it = 1,2
        DO id = 1,2
          DO ii = 1,12
            estble(ii,k,id,it,iy,kj_ray,ki_ray) = temp_store(ii,id,it,iy)
          END DO
        END DO
      END DO
    END DO
  END IF

!-----------------------------------------------------------------------
!  End Lattimer-Swesty eos
!-----------------------------------------------------------------------

  RETURN
END IF

!-----------------------------------------------------------------------
!
!        \\\\\ CALL THE COOPERSTEIN BCK EQUATION OF STATE /////
!
!-----------------------------------------------------------------------

IF ( eos_ii == 'B' ) then

!-----------------------------------------------------------------------
!  Load BCK equation of state parameters for zone k
!-----------------------------------------------------------------------

  ue               = uea   (k,ida,ita,iya)
  un               = una   (k,ida,ita,iya)
  uhat             = uhata (k,ida,ita,iya)
  theta            = thetaa(k,ida,ita,iya)
  zabck            = zaa   (k,ida,ita,iya)
  xabck            = xaa   (k,ida,ita,iya)
  dtran            = dtrana(k,ida,ita,iya)
  jshel            = k
  dbck             = brydns
  tbck             = tmev
  yebck            = ye

!-----------------------------------------------------------------------
!  Call the BCK equation of state
!-----------------------------------------------------------------------

  CALL eos_z( ki_ray, kj_ray )
  IF ( xnbck <= zero  .or.  xpbck <= zero  .or.  stotbck <= zero ) THEN
    dtran          = dbck
    CALL eos_z( ki_ray, kj_ray )
  END IF ! xnbck < 0 or xpbck < 0 or stot < 0

!-----------------------------------------------------------------------
!  Store equation of state parameters for zone k
!-----------------------------------------------------------------------

  uea   (k,ida,ita,iya) = ue
  una   (k,ida,ita,iya) = un
  uhata (k,ida,ita,iya) = uhat
  thetaa(k,ida,ita,iya) = theta
  zaa   (k,ida,ita,iya) = zabck
  xaa   (k,ida,ita,iya) = xabck
  dtrana(k,ida,ita,iya) = dtran

!-----------------------------------------------------------------------
!  Convert thermodynamic quantities from units of mev and fm to cgs
!   units.
!-----------------------------------------------------------------------

  ps               = ptotbck * kp
  us               = etot * ku
  IF ( dbck .ge. dtran ) then
    xnbck          = one - ye
    xpbck          = ye
    xhbck          = zero
  END IF
  xnbck            = DMAX1( xnbck , zero )
  xpbck            = DMAX1( xpbck , zero )
  xhbck            = DMAX1( xhbck , zero )
  ss               = stotbck
  cmpns            = un
  cmpps            = un - uhat
  zs               = zabck * ahbck

!-----------------------------------------------------------------------
!  Store table entries
!-----------------------------------------------------------------------

  estble(1 ,k,ida,ita,iya,kj_ray,ki_ray) = ps
  estble(2 ,k,ida,ita,iya,kj_ray,ki_ray) = us
  estble(3 ,k,ida,ita,iya,kj_ray,ki_ray) = ss
  estble(4 ,k,ida,ita,iya,kj_ray,ki_ray) = cmpns
  estble(5 ,k,ida,ita,iya,kj_ray,ki_ray) = cmpps
  estble(6 ,k,ida,ita,iya,kj_ray,ki_ray) = ue
  estble(7 ,k,ida,ita,iya,kj_ray,ki_ray) = xnbck
  estble(8 ,k,ida,ita,iya,kj_ray,ki_ray) = xpbck
  estble(9 ,k,ida,ita,iya,kj_ray,ki_ray) = xhbck
  estble(10,k,ida,ita,iya,kj_ray,ki_ray) = ahbck
  estble(11,k,ida,ita,iya,kj_ray,ki_ray) = zs

!-----------------------------------------------------------------------
!  Compute derivatives of the pressure and energy with respect to the
!   density.
!-----------------------------------------------------------------------

  dbcks            = dbck
  dbck             = ( one + dlrho ) * dbcks
  CALL eos_z( ki_ray, kj_ray )
  pp               = ptotbck * kp
  up               = etot * ku

  dbck             = ( one - dlrho ) * dbcks
  CALL eos_z( ki_ray, kj_ray )
  pm               = ptotbck * kp
  um               = etot * ku

  dbck             = dbcks
  dpddbck          = ( pp - pm )/( 2.d+00 * dlrho * rhod )
  duddbck          = ( up - um )/( 2.d+00 * dlrho * rhod )

!-----------------------------------------------------------------------
!  Compute derivatives of the pressure and energy with respect to the
!   temperature.
!-----------------------------------------------------------------------

  tbcks            = tbck
  tbck             = ( one + dlt ) * tbcks
  CALL eos_z( ki_ray, kj_ray )
  pp               = ptotbck * kp
  up               = etot * ku

  tbck             = ( one - dlt ) * tbcks
  CALL eos_z( ki_ray, kj_ray )
  pm               = ptotbck * kp
  um               = etot * ku

  tbck             = tbcks
  dpdtbck          = ( pp - pm )/( 2.d+00 * dlt * td )
  dudtbck          = ( up - um )/( 2.d+00 * dlt * td )

!-----------------------------------------------------------------------
!  Compute gamma1 and gamma3
!-----------------------------------------------------------------------

  gamma3           = dpdtbck/( dudtbck * rhod ) + one
  gamma1           = ( td * dpdtbck * ( gamma3 - one ) + rhod * dpddbck )/ps

!-----------------------------------------------------------------------
!  Store table entry
!-----------------------------------------------------------------------

  estble(12,k,ida,ita,iya,kj_ray,ki_ray) = DMAX1( gamma1, tiny )

!-----------------------------------------------------------------------
!  End Cooperstein-BCK equation of state
!-----------------------------------------------------------------------

  RETURN
END IF

!-----------------------------------------------------------------------
!  Print diagnostic and exit if eos_i is neither 'L' nor 'B'
!-----------------------------------------------------------------------

WRITE (6,101) 
STOP

END SUBROUTINE eosdtgen_z
