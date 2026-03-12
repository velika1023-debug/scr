################################################################################
# File Name     : output_write_etm.tcl
# Author        : iskim1001
# Last Modified : 2024-11-07
# Version       : v0.4
# Location      : ${PRJ_PT}/design_scripts/run_sta.tcl
#-------------------------------------------------------------------------------
# Description   : Create *ETM.lib and *ETM.db.
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2023-09-07] : iskim1001
# 		- Initial Version Release
# 	v0.2 [2024-05-30] : iskim1001
# 		- Integrate etm and etmpg
# 		- Add Variable
# 			- etm_setting_project : $PRJ_TOOLS_DIR/pt_sta/${PROJECT_NAME}_etm_set.tcl
# 			- etm_setting_user    : User_setting_value
# 			- etm_setting_upf     : User_setting_value
# 	v0.3 [2024-06-04] : iskim1001
# 		- Modify Variable name
# 			etm_setting_project  ->  ETM_PRJ_CONST
# 			etm_setting_user     ->  ETM_DESIGN_CONST
# 			etm_setting_upf      ->  ETM_DESIGN_UPF
# 	v0.4 [2024-11-07] : iskim1001
# 		- Modify source logic
#
#-------------------------------------------------------------------------------
# Useage        :
#   pt_shell > source output_write_etm.tcl
#################################################################################

# Setting Variable ETM
if {[info exists gen_etm]  && ${gen_etm}  } {


} elseif {[info exists gen_etmpg]  && ${gen_etmpg}  } {
	set_app_var extract_model_include_upf_data true
	set_app_var extract_model_upf_supply_precedence external
	load_upf    $ETM_DESIGN_UPF
}


# Read etm_setting_* file
set fname_list [list ${ETM_PRJ_CONST} ${ETM_DESIGN_CONST} ]
foreach fname $fname_list {
	if { [file exists $fname] } {
		puts "Information_ADF: Found File "
		puts "Information_ADF: --> $fname"
		source -e -v $fname
	} else {
		puts "Warning_ADF: Found File "
		puts "Warning_ADF: --> $fname"
	}
}


#set extract_model_clock_transition_limit $technology_upper_limit ; default 5
#set extract_model_data_transition_limit $technology_upper_limit ; default 5
#set extract_model_capacitance_limit $technology_upper_limit ; default 5
set extract_model_num_clock_transition_points 7
set extract_model_num_data_transition_points 7
set extract_model_status_level high
set extract_model_with_clock_latency_arcs true
set timing_slew_propagation_mode worst_slew
set si_xtalk_delay_analysis_mode all_paths
set extract_model_with_ccs_timing false



update_timing


puts "Geneated ETM model"
extract_model -format {lib db} -library_cell -output ${OUTPUT_DIR}/${DESIGN}.${MODE}.${CORNER}.ETM
exec touch done.etm
