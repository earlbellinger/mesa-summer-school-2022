###############################
Asteroseismology Across the HRD
###############################

Tutorial for the `2022 MESA Summer School <https://mesahub.github.io/summer-school-2022/>`_ at UC Santa Barbara, given by `Earl Bellinger <https://www.earlbellinger.com>`_ on August 11. 

This series of labs teaches how to extend MESA in order to do stellar pulsation calculations with GYRE. The test-case is evolving a solar-type star from the main sequence through to the red giant branch phase and observing the emergence and evolution of mixed oscillation modes (see Supplementary Materials below for background information). 

This tutorial involves editing the Fortran ``run_star_extras.f90`` file in order to call GYRE on every stellar model. For a tutorial based on post-processing of stellar models e.g. in Python, see this `tutorial <https://github.com/earlbellinger/mesa-gyre-tutorial-2022>`_ that I gave at the annual asteroseismology meeting. 

.. toctree::
   :maxdepth: 2
   :caption: Contents

   minilab-1
   minilab-2
   minilab-3
   maxilab
   supplementary
   
