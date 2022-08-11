@echo off
REM  This is file setrundirs.bat (in the util subdirectory of the run directory).

REM  Documentation of the directory-naming environment variables is in settoplevel.bat,
REM    which is also in the util subdirectory of the run directory.

REM The following is rather anal stuff to get clean-looking paths for
REM   parent directory %regenrun% and its parent %regenroot%.

REM  The obscure reference "%~dp0" provides the absolute path of the directory containing
REM     this commmand file, with a trailing "\".

REM  Move up to the parent directory which is to be set as %regenrun%.
pushd %~dp0..
set regenrun=%cd%

REM  Move up to the grandparent directory which is to be set as %regenroot%.
cd ..
set regenroot=%cd%

REM  Return to the original working directory.
popd

REM  The following specify the second-tier levels of directories with run-related files
REM    for three kinds of executions plus some utilities.

(set  elecrun=%regenrun%\elec)   &::  standalone executions of the electric sector model
(set  looprun=%regenrun%\loop)   &::  executions of the macro-elec loop
(set macrorun=%regenrun%\macro)  &::  standalone executions of the macro model
(set enduserun=%regenrun%\enduse) &::  standalone executions of the enduse model
(set hoursrun=%regenrun%\hours) &::  executions of the hour-choice code
(set  runutil=%regenrun%\util)   &::  utility command files
