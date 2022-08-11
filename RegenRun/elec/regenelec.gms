* File regenelec.gms

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* US-REGEN electric sector model

* This is a partial equilibrium model of dispatch and new investment based on
* existing unit characteristics and hourly wind and load data.  Several modes
* of operation can be specified.

* - Stand-alone format or as an iterative step with the US-REGEN macro model.
* - Dynamic or static for a given year.
* - In static mode, new capacity can be "rented" or capacity can be fixed to
*   levels determined by optimal investment in a corresponding dynamic run.

* The scope is the US 2015 to 2050.  For dynamic runs, individual time periods
* can be specified directly in this code (maximum resolution is annual).

* The US is grouped into regions, which are interpreted as electricity
* markets.  The regions are state-based. There is trade between regions
* limited by aggregate inter-region transmission link capacity, which can be
* expanded (if desired).


* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Cause dollar statements to appear in lst file
$ondollar
* Set EOL comment indicator to the default of !!
$oneolcom
* Set global directory names (%elecdata% etc)
$include %sysenv.runutil%\setglobals
* Set code version (please do not use '.' in the version name)
$set codeversion 20210322
* Set titles
$set titlelead "Standalone %scen% electric model using REGEN v.%codeversion%"

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Control parameter defaults

* This section is now in a separate include file so it can be accessed
* by elecrpt after a restart with the same switch values

$include setdefaults.gms

put putscr;
$setlocal marker "%titlelead% setup"
put_utility  "title" / "%marker%" /  "msg" / "==== %marker% ====" /  "msg" / " " /;

* Suppress listing of equations and variables in lst file
option limrow=0;
option limcol=0;
* Suppress solution listing in lst file
option solprint=off;
* Include information about execution time and memory use in lst file
*option profile=3;
* Include status report from solver in lst file
option sysout=on;
* Display system resources information
option profile=1;

$show

* * * * * * * * * * * * Set and Parameter Declarations and Data Load * * * * * * * * * * * * * * *

set     intorder        / 0*10000 /;
set
        s               Load segments
        m               Months /1*12/
        tfull           Full set of time periods
        v               Full set of vintages of generation capacity
        vbase(v)        First vintage for existing capacity and anything older
        newv(v)         New vintages
        acv(v)          Active vintages (omits skipped time periods)
;

$gdxin %elecdata%\modeldata_gen.gdx
$load tfull=t, v=vfinal, vbase

newv(v) = yes$(not vbase(v)) ;

set

        t_all           All possible time periods used in the model /
                        2015,2020,2025,2030,2035,2040,2045
                        2050,2055,2060,2065,2070,2075,2080,2085,2090
                        2095,2100,2105,2110,2115,2120,2125,2130,2135
                        2140,2145,2150,2155,2160,2165,2170,2175
                        /

$iftheni not %static%==no
*       In static mode, a single time period is specified by the user
        t(t_all)        Time periods /%static%/
        vstatic(v)      Static vintage
        tbase(t)        Base year /%static%/
$else
*       In dynamic mode, time periods included in model are identified here
$iftheni.onlybase %baseyronly%==yes
        t(t_all)        Time periods /2015/
$else.onlybase
        t(t_all)        Time periods /
                                     2015,2020,2025,2030,2035,2040,2045,2050
$ifi %moreyrs%==yes                  2055,2060,2065,2070,2075
                                     /
$endif.onlybase
        tbase(t)        Base year    /2015/
        tbase_all(t_all) Extended time horizon base year /2015/
$endif
        sm(s,m,t)       Map between segments and months for assembling availability factors
        tv(t_all,v)     Time period in which vintage v is installed
        vt(v,t)         Vintages active in time period t
        vt_all(v,t_all) Vintages active in extended time periods

        i               Generating units (capacity blocks)
        type            Capacity types
        tech            Technologies
        xcl(type)       Types of existing coal
        class           Classes of capacity
        idef(i,type)    Map from capacity blocks to types
        itech(i,tech)   Map from capacity blocks to technologies
        iclass(i,type,class)  Map to capacity classes
        dspt(i)         Dispatched capacity blocks
        sol(i)          Solar technologies
        cspi(i)         Concentrated solar thermal capacity blocks
        dspt_min(i)     Dispatched blocks subject to minimum dispatch
        ndsp(i)         Non-Dispatched capacity blocks
        new(i)          New vintage technologies
        xtech(i)        Existing technologies in use in base year
        cr(i)           Coal retrofit technologies
        cof(i)          Co-firing technologies
        crmap(cr,i)     Underlying capacity block for coal retrofits
        cofmap(cof,i)   Underlying capacity block for co-fire mode
        stage2(cr)      Second stage retrofit capacity blocks
        irnw(i)         Intermittent renewable technologies
        nuc(i)          Nuclear generation technologies
        ccs(i)          CCS generation technologies
        nrps(i)         Technologies not included in federal RPS denominator
        nces(i)         Technologies not included in CES denominator
        i_end(i)        Capacity blocks for which new rental capacity is endogenous in endogenous static mode
        iv_fix(i,v)     Capacity blocks and vintages for which capacity is fixed in endogenous static mode
        ir              Intermittent percentage classes
        nc              Nuclear share classes
        r               Regions
        reg(r)          Cost of service regulation regions
        csp_r(r)        Regions that can support concentrated solar power
        sb100(r)        Regions adjacent to California with SB-100 eligible resources
        nys_r(r)        Regions wholly included within New York state
        rpt             Final four reporting regions
        xrpt(rpt,r)     Map to final four regions
        f               Fuels
        db              Dedicated biomass supply classes
        cp              Carbon price scenario for biomass cost
        j               Storage technologies /hyps-x,bulk,caes,li-ion/
        batt(j)         Battery storage technologies /li-ion/
        jold            Old storage technologies
        ssm(s,s,t)      State space matrix approximating chronology between segments
        pol             Pollutants /co2,so2,nox,ch4,n2o,slf,llf/
        ghg(pol)        Greenhouse gases /co2,ch4,n2o,slf,llf/
        ogg(ghg)        Non-CO2 (other) greenhouse gases /ch4,n2o,slf,llf/
        fgas(ghg)       High-GWP fluorinated gases /slf,llf/
        trdprg          Trading programs for annual and seasonal emissions of non-co2 pollutants
        trdprg_oz(trdprg) Trading programs for ozone season emissions of non-CO2 pollutants
        ozs(s,t)        Segments in ozone season
        csapr_s(trdprg,s,t)        Segments covered by annual and seasonal non-CO2 trading programs
        rggi_r(r)       Regions subject to RGGI CO2 Program
        cal_r(r)        Regions wholy contained within California
        ivrt(i,v,r,t)   Active vintage-capacity blocks
        csapr_ivrt(pol,i,v,r,t) Technologies covered by CSAPR constraints
        peak(s,r,t)     Segment in which peak load occurs for each region and time step
        ngp             NG supply classes
        xr              Dispatch reporting categories (in order)
        kr              Capacity reporting categories (in order)
$ifthen.respar1 not %opres%==no
        sri(i)          Set of units that can provide spinning reserve
        qsi(i)          Set of units that can provide quick start capability
        dc
        dcmap(s,i,dc,r)
$endif.respar1
        tlc              Set of technology learning curve pathways
        ptctv(t,v)       Set mapping what periods t a vintage v block can claim ptc
        zerocap(t,*)     Time steps in which a net-zero CO2 target is enforced
        zerocap_r(r,t,*) Time steps in which a regional net-zero CO2 target is enforced
        newfossil(i)     New fossil set for static model (varying heat rates and emissions)
	sec		Economy model sectors

*	Data sets (used to track data versions for reporting)
        d_st2r          Data - State-to-region mapping used
        d_unitdata      Data - Unit dataset employed
        d_trndataset    Data - Existing transmission data source used
        d_announced     Data - Announced retirements used
        d_sup_txla      Data - SUP-TX-LA project unit revisions used

*       Hydrogen model
        hi              Hydrogen production technologies
        ccs_h(hi)       Hydrogen production technologies with CCS
        hivrt(hi,v,r,t) Active vintage-capacity blocks for hydrogen production
        hi_map(i,hi)    Map from hydrogen generation units to upstream hydrogen production technologies

*	Direct air capture
        dac             Direct air capture technologies
;

$load i, type, class, tech, sol, cspi, nc, r, csp_r=csp, rpt, xrpt, f, cp, trdprg, trdprg_oz, ngp, xr=dr, kr, tlc, jold=j
$ifi not %opres%==no $load dc, sri, qsi
$load xcl, idef, iclass, itech, dspt, ndsp, new, cr, cof, crmap, cofmap, xtech
$load stage2, irnw, nuc, ccs, csapr_ivrt, nrps, nces
$load d_st2r, d_unitdata, d_trndataset, d_announced, d_sup_txla

$ifi %retail%==mix     $load reg
$ifi %retail%==allcomp reg(r) = no;
$ifi %retail%==allreg  reg(r) = yes;

* Define new fossil set now that i is loaded
newfossil("ngcc-n") = yes ;
newfossil("nggt-n") = yes ;
newfossil("ngcs-n") = yes ;

alias(cr,ccr);
alias(r,rr);
alias(s,ss);
alias(t,tt);
alias(i,ii);
alias(v,vv);

parameter
        xcap(i,r)           Existing Capacity in GW
        cumuprates(r,t)     Cumulative nuclear uprates GW
        cumuprates_nuc60(r,t)  Cumulative nuclear uprates GW 60 yrs nuclear life
        gcap(jold,r)        Existing storage capacity (GW)
        vcost(i,v,r)        Variable O&M cost (excluding fuel but including CO2 T and S) in $ per MWh
        waterdraw(i,r)      Water withdrawals (gallons per MWh)
        watercons(i,r)      Water consumption (gallons per MWh)
        pfadd(i,f,r,t)      Fuel price adders in $ per MMBTU
        pfaddcal(i,r,f,t)   Calibration pfadds that override defaults
        cost(i,v,r,t)       Dispatch cost in $ per MWh
        capcost(i,v,r)      New investment cost ($ per KW)
        capcost_raw(tlc,i,v,r)   New investment cost ($ per KW) - raw version with learning curve sensitivities
        batt_en(tlc,v)      Battery storage energy capacity cost ($ per kWh) - by technology learning curve
        batt_pow(tlc,v)     Battery storage power capacity cost ($ per kW) - by technology learning curve
        tcostadder_alt(*,i)      Adder to geographically distributed renewables (multiple scenarios) ($ per kW)
        tcostadder(i)       Adder to geographically distributed renewables ($ per kW)
        fomcost(i,r)        Fixed O&M cost in $ per KW
        htrate(i,v,f,r,t)   Heat rates in MMBTU per MWh (indexed by fuel for co-firing)
        ifuel(i,f)          Fuel use coefficients
        emit(i,v,pol,r,t)   Pollutant emission rates in metric tons per MWh (htrate and ifuel already applied)
        capture(i,v,r)      Carbon capture rate (tCO2 per MWh)
        cc(f)               Carbon content of fuels
        credit_bio          Carbon neutrality credit for biomass (1 means full 0 means none) /%credit_bio%/
        nclvl(nc,r)         Definition of nuclear percentage classes
        nccost(nc)          Additional public costs for nuclear generation in $ per MWh
        xcapadj_cr(type,v)  Adjustment to capacity for existing coal conversions
        caplim(i,r)         Upper bounds on total installed capacity (GW)
        capjlim(type,class,r) Joint upper bounds on total installed capacity by type and class (GW)
        solarcap(class,r)   Upper bound on total solar capacity (PV + weighted CSP) (GW)
        cspwt               Weight on CSP in solar capacity constraint
        invlim(type,r,t)    Upper bounds on investment based on current pipeline (cumulative since last time period) (GW)
        usinvlim(tech,t)    Upper bounds on national investments by technology (cumulative since last time period) (GW)
        invlim_f(r,type,tfull) Upper bounds on investment based on current pipeline (per period assuming five year time steps) (GW)
        usinvlim_raw(*,tech,tfull) Upper bounds on national investment by technology (cumulative since last time period) (GW)
        tinvlim(*,t)        Upper bounds on total transmision investment by line (GW)
        tusinvlim(t)        Upper bounds on national transmission investment (cumulative since last time period) (GW-miles)
        tusinvlim_raw(*,tfull) Upper bounds on national transmission investment (per period assuming five year time steps) (GW-miles)
        ccs_retro(class,r)  Upper bounds on retrofit eligible coal by class
        lifetime(i,r,t)     Lifetime coefficient for existing capacity
        lifetime_coal(*,i,r,t) Lifetime coefficient sensitivity options for existing coal capacity
        lifetime_nuc60(r,t) Lifetime coefficient for existing nuclear capacity with 60 year lifetimes
        convertgas(i,r,t)   Gas conversion coefficients for existing coal
        convertbio(i,r,t)   Bio conversion coefficients for existing coal
        invlife(type)       Investment life for new capacity additions (years)
        invlife_g(j)        Investment life for new storage additions (years)
        envlim(r,class)     Upper bound on environmental retrofits
        ncl(type)           Number of classes
        pinv(r,t)           Price of investment (from macro model) relative to base year
        plbi(r,t)           Price of labor-intermediate bundle (from macro model) relative to base year
        pf_alt(*,f,t)       Alternative price paths corresponding to alternative baselines
        pf(f,t)             National Average Power Producer Fuel prices in $ per MMBTU (zero for biomass)
        pf_ur(t,*)          Uranium price in $ per MMBTU in alternative scenarios
        pp(pol,t)           Pollutant prices in $ per metric ton
        pp_rg(pol,r,t)      Regional pollutant prices in $ per metric ton
        pco2_m(t)           CO2 price from macro model ($ per metric ton)
        pco2_m_rg(r,t)      Regional CO2 price from macro model ($ per metric ton)
        af_m(i,r,m)         Availability factor by month in base year
        af_mx(i,r,m)        Availability factors calibrated for existing units in base year
        af(s,i,v,r,t)       Availability factor by segment (applies to fossil hydro wind and solar)
        af_t(i,v,r,t_all)   Time-varying availability coefficient (if applicable)
        af_s(s,i,v,r,t)     Availability factor by segment (where populated used in preference to af_m)
        vrsc_t(i,r,t)       Time-varying coefficient for variable resources (if applicable)
        dni(s,i,r)          Direct irradiance for concentrated solar (differs from af only when using endogenous thermal storage)
        cf_y(i,r)           Annual capacity factor upper bound (unrestricted if 0)
        dismin(i,t)         Minimum dispatch factor for dspt_min technologies
        hyps(s,r,t)         Energy requirement for pumped storage (net charge) (GW)
        tcap(r,rr)          Capacity for inter-region trade in GW
        tcost(r,rr)         Transaction cost in $ per MWh for inter-region trade
        trnspen(r,r)        Transmission loss penalty
        hydadj(r,t)         Hydro cf adjustment factor to modify shapes to match long-run average (fraction of 2015)
* * * * * Inputs from end-use model
        netder(s,r,t)           Net power supply from distributed resources (GW)
        netdiststor(s,r,t)      Net power supply from distributed storage (GW)
        selfgen(r,t)            Total annual electricity supply from industrial co-gen (TWh)
        rfpv_out(s,r,t)         Power output from rooftop PV by segment (GW)
        rfpv_twh(r,t)           Total annual energy supplied by rooftop PV (TWh)
        rfpv_gw(r,t)            Installed capacity rooftop PV (GW)
* * * * *
        drcost(r)               Demand response (backstop demand) cost in $ per MWh
        drccost(r)              Cost to curtail distributed resources (negative demand response) in $ per MWh
        biocost(*,db,t)     Cost of biomass by supply class carbon price scenario and time in $ per mmbtu
        biocap(*,cp,db,r,t) Upper bound on dedicated biomass supply by region (trillion btu)
        tcapcost(r,rr)      Capital cost of new transmission capacity (GW) blank means infinity
        tlinelen(r,r)       Length in miles of the transmission lines between two regions
        plevcost(r,r)       Levelized cost of CO2 pipeline transport between two regions (dollars per tonne CO2)
        pcapcost(r,r)       Capital cost of CO2 pipeline transport between two regions (thousand dollars per tonne CO2 per hour)
        pcapann(r,r)        Capital cost of CO2 pipeline transport between two regions (dollars per tonne CO2 per year)
        co2pcap(i,v,r)      Additional plant capital cost of within-region CO2 pipeline ($ per kW)
        co2pfom(i,r)        Additional plant FOM cost of within-region CO2 pipeline ($ per kW)
        pdist(r,r)          Length of CO2 pipelines between two regions (miles)
        pcap                Capacity of 42-inch CO2 pipeline (tonnes per year)
        injcap(r)           CO2 storage capacity in each region (Gt CO2)
        icost(r)            FOM cost of CO2 storage (thousand dollars per tonne CO2 per hour)
        icapcost(r)         Capital cost of CO2 storage (thousand dollars per tonne CO2 per hour)
        ifomann(r)          FOM cost of CO2 storage (dollars per tonne CO2 per year)
        icapann(r)          Capital cost of CO2 storage (dollars per tonne CO2 per year)
        pipeom              Fixed O&M for CO2 pipelines (fraction of capital cost)
        caprate(i)          Capture rate for electric technologies
        cprt_h(hi)          Capture rate for hydrogen technologies
        ccs45Q(i,v,r,t)     45Q credit in each time period for each technology and vintage based on captured CO2 ($ per MWh)
        ccs45Q_h(hi,v,t)    45Q credit in each time period for each technology and vintage based on captured CO2 ($ per mmbtu)
        nuczec(r,t)         Nuclear capacity with state policy support (GW)
        newunits(r,i,t)     Expected (required) new capacity additions (GW)
        csp_cost_c      CSP cost of collector ($ per m2) /60/
        csp_cost_r      CSP cost of receiver ($ per kW-th) /120/
        csp_cost_g      CSP cost of storage ($ per kWh-th) /15/
        csp_cost_p      CSP cost of power block ($ per kW-e) /900/
        fc_csp_cr       Fixed O&M cost for CSP collector + receiver ($ per kW-th-year) /20/
        ic_csp_cr(i)    Investment cost for CSP collector + receiver ($ per kW-th)
        irg_csp(i)      Investment cost for CSP storage room capacity ($ per kWh-th)
        csp_eff_c       CSP collector efficiency (kW-th per m2 relative to nominal conditions of 1) /0.55/
        csp_eff_r       CSP receiver efficiency /0.9/
        csp_loss_g      CSP storage loss per hour (based on 1 pct per day) /0.00042/
        csp_eff_p       CSP power block efficiency (net) /0.45/
        rghours_csp(i,*)  CSP storage hours (implied from model output)
        csp_sm(i,*)     CSP solar multiplier (implied from model output)

        hours(s,t)          Number of hours per load segment
        load(s,r,t)         Load across segments including both retail and self-supplied (GW)
        load_ldv(s,r,t)     LDV charging load in each segment (GW)
        ntxintl(r)          Net international exports by region (TWh)
        dref_alt(*,r,t)     Indexed reference retail load growth path for alternative baseline scenarios
        dctref_alt(*,r,t)   Indexed reference direct use load growth path for alternative baseline scenarios
        dref(r,t)           Indexed reference retail load growth path from a chosen source (usually AEO or macro) (NOT USED)
        dctref(r,t)         Indexed reference direct use growth path from chosen source (usually AEO or macro)
        daref(r,t)          Reference annual retail load by region over time (TWh)
        paref(r,t)          Reference annual average price in $ per MWh
        pelas(r,t)          Price elasticity at reference point (a negative value)
        cb_1(r,t)           Consumer benefit linear coefficient
        cb_2(r,t)           Consumer benefit quadratic coefficient
        cf_ref(i,r)         Default capacity factor estimate for intializing post-terminal capacity value
        biopr_ref(r)        Default biomass price estimate for intializing post-terminal capacity value
        localloss           Losses within regions between generation and delivery (one plus percentage)
        gref(t)             Reference national gas consumption (quad btu)
        gelas(t)            Supply elasticity for natural gas
        gas_nele(t)         Non-electric gas demand for current scenario from end-use model (quad btu)
        co2cap(t_all,*)     Carbon emissions cap in billion metric tons CO2
        co2cap_rg(r,t,*)    Regional carbon emissions cap in billion metric tons CO2
        csaprbudget(trdprg,pol,r,t,*)  CSAPR regional budgets for annual and seasonal non-co2 emissions (million metric tons)
        csaprcap(trdprg,pol,r,t,*)     CSAPR regional assurance levels for annual and seasonal non-co2 emissions (million metric tons)
        ozsadj_r(r,t)       Adjustment for segment-approximated length of ozone season relative to actual length by region
        csapradj_s(trdprg,r,t)  CSAPR segment-approximation adjustment of cap
        svpr(t,*)           Safety valve emissions price in $ per ton CO2
        rps(i,r,*)          Technologies that contribute towards RPS
        rpstgt(t,*)         Federal RPS targets
        rpstgt_r(r,t)       State and regional level RPS targets
        rcmlim_r(r,t)       Total RPS compliance import limits (pct of RPS target)
        rcmlim(r,t)         Total RPS compliance import limits (TWh)
        nmrlim_r(r,t)       Unbundled REC import limits (pct of RPS target)
        nmrlim(r,t)         Unbundled REC import limits (TWh)
        acplim_r(r)         Alternative compliance payment limits (pct of RPS target)
        acplim(r,t)         Alternative compliance payment limits (TWh)
        acpcost(r)          Price of alternative compliance payment ($ per MWh)
        soltgt_r(r,t)       Solar energy mandated by regional solar carve-outs (pct of total energy)
        soltgt(r,t)         Solar energy mandated by regional solar carve-outs (TWh)
        canhyd_r(r)         Canadian hydro RECs (TWh)
        wnostgt_r(r,t)      Offshore wind capacity mandate (GW)
        batttgt_r(r,t)      Battery storage GW capacity mandate (GW)
        ces(i,v,r,*)        Contribution toward Clean Energy Standard (%)
        ces_oth(*,r,*)      Contribution of other technologies to Clean Energy Standard (%)
        cestgt(t,*)         Clean Energy Standard Targets (% of generation)
        cestgt_r(t,r)       Regional CES Targets (e.g. DeGette)
        cestax(i,v,r,t)     Implicit tax or subsidy representing a CES ($ per MWh)
        sb100tgt(t)         California SB-100 clean electricity standard targets
        sb100impcost(t)     California SB-100 cost on unspecified imports ($ per MWh)
        sb100i(i,r)         Contribution toward SB-100 (in-state resources)
        sb100enh(i,r)       Eligible clean electricity for California SB-100 from existing nuclear and hydro in neighboring states
        nys6599(t)          New York electric sector CO2 target (billion metric tonnes CO2)

        ghours(j,r)         Hours of storage (room size relative to door size if fixed)
        chrgpen(j)          Charge efficiency penalty for storage (> 1)
        p_ssm(s,s,t)        Transition probability for state space matrix approximating hourly chronology across segments
        pstay(*,s,t)        Probability of remaining in same state (representative hour) across hourly chronology
        dfact(t)            Discount factor for time period t (reflects number of years)
        dfact_all(t_all)    Discount factor for time period t (extended horizon)
        drate               Annual discount rate /%drate%/
        capr(i)             Capital charge rate
        capr_g(j)           Capital charge rate for storage
        nyrs(t)             Number of years since last time step
        nyrs_all(t_all)     Number of years since last time step (extended horizon)
        tyr(t)              Time period year
        tyr_all(t_all)      Time period year (extended horizon)
        vyr(v)              Vintage year
        ngcap(ngp,t)        Quantities for NG supply step function (trillion btu)
        ngcost(ngp,t)       Prices for NG supply step function ($ per mmbtu)
