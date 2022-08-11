@echo off
REM  This is command file setelecdirs.bat (in the elec subdirectory of the run directory).

REM  If optional argument %1 is "nocreate", the mkdir operations are skipped.

REM  Documentation of the directory-naming environment variables is in settoplevel.bat,
REM    which is in the util subdirectory of the run directory.

REM  The caller REALLY SHOULD set environment variable "scen" to a desired scenario name
REM    (or get the name "unspecified" below).
REM  The caller may set environment variable "group", which causes the case directory
REM    (%casedir%) to be located under %eleccases%\%group% rather than %eleccases%.
REM  DO NOT INCLUDE SPACE CHARACTERS IN ANY OF THESE NAMES.

REM  Call settoplevel.bat to set the higher-level directories.
REM  %~dp0 is the path to the elec directory containing this command file, with a trailing "\".
REM  The util directory is parallel to the elec directory, thus allowing this invocation:
call %~dp0..\util\settoplevel.bat

if not defined scen set scen=unspecified

if defined group (set groupdir=%eleccases%\%group%) else (set groupdir=%eleccases%)

set     casedir=%groupdir%\%scen%

(set   caseelec=%casedir%)        &::  It seems pointless to have an "elec" subdirectory here.

set    eleclist=%caseelec%\list
set    elecbasis=%caseelec%\basis
set     elecout=%caseelec%\out
set     elecrpt=%caseelec%\report
set elecrestart=%caseelec%\restart

set reportelec=%regenreport%\Electric\%group%
set reporttrn=%regenreport%\Transmission\%group%

if '%1'=='nocreate' goto :EOF

if not exist  %groupdir%     mkdir  %groupdir%
if not exist  %casedir%      mkdir  %casedir%
if not exist  %caseelec%     mkdir  %caseelec%
if not exist  %eleclist%     mkdir  %eleclist%
if not exist  %elecbasis%    mkdir  %elecbasis%
if not exist  %elecout%      mkdir  %elecout%
if not exist  %elecrpt%      mkdir  %elecrpt%
if not exist  %elecrestart%  mkdir  %elecrestart%

if not exist %reportelec% mkdir %reportelec%
if not exist %reporttrn% mkdir %reporttrn%
