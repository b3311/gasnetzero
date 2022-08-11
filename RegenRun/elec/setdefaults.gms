* ====================== setdefaults.gms <begin> ================================
* Control parameter defaults (separate include file)

* Scenario definition
$if not set basescen      $setglobal basescen      %scen%    !! The integrated model scenario (basescen) should be equal to the current scenario (scen) except for static runs starting from the results of an integrated run
* basesceniter option - if set to yes, then basescen is used only if enduse model input files for %scen% do not exist
* this allows a sensitivity case to start based on an existing run but use the new run for subsequent iterations
$if set basesceniter $if exist %elecdata%\enduse_%scen%.gdx $setglobal basescen %scen%

* Static Model Controls
$if not set static        $setglobal static        no        !! If set to a year, runs static model for that year (default is no)
$if not set dynfx         $setglobal dynfx         no        !! If set to yes, uses capacity from dynamic model solution in the static model (need to set dynfx_scen in elecsub)
$if not set gdynfx        $setglobal gdynfx        no        !! If set to yes, uses storage capacity from dynamic model solution in the static model (need to set dynfx_scen in elecsub)
$if not set dispatch8760  $setglobal dispatch8760  no        !! Combined switch for static + dynfx + seg=8760
* Control Variable dispatch8760 -> This is set to the year in dynamic model run that you want to run in static 8760 mode
* Turning this on also turns on dynfx and storage by default
$ifthen not %dispatch8760%==no
$setglobal static %dispatch8760%
$setglobal dynfx  yes
$setglobal seg    8760
$setglobal storage yes
$endif

* Dynamic Model Chronology Controls
$if not set moreyrs       $setglobal moreyrs       no        !! Adds years 2055-2075 to the model
* In some cases need to use %tbase% rather than the set tbase(t) to ensure compatibility with static mode
$if not set tbase         $setglobal  tbase         2015
$if not set ptcv          $setglobal ptcv          yes       !! Post terminal capital value
$if not %static%==no      $setglobal ptcv          no        !! Turn off ptcv in static mode

* General Economic Assumptions
$if not set drate         $setglobal drate         0.07      !! Discount rate
$if not set capr          $setglobal capr          0.07      !! Capital charge rate (applies only in static model)
$if not set pelas         $setglobal pelas         0         !! Price elasticity of demand - should be 0 or negative
$if not set gelas         $setglobal gelas         0         !! Price elasticity of gas supply - should be 0 or positive
$if not set tk            $setglobal tk            0.2       !! Investment tax rate

* Load/Fuel Price Assumptions for Standalone Electric Model
$if not set baseline      $setglobal baseline      no        !! Sets both load and fuel prices from the same source
$if not %baseline%==no    $setglobal baseline_pf   %baseline%
$if not %baseline%==no    $setglobal baseline_ld   %baseline%
$if not set baseline_pf   $setglobal baseline_pf   aeo2020   !! Sets fuel prices
$if not set baseline_ld   $setglobal baseline_ld   aeo2017   !! Sets load if not using the end-use model
$if not set pf_shock      $setglobal pf_shock      no        !! Combine with fixIX for a fuel price shock at time fixIX
$if not set flatgas       $setglobal flatgas       no        !! Override natual gas price path with a specific number in $ per mmbtu (flat through time)
$if not set reserve       $setglobal reserve       yes       !! Set to 'no' to turn off reserve margins
$if not set rsvmarg       $setglobal rsvmarg       0.07      !! Code is set up to use the same reserve margin for all regions.  Could easily overwrite.
$if not set bs            $setglobal bs            yes       !! Backstop (demand response) turned on.  Alternative is 'no'

