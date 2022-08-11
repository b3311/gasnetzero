@echo off
REM  This is file getelecgdx.bat (in the util subdirectory of the run directory).
REM  It is used to obtain the complete filename (minus the ".gdx") of the full GDX file
REM    stored with a saved case of a standalone execution of the electric sector model.

REM  %1  should be a group name or a "." if none applies.
REM  %2  should be the scenario_name.
REM  %3  is where the fully specified filename (or a dummy if not found) will be returned.

REM  Documentation of the directory-naming environment variables is in settoplevel.bat,
REM    which is also in the util subdirectory of the run directory.

REM  The obscure reference "%~dp0" provides the absolute path of the directory containing
REM     this commmand file, with a trailing "\".

call %~dp0\getmaingdx.bat elec %1 %2 %3
