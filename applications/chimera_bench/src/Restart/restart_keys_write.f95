SUBROUTINE restart_keys_write( ndump, nez, nnu )
!-----------------------------------------------------------------------
!
!    File:         restart_keys_write
!    Module:       restart_keys_write
!    Type:         Subprogram
!    Author:       S. W. Bruenn, Dept of Physics, FAU,
!                  Boca Raton, FL 33431-0991
!
!    Date:         9/01/05
!
!    Purpose:
!      To direct the writing of the simulation keys for restarting a simulation.
!
!    Subprograms called:
!  array_dimensions_write : writes out the array dimensions
!  radhyd_write           : writes out the radhyd keys
!  e_advct_write          : writes out the neutrino energy advection keys
!  eos_write              : writes out the equation of state keys
!  transport_write        : writes out the neutrino transport keys
!  edit_write             : writes out the edit keys
!  hydro_write            : writes out the hydro keys
!
!    Input arguments:
!  ndump                  : unit number to write restart dump
!  nez                    : neutrino energy array extent
!  nnu                    : neutrino flavor array extent
!
!    Output arguments:
!        none
!
!    Include files:
!  kind_module
!  cycle_module, edit_module
!
!-----------------------------------------------------------------------

USE kind_module, ONLY : double

USE cycle_module, ONLY : nrst
USE edit_module, ONLY : nrrst, nouttmp

IMPLICIT none
SAVE

!-----------------------------------------------------------------------
!        Input variables.
!-----------------------------------------------------------------------

INTEGER, INTENT(in)              :: ndump         ! unit number to write temporary restart dumps
INTEGER, INTENT(in)              :: nez           ! neutrino energy array extent
INTEGER, INTENT(in)              :: nnu           ! neutrino flavor array extent

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------

!-----------------------------------------------------------------------
!
!         \\\\\ WRITE SIMULATION KEYS TO A RESTART FILE /////
!
!-----------------------------------------------------------------------

!-----------------------------------------------------------------------
!  Write array_dimensions
!-----------------------------------------------------------------------

CALL array_dimensions_write( ndump )

!-----------------------------------------------------------------------
!  Write radyhd keys
!-----------------------------------------------------------------------

CALL radhyd_write( ndump )

!-----------------------------------------------------------------------
!  Write neutrino energy advection keys
!-----------------------------------------------------------------------

CALL e_advct_write( ndump, nnu )

!-----------------------------------------------------------------------
!  Write equation of state keys
!-----------------------------------------------------------------------

CALL eos_write( ndump )

!-----------------------------------------------------------------------
!  Write transport keys
!-----------------------------------------------------------------------

CALL transport_write( ndump, nnu )

!-----------------------------------------------------------------------
!  Write edit keys
!-----------------------------------------------------------------------

CALL edit_write( ndump, nez, nnu )

!-----------------------------------------------------------------------
!  Write hydro keys
!-----------------------------------------------------------------------

CALL hydro_write( ndump )

!-----------------------------------------------------------------------
!  Write muclear keys
!-----------------------------------------------------------------------

CALL nuclear_keys_write( ndump )

RETURN
END SUBROUTINE restart_keys_write
