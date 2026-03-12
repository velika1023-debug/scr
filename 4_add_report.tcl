#!/bin/csh -f
###################################################################################################
# File               : 4_add_report.tcl                                                           #
# Author             : ADT-DT (jyjang)                                                            #
# Author2            : ADT-DT (jmpark)                                                            #
# Usage              :                                                                            #
# Init Release Date  : 2023.03.31                                                                 #
# Last Update  Date  : 2023.05.12 - add save_upf                                                  #
#                      2024.11.25 - add dont_touch, dont_use report                               #
#                      2025.02.18 - added a part to source check_con.tcl file (jjh8744)           #
# Script Version     : 0.3                                                                        #
#                                                                                                 #
###################################################################################################

source ${COMMON_TCL}/dc_syn/proc_clock.tcl
source ${COMMON_TCL}/dc_syn/proc_rpt_global_timing.tcl

if {$USE_MULTIBIT} {
source -echo -verbose  ${PRJ_DC_SYN}/report_multibit_register_list.tcl
report_multibit_register_list    > ${REPORT_DIR}/${TOP_DESIGN}.mbit_list.rpt
}

query_objects [get_cells -hierarchical -filter "is_unmapped==true" ]  > ${REPORTS_DIR}/${TOP_DESIGN}.compile.unmapped.rpt

saif_map -type ptpx -write_map ./${TOP_DESIGN}.dft.saif_map

# Latch
#query_objects -truncate 0 [all_registers -level_sensitive ]     > ${REPORT_DIR}/${TOP_DESIGN}.latches.rpt
set ALL_LATCH_CELL [all_registers -level_sensitive]
echo "# Latch list"                                                   > ${REPORT_DIR}/${TOP_DESIGN}.include_lockup_latches.rpt
echo "# Latch list (Excluded cells with names containing \"LOCKUP\")" > ${REPORT_DIR}/${TOP_DESIGN}.latches.rpt

if { [sizeof_collection ${ALL_LATCH_CELL}] > 0 } {
	foreach_in_collection cell $ALL_LATCH_CELL {
		set fname [get_attr $cell full_name]
		echo "$fname" >> ${REPORT_DIR}/${TOP_DESIGN}.include_lockup_latches.rpt

		set endli [lindex [split $fname "/"] end]
		if { ![string match -nocase "*lockup*" $endli] } {
			echo "$fname" >> ${REPORT_DIR}/${TOP_DESIGN}.latches.rpt
		}
	}
}
unset ALL_LATCH_CELL

rpt_global_timing -design_stage ${DESIGN_STAGE}
rpt_clock -design_stage ${DESIGN_STAGE}
report_clocks -attributes -skew                                 > ${REPORT_DIR}/${TOP_DESIGN}.clocks.rpt
#report_clock_tree -summary -settings -structure                 > ${REPORT_DIR}/${TOP_DESIGN}.clock_tree.rpt
report_clock_gating -ungated -verbose    -nosplit               > ${REPORT_DIR}/${TOP_DESIGN}.ungated_registers.rpt
report_compile_options                                          > ${REPORT_DIR}/${TOP_DESIGN}.compile_options.rpt
report_power_gating                                             > ${REPORT_DIR}/${TOP_DESIGN}.power_gating.rpt
report_power_gating -missing                                   >> ${REPORT_DIR}/${TOP_DESIGN}.power_gating.rpt
report_power_gating -unconnected                               >> ${REPORT_DIR}/${TOP_DESIGN}.power_gating.rpt
mem -all                                                        > ${REPORT_DIR}/${TOP_DESIGN}.mem_usage.rpt

report_threshold_voltage_group 									> ${REPORT_DIR}/${TOP_DESIGN}.vth.ratio.rpt

# This is a command added temporarily. (It may disappear.)
#if {$USE_MCMM} {
#report_scenarios         > ${REPORT_DIR}/${TOP_DESIGN}.scenarios.rpt2
#report_block_abstraction > ${REPORT_DIR}/${TOP_DESIGN}.block_abstraction_after_scn_setup.rpt2
#}

if {[file exist $IMPL_UPF]} {

    #write upf
    save_upf                                 ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.syn.upf
    save_upf  -full_upf                      ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.syn.full.upf

    cd ${OUTPUT_DIR}
    exec ln -sf ./${TOP_DESIGN}.${RPT_POSTFIX}.syn.upf            ${TOP_DESIGN}.upf
    exec ln -sf ./${TOP_DESIGN}.${RPT_POSTFIX}.syn.full.upf       ${TOP_DESIGN}.full.upf
    cd ..;
}

#add jmpark 241126
set_app_var collection_result_display_limit -1

source ${COMMON_TCL}/dc_syn/check_con.tcl


#################################################################################
# link Final report
#################################################################################
if { $DESIGN_STAGE != "final" } {
	puts "\[Final Stage\] ${DESIGN_STAGE}"
	cd ${REPORT_DIR}
	foreach rpt_list [glob -nocomplain ./*${DESIGN_STAGE}*] {
	    set rpt_name [file tail $rpt_list]
	    set new_name [regsub -all "${DESIGN_STAGE}" $rpt_name "final"]
	    exec ln -sf $rpt_name $new_name
	}
	cd ${RUN_DIR}

	# SYN OPT- message info
    set SELECT_LIST {OPT-1055 OPT-1206 OPT-1207 OPT-1215}
    set TARGET_LOG "${LOG_DIR}/${TOP_DESIGN}.syn.log"
    set OUTPUT_LOG "${LOG_DIR}/${TOP_DESIGN}.syn_OPT_info.log"
    if {[file exists $OUTPUT_LOG]} {
        puts "Information_ADF : ${TOP_DESIGN}.syn_OPT_info.log is already exist. remove...."
        sh rm $OUTPUT_LOG
    } 
    set fp [open $OUTPUT_LOG w+]
    
    foreach opt $SELECT_LIST {
        set temp_log [exec grep "($opt)" $TARGET_LOG]
        set count    [llength [split $temp_log "\n"]]
    
        puts $fp "# -============================"
        puts $fp "# Target : $opt - $count"
        puts $fp "# -============================"
        puts $fp $temp_log
        puts $fp "\n"
    }
    close $fp
}

# if [file exists "${TOP_DESIGN}_user_dont_touch.rpt"] {
# 	sh rm -rf ${REPORT_DIR}/${TOP_DESIGN}_user_dont_touch.rpt
# }
# 
# if [file exists "${TOP_DESIGN}_user_dont_use.rpt"] {
# 	sh rm -rf ${REPORT_DIR}/${TOP_DESIGN}_user_dont_use.rpt
# }
# 
# foreach_in_collection itr [get_dont_touch_nets -type user -hierarchical *] {
# 	echo "[get_object_name $itr] type : net" >> ${REPORT_DIR}/${TOP_DESIGN}_user_dont_touch.rpt
# }
# 
# foreach_in_collection itr [remove_from_collection [get_dont_touch_cells -type user -hierarchical *] [get_dont_touch_cells -type cg_mo -hierarchical *]] {
# 	echo "[get_object_name $itr] type : cell" >> ${REPORT_DIR}/${TOP_DESIGN}_user_dont_touch.rpt
# }
# 
# foreach itr $TARGET_LIB_NAME {
# 	foreach_in_collection itr2 [remove_from_collection [get_lib_cells *${itr}*/* -filter "dont_use == true && syn_library == true"] [get_lib_cells *${itr}*/* -filter "dont_touch == true"]] {
# 		echo "[get_object_name $itr2]" >> ${REPORT_DIR}/${TOP_DESIGN}_user_dont_use.rpt
# 	}
# }
