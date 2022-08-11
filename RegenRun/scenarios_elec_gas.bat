@echo off
REM  ==================================================================================================
REM  Execute REGEN Electric Model
REM  ==================================================================================================

REM specify regional definitions for runs in this group if not
REM calling from scenarios_loop.bat
set ragg=sup16

echo Regional aggregation in scenarios_elec.bat is %ragg%

call  .\util\settoplevel.bat

REM  ==================================================================================================
REM  Electric Model Parameters
REM  ==================================================================================================

REM  Operational, load, and market parameters (including NG prices, discount rate etc)
set  opparm=     --seg=120
set  opparm8760= --seg=8760

REM  Policy parameters
set  polparm=

REM  Technology parameters (cost or resource adjustments, build limits etc)
set  techparm=--cred45q=no --xcllife=60
set  techparm45q=--cred45q=yes --xcllife=60
set  techparm_relo=--cred45q=no --xcllife=60 --rnwtlc=regen_lo --batttlc=opt

REM  ==================================================================================================
REM  Scenario Definition and Run Commands
REM  ==================================================================================================

REM Prevent any stray value of "ref" environmental variable from being inherited by loopsub.bat or
REM elecsub.bat
set ref=

REM group name should indicate regional aggregation
REM e.g. %ragg%_%studyname%, or simply %ragg%
set group=%ragg%

REM Set runmode to   full     to run regenelec and elecrpt
REM set runmode to   report   to run only elecrpt
set runmode=full

REM  ===========================================================================
REM  Dynamic runs

REM ==== Reference Gas: Ref, Zero by 2035, Zero by 2050

set scen=ref_sup16
set elecparms=%opparm% %polparm% %techparm%
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

goto eof

set scen=zero35neg_ctax50
set elecparms=%opparm% %polparm% %techparm% --cap=zero35
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set scen=zero35_ctax50
set elecparms=%opparm% %polparm% %techparm% --cap=zero35 --credit_bio=0 --nodac=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set scen=cap80by35neg_ctax50
set elecparms=%opparm% %polparm% %techparm% --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set scen=cap80by35_ctax50
set elecparms=%opparm% %polparm% %techparm% --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --credit_bio=0 --nodac=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM ==== Low Gas Prices

set scen=ref_sup16_logas
set elecparms=%opparm% %polparm% %techparm% --baseline_pf=aeo2020hogr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set scen=zero35neg_ctax50_logas
set elecparms=%opparm% %polparm% %techparm% --cap=zero35 --baseline_pf=aeo2020hogr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set scen=cap80by35neg_ctax50_logas
set elecparms=%opparm% %polparm% %techparm% --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --baseline_pf=aeo2020hogr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM ==== High Gas Prices

set scen=ref_sup16_higas
set elecparms=%opparm% %polparm% %techparm% --baseline_pf=aeo2020logr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set scen=zero35neg_ctax50_higas
set elecparms=%opparm% %polparm% %techparm% --cap=zero35 --baseline_pf=aeo2020logr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set scen=cap80by35neg_ctax50_higas
set elecparms=%opparm% %polparm% %techparm% --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --baseline_pf=aeo2020logr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM ==== Sensitivities: Off NZ in 2035 Case with Reference Gas Prices

REM Low Wind/Solar/Battery Costs (NB: Already run for renewables webcast)

set scen=zero35neg_relo_ctax50
set elecparms=%opparm% %polparm% %techparm_relo% --basescen=zero35neg_ctax50 --cap=zero35
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM 45Q Extension

set scen=zero35neg_45qex_ctax50
set elecparms=%opparm% %polparm% %techparm45q% --basescen=zero35neg_ctax50 --cap=zero35
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM Lower Discount Rate (3%)

set scen=zero35neg_dr3_ctax50
set elecparms=%opparm% %polparm% %techparm% --basescen=zero35neg_ctax50 --cap=zero35 --drate=0.03
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM No New Gas

set scen=zero35neg_nonewgas_ctax50
set elecparms=%opparm% %polparm% %techparm% --basescen=zero35neg_ctax50 --cap=zero35 --nonewgas=2020
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM No New Gas or CCS

