!> @file
!> @brief Contains MODULE W3SRC1MD.
!>
!> @author H. L. Tolman  @date 29-May-2009
!>

#include "w3macros.h"
!>
!> @brief Bundle WAM cycle 3 input and dissipation source terms with
!>  their defining parameters.
!>
!> @author  H. L. Tolman  @date 29-May-2009
!>
!/ ------------------------------------------------------------------- /
MODULE W3SRC1MD
  !/
  !/                  +-----------------------------------+
  !/                  | WAVEWATCH III           NOAA/NCEP |
  !/                  |           H. L. Tolman            |
  !/                  |                        FORTRAN 90 |
  !/                  | Last update :         29-May-2009 |
  !/                  +-----------------------------------+
  !/
  !/    06-Dec-1996 : Final FORTRAN 77                    ( version 1.18 )
  !/    06-Dec-1999 : Upgrade to FORTRAN 90               ( version 2.00 )
  !/    23-Dec-2004 : Multiple grid version.              ( version 3.06 )
  !/    29-May-2009 : Preparing distribution version.     ( version 3.14 )
  !/
  !/    Copyright 2009 National Weather Service (NWS),
  !/       National Oceanic and Atmospheric Administration.  All rights
  !/       reserved.  WAVEWATCH III is a trademark of the NWS.
  !/       No unauthorized use without permission.
  !/
  !  1. Purpose :
  !
  !     Bundle WAM cycle 3 input and dissipation source terms with
  !     their defining parameters.
  !
  !  2. Variables and types :
  !
  !  3. Subroutines and functions :
  !
  !      Name      Type  Scope    Description
  !     ----------------------------------------------------------------
  !      W3SPR1    Subr. Public   Mean parameters from spectrum.
  !      W3SIN1    Subr. Public   Input source term.
  !      W3SDS1    Subr. Public   Dissipation source term.
  !     ----------------------------------------------------------------
  !
  !  4. Subroutines and functions used :
  !
  !      Name      Type  Module   Description
  !     ----------------------------------------------------------------
  !      STRACE    Subr. W3SERVMD Subroutine tracing.            ( !/S )
  !      PRT2DS    Subr. W3ARRYMD Print plot of spectra.        ( !/T0 )
  !      OUTMAT    Subr. W3WRRYMD Print out 2D matrix.          ( !/T1 )
  !     ----------------------------------------------------------------
  !
  !  5. Remarks :
  !
  !  6. Switches :
  !
  !       !/S      Enable subroutine tracing.
  !       !/T(n)   Test output, see subroutines.
  !
  !  7. Source code :
  !
  !/ ------------------------------------------------------------------- /
  !/
  PUBLIC
  !/
CONTAINS
  !/ ------------------------------------------------------------------- /
  !>
  !> @brief
  !>
  !> @param[in]  A      Action as a function of direction and wavenumber.
  !> @param[in]  CG     Group velocities.
  !> @param[in]  WN     Wavenumber.
  !> @param[out] EMEAN  Mean wave energy.
  !> @param[out] FMEAN  Mean wave frequency.
  !> @param[out] WNMEAN mean wavenumber.
  !> @param[out] AMAX   Maximum action density in spectrum.
  !>
  !> @author H. L. Tolman  @date 23-Dec-2004
  !>
  SUBROUTINE W3SPR1 (A, CG, WN, EMEAN, FMEAN, WNMEAN, AMAX)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           H. L. Tolman            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         23-Dec-2004 |
    !/                  +-----------------------------------+
    !/
    !/    06-Dec-1996 : Final FORTRAN 77                    ( version 1.18 )
    !/    06-Dec-1999 : Upgrade to FORTRAN 90               ( version 2.00 )
    !/    23-Dec-2004 : Multiple grid version.              ( version 3.06 )
    !/
    !  1. Purpose :
    !
    !     Calculate mean wave parameters for the use in the source term
    !     routines. (WAM-3)
    !
    !  2. Method :
    !
    !     See source term routines.
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       A       R.A.  I   Action as a function of direction and
    !                         wavenumber.
    !       CG      R.A.  I   Group velocities.
    !       WN      R.A.  I   Wavenumbers.
    !       EMEAN   Real  O   Mean wave energy.
    !       FMEAN   Real  O   Mean wave frequency.
    !       WNMEAN  Real  O   Mean wavenumber.
    !       AMAX    Real  O   Maximum action density in spectrum.
    !     ----------------------------------------------------------------
    !
    !  4. Subroutines used :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      STRACE    Subr. W3SERVMD Subroutine tracing.
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      W3SRCE    Subr. W3SRCEMD Source term integration.
    !      W3EXPO    Subr.   N/A    Point output post-processor.
    !      GXEXPO    Subr.   N/A    GrADS point output post-processor.
    !     ----------------------------------------------------------------
    !
    !  6. Error messages :
    !
    !     None.
    !
    !  7. Remarks :
    !
    !  8. Structure :
    !
    !     See source code.
    !
    !  9. Switches :
    !
    !     !/S  Enable subroutine tracing.
    !     !/T  Enable test output.
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    USE CONSTANTS
    USE W3GDATMD, ONLY: NK, NTH, SIG, DDEN, FTE, FTF, FTWN