* Technology Assumptions
$if not set tlc           $setglobal tlc           ref       !! Technology Learning Curves are currently only defined for 'ref'
$if not set rnwtlc        $setglobal rnwtlc        ref       !! Renewable Technology Learning Curves default to 'ref' - alternatives are currently abt* scenarios
$if not set batttlc       $setglobal batttlc       ref       !! Battery Technology Learning Curves default to 'ref' - alternatives are currently opt, pess, and abt* scenarios
$if not set nccost        $setglobal nccost        no        !! Nuclear public costs - default is 'no', alternative is 'yes'
$if not set advnuc	  $setglobal advnuc	   no        !! Advanced nuclear technology with optimistic cost declines - set to 'yes' to make available
$if not set drcost        $setglobal drcost        50000
$if not set windcfadj     $setglobal windcfadj     1         !! Allows the modeler to scale the capacity factors of wind
$if not set windcstadj    $setglobal windcstadj    1         !! Allows the modeler to scale the capital costs of wind
$if not set solcstadj     $setglobal solcstadj     1         !! Allows the modeler to scale the capital costs of solar
$if not set orvre         $setglobal orvre         0.1       !! Operating reserve requirement for variable renewable output
$if not set tdc           $setglobal tdc             tdc_md    !! T&D cost scenarios (for adder to renewables)
$if not set y_shp         $setglobal y_shp         2015      !! Representative year for wind solar load shapes
* Storage assumptions
$if not set storcost      $setglobal storcost      1500      !! Utility-scale bulk storage cost ($ per kW)
$if not set caescost      $setglobal caescost      1500      !! Compressed air energy storage ($ per kW)
$if not set roomsize      $setglobal roomsize      8         !! Hours duration for generic bulk storage
$if not set battlife      $setglobal battlife      20        !! Battery investment lifetime in years


* Restriction on New Additions and Retirements
$if not set usinvscn      $setglobal usinvscn      full      !! Alternatives include 'greater' 'lesser' and others defined in the upstream
$if not set xcllife       $setglobal xcllife       default   !! Existing coal lifetimes - specify a lifetime in years or use 'default' to inherit upstream defaults
$if not set nonewcoal     $setglobal nonewcoal     2015      !! This is the year after which no new coal without CCS can be built
$if not set nonewgas      $setglobal nonewgas      2080      !! This is the year after which no new NGGCs without CCS can be built
$if not set ccslim        $setglobal ccslim        no        !! Turns off all CCS technologies if set to 'yes'
$if not set nuc60         $setglobal nuc60         no        !! Set to 'yes' to set all existing nuclear unit lifetimes to 60 years (or planned retirement if earlier)
$if not set nuclim        $setglobal nuclim        no
$if not set allowtrans    $setglobal allowtrans    yes       !! Set to no to fix transmission as exogenous in the static model
$if not set tuslimscn     $setglobal tuslimscn     lesser    !! Alternatives include 'unlim'
$if not set tlimscn       $setglobal tlimscn       evn       !! Alternatives include 'unlim'
$if not set notrn         $setglobal notrn         no        !! Set to 'yes' to turn off all new transmission investments
$if not set texasent      $setglobal texasent      no        !! Restricts transmission additions in and out of Texas to 1 GW per period (Entergy thinks it should be zero)
$if not set fltc	  $setglobal fltc	   0	     !! Additional transmission allowance into Florida in 2035 for feasibility in high renewables cases
$if not set storage       $setglobal storage       no        !! In static mode this is set to 'yes' by default
$if not set cspstorage    $setglobal cspstorage    no        !! CSP thermal storage turned off by default (only turn on with static model)
$if not set stortgt       $setglobal stortgt       0
$if not set fixghours     $setglobal fixghours     no        !! Fixes storage hours (relative size of room and door)
$if not set fixIX         $setglobal fixIX         no        !! Fixes generation and transmission investments up to the year specified by fixIX
$if not set pssm          $setglobal pssm          no        !! Approximate state space matrix for rep hours chronology to model storage is off by default
$if not set nodac	  $setglobal nodac	   no	     !! Turn off DAC - default is 'no', alternative is 'yes'
$if not set iendbecs	  $setglobal iendbecs	   no	     

* Restriction on Flexibility of dispatch
$if not set free          $setglobal free          no        !! Set to yes to make all generation dispatchable
$if not set nucxmin	  $setglobal nucxmin	   0.7	     !! Minimum dispatch factor for existing nuclear (between 0 and 1 converts to 0 after 2030)

* Energy Efficiency
$if not set enee          $setglobal enee          no        !! Endogenous energy efficiency is turned off by default