set scen=zero35neg_nonewgasnoccs_ctax50
set elecparms=%opparm% %polparm% %techparm% --basescen=zero35neg_ctax50 --cap=zero35 --nonewgas=2020 --ccslim=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM High Capture Rate (Allam) CCS

set scen=zero35neg_allam_ctax50
set elecparms=%opparm% %polparm% %techparm% --basescen=zero35neg_ctax50 --cap=zero35 --allam=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set scen=zero35_allam_ctax50
set elecparms=%opparm% %polparm% %techparm% --basescen=zero35_ctax50 --cap=zero35 --credit_bio=0 --nodac=yes --allam=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM Upstream CH4

set scen=zero35neg_ch4gas_ctax50
set elecparms=%opparm% %polparm% %techparm% --basescen=zero35neg_ctax50 --cap=zero35 --ch4gas=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set scen=zero35neg_ch4gashi_ctax50
set elecparms=%opparm% %polparm% %techparm% --basescen=zero35neg_ctax50 --cap=zero35 --ch4gas=yes --ch4gwp=30 --ch4lk=0.03
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.



REM Low-Cost LDES -- Values from Sepulveda, et al. (2021) consistent with DOE "Long Duration Storage Shot"

set scen=zero35neg_ldes_ctax50
set elecparms=%opparm% %polparm% %techparm% --basescen=zero35neg_ctax50 --cap=zero35 --storroom=10 --storcost=400
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.



REM Pessimistic Gas -- Also includes optimistic electrolyzer and LDES costs

set scen=zero35neg_pess_ctax50
set elecparms=%opparm% %polparm% %techparm_relo% --basescen=zero35neg_ctax50 --cap=zero35 --ch4gas=yes --beccshi=yes --nodac=yes --h2lo=yes --storroom=10 --storcost=400 --baseline_pf=aeo2020logr --hico2ts=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.



:dynnew

REM Low/High Gas Price Cases -- CF by 2050

set scen=cap80by35_ctax50_logas
set elecparms=%opparm% %polparm% %techparm% --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --credit_bio=0 --nodac=yes --baseline_pf=aeo2020hogr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set scen=cap80by35_ctax50_higas
set elecparms=%opparm% %polparm% %techparm% --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --credit_bio=0 --nodac=yes --baseline_pf=aeo2020logr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.





REM  ===========================================================================
REM  Static runs

:static

REM ==== Reference Gas

set dynfx_scen=ref_sup16
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=ref_sup16 --i_end=yes --storage=yes --allowtrans=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=ref_sup16
set dynfx_year=2050
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=ref_sup16 --i_end=yes --storage=yes --allowtrans=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=zero35neg_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=zero35_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --credit_bio=0 --nodac=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=cap80by35neg_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=cap80by35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=cap80by35neg_ctax50
set dynfx_year=2050
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=cap80by35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=cap80by35_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=cap80by35_ctax50 --i_end=yes --storage=yes --allowtrans=yes --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --credit_bio=0 --nodac=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=cap80by35_ctax50
set dynfx_year=2050
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=cap80by35_ctax50 --i_end=yes --storage=yes --allowtrans=yes --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --credit_bio=0 --nodac=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM ==== Low Gas Prices

set dynfx_scen=ref_sup16_logas
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=ref_sup16_logas --i_end=yes --storage=yes --allowtrans=yes --baseline_pf=aeo2020hogr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=ref_sup16_logas
set dynfx_year=2050
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=ref_sup16_logas --i_end=yes --storage=yes --allowtrans=yes --baseline_pf=aeo2020hogr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=zero35neg_ctax50_logas
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50_logas --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --baseline_pf=aeo2020hogr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=cap80by35neg_ctax50_logas
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=cap80by35neg_ctax50_logas --i_end=yes --storage=yes --allowtrans=yes --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --baseline_pf=aeo2020hogr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=cap80by35neg_ctax50_logas
set dynfx_year=2050
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=cap80by35neg_ctax50_logas --i_end=yes --storage=yes --allowtrans=yes --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --baseline_pf=aeo2020hogr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM ==== High Gas Prices

