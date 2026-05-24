@echo off
set xv_path=E:\\Vivado\\2017.2\\bin
call %xv_path%/xelab  -wto 794d52e606ed40eab47ba3248aa8da3f -m64 --debug typical --relax --mt 2 -L blk_mem_gen_v8_3_6 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -L xpm --snapshot minisys_sim_behav xil_defaultlib.minisys_sim xil_defaultlib.glbl -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
