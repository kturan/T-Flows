!==============================================================================!
  subroutine Prec_Solve(a, x, b, prec) 
!------------------------------------------------------------------------------!
! Solves the preconditioning system [d]{x}={b}                                 !
!------------------------------------------------------------------------------!
!   Allows preconditioning of the system by:                                   !
!     1. Diagonal preconditioning                                              !
!     2. Incomplete Cholesky preconditioning                                   !
!                                                                              !
!   The type of precondtioning is chosen by setting the variable prec to 0     !
!   (for no preconditioning), 1 (for diagonal preconditioning) or 2 (for       !
!   incomplete Cholesky preconditioning)                                       !
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use Const_Mod
  use Comm_Mod
  use Matrix_Mod
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Matrix_Type) :: a
  real              :: x(-a % pnt_grid % n_bnd_cells : a % pnt_grid % n_cells)
  real              :: b( a % pnt_grid % n_cells)
  character(len=80) :: prec  ! preconditioner
!-----------------------------------[Locals]-----------------------------------!
  integer :: i, j, k, n
  real    :: sum1
!==============================================================================!

  n  = a % pnt_grid % n_cells - a % pnt_grid % comm % n_buff_cells

  !---------------------------------!
  !   1) diagonal preconditioning   !
  !---------------------------------!
  if(prec .eq. 'DIAGONAL') then
    do i=1,n
      x(i) = b(i)/d % val(d % dia(i))
    end do

  !--------------------------------------------!
  !   2) incomplete cholesky preconditioning   !
  !--------------------------------------------!
  else if(prec .eq. 'INCOMPLETE_CHOLESKY') then

    ! Forward substitutionn
    do i = 1, n
      sum1 = b(i)
      do j = a % row(i),a % dia(i)-1     ! only the lower triangular
        k = a % col(j)
        sum1 = sum1 - a % val(j)*x(k)
      end do
      x(i) = sum1 * d % val(d % dia(i))  ! BUG ?
    end do

    do i = 1, n
      x(i) = x(i) / ( d % val(d % dia(i)) + TINY )
    end do

    ! Backward substitution
    do i = n, 1, -1
      sum1 = x(i)
      do j = a % dia(i)+1, a % row(i+1)-1        ! upper triangular 
        k = a % col(j)
        if(k <= n) sum1 = sum1 - a % val(j)*x(k)  ! avoid buffer entries
      end do
      x(i) = sum1* d % val(d % dia(i))           ! BUG ?
    end do

  !---------------------------!
  !   .) no preconditioning   !
  !---------------------------!
  else
    do i = 1, n
      x(i) = b(i)
    end do
  end if

  end subroutine
