###################################################################################################
# File               : 4_run_compile.tcl                                                          #
# Author             : ADT-DT (jblee)                                                             #
# Description        : performs 'compile_fusion'                                                  #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.20                                                                 #
# Script Version     : 1.1                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
#         2025.08.20 - Add USER_COMPILE_END_STAGE, GEN_NET_FOR_DEF                                #
###################################################################################################

##----------------------------------------------------------------------------------------
## compile_fusion : Synthesis
##----------------------------------------------------------------------------------------
proc_time synthesis_START

source -echo -verbose ${BEFORE_INIT_MAP}

## save block for pre-synthesis floorplan and option check
save_block -as ${TOP_DESIGN}_before_compile
set_svf ${TOP_DESIGN}.initial_map.svf

## Report before compile
redirect ${REPORT_DIR}/${TOP_DESIGN}.check_cg_lib_available.rpt            { check_clock_gate_library_cell_availability }
redirect ${REPORT_DIR}/${TOP_DESIGN}.check_duplicates.rpt                  { check_duplicates -remove }

redirect ${REPORT_DIR}/${TOP_DESIGN}.analyze_lib_cell_placement.rpt        { analyze_lib_cell_placement -lib_cells [get_lib_cells] -directory ${REPORT_DIR}/ANALYZE_LIB_CELL }
if { [catch {exec grep -F ".frame" [file normalize "${REPORT_DIR}/${TOP_DESIGN}.analyze_lib_cell_placement.rpt"]} out] } { set ANALYZE_LIB_DONT_USE_RPT "" } else { set ANALYZE_LIB_DONT_USE_RPT $out }
set ALL_ANALYZE_LIB_DONT_USE_CELL ""
if { $ANALYZE_LIB_DONT_USE_RPT != "" } {
	foreach {CELL RATE} $ANALYZE_LIB_DONT_USE_RPT {
		if { [expr {$RATE == 0}] } {
			set DONT_USE_CELL [regsub {:} [regsub {\.frame} $CELL ""] "/"]
			lappend ALL_ANALYZE_LIB_DONT_USE_CELL $DONT_USE_CELL
			puts "Information_ADF: \"${DONT_USE_CELL}\" is set to dont_use based on the analyze_lib_cell_placement command results."
		} else {
			puts "Information_ADF: The pass rate of the \"${CELL}\" is higher than 0%, so it is not set to dont_use."
		}
	}
	if { $ALL_ANALYZE_LIB_DONT_USE_CELL != "" } {
		set_lib_cell_purpose -include none [get_lib_cells $ALL_ANALYZE_LIB_DONT_USE_CELL]
	}
} else {
	puts "Information_ADF: No cells are prohibited from use according to the results of the \"analyze_lib_cell_placement\" command."
}

redirect ${REPORT_DIR}/${TOP_DESIGN}.compile_check_only.rpt                { compile_fusion -check_only }
redirect ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.app_options.rpt       { report_app_options -non_default }
suppress_message {ATTR-11 ATTR-12 SEL-003}
redirect ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.lib_cell_purposes.rpt { report_lib_cell -objects [get_lib_cells] -column {full_name:70 valid_purposes} }
unsuppress_message {ATTR-11 ATTR-12 SEL-003}

## initial_map
proc_time init_map_START
set compile_cmd "compile_fusion -to initial_map"
puts "Information_ADF: Running ${compile_cmd}"
eval ${compile_cmd}
save_block -as ${TOP_DESIGN}_initial_map
proc_time init_map_END

if { $GEN_NET_FOR_DEF } { source -echo -verbose ${COMMON_FC_SYN}/write_outputs.tcl }
if { $USER_COMPILE_END_STAGE != "" && $USER_COMPILE_END_STAGE == "initial_map" } { puts "End of compile_fusion : USER_COMPILE_END_STAGE($USER_COMPILE_END_STAGE)" ; return }

set_svf ${TOP_DESIGN}.logic_opto.svf
source -echo -verbose ${BEFORE_LOGIC_OPTO}

## logic_opto
proc_time logic_opto_START
set compile_cmd "compile_fusion -from logic_opto -to logic_opto"
puts "Information_ADF: Running ${compile_cmd}"
eval ${compile_cmd}
save_block -as ${TOP_DESIGN}_logic_opto
proc_time logic_opto_END

source -echo -verbose ${AFTER_LOGIC_OPTO}
proc_time synthesis_END

if { $USER_COMPILE_END_STAGE != "" && $USER_COMPILE_END_STAGE == "logic_opto" } { puts "End of compile_fusion : USER_COMPILE_END_STAGE($USER_COMPILE_END_STAGE)" ; return }

if { $USER_COMPILE_END_STAGE == "" } {
    ## qor data
    if { $WRITE_QOR_DATA } { write_qor_data -output ${REPORT_DIR}/qor_data -label synthesis -report_group mapped }
}

## dft insertion
if { $DFT_INSERTION && [file exists $USER_DFT_SCRIPT] && $DFT_FLOW == "in_compile" } {

	set DESIGN_STAGE "dft"

    proc_time dft_insertion_START
	source -e -v ${RUN_DIR}/con/before_insert_dft.tcl
    proc_time dft_insertion_END

	source -e -v ${RUN_DIR}/con/after_insert_dft.tcl

    proc_time write_output_dft_START 
    source -echo -verbose ${COMMON_FC_SYN}/write_outputs.tcl
    proc_time write_output_dft_END 

}


##----------------------------------------------------------------------------------------
## compile_fusion : Initial
##----------------------------------------------------------------------------------------
proc_time initial_stage_START
set DESIGN_STAGE "to_initial_opto"

