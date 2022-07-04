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
<http://www.astro.wisc.edu/~townsend/resource/teaching/mesa-summer-school-2019/townsend-2019-mini-1.tar.gz>`__
file and unpack it using tar:

.. code-block:: console

   $ tar xf townsend-2019-mini-1.tar.gz

This working directory contains a pre-configured set of inlist files
and columns files, a custom ``run_star_extras.f90`` file that we'll be
editing extensively, and some other support files. After making sure
your ``MESA_DIR`` environment variable is properly set, change into
the working directory and build the code:

.. code-block:: console

   $ cd townsend-2019-mini-1
   $ ./mk

Evolve the Model
================

Now let's evolve the model. We run first using ``inlist_to_zams`` as
our master inlist, which evolves a pre-main sequence model to the
ZAMS; and then using ``inlist_to_tams``, which takes the ZAMS model
and evolves it to the TAMS. Note that we bypass the ``rn`` script,
instead running the ``star`` program directly [#f1]_; this allows us to
specify the master inlist on the command line:

.. code-block:: console

   $ ./star inlist_to_zams
   $ ./star inlist_to_tams

During the runs a single PGstar window will display various plots in a
grid layout. We'll be adding to these plots during the MiniLabs and
Maxilab. If the plots are difficult to read on your computer, and/or
the window doesn't fit on your screen properly, consider customizing
the ``Grid1_win_width`` and ``Grid1_win_aspect_ratio`` parameters in
the ``inlist_to_zams_pgstar`` and ``inlist_to_tams_pgstar`` files.

To get an idea of what settings we're using for these calculations,
take a look inside ``inlist_to_tams_project``, which contains the
important parts of the ZAMS-to-TAMS run. Here are a few excerpts:

.. literalinclude:: townsend-2019-mini-1/inlist_to_tams_project
   :start-after: &controls
   :end-before: ! Grid

Here (above), we set the initial mass to :math:`15\,{\rm M_{\odot}}`,
and choose helium and metal mass fractions corresponding to the
:ads:`Asplund et al. (2009) <2009ARA%26A..47..481A>` proto-solar
abundances.

.. literalinclude:: townsend-2019-mini-1/inlist_to_tams_project
   :start-after: initial_Z
   :end-before: ! Stopping

Here, we configure timestep and mesh parameters. We keep the timestep
(relatively) short to ensure that we can adequately follow the
ZAMS-to-TAMS evolution, and we use the ``delta_*`` settings to place
an upper limit on the logarithmic change in the central hydrogen
abundance due to nuclear burning [#f2]_. The ``mesh_delta_coeff``
ensures that models have enough mesh points for GYRE to resolve
pulsation wavefunctions [#f3]_.

.. literalinclude:: townsend-2019-mini-1/inlist_to_tams_project
   :start-after: use_dedt_form_of_energy_eqn
   :end-before: ! Overshooting

Here, we configure various convection parameters. The
``do_conv_premix`` setting turns on the new convective premixing
described in Section 5 of the :ads:`MESA V instrument paper
<2019ApJS..243...10P>`.

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
   :emphasize-lines: 3

   ! >>> Insert additional use statements below

   use gyre_lib

(here and throughout, the added code is highlighted). This will import
the ``gyre_lib`` library, making its subroutines and functions
available for us to call.

Initialize GYRE
---------------

Let's now add code to initialize GYRE. Find the ``extras_startup``
subroutine and add the following highlighted code below the comment
line (to avoid the possibility of typos, it's better you can use
cut-and-paste rather than typing this by hand):

.. code-block:: fortran
    :emphasize-lines: 3-
   
    ! >>> Insert additional code below

    ! Initialize GYRE

    call gyre_init('gyre.in')

    ! Set constants

    call gyre_set_constant('G_GRAVITY', standard_cgrav)
    call gyre_set_constant('C_LIGHT', clight)
    call gyre_set_constant('A_RADIATION', crad)

    call gyre_set_constant('M_SUN', msol)
    call gyre_set_constant('R_SUN', rsol)
    call gyre_set_constant('L_SUN', lsol)

The ``gyre_init`` call takes care of the initialization; its single
argument is the name of the GYRE input file to read parameters
from. Inside your working directory, the file ``gyre.in`` should
already be present; we'll be editing it later on. The subsequent calls
to ``gyre_set_constant`` are used to set GYRE's physical constants to
the same values that MESA adopts.

Call ``run_gyre``
-----------------

Find the ``extras_check_model`` subroutine and add the following
highlighted code below the comment line:

.. code-block:: fortran
    :emphasize-lines: 3-

    ! >>> Insert additional code below

    if (s%x_logical_ctrl(1)) then
       call run_gyre(id, ierr)
    endif

Here, we call the subroutine ``run_gyre`` to take care of running GYRE
(we'll create this subroutine in the next step). The enclosing ``if``
statement checks the ``x_logical_ctrl(1)`` control to decide whether
to make the call; this allows us to skip running GYRE during certain
evolutionary phases (e.g., during the pre-main sequence).

Create ``run_gyre``
-------------------

As our final modification, add the following highlighted code at the
end of ``run_star_extras.f90``:

.. code-block:: fortran
  :emphasize-lines: 3-

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

  contains

    subroutine process_mode (md, ipar, rpar, retcode)

      type(mode_t), intent(in) :: md
      integer, intent(inout)   :: ipar(:)
      real(dp), intent(inout)  :: rpar(:)
      integer, intent(out)     :: retcode

      ! Print out radial order and frequency

      print *, 'Found mode: radial order, frequency = ', &
               md%n_pg, REAL(md%freq('HZ'))

      ! Set return code

      retcode = 0

    end subroutine process_mode

  end subroutine run_gyre

The new subroutine runs GYRE on the current stellar model indexed by
the ``id`` variable. First, the ``star_get_pulse_data`` call copies
pulsation data from the model into the local arrays ``global_data``
and ``point_data``. Then, the ``gyre_set_model`` call passes these
data through to GYRE. Finally, the ``gyre_get_modes`` call instructs
GYRE to find modes with harmonic degree :math:`\ell=0` --- i.e.,
radial modes. The ``process_mode`` routine is passed into
``gyre_get_modes`` as a 'callback' routine; each time GYRE finds a
mode, it will call ``process_mode``. Here, as a starting point for
later work, we've set up ``process_mode`` to print out the mode radial
order and frequency (in Hertz) of the mode.

Compile and Run
===============

With ``run_star_extras.f90`` modified as described above, re-compile
the code:

.. code-block:: console

   $ ./mk

Next, edit ``inlist_to_tams_project`` to add the following line to the ``controls`` namelist:

.. code-block:: fortran

   x_logical_ctrl(1) = .true.

This will make sure that ``run_gyre`` is called during the
ZAMS-to-TAMS evolution. You're now ready to go ahead and run the code:

.. code-block:: console

   $ ./star inlist_to_tams

As the run proceeds, you should be able to see terminal output that looks similar to this:

.. code-block:: console

    Found mode: radial order, frequency =            1   8.5707910250840724E-005
    Found mode: radial order, frequency =            2   1.1184917524623201E-004

This confirms that GYRE is being run, and that radial modes (in this
case, the fundamental and first overtone) are being found. The periods
of the modes are of the order :math:`10^{4}\,{\rm s}`, just what we'd
expect for :math:`\beta` Cephei stars.

.. rubric:: Footnotes

.. [#f1] When using this ``./star`` trick, you can't do restarts
	 using the ``./re`` script. Instead, you should chose which
	 photo in the ``photos`` subdirectory you want to restart
	 from; copy this into the working directory with the name
	 ``restart_photo``; and then run ``./star`` as before. If you
	 later want to *stop* doing restarts, simply delete
	 ``restart_photo``.

.. [#f2] Without these settings, MESA tends to gallop off near the end
         of the main sequence, and doesn't properly resolve the 'Henyey hook'
	 in the Hertzsprung-Russell diagram where massive stars briefly evolve
	 to the blue.
.. [#f3] GYRE is able to do remeshing itself, but we're not going to
         use that particular functionality.
