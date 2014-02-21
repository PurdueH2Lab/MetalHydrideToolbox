Purdue Metal Hydride Toolbox
===============================

The Purdue Metal Hydride Toolbox (PMHT) object-oriented MATLAB Toolbox for modeling 
metal hydride thermal systems and hydrogen storage systems. It is tested in
MATLAB R2012a and newer.


Installation
------------------------------
To clone this repository into your Matlab folder (assuming it is at 
`~/Personal/MATLAB`), enter the following commands at a UNIX shell 
(check that you have `git` installed first by typing `which git`):

    cd ~/Personal/MATLAB
    git clone git://github.com/PurdueH2Lab/MetalHydrideToolbox.git
    
To update your versions of the code if you have already cloned the repository:

    cd ~/Personal/MATLAB/MetalHydrideToolbox
    git pull

To install it in Windows you can use the github Windows client to clone the
repository.

To install it on a system where you cannot access git, download the repository
zip file and unzip it to a folder (ideally called MetalHydrideToolbox).


Usage
------------------------------
There is a demonstration script (`Demo.m`) in the `doc` folder which shows
how to use the PMHT in MATLAB. It can be compiled into an html documentation
guide by using the Publish function in MATLAB (open the m-File and click the
Publish button).

You can also access documentation about the MetalHydride object by typing the
following command in the MATLAB Command Window (after adding the PMHT to the
MATLAB path)

    doc MetalHydride

You can also find out more about the `MetalHydride` sub-classes using

    doc Element
    doc KineticsModel
    doc Reference
