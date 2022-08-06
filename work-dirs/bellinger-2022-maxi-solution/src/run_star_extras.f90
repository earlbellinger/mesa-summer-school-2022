! *****************************************************
!
!   run_star_extras file for Astero Across the HRD Labs
!
! *****************************************************

      module run_star_extras

      use star_lib
      use star_def
      use const_def
      use math_lib

  ! >>> Insert additional use statements below

      use gyre_lib

      implicit none

  ! >>> Insert module variables below

      real(dp), allocatable, save :: frequencies(:,:)
      real(dp), allocatable, save :: inertias(:)
      integer, allocatable, save :: n_gs(:)

      ! Radial displacement eigenfunctions 

      real(dp), allocatable, save :: xi_r_radial(:)
      real(dp), allocatable, save :: xi_r_dipole(:)

      logical, save :: gyre_has_run

      ! these routines are called by the standard run_star check_model
      contains

      subroutine extras_controls(id, ierr)
         integer, intent(in) :: id
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

         ! this is the place to set any procedure pointers you want to change
         ! e.g., other_wind, other_mixing, other_energy  (see star_data.inc)

         ! the extras functions in this file will not be called
         ! unless you set their function pointers as done below.
         ! otherwise we use a null_ version which does nothing (except warn).

         s% extras_startup => extras_startup
         s% extras_start_step => extras_start_step
         s% extras_check_model => extras_check_model
         s% extras_finish_step => extras_finish_step
         s% extras_after_evolve => extras_after_evolve
         s% how_many_extra_history_columns => how_many_extra_history_columns
         s% data_for_extra_history_columns => data_for_extra_history_columns
         s% how_many_extra_profile_columns => how_many_extra_profile_columns
         s% data_for_extra_profile_columns => data_for_extra_profile_columns  

         s% how_many_extra_history_header_items => how_many_extra_history_header_items
         s% data_for_extra_history_header_items => data_for_extra_history_header_items
         s% how_many_extra_profile_header_items => how_many_extra_profile_header_items
         s% data_for_extra_profile_header_items => data_for_extra_profile_header_items

      end subroutine extras_controls

  !****

      subroutine extras_startup(id, restart, ierr)
         integer, intent(in) :: id
         logical, intent(in) :: restart
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

  ! >>> Insert additional code below

         ! Initialize GYRE

         call gyre_init('gyre.in')

         ! Set constants

         call gyre_set_constant('G_GRAVITY', standard_cgrav)
         call gyre_set_constant('C_LIGHT', clight)
         call gyre_set_constant('A_RADIATION', crad)

         call gyre_set_constant('M_SUN', Msun)
         call gyre_set_constant('R_SUN', Rsun)
         call gyre_set_constant('L_SUN', Lsun)

         call gyre_set_constant('GYRE_DIR', TRIM(mesa_dir)//'/gyre/gyre')

  ! >>> Insert allocation code below

         allocate(inertias(50))
         allocate(frequencies(2,50))
         allocate(n_gs(50))

      end subroutine extras_startup

  !****

      integer function extras_start_step(id)
         integer, intent(in) :: id
         integer :: ierr
         integer :: k
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

  ! >>> Insert additional code below

         gyre_has_run = .false.

         do k = 1, 50
            frequencies(1,k) = 0
            frequencies(2,k) = 0
            inertias(k) = 0
            n_gs(k) = 0
         end do

         extras_start_step = 0
      end function extras_start_step

  !****

      ! returns either keep_going, retry, or terminate.
      integer function extras_check_model(id)
         integer, intent(in) :: id
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         extras_check_model = keep_going         
         if (.false. .and. s% star_mass_h1 < 0.35d0) then
            ! stop when star hydrogen mass drops to specified level
            extras_check_model = terminate
            write(*, *) 'have reached desired hydrogen mass'
            return
         end if

  ! >>> Insert additional code below

         if (s%x_logical_ctrl(1)) then
             call run_gyre(id, ierr)
         endif

         ! if you want to check multiple conditions, it can be useful
         ! to set a different termination code depending on which
         ! condition was triggered.  MESA provides 9 customizeable
         ! termination codes, named t_xtra1 .. t_xtra9.  You can
         ! customize the messages that will be printed upon exit by
         ! setting the corresponding termination_code_str value.
         ! termination_code_str(t_xtra1) = 'my termination condition'

         ! by default, indicate where (in the code) MESA terminated
         if (extras_check_model == terminate) s% termination_code = t_extras_check_model
      end function extras_check_model

  !****

      integer function how_many_extra_history_columns(id)
         integer, intent(in) :: id
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

  ! >>> Change number of history columns below

         how_many_extra_history_columns = 100
      end function how_many_extra_history_columns

  !****

      subroutine data_for_extra_history_columns(id, n, names, vals, ierr)
         integer, intent(in) :: id, n
         character (len=maxlen_history_column_name) :: names(n)
         real(dp) :: vals(n)
         integer :: k
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

  ! >>> Insert code to set history column names/values below

         do k = 1, 50
            write (names(k),    '(A,I0)') 'nu_radial_', k 
            write (names(k+50), '(A,I0)') 'nu_dipole_', k 
         end do

         if (s%x_logical_ctrl(1)) then

            ! save the frequencies of the radial and dipole modes 
            do k = 1, 50
                vals(k)    = frequencies(1, k)
                vals(k+50) = frequencies(2, k)
            end do

         else

            ! write out zeros for the 2*50 columns 
            do k = 1, 100
                vals(k) = 0
            end do

         endif

         ! note: do NOT add the extras names to history_columns.list
         ! the history_columns.list is only for the built-in history column options.
         ! it must not include the new column names you are adding here.

      end subroutine data_for_extra_history_columns

  !****

      integer function how_many_extra_profile_columns(id)
         integer, intent(in) :: id
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

  ! >>> Change number of profile columns below

         how_many_extra_profile_columns = 2
      end function how_many_extra_profile_columns

  !****

      subroutine data_for_extra_profile_columns(id, n, nz, names, vals, ierr)
         integer, intent(in) :: id, n, nz
         character (len=maxlen_profile_column_name) :: names(n)
         real(dp) :: vals(nz,n)
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         integer :: k
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

         ! note: do NOT add the extra names to profile_columns.list
         ! the profile_columns.list is only for the built-in profile column options.
         ! it must not include the new column names you are adding here.

         ! here is an example for adding a profile column
         !if (n /= 1) stop 'data_for_extra_profile_columns'
         !names(1) = 'beta'
         !do k = 1, nz
         !   vals(k,1) = s% Pgas(k)/s% P(k)
         !end do

  ! >>> Insert code to set profile column names/values below

         names(1) = 'xi_r_radial'
         names(2) = 'xi_r_dipole'

         if (s%x_logical_ctrl(1)) then

            if (.NOT. gyre_has_run) then
               write(*,*) 'calling run_gyre'
                call run_gyre(id, ierr)
            endif

            vals(:,1) = xi_r_radial
            vals(:,2) = xi_r_dipole

          else

            vals(:,1) = 0.
            vals(:,2) = 0.

         endif

      end subroutine data_for_extra_profile_columns


      integer function how_many_extra_history_header_items(id)
         integer, intent(in) :: id
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         how_many_extra_history_header_items = 0
      end function how_many_extra_history_header_items


      subroutine data_for_extra_history_header_items(id, n, names, vals, ierr)
         integer, intent(in) :: id, n
         character (len=maxlen_history_column_name) :: names(n)
         real(dp) :: vals(n)
         type(star_info), pointer :: s
         integer, intent(out) :: ierr
         ierr = 0
         call star_ptr(id,s,ierr)
         if(ierr/=0) return

         ! here is an example for adding an extra history header item
         ! also set how_many_extra_history_header_items
         ! names(1) = 'mixing_length_alpha'
         ! vals(1) = s% mixing_length_alpha

      end subroutine data_for_extra_history_header_items


      integer function how_many_extra_profile_header_items(id)
         integer, intent(in) :: id
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         how_many_extra_profile_header_items = 0
      end function how_many_extra_profile_header_items


      subroutine data_for_extra_profile_header_items(id, n, names, vals, ierr)
         integer, intent(in) :: id, n
         character (len=maxlen_profile_column_name) :: names(n)
         real(dp) :: vals(n)
         type(star_info), pointer :: s
         integer, intent(out) :: ierr
         ierr = 0
         call star_ptr(id,s,ierr)
         if(ierr/=0) return

         ! here is an example for adding an extra profile header item
         ! also set how_many_extra_profile_header_items
         ! names(1) = 'mixing_length_alpha'
         ! vals(1) = s% mixing_length_alpha

      end subroutine data_for_extra_profile_header_items

  !****

      ! returns either keep_going or terminate.
      ! note: cannot request retry; extras_check_model can do that.
      integer function extras_finish_step(id)
         integer, intent(in) :: id
         integer :: ierr

  ! >>> Declare additional variables below 

         integer :: k, best_k
         real(dp) :: best_freq

         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         extras_finish_step = keep_going

  ! >>> Insert additional code below

         if (s%x_logical_ctrl(1)) then

            if (.NOT. gyre_has_run) then
               write(*,*) 'calling run_gyre'
                call run_gyre(id, ierr)
            endif

            ! find the dipole mode closest to nu_max 
            ! since we have normalized by nu_max, this should be the mode closest to 0
            best_k = 1
            best_freq = 1d99
            do k = 1, 50
               if (frequencies(2,k) .ne. 0 .and. abs(frequencies(2,k)) < best_freq) then
                   best_k = k
                   best_freq = abs(frequencies(2,k))
               end if 
            end do 

            ! stop if n_g != 0 for this mode 
            if (n_gs(best_k) .ne. 0) then
               write (*,*) 'Found an observable mixed mode!'
               extras_finish_step = terminate
            end if

         end if

         ! to save a profile, 
            ! s% need_to_save_profiles_now = .true.
         ! to update the star log,
            ! s% need_to_update_history_now = .true.

         ! see extras_check_model for information about custom termination codes
         ! by default, indicate where (in the code) MESA terminated
         if (extras_finish_step == terminate) s% termination_code = t_extras_finish_step
      end function extras_finish_step


      subroutine extras_after_evolve(id, ierr)
         integer, intent(in) :: id
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
      end subroutine extras_after_evolve

  ! >>> Insert additional subroutines/functions below

      subroutine run_gyre (id, ierr)

         integer, intent(in)  :: id
         integer, intent(out) :: ierr

         real(dp), allocatable :: global_data(:)
         real(dp), allocatable :: point_data(:,:)
         integer               :: ipar(0)
         real(dp)              :: rpar(0)

         ! Pass model data to GYRE

         call star_get_pulse_data(id, 'GYRE', .FALSE., .TRUE., .FALSE., &
              global_data, point_data, ierr)
         if (ierr /= 0) then
            print *,'Failed when calling star_get_pulse_data'
            return
         end if

         call gyre_set_model(global_data, point_data, 101)

         ! Run GYRE to get modes

         call gyre_get_modes(0, process_mode, ipar, rpar)
         call gyre_get_modes(1, process_mode, ipar, rpar)

         gyre_has_run = .true.

      contains

         subroutine process_mode (md, ipar, rpar, retcode)

            type(mode_t), intent(in) :: md
            integer, intent(inout)   :: ipar(:)
            real(dp), intent(inout)  :: rpar(:)
            integer, intent(out)     :: retcode
            integer :: k

            type (star_info), pointer :: s
            ierr = 0
            call star_ptr(id, s, ierr)
            if (ierr /= 0) return

            if (md%n_p >= 1 .and. md%n_p <= 50) then

                ! Print out degree, radial order, mode inertia, and frequency
                print *, 'Found mode: l, n_p, n_g, E, nu = ', &
                    md%l, md%n_p, md%n_g, md%E_norm(), REAL(md%freq('HZ'))

                if (md%l == 0) then ! radial modes 
                    frequencies(md%l+1, md%n_p) = (md%freq('UHZ') - s% nu_max) / s% delta_nu

                    if (md%n_p == s% x_integer_ctrl(1)) then ! store the eigenfunction 
                       if (allocated(xi_r_radial)) deallocate(xi_r_radial)
                       allocate(xi_r_radial(md%n_k))

                       do k = 1, md%n_k
                          xi_r_radial(k) = md%xi_r(k)
                       end do
                       xi_r_radial = xi_r_radial(md%n_k:1:-1)
                    end if

                else if (inertias(md%n_p) > 0 .and. md%E_norm() > inertias(md%n_p)) then
                    write (*,*) 'Skipping mode: inertia higher than already seen'
                else ! non-radial modes 

                    ! choose the mode with the lowest inertia 
                    inertias(md%n_p) = md%E_norm() 
                    frequencies(md%l+1, md%n_p) = (md%freq('UHZ') - s% nu_max) / s% delta_nu
                    n_gs(md%n_p) = md%n_g

                    if (md%n_p == s% x_integer_ctrl(1) - 1) then ! store the eigenfunction 
                       if (allocated(xi_r_dipole)) deallocate(xi_r_dipole)
                       allocate(xi_r_dipole(md%n_k))

                       do k = 1, md%n_k
                          xi_r_dipole(k) = md%xi_r(k)
                       end do
                       xi_r_dipole = xi_r_dipole(md%n_k:1:-1)
                    end if

                end if
            end if

            retcode = 0
         end subroutine process_mode


      end subroutine run_gyre


      end module run_star_extras
