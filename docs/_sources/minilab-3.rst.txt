.. _minilab-3:

*********************************
MiniLab 3: Plotting Wavefunctions
*********************************

Overview
========

In :ref:`MiniLab 2 <minilab-2>`, we found that the periods of the
fundamental and first-overtone radial modes scale approximately with
the dynamical timescale, :math:`P \propto \tau_{\rm dyn}`. In MiniLab
3, we're going to examine the mode radial displacement wavefunctions
:math:`\xi_{r}`, which ultimately determine the constant of
proportionality in this scaling. The steps are similar to before:
first we'll add the :math:`\xi_{r}` data to MESA's profile output, and
then modify ``inlist_to_tams_pgstar`` to plot these wavefunctions. As
the very first step, make a copy of your working directory from
:ref:`MiniLab 2 <minilab-2>` (with all the changes you have made):

.. code-block:: console

   $ cp -a townsend-2019-mini-2 townsend-2019-mini-3
   $ cd townsend-2019-mini-3

Alternatively, if you were unable to get things working with
:ref:`MiniLab 2 <minilab-2>`, then you can grab a working directory
for MiniLab 3 from `here
<http://www.astro.wisc.edu/~townsend/resource/teaching/mesa-summer-school-2019/townsend-2019-mini-3.tar.gz>`__.

Adding Wavefunctions to Profile Output
======================================

As with the mode periods, to communicate data from ``process_mode`` to
other routines in ``run_star_extras.f90``, we'll make use of module
variables.

Adding Module Variables
-----------------------

Add the following highlighted code at the appropriate place near the
top of ``run_star_extras.f90``:

.. code-block:: fortran
    :emphasize-lines: 8-

    ! >>> Insert module variables below

    ! Periods of fundamental and first overtone

    real(dp), save :: period_f
    real(dp), save :: period_1o

    ! Displacement wavefunctions of F and 1-O modes

    real(dp), allocatable, save :: xi_r_f(:)
    real(dp), allocatable, save :: xi_r_1o(:)

Note that we declare the variables as allocatable arrays --- that's
because the displacement wavefunctions are functions of position
within the star.

Setting Module Variables
------------------------

Next, modify the ``process_mode`` callback routine to set the two two
module variables. GYRE provides the radial displacement wavefunction
at the ``k``'th grid point via the ``md%xi_r(k)`` function. However, a
wrinkle here is that GYRE indexes its grid points in the opposite
order to MESA. With this in mind, the following highlighted code
illustrates how to set up the ``xi_r_f`` variable for the fundamental
mode:

.. code-block:: fortran
      :emphasize-lines: 1,14-

      integer :: k

      ! Print out radial order and frequency

      print *, 'Found mode: radial order, frequency = ', &
           md%n_pg, REAL(md%freq('HZ'))

      ! If this is the F mode, store the period

      if (md%n_pg == 1) then
         period_f = 1. / (3600.*REAL(md%freq('HZ')))
      end if

      ! If this is the F mode, store the displacement wavefunction

      if (md%n_pg == 1) then

         if (allocated(xi_r_f)) deallocate(xi_r_f)
         allocate(xi_r_f(md%n_k))

         do k = 1, md%n_k
            xi_r_f(k) = md%xi_r(k)
         end do

	 xi_r_f = xi_r_f(md%n_k:1:-1)

      end if


(Don't overlook the first, highlighted line, where we declare a new
integer variable ``k``).

In this code, we first deallocate ``xi_r_f`` (if currently allocated),
and then allocate it at the correct size (``md%n_k`` is the number of
grid points). Following that, we loop over the grid index ``k``,
storing values in the ``xi_r_f`` array. . As a final step, we reverse
the order of elements in this array (the strange-looking expression
``xi_r_f(md%n_k:1:-1)`` uses Fortran's array-slice notation to access
the elements of ``xi_r_f`` from the last to the first, in increments
of ``-1``).

.. admonition:: Exercise
      
   Add further code to ``process_mode``, to store the radial
   displacement wavefunction of the 1-O mode into ``xi_r_1o``.
   
Adding Profile Columns
----------------------

Next, we'll add two extra columns to profile output, in which we'll
store the radial displacement wavefunctions we've calculated.

