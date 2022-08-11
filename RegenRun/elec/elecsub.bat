@echo off
REM  This is command file elecsub.bat (in the elec subdirectory of the run directory).
REM  It is used to run the electric sector model in standalone mode.

setlocal enabledelayedexpansion

REM  The caller should specify a desired scenario name, either as argument %1 or by
REM    setting environment variable "scen" to the name.
REM  The caller may set a reference case (for paref) via environment variable "ref".
REM  ref should be of the form "group_name scenario_name", where
REM    group_name should be "." if it does not apply.
REM  DO NOT INCLUDE SPACE CHARACTERS in the group or scenario names.

REM  A keyword is used to specify whether or not to solve the scenario.
REM    Any value other than "YES" or "yes" specifies no solve.
REM  There are two ways to specify this keyword.
REM  (1) Load the keyword in an environment variable with name equal to the scenario name.
REM  (2) Supply the keyword as a command line argument:
REM     (a) argument %2 if the scenario name is passed in as argument %1
REM     (b) argument %1 if the scenario name is set via the environment variable "scen"

if '%2' neq '' (
  REM  Two arguments present ==> presume case (2a) applies.
  set scen=%1
  set doit=%2
  goto TESTNOGO
)

if '%1' neq '' (
  REM  One argument is present. Which is it?
  if defined scen (
    REM  Presume the argument is the keyword and case (2b) applies.
    set doit=%1
    goto TESTNOGO
  )
  REM  Presume the argument is the scenario name and case (1) applies.
  set scen=%1
) else (
  REM  No arguments present. If scen is defined, presume case (1) applies; otherwise quietly do nothing.
  if not defined scen goto :EOF
)

REM  Arriving here means case (1) applies.
REM  This is a devious way to pull a value from the environment variable named by the scenario name.
REM  It has the necessary advantage of stripping leading and trailing blanks around a non-blank value.
for /F %%Y in ("!%scen%!") do (set doit=%%Y)

REM  If the value of the environment variable is all blank, doit comes out undefined,
REM    in which case quietly do nothing.
if not defined doit goto :EOF

:TESTNOGO
echo Resolved args: [%scen%] [%doit%]
if /I %doit% neq YES goto :EOF

set message=Executing the %scen% case of the electric sector model
title !message!
echo *
echo !message! ...
echo *

REM  ---------------------------------------------------------------------------------------------------------------------------
REM  Documentation of the directory-naming environment variables is in settoplevel.bat,
REM    which is in the util subdirectory of the run directory.

REM  The execution runs from the %elecrun% directory for standalone solves of the electric sector model.

REM  Environment variable "elecrun" has not been set as of yet, but it is possible to set the
REM    active directory to what will come to be referenced as %elecrun% by means of this device:
pushd %~dp0   &::  "%~dp0" provides the absolute path of the directory containing this commmand file.

REM  The caller may set environment variable "group", which causes the case directory
REM    (%casedir%) to be located under %eleccases%\%group% rather than %eleccases%.
REM  DO NOT INCLUDE SPACE CHARACTERS in the group name.

call setelecdirs.bat  &::  This will set all necessary directory-related environment variables.

REM  ---------------------------------------------------------------------------------------------------------------------------
REM  Environment variables that build up parameter specifications to be used in GAMS processing:

REM  The caller may set environment variable "elecparms" with parameters to pass to GAMS.

REM  The caller may set environment variable "listparms" to override the following defaults.
if not defined listparms set listparms=errmsg=1 logoption=3 logline=1 nocr=1 pagecontr=2 pagesize=0 pagewidth=256

set elecparms=%elecparms% --loopmode=no

if defined licelec set elecparms=%elecparms% license=%licelec%

REM  ---------------------------------------------------------------------------------------------------------------------------
REM  Execution section

REM this is very bad
REM call deloldelec.bat

set moreargs=s=%elecrestart%\%scen%.elec.g00  gdx=%elecout%\%scen%.elec.gdx --basisgdx=%elecbasis%\%scen%.elec

if defined ref_scen (
  call %runutil%\getmaingdx.bat elec %group% %ref_scen% elecrefgdx
REM (Grab the report file as well)
  call %runutil%\getrptgdx.bat elec %group% %ref_scen% elec_rpt elecrptrefgdx
  set moreargs=%moreargs% --elecrefgdx=!elecrefgdx! --elecrptrefgdx=!elecrptrefgdx!
)
if defined fixIXref_scen (
  call %runutil%\getmaingdx.bat elec %group% %fixIXref% fixIXgdx
  set moreargs=%moreargs% --fixIXgdx=!fixIXgdx!
)
if defined etsref_scen (
  call %runutil%\getmaingdx.bat elec %group% %etsref_scen% etsrefgdx
  set moreargs=%moreargs% --etsrefgdx=!etsrefgdx!
)
if defined dynfx_scen (
  call %runutil%\getmaingdx.bat elec %group% %dynfx_scen% dynfxgdx
  set moreargs=%moreargs% --dynfxgdx=!dynfxgdx!

  REM Possible that the dynfx reference file is an integrated run
  if /I !dynfxgdx!==NotFound (
    call %runutil%\getloopgdx.bat elec %group% %dynfx_scen% dynfxgdx
    set moreargs=%moreargs% --dynfxgdx=!dynfxgdx!
  )
)

REM goto report

set errorlevel=0
if not %runmode%==full goto %runmode%

REM * * * * * Electric Model Solve * * * * *
gams regenelec  %elecparms%  %listparms%  %moreargs%  o=%eleclist%\%scen%.elec.lst  |  tee  %eleclist%\%scen%.elec.log
if not exist  %eleclist%\%scen%.elec.lst  goto FAILEDSOLVE
find "ERROR(S) ENCOUNTERED" %eleclist%\%scen%.elec.lst  > nul  &&  goto FAILEDSOLVE
if not ["%errorlevel%"]==["0"] goto FAILEDSOLVE

set message=Successful execution of the %scen% case of the electric sector model
echo !message!. > %casedir%\success_solve.txt
move regenelec_p.gdx %elecbasis%\%scen%.elec.gdx


set message=Successful execution of the %scen% case of the electric model report
echo !message!. > %casedir%\success_report.txt

goto END

:FAILEDSOLVE
set message=Error in solving the %scen% case of the electric sector model (code = %errorlevel%)
set errcode=1
echo !message!. > %casedir%\failed_solve.txt

goto END

:FAILEDREPORT
set message=Error in the %scen% case of the electric model report
set errcode=1
echo !message!. > %casedir%\failed_report.txt

:END
popd

title !message!
echo *
echo * !message!. *
echo *
echo *

if !errcode! equ 1  exit /b 1

