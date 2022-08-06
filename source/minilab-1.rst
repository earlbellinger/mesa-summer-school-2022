.. _minilab-1:

**********************
MiniLab 1: First Steps
**********************

Overview
========

In MiniLab 1, we'll create a model for a solar-type
star and track it as it evolves from the zero-age main sequence
(ZAMS) through to the base of the red giant branch (BRGB). 

Once we've got our model working, we'll modify our
``run_star_extras.f90`` file to run the `GYRE
<https://gyre.readthedocs.io/>`_ oscillation code
after each timestep, calculating the star's oscillation frequencies.

Download a Working Directory
============================

To get started, let's set up a new working directory. Download `this
<https://github.com/earlbellinger/mesa-summer-school-2022/raw/main/work-dirs/bellinger-2022-mini-1.tar.gz>`__ 
file and unpack it using tar:

.. code-block:: console

   $ tar xf bellinger-2022-mini-1.tar.gz

This working directory contains a pre-configured set of inlist files
and columns files, a custom ``run_star_extras.f90`` file that we'll be
editing extensively, and some other support files. After making sure
your ``MESA_DIR`` environment variable is properly set, change into
the working directory and build the code:

.. code-block:: console

   $ cd bellinger-2022-mini-1
   $ ./mk

Evolve the Model
================

Now let's evolve the model. 

.. code-block:: console

   $ ./rn

During the runs a single PGstar window will display various plots in a
grid layout. We'll be adding to these plots during the MiniLabs and
Maxilab. If the plots are difficult to read on your computer, and/or
the window doesn't fit on your screen properly, consider customizing
the ``Grid1_win_width`` and ``Grid1_win_aspect_ratio`` parameters in
the ``inlist_pgstar`` file.

To get an idea of what settings we're using for these calculations,
take a look inside ``inlist_project``. We set the initial mass to 
:math:`1\,{\rm M_{\odot}}` and choose a mixing length that is 
appropriate for the Sun. 


Modify the Code
===============

As the next step, open ``src/run_star_extras.f90`` in a text
editor. We're going to modify this file to run GYRE after each
timestep, using a new subroutine we provide called ``run_gyre``. This
will require edits in four places, as detailed in the following four
subsections.

Import the GYRE Library
-----------------------

At a number of points in the ``run_star_extras.f90`` file, there are
comments lines that mark where to add the new code. The first one
looks like this:

.. code-block:: fortran

   ! >>> Insert additional use statements below

Add code below this comment line like this:

.. code-block:: fortran

   ! >>> Insert additional use statements below

   use gyre_lib

This will import
the ``gyre_lib`` library, making its subroutines and functions
available for us to call.

Initialize GYRE
---------------

Let's now add code to initialize GYRE. Find the ``extras_startup``
subroutine and add the following code below the comment
line (to avoid the possibility of typos, it's better to use
copy-and-paste rather than typing this by hand):

.. code-block:: fortran
   
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

The ``gyre_init`` call takes care of the initialization; its single
argument is the name of the GYRE input file to read parameters
from. Inside your working directory, the file ``gyre.in`` should
already be present; we'll be editing it later on. The subsequent calls
to ``gyre_set_constant`` are used to set GYRE's physical constants to
the same values that MESA adopts.

Call ``run_gyre``
-----------------

Find the ``extras_check_model`` subroutine and add the following
code below the comment line:

.. code-block:: fortran

    ! >>> Insert additional code below

    if (s%x_logical_ctrl(1)) then
       call run_gyre(id, ierr)
    endif

Here, we call the subroutine ``run_gyre`` to take care of running GYRE
(we'll create this subroutine in the next step). The enclosing ``if``
statement checks the ``x_logical_ctrl(1)`` control to decide whether
to make the call; this would allow us, for example, 
to skip running GYRE during certain evolutionary phases. 

Create ``run_gyre``
-------------------

As our final modification, add the following code at the
end of ``run_star_extras.f90``:

.. code-block:: fortran

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

            end if

            retcode = 0
         end subroutine process_mode


      end subroutine run_gyre

The new subroutine runs GYRE on the current stellar model indexed by
the ``id`` variable. First, the ``star_get_pulse_data`` call copies
pulsation data from the model into the local arrays ``global_data``
and ``point_data``. Then, the ``gyre_set_model`` call passes these
data through to GYRE. Finally, the ``gyre_get_modes`` call instructs
GYRE to find modes with harmonic degrees :math:`\ell=0` and :math:`\ell=1` 
--- i.e., radial and dipole modes. The ``process_mode`` routine is passed into
``gyre_get_modes`` as a 'callback' routine; each time GYRE finds a
mode, it will call ``process_mode``. Here, as a starting point for
later work, we've set up ``process_mode`` to print out some information
about the mode. 

Compile and Run
===============

With ``run_star_extras.f90`` modified as described above, re-compile
the code:

.. code-block:: console

   $ ./mk

Next, edit ``inlist_project`` to add the following line to the ``controls`` namelist:

.. code-block:: fortran

   x_logical_ctrl(1) = .true.

This will make sure that ``run_gyre`` is called during the
ZAMS-to-TAMS evolution. You're now ready to go ahead and run the code:

.. code-block:: console

   $ ./rn

As the run proceeds, you should be able to see terminal output that looks similar to this:

.. code-block:: console


 Found mode: l, n_p, n_g, E, nu =            0           1           0   9.6744296164353559E-003   2.9946761840058696E-004
 Found mode: l, n_p, n_g, E, nu =            0           2           0   2.2622227776063577E-003   4.5568978091446087E-004
 Found mode: l, n_p, n_g, E, nu =            0           3           0   4.5829289819634191E-004   6.1980505638224942E-004
 Found mode: l, n_p, n_g, E, nu =            0           4           0   1.3768693565643185E-004   7.9872212926827813E-004
 Found mode: l, n_p, n_g, E, nu =            0           5           0   4.7056235086389738E-005   9.7581695965845720E-004
 ...

This confirms that GYRE is being run, and that modes are being found. 
The frequencies of the modes are of the order :math:`10^{-3}\,{\rm Hz}`, 
just what we'd expect for solar-like stars. 
