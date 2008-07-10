SUBROUTINE transpose_x_z( imin, imax, nx, kmin, kmax, nz, ij_ray_dim,     &
& ik_ray_dim, k_ray_dim, ny, nez, nnu, ls, le, nnc, n_proc, n_proc_y,     &
& n_proc_z, rho_c, t_c, ye_c, ei_c, u_c, v_c, w_c, psi0_c, psi1_e,        &
& xn_c, a_nuc_rep_c, z_nuc_rep_c, be_nuc_rep_c, nse_c, flat_x, agr_c,     &
& e_nu_c, grav_z_c, rho_z, t_z, ye_z, ei_z, u_z, v_z, w_z, nse_z, psi0_z, &
& psi1_z, xn_z, a_nuc_rep_z, z_nuc_rep_z, be_nuc_rep_z, flat_x_z,         &
& agr_z, grav_z_cz, e_nu_z )
!-----------------------------------------------------------------------
!
!    File:         transpose_x_z
!    Module:       transpose_x_z
!    Type:         Subprogram
!    Author:       S. W. Bruenn, Dept of Physics, FAU,
!                  Boca Raton, FL 33431-0991
!
!    Date:         9/24/04
!
!    Purpose:
!      To receive certain of the x-array variables in radial_ray_module,
!       transpose them so that all values of k reside on a given processor,
!       and send them back to be loaded into azimuthal_ray_module.
!
!    Subprograms called:
!        none
!
!    Input arguments:
!
!  imin         : lower x-array index
!  imax         : upper x-array index
!  nx           : x-array extent
!  ij_ray_dim   : number of y-zones on a processor before swapping with y
!  ik_ray_dim   : number of z-zones on a processor before swapping with z
!  kmin         : lower z-array index
!  kmax         : upper z-array index
!  nz           : z-array extent
!  k_ray_dim    : number of radial zones on a processor after swapping with y
!  ny           : y-array extent
!  nez          : neutrino energy array extent
!  nnu          : neutrino flavor array extent
!  ls           : lower composition index
!  le           : upper composition index
!  nnc          : composition array extent
!  n_proc       : number of processors assigned to the run
!  n_proc_y     : number of processors assigned to the y-indices of rays
!  n_proc_z     : number of processors assigned to the z-indices of rays
!  rho_c        : densities (g cm^{-3})
!  t_c          : temperatures (K)
!  ye_c         : electron fractions
!  ei_c         : internal energies (ergs g^{-1})
!  u_c          : velocity x-components (cm s^{-1})
!  v_c          : velocity y-components (cm s^{-1})
!  w_c          : velocity z-components (cm s^{-1})
!  psi0_c       : zero angular moments of the neutrino occupation number
!  psi0_e       : first angular moments of the neutrino occupation number
!  xn_c         : initial mass fractions
!  be_nuc_rep_c : binding energy of mean heavy nucleus
!  z_nuc_rep_c  : mass number of mean heavy nucleus
!  a_nuc_rep_c  : charge number of mean heavy nucleus
!  flat_x       : variable indicating the presence of a radial a shock
!  agr_c        : zone-centered value of the lapse function
!  grav_z_c     : zone-centered z-component of gravitational acceleration
!  e_nu_c       : neutrino energy density [ergs cm^{-3}]
!
!    Output arguments:
!
!  rho_z        : densities (g cm^{-3})
!  t_z          : temperatures (K)
!  ye_z         : electron fractions
!  ei_z         : internal energies (ergs g^{-1})
!  u_z          : velocity x-components (cm s^{-1})
!  v_z          : velocity y-components (cm s^{-1})
!  w_z          : velocity z-components (cm s^{-1})
!  psi0_z       : zero angular moments of the neutrino occupation number
!  psi0_z       : first angular moments of the neutrino occupation number
!  xn_z         : initial mass fractions
!  be_nuc_rep_z : binding energy of mean heavy nucleus
!  a_nuc_rep_z  : mass number of mean heavy nucleus
!  z_nuc_rep_z  : charge number of mean heavy nucleus
!  flat_x_z     : transposed variable indicating the presence of radial a shock
!  agr_z        : zone-centered value of the lapse function
!  grav_z_cz    : zone-centered z-component of gravitational acceleration
!  e_nu_z       : neutrino energy density [ergs cm^{-3}]
!
!      
!    Include files:
!  kind_module
!  edit_module, nu_energy_grid_module, shock_module
!
!-----------------------------------------------------------------------