* CO2 policies section
$if not set cap           $setglobal cap           none      !! Set to a name (e.g. cap80) corresponding to a target defined in policydata.xlsx to implement a U.S. wide CO2 cap
$if not set cap_rg        $setglobal cap_rg        none      !! No regional caps used by default
$if not set nco2          $setglobal nco2          no
$if not set nco2name      $setglobal nco2name      ref
$if not set bank          $setglobal bank          no
$if not set borrow        $setglobal borrow        no
$if not set CA_AB32       $setglobal CA_AB32       yes       !! Set to 'no' to turn off AB32
$if not set CA_SB100      $setglobal CA_SB100      yes       !! Set to 'no' to turn off SB100
$if not set NY_SB6599     $setglobal NY_SB6599     yes       !! Set to 'no' to turn off SB6599 (NY zero electric sector CO2 by 2040)
$if not set RGGI          $setglobal RGGI          yes       !! RGGI is turned on by default.  Alternative is 'off'
$if not set becslim       $setglobal becslim       no
$if not set ctaxrate      $setglobal ctaxrate      %drate%   !! use discount rate as default growth rate for carbon tax
$if not set svpr          $setglobal svpr          no        !! Safety valve price
$if not set co2auction    $setglobal co2auction    yes       !! Only used in report
$if not set compreg_ces_test $setglobal compreg_ces_test no  !! Only used in report

* Additional Calibration
$if not set calibrate48   $setglobal calibrate48   no

* RPS and CES section
$if not set rps           $setglobal rps           none        !! Federal RPS constraint ('none' by default, otherwise specify scenario targets to use per upstream policydata.xlsx spreadsheet)
$if not set rps_full	  $setglobal rps_full	   none	       !! Federal RPS constraint forcing fully renewable generation
$if not set srps          $setglobal srps          yes         !! Existing state RPS constraints (choose 'no' or 'yes') - includes offshore wind mandates
$if not %dispatch8760%==no $if not %i_end%==yes $setglobal srps no
$if not set ces           $setglobal ces           none        !! Federal CES constraint ('none' by default, otherwise specify scenario targets to use per upstream policydata.xlsx and policy.gms)
$if not set cestrd        $setglobal cestrd        usa         !! Set to 'reg' for no CES credit trading or 'usa' for national CES credit trading
$if not set cestax        $setglobal cestax        no
$if not set cesb_qual     $setglobal cesb_qual     no          !! cesb_qual can be eliminated - keep it for now
$if not set cesacp        $setglobal cesacp        no          !! Sets a minimum alternative compliance payment price for CES if not set to 'no'
$if not set cesbnk        $setglobal cesbnk        no          !! Set to yes to turn on CES credit banking

* Other policy assumptions
$if not set noncap        $setglobal noncap        csapr       !! Alternative is 'none'
$if not set ozone         $setglobal ozone         no
$if not set itc           $setglobal itc           yes         !! Investment tax credit for solar and geothermal - alternative is 'no'
$if not set ptc           $setglobal ptc           yes         !! Production tax credit for wind - alternative is 'no'
$if not set cred45q       $setglobal cred45q       yes         !! 45Q CO2 subsidy - alternative is 'no'
$if not set nuczec        $setglobal nuczec        yes         !! Set to 'no' to turn off state nuclear subsidies (modeled as a constraint on retiring)

* Benchmark and Pricing Assumptions Section
$if not set macrocalib    $setglobal macrocalib    no
$if not set retail        $setglobal retail        mix

* Cost assumptions not often modified
$if not set fsmv          $setglobal fsmv          jun11o      !! Alternatives include jun11r - see upstream
$if not set biocpscn      $setglobal biocpscn      ref
$if not set credit_bio    $setglobal credit_bio    1
$if not set ngcapadj      $setglobal ngcapadj      1
$if not set ccscost       $setglobal ccscost       1           !! New coal CCS capital cost multiplier
$if not set ngadder       $setglobal ngadder       0      

* Legacy control parameters not often modified
$if not set flatdemand    $setglobal flatdemand    no
$if not set allownewwind  $setglobal allownewwind  no
$if not set allowfoswin   $setglobal allowfoswin   no
$if not set allowall      $setglobal allowall      no
$if not set irrclass      $setglobal irrclass      no
$if not set irr           $setglobal irr           inf
$if not set crb4          $setglobal crb4          no
$if not set nocr          $setglobal nocr          no
$if not set opres         $setglobal opres         no
$if not set baseyronly    $setglobal baseyronly    no          !! Set to 'yes' to run only the base year
$if not set cfadj         $setglobal cfadj         no          !! Adjusts the availability factors of variable technologies to better match the hourly data

$if not set ngplsteps     $setglobal ngplsteps     s2
$if "%ngplsteps%"=="s1"   $setglobal refstep       ngp7
$if "%ngplsteps%"=="s2"   $setglobal refstep       ngp7
$if not set dismin        $setglobal dismin        no
$if not set fomx0         $setglobal fomx0         no
$if not set rpt           $setglobal rpt           no
$if not set noclec        $setglobal noclec        no


* ====================== setdefaults.gms <end> ================================
