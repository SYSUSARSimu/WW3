#include "w3macros.h"
!/ ------------------------------------------------------------------- /
MODULE W3DISPMD
  !/
  !/                  +-----------------------------------+
  !/                  | WAVEWATCH III           NOAA/NCEP |
  !/                  |           H. L. Tolman            |
  !/                  |                        FORTRAN 90 |
  !/                  | Last update :         29-May-2009 |
  !/                  +-----------------------------------+
  !/
  !/    30-Nov-1999 : Fortran 90 version.                 ( version 2.00 )
  !/    29-May-2009 : Preparing distribution version.     ( version 3.14 )
  !/    10-Mar-2016 : Added Liu & Mollo-Christensen
  !/                  dispersion with ice (E. Rogers)     ( version 5.10 )
  !/
  !/    Copyright 2009 National Weather Service (NWS),
  !/       National Oceanic and Atmospheric Administration.  All rights
  !/       reserved.  WAVEWATCH III is a trademark of the NWS.
  !/       No unauthorized use without permission.
  !/
  !  1. Purpose :
  !
  !     A set of routines for solving the dispersion relation.
  !
  !  2. Variables and types :
  !
  !     All variables are retated to the interpolation tables. See
  !     DISTAB for a more comprehensive description.
  !
  !      Name      Type  Scope    Description
  !     ----------------------------------------------------------------
  !      NAR1D     I.P.  Public   Nmmer of elements in interpolation
  !                               array.
  !      DFAC      R.P.  Public   Value of KH at deep boundary.
  !      EWN1      R.A.  Public   Wavenumber array.
  !      ECG1      R.A.  Public   Group velocity array.
  !      N1MAX     Int.  Public   Actual maximum position in array.
  !      DSIE      Real  Public   SI step.
  !     ----------------------------------------------------------------
  !
  !  3. Subroutines and functions :
  !
  !      Name      Type  Scope    Description
  !     ----------------------------------------------------------------
  !      WAVNU1    Subr. Public   Solve dispersion using lookup table.
  !      WAVNU2    Subr. Public   Solve dispersion relation itteratively.
  !      DISTAB    Subr. Public   Fill interpolation tables.
  !      LIU_FORWARD_DISPERSION Subr. Public  Dispersion with ice
  !      LIU_REVERSE_DISPERSION Subr. Public  Dispersion with ice
  !     ----------------------------------------------------------------
  !
  !  4. Subroutines and functions used :
  !
  !      Name      Type  Module   Description
  !     ----------------------------------------------------------------
  !      STRACE    Subr. W3SERVMD Subroutine tracing            ( !/S )
  !     ----------------------------------------------------------------
  !
  !  5. Remarks :
  !
  !  6. Switches :
  !
  !       !/S   Enable subroutine tracing.
  !
  !  7. Source code :
  !
  !/ ------------------------------------------------------------------- /
  !/
  PUBLIC
  !/
  !/ Set up of public interpolation table ------------------------------ /
  !/
  INTEGER, PARAMETER      :: NAR1D  =  121
  REAL, PARAMETER         :: DFAC   =    6.
  !/
  INTEGER                 :: N1MAX
  REAL                    :: ECG1(0:NAR1D), EWN1(0:NAR1D), DSIE
  !/
  !/ Set up of public subroutines -------------------------------------- /
  !/
CONTAINS
  !/ ------------------------------------------------------------------- /
  SUBROUTINE WAVNU1 (SI,H,K,CG)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           H. L. Tolman            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         30-Nov-1999 |
    !/                  +-----------------------------------+
    !/
    !/    04-Nov-1990 : Final FORTRAN 77                    ( version 1.18 )
    !/    30-Nov-1999 : Upgrade to FORTRAN 90               ( version 2.00 )
    !/
    !  1. Purpose :
    !
    !     Calculate wavenumber and group velocity from the interpolation
    !     array filled by DISTAB from a given intrinsic frequency and the
    !     waterdepth.
    !
    !  2. Method :
    !
    !     Linear interpolation from one-dimensional array.
    !
    !  3. Parameters used :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       SI      Real   I   Intrinsic frequency (moving frame)  (rad/s)
    !       H       Real   I   Waterdepth                            (m)
    !       K       Real   O   Wavenumber                          (rad/m)
    !       CG      Real   O   Group velocity                       (m/s)
    !     ----------------------------------------------------------------
    !
    !  4. Error messages :
    !
    !     - None.
    !
    !  5. Called by :
    !
    !     - Any main program
    !
    !  6. Subroutines used :
    !
    !     - None
    !
    !  7. Remarks :
    !
    !     - Calculated si* is always made positive without checks : check in
    !       main program assumed !
    !     - Depth is unlimited.
    !
    !  8. Structure :
    !
    !     +---------------------------------------------+
    !     | calculate non-dimensional frequency         |
    !     |---------------------------------------------|
    !     | T            si* in range ?               F |
    !     |----------------------|----------------------|
    !     | calculate k* and cg* | deep water approx.   |
    !     | calculate output     |                      |
    !     |      parameters      |                      |
    !     +---------------------------------------------+
    !
    !  9. Switches :
    !
    !     !/S  Enable subroutine tracing.
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    !/
    USE CONSTANTS, ONLY : GRAV
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    REAL, INTENT(IN)        :: SI, H
    REAL, INTENT(OUT)       :: K, CG
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    INTEGER                 :: I1, I2
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    REAL                    :: SQRTH, SIX, R1, R2
    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'WAVNU1')
