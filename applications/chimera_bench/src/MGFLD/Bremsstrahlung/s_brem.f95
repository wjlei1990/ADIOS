SUBROUTINE s_brem( x_p, y_p, eta_star_p,s_fit )
!-----------------------------------------------------------------------
!
!    File:         s_brem
!    Module:       s_brem
!    Type:         Subroutine
!    Author:       S. W. Bruenn, Dept of Physics, FAU,
!                  Boca Raton, FL 33431-0991
!
!    Date:         7/23/02
!
!    Purpose:
!      To compute s-component of the kernal for neutrino bremss-
!       trahlung and inelastic neutrino scattering in a nucleon
!       field.
!
!    Variables that must be passed through common:
!        none
!
!    Subprograms called:
!        none
!
!    Input arguments:
!  y           : m_{pi}^{2}/M_{N}c^{2}kT
!  eta_star    : neutron degeneracy parameter
!
!    Output arguments:
!  s_fit       : dimensionless quantity related to S_{sigma}
!
!    Modules:
!  kind_module, numerical_module, physcnst_module
!
!-----------------------------------------------------------------------

USE kind_module
USE numerical_module, ONLY : zero, half, one, third, pi2
USE physcnst_module, ONLY : pi

IMPLICIT NONE
SAVE

!-----------------------------------------------------------------------
!        Input variables.
!-----------------------------------------------------------------------

REAL(KIND=double), INTENT(in)  :: x_p                  ! w/tmev
REAL(KIND=double), INTENT(in)  :: y_p                  ! pion mass parameter
REAL(KIND=double), INTENT(in)  :: eta_star_p           ! degeneracy parameter

!-----------------------------------------------------------------------
!        Output variables.
!-----------------------------------------------------------------------

REAL(KIND=double), INTENT(out) :: s_fit                ! dimensionless fitting parameter

!-----------------------------------------------------------------------
!        Local variables
!-----------------------------------------------------------------------

REAL(KIND=double)              :: x                    ! use in place of x_p
REAL(KIND=double)              :: y                    ! use in place of y_p
REAL(KIND=double)              :: eta_star             ! use in place of eta_star_p

REAL(KIND=double), PARAMETER   :: x_min = 1.d-10
REAL(KIND=double), PARAMETER   :: y_min = 1.d-10
REAL(KIND=double), PARAMETER   :: eta_min = 1.d-10
REAL(KIND=double), PARAMETER   :: fi_third = 5.d0/3.d0
REAL(KIND=double), PARAMETER   :: fi_sixth = 5.d0/6.d0

REAL(KIND=double)              :: pi1_2                ! pi**(1/2)
REAL(KIND=double)              :: pi1_8                ! pi**(1/8)
REAL(KIND=double)              :: s_ND_num             ! numerator of s_ND
REAL(KIND=double)              :: s_ND_denom           ! denominator of s_ND
REAL(KIND=double)              :: s_ND                 ! nondegenerate limit of s_fit
REAL(KIND=double)              :: u                    ! y/(2*eta_star)
REAL(KIND=double)              :: u2                   ! u**2
REAL(KIND=double)              :: u_arg                ! a function of u
REAL(KIND=double)              :: f_u                  ! a function of u
REAL(KIND=double)              :: s_D                  ! degenerate limit of s_fit
REAL(KIND=double)              :: C_fit                ! fitting function
REAL(KIND=double)              :: F_denom              ! denominator of F_fit
REAL(KIND=double)              :: F_fit                ! fitting function
REAL(KIND=double)              :: G_fit                ! fitting function
REAL(KIND=double)              :: h_fit                ! fitting function
REAL(KIND=double)              :: p_fit                ! fitting function
REAL(KIND=double)              :: fexp                 ! declare function

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------

pi1_2              = pi**(1.d0/2.d0)
pi1_8              = pi**(1.d0/8.d0)

!-----------------------------------------------------------------------
!  Replace input variables for modification
!-----------------------------------------------------------------------

x                  = x_p
y                  = y_p
eta_star           = eta_star_p

!-----------------------------------------------------------------------
!  Prevent singular behavior of terms
!-----------------------------------------------------------------------

IF ( x >= zero ) THEN
  x                = MAX( x       , x_min   )
ELSE
  x                = MIN( x       ,-x_min   )
END IF
y                  = MAX( y       , y_min   )
eta_star           = MAX( eta_star, eta_min )

!-----------------------------------------------------------------------
!  Compute S_ND, nondegenerate approximation
!-----------------------------------------------------------------------

s_ND_num           = 2.d0 * pi1_2 * ( x + 2.d0 - exp(- y/12.d0 ) )**1.5d0 &
&                  * ( x**2 + 2.d0 * x * y + fi_third * y**2 + 1.d0 )
s_ND_denom         = pi1_2 + ( pi1_8 + x + y )**4
s_ND               = s_ND_num/s_ND_denom

IF ( x < zero ) S_ND = S_ND * fexp(-x)

!-----------------------------------------------------------------------
!  Compute S_D, degenerate approximation
!-----------------------------------------------------------------------

u                  = DSQRT( y/( 2.d0 * eta_star ) ) + 1.d-10
u2                 = u * u
u_arg              = u2/( 2.d0 * DSQRT( 2.d0 * u2 + 4.d0 ) )
f_u                = one - fi_sixth * u * DATAN( 2.d0/u )                 &
&                  + u2/( 3.d0 * ( u2 + 4.d0 ) )                          &
&                  + DATAN( one/u_arg ) * third * u_arg
s_D                = 3.d0 * ( half * pi )**2.5d0 * eta_star**( -2.5d0 )   &
&                  * ( x**2 + 4.d0 * pi2 ) * x * f_u                      &
&                  / ( 4.d0 * pi2 * ( one - fexp(-x) ) )

!-----------------------------------------------------------------------
!  Compute F_fit
!-----------------------------------------------------------------------

F_denom            = ( 3.d0 + ( x - 1.2d0 )**2 + x**(-4.d0) )             &
&                  * ( one + eta_star**2 ) * ( one + y**4.d0 )
F_fit              = one + one/F_denom

!-----------------------------------------------------------------------
!  Compute G_fit
!-----------------------------------------------------------------------

G_fit              = one - 0.0044d0 * x**1.1d0                            &
&                  * y/( 0.8d0 + 0.06d0 * y**1.05d0 )                     &
&                  * sqrt( eta_star )/( eta_star + 0.2d0 )

!-----------------------------------------------------------------------
!  Compute C_fit
!-----------------------------------------------------------------------

h_fit              = 0.1d0 * eta_star                                     &
&                  / ( 2.39d0 + 0.1d0 * eta_star**1.1d0 )
C_fit              = 1.1d0 * x**1.1d0 * h_fit                             &
&                  / ( 2.3d0 + h_fit * x**0.93d0 + 0.0001d0 * x**1.2d0 )  &
&                  * 30.d0/( 30.d0 + 0.005d0 * x**2.8d0 )

!-----------------------------------------------------------------------
!  Compute s_fit
!-----------------------------------------------------------------------

p_fit              = 0.67d0 + 0.18d0 * y**0.4d0
s_fit              = ( s_ND**(-p_fit) + s_D**(-p_fit) )**( - one/p_fit )  &
&                  * F_fit * ( one + C_fit * G_fit )

RETURN
END SUBROUTINE s_brem