.. admonition:: Exercise

   Modify ``how_many_extra_profile_columns`` to set the number of
   columns, and ``data_for_extra_profile_columns`` to set up the names
   and values of the columns. Be sure to check ``s%x_logical_ctrl(1)``
   before setting the ``vals`` array, as we did :ref:`here
   <minilab-2-add-hist-cols>` when adding history columns .

Note that the ``vals`` array in ``data_for_extra_profile_columns`` is
*two-dimensional* --- the first dimension is grid location, and the
second dimension is column number. So, to store ``xi_r_f`` into the
first column of ``vals``, we could use Fortran's array-slice notation
like this:

.. code-block:: fortran

   vals(:,1) = xi_r_f

Running the Code
================

With these changes to ``run_star_extras.f90``, re-compile and re-run
the code.

.. admonition:: Exercise

   Check that the profile files written to ``LOGS/profileN.data``
   (where ``N`` is an integer) contain two extra columns, containing
   the radial displacement wavefunction data.

At the end of this run, you'll likely find that the code crashes with
an error message something like this:

.. code-block:: console

  At line 239 of file ../src/run_star_extras.f90
  Fortran runtime error: Array bound mismatch for dimension 1 of array 'vals' (1917/1910)

We'll address this error in the following step.

Fixing the Crash
================

The code crashes at the end of execution because the
``extras_check_model`` hook (and hence the ``run_gyre`` and
``process_mode`` routines) doesn't get called before the final call to
``data_for_extra_profile_columns``. Therefore, the ``xi_r_f`` and
``xi_r_1o`` arrays contain data from the previous timestep, when the
model had a different number of grid points. Attempting to copy data
from these arrays into the ``vals`` array triggers the crash, because
the arrays have different sizes.

To fix this problem, we have to modify
``data_for_extra_profile_columns`` to check whether ``run_gyre`` has
been called since the beginning of the timestep. If not, it should
make the call itself, thereby updating the ``xi_r_f`` and ``xi_r_1o``
arrays.

.. admonition:: Excercise

   Add a new module variable to ``run_star_extras.f90`` (see
   :ref:`here <minilab-2-mod-vars>` for a reminder of how to do this),
   with name ``gyre_has_run`` and type ``logical``. Then

   - modify ``extras_start_step`` to initialize ``gyre_has_run`` to
     ``.false.`` at the beginning of each step.

   - modify ``run_gyre`` to set ``gyre_has_run`` to ``.true.`` after
     GYRE has been run.

   - modify ``data_for_extra_profile_columns`` to call ``run_gyre`` if
     ``gyre_has_run`` is ``.false.``. To perform the check on
     ``gyre_has_run``, you can use a conditional block like this:

     .. code-block:: fortran
	
        if (.NOT. gyre_has_run) then
	   ...
        endif

Be sure to check that these changes fix the crash.

Plotting the Wavefunctions
==========================

Our final step is to add a PGstar window to our ZAMS-to-TAMS run,
showing how the mode radial displacement wavefunctions change as the
star evolves. For this window, we'll use a 'profile panel'.

Open up ``inlist_to_tams_pgstar``, and add the following highlighted
code at the bottom:

.. code-block:: fortran
  :emphasize-lines: 1-

  ! Profile panel showing wavefunctions

  Grid1_plot_name(6) = 'Profile_Panels1'

  Profile_Panels1_num_panels = 1
  Profile_Panels1_title = 'Displacement Wavefunctions'

  Profile_Panels1_xaxis_name = 'logxq'

  Profile_Panels1_yaxis_name(1) = 'xi_r_f'
  Profile_Panels1_other_yaxis_name(1) = 'xi_r_1o'

(Here, the ``logxq`` choice for the x-axis uses the quantity
:math:`\log(1-m/M)`, which nicely emphasizes the outer parts of the
star).

Looking at the wavefunctions, we can clearly see the key difference
between the radial and first-overtone modes: the latter has a node
(:math:`\xi_{r} = 0`) somewhere between the center and the surface,
while the former does not. This sign change means that the effective
wavelength of the first overtone is shorter --- and hence, its
frequency is higher, and its period shorter.

As an aside: the radial displacement wavefunctions are in units of the
stellar radius :math:`R`. Reading off the plots, it would seem that
the radial displacement at the stellar surface is tens or even
hundreds times :math:`R`. This shouldn't alarm you; GYRE is a *linear*
oscillation code, and therefore its wavefunctions have an arbitrary
scaling.