#endif
    !
    SQRTH  = SQRT(H)
    SIX    = SI * SQRTH
    I1     = INT(SIX/DSIE)
    !
    IF (I1.LE.N1MAX.AND.I1.GE.1) THEN
      I2 = I1 + 1
      R1 = SIX/DSIE - REAL(I1)
      R2 = 1. - R1
      K  = ( R2*EWN1(I1) + R1*EWN1(I2) ) / H
      CG = ( R2*ECG1(I1) + R1*ECG1(I2) ) * SQRTH
    ELSE
      K  = SI*SI/GRAV
      CG = 0.5 * GRAV / SI
    END IF
    !
    RETURN
    !/
    !/ End of WAVNU1 ----------------------------------------------------- /
    !/
  END SUBROUTINE WAVNU1
  !/ ------------------------------------------------------------------- /
  SUBROUTINE WAVNU2 (W,H,K,CG,EPS,NMAX,ICON)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           H. L. Tolman            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         30-Nov-1999 |
    !/                  +-----------------------------------+
    !/
    !/    17-Jul-1990 : Final FORTRAN 77                    ( version 1.18 )
    !/    30-Nov-1999 : Upgrade to FORTRAN 90               ( version 2.00 )
    !/
    !  1. Purpose :
    !
    !     Calculation of wavenumber K from a given angular
    !     frequency W and waterdepth H.
    !
    !  2. Method :
    !
    !     Used equation :
    !                        2
    !                       W  = G*K*TANH(K*H)
    !
    !     Because of the nature of the equation, K is calculated
    !     with an itterative procedure.
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       W       Real   I   Angular frequency
    !       H       Real   I   Waterdepth
    !       K       Real   O   Wavenumber ( same sign as W )
    !       CG      Real   O   Group velocity (same sign as W)
    !       EPS     Real   I   Wanted max. difference between K and Kold
    !       NMAX    Int.   I   Max number of repetitions in calculation
    !       ICON    Int.   O   Contol counter ( See error messages )
    !     ----------------------------------------------------------------
    !
    !  9. Switches :
    !
    !     !/S  Enable subroutine tracing.
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    !/
    USE CONSTANTS, ONLY : GRAV
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    INTEGER, INTENT(IN)     :: NMAX
    INTEGER, INTENT(OUT)    :: ICON
    REAL, INTENT(IN)        :: W, H, EPS
    REAL, INTENT(OUT)       :: CG, K
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    INTEGER                 :: I
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    REAL                    :: F, W0, FD, DIF, RDIF, KOLD
    !REAL                    :: KTEST1, CGTEST1, KTEST2, CGTEST2
    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'WAVNU2')
#endif
    !
    !     Initialisations :
    !
    !CALL WAVNU1(ABS(W),H,KTEST1,CGTEST1)
    !CALL WAVNU3(ABS(W),H,KTEST2,CGTEST2)

    CG   = 0
    KOLD = 0
    ICON = 0
    W0   = ABS(W)

    !
    !     1st approach :
    !
    IF (W0.LT.SQRT(GRAV/H)) THEN
      K = W0/SQRT(GRAV*H)
    ELSE
      K = W0*W0/GRAV
    END IF
    !
    !     Refinement :
    !
    DO I=1, NMAX
      DIF = ABS(K-KOLD)
      IF (K.NE.0) THEN
        RDIF = DIF/K
      ELSE
        RDIF = 0
      END IF
      IF (DIF .LT. EPS .AND. RDIF .LT. EPS) THEN
        ICON = 1
        GOTO 100
      ELSE
        KOLD = K
        F    = GRAV*KOLD*TANH(KOLD*H)-W0**2
        IF (KOLD*H.GT.25) THEN
          FD = GRAV*TANH(KOLD*H)
        ELSE
          FD = GRAV*TANH(KOLD*H) + GRAV*KOLD*H/((COSH(KOLD*H))**2)
        END IF
        K    = KOLD - F/FD
      END IF
    END DO
    !
    DIF   = ABS(K-KOLD)
    RDIF  = DIF/K
    IF (DIF .LT. EPS .AND. RDIF .LT. EPS) ICON = 1