* 'mortgage_*' and 'modellife' are used for terminal revenue control
        mortgage_lt(i,v,r,t) Lifetime coefficient for existing and new capacity
        mortgage_lt50(i,t,r,t) Lifetime coefficient for 2050 new capcaity
        mortgage_lt_long(i,v,t,r,t_all) Lifetime coefficient for existing capacity (extended horizon)
        modellife(i,v,r,t)  Fraction of discount annualized payment stream contained in remaining model time horizon
        rsvmarg(r)          Reserve margin by region
        rsvcc(i,r)          Reserve margin capacity credit
        rsvoth(r)           Out of region capacity that counts towards a regions reserve margin (GW)
        tk                  Capital tax rate /%tk%/
        xdr(i,xr)           Map between technologies and dispatch reporting categories
        xkr(i,kr)           Map between technologies and capacity reporting categories
        cesacpr(t)          CES Alternative Compliance Payment price
$ifi not %opres%==no   pct_reserve(i,dc,r) For variable generating technologies - percent of generation in a segment to be covered by operating reserves
$ifi not %opres%==no   ramprate(i)        Limit to spinning reserve provision - set at percentage of nameplate capacity

        itc(type,v)         Investment Tax Credit (Fraction of capcost)
        ptc(type,v)         Level of Production Tax Credit ($ per MWh)
        ptc_inp(type,tfull) Level of Production Tax Credit in real year ($ per MWh)
        itc_inp(type,tfull) Level of Investment Tax Credit in real year (fraction of cap cost)
        itcval(new,v,r)     Value of Investment Tax Credit to specific technologies ($ per kW subsidy)
        CA_AB32pr(t)        California AB32 forecast carbon price
        RGGIcap(t)          Joint carbon cap for RGGI regions (billion tons CO2)

        usemitref(pol,t)    Emissions from reference run (only populated when fixIX and ets turned on)
        demandMC(s,r,t)     Marginal on demand from ETS reference run

        p_nem(t)            Carbon price from macro model (shadow price of non-electric abatement) ($ per tCO2)
        q_nem(t)            Non-electric CO2 emissions from macro model (billion metric tonnes)
        elas_nem(t)         Elasticity of non-electric emissions wrt carbon price (should be updated iteratively)
        p_nem_rg(r,t)       Regional carbon price from macro model (shadow price of non-electric abatement) ($ per tCO2)
        q_nem_rg(r,t)       Regional non-electric CO2 emissions from macro model (billion metric tonnes)
        elas_nem_rg(r,t)    Regional elasticity of non-electric emissions wrt carbon price (should be updated iteratively)

*       Example parameter for multi-gas cap
        co2ecap(t)               Cap of national total economy-wide GHG emissions (billion tons CO2-eq)

*       Hydrogen model
        vcost_h(hi,v)           Variable O&M cost for hydrogen production ($ per mmbtu output)
        capcost_h(hi,v)         Capital cost for hydrogen production ($ per thousand btu per hour)
        fomcost_h(hi)           Fixed O&M cost for hydrogen production ($ per thousand btu per hour per year)
        eph2(hi,*,v)            Energy requirement for hydrogen production (mmbtu input per mmbtu output)
        pfadd_r(f,r,t)          Regional average basis differential fuel price ($ per mmbtu)
        hcost(hi,v,r,t)         Variable operating cost for hydrogen production ($ per mmbtu output)
        emit_h(hi,v,pol)        Emissions rate for hydrogen production technologies (ton per mmbtu output)
        capture_h(hi,v)         Carbon capture rate for hydrogen technologies (tCO2 per mmbtu output)
        af_h(hi)                Availability factor for hydrogen production
        invlife_h(hi)           Hydrogen production technology vintage lifetimes (years)
        modellife_h(hi,v,r,t)   Fraction of discount annualized payment stream contained in remaining model time horizon

        hdu_c(r,t)              Exogenous annual direct use of hydrogen (centralized production) (trillion btu)
        hdu_d(r,t)              Exogenous annual direct use of hydrogen (distributed production) (trillion btu)

* Direct air capture model parameters
        af_dac(dac)             Availability factor relative to nominal capacity f5or DAC
        epdac(dac,*,v)          Energy consumption per tCO2 net removal (mmbtu)
        capcost_dac(dac,v)      Capital cost of direct air capture ($ per net tCO2 removed per year)
        fomcost_dac(dac,v)      Fixed O&M cost for transformation capacity ($ per tCO2)
        vcost_dac(dac,v)        Variable O&M cost for direct air capture ($ per net tCO2 removed)
        capture_dac(dac,v)      Capture rate of DAC (captured tCO2 per net tCO2 removed)
        ccs45Q_dac(dac,v,t)     45Q credit in each time period for each DAC technology and vintage based on captured CO2 ($ per net tCO2 removed)
        invlife_dac(dac)        Investment life for DAC technologies (years)
        daccost(dac,v,r,t)      Variable operating cost for DAC ($ per tCO2 removed)
        modellife_dac(dac,v,r,t) Fraction of discount annualized payment stream contained in remaining model time horizon
        capr_dac(dac)           Annual capital recovery factor for direct air capture investments
;

* Operating reserve parameters
parameters
         orfrac(*)       Fraction of operating reserve requirement spinning vs quick-start
         orreq_fx(*)     Operating reserve requirement on load (a fixed percentage)
         orreq_vr(s,i,r) Operating reserve requirement on variable resources (a percentage that depends on hourly shape)
         orcost(type)    Cost of providing reserves for generation ($ per MW-h) /
                clcl    15
                cbcf    15
                igcc    15
                ccs9    15
                ccs5    15
                ngcc    6
                ngcs    6
                ngst    4
                nggt    4
                ptsg    4
                bioe    4
                hydr    2 /
        orcostg(j)       Cost of providing reserves for storage ($ per MW-h)
;

orcostg(j) = 2;

elas_nem(t)      = 0 ;
elas_nem_rg(r,t) = 0 ;
p_nem(t)         = 0 ;
p_nem_rg(r,t)    = 0 ;
q_nem(t)         = 0 ;
q_nem_rg(r,t)    = 0 ;
co2ecap(t)       = 0 ;

* The following parameters do not depend on the number of segments
$load ifuel, nclvl, nccost, caplim, capjlim, invlife, af_t, vrsc_t, dref_alt, dctref_alt
$load invlim_f=invlim, usinvlim_raw, tinvlim, tusinvlim_raw, gcap, xcapadj_cr, ncl
$load pf_alt, pf_ur, co2cap, co2cap_rg, csaprbudget, csaprcap, svpr, tcap, tcost, tcapcost, tlinelen, trnspen, xdr, xkr
$load tyr, vyr, rps, rpstgt, rpstgt_r, rcmlim_r, nmrlim_r, acplim_r, acpcost=acpcost_r, soltgt_r, wnostgt_r, batttgt_r,
$load canhyd_r, ces, cesacpr, cestgt, cestgt_r, ces_oth
$ifi not %opres%==no $load ramprate, pct_reserve
$load db, biocap, biocost
$load ptc_inp,itc_inp,ptctv,CA_AB32pr,cal_r,RGGIcap,rggi_r
$load solarcap, cspwt, pfadd=pfaddout, pfadd_r=pfaddout_r, vcost, waterdraw, watercons, htrate=htrate_f, cc, emit=emit_f, capture=capture_f, capcost_raw, batt_en, batt_pow
$load fomcost=fomcost_raw, lifetime, lifetime_nuc60, lifetime_coal, convertgas, convertbio, tcostadder_alt, ccs_retro
$load ntxintl, af_m, cf_y, localloss cumuprates, cumuprates_nuc60
$load sec, hydadj
$load pdist, plevcost, pcapcost, pcap, pipeom, injcap, caprate, icost, icapcost, co2pcap, co2pfom, icapann, ifomann, pcapann, ccs45q
$load sb100, sb100i, sb100impcost, sb100tgt, sb100enh, nys_r, nys6599, nuczec, newunits
$gdxin !! close modeldata_gen.gdx

* Read in existing capacity from base year calibration
$if not exist %elecdata%\baseyear.gdx $abort 'ABORTED Need to run baseyear.gms in the electric model upstream to generate file baseyear.gdx in %elecdata% folder.'
$gdxin %elecdata%\baseyear
$load xcap=xcap_cal
$gdxin !! close baseyear.gdx

* Adjust existing nuclear lifetimes if appropriate
$ifi not %nuc60%==no lifetime("nucl-x",r,t) = lifetime_nuc60(r,t);
$ifi not %nuc60%==no cumuprates(r,t) = cumuprates_nuc60(r,t);

* Adjust emissions factor of biomass based on scenario-specified carbon neutrality credit
emit("bioe-n",v,"co2",r,t)             = htrate("bioe-n",v,"dbio",r,t) * cc("dbio") * (1 - credit_bio);
emit("becs-n",v,"co2",r,t)             = htrate("becs-n",v,"dbio",r,t) * cc("dbio") * (1 - credit_bio - caprate("becs-n"));
emit(cr(i),v,"co2",r,t)$idef(i,"bioe") = htrate(i,v,"dbio",r,t) * cc("dbio") * (1 - credit_bio);

$if not set allam       $setglobal allam       no
$iftheni %allam%==yes
emit(i,v,"co2",r,t)$idef(i,"ngcs") = 0;
$endif

$if not set hico2ts       $setglobal hico2ts       no
$iftheni %hico2ts%==yes
icapann(r) = icapann(r) * 2;
$endif

* Define vstatic dynamically
$iftheni not %static%==no
vstatic(v)$(vyr(v) <= %static% and (not vbase(v))) = yes;
$endif

* Read in parameters for hydrogen model
$gdxin %elecdata%\h2data
$load hi, ccs_h, hi_map
$load vcost_h, capcost_h, fomcost_h, eph2, emit_h, capture_h, af_h, invlife_h, cprt_h, ccs45q_h
$gdxin

* Read in parameters for direct air capture
$gdxin %elecdata%\dacdata
$load dac
$load af_dac, vcost_dac, fomcost_dac, capcost_dac, capture_dac, epdac, invlife_dac, ccs45Q_dac
$gdxin

* Define tv and vt
tv(t,newv(v)) = yes$sameas(t,v);
tv(t,"2050+") = yes$(tyr(t) ge 2050);

acv(vbase(v)) = yes;
loop(t, acv(v)$tv(t,v) = yes;);

$iftheni.staticv %static%==no
vt(acv(v),t) = yes$(vyr(v) le tyr(t));
$else.staticv
vt(acv(v),"%static%") = yes$(vyr(v) le %static%);
$endif.staticv


* The following set and parameters depend on the number of segments (but not on control costs):

* With 8760 segments, the parmeters are time-indexed using 8760
$ifthen %seg%==8760
$gdxin %elecdata%\segdata_%seg%_%basescen%.gdx
$load s, sm, ozs
$load peak, hours, load=load_s, load_ldv=load_ldv_s, af_s=vrsc, hyps
$gdxin !! close segdata_%seg%.gdx
csapr_s(trdprg,s,t) = yes$(not trdprg_oz(trdprg) or ozs(s,t));
csapradj_s(trdprg,r,t) = 1;
$endif

* With 120 segments, the parmeters are time-indexed using representative hours
$ifthen %seg%==120
$if not %pssm%==yes $gdxin %elecdata%\segdata_%seg%_%basescen%.gdx
$if %pssm%==yes $gdxin %elecdata%\segdata_%seg%_pssm_%basescen%.gdx
$load s, sm, ozs, ozsadj_r
$load peak, hours, load=load_s, load_ldv=load_ldv_s, af_s=vrsc, hyps
$if %pssm%==yes $load ssm, p_ssm, pstay
$gdxin !! close segdata_%seg%.gdx
csapr_s(trdprg,s,t) = yes$(not trdprg_oz(trdprg) or ozs(s,t));
csapradj_s(trdprg,r,t) = 1$(not trdprg_oz(trdprg)) + ozsadj_r(r,t)$trdprg_oz(trdprg);
$endif

* Read in parameters from end-use model
$gdxin %elecdata%\enduse_%basescen%
$load selfgen, gas_nele
$gdxin %elecdata%\rfpv_%basescen%
$load rfpv_gw=pvrfcap_r
hdu_c(r,t)$(not tbase(t)) = 1;
hdu_d(r,t)$(not tbase(t)) = 1;
netdiststor(s,r,t) = 0;
rfpv_out(s,r,tbase(t)) = sum(vbase(v), af_s(s,"pvrf-xn",v,r,t) * rfpv_gw(r,t));
rfpv_out(s,r,t)$(not tbase(t)) = sum(tv(t,v), af_s(s,"pvrf-xn",v,r,t)) * rfpv_gw(r,t);
rfpv_twh(r,t) = 1e-3 * sum(s, hours(s,t) * rfpv_out(s,r,t));
netder(s,r,t) = rfpv_out(s,r,t) + netdiststor(s,r,t) + selfgen(r,t) / 8.76;

* Calculate upstream methane emissions factors
$if not set ch4gwp	$setglobal ch4gwp	25
$if not set ch4lk	$setglobal ch4lk	0.015
parameter
ch4_leakage_rate        Assumed average leakage rate (fraction of consumed natural gas) /%ch4lk%/
ch4_conv                Mass conversion for methane (mmbtu per t) /54/
ch4_gwp                 Assumed GWP coefficient for methane (t CO2-eq per t CH4) /%ch4gwp%/
leaked_ch4(i,v,r)       Implied upstream methane emissions rate for generation technologies (tCO2-eq per MWh)
leaked_ch4_h(hi,v)	Implied upstream methane emissions rate for hydrogen production technologies (tCO2-eq per MMBtu output)
;

leaked_ch4(i,v,r) = ch4_leakage_rate / ch4_conv * ch4_gwp * sum(vt(v,t), htrate(i,v,"ng",r,t));
leaked_ch4_h(hi,v) = ch4_leakage_rate / ch4_conv * ch4_gwp * eph2(hi,"ng",v);

$if not set ch4gas       $setglobal ch4gas       no
$iftheni %ch4gas%==yes
emit(i,v,"co2",r,t) = emit(i,v,"co2",r,t) + leaked_ch4(i,v,r);
emit_h(hi,v,"co2") = emit_h(hi,v,"co2") + leaked_ch4_h(hi,v);
$endif

* Zero out pvrf-x from xcap (all comes in from end-use model)
xcap("pvrf-xn",r) = 0;

parameter vrscsum(i,v,r,t);
vrscsum(i,v,r,t) = sum(ss, af_s(ss,i,v,r,t));
af_s(s,i,v,r,t)$vrscsum(i,v,r,t) = af_s(s,i,v,r,t) + eps;

af_m("ngcc-n",r,m)         = af_m("ngcc-x1",r,m) ;
af_m(i,r,m)$idef(i,"clng") = af_m("clcl-x1",r,m) ;
af_m(i,r,m)$idef(i,"cbcf") = af_m("clcl-x1",r,m) ;
af_m(i,r,m)$idef(i,"ccs5") = af_m("clcl-x1",r,m) ;
af_m(i,r,m)$idef(i,"ccs9") = af_m("clcl-x1",r,m) ;
af_m(i,r,m)$idef(i,"clec") = af_m("clcl-x1",r,m) ;
af_m(i,r,m)$idef(i,"ngcs") = af_m("ngcc-x1",r,m) ;
af_m(i,r,m)$idef(i,"h2cc") = 1;

$ifi not %opres%==no af_m(i,"Pacific",m)$(sameas(i,"nggt-x1") or sameas(i,"nggt-x2") or sameas(i,"nggt-x3")) = 1;

* * * * * * * * * * * * * * Run-time Model Set-up to Enact Switch Settings * * * * * * * * * * * * * * * * * *

* * * Time-mode dependent settings:

tyr_all(t_all) = t_all.val;
alias(t_all,tt_all);
vt_all(v,t_all)$(vyr(v) le tyr_all(t_all) and sum(tt_all, tv(tt_all,v))) = yes;
$ifi %static%==no nyrs_all(tbase_all) = 1 ;
$ifi %static%==no nyrs_all(t_all)$(not tbase_all(t_all)) = tyr_all(t_all) - tyr_all(t_all-1);

* Adjust existing coal lifetimes if requested by user (default means to retain the upstream default lifetime)
$iftheni.xcllife not %xcllife%==default
lifetime(i,r,t)$(idef(i,"clcl") and xcap(i,r)) = lifetime_coal("%xcllife%",i,r,t) ;
$endif.xcllife

* Identify unit-vintage-region-time period combinations relevant for optimization
ivrt(new,newv,r,t)$vt(newv,t) = yes ;
ivrt(i,vbase(v),r,t)$(vt(v,t) and xcap(i,r)*lifetime(i,r,t)) = yes ;
ivrt(cr,newv,r,t)$idef(cr,"ccs9") = no;
ivrt(cr,newv,r,t)$(idef(cr,"ccs9") and vt(newv,t)) = yes$sum(iclass(cr,"ccs9",class), ccs_retro(class,r));
ivrt(new,v,r,t)$((not cr(new)) and (vyr(v) + sum(idef(new,type), invlife(type)) <= t.val)) = no;
ivrt(i,v,r,t)$(irnw(i) and new(i) and not sameas(i,"wind-r") and (sum(iclass(i,type,class), capjlim(type,class,r)) eq 0 or (sum(iclass(i,type,class), solarcap(class,r)) eq 0 and sol(i)))) = no;
ivrt("wind-r",v,r,t)$(xcap("wind-x",r) eq 0) = no;

hivrt(hi,newv,r,t)$vt(newv,t) = yes;
hivrt(hi,v,r,t)$((vyr(v) + invlife_h(hi)) <= t.val) = no;

ivrt(i,v,r,t)$(not new(i) and not cr(i) and xcap(i,r)*lifetime(i,r,t)=0 ) = no;

ivrt(cr,v,r,t)$((not stage2(cr)) and sum(i$(crmap(cr,i)), xcap(i,r)*lifetime(i,r,t))=0) = no;

* Co-fired units are only available when their existing parent is available
ivrt(cof,v,r,t)$(
* Condition 1 - Cofired unit
  idef(cof,"cbcf") and
* Condition 2 - Both retrofit and parent units have zero lifetime
  (sum(i$(xtech(i) and cofmap(cof,i)), xcap(i,r)*lifetime(i,r,t))=0) and
  (sum((i,cr)$(cofmap(cof,cr) and crmap(cr,i)), xcap(i,r)*lifetime(i,r,t))=0)
) = no ;

* Turn off any exlcuded combinations in CSAPR compliance set
csapr_ivrt(pol,i,v,r,t)$(not ivrt(i,v,r,t)) = no;

* Set discount factor and number of years per time period
$iftheni not %static%==no
   dfact(t) = 1;
   dfact_all(t_all) = 1;
   nyrs( t) = 1;
$else
*  Define discount factor (equal to sum of discounted years between t-1 and t)
*  e.g. for drate = 5%
*  dfact(2015) = 0.95   * (1 + 0.95 + 0.95^2)
*  dfact(2020) = 0.95^4 * (1 + 0.95 + ... + 0.95^4)
*  etc...

   dfact(tbase) = 1;
   nyrs( tbase) = 1;
   nyrs( t)$(not tbase(t)) = tyr(t) - tyr(t-1);
   dfact(t)$(not tbase(t)) = (1 - drate)**(tyr(t-1)+1 - sum(tbase, tyr(tbase))) * (1 - (1-drate)**(nyrs(t))) / drate;
   dfact_all(t_all)$(not tbase_all(t_all)) = (1 - drate)**(tyr_all(t_all-1) + 1 - sum(tbase, tyr(tbase))) * (1 - (1 - drate)**(nyrs_all(t_all))) / drate;
$endif

* Calculate average PTC and ITC subsidies for a given model year

$iftheni.ptcswitch %ptc%==yes
loop(v$(not vbase(v)),
ptc(type,v)$sum(tfull$((tfull.val gt vyr(v-1)) and (tfull.val le vyr(v)) and ptc_inp(type,tfull)), 1) =
       sum(tfull$((tfull.val gt vyr(v-1)) and (tfull.val le vyr(v)) and ptc_inp(type,tfull)), ptc_inp(type,tfull))
    /  sum(tfull$((tfull.val gt vyr(v-1)) and (tfull.val le vyr(v)) and ptc_inp(type,tfull)), 1) ;
);
$else.ptcswitch
ptc(type,v) = 0 ;
ptctv(t,v) = 0 ;
$endif.ptcswitch

