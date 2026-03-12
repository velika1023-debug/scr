##########################################################################################
## DFT in/post_compile flow
##########################################################################################
# If you encounter the following Error message, use the "tmax_exec" option to specify the correct path to tmax64.
#     Error: TMAX executable .../fusioncompiler/V-2023.12-SP5/linux64/syn/bin/tmax64 could not run, exceeded first prompt time limit
#
# set TMAX_PATH "/misc/tool/SYNOPSYS/txs/V-2023.12-SP5-3/linux64/syn/bin/tmax64"
# set_dft_drc_configuration -tmax_exec $TMAX_PATH


if { $DFT_FLOW == "in_compile" } {
	puts "Information_ADF: DFT in_compile flow"
	set_app_options  -name  dft.insertion_post_logic_opto             -value  true
} else {
	puts "Information_ADF: DFT post_compile flow"
}

if { $SCAN_DEF_FILE == "" } {
	puts "Information_ADF: Not using scandef file"
	set_app_options  -name  place.coarse.continue_on_missing_scandef  -value  true
} elseif { ![file exist $SCAN_DEF_FILE] } {
	puts "Error_ADF: $SCAN_DEF_FILE does not exist"
} else {
	puts "Information_ADF: Read scandef file :"
	puts "                   $SCAN_DEF_FILE"
	read_def $SCAN_DEF_FILE
}

if { $COMPILE_OPT_SCAN_CHAIN == "true" } {
	puts "Information_ADF: Enable scan chain optimization"
	set_app_options  -name  opt.dft.optimize_scan_chain               -value  true
	set_app_options  -name  opt.dft.use_ng_engines                    -value  true
	set_optimize_dft_options -goal total_interconnect_length  ;# total_interconnect_length/max_interconnect_length
}

source -echo -verbose $USER_DFT_SCRIPT
save_block -as ${TOP_DESIGN}_after_dft_${DFT_FLOW}