100 CONTINUE
    IF (2*K*H.GT.25) THEN
      CG = W0/K * 0.5
    ELSE
      CG = W0/K * 0.5*(1+(2*K*H/SINH(2*K*H)))
    END IF
    IF (W.LT.0.0) THEN
      K  = (-1)*K
      CG = CG*(-1)
    END IF

    !WRITE(*,'(20F20.10)') W, H, (K-KTEST2)/K*100., (CG-CGTEST2)/CG*100.
    !
    RETURN
    !/
    !/ End of WAVNU2 ----------------------------------------------------- /
    !/
  END SUBROUTINE WAVNU2
  !/
  PURE SUBROUTINE WAVNU3 (SI,H,K,CG)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           Aron Roland             |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         20-05-17    |
    !/                  +-----------------------------------+
    !/
    !/    20.05.17 : Initial Version, Aron Roland based on WAVNU1
    !/
    !  1. Purpose :
    !
    !     Calculate wavenumber and group velocity from the improved
    !     Eckard's formula by Beji (2003)
    !
    !  2. Method :
    !
    !     Direct computation by approximation
    !
    !  3. Parameters used :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       SI      Real   I   Intrinsic frequency (moving frame)  (rad/s)
    !       H       Real   I   Waterdepth                            (m)
    !       K       Real   O   Wavenumber                          (rad/m)
    !       CG      Real   O   Group velocity                       (m/s)
    !     ----------------------------------------------------------------
    !
    !  4. Error messages :
    !
    !     - None.
    !
    !  5. Called by :
    !
    !     - Any main program
    !
    !  6. Subroutines used :
    !
    !     - None
    !
    !  7. Remarks :
    !
    !     - Calculated si* is always made positive without checks : check in
    !       main program assumed !
    !     - Depth is unlimited.
    !
    !  8. Structure :
    !
    !     +---------------------------------------------+
    !     | calculate non-dimensional frequency         |
    !     |---------------------------------------------|
    !     | T            si* in range ?               F |
    !     |----------------------|----------------------|
    !     | calculate k* and cg* | deep water approx.   |
    !     | calculate output     |                      |
    !     |      parameters      |                      |
    !     +---------------------------------------------+
    !
    !  9. Switches :
    !
    !     !/S  Enable subroutine tracing.
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    !/
    USE CONSTANTS, ONLY : GRAV, PI
    !!/S      USE W3SERVMD, ONLY: STRACE
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    REAL, INTENT(IN)        :: SI, H
    REAL, INTENT(OUT)       :: K, CG
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    INTEGER                 :: I1, I2
    !!/S      INTEGER, SAVE           :: IENT = 0
    REAL                    :: KH0, KH, TMP, TP, CP, L
    REAL, PARAMETER         :: BETA1 = 1.55
    REAL, PARAMETER         :: BETA2 = 1.3
    REAL, PARAMETER         :: BETA3 = 0.216
    REAL, PARAMETER         :: ZPI   = 2 * PI
    REAL, PARAMETER         :: KDMAX = 20.
    !/
    !/ ------------------------------------------------------------------- /
    !/
    ! IENT does not work with PURE subroutines
    !!/S      CALL STRACE (IENT, 'WAVNU1')
    !
    TP  = SI/ZPI
    KH0 = ZPI*ZPI*H/GRAV*TP*TP
    TMP = 1.55 + 1.3*KH0 + 0.216*KH0*KH0
    KH  = KH0 * (1 + KH0**1.09 * 1./EXP(MIN(KDMAX,TMP))) / SQRT(TANH(MIN(KDMAX,KH0)))
    K   = KH/H
    CG  = 0.5*(1+(2*KH/SINH(MIN(KDMAX,2*KH))))*SI/K
    !
    RETURN
    !/
    !/ End of WAVNU3 ----------------------------------------------------- /
    !/
  END SUBROUTINE WAVNU3

  PURE SUBROUTINE WAVNU_LOCAL (SIG,DW,WNL,CGL)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           Aron Roland             |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         20-05-17    |
    !/                  +-----------------------------------+
    !/
    !/    20.05.17 : Initial Version, Aron Roland based on WAVNU1
    !/
    !  1. Purpose :
    !
    !     Calculate wavenumber and group velocity from the improved
    !     Eckard's formula by Beji (2003)
    !
    !  2. Method :
    !
    !     Linear interpolation from one-dimensional array.
    !
    !  3. Parameters used :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       SI      Real   I   Intrinsic frequency (moving frame)  (rad/s)
    !       H       Real   I   Waterdepth                            (m)
    !       K       Real   O   Wavenumber                          (rad/m)
    !       CG      Real   O   Group velocity                       (m/s)
    !     ----------------------------------------------------------------
    !
    !  4. Error messages :
    !
    !     - None.
    !
    !  5. Called by :
    !
    !     - Any main program
    !
    !  6. Subroutines used :
    !
    !     - None
    !
    !  7. Remarks :
    !
    !     - Calculated si* is always made positive without checks : check in
    !       main program assumed !
    !     - Depth is unlimited.
    !
    !  8. Structure :
    !
    !     +---------------------------------------------+
    !     | calculate non-dimensional frequency         |
    !     |---------------------------------------------|
    !     | T            si* in range ?               F |
    !     |----------------------|----------------------|
    !     | calculate k* and cg* | deep water approx.   |
    !     | calculate output     |                      |
    !     |      parameters      |                      |
    !     +---------------------------------------------+
    !
    !  9. Switches :
    !
    !     !/S  Enable subroutine tracing.
    !
    ! 10. Source code :

    USE W3GDATMD, ONLY: DMIN
    !
    !/ ------------------------------------------------------------------- /
    !/
    IMPLICIT NONE

    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    REAL, INTENT(IN)        :: SIG, DW
    REAL, INTENT(OUT)       :: WNL, CGL
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    REAL                    :: DEPTH
    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'WAVNU2')