$iftheni.itcswitch %itc%==yes
loop(v$(not vbase(v)),
itc(type,v)$sum(tfull$((tfull.val gt vyr(v-1)) and (tfull.val le vyr(v)) and itc_inp(type,tfull)), 1) =
       sum(tfull$((tfull.val gt vyr(v-1)) and (tfull.val le vyr(v)) and itc_inp(type,tfull)), itc_inp(type,tfull))
    /  sum(tfull$((tfull.val gt vyr(v-1)) and (tfull.val le vyr(v)) and itc_inp(type,tfull)), 1) ;
);
$else.itcswitch
itc(type,v) = 0 ;
$endif.itcswitch

* Use CO2 storage 45Q credits if applicable
$ifi %cred45q%==no ccs45q(i,v,r,t)  = 0 ;
$ifi %cred45q%==no ccs45q_h(hi,v,t) = 0 ;
$ifi %cred45q%==no ccs45q_dac(dac,v,t) = 0 ;

* Calculate investment limits based on time period specification

invlim(type,r,t) = 0;
usinvlim(tech,t) = 0;

loop(t,
         invlim(type,r,t) = sum(tfull$(tfull.val le tyr(t) and tfull.val > tyr(t-1)), invlim_f(r,type,tfull));
         usinvlim(tech,t) = sum(tfull$(tfull.val le tyr(t) and tfull.val > tyr(t-1)), usinvlim_raw("%usinvscn%",tech,tfull));
);

* Calculate investment limits based on time period specification and scenario requested (default is 'unlim')

tusinvlim(t) = 0;
loop(t,
         tusinvlim(t) = sum(tfull$(tfull.val le tyr(t) and tfull.val > tyr(t-1)), tusinvlim_raw("%tuslimscn%",tfull));
);

* Can enforce a national moratorium on new NGCC builds after %nonewgas% year
invlim("ngcc",r,t)$(t.val > %nonewgas%) = 0 ;
invlim("ccs5",r,t)$(t.val > %nonewgas%) = 0 ;

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Assemble availability factors

* Use monthly af by default (available for thermal and hydro)
af(s,i,v,r,t)             = sum(sm(s,m,t), af_m(i,r,m)) ;

* Adjust hydro to use long-run historical average for all year asides from the base year
af(s,i,v,r,t)$idef(i,"hydr") = sum(sm(s,m,t), af_m(i,r,m) * hydadj(r,t)) ;

* Override with segment af where available (hydro and renewables)
af(s,i,v,r,t)$vrscsum(i,v,r,t) = af_s(s,i,v,r,t) ;

* Adjust hydro to use long-run historical average for all year asides from the base year
af(s,i,v,r,t)$(vrscsum(i,v,r,t) and idef(i,"hydr")) = af_s(s,i,v,r,t) * hydadj(r,t);

$iftheni.cf %cfadj%==yes

* The following code adjusts the availability factors from segdata
* (which are based on the af of the representative hour for each segment) to
* make the average annual c.f. equal to that calculated from the 8760 hour data.

parameter
acf_h(i,v,r)    Annual average hourly capacity factors for intermittent resources
aaf_m(i,r,t)    Annual average monthly availability factors for non-intermittent resources
twh_h(r,t)      Total TWh load from hourly enduse loadshapes
twh_s(r,t)      Total TWh load based on current segments
acf_s(i,v,r,t)  Annual average capacity factors based on current segments
acf_s_chk(*,i,v,r,t)    Check on adjusted annual average capacity factors
monthdays(m)            /1 31,2 28,3 31,4 30,5 31,6 30,7 31,8 31,9 30,10 31,11 30,12 31/
;

* Load hourly-weighted annual average capacity factors for intermittents from the upstream
$gdxin %elecdata%\modeldata_gen
$load acf_h
$gdxin

$if not set y_shp $set y_shp 2015
$gdxin %hoursdata%\load_t_%y_shp%_%basescen%
$load twh_h
$gdxin

* Calculate an average availability factor for thermal
aaf_m(i,r,t) = sum(m, monthdays(m) * af_m(i,r,m)) / sum(m, monthdays(m)) * (1 + (hydadj(r,t) - 1)$idef(i,"hydr"));

* Calculate segment-weighted annual average availability factors from segment data
acf_s(i,v,r,t) = sum(s, hours(s,t) * af(s,i,v,r,t)) / sum(s, hours(s,t));

* Calculate segment-weighted annual TWh
twh_s(r,t) = 1e-3 * sum(s, hours(s,t) * load(s,r,t));

* Scale availability factors so average availability factor over the segments equals that over the hours
af(s,i,v,r,t)$(acf_h(i,v,r) and acf_s(i,v,r,t)) = af(s,i,v,r,t) * acf_h(i,v,r) / acf_s(i,v,r,t);
af(s,i,v,r,t)$(aaf_m(i,r,t) and acf_s(i,v,r,t)) = af(s,i,v,r,t) * aaf_m(i,r,t) / acf_s(i,v,r,t);

rfpv_out(s,r,tbase(t)) = sum(vbase(v), af(s,"pvrf-xn",v,r,t) * rfpv_gw(r,t));
rfpv_out(s,r,t)$(not tbase(t)) = sum(tv(t,v), af(s,"pvrf-xn",v,r,t)) * rfpv_gw(r,t);
rfpv_twh(r,t) = 1e-3 * sum(s, hours(s,t) * rfpv_out(s,r,t));
netder(s,r,t) = rfpv_out(s,r,t) + netdiststor(s,r,t) + selfgen(r,t) / 8.76;

* Scale load to match hourly total
load(s,r,t) = load(s,r,t) * twh_h(r,t) / twh_s(r,t);

acf_s_chk("before",i,v,r,t) = acf_s(i,v,r,t);
acf_s_chk("after",i,v,r,t) = sum(s, hours(s,t) * af(s,i,v,r,t)) / sum(s, hours(s,t));
acf_s_chk("target",i,v,r,t) = acf_h(i,v,r) + aaf_m(i,r,t);
acf_s_chk("max>1",i,v,r,t) = smax(s, af(s,i,v,r,t))$(smax(s, af(s,i,v,r,t)) > 1);

$endif.cf

dni(s,cspi,r) = 0 ;
$iftheni.cspaf %cspstorage%==yes
af(s,cspi,v,r,t)$csp_r(r) = sum(sm(s,m,t), af_m(cspi,r,m));
af(s,cspi,v,r,t)$(not csp_r(r)) = eps;
dni(s,cspi,r)  = sum((tbase,vbase), af_s(s,cspi,vbase,r,tbase));
$else.cspaf
af(s,cspi,v,r,t)$new(cspi) = 0;
$endif.cspaf

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Cost and deployment settings:

* Remove public nuclear costs if appropriate
$ifi not %nccost%==yes nccost(nc) = 0 ;

* Remove fixed O&M costs on existing capacity if appropriate
$ifi not %fomx0%==no     fomcost(i,r)$(not new(i)) = 0;

* Set renewable costs as appropriate
capcost(i,newv(v),r)$(not irnw(i)) = capcost_raw("%tlc%",i,v,r);
capcost(irnw(i),newv(v),r) = capcost_raw("%rnwtlc%",i,v,r);

* Adjust renewable capacity costs by a scalar factor if appropriate
capcost(new(i),newv(v),r)$idef(i,"wind") = capcost(i,v,r) * %windcstadj% ;
capcost(new(i),newv(v),r)$sol(i) = capcost(i,v,r) * %solcstadj% ;

capcost("ccs9-rc1",v,r) = 1407; capcost("ccs9-re1",v,r) = 1407;
capcost("ccs9-rc2",v,r) = 1522; capcost("ccs9-re2",v,r) = 1522;
capcost("ccs9-rc3",v,r) = 1669; capcost("ccs9-re3",v,r) = 1669;
capcost("ccs9-rc4",v,r) = 2160; capcost("ccs9-re4",v,r) = 2160;

$if not set beccshi	$set beccshi       no
$ifi %beccshi%==yes	capcost("becs-n",v,r) = 10000;

$if not set daclo	$set daclo       no
$ifi %daclo%==yes	capcost_dac(dac,v)$(vyr(v) ge 2030) = 0.5 * capcost_dac(dac,v);
$ifi %daclo%==yes	fomcost_dac(dac,v)$(vyr(v) ge 2030) = 0.5 * fomcost_dac(dac,v);
$ifi %daclo%==yes	vcost_dac(dac,v)$(vyr(v) ge 2030) = 0.5 * vcost_dac(dac,v);

$if not set h2lo	$set h2lo       no
$ifi %h2lo%==yes	capcost_h("elys-c",v)$(vyr(v) eq 2025) = 194; capcost_h("elys-c",v)$(vyr(v) eq 2030) = 40;
$ifi %h2lo%==yes	capcost_h("elys-c",v)$(vyr(v) eq 2035) = 37; capcost_h("elys-c",v)$(vyr(v) eq 2040) = 34;
$ifi %h2lo%==yes	capcost_h("elys-c",v)$(vyr(v) eq 2045) = 31; capcost_h("elys-c",v)$(vyr(v) eq 2050) = 28;

$if not set lownuccost $set lownuccost no
$iftheni.lownuc %lownuccost%==yes
capcost("nuca-n",v,r)$(vyr(v) eq 2025) = 5572;
capcost("nuca-n",v,r)$(vyr(v) eq 2030) = 5182;
capcost("nuca-n",v,r)$(vyr(v) eq 2035) = 4792;
capcost("nuca-n",v,r)$(vyr(v) eq 2040) = 4402;
capcost("nuca-n",v,r)$(vyr(v) eq 2045) = 4068;
capcost("nuca-n",v,r)$(vyr(v) eq 2050) = 3789;
fomcost("nuca-n",r) = 93.26;
htrate("nuca-n",v,f,r,t) = 0.8 * htrate("nucl-n2",v,f,r,t);
$endif.lownuc

* Calculate applicable investment tax credit in $ per kW by technology
itcval(new,v,r) = 0 ;
$ifi %itc%==yes itcval(new,v,r) = capcost(new,v,r) * sum(idef(new,type),itc(type,v)) ;

* Assign CSP cost parameters (CSP storage door cost is built into collector / receiver)
ic_csp_cr(cspi)$new(cspi) = (csp_cost_c * 1.173) / csp_eff_c + csp_cost_r * 1.173;
irg_csp(cspi)$new(cspi) = csp_cost_g * 1.173;
capcost(new(i),newv(v),r)$idef(i,"cspr") = csp_cost_p * 1.173;
fomcost(new(i),r)$idef(i,"cspr") = 10;

* Adjust capital cost of new gas if appropriate
capcost("ngcc-n",v,r) = capcost("ngcc-n",v,r) * %ngcapadj%;
capcost("nggt-n",v,r) = capcost("nggt-n",v,r) * %ngcapadj%;

* Adjust capital cost of ccs technologies based on switch. Add capital and FOM costs to reflect
* cost of within-region CO2 transport.
capcost(ccs(i),v,r)$(capcost(i,v,r) > 0) = capcost(i,v,r) * %ccscost% ;
capcost(ccs,v,r) = capcost(ccs,v,r) + co2pcap(ccs,v,r) ;
fomcost(ccs,r) = fomcost(ccs,r) + co2pfom(ccs,r) ;

abort$(smin((new,newv)$(not cr(new)), sum(r,capcost(new,newv,r))) eq 0) "Capcost for some vintage and new technology is zero!";

* Set fuel prices
pf(f,t) = pf_alt("%baseline_pf%",f,t);

* Set T&D cost adder for renewables
tcostadder(i) = tcostadder_alt("%tdc%",i);

$iftheni.flatgas not %flatgas%==no
pf("ng",t)$(not tbase(t)) = %flatgas% ;
$endif.flatgas

* Override fuel prices after %fixIX% year if requested to simulate a fuel price shock
$iftheni.pfshock not %pf_shock%==no
$iftheni.fixix3 not %fixIX%==no
pf("ng",t)$(t.val gt %fixIX%) = pf_alt("%pf_shock%","ng",t);
$else.fixix3
$abort 'Need to set fixIX switch when using pf_shock switch'
$endif.fixix3
$endif.pfshock

* Set pollutant prices
pp(pol,t)$(not sameas(pol,"co2"))      = 10 ;
pp_rg(pol,r,t)$(not sameas(pol,"co2")) = 0  ;

* Set demand response backstop cost
drcost(r) = %drcost%;
drccost(r) = 100;

* Set reserve margin, reserve margin capacity credit, and out-of-region reserve credit
rsvcc(i,r) = 0 ;
rsvmarg(r) = 0 ;
rsvoth(r) = 0 ;
rsvcc(i,r)$(not irnw(i)) = 1;
* cbcf technologies must be removed because capacity is duplicate of existing coal
rsvcc(i,r)$idef(i,"cbcf") = 0 ;
rsvmarg(r) = %rsvmarg% ;
* Calculate contributions to reserve capacity that are out-of-state, based upon
* base year peakload vs. capacity (ensure non-zero)
rsvoth(r) = max(eps,
            sum(peak(s,r,tbase(t)), ((load(s,r,t) - netder(s,r,t)) * localloss) * (1 + rsvmarg(r)) + hyps(s,r,t)
              - sum(ivrt(irnw(i) ,vbase(v),r,t), af_s(s,i,v,r,t) * xcap(i,r)))
            - sum(i, xcap(i,r) * rsvcc(i,r))
);

* Move all technologies to dspt if indicated
$ifi not %free%==no dspt(i) = yes; ndsp(i) = no;

* By default dspt_min is empty, dismin is zero
dspt_min(i) = no;
dismin(i,t) = 0;

* Nucl-x is in ndsp by default, can override if nucxmin < 1 to allow flexible dispatch
$ifthene.flex %nucxmin%<1
ndsp("nucl-x") = no; dspt("nucl-x") = yes;
* If 0 < nucxmin < 1, add to dspt_min and enforce minimum dispatch constraint
$ifthene.min %nucxmin%>0
dspt_min("nucl-x") = yes; dismin("nucl-x",t)$(t.val le 2030) = %nucxmin%;
$endif.min
$endif.flex

* * * Policy settings

* A carbon tax path starting in different years can be specified directly
$if set ctax20  pp("co2",t)$(tyr(t) ge 2020) = %ctax20% * (1 + %ctaxrate%)**(tyr(t) - 2020);
$if set ctax25  pp("co2",t)$(tyr(t) ge 2025) = %ctax25% * (1 + %ctaxrate%)**(tyr(t) - 2025);
$if set ctax30  pp("co2",t)$(tyr(t) ge 2030) = %ctax30% * (1 + %ctaxrate%)**(tyr(t) - 2030);
$if set ctax35  pp("co2",t)$(tyr(t) ge 2035) = %ctax35% * (1 + %ctaxrate%)**(tyr(t) - 2035);
$if set ctax40  pp("co2",t)$(tyr(t) ge 2040) = %ctax40% * (1 + %ctaxrate%)**(tyr(t) - 2040);
$if set ctax45  pp("co2",t)$(tyr(t) ge 2045) = %ctax45% * (1 + %ctaxrate%)**(tyr(t) - 2045);
$if set ctax50  pp("co2",t)$(tyr(t) ge 2050) = %ctax50% * (1 + %ctaxrate%)**(tyr(t) - 2050);

* Carbon taxes can be imposed to proxy expected carbon prices in regions subject
* to AB32
$ifi %CA_AB32%==yes pp_rg("co2",cal_r,t) = CA_AB32pr(t) ;

* To reproduce a CES scenario with a tax/subsidy instrument, read cestax from previous run
cestax(i,v,r,t) = 0;
$ifi not %cestax%==no execute_load '%cestax%.gdx', cestax;

* To enforce a region-class level constraint on environmental retrofits, read in from specified scenario
envlim(r,class) = inf;
$ifi not %irrclass%==no execute_load '%elecdata%\%irrclass%.gdx', envlim=envlim_pay;

* Existing generators do not qualify for the Clean Energy Standard (CES) if the following control variable is set
$ifi %cesb_qual%==yes ces(i,v,r,"%ces%")$(sameas(i,"nucl-x") or sameas(i,"hydr-x")) = 0;

* For DeGette & CFA Clean Energy Standards, update crediting of hydrogen generation technologies based on
* non-electric hydrogen production source, adjusting for electric inputs into hydrogen production
parameter emit_h2(i,v,*,r)       Implied emission rate from non-electric hydrogen production sources;

loop(hi_map(i,hi)$(not sameas(hi,"elys-c")),

* First calculate implied emissions rate from non-electric hydrogen production sources
emit_h2(i,v,"co2",r) =
*       Fuel input to hydrogen production
        (sum(f, eph2(hi,f,v)) * sum(tv(t,v), htrate(i,v,"h2",r,t))) /
*       Adjusted for electric input
*        (1 - eph2(hi,"ele",v) * sum(tv(t,v), htrate(i,v,"h2",r,"2015")) / 3.412) *
        (1 - eph2(hi,"ele",v) * sum(tv(t,v), htrate(i,v,"h2",r,t)) / 3.412) *
*       Times carbon content of fuel (adjusted for capture)
        sum(f$eph2(hi,f,v), cc(f) * (1 - cprt_h(hi)))
;

* Then apply CES crediting formula to implied emissions rate
ces(i,v,r,"degette") = min(1, max(0, (1 - (emit_h2(i,v,"co2",r) / 0.82))));
ces(i,v,r,"cfa") = min(1, max(0, (1 - (emit_h2(i,v,"co2",r) / 0.82))));

);

parameter dfx(r,t), xcfx(i,v,r,t), tcfx(r,r,t), gcfx(j,r,t), installedG(i,v,r,t), installedT(r,r), itfx(r,r,t);


* Set reference demand path to appropriate exogenous baseline
dref(r,t) = dref_alt("%baseline_ld%",r,t);
dctref(r,t) = dctref_alt("%baseline_ld%",r,t);

$ifi %flatdemand%==yes dref(r,t) = 1 ;
$ifi %flatdemand%==yes dctref(r,t) = 1 ;

pinv(r,t) = 1; plbi(r,t) = 1;
pelas(r,t) = %pelas%;

$ifthen.pelas %pelas%==0
paref(r,t) = 0;
$else.pelas
* For non-zero elasticity, load reference prices from appropriate reference run
execute_load '%elecrefgdx%.gdx', paref=p_lse;
$endif.pelas

* Calculate annual demand levels based on dref
daref(r,t) = 1e-3 * sum(s, load(s,r,t) * hours(s,t));

* Specify elasticity of gas supply and reference value (if elastic) [NOT CURRENTLY USED]
gelas(t) = %gelas%;
$ifthen.gelas %gelas%==0
  gref(t) = 0;
$else.gelas
* For non-zero gas supply elasticity, load reference gas demand from appropriate reference run
* Reference run should be a zero-elasticity instance with same gas price as current run
  execute_load '%grefgdx%.gdx', gref=usgastot;
$endif.gelas

* In dynfx mode, load D (along with dref) and XC variables from indicated dynamic run (consolidating data)
$iftheni.dynfx %dynfx%==yes
execute_load '%dynfxgdx%.gdx', dref, pf, dfx=D.L, xcfx=XC.L, tcfx=TC.L, itfx=IT.L, gcfx=GC.L, rsvoth;
xcfx(i,v,r,t) = round(xcfx(i,v,r,t),6) ;
* In cases where endogenous rental capacity is allowed for some capacity, we split the (i,v) sets to
* correspond to fixed and endogenous capacity blocks
i_end(i) = no;
set type_end(type)      Types that can be added endogenously in static mode /
                        nucl, nuca, wind, wnos, pvft, pvsx, pvdx, ngcc, nggt, ngcs, h2cc
$ifi %cspstorage%==yes  cspr
$ifi %iendbecs%==yes	becs
/;
$if not %i_end%==no i_end(new(i))$sum(idef(i,type), type_end(type)) = yes;
$if not %i_end%==no i_end("ngcc-xc") = no;
iv_fix(xtech,vbase) = yes;
iv_fix(new(i),vstatic)$(not i_end(i)) = yes;

* Remove capacity with near-zero values to prevent numerical issues in the static model
xcfx(i,v,r,t)$(xcfx(i,v,r,t) le 1e-3) = 0;
installedG(i,v,r,t) = 0;
installedG(i,v,r,t)$(vstatic(v) and newfossil(i)) = sum(ivrt(i,v,r,t),xcfx(i,v,r,t));
installedG(new(i),v,r,t)$((not newfossil(i)) and (vyr(v) = tyr(t))) =
                          sum(vv$(vyr(vv) <= tyr(t)), xcfx(i,vv,r,t));
installedG(xtech(i),v,r,t) = xcfx(i,v,r,t);
installedT(r,rr) = sum(t,tcfx(r,rr,t));

installedG(i,v,r,t)$(installedG(i,v,r,t) < eps) = 0;
installedT(r,rr)$(installedT(r,rr) < eps) = 0;

xcfx(i,v,r,t) = installedG(i,v,r,t);
xcfx(new(i),v,r,t)$((not newfossil(i)) and vyr(v) < tyr(t)) = 0;

* We truncate, rather than round, to prevent the possibility of rounding up and
* breaching a constraint
xcfx(i,v,r,t) = trunc(xcfx(i,v,r,t)*1000000)/1000000 ;

* * * * Replacing ivrt assignment with a simple conditional on xcfx or i_end
ivrt(i,v,r,t) = yes$((xcfx(i,v,r,t) and iv_fix(i,v)) or (i_end(i) and tv(t,v)));
* Remove inactive renewable classes
ivrt(i,v,r,t)$(irnw(i) and new(i) and not sameas(i,"wind-r") and (sum(iclass(i,type,class), capjlim(type,class,r)) eq 0 or (sum(iclass(i,type,class), solarcap(class,r)) eq 0 and sol(i)))) = no;
ivrt("wind-r",v,r,t)$(xcap("wind-x",r) eq 0) = no;

$endif.dynfx

* Setting --cap=ref provides a convenient way to fix U.S. electric sector CO2
* emissions to those in a reference scenario.
usemitref(pol,t) = 0 ;
$ifthen.co2ref %cap%==ref
execute_load '%elecrptrefgdx%.gdx', usemitref=usemit ;
co2cap(t,"ref")$(not tbase(t)) = 1e-3 * usemitref("co2",t) ;
$endif.co2ref