#ifdef W3_T
    USE W3ODATMD, ONLY: NDST
#endif
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    REAL, INTENT(IN)        :: A(NTH,NK), CG(NK), WN(NK)
    REAL, INTENT(OUT)       :: EMEAN, FMEAN, WNMEAN, AMAX
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    INTEGER                 :: IK, ITH
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    REAL                    :: EB(NK), EBAND
    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'W3SPR1')
#endif
    !
    EMEAN  = 0.
    FMEAN  = 0.
    WNMEAN = 0.
    AMAX   = 0.
    !
    ! 1.  Integral over directions
    !
    DO IK=1, NK
      EB(IK) = 0.
      DO ITH=1, NTH
        EB(IK) = EB(IK) + A(ITH,IK)
        AMAX   = MAX ( AMAX , A(ITH,IK) )
      END DO
    END DO
    !
    ! 2.  Integrate over directions
    !
    DO IK=1, NK
      EB(IK) = EB(IK) * DDEN(IK) / CG(IK)
      EMEAN  = EMEAN  + EB(IK)
      FMEAN  = FMEAN  + EB(IK) / SIG(IK)
      WNMEAN = WNMEAN + EB(IK) / SQRT(WN(IK))
    END DO
    !
    ! 3.  Add tail beyond discrete spectrum
    !     ( DTH * SIG absorbed in FTxx )
    !
    EBAND  = EB(NK) / DDEN(NK)
    EMEAN  = EMEAN  + EBAND * FTE
    FMEAN  = FMEAN  + EBAND * FTF
    WNMEAN = WNMEAN + EBAND * FTWN
    !
    ! 4.  Final processing
    !
    FMEAN  = TPIINV * EMEAN / MAX ( 1.E-7 , FMEAN )
    WNMEAN = ( EMEAN / MAX ( 1.E-7 , WNMEAN ) )**2
    !
#ifdef W3_T
    WRITE (NDST,9000) EMEAN, FMEAN, WNMEAN
#endif
    !
    RETURN
    !
    ! Formats
    !
#ifdef W3_T
9000 FORMAT (' TEST W3SPR1 : E,F,WN MEAN ',3E10.3)
#endif
    !/
    !/ End of W3SPR1 ----------------------------------------------------- /
    !/
  END SUBROUTINE W3SPR1
  !/ ------------------------------------------------------------------- /
  !>
  !> @brief Calculate diagonal of input source (actual source term put
  !>  together in W3SRCE).
  !>
  !> @param[in]  A     Action density spectrum (1-D).
  !> @param[in]  K     Wavenumber for entire spectrum.
  !> @param[in]  USTAR Friction velocity.
  !> @param[in]  USDIR Direction of USTAR.
  !> @param[out] S     Source term (1-D version).
  !> @param[out] D     Diagonal term of derivative.
  !>
  !> @author H. L. Tolman  @date 23-Dec-2004
  !>
  SUBROUTINE W3SIN1 (A, K, USTAR, USDIR, S, D)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           H. L. Tolman            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         23-Dec-2004 |
    !/                  +-----------------------------------+
    !/
    !/    05-Dec-1996 : Final FORTRAN 77                    ( version 1.18 )
    !/    08-Dec-1999 : Upgrade to FORTRAN 90               ( version 2.00 )
    !/    23-Dec-2004 : Multiple grid version.              ( version 3.06 )
    !/
    !  1. Purpose :
    !
    !     Calculate diagonal of input source (actual source term put
    !     together in W3SRCE).
    !
    !  2. Method :
    !
    !       WAM-3 : Snyder et al. (1981), Komen et al. (1984).
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       A       R.A.  I   Action density spectrum (1-D).
    !       K       R.A.  I   Wavenumber for entire spectrum.          *)
    !       USTAR   Real  I   Friction velocity.
    !       USDIR   Real  I   Direction of USTAR.
    !       S       R.A.  O   Source term (1-D version).
    !       D       R.A.  O   Diagonal term of derivative.             *)
    !     ----------------------------------------------------------------
    !                         *) Stored as 1-D array with dimension NTH*NK
    !
    !  4. Subroutines used :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      STRACE    Subr. W3SERVMD Subroutine tracing.
    !      PRT2DS    Subr. W3SRRYMD Print plot of spectrum.
    !      OUTMAT    Subr. W3SRRYMD Print out matrix.
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      W3SRCE    Subr. W3SRCEMD Source term integration.
    !      W3EXPO    Subr.   N/A    Point output post-processor.
    !      GXEXPO    Subr.   N/A    GrADS point output post-processor.
    !     ----------------------------------------------------------------
    !
    !  6. Error messages :
    !
    !  7. Remarks :
    !
    !  8. Structure :
    !
    !     See source code.
    !
    !  9. Switches :
    !
    !     !/S   Enable subroutine tracing.
    !     !/T   Enable general test output.
    !     !/T0  2-D print plot of source term.
    !     !/T1  Print arrays.
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
#ifdef W3_T
    USE CONSTANTS
