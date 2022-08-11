* Include file setglobals.gms

$if setenv  group     $setglobal  group     %sysenv.group%

$if not set  scen     $if setenv  scen     $setglobal  scen     %sysenv.scen%

$if not set  looprun  $if setenv  looprun  $setglobal  looprun  %sysenv.looprun%

* $if not set  elecdata $if setenv  elecdata $setglobal  elecdata %sysenv.elecdata%
$if setenv  elecdata $setglobal  elecdata %sysenv.elecdata%
$if not set macrodata $if setenv macrodata $setglobal macrodata %sysenv.macrodata%
* $if not set endusedata $if setenv endusedata $setglobal endusedata %sysenv.endusedata%
$if setenv endusedata $setglobal endusedata %sysenv.endusedata%
* $if not set hoursdata $if setenv hoursdata $setglobal hoursdata %sysenv.hoursdata%
$if setenv hoursdata $setglobal hoursdata %sysenv.hoursdata%

$if not set  casedir  $if setenv  casedir  $setglobal  casedir  %sysenv.casedir%
$if not set  casepass $if setenv  casepass $setglobal  casepass %sysenv.casepass%

$if not set  elecout  $if setenv  elecout  $setglobal  elecout  %sysenv.elecout%
* $if not set  elecrpt  $if setenv  elecrpt  $setglobal  elecrpt  %sysenv.elecrpt%
$if setenv  elecrpt  $setglobal  elecrpt  %sysenv.elecrpt%

$if not set reportelec $if setenv reportelec $setglobal reportelec %sysenv.reportelec%
$if not set reporttrn $if setenv reporttrn $setglobal reporttrn %sysenv.reporttrn%
$if not set reportelecassm $if setenv reportelecassm $setglobal reportelecassm %sysenv.reportelecassm%

$if not set macroout  $if setenv macroout  $setglobal macroout  %sysenv.macroout%
$if not set macrorpt  $if setenv macrorpt  $setglobal macrorpt  %sysenv.macrorpt%

$if not set enduseout  $if setenv enduseout  $setglobal enduseout  %sysenv.enduseout%
$if not set enduserpt  $if setenv enduserpt  $setglobal enduserpt  %sysenv.enduserpt%

$if not set loopmode  $set loopmode no
$setglobal loopmode %loopmode%

$if set iter $setglobal iter %iter%

$if not defined putscr file putscr /%gams.scrdir%\tmp.scr/;