#endif
    !
    !/
    !/ End of WAVNU_LOCAL------------------------------------------------- /
    !/

    DEPTH  = MAX ( DMIN , DW)
    !
    CALL WAVNU3(SIG,DEPTH,WNL,CGL)

  END SUBROUTINE WAVNU_LOCAL
  !/
  !/ ------------------------------------------------------------------- /

  !/ ------------------------------------------------------------------- /
  SUBROUTINE DISTAB
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           H. L. Tolman            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         30-Nov-1990 |
    !/                  +-----------------------------------+
    !/
    !/    04-Nov-1990 : Final FORTRAN 77                    ( version 1.18 )
    !/    30-Nov-1999 : Upgrade to FORTRAN 90               ( version 2.00 )
    !/
    !  1. Purpose :
    !
    !     Fill interpolation arrays for the calculation of wave parameters
    !     according to the linear (Airy) wave theory given the intrinsic
    !     frequency.
    !
    !  2. Method :
    !
    !     For a given set of non-dimensional frequencies the interpolation
    !     arrays with non-dimensional depths and group velocity are filled.
    !     The following non-dimensional parameters are used :
    !
    !       frequency   f*SQRT(h/g) = f*
    !       depth       kh          = k*
    !       group vel.  c/SQRT(gh)  = c*
    !
    !     Where k is the wavenumber, h the depth f the intrinsic frequency,
    !     g the acceleration of gravity and c the group velocity.
    !
    !  3. Parameters :
    !
    !     See module documentation.
    !
    !  4. Error messages :
    !
    !     - None.
    !
    !  5. Called by :
    !
    !     - W3GRID
    !     - Any main program.
    !
    !  6. Subroutines used :
    !
    !     - WAVNU2 (solve dispersion relation)
    !
    !  7. Remarks :
    !
    !     - In the filling of the arrays H = 1. is assumed and the factor
    !       SQRT (g) is moved from the interpolation to the filling
    !       procedure thus :
    !
    !         k* = k
    !
    !         c* = cg/SQRT(g)
    !
    !  8. Structure
    !
    !     -----------------------------------
    !       include common block
    !       calculate parameters
    !       fill zero-th position of arrays
    !       fill middle positions of arrays
    !       fill last positions of arrays
    !     -----------------------------------
    !
    !  9. Switches :
    !
    !       !/S   Enable subroutine tracing.
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    !/
    USE CONSTANTS, ONLY : GRAV
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    INTEGER                 :: I, ICON
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    REAL                    :: DEPTH, CG, SIMAX, SI, K
    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'DISTAB')