USE kind_module, ONLY: double

USE edit_module, ONLY : nlog, nprint
USE nu_energy_grid_module, ONLY : nnugp
USE shock_module, ONLY: j_shk_radial_p, j_shk_radial_all_p


IMPLICIT none
SAVE

!-----------------------------------------------------------------------
!        Input variables
!-----------------------------------------------------------------------

INTEGER, INTENT(in)              :: imin               ! lower x-array index
INTEGER, INTENT(in)              :: imax               ! upper x-array index
INTEGER, INTENT(in)              :: nx                 ! x-array extent
INTEGER, INTENT(in)              :: ij_ray_dim         ! number of y-zones on a processor before swapping with y
INTEGER, INTENT(in)              :: ik_ray_dim         ! number of z-zones on a processor before swapping with z

INTEGER, INTENT(in)              :: kmin               ! lower z-array index
INTEGER, INTENT(in)              :: kmax               ! upper z-array index
INTEGER, INTENT(in)              :: nz                 ! z-array extent
INTEGER, INTENT(in)              :: k_ray_dim          ! number of radial zones on a processor after swapping with y

INTEGER, INTENT(in)              :: ny                 ! y-array extent
INTEGER, INTENT(in)              :: nez                ! neutrino energy array extent
INTEGER, INTENT(in)              :: nnu                ! neutrino flavor array extent

INTEGER, INTENT(in)              :: ls                 ! lower composition index
INTEGER, INTENT(in)              :: le                 ! upper composition index
INTEGER, INTENT(in)              :: nnc                ! composition array extent

INTEGER, INTENT(in)              :: n_proc             ! number of processors assigned to the run
INTEGER, INTENT(in)              :: n_proc_y           ! number of processors assigned to the y-indices of rays
INTEGER, INTENT(in)              :: n_proc_z           ! number of processors assigned to the z-indices of rays

INTEGER, INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)                   :: nse_c        ! nse flag

REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: rho_c        ! density (cm^{-3})
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: t_c          ! temperature (MeV)
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: ye_c         ! temperature (MeV)
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: ei_c         ! internal energy (ergs/g)
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: u_c          ! radial velocity of zone (cm)
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: v_c          ! y-velocity of zone (cm)
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: w_c          ! z-velocity of zone (cm)

REAL(KIND=double), INTENT(in), DIMENSION(nx,nez,nnu,ij_ray_dim,ik_ray_dim) :: psi0_c       ! zeroth angular moment of the NDS
REAL(KIND=double), INTENT(in), DIMENSION(nx,nez,nnu,ij_ray_dim,ik_ray_dim) :: psi1_e       ! first angular moment of the NDS

REAL(KIND=double), INTENT(in), DIMENSION(nx,nnc,ij_ray_dim,ik_ray_dim)     :: xn_c         ! mass fractions
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: a_nuc_rep_c  ! nuclear mass number
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: z_nuc_rep_c  ! nuclear charge number
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: be_nuc_rep_c ! nuclear binding energy
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: flat_x       ! variable indicating the presence of radial a shock
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: agr_c        ! zone-centered value of the lapse function
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: e_nu_c       ! neutrino energy density [ergs cm^{-3}]
REAL(KIND=double), INTENT(in), DIMENSION(nx,ij_ray_dim,ik_ray_dim)         :: grav_z_c     ! zone-centered y-component of gravitational acceleration

!-----------------------------------------------------------------------
!        Output variables
!-----------------------------------------------------------------------

INTEGER, INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)                   :: nse_z        ! nse flag

REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: rho_z        ! density (cm^{-3})
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: t_z          ! temperature (MeV)
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: ye_z         ! temperature (MeV)
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: ei_z         ! internal energy (ergs/g)
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: u_z          ! radial velocity of zone (cm)
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: v_z          ! y-velocity of zone (cm)
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: w_z          ! z-velocity of zone (cm)