#endif
    USE W3GDATMD, ONLY: NK, NTH, NSPEC, SIG, SIG2, ESIN, ECOS, SINC1
#ifdef W3_T
    USE W3ODATMD, ONLY: NDST
#endif
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
#ifdef W3_T0
    USE W3ARRYMD, ONLY: PRT2DS
#endif
#ifdef W3_T1
    USE W3ARRYMD, ONLY: OUTMAT
#endif
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    REAL, INTENT(IN)        :: A(NSPEC), K(NSPEC), USTAR, USDIR
    REAL, INTENT(OUT)       :: S(NSPEC), D(NSPEC)
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    INTEGER                 :: IS
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
#ifdef W3_T0
    INTEGER                 :: IK, ITH
#endif
    REAL                    :: COSU, SINU
#ifdef W3_T0
    REAL                    :: DOUT(NK,NTH)
#endif
    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'W3SIN1')
#endif
    !
#ifdef W3_T
    WRITE (NDST,9000) SINC1, USTAR, USDIR*RADE
#endif
    !
    ! 1.  Preparations
    !
    COSU   = COS(USDIR)
    SINU   = SIN(USDIR)
    !
    ! 2.  Diagonal
    !
    DO IS=1, NSPEC
      D(IS) = SINC1 * SIG2(IS) * MAX ( 0. ,                         &
           ( USTAR * (ECOS(IS)*COSU+ESIN(IS)*SINU)                  &
           * K(IS)/SIG2(IS) - 0.035714) )
    END DO
    !
    S = D * A
    !
    ! ... Test output of arrays
    !
#ifdef W3_T0
    DO IK=1, NK
      DO ITH=1, NTH
        DOUT(IK,ITH) = D(ITH+(IK-1)*NTH)
      END DO
    END DO
#endif
    !
#ifdef W3_T0
    CALL PRT2DS (NDST, NK, NK, NTH, DOUT, SIG(1:), '  ', 1.,    &
         0.0, 0.001, 'Diag Sin', ' ', 'NONAME')
#endif
    !
#ifdef W3_T1
    CALL OUTMAT (NDST, D, NTH, NTH, NK, 'diag Sin')
#endif
    !
    RETURN
    !
    ! Formats
    !