set_svf ${TOP_DESIGN}.initial_place.svf
source -echo -verbose ${BEFORE_INIT_PLACE}

## initial_place
proc_time init_place_START
set compile_cmd "compile_fusion -from initial_place -to initial_place"
puts "Information_ADF: Running ${compile_cmd}"
eval ${compile_cmd}
save_block -as ${TOP_DESIGN}_initial_place
proc_time init_place_END

if { $USER_COMPILE_END_STAGE != "" && $USER_COMPILE_END_STAGE == "initial_place" } { puts "End of compile_fusion : USER_COMPILE_END_STAGE($USER_COMPILE_END_STAGE)" ; return }

set_svf ${TOP_DESIGN}.initial_drc.svf
source -echo -verbose ${BEFORE_INIT_DRC}

## initial_drc
proc_time init_drc_START
set compile_cmd "compile_fusion -from initial_drc -to initial_drc"
puts "Information_ADF: Running ${compile_cmd}"
eval ${compile_cmd}
save_block -as ${TOP_DESIGN}_initial_drc
proc_time init_drc_END

if { $USER_COMPILE_END_STAGE != "" && $USER_COMPILE_END_STAGE == "initial_drc" } { puts "End of compile_fusion : USER_COMPILE_END_STAGE($USER_COMPILE_END_STAGE)" ; return }

set_svf ${TOP_DESIGN}.initial_opto.svf
source -echo -verbose ${BEFORE_INIT_OPTO}

## initial_opto
proc_time init_opto_START
set compile_cmd "compile_fusion -from initial_opto -to initial_opto"
puts "Information_ADF: Running ${compile_cmd}"
eval ${compile_cmd}
save_block -as ${TOP_DESIGN}_initial_opto
proc_time init_opto_END

source -echo -verbose ${AFTER_INIT_OPTO}
proc_time initial_stage_END

if { $USER_COMPILE_END_STAGE != "" && $USER_COMPILE_END_STAGE == "initial_opto" } { puts "End of compile_fusion : USER_COMPILE_END_STAGE($USER_COMPILE_END_STAGE)" ; return }

if { $USER_COMPILE_END_STAGE == "" } {
    proc_time write_output_compile_report_START 
    if { $WRITE_QOR_DATA } { write_qor_data -output ${REPORT_DIR}/qor_data -label ${DESIGN_STAGE} -report_group placed }
    
    source -echo -verbose ${COMMON_FC_SYN}/write_outputs.tcl
    source -echo -verbose ${COMMON_FC_SYN}/report.tcl
    proc_time write_output_compile_report_END 
}

## dft insertion
if { $DFT_INSERTION && [file exists $USER_DFT_SCRIPT] && $DFT_FLOW == "post_compile" } {

	set DESIGN_STAGE "dft"

    proc_time dft_insertion_START
	source -e -v ${RUN_DIR}/con/before_insert_dft.tcl
    proc_time dft_insertion_END

	source -e -v ${RUN_DIR}/con/after_insert_dft.tcl

    proc_time write_output_dft_START 
    source -echo -verbose ${COMMON_FC_SYN}/write_outputs.tcl
    source -echo -verbose ${COMMON_FC_SYN}/report.tcl
    proc_time write_output_dft_END
}

##----------------------------------------------------------------------------------------
## compile_fusion : Final
##----------------------------------------------------------------------------------------
if { $COMPILE_FINAL_STAGE } {
    proc_time final_stage_START
    set DESIGN_STAGE "to_final_opto"

	set_svf ${TOP_DESIGN}.final_place.svf

    ## pre-cts settings
    set set_stage_cmd "set_stage -step compile_place"
    puts "FRM_INFO: Running ${set_stage_cmd}"
    eval ${set_stage_cmd}

    source -echo -verbose ${BEFORE_FINAL_PLACE}
    
    ## final_place
    proc_time final_place_START
    set compile_cmd "compile_fusion -from final_place -to final_place"
    puts "Information_ADF: Running ${compile_cmd}"
    eval ${compile_cmd}
    save_block -as ${TOP_DESIGN}_final_place
    proc_time final_place_END

    if { $USER_COMPILE_END_STAGE != "" && $USER_COMPILE_END_STAGE == "final_place" } { puts "End of compile_fusion : USER_COMPILE_END_STAGE($USER_COMPILE_END_STAGE)" ; return }

	set_svf ${TOP_DESIGN}.final_opto.svf
    source -echo -verbose ${BEFORE_FINAL_OPTO}
    
    ## final_opto
    proc_time final_opto_START
    set compile_cmd "compile_fusion -from final_opto -to final_opto"
    puts "Information_ADF: Running ${compile_cmd}"
    eval ${compile_cmd}
    save_block -as ${TOP_DESIGN}_final_opto
    proc_time final_opto_END

    source -echo -verbose ${AFTER_FINAL_OPTO}
    proc_time final_stage_END

    if { $USER_COMPILE_END_STAGE != "" && $USER_COMPILE_END_STAGE == "final_opto" } { puts "End of compile_fusion : USER_COMPILE_END_STAGE($USER_COMPILE_END_STAGE)" ; return }

    proc_time write_output_compile_report_START 
    if { $WRITE_QOR_DATA } { write_qor_data -output ${REPORT_DIR}/qor_data -label ${DESIGN_STAGE} -report_group placed }
    
    source -echo -verbose ${COMMON_FC_SYN}/write_outputs.tcl
    source -echo -verbose ${COMMON_FC_SYN}/report.tcl
    proc_time write_output_compile_report_END 
}
