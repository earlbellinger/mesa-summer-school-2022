.. _maxilab:

******************************************
MaxiLab: Exploring Mixed Oscillation Modes
******************************************

Overview
========

In this maxilab, we will determine when mixed modes are expected to 
become observable. Recall that :math:`\nu_\max` is the frequency at 
maximum oscillation power, and that we have normalized our frequencies 
by this frequency. Recall also that only non-radial modes can become 
mixed modes. Thus, we want to stop our run when the dipole mode closest to 
:math:`\nu_\max` becomes mixed, which we can determine by inspecting its value 
of ``md%n_g`` and seeing when it becomes nonzero. 

As the very first step, make a copy of your working directory from
:ref:`MiniLab 3 <minilab-3>` (with all the changes you have made):

.. code-block:: console

   $ cp -a bellinger-2022-mini-3 bellinger-2022-maxi
   $ cd bellinger-2022-maxi

Alternatively, if you were unable to get things working with
:ref:`MiniLab 3 <minilab-3>`, then you can grab a working directory
for the MaxiLab from `here
<https://github.com/earlbellinger/mesa-summer-school-2022/raw/main/work-dirs/bellinger-2022-mini-3-solution.tar.gz>`__.

Finding the mixed mode 
======================

The next step is to add code to determine when the dipole mode 
closest to :math:`\nu_\max` becomes mixed. Since we have normalized 
our frequencies by subtracting :math:`\nu_\max`, it will be sufficient 
to check when the dipole mode whose frequency is closest to zero 
takes on a nonzero value of :math:`n_g`.

.. admonition:: Exercise

  Add a stopping condition to your run by modifying ``extras_finish_step``
  that checks when the dipole mode closest to zero takes on a nonzero 
  value of :math:`n_g`. 
  In order to accomplish this, you will need to store the values of 
  :math:`n_g` in an integer array. 
  Therefore, you will want to allocate and initialize an array (like 
  we did previously with the ``frequencies`` and ``inertias`` arrays)
  and then store the values of ``md%n_g`` inside the 
  ``process_mode`` subroutine. 
  Then you will want to write a do loop inside ``extras_finish_step`` 
  that iterates through the dipole modes and stores the index 
  of the mode whose normalized frequency closest to zero. Finally, 
  you will check whether the stored ``n_g`` value for that mode is nonzero, 
  and if so, then set ``extras_finish_step = terminate``. 

Mapping the Instability Strip
=============================

As the final part of the MaxiLab, we're going to use GYRE and MESA to
map out the extent of the "mixed mode" instability strip for
dipole modes. This will involve repeating the evolution for a range of
different stellar masses and metallicities, and noting the effective 
temperature and luminosity when the dipole mode closest to 
:math:`\nu_\max` becomes mixed. To speed things
up, we'll crowd-source the calculations: each student will focus on a
single stellar mass, and record their results in a shared online
spreadsheet.

If you haven't had any luck in getting the first part of the MaxiLab
working, then you can grab the solution from `here
<https://github.com/earlbellinger/mesa-summer-school-2022/raw/main/work-dirs/bellinger-2022-maxi-solution.tar.gz>`__;
use this as your working directory for the mixed mode
calculations.

Picking a Mass
--------------

The first step is for each student to pick a (different) mass and composition.

.. admonition:: Exercise

   Visit the Google spreadsheet `here
   <https://docs.google.com/spreadsheets/d/1HMFr3RsocZoBkcyLmRLYiyz-xBB33kvZygJtlYrov9w/edit?usp=sharing>`__,
   and claim a row by
   entering your name to the *Name* column. Make a note of the
   mass and metallicity listed in the following columns.

Determining Boundaries
----------------------

The next step is to perform the calculation and record the instability
strip boundaries. 

.. admonition:: Exercise

   Modify ``inlist_project`` in your working directory 
   to set the initial stellar mass to your
   assigned value. Then, use the ``relax_initial_z`` and 
   ``relax_initial_y`` parameters in ``star_job`` (along with ``new_z``
   and ``new_y``) to input your new composition. In order to obtain a value for 
   Y, we will assume the linear scaling :math:`Y = 0.2463 + 2 \cdot Z`. 
   Make sure to also modify ``Zbase`` in the ``&kap`` namelist. 
   
   Finally, perform the calculations, and note down the log effective temperature
   :math:`\log T_{\rm eff}/{\rm K}` and log luminosity :math:`\log
   L/{\rm L_{\odot}}` at the new stopping point 
   (you can do this by inspecting the terminal output, or by analyzing
   the ``history.data`` file after the run). **Be
   sure to enter logarithmic values, and use 3 decimal places**. Note
   that you may wish to turn off the writing of profile files, and 
   depending on your mass and metallicity, you may need to alter the 
   pre-existing stopping conditions of the inlist. You may also wish to only
   begin computing the oscillations when nearing the end of the main sequence,
   for example by adding logic like ``if (s%xa(1,s%nz) < 0.01) then ...``.

A solution can be found `here <https://github.com/earlbellinger/mesa-summer-school-2022/raw/main/work-dirs/bellinger-2022-maxi-solution.tar.gz>`_. 

.. admonition:: *Optional* Exercise

   If you're feeling bold, see if you can increase the precision with
   which the boundaries are determined. One approach is to modify the
   ``extras_check_model`` hook, to retry the step with a reduced
   timestep when a transition from ``n_g`` zero to ``n_g`` nonzero
   is detected. 

When all the data are collected, we'll combine them to create a map of
the instability strip boundaries in the Hertzsprung-Russell diagram.

.. admonition:: *Optional* Open-Source Development
   
   Wouldn't it be great if MESA were able to output some asteroseismic quantities by default in its history and profile files? 
   Then one could simply add, for example, ``large_frequency_separation`` to ``history_columns.list`` and MESA would call GYRE to perform this calculation — without needing to modify ``run_star_extras.f``. 

   Let's modify MESA's source code to calculate the some of these quantities, such as the large frequency separation or the period of the fundamental mode. 
   Then, let's open a `pull request <https://docs.mesastar.org/en/release-r22.05.1/developing/contributing.html#pull-requests>`_ on the `MESA GitHub <https://github.com/MESAHub/mesa>`_ to share our modifications with the wider MESA community. 

   A tutorial for modifying MESA's source and adding calculations that are then output into the history/profile files can be found `here <https://docs.mesastar.org/en/release-r22.05.1/developing/common_tasks.html#history-profile-output>`_.

   This task is intended to be done collaboratively. Communicate on Slack with others who are working on this. Distribute tasks, such as (a) creating the history column outputs, (b) calling GYRE within MESA, (c) handling the GYRE inlist, and (d) creating an appropriate ``test_suite`` case. Anyone who attempts this task will be credited by name on the pull request. 
