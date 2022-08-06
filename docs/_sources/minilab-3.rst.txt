.. _minilab-3:

**********************************
MiniLab 3: Plotting Eigenfunctions
**********************************

Overview
========

In :ref:`MiniLab 2 <minilab-2>`, we calculated the frequencies of the
modes, and plotted a radial and a dipole mode. 
In MiniLab 3, we're going to examine the radial displacement eigenfunctions 
:math:`\xi_{r}` of these modes. The steps are similar to before:
first we'll add the :math:`\xi_{r}` data to MESA's profile output, and
then modify ``inlist_pgstar`` to plot these eigenfunctions. As
the very first step, make a copy of your working directory from
:ref:`MiniLab 2 <minilab-2>` (with all the changes you have made):

.. code-block:: console

   $ cp -a bellinger-2022-mini-2 bellinger-2022-mini-3
   $ cd bellinger-2022-mini-3

Alternatively, if you were unable to get things working with
:ref:`MiniLab 2 <minilab-2>`, then you can grab a working directory
for MiniLab 3 from `here
<https://github.com/earlbellinger/mesa-summer-school-2022/raw/main/work-dirs/bellinger-2022-mini-2-solution.tar.gz>`__.

Adding Eigenfunctions to Profile Output
=======================================

As with the mode frequencies, to communicate data from ``process_mode`` to
other routines in ``run_star_extras.f90``, we'll make use of module
variables.

Adding Module Variables
-----------------------

Add the following code at the appropriate place near the
top of ``run_star_extras.f90``:

.. code-block:: fortran

  ! >>> Insert module variables below

      real(dp), allocatable, save :: frequencies(:,:)
      real(dp), allocatable, save :: inertias(:)

      ! Radial displacement eigenfunctions 

      real(dp), allocatable, save :: xi_r_radial(:)
      real(dp), allocatable, save :: xi_r_dipole(:)

Setting Module Variables
------------------------

Next, modify the ``process_mode`` callback routine to set the two 
module variables. GYRE provides the radial displacement eigenfunction 
at the ``k``'th grid point via the ``md%xi_r(k)`` function. However, a
wrinkle here is that GYRE indexes its grid points in the opposite
order to MESA. With this in mind, the following code
illustrates how to set up the ``xi_r_radial`` variable for a
radial mode whose radial order we specify in the inlist using 
``x_integer_ctrl``:

.. code-block:: fortran

        integer :: k

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

            end if
        end if


(Don't overlook the first line, where we declare a new
integer variable ``k``).

In this code, we first deallocate ``xi_r_radial`` (if currently allocated),
and then allocate it at the correct size (``md%n_k`` is the number of
grid points). Following that, we loop over the grid index ``k``,
storing values in the ``xi_r_radial`` array. As a final step, we reverse
the order of elements in this array (the strange-looking expression
``xi_r_radial(md%n_k:1:-1)`` uses Fortran's array-slice notation to access
the elements of ``xi_r_radial`` from the last to the first, in increments
of ``-1``). 

Make sure to also set ``x_integer_ctrl(1)`` in your inlist; 
``x_integer_ctrl(1) = 10`` is a good value, though you can of course change it 
to look at others as well. Note that this code could crash if you set it to 
a mode that isn't computed! 

.. admonition:: Exercise
      
   Add further code to ``process_mode``, to store the radial
   displacement eigenfunction of the ``md%n_p == s% x_integer_ctrl(1)-1`` 
   dipole mode into ``xi_r_dipole``. This code will be otherwise essentially
   identical to the addition made above. 
   
Adding Profile Columns
----------------------

Next, we'll add two extra columns to profile output, in which we'll
store the radial displacement eigenfunctions we've calculated.

.. admonition:: Exercise

   Modify ``how_many_extra_profile_columns`` to set the number of
   columns, and ``data_for_extra_profile_columns`` to set up the names
   and values of the columns. Name them ``'xi_r_radial'`` and ``'xi_r_dipole'``.
   Be sure to check ``s%x_logical_ctrl(1)``
   before setting the ``vals`` array, as we did :ref:`here
   <minilab-2-add-hist-cols>` when adding history columns.

Note that the ``vals`` array in ``data_for_extra_profile_columns`` is
*two-dimensional* --- the first dimension is grid location, and the
second dimension is column number. So, to store ``xi_r_radial`` into the
first column of ``vals``, we could use Fortran's array-slice notation
like this:

.. code-block:: fortran

   vals(:,1) = xi_r_radial

Running the Code
================

With these changes to ``run_star_extras.f90``, re-compile and re-run
the code.

.. admonition:: Exercise

   Check that the profile files written to ``LOGS/profileN.data``
   (where ``N`` is an integer) contain two extra columns, containing
   the radial displacement eigenfunction data.

At the end of this run, you'll likely find that the code crashes with
an error message something like this:

.. code-block:: console

  At line 239 of file ../src/run_star_extras.f90
  Fortran runtime error: Array bound mismatch for dimension 1 of array 'vals' (3832/1)

We'll address this error in the following step.

Fixing the Crash
================

The code crashes at the end of execution because the
``extras_check_model`` hook (and hence the ``run_gyre`` and
``process_mode`` routines) doesn't get called before the final call to
``data_for_extra_profile_columns``. Therefore, the ``xi_r_radial`` and
``xi_r_dipole`` arrays contain data from the previous timestep, when the
model had a different number of grid points. Attempting to copy data
from these arrays into the ``vals`` array triggers the crash, because
the arrays have different sizes.

To fix this problem, we have to modify
``data_for_extra_profile_columns`` to check whether ``run_gyre`` has
been called since the beginning of the timestep. If not, it should
make the call itself, thereby updating the ``xi_r_radial`` and ``xi_r_dipole``
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

Plotting the Eigenfunctions
===========================

Our final step is to add a PGstar window to our run,
showing how the mode radial displacement eigenfunctions change as the
star evolves. For this window, we'll use a 'profile panel'.

Open up ``inlist_pgstar``, and add the following 
code at the bottom:

.. code-block:: fortran

  ! Profile panel showing eigenfunctions

  Grid1_plot_name(6) = 'Profile_Panels1'

  Profile_Panels1_num_panels = 1
  Profile_Panels1_title = 'Eigenfunctions'
  Profile_Panels1_xaxis_name = 'logR' ! 'logxq'
  Profile_Panels1_yaxis_name(1) = 'xi_r_radial'
  Profile_Panels1_other_yaxis_name(1) = 'xi_r_dipole'
  
  Profile_Panels1_ymin(1) = -10
  Profile_Panels1_ymax(1) = 10
  Profile_Panels1_other_ymin(1) = -10
  Profile_Panels1_other_ymax(1) = 10

Now watch the evolution, and see how the sensitivity in the dipole 
mode develops as the star becomes a subgiant! 

As an aside: the radial displacement eigenfunctions are in units of the
stellar radius :math:`R`. Reading off the plots, it would seem that
the radial displacement at the stellar surface is tens or even
hundreds times :math:`R`. This shouldn't alarm you; GYRE is a *linear*
oscillation code, and therefore its eigenfunctions have an arbitrary
scaling.