set dynfx_scen=ref_sup16_higas
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=ref_sup16_higas --i_end=yes --storage=yes --allowtrans=yes --baseline_pf=aeo2020logr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=ref_sup16_higas
set dynfx_year=2050
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=ref_sup16_higas --i_end=yes --storage=yes --allowtrans=yes --baseline_pf=aeo2020logr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=zero35neg_ctax50_higas
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50_higas --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --baseline_pf=aeo2020logr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=cap80by35neg_ctax50_higas
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=cap80by35neg_ctax50_higas --i_end=yes --storage=yes --allowtrans=yes --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --baseline_pf=aeo2020logr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=cap80by35neg_ctax50_higas
set dynfx_year=2050
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=cap80by35neg_ctax50_higas --i_end=yes --storage=yes --allowtrans=yes --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --baseline_pf=aeo2020logr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM ==== Sensitivities: Off NZ in 2035 Case with Reference Gas Prices

REM Low Wind/Solar/Battery Costs (NB: Already run for renewables webcast)

set dynfx_scen=zero35neg_relo_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm_relo% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM 45Q Extension

set dynfx_scen=zero35neg_45qex_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm45q% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM Lower Discount Rate (3%)

set dynfx_scen=zero35neg_dr3_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --drate=0.03
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM No New Gas

set dynfx_scen=zero35neg_nonewgas_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --nonewgas=2020
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM No New Gas or CCS

set dynfx_scen=zero35neg_nonewgasnoccs_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --nonewgas=2020 --ccslim=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM Allam

set dynfx_scen=zero35neg_allam_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --allam=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=zero35_allam_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --credit_bio=0 --nodac=yes --allam=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM Methane

set dynfx_scen=zero35neg_ch4gas_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --ch4gas=yes
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=zero35neg_ch4gashi_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --ch4gas=yes --ch4gwp=30 --ch4lk=0.03
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.



REM Low-Cost LDES

set dynfx_scen=zero35neg_ldes_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --storroom=10 --storcost=400
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.



REM Pessimistic Gas

set dynfx_scen=zero35neg_pess_ctax50
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm_relo% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --ch4gas=yes --nodac=yes --beccshi=yes --h2lo=yes --storroom=10 --storcost=400 --baseline_pf=aeo2020logr --hico2ts=ye
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.



:stnew

REM Low/High Gas Prices -- CF by 2050

set dynfx_scen=cap80by35_ctax50_logas
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=cap80by35neg_ctax50_logas --i_end=yes --storage=yes --allowtrans=yes --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --credit_bio=0 --nodac=yes --baseline_pf=aeo2020hogr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=cap80by35_ctax50_logas
set dynfx_year=2050
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=cap80by35neg_ctax50_logas --i_end=yes --storage=yes --allowtrans=yes --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --credit_bio=0 --nodac=yes --baseline_pf=aeo2020hogr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=cap80by35_ctax50_higas
set dynfx_year=2035
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=cap80by35neg_ctax50_higas --i_end=yes --storage=yes --allowtrans=yes --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --credit_bio=0 --nodac=yes --baseline_pf=aeo2020logr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=cap80by35_ctax50_higas
set dynfx_year=2050
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=cap80by35neg_ctax50_higas --i_end=yes --storage=yes --allowtrans=yes --manualcap=cap80by35 --mcap20=1.5 --mcap35=0.48 --mcap50=0 --credit_bio=0 --nodac=yes --baseline_pf=aeo2020logr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

REM Low/High Gas Prices -- NZ by 2035 in 2050

set dynfx_scen=zero35neg_ctax50
set dynfx_year=2050
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=zero35neg_ctax50_logas
set dynfx_year=2050
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --baseline_pf=aeo2020hogr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

set dynfx_scen=zero35neg_ctax50_higas
set dynfx_year=2050
set scen=static_%dynfx_scen%_%dynfx_year%
set elecparms=%opparm8760% %polparm% %techparm% --dynfx=yes --dispatch8760=%dynfx_year% --basescen=zero35neg_ctax50 --i_end=yes --storage=yes --allowtrans=yes --cap=zero35 --baseline_pf=aeo2020logr
call %elecrun%\elecsub.bat YES  &:: The YES just tells it to run the case -- useful in multi-case files.

:eof

REM  ==================================================================================================
REM  Tidy up and close files
REM  ==================================================================================================

title Finished all cases
