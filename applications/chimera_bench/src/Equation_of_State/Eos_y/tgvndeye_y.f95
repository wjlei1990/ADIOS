SUBROUTINE tgvndeye_y( j, ji_ray, jk_ray, rho, e, ye, t_prev, t )
!-----------------------------------------------------------------------
!
!    File:         tgvndeye_y
!    Module:       tgvndeye_y
!    Type:         Subprogram
!    Author:       S. W. Bruenn, Dept of Physics, FAU,
!                  Boca Raton, FL 33431-0991
!
!    Date:         3/19/05
!
!    Purpose:
!      To compute the temperature given rho, s, and ye. Iteration
!       is by means of the bisection method if an initial guess
!       of the temperature is unavailable or is not within fraction
!       of the previous value, otherwise by Newton-Rhapson.
!
!    Variables that must be passed through common:
!   nse(j): nuclear statistical equilibrium flag for angular zone j.
!
!    Subprograms called:
!  esrgn_y_t : computes (if the temperature warrants) a new EOS-cube
!  eqstt_y   : interpolates between cube corners to a given state point
!
!    Input arguments:
!  j         : y (angular) zone index.
!  ji_ray    : i (radial) index of a specific y (angular) ray
!  jk_ray    : k (azimuthal) index of a specific y (angular) ray
!  rho       : density (g/cm**3).
!  e         : inernal energy (ergs/g)
!  ye        : electron fraction.
!  t_prev    : temperature guess.
!
!    Output arguments:
!  t         : temperature (K)
!
!    Include files:
!  kind_module, array_module, numerical_module
!  edit_module, eos_snc_y_module, parallel_module
!
!-----------------------------------------------------------------------

USE kind_module, ONLY : double
USE array_module, ONLY: n_proc_y, ij_ray_dim, j_ray_dim, ik_ray_dim, ny
USE numerical_module, ONLY: epsilon, half

USE edit_module, ONLY: nprint, nlog
USE eos_snc_y_module, ONLY : nse
USE parallel_module, ONLY : myid, myid_y, myid_z

IMPLICIT NONE
SAVE

!-----------------------------------------------------------------------
!        Input variables.
!-----------------------------------------------------------------------

INTEGER, INTENT(in)              :: j             ! angular zone index
INTEGER, INTENT(in)              :: ji_ray        ! i (radial) index of a specific y (angular) ray
INTEGER, INTENT(in)              :: jk_ray        ! k (azimuthal) index of a specific y (angular) ray

REAL(KIND=double), INTENT(in)    :: rho           ! ensity (g/cm**3)
REAL(KIND=double), INTENT(in)    :: e             ! inernal energy (ergs/g)
REAL(KIND=double), INTENT(in)    :: ye            ! electron fraction
REAL(KIND=double), INTENT(in)    :: t_prev        ! guess of the temperature

!-----------------------------------------------------------------------
!        Output variables.
!-----------------------------------------------------------------------

REAL(KIND=double), INTENT(out)   :: t             ! temperature (K)

!-----------------------------------------------------------------------
!        Local variables
!-----------------------------------------------------------------------

INTEGER, PARAMETER               :: itmax = 50    ! maximum number of iterations
INTEGER                          :: it            ! iteration index
INTEGER                          :: ivar = 2      ! EOS energy index
INTEGER                          :: j_angular     ! angular ray index
INTEGER                          :: k_angular     ! azimuthal ray index
INTEGER                          :: jm1           ! mimimum of j-1 and 1
INTEGER                          :: jp1           ! maximum of j+1 and ny
INTEGER                          :: j_ray_bndl    ! polar index of the radial ray bundle
INTEGER                          :: k_ray_bndl    ! azimuthal index of the radial ray bundle

REAL(KIND=double), PARAMETER     :: tol = 1.d-8   ! convergence criterion
REAL(KIND=double), PARAMETER     :: t_min = 1.d+07! minimum temperature for bisection
REAL(KIND=double), PARAMETER     :: t_max = 5.d+11! maximum temperature for bisection
REAL(KIND=double)                :: tmin          ! minimum temperature during bisection iteration
REAL(KIND=double)                :: tmax          ! maximum temperature during bisection iteration
REAL(KIND=double)                :: t_test        ! temperature guess for iteration
REAL(KIND=double)                :: e_test        ! energy computed using t_test
REAL(KIND=double)                :: dedd          ! derivative of the energy wrt density
REAL(KIND=double)                :: dedt          ! derivative of the temperature wrt density
REAL(KIND=double)                :: dedy          ! derivative of the electron fraction wrt density
REAL(KIND=double)                :: dt            ! increment in temperature