* Consider zero emissions caps for 2035 and 2050, with ramp-down requirements in prior years
* cap95by50 requires 60% reduction (relative to 2005) by 2035, 80% by 2040, and 90% by 2045
* zero50 cap adopts these targets, zero35 cap adopts the 2035 and 2040 targets ten years earlier
zerocap(t,"zero50") = yes$(t.val ge 2050);
zerocap(t,"zero35") = yes$(t.val ge 2035);
co2cap(t,"zero50") = co2cap(t,"cap95by50")$(t.val < 2050);
co2cap(t,"zero35") = co2cap(t+2,"cap95by50")$(t.val < 2035 and t.val > 2020);
$ifthen.manual set manualcap
$set cap %manualcap%
co2cap("2020","%cap%") = %mcap20%;
co2cap("2025","%cap%") = (2/3) * %mcap20% + (1/3) * %mcap35%;
co2cap("2030","%cap%") = (1/3) * %mcap20% + (2/3) * %mcap35%;
co2cap("2035","%cap%") = %mcap35%;
$ifthen.m50 set mcap50
co2cap("2040","%cap%") = (2/3) * %mcap35% + (1/3) * %mcap50%;
co2cap("2045","%cap%") = (1/3) * %mcap35% + (2/3) * %mcap50%;
co2cap("2050","%cap%") = %mcap50%;
$else.m50
$if set mcap40 co2cap("2040","%cap%") = %mcap40%;
$if set mcap45 co2cap("2045","%cap%") = %mcap45%;
$endif.m50
zerocap(t,"%cap%")$(t.val > 2015) = yes$(co2cap(t,"%cap%") eq 0);
$endif.manual

* * * Assemble and calculate state RPS parameters based on input load
rcmlim(r,t) = 1e-3 * sum(s, hours(s,t) * load(s,r,t)) * rpstgt_r(r,t) * rcmlim_r(r,t) * (1 + 0.1$cal_r(r));
nmrlim(r,t) = 1e-3 * sum(s, hours(s,t) * load(s,r,t)) * rpstgt_r(r,t) * nmrlim_r(r,t) * (1 + 0.1$cal_r(r));
acplim(r,t) = 1e-3 * sum(s, hours(s,t) * load(s,r,t)) * rpstgt_r(r,t) * acplim_r(r) * (1 + 0.1$cal_r(r));
soltgt(r,t) = 1e-3 * sum(s, hours(s,t) * load(s,r,t)) * soltgt_r(r,t);

* ------------------------------------------------------------------------------
* Mortgage calculations for revenue end effects

$ifthen.mcalc %static%==no

loop(i$sameas(i,"enee-n"),
mortgage_lt(i,v,r,t)$(vt(v,t) and (new(i) and newv(v))) = (af_t(i,v,r,t)$af_t(i,v,r,t) + 1$(not af_t(i,v,r,t))) * (
            1.0$(vyr(v) + sum(idef(i,type), invlife(type)) > t.val + nyrs(t)) +
            0.8$(vyr(v) + sum(idef(i,type), invlife(type)) eq t.val + nyrs(t)) +
            0.5$(vyr(v) + sum(idef(i,type), invlife(type)) eq t.val) +
            0.2$(vyr(v) + sum(idef(i,type), invlife(type)) eq t.val - nyrs(t))
);

* Lifetime parameter should be simply set to 1 for 2050+, since it can be continually expanded
mortgage_lt(new(i),"2050+",r,t)$vt("2050+",t) = (af_t(i,"2050+",r,t)$af_t(i,"2050+",r,t) + 1$(not af_t(i,"2050+",r,t)));

* A second parameter is needed to clarify when the 2050+ was incremented (with v replaced by t):
mortgage_lt50(new(i),t,r,tt)$(t.val ge 2050 and tt.val ge t.val) = (af_t(i,"2050+",r,t)$af_t(i,"2050+",r,t) + 1$(not af_t(i,"2050+",r,t))) * (
           1.0$(t.val + sum(idef(i,type), invlife(type)) > tt.val + nyrs(tt)) +
           0.8$(t.val + sum(idef(i,type), invlife(type)) eq tt.val + nyrs(tt)) +
           0.5$(t.val + sum(idef(i,type), invlife(type)) eq tt.val) +
           0.2$(t.val + sum(idef(i,type), invlife(type)) eq tt.val - nyrs(tt))
);

* Now calculate a hypothetical full lifetime over the extended time horizon
mortgage_lt_long(new(i),newv(v),t,r,t_all)$(tv(t,v) and vt_all(v,t_all) and t_all.val ge t.val) = (af_t(i,v,r,t_all)$af_t(i,v,r,t_all) + 1$(not af_t(i,v,r,t_all))) * (
            1.0$(t.val + sum(idef(i,type), invlife(type)) > t_all.val + nyrs_all(t_all)) +
            0.8$(t.val + sum(idef(i,type), invlife(type)) eq t_all.val + nyrs_all(t_all)) +
            0.5$(t.val + sum(idef(i,type), invlife(type)) eq t_all.val) +
            0.2$(t.val + sum(idef(i,type), invlife(type)) eq t_all.val - nyrs_all(t_all))
);
);

set    vv2          /2015,2020,2025,2030,2035,2040,2045,2050+/

       tt2          /2015,2020,2025,2030,2035,2040,2045,2050/

       t_all2       All possible time periods used in the model /
                        2015,2020,2025,2030,2035,2040,2045
                        2050,2055,2060,2065,2070,2075,2080,2085,2090
                        2095,2100,2105,2110,2115,2120,2125,2130,2135
                        2140,2145,2150,2155,2160,2165,2170,2175
                        /
       vvt(vv2,tt2)
       newv2(vv2)
       tv2(tt2,vv2)
       vt_all2(vv2,t_all2)
       tbase_all2(t_all2);

alias (tt2,ttt2);

parameter vvyr(vv2)
          nyrs2(tt2), nyrs_all2(t_all2)
          mortgage_lt2(i,vv2,r,tt2),mortgage_lt502(i,tt2,r,tt2),mortgage_lt_long2(i,vv2,tt2,r,t_all2)
          modellife2(i,vv2,r,tt2)
          dfact_all2(t_all2)
          tyr_all2(t_all2)
          tyr2(tt2)
          dfact2(ttt2)
;

nyrs2(tt2) = 5;
nyrs_all2(t_all2) = 5;

vvyr(vv2)$(not sameas(vv2,"2050+")) = vv2.val;
vvyr("2050+") = 2050;
vvt(vv2,tt2)$(tt2.val >= vvyr(vv2)) = yes;
tv2(tt2,vv2)$(tt2.val = vvyr(vv2)) = yes;
newv2(vv2)$(vvyr(vv2)>2015) = yes;
vt_all2(vv2,t_all2)$(t_all2.val >= vvyr(vv2)) = yes;

tyr2(tt2) = tt2.val;
dfact("2015") = 1;
dfact_all("2015") = 1;
tyr_all2(t_all2) = t_all2.val;

tbase_all2("2015") = yes;
dfact_all2("2015") = 1;
dfact_all2(t_all2)$(not tbase_all2(t_all2)) = (1 - drate)**(tyr_all2(t_all2-1) + 1 - sum(tbase, tyr2("2015"))) * (1 - (1 - drate)**(nyrs_all2(t_all2))) / drate;
dfact2("2015") = 1;
dfact2(tt2)$(tt2.val > 2015) = (1 - drate)**(tyr2(tt2-1) + 1 - sum(tbase, tyr2("2015"))) * (1 - (1 - drate)**(nyrs2(tt2))) / drate;

loop(i$(not sameas(i,"enee-n")),
mortgage_lt2(i,vv2,r,tt2)$(vvt(vv2,tt2) and (new(i) and newv2(vv2))) =  (
            1.0$(vvyr(vv2) + sum(idef(i,type), invlife(type)) > tt2.val + nyrs2(tt2)) +
            0.8$(vvyr(vv2) + sum(idef(i,type), invlife(type)) eq tt2.val + nyrs2(tt2)) +
            0.5$(vvyr(vv2) + sum(idef(i,type), invlife(type)) eq tt2.val) +
            0.2$(vvyr(vv2) + sum(idef(i,type), invlife(type)) eq tt2.val - nyrs2(tt2))
);

* Lifetime parameter should be simply set to 1 for 2050+, since it can be continually expanded
mortgage_lt2(new(i),"2050+",r,tt2)$vvt("2050+",tt2) = 1;

* A second parameter is needed to clarify when the 2050+ was incremented (with v replaced by t):
mortgage_lt502(new(i),tt2,r,ttt2)$(tt2.val ge 2050 and ttt2.val ge tt2.val) =  (
           1.0$(tt2.val + sum(idef(i,type), invlife(type)) > ttt2.val + nyrs2(ttt2)) +
           0.8$(tt2.val + sum(idef(i,type), invlife(type)) eq ttt2.val + nyrs2(ttt2)) +
           0.5$(tt2.val + sum(idef(i,type), invlife(type)) eq ttt2.val) +
           0.2$(tt2.val + sum(idef(i,type), invlife(type)) eq ttt2.val - nyrs2(ttt2))
);

* Now calculate a hypothetical full lifetime over the extended time horizon
mortgage_lt_long2(new(i),newv2(vv2),tt2,r,t_all2)$(tv2(tt2,vv2) and vt_all2(vv2,t_all2) and t_all2.val ge tt2.val) =  (
            1.0$(tt2.val + sum(idef(i,type), invlife(type)) > t_all2.val + nyrs_all2(t_all2)) +
            0.8$(tt2.val + sum(idef(i,type), invlife(type)) eq t_all2.val + nyrs_all2(t_all2)) +
            0.5$(tt2.val + sum(idef(i,type), invlife(type)) eq t_all2.val) +
            0.2$(tt2.val + sum(idef(i,type), invlife(type)) eq t_all2.val - nyrs_all2(t_all2))
);
);

* The numerator here is the sum of discount factors contained in the model time horizon
* The denominator is the sum of discount factors over the entire hypothetical lifetime of the investment
loop(i$(sameas(i,"enee-n")),
modellife(new(i),newv(v),r,t)$tv(t,v) = sum(tt$(tt.val ge t.val), dfact(tt) * (mortgage_lt(i,v,r,tt)$(not sameas(v,"2050+"))
                                        + mortgage_lt50(i,t,r,tt)$sameas(v,"2050+"))) /
                                        sum(t_all$(t_all.val ge t.val), dfact_all(t_all) * mortgage_lt_long(i,v,t,r,t_all))
;
);
loop(i$(not sameas(i,"enee-n")),
modellife2(new(i),newv2(vv2),r,tt2)$tv2(tt2,vv2) = sum(ttt2$(ttt2.val ge tt2.val), dfact2(ttt2) * (mortgage_lt2(i,vv2,r,ttt2)$(not sameas(vv2,"2050+"))
                                        + mortgage_lt502(i,tt2,r,ttt2)$sameas(vv2,"2050+"))) /
                                        sum(t_all2$(t_all2.val ge tt2.val), dfact_all2(t_all2) * mortgage_lt_long2(i,vv2,tt2,r,t_all2))
;
);

$iftheni.o2015 NOT %baseyronly%==yes
loop(i$(not sameas(i,"enee-n")),
modellife(new(i),"2020",r,"2020") = modellife2(i,"2020",r,"2020");
modellife(new(i),"2025",r,"2025") = modellife2(i,"2025",r,"2025");
modellife(new(i),"2030",r,"2030") = modellife2(i,"2030",r,"2030");
modellife(new(i),"2035",r,"2035") = modellife2(i,"2035",r,"2035");
modellife(new(i),"2040",r,"2040") = modellife2(i,"2040",r,"2040");
modellife(new(i),"2045",r,"2045") = modellife2(i,"2045",r,"2045");
modellife(new(i),"2050+",r,"2050") = modellife2(i,"2050+",r,"2050");
);
$endif.o2015

* Set hydrogen technology modellife parameter equal to that of h2cc generation (all H2 generation types have 40 year lifetimes)
modellife_h(hi,v,r,t) = modellife("h2cc-gsst",v,r,t);

* Set DAC technology modellife parameter equal to that of geothermal (30 years)
modellife_dac(dac,v,r,t) = modellife("geot-n",v,r,t);

$endif.mcalc

* Set capital charge rate to coincide with one year's worth of rental using above formula
capr(new(i)) = drate / (1 - (1+drate)**(-sum(idef(i,type), invlife(type))));

* ------------------------------------------------------------------------------------------------------------------- *
* First part of code to fix investment for a given set of years to what occurred in the baseline
$iftheni.fixix1 not %fixIX%==no
parameter ixfx(i,r,t), itfx(r,r,t), lifetimeref(i,r,t) ;
execute_load '%fixIXgdx%.gdx', ixfx=IX.L, itfx=IT.L, lifetimeref=lifetime ;
$endif.fixix1

* * * Natural Gas Supply Function Calibration [NOT CURRENTLY USED]

$ifthen not declared cumngf
table   cumngf(*,ngp)     Cumulative fraction of gas supply by step (ngp is loaded from base GDX)
        ngp1  ngp2  ngp3  ngp4  ngp5  ngp6  ngp7  ngp8  ngp9  ngp10 ngp11 ngp12 ngp13 ngp14 ngp15 ngp16
  s1    0.50  0.75  0.85  0.90  0.95  0.99  1.01  1.05  1.10  1.20  1.30  1.40  1.50  1.60  1.75  2.00
  s2    0.50  0.75  0.90  0.95  0.97  0.99  1.01  1.03  1.05  1.10  1.15  1.20  1.35  1.50  1.75  2.00
;
$endif

* Supply steps for natural gas supply are determined relative to reference point
ngcap( ngp,t)$gelas(t) = (cumngf("%ngplsteps%",ngp) - cumngf("%ngplsteps%",ngp-1)) * 1000 * gref(t);
ngcost(ngp,t)$gelas(t) = pf("ng",t) * (1 + (cumngf("%ngplsteps%",ngp) - cumngf("%ngplsteps%","%refstep%")) / gelas(t));

* * * Demand function calibration

* Define consumer benefit based on a linear demand curve that has a negative elasticity
* pelas(r) at the point (daref,paref). Consumer benefit for demand x is equal to
* the integral of the inverse demand function P(x) from 0 to x, where
*
* P(x) = paref + (1/pelas)*(paref/daref)*(x - daref).
*
* If we state the integral of P(x) as cb_1*x + 0.5*cb_2*x^2,
* the appropriate coefficients are as follows:

cb_1(r,t)$pelas(r,t) = paref(r,t) * (1 - 1/pelas(r,t));

cb_2(r,t)$pelas(r,t) = (1/pelas(r,t))*(paref(r,t)/daref(r,t));

* * * Carbon market function calibration [FOR USE ONLY IN ITERATION WITH A NON-ELECTRIC MODEL 'NEM']
$macro nem_1(t)      (p_nem(t) * (1/elas_nem(t) - 1))
$macro nem_2(t)      (-0.5 * (1/elas_nem(t))*(p_nem(t)/q_nem(t)))
$macro nem_rg_1(r,t) (p_nem_rg(r,t) * (1/elas_nem_rg(r,t) - 1))
$macro nem_rg_2(r,t) (-0.5 * (1/elas_nem_rg(r,t))*(p_nem_rg(r,t)/q_nem_rg(r,t)))

;

* * * Define generation dispatch cost

cost(i,v,r,t)$ivrt(i,v,r,t) =
*       Variable O&M costs (multiplied by labor-intermediate price index)
          vcost(i,v,r) * plbi(r,t)
*       Fuel costs (including i-specific price delta)
        + sum(f, ifuel(i,f) * htrate(i,v,f,r,t) * (pf(f,t) + pfadd(i,f,r,t)))
*       Pollutant prices
        + sum(pol, emit(i,v,pol,r,t) * pp(pol,t))
*       Regional pollutant prices
        + sum(pol, emit(i,v,pol,r,t) * pp_rg(pol,r,t))
*       Implicit CES tax or subsidy
        + cestax(i,v,r,t)
*       Production Tax Credit (if applicable)
        - sum(idef(i,type),ptc(type,v))$ptctv(t,v)
*       CO2 Storage 45Q Credit (will be 0 if not activated)
        - ccs45Q(i,v,r,t)
;

* * * Define hydrogen dispatch cost

hcost(hi,v,r,t)$vt(v,t) =
*       Variable O&M costs (multiplied by labor-intermediate price index)
          vcost_h(hi,v) * plbi(r,t)
*       Fuel costs (including r-specific price delta) (non-electric only)
        + sum(f, eph2(hi,f,v) * (pf(f,t) + pfadd_r(f,r,t)))
*       Pollutant prices
        + sum(pol, emit_h(hi,v,pol) * pp(pol,t))
*       Regional pollutant prices
        + sum(pol, emit_h(hi,v,pol) * pp_rg(pol,r,t))
*       CO2 Storage 45Q Credit (will be 0 if not activated)
        - ccs45Q_h(hi,v,t)
;

* * * Define direct air capture variable cost

daccost(dac,v,r,t)$vt(v,t) =
*       Variable O&M costs
        vcost_dac(dac,v) * plbi(r,t)
*       Fuel costs (including r-specific price delta) (non-electric only, pf("ele") = 0)
        + sum(f, epdac(dac,f,v) * (pf(f,t) + pfadd_r(f,r,t)))
*       CO2 storage 45Q credit (will be 0 if not activated)
        - ccs45Q_dac(dac,v,t)
;

* ------------------------------------------------------------------------------
* Energy storage code

parameters
icg(j,t)   Storage investment capital cost ($ per kW charging capacity)
irg(j,t)   Storage room investment cost ($ per kWh storage capacity)
;

$if not set storroom       $setglobal storroom       150
icg("bulk",t) = %storcost%;
icg("caes",t) = %caescost%;
irg("bulk",t) = %storroom%;
irg("caes",t) = 100;

* Battery room and door costs are read in upstream (multiple scenarios)
irg("li-ion",t) = sum(tv(t,v), batt_en("%batttlc%",v));
icg("li-ion",t) = sum(tv(t,v), batt_pow("%batttlc%",v));

* Storage capacity -- Room size of different storage options (in hours)
* Note: In the latest formulation, storage has a cost and separate decision variables for
*       door (GC) and room (GR) unless ratio is fixed (fixghours)
*        Existing pumped hydro
ghours("hyps-x",r) = 20;
*        Generic "bulk" storage (currently parameterized based on NaS)
ghours("bulk",r) = %roomsize%;
*        CAES
ghours("caes",r) = 10;
*        Battery storage (currently based on lithium-ion)
ghours("li-ion",r) = 2;

* Charge penalty
chrgpen("hyps-x") = 1.2;
chrgpen("bulk") = 1.7;
chrgpen("caes") = 0.8;
chrgpen(batt) = 1.1;

parameters
* Loss factor from accumulated storage -- Based on 10% loss in capacity after 1 month
loss_g(j)       Loss rate from accumulated storage /
                li-ion   0.000146
                /
* Storage HR -- For CAES, assume 0.4 MWh gas (plus 0.8 MWh electricity) per MWh discharge
htrate_g(j)     Fuel consumption at storage discharge (GJ per MWh) /
                caes    1.44
                /
vcg(j,r,t)      Variable cost for storage technologies ($ per MWh)
;

vcg(j,r,t) = htrate_g(j) * (0.9478 * (pf("NG",t) + pfadd("ngcc-n","NG",r,t)) + 0.051 * (pp("co2",t) + pp_rg("co2",r,t)));

* If storage is active, then allow existing pumped hydro to endogenously dispatch
$ifi not %storage%==no hyps(s,r,t) = 0;

* Set investment lifetime for storage
invlife_g("hyps-x") = 100;
invlife_g("bulk") = 20;
invlife_g("caes") = 30;
invlife_g("li-ion") = %battlife%;

* Set capital charge rate for storage and DAC
capr_g(j) = drate / (1 - (1 + drate)**(-invlife_g(j)));

capr_dac(dac) = drate / (1 - (1 + drate)**(-invlife_dac(dac)));


* * * * * * * * * * * * * * * * MODEL FORMULATION:  Variables and Equations * * * * * * * * * * * * *  *

positive variable
        X(s,i,v,r,t)      Unit dispatch by segment (in GW)
        XN(nc,r,t)        Nuclear generation (in TWh)
        XC(i,v,r,t)       Installed generation capacity (in GW)
        XCS(s,i,v,r,t)    Copies of XC for sparsity purposes
        XTWH(i,v,r,t)     Sum over s of X*hours*1e-3 (yielding TWh) for sparsity purposes
        IX(i,r,t)         New vintage investment (total GW to be added from t-1 to t)
        DR(s,r,t)         Demand response (backstop demand option) (in GW)
        DRC(s,r,t)        Curtailment of distributed resource (negative demand response) (in GW)
        GRID(s,r,t)       Total grid-based generation by segment (GW)
        GRIDTWH(r,t)      Total annual grid-based generation (TWh)
        D(r,t)            Demand index relative to reference
        E(s,r,r,t)        Bilateral trade flows by load segment (in GW)
        ER(s,r,r,t)       Exportable renewable power by load segment (in GW)
        NUPR(r,t)         Existing nuclear unit uprates in period t (GW)
        EC(s,r,t)         Exportable clean electricity by load segment into California (in GW)
        UI(t)             Unspecified imports into CA (in TWh per year)
        RPC2(r,t)         Renewable clean electricity contract bundled RECs (in TWh)

        TC(r,r,t)         New Trade flow capacity (in GW)
        IT(r,r,t)         Investment in transmission (total GW to be added from t-1 to t)
        DBS(db,r,t)       Dedicated biomass supply by class (trillion btu)
        NGS(ngp,t)        NG supply by class (trillion btu)
        NEM(t)            Non-electric CO2 emissions (billions tons CO2)
        NEM_RG(r,t)       Regional non-electric CO2 emissions (billions tons CO2)
        RPC(r,r,t)        Renewable power contract bundled RECs (in TWh)
        ACP(r,t)          Alternative compliance payment certificates for state RPS (in TWh)
        SV(t)             Safety valve allowance purchases (billion metric tons CO2)
        G(s,j,r,t)        Energy storage charge (in GW)
        GD(s,j,r,t)       Energy storage discharge (in GW)
        GC(j,r,t)         Energy storage capacity (size of door) (in GW)
        GR(j,r,t)         Energy storage capacity (size of room) (in GWh)
        IGC(j,r,t)        Investment in storage charge-discharge capacity (in GW)
        IGR(j,r,t)        Investment in storage size of room (in GWh)
        GB(s,j,r,t)       Energy storage accumulated balance (in GWh)
        X_CSP_CR(s,i,r)   CSP power reaching receiver from incoming DNI (GW-th)
        C_CSP_CR(i,r)     Installed (rented) CSP collector + receiver capacity (GW-th)
        G_CSP(s,i,r)      Storage charge from CSP receiver (after losses) (GW-th)
        GD_CSP(s,i,r)     Storage discharge from CSP TES (GW-th)
        GR_CSP(i,r)       Installed (rented) CSP storage capacity (size of room) (GWh-th)
        GB_CSP(s,i,r)     Dynamic balance of installed CSP storage capacity utilization (GWh-th)
        RC(class,r,t)     Cumulative retired coal capacity by class in GW
        PKGRID(r,t)       Peak grid-supplied residual load (net of intermittent renewables and pumped hydro) by region (GW)
        RMARG(r,t)        Reserve margin at peak load by region (GW additional)