#endif
    !
    ! Calculate parameters ----------------------------------------------- *
    !
    N1MAX  = NAR1D - 1
    DEPTH  = 1.
    SIMAX  = SQRT (GRAV * DFAC)
    DSIE   = SIMAX / REAL(N1MAX)
    !
    ! Fill zero-th position of arrays ------------------------------------ *
    !
    EWN1(0) = 0.
    ECG1(0) = SQRT(GRAV)
    !
    ! Fill middle positions of arrays ------------------------------------ *
    !
    DO I=1, N1MAX
      SI = REAL(I)*DSIE
      CALL WAVNU2 (SI,DEPTH,K,CG,1E-7,15,ICON)
      EWN1(I) = K
      ECG1(I) = CG
    END DO
    !
    ! Fill last positions of arrays -------------------------------------- *
    !
    I      = N1MAX+1
    SI     = REAL(I)*DSIE
    CALL WAVNU2 (SI,DEPTH,K,CG,1E-7,15,ICON)
    EWN1(I) = K
    ECG1(I) = CG
    !
    RETURN
    !/
    !/ End of DISTAB ----------------------------------------------------- /
    !/
  END SUBROUTINE DISTAB

  !/ ------------------------------------------------------------------- /
  !/
  SUBROUTINE LIU_FORWARD_DISPERSION (H_ICE,VISC,H_WDEPTH,SIGMA &
       ,K_SOLUTION,CG,ALPHA)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |        W. E. Rogers (NRL-SSC)     |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         11-Oct-2013 |
    !/                  +-----------------------------------+
    !/
    !/    16-Oct-2012 : Origination.                        ( version 4.04 )
    !/                                                        (E. Rogers)
    !/
    !  1. Purpose :
    !
    !     Dispersion relation calculation: given frequency, find k
    !     This is for dispersion in ice, so it requires the ice thickness
    !     and viscosity also. (the latter is the "eddy viscosity in the
    !     turbulent boundary layer beneath the ice.").
    !     Please note that this is for a continuous ice cover (not broken in floes)
    !
    !     This subroutine also calculates Cg and alpha.
    !     alpha is the exponential decay rate of *energy* (not to be
    !     confused with k_i which is the exponential decay rate of
    !     amplitude)
    !
    !     Both alpha and k_i are for spatial decay rate, units (1/m)
    !     Neither is for temporal decay rate.
    !
    !     References:
    !     N/A here, but see subroutine "Liu_reverse_dispersion"
    !
    !  2. Method :
    !
    !     Newton-Raphson.
    !     For actual dispersion relation, see documentation of subroutine
    !     "Liu_reverse_dispersion"
    !
    !  3. Parameters :
    !
    !      Parameter list
    !     ----------------------------------------------------------------
    !      H_ICE      Real    I  Ice thickness
    !      VISC       Real    I  Eddy viscosity (m2/sec)
    !      H_WDEPTH   Real    I  Water depth
    !      SIGMA      R.A.    I  Radian Wave frequency
    !      K_SOLUTION R.A.    O  Wave number
    !      CG         R.A.    O  Group velocity
    !      ALPHA      R.A.    O  Exponential decay rate of energy
    !      NK         Int.    I  Number of frequencies
    !     ----------------------------------------------------------------
    !
    !  4. Subroutines used :
    !
    !      Name                   | Type |  Module | Description
    !     ----------------------------------------------------------------
    !      Liu_reverse_dispersion | Subr.| W3SIC2MD| As name implies.
    !      STRACE                 | Subr.| W3SERVMD| Subroutine tracing.
    !      WAVNU1                 | Subr.| W3DISPMD| Wavenumber for waves
    !                                                in open water.
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !      Name                   | Type |  Module | Description
    !     ----------------------------------------------------------------
    !      W3SIC2                 | Subr.| W3SIC2MD| S_ice source term
    !     ----------------------------------------------------------------
    !
    !  6. Error messages :
    !
    !     Fails if solution is not found in a given number of iterations
    !
    !  7. Remarks :
    !
    !     Eventually, k and Cg should be used for propagation. This is not
    !     implemented yet. For now, it is only used to calculate the source
    !     term.
    !
    !     For discussion of the eddy viscosity term, see documentation of
    !     subroutine "Liu_reverse_dispersion"
    !
    !     This subroutine expects eddy viscosity in units of m2/sec even
    !     though values are given in units of cm2/sec in the Liu paper.
    !
    !  8. Structure :
    !
    !     See source code.
    !
    !  9. Switches :
    !
    !     !/S   Enable subroutine tracing.
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    USE CONSTANTS, ONLY: TPI
    USE W3ODATMD,  ONLY: NDSE
    USE W3SERVMD,  ONLY: EXTCDE
    USE W3GDATMD, ONLY: NK, IICEHDISP, IICEDDISP, IICEFDISP, IICEHMIN
    ! USE W3DISPMD,  ONLY: WAVNU1
#ifdef W3_S
    USE W3SERVMD,  ONLY: STRACE
#endif
    !/
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list

    REAL   , INTENT(IN)  :: H_ICE, H_WDEPTH, SIGMA(NK)
    REAL   , INTENT(IN)  :: VISC    ! in m2/sec
    REAL   , INTENT(OUT) :: K_SOLUTION(NK) ,CG(NK) ,ALPHA(NK)

    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
#ifdef W3_S
    INTEGER, SAVE     :: IENT = 0
#endif
    INTEGER            :: IK
    REAL, PARAMETER    :: FERRORMAX=1.0E-5  ! maximum acceptable error
    INTEGER, PARAMETER :: N_ITER=20  ! number of iterations prior to
    ! failure
    LOGICAL            :: GET_CG     ! indicates whether to get Cg
    ! and alpha
    ! from "Liu_reverse_dispersion"
    REAL :: FREQ(20)    ! wave frequency at current
    ! iteration
    REAL  :: KWN(20)     ! wavenumber at current
    ! iteration
    INTEGER            :: ITER       ! iteration number
    REAL               :: DK,DF,DFDK ! as name implies
    REAL               :: FDUMMY     ! as name implies
    !REAL               :: SIGMA      ! 2*pi/T
    REAL               :: K_OPEN     ! open-water value of k
    REAL               :: CG_OPEN    ! open-water value of Cg
    REAL               :: FWANTED    ! Freq. corresponding to sigma
    REAL               :: FERROR     ! Max acceptable error after test to avoid crash

    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'LIU_FORWARD_DISPERSION')
