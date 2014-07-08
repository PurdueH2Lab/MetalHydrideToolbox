%% Purdue Metal Hydride Toolbox (PMHT) Demonstration and User Guide
%
% This script demonstrates how to load and use metal hydrides from the
% Purdue Metal Hydride Toolbox (PMHT) in MATLAB. It is assumed that you 
% have downloaded or cloned the entire PMHT repository before 
% starting this guide.

%% Part 1 - Purdue Metal Hydride Toolbox File Structure
% The Purdue Metal Hydride Toolbox repository consists of six folders:
%
% * @Element
% * @KineticsModel
% * @MetalHydride
% * @Reference
% * data
% * doc
%
% In this section the relevant components of each folder will be presented.
% Unless you have added the PMHT folder permanently to your MATLAB path,
% you will need to preface all your scripts with a line adding the
% MetalHydrideToolbox folder to your path. If you have cloned or saved
% the repository into your MATLAB user path, this line will be:

addpath(fullfile(fileparts(userpath),'MATLAB','MetalHydrideToolbox'));

%%
%%% 1.1 @Element
% The @Element folder contains the definition of the |Element| class. This
% class contains a periodic table and is used to define alloys (an alloy is
% an array of |Element| objects. You should not need to call the |Element|
% class directly for normal use; the |MetalHydride| class uses the
% |Element| class to read and interpret the alloy compositions listed in
% the |*.mh| files. If you need to add a new element to the periodic table,
% this is where to add it. To see what elements are currently available,
% you can type

Element.ListElements()

%%
%%% 1.2 @KineticsModel
% The @KineticsModel folder contains the definition of the |KineticsModel|
% class, which is used for defining different reaction rate laws that can
% be used by the |MetalHydride| class. As with the |Element| class, you
% should not need to call this directly. The |MetalHydride| class creates
% an instance of a |KineticsModel| upon creation based on the entries in
% the |*.mh| file.
%
% The overall hydriding reaction rate is expressed as a product of three
% terms:
%
% $$\frac{\partial w}{\partial t} = k(T) f_P(P,P_{eq}) f_w(w, w_{max}, P, P_{eq}, T)$$
%
% where $w$ is the weight fraction of hydrogen in the alloy,
%
% $$k(T) = C_a \exp\left(-\frac{E_a}{RT}\right)$$
%
% and the forms of $f_P$ and $f_w$ are selected from a list of options
% based on the input in the |*.mh| file. To see a list of currently
% available forms of $f_P$, use

KineticsModel.ListPFcns()

%%
% and to add new options, modify
% the |pFcnList| variable in |KineticsModel.m|. To use a custom p function,
% you can enter the function directly in the |*.mh| file in valid MATLAB
% syntax, with inputs of |p| and |peq|. For example:
%
%   pFcn:  log(p/peq)^0.25
%
% Each option for $f_w$ must end with the word 'Hydriding' or
% 'Dehydriding'. To show a list of available functions, use

KineticsModel.ListWFcns()

%%
% Further information on how to select these functions is
% included in the section on |*.mh| files. As with the pressure function,
% you can enter a custom function in the |.mh| file in valid MATLAB syntax
% with inputs of |w|, |wmax|, |p|, |peq|, and |T|.
% For example, to adjust the rate into two segments, you could use:
%
%   wFcn:  (w-wmax)*200*(p>2*peq) + (w-wmax)*(p<=2*peq)
%
%%% 1.3 @MetalHydride
% This folder contains the class definition for the |MetalHydride| class,
% which is the largest class in the Metal Hydride MATLAB Toolbox. 
% In addition to storing properties
% and methods related to metal hydrides, this class also contains a number
% of static methods for reading the |*.mh| files which are used by the
% |KineticsModel| and |Reference| classes. You can find out statistics
% about the currently available hydrides with the |PrintStats| function

MetalHydride.PrintStats();

%%
%%% 1.4 @Reference
% This folder contains the definition of the |Reference| class. Like the
% |KineticsModel| and |Element| classes, this should not need to be called
% directly, it is called by the |MetalHydride| class when reading the input
% file reference lists and used when generating the reference list for the
% database summary. If you want to change the format of the references in
% the summary file, you will need to modify |References.m|.
%
%%% 1.5 data
% The |data| folder contains all the metal hydride definition files
% (|*.mh| files). Any file here which is not a |*.mh| file is ignored.
% There is also a |supporting| subfolder in the |data| folder which
% contains a handful of digitized PCI curves for different hydrides which
% can be compared with the PCI model in the |MetalHydride|. Calling the
% |WriteLaTeXSummary| function also generates PDF figures of each PCI
% comparison in the |doc| folder.
%
%%% 1.6 doc
% The |doc| folder contains this Demo file and any automatically generated
% summaries of the hydride database. To create a PDF from the TeX files
% generated by |WriteLaTeXSummary|, use the Makefile by typing |make doc|
% in this folder on a Unix system.
%
%% Part 2 - Formatting of |*.mh| Files
% The metal hydride data used to define hydrides is stored in ASCII |*.mh|
% files saved in the |data| folder. Each file defines a single hydride. The
% files can be edited in any text editor which recognizes UNIX line endings
% (this means you can use the MATLAB editor, Notepad++, gedit, or several 
% others, just not Microsoft Notepad). If you open it in Microsoft Notepad,
% the entire contents of the file will be displayed on one line.
%
% The MH files are named according to their chemical composition, with all
% elemental compositions shown in square brackets, even for unity
% compositions. For example, some file names are:
%
%   La[1]Ni[5].mh
%   Ti[1.01]Cr[1.06]Mn[1].mh
%   Mg[1].mh
%
% This naming convention is not strictly enforced (a file named
% |HydralloyC5.mh| will be read) but it should be used whenever possible to
% avoid duplicate hydride entries make it easy to locate specific hydride
% files. This filename is also used when creating instances of the
% |MetalHydride| class, so the name should be descriptive.
%
% *Note*: Do not include reversible hydrogen in the hydride name. List
% magnesium hydride (MgH2) as Mg.
%
% The contents of the files must be formatted in such a way that the
% |MetalHydride| class can read them. The files consist of entries, 
% formatted like:
%
%  entry name: value   # comments and stuff
%
% The entry name is not case sensitive, but must be immediately followed by
% a colon (|:|) to be recognized. Use an octothorpe (|#|) to indicate where
% comments begin after the value. Whitespace around the value to be read 
% is ignored and can be spaces or tabs. Anything occuring after the first
% octothorpe on a line is ignored.
%
% There are also named sub-sections in the MH files, which are surrounded
% by curly brackets. For example:
%
%  SubSection Name
%  {
%     # line with just a comment
%     entry: value  # comment
%  }
%
% The sub-section names are not case sensitive, but must come on the line
% before the opening |{|. The closing |}| must come after the last entry
% (do not put the |}| on the same line as an entry).
%
% The order of entries and sections in the MH file does not matter. The
% following example file sections show the commonly used order, but it is
% not required. The order of entries can be changed and the order of
% sub-sections can be changed. However, consistency is convenient for
% organization.
%
%%% 2.1 Example MH File - Type and Element Entries
%
% To demonstrate these formatting rules, we will go through the contents of
% |La[1]Ni[5].mh|. The file begins with two required entries which are not
% in a sub-section: |Elements| and |Type|. Many of the MH files also
% have a |Name| entry here, but it is deprecated and is not read by the
% |MetalHydride| class. The hydride name is now generated from the element
% list.
%
%  Elements: [La:1, Ni:5]
%  Type: AB5
% 
% The |Elements| entry must have a list of valid elements between the |[]|
% formatted as |name:value| pairs, with whitespace ignored. For example:
%
%  [name: value, name : value  ,name:value]
%
% Anything entered outside the |[]| is ignored. The element names are
% case-sensitive and use their abbreviated names. To see a list of
% elements currently available, use the |Element.ListElements()| command.
%
% The |Type| entry is a string entry indicating the hydride type. If the type
% is in unknown, the type entry is "Unknown". Common types are "AB5", "AB",
% "AB2", "Mg", "SS" (solid solution), however the entered value does not
% have to be any of these. The type is used to determine default values for
% certain properties if they are not entered in the MH file. In order for a
% hydride to be registered as part of a type, the |Type| entry must be a
% case-insensitive match to the options in
% |@MetalHydride/GetTypeProperty.m|. To see the currently available types
% and their corresponding assumed values, run the |WriteDbSummary| function
% and look in the spreadsheet.
%
%%% 2.2 Example MH File - Thermodynamics (single plateau)
% The first sub-section in the MH file is the |Thermodynamics| section. 
% This contains a number of different required and optional entries. Also
% note in this example how every number has a reference indicated. The full
% reference (in this case, 'Sandrock') is included in the |References|
% sub-section described later.
%
% In this section and all following, the units are indicated in the
% comments. These are *not* read by the parser, so you must enter all
% values in the correct, specified units.
%
%  Thermodynamics
%  {
%      Weight Percent: 1.49   # Sandrock Table 1
% 
%      Dehydriding 
%      { 
%          DH: -30800   # J/mol - Sandrock Table 1
%          DS: -108     # J/mol.K - Sandrock Table 1
%          slope: 0.13  # Sandrock Table 1
%
%          From Isotherms:  False
%      } 
%      Hydriding
%      {
%          ln(Pa/Pd): 0.13  # Sandrock Table 1
%      }
%  }
% 
% Top-level line entries that can go in the |Thermodynamics| sub-section 
% are:
%
% * |Weight Percent| - This is the first storage metric the code looks for
%  and is defined as mass_H / (mass_Metal + mass_H) at full reversible 
%  capacity.
% * |H/M| - This is the hydrogen-to-metal ratio and is only used if the
%  |Weight Percent| entry is missing. This must be a molecular ratio,
%  not an atomic ratio, so |LaNi5H6| would have an H/M = 6 rather than an
%  H/M = 1. If neither |Weight Percent| nor |H/M| are provided an error is
%  generated.
%
% The first sub-section in |Thermodynamics| is |Dehydriding|, which is
% required. Note that all enthalpies and entropies are relative to a common
% reference state (completely desorbed molecular hydrogen and the metal).
% Because of this common reference state, hydriding and dehydriding
% enthalpies and entropies will be of the same sign (almost always
% negative). Whether the reaction is exothermic or endothermic depends on
% the reaction direction. The following entries can go in the 
% |Dehydriding| section:
%
% * |DH| - This is the enthalpy of the dehydriding reaction in J/mol and
% should be negative. This entry is required.
% * |DS| - This is the entropy of the dehydriding reaction in J/mol-K and
% should be negative. This entry is required.
% * |slope| - This is the slope of the hydriding plateau at |Ts|. 
% The slope is from a normalized log plot, so
% it is defined as $\Delta (\ln(P)) / \Delta (w/w_{max})$, with pressure in
% Pa. This entry is optional and uses the default value for the hydride
% type if omitted.
% * |Ts| - This is the temperature the plateau slope is at in Kelvin.
% This entry is optional and defaults to 298 K if omitted.
% * |From Isotherms| - This is a case-insensitive |true| or |false| string
% to indicate whether the values are supported by an isotherm. If omitted,
% it defaults to false, so it is generally not included unless it is true.
%
% The next sub-section in |Thermodynamics| is |Hydriding|. The |Hydriding|
% section is optional and can either be omitted, or left empty if there is
% no |Hydriding| data. The entries that can go into the |Hydriding| section
% are:
%
% * |DH| - This is the enthalpy of the hydriding reaction in J/mol and
% should be negative.
% * |DS| - This is the entropy of the hydriding reaction in J/mol-K and
% should be negative.
% * |ln(Pa/Pd)| - This is the hystersis entry. If |DH| and |DS| are not
% provided, then the hysteresis is used to calculate the hydriding |DH| and
% |DS|. If ommited, the default for the hydride type is used. This can be
% entered in combination with either |DH| or |DS| to calculate the missing
% value, or by itself to use the assumed critical temperature.
% * |T| - This is the temperature the hysteresis (|ln(Pa/Pd)|) value is at. 
% This entry is optional and defaults to 298 K if omitted.
% * |Tc| - This is an optional input of the hydride critical temperature
%  in Kelvin. If it is ommitted and cannot be calculated, the default 
%  value for the hydride type is used.
% * |From Isotherms| - This is a case-insensitive |true| or |false| string
% to indicate whether the values are supported by an isotherm. If omitted,
% it defaults to false, so it is generally not included unless it is true.
%
% The hydriding thermodynamics can be calculated using a number
% of combinations of inputs. The valid combinations of entries
% and their corresponding calculations are listed below. Default values are
% determined based on the hydride type. You cannot enter more than two
% thermodynamic parameters or the problem is over-specified and an error
% will be generated. For each combination, the thermodynamics level, stored
% in |ThermoLevel| indicates the number of parameters used in the
% calculation. Level 2 thermodynamics are fully specified, Level 1 are
% partially specified, and Level 0 are fully assumed.
%
% * |DH| and |DS| - Update |Tc| value (Level 2)
% * |DH| and |ln(Pa/Pd)| - Calculate |DS| then update |Tc| value (Level 2)
% * |DS| and |ln(Pa/Pd)| - Calculate |DH| then update |Tc| value (Level 2)
% * |DH| and |Tc| - Calculate |DS| but do not update |Tc| (Level 2)
% * |DS| and |Tc| - Calculate |DH| but do not update |Tc| (Level 2)
% * |DH| - Use default |ln(Pa/Pd)| and calculate |DS| then update |Tc| 
%          value (Level 1)
% * |DS| - Use default |ln(Pa/Pd)| and calculate |DH| then update |Tc|
%          value (Level 1)
% * |ln(Pa/Pd)| - Use default |Tc| to calculate |DH| and |DS| and do not 
%                 update |Tc| (Level 1)
% * |Tc| - Use default |ln(Pa/Pd)| to calculate |DH| and |DS| and do not 
%          update |Tc| (Level 1)
% * None - Use default |ln(Pa/Pd)| and default |Tc| to calculate |DH| 
%          and |DS| and do not update |Tc| (Level 0)
%
% For all the above thermodynamics calculations, the metal hydride class 
% stores whether entered or assumed values were used in its |TcAssumed|,
% |SlopeAssumed|, and |HysteresisAssumed| fields. A value is considered
% assumed if it is not entered directly and cannot be calculated from
% directly entered values.
%
%%% 2.3 Example MH File - Thermodynamics (multiple plateaus)
% You can also specify thermodynamics for hydrides with multiple plateaus
% in a manner similar to those shown for single plateaus. The rules for
% doing so are similar. An example from YCo3 is:
%
%  Dehydriding
%  {
%      DH: [-55455, -44570, -52540]   # J/mol  Fit to Yamaguchi isotherm
%      DS: [-118.97, -121.2, -176]    # J/mol.K  Fit to Yamaguchi isotherm
%      slope: [NaN, 0, 1]             # Fit to Yamaguchi isotherm
%         
%      centers: [0.13, 0.6, 0.95]   # Fit to Yamaguchi isotherm
%      widths: [0.26, 0.4, 0.1]     # Fit to Yamaguchi isotherm
%      minSpans: [0.08, 0.08]       # Fit to Yamaguchi isotherm
%
%      From Isotherms:  True
%  }
%  Hydriding
%  {
%      Tc: [423, 550, 300]  # Approximated from isotherm fitting
%  }
%
% The format for entering multiple values is to use a comma separated list
% inside square brackets. The rules for multi-plateau systems are:
%
% # You must enter dH and dS for dehydriding and they must have the same
%   number of entries.
% # You must enter the additional fields |centers|, |widths|, and 
%   |minSpans| which are the centers, widths, and minimum joining lengths
%   of each plateau region, in normalized hydrogen capacity units 
%   (so ranging from 0 to 1). They must be in order and the
%   lowest center minus half its width cannot be less than 0, nor the
%   highest center plus half its width be greater than 1. The length of
%   |minSpans| should be 1 less than the number of plateaus, so that 
%   |minSpan(i)| is the minimum span between plateau |i| and |i+1|. The
%   range of the joining span should not exceed the plateau center, so
%   |minSpan/2| should be less than |width/2| for both plateaus it joins.
% # If you enter a lower or upper center whose half-width does not extend
%   to 0 or 1, the hydride capacity is truncated at that new limit.
% # Optional entries, like slope, can have the string 'NaN' for some
%   plateaus, which will use the default value and be treated as assumed.
%   This is particularly relevant for specifying hydriding thermodynamics.
% # The hydriding thermodynamics for each plateau follow the rules from the
%   single plateau section, so no more than two parameters can be specified
%   per plateau and if a plateau is under-specified, default values will be
%   used for closure.
%
% It is possible to specify different combinations of values for hydriding
% by using the 'NaN' entries. For example, the following entry is valid,
% however unlikely, since each plateau has only two parameters defined.
%
%  Hydriding
%  {
%      Tc:        [ NaN,   550,    300]
%      ln(Pa/Pd): [ 0.1,   NaN,    NaN]
%      DS:        [-120,  -115,    NaN]
%      DH:        [ NaN,   NaN, -15000]
%  }
%
% In this case, all three plateaus would be considered fully defined since
% each plateau has exactly two specified values. For multi-plateau systems,
% the reported thermodynamic level is the minimum level from any plateau.
%
% *Note*: While the |centers| and |widths| inputs are primarily useful for
% multi-plateau systems, you can also include them for single-plateau
% hydrides if you want to limit the hydride to a certain plateau. However,
% it is more practical to simply limit the |H/M| or |Weight Percent| to
% match that plateau. This may, however, slightly affect the accuracy of
% the heat capacity calculation.
%
%%% 2.4 Example MH File - Properties
% The next section in the MH file is the |Properties| section, which
% contains thermophysical properties of the hydride. Even if no properties
% are available, the |Properties| sub-section must be present.
%
%  Properties
%  {
%      keff: 0.1   # W/m.K
%      Cp: 355     # J/kg.K
%      rho: 8300   # kg/m^3
%  }
% 
% All three possible property entries (|keff|, |Cp|, and |rho|) are 
% optional, and the default for the hydride type will
% be used if they are omitted. As with the thermodynamics, whether these
% values are assumed is stored in |kEffAssumed|, |CpAssumed|, and
% |rhoAssumed|. The density and specific
% heat are of the pure (non-hydrided) solid metal (not a powder). The
% effective thermal conductivity is of an appropriate powder bed, since
% solid properties are typically less relevant for conductivity.
% Enhancements to thermal conductivity should not be included here.
%
% The |MetalHydride| class calculates a variable specific heat consistent
% with the measurements by Dadson et al. and Fluckieger et al. using the
% formula:
%
% $$C_p(w) = C_{p,metal} \left( 1 + H/M \frac{w}{w_{max}} \right)$$
%
% where H/M here is an atomic ratio, not a molecular ratio (so LaNi5H6
% has an H/M = 1 here). The value read from the |*.mh| file for |Cp| is
% used here for $C_{p,metal}$.
%
%%% 2.5 Example MH File - Kinetics
% The next section in the MH file contains kinetics information. As with
% the |Properties| sub-section, |Kinetics| must be present even if there is
% no kinetics data in it.
%
%  Kinetics
%  {
%      Hydriding
%      {
%          Ca: 50     # 1/s
%          Ea: 20000  # J/mol
% 
%          pFcn: log
%          wFcn: 1st Order
%      }
% 
%      Dehydriding
%      { 
%          Ca: 9.57    # 1/s
%          Ea: 16420   # J/mol
% 
%          pFcn: log(p/peq)^2
%          wFcn: (w-wmax)*12*tanh(p-peq)
%      }
%  }
% 
% All the information in the kinetics section goes into either the
% |Hydriding| or |Dehydriding| sub-sections. Both sub-sections are optional
% and can be omitted if no data is available. If omitted, the default 
% kinetics for the hydride type will be used. The kinetics model is
% implemented as described previously, where the entries for |pFcn| and
% |wFcn| indicate which pressure function and composition functions to use.
% The word "Hydriding" or "Dehydriding" is appended to the entry for
% |wFcn| in order to match those in |KineticsModel| depending on which
% sub-section they are in. To see a list of available options, use
%
%   KineticsModel.ListPFcns();
%   KineticsModel.ListWFcns();
%
% or simply enter a custom function directly, as done for the Dehydriding
% case in the example above.
%
%%% 2.6 Example MH File - Notes
% The notes section is not required and not read by the |MetalHydride|
% class. It is a convenient central location for making relevant notes
% about a hydride. The only thing that should not be typed in the notes
% section are un-matched curly brackets |{}| on non-commented lines
% since this will mess up where
% it thinks the |Notes| section ends.
%
%  Notes
%  {
%     I can type whatever I want
%     # comments do not matter
%     The only illegal thing to type in here are un-matched curly 
%     brackets {} without a comment hash before them
%  }
% 
%%% 2.7 Example MH File - References
% The last section is the references section. This is a required section.
% For best practices, it is also essential that every number in a |*.mh|
% file can be tracked to a published reference. Each reference is a
% sub-section with a descriptive name. Use the name in the comments in the
% file to indicate which reference a number came from. This is not used by
% the |MetalHydride| class, but makes the database entries tracable.
%
%  References
%  {
%      Walker
%      {
%          ID:      1845692705
%          Authors: G. Walker
%          Title:   Solid State Hydrogen Storage: Materials and Chemistry
%          Year:    2008
%          Other:   Woodhead Publishing: Cambridge, England
%      }
% 
%      Sandrock
%      {
%          ID:      10.1016/S0925-8388(99)00384-9
%          Authors: G. Sandrock
%          Title:   A panoramic overview of hydrogen storage alloys from a gas reaction point of view
%          Journal: Journal of Alloys and Compounds
%          Year:    1999
%          Volume:  293-295
%          Pages:   877-888
%      }
%  }
%
% Each reference sub-structure must have the |ID|, |Authors|, |Title|, and
% |Year| entries. Optional additional entries are |Journal|, |Volume|,
% |Pages|, and |Other|. The entry for the |ID| must be unique to that
% reference and used everywhere that reference is used (so it has the same
% |ID| in all the |*.mh| files). For journal papers, it is most convenient
% to use the DOI, since it is unique and also allows quick retrieval of 
% the paper using dx.doi.org/[DOI]. The ISBN is a good option for books.
%
% Hydrides imported from the Sandia database were given IDs of the form
% "SandiaDBRefX" rather than tracking down hundreds of DOIs. Once
% references have been verified, the "SandiaDBRefX" is replaced by the DOI.
%
%%% 2.8 Common "Gotchas" Reading Hydride PCI Data from Papers
% There are a few unfortunately prevalent inconsistencies in the ways of
% presenting metal hydride data in the literature. This section lists some
% common ones to watch out for if you are adding information to an MH file.
%
% # *H/M Definition* - There are two ways of defining the H to M ratio used
%   in the literature. One is H per formula unit (FU), the other is per 
%   metal atom. For example, LaNi5H6 has an H/FU = 6 and an H/M = 1,
%   however in papers both are referred to as "H/M". A good rule of thumb
%   is to see if it exceeds 1 (making it most likely H/FU). Some papers 
%   will even use both metrics within the same paper without distinguishing 
%   them. The value put in the MH file must be the H/FU definition.
% # *Units* - It goes without saying, but pay attention to the units. Some
%   papers report energies in cal and kcal, while others use J and kJ. The
%   numbers in the MH files must all be in J. Pressure units, if used to
%   calculate thermodynamics with the Van't Hoff plot, could be any number
%   of units. All pressures in the database are in Pa.
% # *Molar Designation* - This one is a little tricky. Most papers report
%   enthalpy and entropy per mol-H2, but some report it per mol-H. They
%   will differ by a factor of 2 (a number per mol-H must be multiplied by
%   2 to get a number per mol-H2). All the numbers in the database must 
%   be per mol-H2. Now here's where it gets tricky. Some authors report 
%   numbers whose values are per mol-H2, but call it per mol-H in the unit
%   label (because apparently they think it's the same thing). If you are
%   unsure, the best way to check is to use the numbers in the Van't Hoff
%   equation to calculate Peq and compare it with reported isotherms.
% # *Authors* - Do not include work by V. Sinha, W. Wallace, F. Pourarian,
%   or N. Rajalakshmi without careful verification and confirmation from
%   other references. They published quite a few papers in the late 1980s
%   using what appears to be a seriously flawed experimental
%   technique. All their results produce unusually low enthalpies and have
%   not been repeated by those who have tried (and multiple authors have 
%   tried). All the results by Sinha were excluded. Some of the results by
%   Pourarian appear reasonable and have been left in, but always apply
%   extra scrutiny to papers by these authors and see if there are very
%   similar hydrides in the database or in other papers you can compare 
%   with.
%

%% Part 3 - Using the MetalHydride Class
% Before going through this section read the documentation on the 
% |MetalHydride| class by typing
%
%   doc MetalHydride
%
% in the command window to see a complete list of available functions and
% properties.
%
% Start this demo with a clean workspace and command window.
clear all
close all
clc
%%
% *Creating Hydrides*
%
% There are two ways to load metal hydrides from the hydride database:
% either one at a time or all at once.
% To load them one at a time, call the |MetalHydride| constructor function
% with the MH file name string as the input, with or without the
% |*.mh| extension, as

A = MetalHydride('La[1]Ni[5].mh');
B = MetalHydride('Ti[1.01]Cr[1.06]Mn[1]');

%%
% If you want to perform operations on all the hydrides in the database,
% you can use the |LoadDatabase| static function to get an array of all the
% hydrides.

hydrides = MetalHydride.LoadDatabase();

%%
% *Extracting Hydride Array Subsets*
%
% Once the hydride database is loaded, you can use logical indexing to
% easily extract specific sub-sets of the database for analysis. For
% example, to get a list of what hydride types are currently in the
% database, use

unique({hydrides.Type})

%%
% or to extract all the 'AB5' hydrides, use logical indexing with |strcmpi|,
% or using the |IsType| function

AB5 = hydrides( strcmpi({hydrides.Type},'AB5') );
AB5 = hydrides( hydrides.IsType('AB5') );

%%
% These type of statements can be combined based on other criteria too,
% for example, to get all AB5 hydrides with fully defined thermodynamics,
% you can use

AB5full = hydrides( hydrides.IsType('AB5') & [hydrides.ThermoLevel] == 2);

%%
% *Comparing Hydrides*
%
% To compare the alloy composition of two hydrides, you can use the
% |SimilarTo| operator in the |MetalHydride| class. This function
% returns the average difference in elemental composition between two
% alloys (alloys are arrays of |Element| objects).
% A low difference value means the alloys have similar elemental
% composition. For example:

HydA = MetalHydride('La[1]Ni[5]');
HydB = MetalHydride('Ti[1.01]Cr[1.06]Mn[1]');
HydC = MetalHydride('La[1]Ni[4.9]Al[0.1]');
HydD = MetalHydride('Ti[1]Cr[1]Mn[0.8]');

fprintf('A and B -> %f\n',HydA.SimilarTo(HydB));
fprintf('A and C -> %f\n',HydA.SimilarTo(HydC));
fprintf('B and D -> %f\n',HydB.SimilarTo(HydD));
fprintf('A and D -> %f\n',HydA.SimilarTo(HydD));

%%
% *Plotting Hydrides*
%
% Once you have created some metal hydrides, you can access their
% properties and methods. To plot a metal hydride's thermodynamics, you can
% use its built-in plot function to make a set of PCI curves and 
% Van't Hoff plot. See the documentation (|doc MetalHydride|) to see
% available input options for this function

B.plot([300 400],5); % Plot 5 temperatures from 300 to 400 K

%%
% or you can use the |Peq| function to make the plot manually or do other
% calculations.

w = linspace(0,A.wMax*0.9,500);
T = [300 350 400];
colors = jet(length(T)*5);

figure;
set(gcf,'Units','Inches','Position',[2 2 5 4]);
hold on
h = zeros(size(T));
for i = 1:length(T)
    h(i) = plot(w.*100, A.Peq(T(i), w, 'abs')./1e5,...
        'Line','-','Color',colors(i*5,:),'LineWidth',1.5,...
        'DisplayName',num2str(T(i),'%3.0f K'));
    plot(w.*100, A.Peq(T(i), w, 'des')./1e5,...
        'Line','--','Color',colors(i*5,:),'LineWidth',1.5);
end
set(gca,'Box','on','LineWidth',1);
lh = legend(h,'Location','NorthWest');
set(lh,'Box','off');
xlabel('w_H / w_M (%)')
ylabel('P (bar)')

%%
% If the hydride has PCI curves available in the data/supporting folder,
% you can plot the |Peq| model with the PCI data using the |ComparePCI|
% function (which can return the figure handle and the DOI of the reference
% the PCI data is from).

A.ComparePCI();

%%
% *Solving ODEs with Hydride Rate Functions*
%
% You can use the hydride's reaction rate function and heating rate
% function with one of MATLAB's ODE
% solvers to calculate the non-isothermal reaction rate over time

Ti = 300; % Initial and coolant temperature (K)
P = 4*A.Peq(Ti, A.wMax*0.5, 'abs'); % Constant gas pressure (Pa)
Uth = 100000; % Thermal conductance (W/K)

% y = [w; T]
dydt = @(t,y) [A.dwdt(y(2),P,y(1)); ...
               (A.dEdt(y(2),P,y(1)) + Uth/A.rho*(Ti - y(2)))/A.Cp(y(1))];

[t,y] = ode15s(dydt,[0 1500],[0.02*A.wMax Ti]);

figure;
set(gcf,'Units','Inches','Position',[2 2 5 4])
[ax,h1,h2] = plotyy(t./60,y(:,1).*100,t./60,y(:,2));
set([h1; h2],'LineWidth',2);
xlabel(ax(1),'Time (min)')
ylabel(ax(1),'w_H / w_M (%)')
ylabel(ax(2),'T (K)')

%%
% *Searching the Hydride Array*
%
% The equality operator is defined for the |MetalHydride| class, so you can
% use the built-in |find| function

Aid = find(hydrides == A); % Locate hydride A in the array

%%
% It is also overloaded to accept a string as an input to the equality
% operator, so you can find hydrides by name too

Bid = find(hydrides == 'Ti1.01Cr1.06Mn'); % Locate TiCrMn by name

%%
% *Displaying Hydrides*
%
% The |MetalHydride| class also defines the |disp| function, which displays
% the hydride name. This works on arrays too, so you can more easily see 
% the array contents. For example:

A
hydrides(1:10)

%%
% *Using Null Hydrides*
%
% Null hydrides can be created by making a |MetalHydride| which is not
% linked to an |*.mh| file, but if you try to call
% most methods it will generate an error. Allowing null
% hydrides enables several built-in MATLAB functionalities. For instance,
% you can pre-populate arrays automatically

hyArray(5,1) = A

%%
% As you can see, the other entries of the array were filled with empty
% hydrides. You can check for null hydrides using |isnan| or |empty|.

N = MetalHydride()
isnan(N)
empty(N)

try
    N.Peq(300,5e5,'abs')
catch err
    disp(err)
end

%%
% Because many of its entries are empty, the null hydride also uses
% less memory

whos A N hyArray hydrides

%%
% *Calling Hydride Functions on Arrays of Hydrides*
%
% In general, these features let you use metal hydrides like you would any
% other data type in MATLAB, using as many of the built-in features as
% possible.
%
% For instance, you can call most hydride functions on an entire array of
% hydrides. To demonstrate, we'll use a subset of the |hydrides| array. Not
% all functions are compatible with this calling mode. More complex
% functions, or functions which return arrays from single hydrides are not
% supported (for example, |Peq|, |Teq|, |dwdt|, |dEdt|, |tau|, and 
% |RxnRate| are not supported).

smh = hydrides(1:5)          % Get a small subset of hydrides to demonstrate
CpM = smh.Cp                 % Find the Cp of the metal
Cps = smh.Cp([smh.wMax]./2)  % Find the Cp of the hydride at 50% capacity
HasLa = smh.HasElement('La') % Check which hydrides have La
IsAB5 = smh.IsType('AB5')    % Check which hydrides are AB5

%%
% *Getting Subsets based on Alloy Composition*
%
% You can use these features to further subset the hydride array, for
% example, to get all hydrides with La, or all the hydrides without Ti, you
% could do

LaHydrides = hydrides( hydrides.HasElement('La') );
NoTiHydrides = hydrides( ~hydrides.HasElement('Ti') );

%%
% *Getting Type Statistics*
%
% You can determine properties of hydride subsets using a similar method.
% To find the distribution of non-assumed slopes of all AB2 hydrides, 
% you can do

AB2 = hydrides( hydrides.IsType('AB2') & ~[hydrides.SlopeAssumed] & [hydrides.NumPlateaus] == 1);
AB2slopes = [AB2.Slope];

figure;
histfit(AB2slopes(AB2slopes>0),10,'lognormal')
xlim([0 4])
xlabel('AB_2 Slope')
ylabel('Count')

%%
% *Dealing with Multi-Plateau Hydrides
%
% Using logical indexing can result in errors for multi-plateau hydrides.
% To re-do the analysis above of AB2 hydride slopes, using the mean slope
% for multi-plateau hydrides, you can use a cell and cellfun, as

AB2 = hydrides( hydrides.IsType('AB2') & ~[hydrides.SlopeAssumed]);
AB2slopes = cellfun(@mean,{AB2.Slope});

figure;
histfit(AB2slopes(AB2slopes>0),10,'lognormal')
xlim([0 4])
xlabel('AB_2 Slope')
ylabel('Count')


%%
% *Generating the Database Summary Files*
%
% You can use the |WriteExcelSummary| and |WriteLaTeXSummary| static 
% function to write an Excel sheet and references text file, or TeX source
% files from the full database. This database summary shows direct 
% (non-assumed) values and is useful for generating appendices or 
% looking through the database information in a compact format. 
% The reference numbers in the Excel sheet correspond to
% those in the references text file.

MetalHydride.WriteExcelSummary();
MetalHydride.WriteLaTeXSummary();