* CES
        CESTOT(r,t)       Total System TWh under the CES policy
        CES_ACP(r,t)      Level of alternative compliance payments to avoid CES cap
* Operating reserve variables
$ifthen not %opres%==no
        SR(s,i,v,r,t)     Spinning Reserve provided by capacity block in a segment (GW)
        SRJ(s,j,r,t)      Spinning reserve provided by storage (GW)
        SPINREQ(s,r,t)    Spinning Reserve requirement in a segment (GW)
        QS(s,i,v,r,t)     Quick start reserve provided by a capacity block in a segment (GW)
        QSJ(s,j,r,t)      Quick start reserve provided by storage (GW)
        QSREQ(s,r,t)      Quick start reserve requirement (GW)
$endif

* Hydrogen model
        HX(s,hi,v,r,t)    Dispatch of hydrogen production capacity (billion btu per hour)
        HC(hi,v,r,t)      Hydrogen production capacity (billion btu per hour)
        HCS(s,hi,v,r,t)   Copies of HC for sparsity purposes
        HPROD(hi,v,r,t)   Annual production of hydrogen (trillion btu per year)
        IH(hi,r,t)        New vintage investment (total billion btu per hour to be added from t-1 to t)
        HDU(hi,r,t)       Hydrogen for direct use by (centralized) production source (trbtu)
* Direct air capture technologies
        DACC(dac,v,r,t)         Direct air capture capacity (MtCO2 net removal per year)
        IDAC(dac,r,t)           New vintage investment in direct air capture capacity (MtCO2 per year)
        DACX(s,dac,v,r,t)       Dispatch of CO2 from direct air capture (thousand tCO2 per hour)
        DACANN(dac,v,r,t)       Total annual net removal from dac (MtCO2 per year)
* CO2 pipeline and storage model
        CX(r,r,t)         CO2 pipeline flow (million tonnes per year)
        PC(r,r,t)         Total CO2 pipeline capacity (million tonnes per year)
        CSTOR(r,t)        CO2 annual flow (million tonnes per year)
        CCRED(v,r,t)      CO2 storage that qualifies for 45Q credit (million tonnes per year)
        IP(r,r,t)         Investment in CO2 pipelines (million tonnes per year to be added from t-1 to t)
        IInj(r,t)         Investment in CO2 injection (million tonnes per year to be added from t-1 to t)
        InjC(r,t)         Total CO2 injection capacity (million tonnes per year)
;
variable
        DA(r,t)             Annual total end-use electric consumption by region (in TWh)
        NBC(t)              Net banked credits (billion metric tons CO2)
        NBC_RG(r,t)         Regional net banked credits (billion metric tons CO2)
        NBC_RGGI(t)         Net banked credits in RGGI market (billion metric tons CO2)
        NBC_CSAPR(trdprg,t)       Net banked credits in CSAPR trading markets (million metric tons)
        NTX_CSAPR(trdprg,pol,r,t) Net exported credits in CSAPR trading markets (million metrics tons)
        CBC(t)              Cumulative banked credits (billion metric tons CO2)
        CBC_RG(r,t)         Regional cumulative banked credits (billion metric tons CO2)
        CBC_RGGI(t)         Cumulative banked credits in RGGI market (billion metric tons CO2)
        CBC_CSAPR(trdprg,t) Cumulative banked credits in CSAPR trading markets (million metric tons)
        NMR(r,t)            Net imports of unbundled RECs for state RPS (in TWh)
* CES
        CES_NTX(r,t)        Net unbundled CES credit imports by region per period
        CES_NBC(t)          Banking of CES credits per period
        BCEC(r,r,t)         Bundled clean electricity credits (in TWh)
        EC2(s,r,r,t)        Exportable clean electricity by load segment (in GW)

        SURPLUS             Social surplus (negative of) in $ million
;
equation
        objdef                  Objective function -- definition of surplus
        demand(s,r,t)           Electricity market clearing condition
        enduseload(s,r,t)       Disposition of electricity supply and demand
        annuald(r,t)            Annual total electricity demand
        xtwhdef(i,v,r,t)        Calculate XTWH from X
        gridtwhdef(r,t)         Calculate GRIDTWH from GRID
        copyxc(s,i,v,r,t)       Make copies of XC in XCS
        nucshr(nc,r,t)          Nuclear share classes
        nuctot(r,t)             Total nuclear generation
        invest(i,v,r,t)         Accumulation of annual investment flows
        investstatic(i,v,r,t)   Transfer new additions to installed
        capacity(s,i,v,r,t)     Generation capacity constraint on dispatch
        cofire(s,i,r,t)         Coal capacity can be dispatched as coal or co-fire
        cofirecap(s,i,r,t)      Reported co-fire coal capacity is limied by installed coal
        capacitymin(s,i,v,r,t)  Dispatch for units subject to minimum
        capacityfx(s,i,v,r,t)   Non-dispatched capacity
        capacitylim(i,r,t)      Limits on total installed capacity
        capacityjointlim(type,class,r,t) Limits on joint total installed capacity
        investlim(type,r,t)     Upper bounds on per period regional investment by type
        usinvestlim(tech,t)     Upper bounds on per period national investment by technology
        tusinvestlim(t)         National limits on per period transmission investment
        retiresch(class,r,t)    Maintain original coal retirement schedule
        retireamt(class,r,t)    Evaluate coal retirement amount (includes scheduled retirement)
        retiremon(class,r,t)    Monotonicity of coal retirement
        convgassch(class,r,t)   Planned coal gas conversions
        convbiosch(class,r,t)   Planned coal biomass conversions
        convert1(class,r,t)     Cap on initial conversion (1st phase)
        convert2(i,r,t)         Cap on further conversion (2nd phase)
        retro(class,r,t)        Retrofit eligibility for existing coal
        irrlim(t)               Upper bound on total environmental retrofits based on IRR hurdle rate
        irrlim_rcl(r,class,t)   Region-class upper bound on total environmental retrofits based on IRR hurdle rate
        retire(i,v,r,t)         Monotonicity constraint on installed capacity
        tinvest(r,r,t)          Accumulation of annual transmission investment flows
        tinveststatic(r,r,t)    Transfer new trans additions to installed
        tcapacity(s,r,r,t)      Transmission capacity constraint on trade
        biomarket(r,t)          Supply demand equilibrium for dedicated bioenergy
        carbonmarket(t)         Policy constraint on carbon emissions
        carbonmarket_rg(r,t)    Policy constraint(s) on carbon emissions for individual regions
        carbonmarket_ny(t)      Carbon target for NY electric sector (bmt co2)
        rggimarket(t)           RGGI joint CO2 cap across certain regions
        csapr_r(trdprg,pol,r,t)        CSAPR policy constraint on annual and seasonal non-co2 emissions by region and trading program
        csapr_trdprg(trdprg,t)         CSAPR policy trading program market equation
        itnbc                   Intertemporal budget constraint on net banked credits
        itnbc_rg(r)             Regional intertemporal budget constraint on net banked credits
        itnbc_rggi              Intertemporal budget constraint on net banked credits for RGGI market
        itnbc_csapr(trdprg)      Intertemporal budget constraint on net banked NOx and SO2 credits for CSAPR annual markets
        cbcdf(t)                Definition of cumulative banked credits
        cbcdf_rg(r,t)           Regional definition of cumulative banked credits
        cbcdf_rggi(t)           Definition of cumulative banked credits for RGGI market
        cbcdf_csapr(trdprg,t)   Definition of cumulative banked credits for CSAPR annual NOx and SO2 markets
        fedrps(t)               Federal RPS
        fullrps(t)              Federal RPS forcing generation to be fully renewable
	fullrps_h(t)            Federal RPS forcing hydrogen production to be fully green
        staterps(r,t)           State and regional level RPS requirements
        recmkt(t)               Unbundled REC market balance for state RPS
        rpcgen(s,r,t)           Exportable renewable power cannot exceed generation
        rpctrn(s,r,r,t)         Exportable renewable power cannot exceed transmission
        rpcflow(r,r,t)          RECs bundled with RPCs must be supported by exportable renewable power
        rpsimports(r,t)         Upper bound on total imported compliance with state RPS
        rpssolar(r,t)           Carve-outs for solar PV in state RPS
        wnosmandate(r,t)        Offshore wind mandate
        nucst(r,t)              State nuclear support constraint (GW)
        sb100ces(t)             California SB-100 clean electricity standard constraint
        rpcgen2(s,r,t)          Exportable clean electricity cannot exceed generation
        rpctrn2(s,r,t)          Exportable renewable power cannot exceed transmission
        rpcflow2(r,t)           RECs bundled with RPCs must be supported by exportable clean electricity
        uidef(t)                Definition of unspecified imports (TWh)
*	Thermal storage (CSP)
        capacity_csp_cr(s,i,r)  Capture of DNI by CSP solar collector and receiver capacity constraint
        dispatch_csp(s,i,r)     CSP dispatch must come from solar collector or storage
        storagebal_csp(s,i,r)   CSP Dynamic storage balance
        storagelim_csp(s,i,r)   CSP Size of room
*	All other storage
        ginvestc(j,r,t)         Investment in storage (size of door)
        ginvestr(j,r,t)         Investment in storage (size of room)
        chargelim(s,j,r,t)      Charge cannot exceed capacity (size of door)
        dischargelim(s,j,r,t)   Discharge cannot exceed capacity (size of door)
        storagebal(s,j,r,t)     Dynamic storage balance accumulation
        storagelim(s,j,r,t)     Storage reservoir capacity (size of room)
        storageratio(j,r,t)     Size of room relative to size of door (option to fix)
        storagesum(j,r,t)       Storage charge-discharge energy conservation balance
        storagefx(t)            Exogenous storage capacity constraint
        storagefxlo(j,r,t)      Exogenous storage capacity lower bound
        gasmarket(t)            NG usage (quad btu)
*	Reserve margins
        reserve(r,t)            Reserve margin by region and period
        peakgrid(s,r,t)         Define peak residual load for grid-supplied energy (net of pumped hydro and intermittent renewables) by region (GW)
        resmargin(s,r,t)        Define reserve margin at peak grid-supplied load by region (GW)

        solarlim(class,r,t)     Joint capacity constraint on PV and CSP (upstream profile data comes from same land)
        windrepowerlim(r,t)     Sum of existing and repowered wind capacity cannot exceed base year wind capacity
        cflim(i,v,r,t)          Limit annual cf by unit
*	Clean Energy Standard
        cesmkt(r,t)             Clean Energy Standard credit supply-credit demand balance equation
        cestrade(t)             Clean Energy Standard regional (unbundled) credit trading market
        cestotdef(r,t)          Definition of system total for CES compliance (i.e. denominator of the CES credit balance equation)
        bcegen(s,r,t)           Exportable clean electricity cannot exceed generation
        bcetrn(s,r,r,t)         Exportable clean electricity cannot exceed transmission
        bceflow(r,r,t)          Bundled CES credits must be supported by exportable clean electricity
        cesexport(r,t)          Upper bound on total exported CES compliance instruments

*	Equations relating to operating reserves
$iftheni not %opres%==no
        srav(s,i,v,r,t)         Ensure spinning reserve is only available when unit is generating
        srreqt(s,r,t)           Spinning reserve market
        spinreqdef(s,r,t)       Definition of spinning reserve requirement
        qsreqdef(s,r,t)         Definition of quickstart reserve requirement
        qsreqt(s,r,t)           Quickstart reserve market
        srramp(s,i,v,r,t)       Limit on amount of spinning reserve capacity some units can provide
        stordef(s,j,r,t)        Storage definition mutually exclusive provision of services
$endif
*       Hydrogen model
        hcapacity(s,hi,v,r,t)   Hydrogen production capacity constraint on dispatch
        hinvest(hi,v,r,t)       Accumulation of hydrogen production capacity investment
        hretire(hi,v,r,t)       Monotonicity constraint on installed hydrogen production capacity
        hannuald_c(hi,r,t)      Annual total hydrogen demand (centralized) by hydrogen production pathway hi
        hannuald_d(r,t)         Annual total hydrogen demand (distributed)
        hdumarket(r,t)          Market for direct use of hydrogen (centralized)
        copyhc(s,hi,v,r,t)      Make copies of HC in HCS
        hproddef(hi,v,r,t)      Annual total hydrogen production by technology and vintage
*       CO2 Storage and Transport model
        co2balance(r,t)         Balancing constraint on CO2 sources and sinks in each region and segment
        co2storcap(r)           Constraint on CO2 storage in each region
        co2pinvest(r,r,t)       Accumulation of CO2 pipeline investments
        co2pcapacity(r,r,t)     CO2 pipeline capacity constraint
        co2injinvest(r,t)       Accumulation of CO2 injection investments
        co2injcapacity(r,t)     CO2 injection capacity constraint
*       DAC model
        daccapacity(s,dac,v,r,t) Utilization of DAC must not exceed installed capacity
        dacinvest(dac,v,r,t)    Accumulation of DAC capacity investment
        dacretire(dac,v,r,t)    Monotonicity constraint on installed DAC capacity
        annualdac(dac,v,r,t)    Annual total CO2 captured from DAC (million t-CO2)
;

