.. _minilab-2:

*******************************
MiniLab 2: Plotting Frequencies
*******************************

Overview
========

In Minilab 2, we'll take mode periods calculated by GYRE and plot them
using PGstar. This will involve first adding the periods to MESA's
history output; and then modifying ``inlist_pgstar`` to set up
the plots. As the very first step, make a copy of your working
directory from :ref:`MiniLab 1 <minilab-1>` (with all the changes you have made):

.. code-block:: console

   $ cp -a bellinger-2022-mini-1 bellinger-2022-mini-2
   $ cd bellinger-2022-mini-2

Alternatively, if you were unable to get things working with
:ref:`MiniLab 1 <minilab-1>`, then you can grab a working directory
for MiniLab 2 from `here
<TODO>`__.

Adding Frequencies to History Output
====================================

The standard approach to adding extra columns to history output is to
modify the ``how_many_extra_history_columns`` and
``data_for_extra_history_columns`` hooks. The former defines how many
extra columns we want to add; while the latter specifies the data to
put into the columns, together with their associated names. Before we
make these modifications, however, we have solve a logistical problem:
how do we access the GYRE results outside of the ``process_mode``
callback routine?

The answer is to store these results in 'module variables' ---
effectively, global variables that can be accessed from anywhere
within ``run_star_extras.f90``.

Adding Module Variables
-----------------------

Let's add a couple of module variables to store the periods of the
fundamental (F) and first-overtone (1-O) modes. Add the following
highlighted code at the appropriate place near the top of
``run_star_extras.f90``:

.. code-block:: fortran
    :emphasize-lines: 3-

    ! >>> Insert module variables below

    ! Periods of F and 1-O modes

    real(dp), save :: period_f
    real(dp), save :: period_1o

The ``save`` attributes ensure that the values of the ``period_f`` and
``period_1o`` variables are preserved throughout program execution.

.. _minilab-2-mod-vars:

Setting Module Variables
------------------------

Let's now modify the ``process_mode`` callback routine to set these
two module variables. As a reminder, ``process_mode`` is called each
time GYRE finds a mode. Therefore, we have to add checks to see
*which* mode has been found --- and if it is the fundamental or first
overtone, update one or the other module variable accordingly.

Within ``process_mode``, all data for the mode being processed are
stored in the ``md`` object. The existing code that prints radial
orders and frequencies to the screen already shows us how to access
these data:

.. code-block:: fortran

      ! Print out radial order and frequency

      print *, 'Found mode: radial order, frequency = ', &
           md%n_pg, REAL(md%freq('HZ'))

Here, ``md%n_pg`` is a simple integer variable containing the radial
order (which equals 1 for the F mode; 2 for the 1-O mode; and so on);
while ``md%freq(...)`` is a function that returns the mode frequency
in the desired units (in this case, Hertz). The ``REAL(...)`` wrapper
is required because ``md%freq(...)`` returns a complex value, with the
real part containing the frequency and the imaginary part containing
the growth rate (more of that later in the :ref:`MaxiLab <maxilab>`,
when we consider non-adiabatic pulsations).

With these points in mind, we can set ``period_f`` to the
F-mode period *in hours* by adding the following highlighted
code to the ``process_mode`` subroutine:

.. code-block:: fortran
     :emphasize-lines: 6-

      ! Print out radial order and frequency

      print *, 'Found mode: radial order, frequency = ', &
           md%n_pg, REAL(md%freq('HZ'))

      ! If this is the F mode, store the period

      if (md%n_pg == 1) then
         period_f = 1. / (3600.*REAL(md%freq('HZ')))
      end if

.. admonition:: Exercise
      
   Add further code to ``process_mode``, to store the 1-O mode period
   in hours into ``period_1o``.

.. _minilab-2-add-hist-cols:
   
Adding History Columns
----------------------

We're now in a position to add two extra columns to history output, in
which we'll store the periods we've calculated. First, edit
``how_many_extra_history_columns`` to set the number of columns (here,
the modified line is highlighted):

.. code-block:: fortran
    :emphasize-lines: 3

    ! >>> Change number of history columns below

    how_many_extra_history_columns = 2

Next, add code to ``data_for_extra_history_columns`` to set up
the names and values of the two extra columns:

