.. _maxilab:

******************************************
MaxiLab: Exploring Mixed Oscillation Modes
******************************************

Overview
========

TODO

As the very first step, make a copy of your working directory from
:ref:`MiniLab 3 <minilab-3>` (with all the changes you have made):

.. code-block:: console

   $ cp -a townsend-2019-mini-3 townsend-2019-maxi
   $ cd townsend-2019-maxi

Alternatively, if you were unable to get things working with
:ref:`MiniLab 3 <minilab-3>`, then you can grab a working directory
for the MaxiLab from `here
<https://github.com/earlbellinger/mesa-summer-school-2022/blob/main/work-dirs/bellinger-2022-mini-3-solution.tar.gz>`__.

Mapping the Instability Strip
=============================

As the final part of the MaxiLab, we're going to use GYRE and MESA to
map out the extent of the "mixed mode" instability strip for
dipole modes. This will involve repeating the evolution for a range of
different stellar masses, and noting where the dipole mode closest to 
:math`\nu_\max`. To speed things
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

The first step is for each student to pick a (different) mass.

.. admonition:: Exercise

   Visit the Google spreadsheet `here
   <https://docs.google.com/spreadsheets/d/1c3WuXlwzN944kdXWkwg7bO526MdZxiZeHAC4iK4T0NA/edit?usp=sharing>`__,
   and claim a row (identified by a unique *Task Index* number) by
   entering your name to the *Name* column. Make a note of the
   mass listed in the *Stellar Mass* column.

Determining Boundaries
----------------------

The next step is to perform the calculation and record the instability
strip boundaries.

.. admonition:: Exercise

   Modify ``inlist_project`` in your working directory, 
   to set the initial stellar mass to your
   assigned value. Then, repeat the pre-main sequence to ZAMS run
   (don't forget to do this!), followed by the ZAMS-to-TAMS
   run. During the latter, note down the log effective temperature
   :math:`\log T_{\rm eff}/{\rm K}` and log luminosity :math:`\log
   L/{\rm L_{\odot}}` where either the F or 1-O mode first becomes unstable
   (you can do this by inspecting the terminal output, or by analyzing
   the ``history.data`` file after the run). Note the corresponding
   values when both modes again become stable. Enter these data in the
   appropriate *Solar Metallicity* columns of the spreadsheet. **Be
   sure to enter logarithmic values, and use 3 decimal places**.

For some choices of stellar mass, there can be multiple boundaries; if
you encounter this situation for your assigned stellar mass, then
enter the first boundary (where either mode first becomes unstable)
and last boundary (when both modes become stable) into the
spreadsheet.

.. admonition:: *Optional* Exercise

   If you're feeling bold, see if you can increase the precision with
   which the boundaries are determined. One approach is to modify the
   ``extras_check_model`` hook, to retry the step with a reduced
   timestep when a transition from stable to unstable (or vice versa)
   is detected. See `this
   <http://www.astro.wisc.edu/~townsend/resource/teaching/mesa-summer-school-2019/run_star_extras_adaptive.f90>`__
   ``run_star_extras.f90`` file for an example implementation of this
   adaptive timestepping approach.

When all the data are collected, we'll combine them to create a map of
the instability strip boundaries in the Hertzsprung-Russell diagram.

Exploring Metallicity Effects
-----------------------------

Since the instability of :math:`\beta` Cephei stars is driven by iron
and nickel opacity, we can expect it to be sensitive to metallicity
:math:`Z`. We'll finish up the maxilab by exploring how our
instability strip changes for different :math:`Z`.

.. admonition:: Exercise

   Repeat your calculation from the previous step, for metallicities
   of 75% solar (:math:`Z = 0.01065`) and 50% solar (:math:`Z =
   0.0071`). Enter the results in the appropriate columns of the
   spreadsheet.

During these calculations, be sure to look for changes in the
iron-bump opacity peak resulting from the reduced metallicity.
