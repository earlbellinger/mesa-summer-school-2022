.. _minilab-2:

*******************************
MiniLab 2: Plotting Frequencies
*******************************

Overview
========

In Minilab 2, we'll take mode frequencies calculated by GYRE and plot them
using PGstar. This will involve first adding the frequencies to MESA's
history output; and then modifying ``inlist_pgstar`` to set up
the plots. As the very first step, make a copy of your working
directory from :ref:`MiniLab 1 <minilab-1>` (with all the changes you have made):

.. code-block:: console

   $ cp -a bellinger-2022-mini-1 bellinger-2022-mini-2
   $ cd bellinger-2022-mini-2

Alternatively, if you were unable to get things working with
:ref:`MiniLab 1 <minilab-1>`, then you can grab a working directory
for MiniLab 2 from `here
<https://github.com/earlbellinger/mesa-summer-school-2022/raw/main/work-dirs/bellinger-2022-mini-1-solution.tar.gz>`__.

Adding Frequencies to History Output
====================================

The standard approach to adding extra columns to history output is to
modify the ``how_many_extra_history_columns`` and
``data_for_extra_history_columns`` hooks. The former defines how many
extra columns we want to add; while the latter specifies the data to
put into the columns, together with their associated names. Before we
make these modifications, however, we have to solve a logistical problem:
how do we access the GYRE results outside of the ``process_mode``
callback routine?

The answer is to store these results in 'module variables' ---
effectively, global variables that can be accessed from anywhere
within ``run_star_extras.f90``.

.. _minilab-2-mod-vars:

Adding Module Variables
-----------------------

Let's add a couple of module variables to store the frequencies of the
radial and dipole modes, and the inertias of the dipole modes. Add the following
code at the appropriate place near the top of
``run_star_extras.f90``:

.. code-block:: fortran

  ! >>> Insert module variables below

      real(dp), allocatable, save :: frequencies(:,:)
      real(dp), allocatable, save :: inertias(:)

The ``save`` attributes ensure that the values of the 
variables are preserved throughout program execution.
Note that we declare the variables as allocatable arrays, 
and therefore need to allocate them in `extras_startup` and 
initialize them in `extras_start_step`. Therefore, find the following
code blocks and make the following additions:

.. code-block:: fortran

  ! >>> Insert allocation code below

         allocate(inertias(50))
         allocate(frequencies(2,50))

as well as 

.. code-block:: fortran

  ! >>> Insert additional code below

         do k = 1, 50
            frequencies(1,k) = 0
            frequencies(2,k) = 0
            inertias(k) = 0
         end do

Note that we are also storing the inertias of the dipole modes. 
That is because we want the most p-dominated modes, and therefore 
need to select the modes with the lowest mode inertias. 
We have allocated space for 100 modes, but in practice we will find 
an *a priori* unknown amount of around 70 or so. 

Setting Module Variables
------------------------

Let's now modify the ``process_mode`` callback routine to set these
module variables. As a reminder, ``process_mode`` is called each
time GYRE finds a mode. Therefore, we have to add checks to see
*which* mode has been found --- and if it is a radial or dipole mode, 
update one or the other module variable accordingly.

Within ``process_mode``, all data for the mode being processed are
stored in the ``md`` object. The existing code that prints radial
frequencies to the screen already shows us how to access
these data:

.. code-block:: fortran

    ! Print out degree, radial order, mode inertia, and frequency
    print *, 'Found mode: l, n_p, n_g, E, nu = ', &
        md%l, md%n_p, md%n_g, md%E_norm(), REAL(md%freq('HZ'))

Here, ``md%n_p`` is a simple integer variable containing the acoustic radial
order, while ``md%freq(...)`` is a function that returns the mode frequency
in the desired units (in this case, Hertz). The ``REAL(...)`` wrapper
is required because ``md%freq(...)`` returns a complex value, with the
real part containing the frequency and the imaginary part containing
the growth rate. This also prints the spherical degree ``md%l``, 
the g-mode radial order ``md%n_g``, and the mode inertia ``md%E_norm()``.

