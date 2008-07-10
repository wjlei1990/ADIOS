SUBROUTINE dimension_mdl_cnfg_y_arrays(ny)
!-----------------------------------------------------------------------
!
!    File:         dimension_mdl_cnfg_y_arrays
!    Module:       dimension_mdl_cnfg_y_arrays
!    Type:         Subprogram
!    Author:       S. W. Bruenn, Dept of Physics, FAU,
!                  Boca Raton, FL 33431-0991
!
!    Date:         3/21/05
!
!    Purpose:
!      To allocate dimensions to the model configuration y-arrays.
!
!    Subprograms called:
!        none
!
!    Input arguments:
!  ny        : y (angular) array extent
!
!    Output arguments:
!        none
!
!    Include files:
!  numerical_module
!  edit_module, mdl_cnfg_module, parallel_module
!
!-----------------------------------------------------------------------

USE numerical_module, ONLY : zero

USE edit_module, ONLY : nlog
USE mdl_cnfg_y_module
USE parallel_module, ONLY : myid

IMPLICIT none
SAVE

!-----------------------------------------------------------------------
!        Input variables
!-----------------------------------------------------------------------

CHARACTER (len=10)               :: var_name

INTEGER, INTENT(in)              :: ny            ! y (angular) array extent

!-----------------------------------------------------------------------
!        Local variables
!-----------------------------------------------------------------------

INTEGER                          :: istat         ! allocation status

!-----------------------------------------------------------------------
!        Formats
!-----------------------------------------------------------------------

  101 FORMAT (' Model y-configuration arrays have been dimensioned')
 1001 FORMAT (' Allocation problem for array ',a10,' in dimension_mdl_cnfg_y_arrays')

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------

!-----------------------------------------------------------------------
!
!            \\\\\ ALLOCATE MDL_CNFG_Y_MODULE ARRAYS /////
!
!-----------------------------------------------------------------------

!-----------------------------------------------------------------------
!  Thermodynamic state
!-----------------------------------------------------------------------

ALLOCATE (rho(ny), STAT = istat)
  IF ( istat /= 0 ) THEN; var_name = 'rho       '; WRITE (nlog,1001) var_name; END IF
ALLOCATE (t(ny), STAT = istat)
  IF ( istat /= 0 ) THEN; var_name = 't         '; WRITE (nlog,1001) var_name; END IF
ALLOCATE (ye(ny), STAT = istat)
  IF ( istat /= 0 ) THEN; var_name = 'ye        '; WRITE (nlog,1001) var_name; END IF

!-----------------------------------------------------------------------
!
!            \\\\\ INITIALIZE MDL_CNFG_Y_MODULE ARRAYS /////
!
!-----------------------------------------------------------------------

!-----------------------------------------------------------------------
!  Thermodynamic state
!-----------------------------------------------------------------------

rho                       = zero
t                         = zero
ye                        = zero

IF ( myid == 0 ) WRITE (nlog,101)

RETURN
END SUBROUTINE dimension_mdl_cnfg_y_arrays