#ifdef W3_T
9000 FORMAT (' TEST W3SIN1 : COMMON FACT.: ',3E10.3)
#endif
    !/
    !/ End of W3SIN1 ----------------------------------------------------- /
    !/
  END SUBROUTINE W3SIN1
  !/ ------------------------------------------------------------------- /
  !>
  !> @brief Calculate whitecapping source term and diagonal term of derivative.
  !>
  !> @param[in]  A      Action density spectrum (1-D).
  !> @param[in]  K      Wavenumber for entire spectrum.
  !> @param[in]  EMEAN  Mean wave energy.
  !> @param[in]  FMEAN  Mean wave frequency.
  !> @param[in]  WNMEAN Mean wavenumber.
  !> @param[out] S      Source term (1-D version).
  !> @param[out] D      Diagonal term of derivative.
  !>
  !> @author H. L. Tolman  @date 23-Dec-2004
  !>
  SUBROUTINE W3SDS1 (A, K, EMEAN, FMEAN, WNMEAN, S, D)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           H. L. Tolman            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         23-Dec-2004 |
    !/                  +-----------------------------------+
    !/
    !/    05-Dec-1996 : Final FORTRAN 77                    ( version 1.18 )
    !/    08-Dec-1999 : Upgrade to FORTRAN 90               ( version 2.00 )
    !/    23-Dec-2004 : Multiple grid version.              ( version 3.06 )
    !/
    !  1. Purpose :
    !
    !     Calculate whitecapping source term and diagonal term of derivative.
    !
    !  2. Method :
    !
    !       WAM-3
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       A       R.A.  I   Action density spectrum (1-D).
    !       K       R.A.  I   Wavenumber for entire spectrum.          *)
    !       EMEAN   Real  I   Mean wave energy.
    !       FMEAN   Real  I   Mean wave frequency.
    !       WNMEAN  Real  I   Mean wavenumber.
    !       S       R.A.  O   Source term (1-D version).
    !       D       R.A.  O   Diagonal term of derivative.             *)
    !     ----------------------------------------------------------------
    !                         *) Stored in 1-D array with dimension NTH*NK
    !
    !  4. Subroutines used :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      STRACE    Subr. W3SERVMD Subroutine tracing.
    !      PRT2DS    Subr. W3SRRYMD Print plot of spectrum.
    !      OUTMAT    Subr. W3SRRYMD Print out matrix.
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      W3SRCE    Subr. W3SRCEMD Source term integration.
    !      W3EXPO    Subr.   N/A    Point output post-processor.
    !      GXEXPO    Subr.   N/A    GrADS point output post-processor.
    !     ----------------------------------------------------------------
    !
    !  6. Error messages :
    !
    !  7. Remarks :
    !
    !  8. Structure :
    !
    !     See source code.
    !
    !  9. Switches :
    !
    !     !/S   Enable subroutine tracing.
    !     !/T   Enable general test output.
    !     !/T0  2-D print plot of source term.
    !     !/T1  Print arrays.
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    USE W3GDATMD, ONLY: NK, NTH, NSPEC, SIG, SDSC1
#ifdef W3_T
    USE W3ODATMD, ONLY: NDST
#endif
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
#ifdef W3_T0
    USE W3ARRYMD, ONLY: PRT2DS
#endif
#ifdef W3_T1
    USE W3ARRYMD, ONLY: OUTMAT
#endif
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    REAL, INTENT(IN)        :: A(NSPEC), K(NSPEC),                  &
         EMEAN, FMEAN, WNMEAN
    REAL, INTENT(OUT)       :: S(NSPEC), D(NSPEC)
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    INTEGER                 :: IS
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
#ifdef W3_T0
    INTEGER                 :: IK, ITH
#endif
    REAL                    :: FACTOR
#ifdef W3_T0
    REAL                    :: DOUT(NK,NTH)
#endif
    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'W3SDS1')
#endif
    !
    ! 1.  Common factor
    !
    FACTOR = SDSC1 * FMEAN * WNMEAN**3 * EMEAN**2
    !
#ifdef W3_T
    WRITE (NDST,9000) SDSC1, FMEAN, WNMEAN, EMEAN, FACTOR
#endif
    !
    ! 3.  Source term
    !
    D = FACTOR * K
    S = D * A
    !
    ! ... Test output of arrays
    !
#ifdef W3_T0
    DO IK=1, NK
      DO ITH=1, NTH
        DOUT(IK,ITH) = D(ITH+(IK-1)*NTH)
      END DO
    END DO
#endif
    !
#ifdef W3_T0
    CALL PRT2DS (NDST, NK, NK, NTH, DOUT, SIG(1:), '  ', 1.,    &
         0.0, 0.001, 'Diag Sds', ' ', 'NONAME')
#endif
    !
#ifdef W3_T1
    CALL OUTMAT (NDST, D, NTH, NTH, NK, 'diag Sds')
#endif
    !
    RETURN
    !
    ! Formats
    !
#ifdef W3_T
9000 FORMAT (' TEST W3SDS1 : COMMON FACT.: ',5E10.3)
#endif
    !/
    !/ End of W3SDS1 ----------------------------------------------------- /
    !/
  END SUBROUTINE W3SDS1
  !/
  !/ End of module W3SRC1MD -------------------------------------------- /
  !/
END MODULE W3SRC1MD
