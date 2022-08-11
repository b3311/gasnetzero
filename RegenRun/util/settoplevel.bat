REM @echo off

REM  This is command file settoplevel.bat (in the util subdirectory of the run directory).

REM  REGEN operation depends upon the setting of various environment variables used to
REM    identify the locations of essential subdirectories.

REM  -------------------------------------------------------------------------------------------
REM  Directories containing files controlling executions.

REM  %regenrun%   is the root directory for GAMS files, command files, and
REM                 supporting files used to solve cases, report results, etc.
REM  %regenroot%  is the parent directory of %regenrun%.

REM  Under %regenrun% are subdirectories for three kinds of executions plus some utilities:
REM  %elecrun%   standalone executions of the electric sector model.
REM  %looprun%   executions of the macro-elec loop.
REM  %macrorun%  standalone executions of the macro model.
REM  %runutil%   utility command files.

REM  The locations of these execution-related directories are established by setrundirs.bat,
REM    which is located in %runutil% along with the current command file, settoplevel.bat.

REM  The obscure reference "%~dp0" provides the absolute path of the directory containing
REM     this commmand file, with a trailing "\".
REM  Hence, setrundirs.bat can be dispatched as follows, regardless of calling context:

call %~dp0\setrundirs.bat

REM  -------------------------------------------------------------------------------------------
REM  Directories containing (1) input data and (2) case results and reports.

REM  %elecdata%    contains the input data files (GDX) for execution of the electric sector
REM                  model (and maybe some supporting files also).
REM  %macrodata%   contains the input data files (GDX) for execution of the macroeconomic
REM                  model (and maybe some supporting files also).
REM  %regencases%  is the root directory for all files output by the execution of a case,
REM                  plus any follow-on report writing.

REM  If a "standard" REGEN setup is used, logic below can figure out the locations of
REM    these directories based on %regenroot%.

REM  If any of these directories is located elsewhere, settings specific to a user's
REM    environment are made by means of a command file called regenuser.bat, which
REM    is called here at the outset.

REM  Note that regenuser.bat is also used to set the location of GAMS license file(s),
REM    if the license in the active GAMS program directory is not the one to use for REGEN.

REM  If the standard directory setup is used *and* the GAMS license to use is the one
REM    in the active GAMS program directory, then file regenuser.bat is not needed at all.

REM  A user can choose to copy his/her file regenuser.bat into the %regenrun% directory
REM    (or %regenroot%) each time a new version of the %regenrun% tree is "installed".
REM  To avoid this, a user can define a persistent environment variable "regenuser" that
REM    contains the absolute path to the directory where his/her regenuser.bat resides.

if defined regenuser (
if exist  %regenuser%\regenuser.bat ( call %regenuser%\regenuser.bat & goto SETDIRS )
)
if exist   %regenrun%\regenuser.bat ( call  %regenrun%\regenuser.bat & goto SETDIRS )
if exist  %regenroot%\regenuser.bat ( call %regenroot%\regenuser.bat & goto SETDIRS )

REM  -------------------------------------------------------------------------------------------
:SETDIRS

REM  Set any unspecified directories to those of the standard setup, for which %regenroot%
REM    happens to be the parent directory for the data and results directories.

echo %elecdata%

REM data directories should not be conditioned on 'if not defined ...'
REM need to be able to redefine elecdata, etc. for different %ragg%'s
REM or even redefine regencases for different %regenroot%'s
set   elecdata=%regenroot%\RegenData\elec\%ragg%
REM if not defined   macrodata  set  macrodata=%regenroot%\RegenData\macro
set  endusedata=%regenroot%\RegenData\enduse\%ragg%
set  hoursdata=%regenroot%\RegenData\hours\%ragg%
set  regencases=%regenroot%\RegenCases
set  regenhours=%regenroot%\RegenHours
set  regenreport=%regenroot%\RegenReport


REM  The following identifies the second-tier levels of directories to contain case results.

set  eleccases=%regencases%\elec
set  loopcases=%regencases%\loop
REM set macrocases=%regencases%\macro
set endusecases=%regencases%\enduse

REM  The case results directories are created here if they do not yet exist.

if not exist  %regencases%  mkdir  %regencases%
if not exist  %regenhours%  mkdir  %regenhours%
if not exist  %regenreport%  mkdir  %regenreport%
if not exist   %eleccases%  mkdir  %eleccases%
if not exist   %loopcases%  mkdir  %loopcases%
REM if not exist  %macrocases%  mkdir  %macrocases%
if not exist  %endusecases%  mkdir  %endusecases%