REAL(KIND=double), INTENT(out), DIMENSION(nz,nez,nnu,ij_ray_dim,k_ray_dim) :: psi0_z       ! zeroth angular moment of the NDS
REAL(KIND=double), INTENT(out), DIMENSION(nz,nez,nnu,ij_ray_dim,k_ray_dim) :: psi1_z       ! first angular moment of the NDS

REAL(KIND=double), INTENT(out), DIMENSION(nz,nnc,ij_ray_dim,k_ray_dim)     :: xn_z         ! mass fractions
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: a_nuc_rep_z  ! nuclear mass number
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: z_nuc_rep_z  ! nuclear charge number
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: be_nuc_rep_z  ! nuclear binding energy
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: flat_x_z     ! variable indicating the presence of radial a shock
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: agr_z        ! zone-centered value of the lapse function
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: grav_z_cz    ! zone-centered y-component of gravitational acceleration
REAL(KIND=double), INTENT(out), DIMENSION(nz,ij_ray_dim,k_ray_dim)         :: e_nu_z       ! neutrino energy density [ergs cm^{-3}]

!-----------------------------------------------------------------------
!        Local variables
!-----------------------------------------------------------------------

INTEGER                        :: i             ! x-array index
INTEGER                        :: k             ! z-array index
INTEGER                        :: ie            ! neutrino energy index
INTEGER                        :: l             ! composition index
INTEGER                        :: n             ! neutrino flavor index
!-----------------------------------------------------------------------
!        Formats
!-----------------------------------------------------------------------

  101 FORMAT (' Need MPI version of transpose_x_z since n_proc=',i4,' > 1')

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------

!-----------------------------------------------------------------------
!  Stop if n_proc > 1.
!-----------------------------------------------------------------------

IF ( n_proc > 1 ) THEN
  WRITE (nprint,101) n_proc
  WRITE (nlog,101) n_proc
  STOP
END IF ! n_proc > 1

!-----------------------------------------------------------------------
!
!                    \\\\\ LOAD Y-ARRAYS /////
!
!-----------------------------------------------------------------------

j_shk_radial_all_p(:,:)      = j_shk_radial_p(:,:)

!-----------------------------------------------------------------------
!
!                  \\\\\ TRANSPOSE VARIABLES /////
!
!-----------------------------------------------------------------------

DO i = imin,imax
  DO k = kmin,kmax
    rho_z       (k,:,i)      = rho_c       (i,:,k)
    t_z         (k,:,i)      = t_c         (i,:,k)
    ye_z        (k,:,i)      = ye_c        (i,:,k)
    ei_z        (k,:,i)      = ei_c        (i,:,k)
    u_z         (k,:,i)      = u_c         (i,:,k)
    v_z         (k,:,i)      = v_c         (i,:,k)
    w_z         (k,:,i)      = w_c         (i,:,k)
    a_nuc_rep_z (k,:,i)      = a_nuc_rep_c (i,:,k)
    z_nuc_rep_z (k,:,i)      = z_nuc_rep_c (i,:,k)
    be_nuc_rep_z(k,:,i)      = be_nuc_rep_c(i,:,k)
    nse_z       (k,:,i)      = nse_c       (i,:,k)
    flat_x_z    (k,:,i)      = flat_x      (i,:,k)
    agr_z       (k,:,i)      = agr_c       (i,:,k)
    grav_z_cz   (k,:,i)      = grav_z_c    (i,:,k)
    e_nu_z      (k,:,i)      = e_nu_c      (i,:,k)
  END DO
END DO

DO l = ls,le
  DO i = imin,imax
    DO k = kmin,kmax
      xn_z(k,l,:,i)          = xn_c(i,l,:,k)
    END DO
  END DO
END DO

DO n = 1,nnu
  IF ( nnugp(n) == 0 ) CYCLE
  DO ie = 1,nnugp(n)
    DO i = imin,imax
      DO k = kmin,kmax
        psi0_z(k,ie,n,:,i)   = psi0_c(i,ie,n,:,k) 
        psi1_z(k,ie,n,:,i)   = psi1_e(i,ie,n,:,k) 
      END DO
    END DO
  END DO
END DO

RETURN
END SUBROUTINE transpose_x_z
