@echo off
set xv_path=E:\\Vivado\\2017.2\\bin
call %xv_path%/xsim minisys_sim_behav -key {Behavioral:sim_1:Functional:minisys_sim} -tclbatch minisys_sim.tcl -view E:/project11/minisys_sim_behav1.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