#endif
    !
    !/ 0) --- Initialize/allocate variables ------------------------------ /




    DO IK = 1, NK

      GET_CG  = .FALSE.
      !/T38      WRITE(*,*)'FORWARD IN: H_ICE,VISC,H_WDEPTH,FWANTED = ', &
      !/T38                          H_ICE,VISC,H_WDEPTH,FWANTED
      FWANTED=SIGMA(IK)/TPI
      ! First guess for k :

      CALL WAVNU1(SIGMA(IK),H_WDEPTH,K_OPEN,CG_OPEN)
      !     KWN(1)  = 0.2 ! (old method)
      KWN(1)  =K_OPEN ! new method, Mar 10 2014
      !
      !/ 1) ----- Iteration loop to find k --------------------------------- /
      ITER = 0
      DF   = 999.

      IF ( (H_ICE.LT.IICEHDISP).OR.(H_WDEPTH.LT.IICEDDISP) ) THEN
        FERROR=IICEFDISP*FERRORMAX
      ELSE
        FERROR=FERRORMAX
      ENDIF

      DO WHILE ( ABS(DF).GE.FERROR .AND. ITER.LE.N_ITER )
        ITER = ITER + 1
        ! compute freq for this iteration
        CALL LIU_REVERSE_DISPERSION(H_ICE,VISC,H_WDEPTH,KWN(ITER), &
             GET_CG,FREQ(ITER),CG(IK),ALPHA(IK))

        ! calculate dk
        IF (ITER == 1)THEN
          ! We do not have slope yet, so pick a number...
          DK = 0.01
        ELSEIF (ITER.EQ.N_ITER+1) THEN
          WRITE(NDSE,800) N_ITER
          CALL EXTCDE(2)
        ELSE
          ! use slope
          DFDK = (FREQ(ITER)-FREQ(ITER-1)) / (KWN(ITER)-KWN(ITER-1))
          DF   = FWANTED - FREQ(ITER)
          !/T38       WRITE(*,*)'ITER = ',ITER,' ;  K = ',KWN(ITER),' ; F = ', &
          !/T38                  FREQ(ITER),' ; DF = ',DF
          DK   = DF / DFDK
        ENDIF

        ! Decide on next k to try
        KWN(ITER+1) = KWN(ITER) + DK
        ! If we end up with a negative k for the next iteration, don't
        !   allow this.
        IF(KWN(ITER+1) < 0.0)THEN
          KWN(ITER+1) = TPI / 1000.0
        ENDIF

      END DO

      !/ 2) -------- Finish up. -------------------------------------------- /
      !     Success, so return K_SOLUTION, and call LIU_REVERSE_DISPERSION one
      !     last time, to get CG and ALPHA

      K_SOLUTION(IK) = KWN(ITER)

      GET_CG     = .TRUE.
      CALL LIU_REVERSE_DISPERSION(H_ICE,VISC,H_WDEPTH,K_SOLUTION(IK), &
           GET_CG,FDUMMY,CG(IK),ALPHA(IK))
    END DO
    !