.. code-block:: fortran
    :emphasize-lines: 3-

    ! >>> Insert code to set history column names/values below

    names(1) = 'period_f'
    names(2) = 'period_1o'

    if (s%x_logical_ctrl(1)) then

       vals(1) = period_f
       vals(2) = period_1o

    else

       vals(1) = 0.
       vals(2) = 0.

    endif

Note that we check ``s%x_logical_ctrl(1)`` before setting the ``vals``
array; that way, we avoid copying undefined values from ``period_f``
and ``period_1o`` if running GYRE has been skipped.

Running the Code
================

With these changes to ``run_star_extras.f90``, re-compile and re-run
the code:

.. code-block:: console

   $ ./mk
   $ ./star inlist_to_tams

The history file written to ``LOGS/history.data`` should now contain
two extra columns, containing the period data. An easy way to check
this is to use the ``less`` command with the ``-S`` (chop long lines)
flag:

.. code-block:: console

   $ less -S LOGS/history.data

(Use the left/right cursors key to scan through the columns).

Plotting the Periods
====================

We're now in a position to add a PGstar panel to our ZAMS-to-TAMS
run, showing how the mode periods change as the star evolves. The type
of panel we'll use is called a 'history panel', which plots columns
from the history file as a function of model number or time.

Open up ``inlist_to_tams_pgstar``, and add the following highlighted
code at the bottom:

.. code-block:: fortran
  :emphasize-lines: 3-

  ! >>> Insert additional parameters below

  ! History panel showing periods

  Grid1_plot_name(5) = 'History_Panels1'

  History_Panels1_num_panels = 2
  History_Panels1_title = 'Periods'

  History_Panels1_xaxis_name = 'star_age'
  History_Panels1_max_width = 0

  History_Panels1_yaxis_name(1) = 'period_f'
  History_Panels1_ymin(1) = 0
  History_Panels1_other_yaxis_name(1) = ''
  History_Panels1_other_ymin(1) = 0

  History_Panels1_yaxis_name(2) = 'period_1o'
  History_Panels1_ymin(2) = 0
  History_Panels1_other_yaxis_name(2) = ''
  History_Panels1_other_ymin(2) = 0

(Here, the first line indicates where in the existing grid layout to
place the history panel; the subsequent lines specify what to plot in
the panel).
  
Now re-run the ZAMS-to-TAMS evolution, and consider the following questions:

  - Why do the mode periods get longer for the most of the run --- but
    then briefly get shorter at the end of the run?

  - Why do the mode periods move in lockstep, with the 1-O mode being
    an almost-fixed multiple of the F mode?

.. admonition:: *Optional* Exercise

   In addition to printing periods to the terminal, it's often useful
   to display them in the PGstar window. Modifiy
   ``inlist_to_tams_pgstar`` to set ``Text_Summary1_name(1,4)`` (i.e.,
   the first item in the fourth column of the text area) to
   ``'period_f'``. Make a similar modifications to add ``period_1o``
   as the second item.

Quantifying the Period Scaling
==============================

The answer to both of the questions above lies in considering the
response of a star to departures from hydrostatic equilibrium. One of
the first things we learn in any course on stellar astrophysics is
that this response occurs on the star's dynamical timescale:
:math:`\tau_{\rm dyn} = \sqrt{R^{3}/GM}`. Since radial pulsations are
an example of departures from hydrostatic equilibrium, we should
therefore expect the pulsation periods :math:`P` to scale
(approximately) proportionally with :math:`\tau_{\rm dyn}`. Our next
step is to check whether this is the case.

.. admonition:: Exercise
      
   Edit the existing ``history_columns.list`` file in the working
   directory. Find which history item contains the dynamical
   timescale, and uncomment the corresponding line. Then, modify
   ``inlist_to_tams_pgstar`` to add this timescale to each of the
   plots in the history panel (hint: use the
   ``History_Panels1_other_yaxis_name`` controls), and repeat the
   ZAMS-to-TAMS run.

This exercise confirms that periods follow the approximate scaling
:math:`P \propto \tau_{\rm dyn}`. The period lengthening as the star
evolves toward the TAMS is driven mostly by the :math:`\tau_{\rm dyn}`
increase, which in turn is driven by the expansion of the star. The
brief reversal in this behavior, near the TAMS, is associated with the
Henyey hook where the star shrinks.

.. admonition:: *Optional* Exercise

   Modifiy ``inlist_to_tams_pgstar`` to add the dynamical timescale to
   the text area.
