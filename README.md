Purdue Metal Hydride Toolbox
===============================

The Purdue Metal Hydride Toolbox (PMHT) is an object-oriented MATLAB Toolbox for modeling 
metal hydride thermal systems and hydrogen storage systems. It is tested in
MATLAB R2012a and newer.


Installation
------------------------------

### Using SSH or Linux (recommended)
To clone this repository into your Matlab folder (assuming it is at 
`~/Personal/MATLAB`), enter the following commands at a UNIX shell 
(check that you have `git` installed first by typing `which git`):

    cd ~/Personal/MATLAB
    git clone git://github.com/PurdueH2Lab/MetalHydrideToolbox.git
    
Note: if you are a developer (and want to be able to push changes to this repository),
use the following notation instead:

    git clone git@github.com/PurdueH2Lab/MetalHydrideToolbox.git
    
To update your versions of the code if you have already cloned the repository:

    cd ~/Personal/MATLAB/MetalHydrideToolbox
    git pull

To have the MatlabCEA folder added to your Matlab path by default, add the
following line to your `startup.m` file in your default Matlab path (create
`startup.m` if it does not exist):
    
    addpath(fullfile(fileparts(userpath),'MATLAB','MetalHydrideToolbox'));

### Using the GitHub Windows Client
Download [GitHub for Windows](http://windows.github.com) and install it. Click
the Clone in Desktop button on the right
to clone this repository onto your local machine. The repository will be saved 
in your `GitHub` folder by default.

To update your version of the code, use the 'Sync' button in the GitHub program.

To have the MetalHydrideToolbox folder added to your Matlab path by default, add the
following line to your `startup.m` file in your default Matlab path (create
`startup.m` if it does not exist):
    
    addpath(fullfile(fileparts(userpath),'GitHub','MetalHydrideToolbox'));

### Using the Source Download
Download the [source zip file](https://github.com/PurdueH2Lab/MetalHydrideToolbox/archive/master.zip). 
Extract its contents to your default Matlab folder and rename the newly created 
`MetalHydrideToolbox-master` folder to `MetalHydrideToolbox`.

To update your version of the code, delete the existing `MetalHydrideToolbox` folder and
repeat the above procedure.

To have the MetalHydrideToolbox folder added to your Matlab path by default, add the
following line to your `startup.m` file in your default Matlab path (create
`startup.m` if it does not exist):
    
    addpath(fullfile(fileparts(userpath),'MATLAB','MetalHydrideToolbox'));
    


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