With these points in mind, we can store the frequencies by adding the following 
code to the ``process_mode`` subroutine. Note that we will calculate 
the frequencies in microHertz (``'UHZ'``) and then normalize 
the frequencies by ``s% nu_max`` and ``s% delta_nu`` in order to make the plots look nicer. 

.. code-block:: fortran

    if (md%n_p >= 1 .and. md%n_p <= 50) then

        ! Print out degree, radial order, mode inertia, and frequency
        print *, 'Found mode: l, n_p, n_g, E, nu = ', &
            md%l, md%n_p, md%n_g, md%E_norm(), REAL(md%freq('HZ'))

        if (md%l == 0) then ! radial modes 
            frequencies(md%l+1, md%n_p) = (md%freq('UHZ') - s% nu_max) / s% delta_nu

        else if (inertias(md%n_p) > 0 .and. md%E_norm() > inertias(md%n_p)) then
            write (*,*) 'Skipping mode: inertia higher than already seen'
        else ! non-radial modes 

            ! choose the mode with the lowest inertia 
            inertias(md%n_p) = md%E_norm() 
            frequencies(md%l+1, md%n_p) = (md%freq('UHZ') - s% nu_max) / s% delta_nu

        end if
    end if

Notice here that we are only saving the dipole mode with the lowest inertia. 

.. _minilab-2-add-hist-cols:
   
Adding History Columns
----------------------

We're now in a position to add two extra columns to history output, in
which we'll store the frequencies we've calculated. First, edit
``how_many_extra_history_columns`` to set the number of columns:

.. code-block:: fortran

  ! >>> Change number of history columns below

         how_many_extra_history_columns = 100

Next, add code to ``data_for_extra_history_columns`` to set up
the names and values of the two extra columns:

.. code-block:: fortran

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

Note that we check ``s%x_logical_ctrl(1)`` before setting the ``vals``
array; that way, we avoid copying undefined values if running GYRE has been skipped.

Running the Code
================

With these changes to ``run_star_extras.f90``, re-compile and re-run
the code:

.. code-block:: console

   $ ./mk
   $ ./rn

The history file written to ``LOGS/history.data`` should now contain
extra columns, containing the frequency data. An easy way to check
this is to use the ``less`` command with the ``-S`` (chop long lines)
flag:

.. code-block:: console

   $ less -S LOGS/history.data

(Use the left/right cursors key to scan through the columns).

Plotting the Frequencies 
========================

We're now in a position to add a PGstar panel to our
run, showing how the mode frequencies change as the star evolves. The type
of panel we'll use is called a 'history panel', which plots columns
from the history file as a function of model number or time.

Open up ``inlist_pgstar``, and add the following code at the bottom:

.. code-block:: fortran

  ! >>> Insert additional parameters below

  ! History panel showing frequencies

  Grid1_plot_name(5) = 'History_Panels1'

  History_Panels1_num_panels = 1
  History_Panels1_title = 'Frequencies'
  History_Panels1_xaxis_name = 'model_number'
  History_Panels1_max_width = 0

  History_Panels1_yaxis_name(1) = 'nu_radial_10'
  History_Panels1_other_yaxis_name(1) = 'nu_dipole_9'
  
  History_Panels1_same_yaxis_range(1) = .true.

(Here, the first line indicates where in the existing grid layout to
place the history panel; the subsequent lines specify what to plot in
the panel).
  
Now re-run the evolution, and consider the following question:

  - Why do the frequencies move in lockstep, with the dipole mode 
    having a nearly constant offset from the radial mode? 

The answer can be found by considering the asymptotic relation, 
which gives that the frequencies of the modes scale with the 
large frequency separation ``delta_nu``, the spherical degree,
and radial order: 

.. math::

   \nu_{n,\ell} \simeq \Delta\nu\left( n + \ell/2 + \epsilon \right)

where :math:`\nu_{n,\ell}` is the frequency of a mode with 
radial order :math:`n` and spherical degree :math:`\ell`;
:math:`\Delta\nu` is the large frequency separation, and 
:math:`\epsilon` is a phase term. 