objdef..
*       Negative of
                SURPLUS =e= sum(t, dfact(t) *
        (sum(r,

*       Investment flows are annualized evenly across period in dynamic model,
*       rented at a fixed charge rate in static model
*       Capital cost of total period investment in generation capacity
                sum(new,
$ifi     %static%==no   (1 + tk) * ((pinv(r,t)/nyrs(t))) *
$ifi not %static%==no   (1 + tk) * (capr(new)) *
                IX(new,r,t) * sum(tv(t,v)$ivrt(new,v,r,t), (capcost(new,v,r) + tcostadder(new) - itcval(new,v,r)) *
$ifi %ptcv%==yes modellife(new,v,r,t)
$ifi NOT %ptcv%==yes  1
                )) +
$ifi     %static%==no   (1 + tk) * ((pinv(r,t)/nyrs(t))) * (
$ifi not %static%==no   (1 + tk) * (drate) * (
*       Capital cost of total period investment in transmission capacity
                sum(rr$tcapcost(r,rr), IT(r,rr,t) * tcapcost(r,rr))
*       Capital cost of total period investment in CO2 pipeline capacity
              + sum(rr$pcapann(r,rr), IP(r,rr,t) * pcapann(r,rr))
*       Capital cost of total period investment in CO2 injection capacity
              + IInj(r,t) * icapann(r)
*       Capital cost of total period investment in storage capacity
$ifi not %storage%==no  + sum(j, capr_g(j) / drate * (IGC(j,r,t) * icg(j,t) + IGR(j,r,t) * irg(j,t)))
*       Capital cost of total period investment in storage thermal capacity for CSP
$ifi not %cspstorage%==no + sum(cspi, (capr(cspi)/drate) * irg_csp(cspi) * GR_CSP(cspi,r))
*       Capital cost of CSP receiver/collector
$ifi not %cspstorage%==no + sum(cspi, (capr(cspi)/drate) * ic_csp_cr(cspi) * C_CSP_CR(cspi,r))
*       Capital cost of total period investment in hydrogen production capacity
              + sum((hi,tv(t,v)), IH(hi,r,t) * capcost_h(hi,v) *
$ifi %ptcv%==yes modellife_h(hi,v,r,t)
$ifi NOT %ptcv%==yes  1
              )
*       Capital cost of total period investment in DAC capacity
                + sum((dac,tv(t,v)), IDAC(dac,r,t) * capcost_dac(dac,v) *
$ifi %ptcv%==yes modellife_dac(dac,v,r,t)
$ifi NOT %ptcv%==yes  1
              )
              )  !! end pinv-dependent costs

*       Dispatch cost for generation (excludes cost of biomass fuel and has only the base gas price)
              + 1e-3 * sum(ivrt(i,v,r,t), cost(i,v,r,t) * sum(s, X(s,i,v,r,t) * hours(s,t)))
*       Dispatch cost for hydrogen production
              + 1e-3 * sum(hivrt(hi,v,r,t), hcost(hi,v,r,t) * sum(s, HX(s,hi,v,r,t) * hours(s,t)))
*       Dispatch cost for CO2 injection (VOM of $0.03 per tonne CO2)
              + CSTOR(r,t) * 0.03
*       Dispatch costs of direct air capture
              + 1e-3 * sum((dac,vt(v,t)), daccost(dac,v,r,t) * sum(s, DACX(s,dac,v,r,t) * hours(s,t)))
*        Dispatch cost for storage (CAES only)
$ifi not %storage%==no + 1e-3 * sum(j, vcg(j,r,t) * sum(s, GD(s,j,r,t) * hours(s,t)))
*       Cost of biomass fuel supply
              + sum(db, DBS(db,r,t) * biocost("%fsmv%",db,t))
*       Alternative compliance payments for state RPS
              + ACP(r,t) * acpcost(r)
*       Remaining costs are subject to labor-intermediate price index in macro model
              + plbi(r,t) * (
*       Cost of providing operating reserves
$ifi not %opres%==no + sum(s, sum((i,v), (SR(s,i,v,r,t) * sum(idef(i,type), orcost(type))) + sum(j, orcostg(j) * SRJ(s,j,r,t))) * hours(s,t) * 1e-3)
*       Cost of demand response
$ifi not %bs%==no    + sum(s, DR(s,r,t) * drcost(r) * hours(s,t) * 1e-3)
                     + sum(s, DRC(s,r,t) * drccost(r) * hours(s,t) * 1e-3)
*       Public acceptance cost for incremental nuclear generation
              + sum(nc, XN(nc,r,t) * nccost(nc))
*       Fixed Maintenance cost for capacity
              + sum(ivrt(i,v,r,t), XC(i,v,r,t) * fomcost(i,r))
*       Fixed Maintenance cost for DAC
              + sum((dac,vt(v,t)), DACC(dac,v,r,t) * fomcost_dac(dac,v))
*       Maintenance cost for CSP collector + receiver (power block cost included in fomcost)
$ifi not %cspstorage%==no  + sum(cspi, fc_csp_cr * C_CSP_CR(cspi,r))
*       Fixed Maintenance cost for hydrogen production capacity
              + sum(hivrt(hi,v,r,t), HC(hi,v,r,t) * fomcost_h(hi))
*       Fixed Maintenance cost for CO2 pipeline capacity (2.5% of capital), model will build PC in both directions so pipeline fom should be cut in half
              + sum(rr$pcapann(r,rr), PC(r,rr,t) * pcapann(r,rr) * (pipeom / 2))
*       Fixed Maintenance cost for CO2 injection capacity
              + InjC(r,t) * ifomann(r)
*       Transaction cost for inter-region trade
              + sum((s,rr)$tcapcost(r,rr), E(s,r,rr,t) * tcost(r,rr) * hours(s,t) * 1e-3)
              )  !! end plbi-dependent costs

*       Less consumer surplus (at annual level) if pelas is < 0
              - (cb_1(r,t) * DA(r,t) + 0.5 * cb_2(r,t) * DA(r,t) * DA(r,t))$pelas(r,t)

*       Abatement supply schedule for regional non-electric abatement
              + 1e3 * (nem_rg_1(r,t) * NEM_RG(r,t) + nem_rg_2(r,t) * NEM_RG(r,t) * NEM_RG(r,t))$(co2cap_rg(r,t,"icap") and (co2cap_rg(r,t,"icap") < inf) and elas_nem_rg(r,t))
$ifi %nco2%==yes      + AC(r,t)
*       Alternative compliance payments for ces
$ifi NOT %cesacp%==no  + CES_ACP(r,t) * cesacpr(t)
        )  !! end regional sum

*       CO2 tax associated with unspecified imports
$ifi %CA_SB100%==yes + UI(t) * sb100impcost(t)

*       Abatement supply schedule for national non-electric abatement
              + 1e3 * (nem_1(t) * NEM(t) + nem_2(t) * NEM(t) * NEM(t))$(((co2cap(t,"icap") and co2cap(t,"icap") < inf) or (co2ecap(t) and co2ecap(t) < inf)) and elas_nem(t))
*       Safety valve allowance purchases for federal cap or intensity standard
$ifi not %svpr%==no  + SV(t) * svpr(t,"%svpr%") * 1e3
*       Incremental NG fuel cost (negative for supply steps less than reference point) if gelas > 0
              + sum(ngp, NGS(ngp,t) * (ngcost(ngp,t) - pf("ng",t)))$gelas(t)
        ))
;

* The main market clearance equation in the model sets grid-based generation equal to
* grid-based energy for load in each segment
demand(s,r,t)..
*       Scale from GW to TWh so that marginal value is denominated in $ per MWh
        1e-3 * hours(s,t) * (
*       Dispatched generation in region
                sum(ivrt(i,v,r,t), X(s,i,v,r,t))
*       Plus inter-region imports
              + sum(rr$tcapcost(rr,r), E(s,rr,r,t))
*       Less inter-region exports (including loss penalty)
              - sum(rr$tcapcost(r,rr), trnspen(r,rr) * E(s,r,rr,t))
*       Plus discharges from storage less charges (including penalty)
$ifi not %storage%==no  + sum(j, GD(s,j,r,t) - chrgpen(j) * G(s,j,r,t))
*       Less net charge of existing pumped storage
              - hyps(s,r,t)
*       Less net international exports (annual TWh scaled uniformly to segment level GW)
              - (ntxintl(r) / 8.76)
*       Less electricity consumed for central station hydrogen production (mainly electrolysis but also gas-based) (convert billion btu per hour to GW)
              - sum(hivrt(hi,v,r,t)$(not sameas(hi,"elys-d")), (1/3.412) * eph2(hi,"ele",v) * HX(s,hi,v,r,t))
*       Less electricity demand from DAC
              - sum((dac,vt(v,t)), (1/3.412) * epdac(dac,"ele",v) * DACX(s,dac,v,r,t))
        )
*       Equals total local grid-supplied energy for load
            =e= 1e-3 * hours(s,t) * GRID(s,r,t)
;

enduseload(s,r,t)..
*       Scale from GW to TWh so that marginal value is denominated in $ per MWh (discounted)
*       Grid-supplied energy minus losses plus net supply from distributed resources plus demand response equals
        1e-3 * hours(s,t) * (GRID(s,r,t) / localloss + netder(s,r,t) - DRC(s,r,t) + DR(s,r,t))
*       Total end-use consumption (possibly scaled by price elasticity)
         =e= 1e-3 * hours(s,t) * (D(r,t) * load(s,r,t)
*       Plus electricity consumed for distributed electrolysis hydrogen production (convert billion btu per hour to GW)
              + sum(hivrt("elys-d",v,r,t), (1/3.412) * eph2("elys-d","ele",v) * HX(s,"elys-d",v,r,t)))
;

*       Annual demand is sum of all end-use electric consumption (only used to approximate a price-elastic response)
*       Excludes demand response measures
annuald(r,t)..
        DA(r,t) =e= 1e-3 * D(r,t) * sum(s, hours(s,t) * load(s,r,t));

*       Structural equations to aid solver
xtwhdef(ivrt(i,v,r,t))..  XTWH(i,v,r,t) =e= 1e-3 * sum(s, X(s,i,v,r,t) * hours(s,t));
gridtwhdef(r,t).. GRIDTWH(r,t) =e= 1e-3 * sum(s, GRID(s,r,t) * hours(s,t));
copyxc(s,ivrt(i,v,r,t))..  XCS(s,i,v,r,t) =e= XC(i,v,r,t)$(ord(s)=1) + XCS(s-1,i,v,r,t)$(ord(s)>1);

*       Nuclear generation classified by share of total generation:
nucshr(nc,r,t)$(not sameas("%seg%","8760"))..  XN(nc,r,t) =l= nclvl(nc,r) * sum(ivrt(i,v,r,t), XTWH(i,v,r,t));

*   Total nuclear generation must be equal when summed
*   across technologies and across penetration levels
nuctot(r,t)$(not sameas("%seg%","8760")).. sum(nc, XN(nc,r,t)) =e= sum(ivrt(nuc(i),v,r,t), XTWH(i,v,r,t));

* A variety of adjustment factors are applied to capacity to determine potential dispatch.
* These include availability factors that may or may not vary by segment (af_m),
* variable resource factors that vary by segment (af_s), and in some cases time trends in the
* shape of availability or variability (af_t and vrsc_t). In each case, the parameter applies
* to only a subset of technologies.  To avoid creating a very large parameter matrix with many
* placeholder entries of 1, we use the following construct to perform a conditional product:

* 1 + (par(i) - 1)$par(i) = par(i) if it is defined, 1 otherwise

* NB: It is crucial that Eps is used for parameters where only some of the segments are populated
* In these cases the zero is intended as a zero instead of a 1.

*       Dispatch of units cannot exceed available capacity
capacity(s,ivrt(dspt(i),v,r,t))..
        X(s,i,v,r,t)
$ifi not %opres%==no   + SR(s,i,v,r,t)$sri(i) + QS(s,i,v,r,t)$qsi(i)
        =l=  XCS(s,i,v,r,t) * (1 + (af(s,i,v,r,t)-1)$af(s,i,v,r,t)) *
                              (1 + (af_t(i,v,r,t)-1)$af_t(i,v,r,t)) *
                              (1 + (vrsc_t(i,r,t)-1)$vrsc_t(i,r,t))
;

*       Some dispatchable capacity has a minimum dispatch factor (i.e. limited flexibility)
capacitymin(s,ivrt(dspt_min(i),v,r,t))$dismin(i,t)..
        X(s,i,v,r,t)
$ifi not %opres%==no   + SR(s,i,v,r,t)$sri(i) + QS(s,i,v,r,t)$qsi(i)
        =g=  XCS(s,i,v,r,t) * (1 + (af(s,i,v,r,t)-1)$af(s,i,v,r,t)) *
                              (1 + (af_t(i,v,r,t)-1)$af_t(i,v,r,t)) *
                              (1 + (vrsc_t(i,r,t)-1)$vrsc_t(i,r,t))
                            * dismin(i,t)
;

*       Some capacity is "must-run" (i.e. no flexibility)
capacityfx(s,ivrt(ndsp(i),v,r,t))..
        X(s,i,v,r,t)
$ifi not %opres%==no       +      SR(s,i,v,r,t)$sri(i)
        =e=     XCS(s,i,v,r,t) * (1 + (af(s,i,v,r,t)-1)$af(s,i,v,r,t)) *
                                 (1 + (af_t(i,v,r,t)-1)$af_t(i,v,r,t)) *
                                 (1 + (vrsc_t(i,r,t)-1)$vrsc_t(i,r,t))
;

*       Reserve margins (capacity constraint in peak segment) if desired

*       Calculate the peak residual load net of dynamic contribution of renewables and storage
peakgrid(s,r,t).. PKGRID(r,t) =g= GRID(s,r,t) - sum(ivrt(irnw(i),v,r,t), af_s(s,i,v,r,t) * XCS(s,i,v,r,t))
*       Pumped hydro discharge (minus negative of charge)
                                              + hyps(s,r,t)
*       Net discharge from other storage technologies if included
$ifi not %storage%==no                        - sum(j, GD(s,j,r,t) - chrgpen(j) * G(s,j,r,t))
*       Hydrogen production will likely be zero in binding peak hour but should be included (minus negative of charge)
                                              + sum(hivrt(hi,v,r,t)$(not sameas(hi,"elys-d")), (1/3.412) * eph2(hi,"ele",v) * HX(s,hi,v,r,t))
*       DAC operation
                                              + sum((dac,vt(v,t)), (1/3.412) * epdac(dac,"ele",v) * DACX(s,dac,v,r,t))
;

*       Reserve margin is a multiplier of the absolute peak grid-supplied load
resmargin(s,r,t).. RMARG(r,t) =g= rsvmarg(r) * GRID(s,r,t) ;

*       Sum of firm capacity from non-renewables must be greater than or equal to peak residual load plus reserve margin
reserve(r,t)$(t.val > 2015)..
        sum(ivrt(i,v,r,t), XC(i,v,r,t) * rsvcc(i,r)) + rsvoth(r)
                     =g= RMARG(r,t) + PKGRID(r,t);

*       Existing unconverted coal capacity can be dispatched with or without co-firing
cofire(s,cof,r,t)$idef(cof,"cbcf")..
*       Generation in co-fire mode plus all-coal generation in the underlying capacity block
        sum(ivrt(cof,v,r,t), X(s,cof,v,r,t)) + sum(ivrt(i,v,r,t)$cofmap(cof,i),X(s,i,v,r,t)) =l=
*       Must not exceed availability of the underlying capacity block
        sum(ivrt(i,v,r,t)$cofmap(cof,i), (1 + (af(s,i,v,r,t)-1)$af(s,i,v,r,t)) * XCS(s,i,v,r,t));

cofirecap(s,cof,r,t)$idef(cof,"cbcf")..
*       Make sure the reporting of the co-fired capacity is consistent with the installed coal capacity
        sum(ivrt(cof,v,r,t), XCS(s,cof,v,r,t)) =l= sum(ivrt(i,v,r,t)$cofmap(cof,i), XCS(s,i,v,r,t));

*        Investment flows accumulate as new vintage capacity
invest(new(i),newv(v),r,t)$tv(t,v)..
        XC(i,v,r,t) =e= IX(i,r,t)
*       Allow accumulation of 2050+ capacity
                        + XC(i,v,r,t-1)$(sameas(v,"2050+") and tyr(t) > 2050);

investstatic(i_end(i),newv(v),r,t)$tv(t,v)..
        XC(i,v,r,t) =e= IX(i,r,t)
*       Include cumulative dynamic investment up to t-1 (if applicable)
*                        + installedG(i,v,r,t)
;

* Unconverted plus converted coal capacity (including capacity penalty) must not exceed remaining capacity
*               This equation, retiresch, makes sure that the original coal retirement schedule remains unchanged
*                after retrofit. Additional retirements are allowed.
retiresch(class,r,t)$(class.val le ncl("clcl"))..
        sum((iclass(i,xcl,class),vbase), XC(i,vbase,r,t)) + sum((iclass(cr,type,class),v)$ivrt(cr,v,r,t), XC(cr,v,r,t) * xcapadj_cr(type,v))
                 =l= sum(iclass(i,xcl,class), xcap(i,r)*lifetime(i,r,t));

* Evaluate the actual coal retirement yearly. The RC term in retireamt below includes the scheduled
*                 coal retirement as well as unplanned retirement. The RC term is used in retiremon equation to ensure
*                 monotonicity of coal retirement.
retireamt(class,r,t)$(class.val le ncl("clcl"))..
        sum((iclass(i,xcl,class),vbase), XC(i,vbase,r,t)) + sum((iclass(cr,type,class),v)$ivrt(cr,v,r,t), XC(cr,v,r,t) * xcapadj_cr(type,v))
                 + RC(class,r,t)
                 =e= sum(iclass(i,xcl,class), xcap(i,r));

* Monotonicity of total coal retirement. RC represents total coal retirement.
retiremon(class,r,t)$(class.val le ncl("clcl") and ord(t) gt 1)..
               RC(class,r,t) =g= RC(class,r,t-1) ;

* Force planned gas conversions to occur in the model
convgassch(class,r,t)$(class.val le ncl("clcl"))..
       sum((iclass(i,"clng",class),v), (XC(i,v,r,t) * xcapadj_cr("clng",v)))
              =g= sum(iclass(i,xcl,class), xcap(i,r)*convertgas(i,r,t)) ;

* Force planned bio conversions to occur in the model
convbiosch(class,r,t)$(class.val le ncl("clcl"))..
       sum((iclass(i,"bioe",class),v), (XC(i,v,r,t) * xcapadj_cr("bioe",v)))
              =g= sum(iclass(i,xcl,class), xcap(i,r)*convertbio(i,r,t)) ;

* When investing in Stage 1 retrofits, a corresponding amount of capacity from the base existing class
* must be "consumed", i.e. base capacity must decrease relative to the preceding period
convert1(class,r,t)$(class.val le ncl("clcl") and ord(t) gt 1)..
        sum((iclass(i,xcl,class),vbase), XC(i,vbase,r,t)) =l= sum((iclass(i,xcl,class),vbase), XC(i,vbase,r,t-1)) -
          sum((iclass(cr,type,class))$(not stage2(cr)), IX(cr,r,t) * sum(tv(t,v), xcapadj_cr(type,v)));

* When investing in a Stage 2 retrofit, a corresponding amount of capacity from the intermediate retrofit class
* must be "consumed", i.e. intermediate capacity must decrease relative to the preceding period
* NOTE: the sum should be over vintages active in the previous period to correctly calculate "consumed" capacity
convert2(cr,r,t)$(idef(cr,"clec") and ord(t) gt 1)..
        sum(ivrt(cr,v,r,t-1), XC(cr,v,r,t)) =l= sum(ivrt(cr,v,r,t-1), XC(cr,v,r,t-1)) -
          sum(ccr$(idef(ccr,"ccs9") and crmap(ccr,cr)), IX(ccr,r,t) * sum(tv(t,v), xcapadj_cr("ccs9",v)));

* Limit on existing coal CCS retrofits (GW)
retro(class,r,t)$(class.val le ncl("clcl"))..
        sum((iclass(cr,"ccs9",class),v)$ivrt(cr,v,r,t), XC(cr,v,r,t) * xcapadj_cr("ccs9",v)) =l= ccs_retro(class,r);

* This is a national upper bound on environmental retrofits based on an IRR threshold
irrlim(t)..
        sum((ivrt(cr,v,r,t))$idef(cr,"clec"), XC(cr,v,r,t)) =l= %irr%;

* This is a region-class upper bound on environmental retrofits based on an IRR threshold
irrlim_rcl(r,class,t)..
        sum((ivrt(cr,v,r,t))$iclass(cr,"clec",class), XC(cr,v,r,t)) =l= envlim(r,class);

*       Absolute limits on certain types of installed capacity (nucl, ccs, wnos, enee)
capacitylim(i,r,t)$(caplim(i,r)<INF)..
        sum(ivrt(i,v,r,t), XC(i,v,r,t)) =l= caplim(i,r);

*       Absolute joint limits on certain types of installed capacity (wind, pvrf, geot)
capacityjointlim(type,class,r,t)$(capjlim(type,class,r)<INF)..
        sum(ivrt(i,v,r,t)$(idef(i,type) and iclass(i,type,class)), XC(i,v,r,t)) =l= capjlim(type,class,r);

*       Joint limit on solar PV and CSP within each region-class
solarlim(class,r,t)$(solarcap(class,r)<inf)..
       sum(ivrt(i,v,r,t)$(iclass(i,"pvft",class)), XC(i,v,r,t))
       + sum(ivrt(i,v,r,t)$(iclass(i,"pvsx",class)), XC(i,v,r,t))
       + sum(ivrt(i,v,r,t)$(iclass(i,"pvdx",class)), XC(i,v,r,t))
       + sum(ivrt(i,v,r,t)$(iclass(i,"cspr",class)), cspwt * XC(i,v,r,t))
       =l= solarcap(class,r);

*       Sum of existing and repowered wind capacity within each region cannot exceed base year capacity
windrepowerlim(r,t)$xcap("wind-x",r)..
         sum(ivrt("wind-x",v,r,t), XC("wind-x",v,r,t))
       + sum(ivrt("wind-r",v,r,t), XC("wind-r",v,r,t))
       =l= xcap("wind-x",r);

*       Limit on annual cf of units by technology
cflim(ivrt(i,v,r,t))$cf_y(i,r)..
       XTWH(i,v,r,t) =l= cf_y(i,r) * XC(i,v,r,t) * 1e-3 * 8760 ;

*       Limits on regional generation investments based on current pipeline or other regional constraints
investlim(type,r,t)$(invlim(type,r,t)<INF)..
        sum(idef(i,type)$(new(i) and not cr(i)), IX(i,r,t)) =l= invlim(type,r,t);

*       Limits on national generation investments based on historical max build rates or expert opinion
usinvestlim(tech,t)$(usinvlim(tech,t)<INF)..
        sum((r, itech(new,tech)), IX(new,r,t)) =l= usinvlim(tech,t);

*       Limits on total national transmission investments
tusinvestlim(t)$(tusinvlim(t)<INF)..
        sum((r,rr), IT(r,rr,t) * tlinelen(r,rr)) =l= tusinvlim(t) ;

*       Installed capacity must be monotonically decreasing
retire(ivrt(i,v,r,t))$(not sameas(v,"2050+"))..
        XC(i,v,r,t+1) =l= XC(i,v,r,t) + NUPR(r,t)$sameas(i,"nucl-x");

NUPR.UP(r,t)$ivrt("nucl-x","2015",r,t) = max(0, cumuprates(r,t) - cumuprates(r,t-1));

*       Enforce capacity constraint on inter-region trade flows
tcapacity(s,r,rr,t)$tcapcost(r,rr)..
        E(s,r,rr,t) =l= tcap(r,rr) + TC(r,rr,t)$tcapcost(r,rr);

*       Allow accumulation of transmission capacity investments
tinvest(r,rr,t)$tcapcost(r,rr)..
        TC(r,rr,t) =e= IT(r,rr,t) + IT(rr,r,t) + TC(r,rr,t-1);

tinveststatic(r,rr,t)$tcapcost(r,rr)..
        TC(r,rr,t) =e= IT(r,rr,t) + IT(rr,r,t) + installedT(r,rr);

* * Hydrogen supply market

hcapacity(s,hivrt(hi,v,r,t))..
        HX(s,hi,v,r,t) =l= af_h(hi) * HCS(s,hi,v,r,t);


hinvest(hi,newv(v),r,t)$tv(t,v)..
        HC(hi,v,r,t) =e= IH(hi,r,t)
*       Allow accumulation of 2050+ capacity
                        + HC(hi,v,r,t-1)$(sameas(v,"2050+") and tyr(t) > 2050);

hretire(hivrt(hi,v,r,t))$(vt(v,t) and not sameas(v,"2050+"))..
        HC(hi,v,r,t+1) =l= HC(hi,v,r,t);

hannuald_c(hi,r,t)$(not sameas(hi,"elys-d"))..
*       Direct use central station H2 (from end-use model) plus
        HDU(hi,r,t) +
*       Stored production used for electric generation by stand-alone combined cycle H2
        1e-3 * sum((s,ivrt(i,v,r,t),hi_map(i,hi)), hours(s,t) * htrate(i,v,"h2",r,t) * X(s,i,v,r,t)) =e=
*       Total production stored for external use (centralized)
        1e-3 * sum((s,hivrt(hi,v,r,t)), hours(s,t) * HX(s,hi,v,r,t))
;

hdumarket(r,t)..
        hdu_c(r,t) =e= sum(hi$(not sameas(hi,"elys-d")), HDU(hi,r,t));

hannuald_d(r,t)..
*       Direct use distributed H2 (from end-use model) plus
        hdu_d(r,t) =e=
*       Total production stored for external use (distributed)
        1e-3 * sum((s,hivrt("elys-d",v,r,t)), hours(s,t) * HX(s,"elys-d",v,r,t))
;

hproddef(hi,v,r,t)..  HPROD(hi,v,r,t) =e= 1e-3 * sum(s, HX(s,hi,v,r,t) * hours(s,t));

copyhc(s,hivrt(hi,v,r,t))..  HCS(s,hi,v,r,t) =e= HC(hi,v,r,t)$(ord(s)=1) + HCS(s-1,hi,v,r,t)$(ord(s)>1);

* * * * DAC equations

* Utilization of DAC must not exceed installed capacity
daccapacity(s,dac,v,r,t)$vt(v,t)..
        DACX(s,dac,v,r,t) =l= af_dac(dac) * DACC(dac,v,r,t) / 8.76;

* Accumulation of DAC capacity investment
dacinvest(dac,newv(v),r,t)$tv(t,v)..
        DACC(dac,v,r,t) =e= IDAC(dac,r,t)
*       Allow accumulation of 2050+ capacity
                        + DACC(dac,v,r,t-1)$(sameas(v,"2050+") and tyr(t) > 2050);

* Monotonicity constraint on installed DAC capacity
dacretire(dac,v,r,t)$(vt(v,t) and not sameas(v,"2050+"))..
        DACC(dac,v,r,t+1) =l= DACC(dac,v,r,t);

* Annual total CO2 captured from DAC (million t-CO2 per year)
annualdac(dac,v,r,t)$vt(v,t)..
        DACANN(dac,v,r,t) =e= 1e-3 * sum(s, DACX(s,dac,v,r,t) * hours(s,t));

* * * * * * * * * * * * * *
* Equations governing CO2 transport and storage (CCS)

* Ensures conservation of annual CO2 flows in each region and period
co2balance(r,t)..
*       CO2 captured by electric-only CCS plants
        sum((ivrt(ccs(i),v,r,t),s), 1e-3 * X(s,ccs,v,r,t) * hours(s,t) * capture(i,v,r))
*       CO2 captured by hydrogen-based CCS plants
        + sum((hivrt(ccs_h(hi),v,r,t),s), 1e-3 * HX(s,hi,v,r,t) * hours(s,t) * capture_h(hi,v))
*       CO2 captured by DAC
        + sum((dac,vt(v,t)), DACANN(dac,v,r,t) * capture_dac(dac,v))
*       Plus inter-region CO2 imports
        + sum(rr$pcapann(rr,r), CX(rr,r,t))
*       Less inter-region CO2 exports (including loss penalty)
        - sum(rr$pcapann(r,rr), CX(r,rr,t))
*       Equals CO2 stored in region
        =e= CSTOR(r,t)$injcap(r);

co2storcap(r)$injcap(r)..
*       CO2 stored over all time periods
        sum(t, CSTOR(r,t) * nyrs(t))
*       must be less than regional storage capacity
        =l= 1e3 * injcap(r);

*       Allow accumulation of CO2 pipeline capacity investments
co2pinvest(r,rr,t)$pcapann(r,rr)..
        PC(r,rr,t) =e= IP(r,rr,t) + IP(rr,r,t) + PC(r,rr,t-1);

*       Enforce capacity constraint on inter-region CO2 pipeline flows
co2pcapacity(r,rr,t)$pcapann(r,rr)..
        CX(r,rr,t) =l= PC(r,rr,t);

*       Allow accumulation of CO2 injection capacity investments
co2injinvest(r,t)$injcap(r)..
        InjC(r,t) =e= IInj(r,t) + InjC(r,t-1);

*       Enforce capacity constraint on CO2 injection
co2injcapacity(r,t)$injcap(r)..
        CSTOR(r,t) =l= InjC(r,t);

* * * * * * * * * * * * * *

*       Regional supply of dedicated biomass must equal demand (no trade)
biomarket(r,t)..
        sum(db, DBS(db,r,t)) =g= sum(ivrt(i,v,r,t)$ifuel(i,"dbio"), ifuel(i,"dbio") * htrate(i,v,"dbio",r,t) * XTWH(i,v,r,t));

*       National NG market (including non-electric demand from end-use model)
gasmarket(t)$gelas(t)..
        sum(ngp, NGS(ngp,t)) =e=
                sum(ivrt(i,v,r,t)$ifuel(i,"ng"), ifuel(i,"ng") * htrate(i,v,"ng",r,t) * XTWH(i,v,r,t)) +
                sum(hivrt(hi,v,r,t), eph2(hi,"ng",v) * HPROD(hi,v,r,t)) +
                sum((dac,r,vt(v,t)), epdac(dac,"ng",v) * DACANN(dac,v,r,t)) +
                1e3 * gas_nele(t)
                ;

*       National CO2 market
carbonmarket(t)$(co2cap(t,"%cap%") and (co2cap(t,"%cap%") < inf) or zerocap(t,"%cap%"))..
        co2cap(t,"%cap%") - NBC(t) + SV(t) =g= 1e-3 * sum(ivrt(i,v,r,t)$emit(i,v,"co2",r,t), emit(i,v,"co2",r,t) * XTWH(i,v,r,t))
*       Plus emissions from hydrogen production
                     + 1e-3 * sum(hivrt(hi,v,r,t)$emit_h(hi,v,"co2"), emit_h(hi,v,"co2") * HPROD(hi,v,r,t))
*       Less net removal from DAC
                     - 1e-3 * sum((dac,r,vt(v,t)), DACANN(dac,v,r,t))
*       Plus non-electric sector CO2 emissions when doing integrated runs (in this case the cap is the economy cap)
$ifi %cap%==icap      + NEM(t)$elas_nem(t) + q_nem(t)$(not elas_nem(t))
;

*       Regional CO2 markets
carbonmarket_rg(r,t)$(co2cap_rg(r,t,"%cap_rg%") and (co2cap_rg(r,t,"%cap_rg%") < inf) or zerocap_r(r,t,"%cap_rg%"))..
        co2cap_rg(r,t,"%cap_rg%") - NBC_RG(r,t)   =g= 1e-3 * sum((i,v)$(ivrt(i,v,r,t) and emit(i,v,"co2",r,t)), emit(i,v,"co2",r,t) * XTWH(i,v,r,t))
*       Plus emissions from hydrogen production
                     + 1e-3 * sum(hivrt(hi,v,r,t)$emit_h(hi,v,"co2"), emit_h(hi,v,"co2") * HPROD(hi,v,r,t))
*       Less net removal from DAC
                     - 1e-3 * sum((dac,vt(v,t)), DACANN(dac,v,r,t))
*       Plus non-electric sector CO2 emissions when doing integrated runs (in this case the cap is the economy cap)
$ifi %cap%==icap      + NEM_RG(r,t)$elas_nem_rg(r,t) + q_nem_rg(r,t)$(not elas_nem_rg(r,t))
;

*       RGGI joint electric sector CO2 emissions market
rggimarket(t)$(rggicap(t))..
        rggicap(t) - NBC_RGGI(t) =g= 1e-3 * sum(ivrt(i,v,r,t)$(rggi_r(r) and emit(i,v,"co2",r,t)), emit(i,v,"co2",r,t) * XTWH(i,v,r,t))
;

* If New York is a separate region, then NY SB6599 (zero CO2 by 2040) can be required
carbonmarket_ny(t)$nys6599(t)..
        nys6599(t) =g= 1e-3 * sum(ivrt(i,v,r,t)$(nys_r(r) and emit(i,v,"co2",r,t)), emit(i,v,"co2",r,t) * XTWH(i,v,r,t))
*       Plus emissions from hydrogen production
                     + 1e-3 * sum(hivrt(hi,v,r,t)$(nys_r(r) and emit_h(hi,v,"co2")), emit_h(hi,v,"co2") * HPROD(hi,v,r,t))
*       Less net removal from DAC
                     - 1e-3 * sum((dac,nys_r(r),vt(v,t)), DACANN(dac,v,r,t))
;

*       Regional non-CO2 pollutant markets
* CSAPR enforces caps ("budgets") on certain states/regions for SO2 and NOx. There are separate caps for annual NOx and ozone-season NOx.
* Trading is allowed for certain state/regional groupings which vary by pollutant and annual/seasonal.
* Banking before borrowing is also allowed within the trading programs.
* However, for each capped region in each trading program there is an upper bound on physical emissions ("assurance level").
* The difference between the assurance level and the budget is implicitly an upper bound on imports + bank withdrawals.
* Or equivalently a lower (negative) bound on net exports.

csapr_r(trdprg,pol,r,t)$csaprbudget(trdprg,pol,r,t,"%noncap%")..
        sum((csapr_s(trdprg,s,t), csapr_ivrt(pol,i,v,r,t)),
                1e-3 * emit(i,v,pol,r,t) * X(s,i,v,r,t) * hours(s,t)) =l= csaprbudget(trdprg,pol,r,t,"%noncap%") * csapradj_s(trdprg,r,t) - NTX_CSAPR(trdprg,pol,r,t)
;

csapr_trdprg(trdprg,t)..
        sum((pol,r)$csaprbudget(trdprg,pol,r,t,"%noncap%"), NTX_CSAPR(trdprg,pol,r,t)) =e= NBC_CSAPR(trdprg,t);

NTX_CSAPR.LO(trdprg,pol,r,t)$csaprcap(trdprg,pol,r,t,"%noncap%") = - (csaprcap(trdprg,pol,r,t,"%noncap%") - csaprbudget(trdprg,pol,r,t,"%noncap%"));

* CSAPR emission banking

itnbc_csapr(trdprg)..
         sum(t$(sum((pol,r), csaprbudget(trdprg,pol,r,t,"%noncap%")) and t.val le 2050), NBC_CSAPR(trdprg,t) * nyrs(t)) =e= 0;

cbcdf_csapr(trdprg,t)..
         CBC_CSAPR(trdprg,t) =e= sum(tt$(sum((pol,r), csaprbudget(trdprg,pol,r,tt,"%noncap%")) and tt.val le t.val), NBC_CSAPR(trdprg,tt) * nyrs(tt));

* Intertemporal constraints on banked credits for CO2

itnbc..
        sum(t$((co2cap(t,"%cap%") or zerocap(t,"%cap%")) and t.val le 2050), NBC(t)*nyrs(t)) =e= 0;

itnbc_rg(r)..
        sum(t$(co2cap_rg(r,t,"%cap_rg%") and t.val le 2050), NBC_RG(r,t)*nyrs(t)) =e= 0;

itnbc_rggi..
        sum(t$(rggicap(t) and t.val le 2050), NBC_RGGI(t)*nyrs(t)) =e= 0;

* Cumulative banked credits - when this is constrained to be positive, borrowing is not allowed

cbcdf(t)..
        CBC(t) =e= sum(tt$((co2cap(tt,"%cap%") or zerocap(tt,"%cap%")) and tt.val le t.val), NBC(tt)*nyrs(tt)) ;

cbcdf_rg(r,t)..
        CBC_RG(r,t) =e= sum(tt$(co2cap_rg(r,tt,"%cap_rg%") and tt.val le t.val), NBC_RG(r,tt)*nyrs(tt)) ;

cbcdf_rggi(t)..
        CBC_RGGI(t) =e= sum(tt$(rggicap(t) and tt.val le t.val), NBC_RGGI(tt)*nyrs(tt)) ;

fedrps(t)..
        sum(ivrt(i,v,r,t), rps(i,r,"fed") * XTWH(i,v,r,t)) + sum(r, rfpv_twh(r,t)$rps("pvrf-xn",r,"fed")) =g= rpstgt(t,"%rps%") * sum(r, GRIDTWH(r,t) / localloss + rfpv_twh(r,t)$rps("pvrf-xn",r,"fed")) ;

* Hypothetical RPS expressed directly as share of generation
fullrps(t)$(rpstgt(t,"%rps_full%") < 1)..
        sum(ivrt(i,v,r,t), rps(i,r,"full") * XTWH(i,v,r,t)) =g= rpstgt(t,"%rps_full%") * sum(ivrt(i,v,r,t), XTWH(i,v,r,t));

* Hydrogen production must meet RPS target as well (only electrolysis is considered renewable)
fullrps_h(t)$(rpstgt(t,"%rps_full%") < 1)..
	sum(hivrt("elys-c",v,r,t), HPROD("elys-c",v,r,t)) =g= rpstgt(t,"%rps_full%") * sum(hivrt(hi,v,r,t)$(not sameas(hi,"elys-d")), HPROD(hi,v,r,t));

$ifi not %rps_full%==none XTWH.UP(ivrt(i,v,r,t))$(rpstgt(t,"%rps_full%") eq 1 and not rps(i,r,"full")) = 0;  HPROD.UP(hi,v,r,t)$(rpstgt(t,"%rps_full%") eq 1 and not (sameas(hi,"elys-c") or sameas(hi,"elys-d"))) = 0;

* Equations describing state RPS constraints

staterps(r,t)..
* In-state qualified renewable generation in TWh (may or may not include distributed PV)
        sum(ivrt(i,v,r,t), rps(i,r,"state") * XTWH(i,v,r,t)) + rfpv_twh(r,t)$rps("pvrf-xn",r,"state")
* Plus imports less exports of RECs bundled with renewable power contracts (RPC)
        + sum(rr$tcapcost(r,rr), RPC(rr,r,t) - RPC(r,rr,t))
* Plus net imports of unbundled RECs (NMR) plus alternative compliance payments (ACP)
        + NMR(r,t) + ACP(r,t)
* Plus RECs from Canadian hydro
        + canhyd_r(r)
* Must satisfy adjusted target as a percentage of retail sales (plus rooftop PV if included)
        =g= rpstgt_r(r,t) * (GRIDTWH(r,t) / localloss + rfpv_twh(r,t)$rps("pvrf-xn",r,"state"))
;

* Unbundled REC market must balance (no geographic constraints)
recmkt(t)..
        sum(r, NMR(r,t)) =e= 0;

* Exportable renewable power must be generated concurrently with transmission
rpcgen(s,r,t)..
        sum(rr$tcapcost(r,rr), ER(s,r,rr,t)) =l= sum(ivrt(i,v,r,t), rps(i,r,"state") * X(s,i,v,r,t));

rpctrn(s,r,rr,t)$tcapcost(r,rr)..
        ER(s,r,rr,t) =l= E(s,r,rr,t);

* Bilateral trade flows in RECs bundled with renewable power contracts
* must not exceed exportable renewable power
rpcflow(r,rr,t)$tcapcost(r,rr)..
        RPC(r,rr,t) =l= 1e-3 * sum(s, ER(s,r,rr,t) * hours(s,t));

* Upper bound on total compliance imports to reflect certain states' constraints
rpsimports(r,t)..
        sum(rr$tcapcost(r,rr), RPC(rr,r,t)) + NMR(r,t) =l= rcmlim(r,t);

* Solar carve-outs in certain states force in solar energy
rpssolar(r,t)$soltgt(r,t)..
        sum(ivrt(i,v,r,t)$sol(i), XTWH(i,v,r,t)) =g= soltgt(r,t) - rfpv_twh(r,t) ;

* Offshore wind mandates
wnosmandate(r,t)$wnostgt_r(r,t)..
        sum(ivrt(i,v,r,t)$idef(i,"wnos"), XC(i,v,r,t)) =g= wnostgt_r(r,t) ;

* California SB-100 clean electricity standard constraint
sb100ces(t)..
* In-state qualified "eligible renewable energy resources and zero-carbon resources" in TWh
        sum(ivrt(i,v,cal_r(r),t), sb100i(i,r) * XTWH(i,v,r,t))
* California rooftop PV
      + sum(cal_r(r), rfpv_twh(r,t))
* Plus imports of bundled clean electricity (new builds and existing hydro/nuclear)
      + sum(sb100(r), RPC2(r,t))
* Must satisfy adjusted target as a percentage of retail sales (plus rooftop PV if included)
    =g= sb100tgt(t) * sum(cal_r(r), (GRIDTWH(r,t) / localloss + rfpv_twh(r,t)))
;

* Exportable clean electricity (defined via SB-100) must be generated concurrently with transmission
rpcgen2(s,r,t)$sb100(r)..
         EC(s,r,t) =l=
*        New builds for neighboring regions -- Not enforcing resource shuffling provisions in this formulation
         sum(ivrt(i,v,r,t), sb100i(i,r) * X(s,i,v,r,t))
*        Existing nuclear and hydro
$ifi %dynfx%==no         + sum(i, sb100enh(i,r) * sum(vbase, X(s,i,vbase,r,t)))
$ifi %dynfx%==yes        + sum(i, sb100enh(i,r) * sum(ivrt(i,v,r,t)$(vyr(v)=tyr(t)), X(s,i,v,r,t)))
;

rpctrn2(s,r,t)$sb100(r)..
        EC(s,r,t) =l= sum(cal_r(rr), E(s,r,rr,t)) ;

rpcflow2(r,t)$sb100(r)..
        RPC2(r,t) =l= 1e-3 * sum(s, EC(s,r,t) * hours(s,t));

***JEB-CA: Unspecified imports into CA (in TWh per year)
uidef(t)..
         UI(t) =e= sum((s,sb100(r),cal_r(rr)), (E(s,r,rr,t) - EC(s,r,t)) * hours(s,t) * 1e-3);

* Nuclear state policy constraint
nucst(r,t)$(not rpstgt(t,"%rps_full%") eq 1)..
         sum(v, XC("nucl-x",v,r,t)) =g= nuczec(r,t);

* * * Federal CES Policy Equations * * *

* Equations describing a Clean Energy Standard (lower bound on qualified generation as a share of system total)
* Note that different versions of the CES vary in terms of
*   - what is qualified / credited (i.e. numerator)
*   - what metric is used as the system total (i.e. denominator)

* National balance of CES compliance credits
cesmkt(r,t)$(not sameas(t,"2015"))..
*        In-region qualified / credited generation
         sum(ivrt(i,v,r,t), ces(i,v,r,"%ces%") * XTWH(i,v,r,t))
*        Plus credits for in-region distributed PV
         + rfpv_twh(r,t) * ces_oth("rfpv",r,"%ces%")
*        Plus credits from Direct Air Capture
         + sum((dac,vt(v,t)), ces_oth("dac",r,"%ces%") * DACANN(dac,v,r,t))
*        Plus net CES credit imports
         + CES_NTX(r,t)
*        Plus alternative compiance payments (ACP)
         + CES_ACP(r,t)
*        Plus net international clean energy imports
*         - ntxintl(r) * ces_oth("ntmintl",r,"%ces%")
*        Is greater than or equal to target share of system total
     =g= cestgt_r(t,r) * CESTOT(r,t)
;

* Definition of system total for CES compliance (i.e. denominator)
cestotdef(r,t)$(not sameas(t,"2015"))..
                 CESTOT(r,t) =e=
*                                rooftopPV (TWh) is included in all options
                                 rfpv_twh(r,t)
* "totalload" option = total generation (except green hydrogen, interpreted as storage discharge), adjusted for net trade
* this definition of the denominator is used in the Default CES implementation
$iftheni %cestot_option%==totalload
*                               total generation (TWh) less downstream h2cc-elys-c 'discharge'
                                + sum(ivrt(i,v,r,t)$(not sameas(i,"h2cc-elys-c")), XTWH(i,v,r,t))
*                                plus net inter-region imports (sums to zero across regions)
                                + 1e-3 * sum((s,rr)$tcapcost(rr,r), hours(s,t) * E(s,rr,r,t) - E(s,r,rr,t))
$endif
* "en4load" option = all grid-supplied energy (including electricity consumed for primarily non-electric hydrogen production)
* equivalent to "totalload" excluding storage losses for both batteries/pumped hydro and electrolysis/hydrogen (still gross of delivery losses)
$iftheni %cestot_option%==en4load
*                               total electricity delivered from grid for end-use load
                                + GRIDTWH(r,t)
*                                include net international exports (for equivalency with totalload option; CES analysis is domestic)
                                + ntxintl(r)
*                                include electricity consumed for dedicated non-electric hydrogen production
                                + 1e-3 * sum((s,hivrt(hi,v,r,t))$(not sameas(hi,"elys-c") and not sameas(hi,"elys-d")), (1/3.412) * eph2(hi,"ele",v) * hours(s,t) * HX(s,hi,v,r,t))
$endif
* "retailload" option = grid-supplied energy adjusted for localloss
$iftheni %cestot_option%==retailload
*                               total electricity delivered from grid for end-use load, adjusted for deliver loss
                                + GRIDTWH(r,t) / localloss
*                                include net international exports (for equivalency with totalload option; CES analysis is domestic)
                                + ntxintl(r) / localloss
*                                plus electricity consumed for central station hydrogen production via eletrolysis (delivery losses not really applicable here)
                                + 1e-3 * sum((s,hivrt(hi,v,r,t))$(not sameas(hi,"elys-c") and not sameas(hi,"elys-d")), (1/3.412) * eph2(hi,"ele",v) * hours(s,t) * HX(s,hi,v,r,t))
$endif
;

* Regional (unbundled) CES trading
* If banking/borrowing credits is allowed, then sum of exports could be non-zero
cestrade(t)..
        sum(r, CES_NTX(r,t)) =e= CES_NBC(t);

* * * End of CES Policy Equations * * *

* * * CSP Equations * * *

* Parallel structure to capacity equation for CSP solar collector + receiver:
capacity_csp_cr(s,cspi,r).. X_CSP_CR(s,cspi,r) =l= dni(s,cspi,r) * C_CSP_CR(cspi,r);

* Dispatch of CSP power block comes from either storage discharge
* or net direct transfer from receiver (after losses)
* Note that for now no round-trip charge penalty is applied to CSP TES
* Static model equation, no indexing over t
dispatch_csp(s,cspi,r)..
                sum(tv(t,v), X(s,cspi,v,r,t))
            =e= (GD_CSP(s,cspi,r) + (X_CSP_CR(s,cspi,r) * csp_eff_r - G_CSP(s,cspi,r))) * csp_eff_p;

* Dynamic accumulation of thermal storage balance for CSP
storagebal_csp(s,cspi,r)..
                 GB_CSP(s,cspi,r)
             =e= (1 - csp_loss_g) * (GB_CSP(s-1,cspi,r) + GB_CSP("%seg%",cspi,r)$(sameas(s,"1"))) + (G_CSP(s,cspi,r) - GD_CSP(s,cspi,r));

* CSP thermal storage cannot exceed a stated upper bound
storagelim_csp(s,cspi,r)..   GB_CSP(s,cspi,r) =l= GR_CSP(cspi,r);

* * * Storage Investment and Dispatch Constraints * * *

*       Allow accumulation of storage charge capacity investments
ginvestc(j,r,t)..       GC(j,r,t) =e= IGC(j,r,t) + GC(j,r,t-1);

*       Allow accumulation of storage size of room investments
ginvestr(j,r,t)..       GR(j,r,t) =e= IGR(j,r,t) + GR(j,r,t-1);

*       Storage charge must not exceed charge capacity (size of door)
chargelim(s,j,r,t)..    G(s,j,r,t) =l= GC(j,r,t);

*       Storage discharge must not exceed charge capacity (size of door)
dischargelim(s,j,r,t).. GD(s,j,r,t) =l= GC(j,r,t);

* Dynamic accumulation of storage balance
$ifthen.pssm not %pssm%==yes
storagebal(s,j,r,t)..   GB(s,j,r,t) =e= (1 - loss_g(j)) * (GB(s-1,j,r,t) + GB("%seg%",j,r,t)$sameas(s,"1")) + hours(s,t) * (G(s,j,r,t) - GD(s,j,r,t));
$else.pssm
* If p_ssm is turned on, dynamic balance is calculated using approximate state space matrix instead of hourly chronology
storagebal(s,j,r,t)..   GB(s,j,r,t)
                        =e=
                        (1 - loss_g(j))
                        * sum(ssm(s,ss,t), p_ssm(s,ss,t) * GB(ss,j,r,t))
                        + (1 + pstay("max",s,t) * hours(s,t)) * (G(s,j,r,t) - GD(s,j,r,t));
$endif.pssm

*       Accumulated balance must not exceed storage capacity (size of room)
storagelim(s,j,r,t)..   GB(s,j,r,t) =l= GR(j,r,t);

*       Size of room relative to size of door (option to fix)
storageratio(j,r,t)$(%fixghours%)..     GR(j,r,t) =e= ghours(j,r) * GC(j,r,t);

*       Storage charge-discharge energy conservation balance (dynamic model only) -- Annual balancing and initial charging losses only for now
storagesum(j,r,t)..     sum(s, hours(s,t) * G(s,j,r,t)) =e= sum(s, hours(s,t) * GD(s,j,r,t));

*       Exogenous storage capacity constraint
storagefx(t)..          sum((j,r)$(not sameas(j,"hyps-x")), GC(j,r,t)) =e= %stortgt%;

*       Exogenous storage capacity lower bound
storagefxlo(j,r,t)..    GR(j,r,t) =g= 2 * GC(j,r,t);

* If running in static mode with storage, can import storage capacity values from dynamic run
$ifi not %storage%==no $ifi not %static%==no $ifi not %gdynfx%==no GC.FX(j,r,t) = gcfx(j,r,"%static%");

* If storage is endogenous, then fix endowment of existing pumped hydro capacity
$ifi not %storage%==no GC.FX("hyps-x",r,t) = gcap("hyps",r); GR.FX("hyps-x",r,t) = gcap("hyps",r) * ghours("hyps-x",r);

* In certain storage runs, we only allow new investment in one type of storage technology
$if set hypsonly IGC.FX(batt,r,t) = 0; IGR.FX(batt,r,t) = 0;
$if set battonly IGC.FX("bulk",r,t) = 0; IGR.FX("bulk",r,t) = 0;

$iftheni.opconstraints not %opres%==no
* * * Operating Reserves Constraints * * *

* Expand sri(i) to include CCS and cbcf
sri(i)$(idef(i,"ccs9") or idef(i,"ccs5") or idef(i,"ngcs") or idef(i,"cbcf")) = yes;
* Remove hydro from qsi(i)
qsi("hydr-x") = no;
* Note: Assume these fractions apply to both contingency reserves and VRE
*       forecast error reserves, as frequency regulation is assumed to be spinning
orfrac("spin") = 0.5; orfrac("quik") = 1-orfrac("spin");
* Contingency reserves defined as 6% load in each segment (like WECC contingency reserve criteria)
orreq_fx("cont") = 0.06;
* Frequency regulation reserves defined as 1.5% load in each segment
orreq_fx("freq") = 0.015;
* Variable renewable energy (VRE) forecast error reserves defined as 30%
*       of wind and solar output in each segment (can vary in sensitivity)
orreq_vr(s,irnw,r) = %orvre%;

* Spinning reserve requirement (GW)
spinreqdef(s,r,t)..
        SPINREQ(s,r,t) =e=
*       Contingency reserves (6% of load in each segment, where 50% is spinning)
                orreq_fx("cont") * orfrac("spin") * load(s,r,t)
*       Frequency regulation reserves (1.5% of load in each segment)
              + orreq_fx("freq") * load(s,r,t)
*       VRE forecast error reserves (30% of wind/solar output in each segment)
              + orfrac("spin") * sum(ivrt(irnw,v,r,t), orreq_vr(s,irnw,r) * X(s,irnw,v,r,t))
;

* Quick-start reserve requirement (GW)
qsreqdef(s,r,t)..
        QSREQ(s,r,t) =e=
*       Contingency reserves (6% of load in each segment, where 50% is QS)
                orreq_fx("cont") * orfrac("quik") * load(s,r,t)
*       Frequency regulation reserves (assumed to be spinning only)
*       VRE forecast error reserves (30% of wind/solar output in each segment)
              + orfrac("quik") * sum(ivrt(irnw,v,r,t), orreq_vr(s,irnw,r) * X(s,irnw,v,r,t))
;

* Spinning reserve market in each segment
srreqt(s,r,t)$(t.val > %tbase%)..
        hours(s,t) * (sum(ivrt(sri,v,r,t), SR(s,sri,v,r,t)) + sum(j, SRJ(s,j,r,t))) =g= hours(s,t) * SPINREQ(s,r,t);

* Quick-start reserve market in each segment
qsreqt(s,r,t)$(t.val > %tbase%)..
        hours(s,t) * (sum(ivrt(qsi,v,r,t), QS(s,qsi,v,r,t)) + sum(j, QSJ(s,j,r,t))) =g= hours(s,t) * QSREQ(s,r,t);

* Spinning reserve only available when unit is generating (assume that amount of spinning reserve cannot be more than what is being generated in a given segment)
* Implicit that a unit can provide up to half its capacity as spinning reserve (tempered by srramp constraint below)
srav(s,ivrt(i,v,r,t))$sri(i)..
        SR(s,i,v,r,t) =l= X(s,i,v,r,t);

* Spinning reserves can only be provided up to a fraction of nameplate capacity corresponding to ramp capability
srramp(s,ivrt(i,v,r,t))$(sri(i) and ramprate(i))..
        SR(s,i,v,r,t) =l= (ramprate(i)/100) * XCS(s,i,v,r,t);

* Storage definition mutually exclusive provision of services
stordef(s,j,r,t)..      SRJ(s,j,r,t) + QSJ(s,j,r,t) + GD(s,j,r,t) + G(s,j,r,t) =l= GC(j,r,t);

$endif.opconstraints

* * * * * * * * Model Statement * * * * * * * * * * *

model regenelec /
* All versions of model include:
*         Objective function and electricity market clearance conditions;
                    objdef, demand, enduseload, annuald
*         Utilization constraints and generation and transmission capacity; and
                    xtwhdef, gridtwhdef, copyxc, capacity, cofire, tcapacity, solarlim, windrepowerlim
*	  Hydrogen model
                    hcapacity, hinvest, hretire, hannuald_c, hannuald_d, copyhc, hproddef, hdumarket
*         Biomass market and gas market clearance condition
                    biomarket, gasmarket
*         CO2 Storage and Transport model
                    co2balance, co2injinvest, co2storcap, co2pinvest, co2pcapacity, co2injcapacity
*         Direct air capture
                    daccapacity, dacinvest, dacretire, annualdac
*         Reserve requirements if switched on
$iftheni.resmrg not %reserve%==no
                    peakgrid, resmargin, reserve
$endif.resmrg
*         Investment constraints (except in static mode with capacity fixed to dynamic results)
$iftheni.dfinv %dynfx%==no
                    invest, investlim, usinvestlim, tusinvestlim, capacitylim, capacityjointlim, tinvest
                    retiresch, retireamt, retiremon, convert1, convert2, convgassch, convbiosch, retro
                    cofirecap
$elseifi.dfinv %dynfx%==yes
                    investstatic, investlim, usinvestlim, tusinvestlim, capacitylim, capacityjointlim, tinveststatic
$else.dfinv
$abort 'Do not understand the setting used for control parameter dynfx (should be yes or no)!!'
$endif.dfinv
$iftheni.freecap %free%==no
                    capacityfx
$endif.freecap
                    capacitymin
* State nuclear support equation - only applies in dynamic model
$ifi %nuczec%==yes $ifi %dynfx%==no      nucst
* Only include IRR hurdle rate constraint if a total GW above the threshold has been specified
$ifi not %irr%==inf       irrlim
$ifi not %irrclass%==no   irrlim_rcl
* Except when run in static mode, capacity vintage dynamics are included:
$ifi %static%==no  retire
* Except when run in 8760 mode, nuclear share costs constraints are included:
$iftheni.nshr %nccost%==yes
$ifi not %seg%==8760   nucshr, nuctot
$endif.nshr
* When an emissions cap is specified, carbon and non-co2 market conditions are included:
$ifi not %RGGI%==off     rggimarket, itnbc_rggi, cbcdf_rggi
$ifi not %NY_SB6599%==no carbonmarket_ny
$ifi not %cap%==none     carbonmarket, itnbc, cbcdf
$ifi not %cap_rg%==none  carbonmarket_rg, itnbc_rg, cbcdf_rg
$ifi not %noncap%==none  csapr_r, csapr_trdprg, itnbc_csapr, cbcdf_csapr
* A Federal RPS constraint can be included if indicated:
$ifi not %rps%==none      fedrps
$ifi not %rps_full%==none fullrps, fullrps_h
* State RPS constraints can be included if indicated:
$ifi %srps%==yes     staterps, recmkt, rpcgen, rpctrn, rpcflow, rpsimports, rpssolar, wnosmandate
$ifi %CA_SB100%==yes         sb100ces, rpcgen2, rpctrn2, rpcflow2, uidef
* A Federal Clean Energy Standard can be included if indicated:
$iftheni.cs1 NOT %ces%==none
$iftheni.cs2 %cestrd%==usa
        cesmkt, cestotdef, cestrade
*       bcegen, bcetrn, bceflow, cesexport
$elseif.cs2 %cestrd%==reg
       cesmkt_r
$else.cs2
$abort 'Value for cestrd switch not recognized (should be usa or reg)'
$endif.cs2
$endif.cs1
* CSP thermal storage equations can be included if indicated (requires static model)
$iftheni.cspstore %cspstorage%==yes
$iftheni.staticcspstore not %static%==no
capacity_csp_cr, storagebal_csp, dispatch_csp, storagelim_csp
$else.staticcspstore
$abort 'Cannot use CSP thermal storage equations without the static model'
$endif.staticcspstore
$endif.cspstore
* Storage technologies can be included if indicated:
$iftheni.store not %storage%==no
ginvestc, ginvestr, chargelim, dischargelim, storagelim, storageratio
$iftheni.staticstore %static%==no
* In the dynamic model, use annual balance sum unless pssm mode is turned on, in which case use storagebal
$if     %pssm%==no storagesum
$if not %pssm%==no storagebal
$else.staticstore
* In the static model, always use storagebal
storagebal
$ifthene.stortgt %stortgt%>0
* If specified include fixed storage capacity
storagefx, storagefxlo
$endif.stortgt
$endif.staticstore
$endif.store
cflim
$ifi not %opres%==no    srav, srreqt, spinreqdef, qsreqdef, qsreqt, srramp, stordef
/;

* The various versions of the model also include several simple bound constraints:

* If price elasticity is 0, fix load:
D.FX(r,t)$(pelas(r,t) eq 0) = 1;

* Future capacity of existing vintage cannot exceed current capacity lifetimes
XC.UP(i,vbase,r,t)$ivrt(i,vbase,r,t) = xcap(i,r) * lifetime(i,r,t);
* No existing hydrogen capacity
HC.FX(hi,vbase,r,t) = 0;

* Direct air capture
$if %nodac%==yes DACC.UP(dac,v,r,t) = 0;
DACC.UP(dac,v,r,t)$(t.val le 2020) = 0;
* Constrain waste heat configuration until have supply characterized
DACC.UP("dac-lt-waste",v,r,t) = 0;
DACC.UP(dac,vbase,r,t) = 0;

* Fix existing CSP storage to 10 hours, and existing CSP solar multiple to 2.3
GR_CSP.FX("cspr-x",r) = (10 / (csp_eff_p * csp_eff_r)) * xcap("cspr-x",r);
C_CSP_CR.L("cspr-x",r) = (2.3 / (csp_eff_p * csp_eff_r)) * xcap("cspr-x",r);

* Upper bound on cumulative additions to any given link (not applicable in
* baseyronly mode)
$ifi NOT %baseyronly%==yes TC.UP(r,rr,t)$tcapcost(r,rr) = tinvlim("%tlimscn%",t) + %fltc%$((sameas(r,"Florida") or sameas(rr,"Florida")) and t.val ge 2035);
* initialize
TC.L(r,rr,t) = 0;
* If specified, restrict transmission additions into and out of Texas to
* 1 GW per time period
$if not %texasent%==no IT.UP("Texas",r,t) = 1; IT.UP(r,"Texas",t) = 1;

* In Limited Portfolio, constrain all investment in CCS and nuclear
$ifi not %ccslim%==no IX.FX(ccs(i),r,t) = 0;
$ifi not %nuclim%==no IX.FX(nuc(i),r,t)$(t.val ge 2025) = 0;
* Disable new coal units without CCS after a given year
IX.FX("clec-n",r,t)$(t.val > %nonewcoal%) = 0;
IX.FX("igcc-n",r,t)$(t.val > %nonewcoal%) = 0;

* If BECCS is turned off, do not deploy
$ifi %becslim%==yes IX.FX("becs-n",r,t) = 0;

* If advanced nuclear is turned off, do not deploy
$ifi %advnuc%==no IX.FX("nuca-n",r,t) = 0;

* Do not allow rooftop PV in electric model (all comes from end-use)
IX.FX("pvrf-xn",r,t) = 0;

* Upper bound on dedicated biomass supply
DBS.UP(db,r,t) = biocap("%fsmv%","%biocpscn%",db,r,t) ;

* Upper bound on NG supply (0 when gelas = 0)
NGS.UP(ngp,t) = ngcap(ngp,t);

* No safety valve if not indicated:
$ifi %svpr%==no SV.FX(t) = 0;

* Define additional constraints for state RPS Scenarios
* Non-RPS participants cannot import bundled RECs (to export as unbundled)
$ifi %srps%==yes  RPC.FX(rr,r,t)$(not rpstgt_r(r,t)) = 0;
* Unbundled REC trade limit
$ifi %srps%==yes   NMR.UP(r,t) = nmrlim(r,t);
* Alternative compliance payment limit
$ifi %srps%==yes ACP.UP(r,t) = acplim(r,t);

* Turn state RPS variables off if not indicated:
$ifi not %srps%==yes  RPC.FX(r,rr,t) = 0; NMR.FX(r,t) = 0; ACP.FX(r,t) = 0; ER.FX(s,r,rr,t) = 0;

* Unless backstop is explicitly allowed, fix to zero:
$ifi %bs%==no BS.FX(s,r,t) = 0;

* Turn off banking variables if no cap (or in static application, or for post-2050 in all modes)
NBC.FX(t)$(t.val > 2050) = 0;
$ifi     %cap%==none    NBC.FX(t) = 0; CBC.FX(t) = 0;
$ifi     %cap_rg%==none NBC_RG.FX(r,t)=0; CBC_RG.FX(r,t)=0;
$ifi     %RGGI%==off    NBC_RGGI.FX(t) = 0; CBC_RGGI.FX(t) = 0;
$ifi not %static%==no   NBC.FX(t) = 0; CBC.FX(t) = 0; NBC_RG.FX(r,t)=0; CBC_RG.FX(r,t)=0;
* Banking and borrowing with a cap must be explicitly allowed
$ifi %bank%==no     NBC.FX(t) = 0; CBC.FX(t) = 0; NBC_RG.FX(r,t) = 0; CBC_RG.FX(r,t) = 0 ;
$ifi %borrow%==no   CBC.LO(t) = 0; CBC_RG.LO(r,t) = 0 ;
CBC_RGGI.LO(t) = 0 ;

* CES related:
$ifi %cesacp%==no        CES_ACP.up(r,t) = 0 ;
CES_NBC.FX(t) = 0;

$iftheni.resbounds not %opres%==no
* Operating Reserve related:
* Only certain technologies can contribute to spinning reserve:
SR.UP(s,i,v,r,t)$((not sri(i)) or (not ivrt(i,v,r,t))) = 0;

* For now, only natural gas turbines can contribute to quick start requirements
QS.UP(s,i,v,r,t)$((not qsi(i)) or (not ivrt(i,v,r,t))) = 0;

* Turn off variables if operating reserves not set
$ifi %opres%==no TOTREQ.UP(s,r,t)  = 0;
$ifi %opres%==no SPINREQ.UP(s,r,t) = 0;
$ifi %opres%==no SR.UP(s,i,v,r,t)  = 0;
$ifi %opres%==no QSREQ.UP(s,r,t)   = 0;
$ifi %opres%==no QS.UP(s,i,v,r,t)  = 0;
$endif.resbounds

* Turn off storage variables unless indicated
$ifi %storage%==no G.FX(s,j,r,t)=0; GD.FX(s,j,r,t)=0; GC.FX(j,r,t)=0; GB.FX(s,j,r,t)=0; GR.FX(j,r,t)=0; IGC.FX(j,r,t)=0; IGR.FX(j,r,t)=0;
$ifi %storage%==no $ifi not %opres%==no  SRJ.FX(s,j,r,t)=0; QSJ.FX(s,j,r,t)=0;

* Turn off CSP thermal storage variables unless indicated
$ifi not %cspstorage%==yes   G_CSP.FX(s,cspi,r) = 0; GD_CSP.FX(s,cspi,r) = 0; GB_CSP.FX(s,cspi,r) = 0;

* Turn off co-firing and retrofits (for testing)
$ifi not %nocr%==no X.FX(s,ivrt(i,v,r,t))$(cr(i) or idef(i,"cbcf")) = 0;

* Turn off nuclear share variables when 8760 segments are used
$ifi %seg%==8760 XN.FX(nc,r,t) = 0;

* In certain cases, no new transmission is allowed
$ifi not %notrn%==no TC.FX(r,rr,t) = 0;

* Turn off endogenous energy efficiency if so desired (default is 'no')
$ifi %enee%==no XC.FX("enee-n",v,r,t) = 0 ;

* In policy case, investments can be fixed to what occurred in the reference (fixIXref.gdx), up to the year %fixIX%
$iftheni.fixix2 not %fixIX%==no

* Generation investment bounds based upon reference investments. However, if the lifetime of a unit is lower in the current scenario than in
* the reference, this could be infeasible, so scale by current lifetime / reference lifetime.

parameter
  liferatio(i,r)
;

liferatio(i,r) = 1 ;

IX.LO(i,r,t)$(sum(tv(t,v), ivrt(i,v,r,t)) and not cr(i) and not (cof(i) and not xtech(i)) and (t.val le %fixIX%) and not tbase(t)) =
         max(0, ixfx(i,r,t) * liferatio(i,r) - 0.001) ;
IX.UP(i,r,t)$(sum(tv(t,v), ivrt(i,v,r,t)) and not cr(i) and not (cof(i) and not xtech(i)) and (t.val le %fixIX%) and not tbase(t)) =
         max(0, ixfx(i,r,t) * liferatio(i,r) + 0.001) ;

IX.LO(cr,r,t)$(sum(tv(t,v), ivrt(cr,v,r,t)) and (t.val le %fixIX%) and not tbase(t))  =
         max(0, ixfx(cr,r,t) * sum(ii$(crmap(cr,ii) and xtech(ii)), liferatio(ii,r)) - 0.001) ;
IX.UP(cr,r,t)$(sum(tv(t,v), ivrt(cr,v,r,t)) and (t.val le %fixIX%) and not tbase(t))  =
         max(0, ixfx(cr,r,t) * sum(ii$(crmap(cr,ii) and xtech(ii)), liferatio(ii,r)) + 0.001) ;

IX.LO(cof,r,t)$(sum(tv(t,v), ivrt(cof,v,r,t)) and not xtech(cof) and not cr(cof) and (t.val le %fixIX%) and not tbase(t)) =
         max(0,ixfx(cof,r,t) * sum(ii$(cofmap(cof,ii) and xtech(ii)), liferatio(ii,r)) - 0.001) ;
IX.UP(cof,r,t)$(sum(tv(t,v), ivrt(cof,v,r,t)) and not xtech(cof) and not cr(cof) and (t.val le %fixIX%) and not tbase(t)) =
         max(0,ixfx(cof,r,t) * sum(ii$(cofmap(cof,ii) and xtech(ii)), liferatio(ii,r)) + 0.001) ;

XC.LO(i,v,r,t)$(ivrt(i,v,r,t)$(t.val le %fixIX%)) = max(0, xcfx(i,v,r,t)-0.0001);
XC.UP(i,v,r,t)$(ivrt(i,v,r,t)$(t.val le %fixIX%)) = xcfx(i,v,r,t)+0.0001;

IT.LO(r,rr,t)$((t.val le %fixIX%) and not tbase(t)) = max(0,itfx(r,rr,t) - 0.001);
IT.UP(r,rr,t)$((t.val le %fixIX%) and not tbase(t)) = max(0,itfx(r,rr,t) + 0.001);
$endif.fixix2

* Investment only applies to new technologies, and only if not in dynfx mode
IX.FX(i,r,t)$(not new(i)) = 0;

* In dynfx mode, demand and installedG capacity are fixed to indicated values
$iftheni.dynfx2 %dynfx%==yes
D.FX(r,t) = dfx(r,t);

XC.FX(iv_fix(i,v),r,t) = xcfx(i,v,r,t);
IX.FX(i,r,t)$(not i_end(i)) = 0;
$iftheni.allowtrans not %allowtrans%==no
   installedT(r,rr) = 0;
$else.allowtrans
   IT.FX(r,rr,t) = 0;
   IT.UP(r,rr,t)$(ord(r)>ord(rr)) = installedT(r,rr) + 1e-6;
   IT.LO(r,rr,t)$(ord(r)>ord(rr)) = max(0, installedT(r,rr) - 1e-6);
   installedT(r,rr) = 0;
$endif.allowtrans
$endif.dynfx2

* Minimum battery storage policy constraints
$ifi not %static%==no $ifi %storage%==yes GC.LO("li-ion",r,t) = batttgt_r(r,t) ;

* * * * * * * * Trim non-applicable parts of matrix * * * * * *
           !! !!!!!!! CHECK ALL THIS !!!!!!!!!!!

* Turn off all non-applicable technology-vintage-timeperiod combinations
* Too costly for memory to assign complement of X:  must explicitly omit from model equations
XC.FX(   i,v,r,t)$(not ivrt(i,v,r,t)) = 0;

* No investment in base year (not applicable for static mode)
$ifi %static%==no IX.FX(i,r ,tbase) = 0;
$ifi %static%==no IT.FX(r,rr,tbase) = 0;
$ifi %static%==no IGC.FX(j,r ,tbase)$(not sameas(j,"hyps-x")) = 0; IGR.FX(j,r ,tbase)$(not sameas(j,"hyps-x")) = 0;

* No investment in CSP in the dynamic model
$ifi %static%==no IX.UP(cspi,r,t) = 0;

* No retirements permitted in the base year (not applicable for static model)
$ifi %static%==no XC.LO(i,vbase,r,tbase)$(not new(i)) = xcap(i,r) ;

* Fix battery storage investment in dynamic model
$ifi %static%==no IGC.FX(batt,r,t) = 0 ; IGR.FX(batt,r,t) = 0;

* Turn off trade variables for non-adjacent region pairs
E.FX(s,r,rr,t)$(not tcapcost(r,rr)) = 0;
ER.FX(s,r,rr,t)$(not tcapcost(r,rr)) = 0;
RPC.FX(r,rr,t)$(not tcapcost(r,rr)) = 0;

$ifi not %crb4%==no    IX.FX(i,r,t)$(cr(i) and (not idef(i,"ccs9")) and (t.val ge %crb4%)) = 0;

* Required new additions based on committed projects
IX.LO(i,r,t)$(not tbase(t)) = newunits(r,i,t);

* * * * * * * * * * * * * * * * * Solve the model * * * * * * * * * * * * * * * * *

$setlocal marker "%titlelead% solve"
put putscr;
put_utility  "title" / "%marker%" /  "msg" / "==== %marker% ====" /  "msg" / " " /;

$if not set solver $set solver cplex
option qcp=%solver%;

* If skipsolve is specified, read solution from basis and go directly to reporting
$ifthen.skip set skipsolve
$gdxin '%basisgdx%.gdx'
$load DR, X, HX, HPROD, XTWH, GRID, GRIDTWH, DA, demand, hannuald_d, hannuald_c, staterps, biomarket, gasmarket, rggimarket, recmkt
$ifi not %cap%==none $load carbonmarket
$ifi not %noncap%==none $load csapr_r, csapr_trdprg
$ifthen.nccost %nccost%==yes
$load XN
$else.nccost
XN.L(nc,r,t) = 0;
$endif.nccost
$gdxin
* Then read in entire solution at execution time
execute_loadpoint '%basisgdx%.gdx';
$else.skip
regenelec.optfile = 1;
regenelec.holdfixed = 1;
regenelec.reslim=72000;
$ifi not %opres%==no regenelec.reslim=72000;
option savepoint=1;
solve regenelec using qcp minimizing surplus;

$endif.skip

* * * * * * * * * * * * * * * * * * * Report solution * * * * * * * * * * * * * * *
$label report

put putscr;
$setlocal marker "%titlelead% reporting"
put_utility  "title" / "%marker%" /  "msg" / "==== %marker% ====" /  "msg" / " " /;

* Reporting calculations
$setglobal rptgdx %elecrpt%\%scen%.elec_rpt