!-----------------------------------------------------------------------
!        Formats
!-----------------------------------------------------------------------

 1001 FORMAT (' NR iteration for e will not converge in subroutine tgvndeye_y, will try Bisection')
 1003 FORMAT (' j=',i4,' j_ray_bndl=',i4,' k_ray_bndl=',i4,' j_angular=',i4, &
& ' k_angular=',i4,' myid=',i4,' rho=',es11.3,' t_prev=',es11.3, ' ye=',es11.3, &
& ' e=',es20.11,' e_test=',es20.11,' t_test=',es20.11)
 1005 FORMAT (' nes(',i4,')=',i4,' nes(',i4,')=',i4,' nes(',i4,')=',i4)
 2001 FORMAT (' it=',i4,' rho=',es12.4,' t_test=',es12.4,' ye=',es12.4, &
& ' e=',es12.4,' e_test=',es12.4,' tmin=',es12.4,' tmax=',es12.4)
 2003 FORMAT (' Bisection iteration for e will not converge in subroutine tgvndeye_y')
 2005 FORMAT (' j=',i4,' j_ray_bndl=',i4,' k_ray_bndl=',i4,' j_angular=',i4, &
& ' k_angular=',i4,' e=',es20.11, ' e_test=',es20.11,' tmin=',es20.11, &
& ' tmax=',es20.11)

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------

!-----------------------------------------------------------------------
!
!               \\\\\ NEWTON-RHAPSON ITERATION /////
!
!-----------------------------------------------------------------------

t_test             = t_prev

DO it = 1,itmax

!-----------------------------------------------------------------------
!  esrgn_y not called to avoid discontinuity in t
!-----------------------------------------------------------------------

  CALL eqstt_y( ivar, j, ji_ray,jk_ray, rho, t_test, ye, e_test, dedd, &
&  dedt, dedy )

  IF ( DABS( e - e_test ) <= tol * DABS(e)  .and.  it /= 1 ) THEN
    t              = t_test
    RETURN
  END IF

  dt               = ( e - e_test )/( dedt + epsilon )
  t_test           = DMIN1( DMAX1( t_test + dt, 0.9d0 * t_test ), 1.1d0 * t_test )

END DO

!-----------------------------------------------------------------------
!  Ray coordinates
!-----------------------------------------------------------------------

j_angular          = myid_y * j_ray_dim + ji_ray
k_angular          = myid_z * ik_ray_dim + jk_ray
j_ray_bndl         = MOD( myid, n_proc_y ) * ij_ray_dim + 1
k_ray_bndl         = ( myid/n_proc_y ) * ik_ray_dim + 1

!-----------------------------------------------------------------------
!  Edit diagnostics
!-----------------------------------------------------------------------

jm1                = MAX( j - 1, 1 )
jp1                = MIN( j + 1, ny )

WRITE (nprint,1001)
WRITE (nprint,1003) j, j_ray_bndl, k_ray_bndl, j_angular, k_angular, myid, &
& rho, t_prev, ye, e, e_test, t_test
WRITE (nprint,1005) jm1, nse(jm1,ji_ray,jk_ray), j, nse(j,ji_ray,jk_ray), &
& jp1, nse(jp1,ji_ray,jk_ray)
WRITE (nlog,1001)
WRITE (nlog,1003) j, j_ray_bndl, k_ray_bndl, j_angular, k_angular, myid, &
& rho, t_prev, ye, e, e_test, t_test
WRITE (nlog,1005) jm1, nse(jm1,ji_ray,jk_ray), j, nse(j,ji_ray,jk_ray), &
& jp1, nse(jp1,ji_ray,jk_ray)

!-----------------------------------------------------------------------
!
!                  \\\\\ BISECTION ITERATION /////
!
!-----------------------------------------------------------------------

!-----------------------------------------------------------------------
!  Set iteration boundaries
!-----------------------------------------------------------------------

tmin               = t_min
tmax               = t_max

!-----------------------------------------------------------------------
!  Iterate
!-----------------------------------------------------------------------

DO it = 1,itmax

  t_test           = half * ( tmin + tmax )

  CALL esrgn_y_t( j, ji_ray, jk_ray, rho, t_test, ye )
  CALL eqstt_y( ivar, j, ji_ray, jk_ray, rho, t_test, ye, e_test, dedd, dedt, dedy )

  WRITE (nlog,2001) it, rho, t_test, ye, e, e_test, tmin, tmax

  IF ( DABS( e - e_test ) <= tol * DABS(e) ) THEN
    t              = t_test
    RETURN
  END IF

  IF ( e_test <= e ) THEN
    tmin           = t_test
  ELSE
    tmax           = t_test
  END IF

END DO

!-----------------------------------------------------------------------
!  Ray coordinates
!-----------------------------------------------------------------------

j_angular          = myid_y * j_ray_dim + ji_ray
k_angular          = myid_z * ik_ray_dim + jk_ray
j_ray_bndl         = MOD( myid, n_proc_y ) * ij_ray_dim + 1
k_ray_bndl         = ( myid/n_proc_y ) * ik_ray_dim + 1

!-----------------------------------------------------------------------
!  Edit diagnostics
!-----------------------------------------------------------------------

WRITE (nprint,2003)
WRITE (nprint,2005) j, j_ray_bndl, k_ray_bndl, j_angular, k_angular, e, &
& e_test, tmin, tmax
WRITE (nlog,2003)
WRITE (nlog,2005) j, j_ray_bndl, k_ray_bndl, j_angular, k_angular, e, &
& e_test, tmin, tmax
STOP

!-----------------------------------------------------------------------
!  Done
!-----------------------------------------------------------------------

RETURN
END SUBROUTINE tgvndeye_y