#ifdef W3_T38
    WRITE(*,*)'FORWARD OUT: K_SOLUTION,CG,ALPHA = ', &
         K_SOLUTION,CG,ALPHA
    IF (H_ICE==1.0)THEN
      WRITE(*,*)FWANTED,ALPHA
    ENDIF
#endif
    !
800 FORMAT (/' *** WAVEWATCH III ERROR IN '           &
         'W3SIC2_LIU_FORWARD_DISPERSION : ' /     &
         '     NO SOLUTION FOUND AFTER ',I4,' ITERATIONS.')
    !/
    !/ End of LIU_FORWARD_DISPERSION ------------------------------------- /
    !/
  END SUBROUTINE LIU_FORWARD_DISPERSION
  !/ ------------------------------------------------------------------- /
  !/
  SUBROUTINE LIU_REVERSE_DISPERSION (H_ICE,VISC,H_WDEPTH,KWN &
       ,GET_CG,FREQ,CG,ALPHA)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |        W. E. Rogers (NRL-SSC)     |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         11-Oct-2013 |
    !/                  +-----------------------------------+
    !/
    !/    12-Oct-2012 : Origination.                        ( version 4.04 )
    !/                                                        (E. Rogers)
    !/
    !  1. Purpose :
    !
    !     Dispersion relation calculation: given k, find frequency.
    !     This is for dispersion in ice, so it requires the ice thickness
    !     and viscosity also. (the latter is the "eddy viscosity in the
    !     turbulent boundary layer beneath the ice.").
    !
    !     This subroutine also (optionally) calculates Cg and alpha.
    !     alpha is the exponential decay rate of *energy* (not to be
    !     confused with k_i which is the exponential decay rate of
    !     amplitude)
    !
    !     Both alpha and k_i are for spatial decay rate, units (1/m)
    !     Neither is for temporal decay rate.

    !     This calculation is optional for reasons of computational
    !      efficiency (don't calculate if it will not be used). Note that
    !      if Cg and alpha are not calculated, the value of input viscosity
    !      is irrelevant.
    !
    !     References:
    !       Liu et al.    1991: JGR 96 (C3), 4605-4621
    !       Liu and Mollo 1988: JPO 18       1720-1712
    !
    !  2. Method :
    !
    !     In 1991 paper, see equations on page 4606. The key equations are:
    !     sigma2=(grav*k+B*k^5)/((coth(k*H_wdepth))+k*M);
    !     Cg=(grav+(5+4*k*M)*(B*k^4))/((2*sigma)*((1+k*M)^2));
    !     alpha=(sqrt(visc)*k*sqrt(sigma))/(Cg*sqrt(2)*(1+k*M));
    !
    !  3. Parameters :
    !
    !      Parameter list
    !     ----------------------------------------------------------------
    !      H_ICE     REAL    I  Ice thickness
    !      VISC      REAL    I  Eddy viscosity (if GET_CG) (m2/sec)
    !      H_WDEPTH  REAL    I  Water depth
    !      KWN       REAL    I  Wavenumber
    !      GET_CG    LOGICAL I  Indicates whether to calculate Cg and alpha
    !      FREQ      REAL    O  Frequency
    !      CG        REAL    O  Group velocity (if GET_CG)
    !      ALPHA     REAL    O  Exponential decay rate of energy (if GET_CG)
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
    !      Name                  | Type |  Module | Description
    !     ----------------------------------------------------------------
    !      Liu_forward_dispersion| Subr.| W3SIC2MD| As name implies.
    !     ----------------------------------------------------------------
    !
    !  6. Error messages :
    !
    !       None.
    !
    !  7. Remarks :
    !
    !     Eventually, k and Cg should be used for propagation. This is not
    !     implemented yet. For now, it is only used to calculate the source
    !     term.
    !
    !     The eddy viscosity term given by Liu is unfortunately highly
    !     variable, and "not a physical parameter", which suggests that it
    !     is difficult to specify in practice. In this paper, we see values
    !     of:
    !     nu= 160.0e-4 m2/sec (Brennecke (1921)
    !     nu=  24.0e-4 m2/sec (Hunkins 1966)
    !     nu=3450.0e-4 m2/sec (Fig 11)
    !     nu=   4.0e-4 m2/sec (Fig 12)
    !     nu= 150.0e-4 m2/sec (Fig 13)
    !     nu=  54.0e-4 m2/sec (Fig 14)
    !     nu= 384.0e-4 m2/sec (Fig 15)
    !     nu=1536.0e-4 m2/sec (Fig 16)
    !
    !     The paper states: "The only tuning parameter is the turbulent eddy
    !     viscosity, and it is a function of the flow conditions in the
    !     turbulent boundary layer which are determined by the ice
    !     thickness, floe sizes, ice concentration, and wavelength."
    !
    !     Another criticism of this source term is that it does not use the
    !     ice concentration in actual calculations. The method appears to
    !     simply rely on concentration being high, "When the ice is highly
    !     compact with high concentration, the flexural waves obey the
    !     dispersion relation (1) as similar waves in a continuous ice
    !     sheet." Later, "Five of these  cases with high ice conentration
    !     (larger than 60%) in the MIZ have been selected"
    !
    !     This subroutine expects eddy viscosity in units of m2/sec even
    !     though values are given in units of cm2/sec in the Liu paper.
    !
    !     Cg used here is correct only for deep water. It is taken from
    !     Liu et al. (1991) equation 2. If we want to calculate for finite
    !     depths accurately, we need to use d_sigma/d_k. However, be warned
    !     that this calculation is sensitive to numerical error and so the
    !     (potentially too coarse) computational grid for sigma and k should
    !     *not* be used.
    !
    !  8. Structure :
    !
    !     See source code.
    !
    !  9. Switches :
    !
    !     !/S   Enable subroutine tracing.
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    USE CONSTANTS, ONLY: DWAT, TPI, GRAV
    USE W3GDATMD, ONLY: NK
#ifdef W3_S
    USE W3SERVMD,  ONLY: STRACE
#endif
    !/
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    REAL   , INTENT(IN)  :: H_ICE,H_WDEPTH,KWN
    REAL   , INTENT(IN)  :: VISC    ! in m2/sec
    LOGICAL, INTENT(IN)  :: GET_CG
    REAL   , INTENT(OUT) :: FREQ,CG,ALPHA
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
#ifdef W3_S
    INTEGER, SAVE     :: IENT = 0
#endif
    REAL, PARAMETER   :: E = 6.0E+9 ! Young's modulus of elasticity
    REAL, PARAMETER   :: S = 0.3    ! "s", Poisson's ratio
    REAL              :: DICE       ! "dice", density of ice
    REAL              :: B          ! quantifies effect of bending
    ! of ice
    REAL              :: M          ! quantifies effect of inertia
    ! of ice
    REAL              :: COTHTERM   ! temporary variable
    REAL              :: SIGMA      ! 2*pi/T
    REAL              :: KH         ! k*h
    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'LIU_REVERSE_DISPERSION')
#endif
    !
    !/ 0) --- Initialize essential parameters ---------------------------- /
    CG    = 0.
    ALPHA = 0.
    FREQ  = 0.
    DICE = DWAT * 0.9 ! from Liu 1991 pg 4606

#ifdef W3_T38
    WRITE(*,*)'REVERSE IN: H_ICE,VISC,H_WDEPTH,KWN,GET_CG = ', &
         H_ICE,VISC,H_WDEPTH,KWN,GET_CG
#endif

    !
    !/ 1) --- Calculate frequency ---------------------------------------- /

    ! Note: Liu et al 1991 have "kwn*h_ice" in COTH(_) but I believe they
    ! meant to write "kwn*H_wdepth"

    B  = (E * H_ICE**3) / (12. * (1. - S**2) * DWAT)
    M  = DICE * H_ICE / DWAT
    KH = KWN * H_WDEPTH
    IF ( KH>5.0 ) THEN
      COTHTERM = 1.0
    ELSEIF ( KH<1.0E-4 ) THEN
      COTHTERM = 1.0 / KH
    ELSE
      COTHTERM = COSH(KH) / SINH(KH)
    ENDIF
    SIGMA = SQRT((GRAV * KWN + B * KWN**5) / (COTHTERM + KWN * M))
    FREQ  = SIGMA/(TPI)

    !/ 2) --- Calculate Cg and alpha if requested ------------------------ /
    !     Note: Cg is correct only for deep water
    IF (GET_CG) THEN
      CG    = (GRAV + (5.0+4.0 * KWN * M) * (B * KWN**4)) &
           / (2.0 * SIGMA * ((1.0 + KWN * M)**2))
      ALPHA = (SQRT(VISC) * KWN * SQRT(SIGMA)) &
           / (CG * SQRT(2.0) * (1 + KWN * M))
    ENDIF

#ifdef W3_T38
    WRITE(*,*)'REVERSE OUT: FREQ,CG,ALPHA = ',FREQ,CG,ALPHA
#endif

    !/
    !/ End of LIU_REVERSE_DISPERSION ------------------------------------- /
    !/
  END SUBROUTINE LIU_REVERSE_DISPERSION
  !/ ------------------------------------------------------------------- /
  !/
  !/ End of module W3DISPMD -------------------------------------------- /
  !/
END MODULE W3DISPMD
