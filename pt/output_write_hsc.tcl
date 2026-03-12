################################################################################
# File Name     : output_write_hsc.tcl
# Author        : iskim1001
# Creation Date : 2023-09-07 
# Last Modified : 2024-08-01 
# Version       : v0.2
# Location      : ${PRJ_PT}/design_scripts/run_sta.tcl
#-------------------------------------------------------------------------------
# Description   : Create HSC
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2023-09-07] : iskim1001
# 		- Initial Version Release
# 	v0.2 [2024-08-01] : iskim1001
#       - Add if statement according to hsc_type variable
#-------------------------------------------------------------------------------
# Useage        :
# 	pt_shell > source output_write_hsc.tcl
#################################################################################
#check Before Value
printvar hier_enable_analysis 
printvar timing_save_hier_model_data
printvar timing_save_hier_context_data

#------------------------------------------------------------------------------
# Create hsc
#------------------------------------------------------------------------------
set_app_var hier_enable_analysis true

if {[ info exists hsc_type ] && $hsc_type == "model" } { 
		set_app_var timing_save_hier_model_data   true 
		set_app_var timing_save_hier_context_data false
} elseif { [info exists hsc_type] && $hsc_type == "context" } { 
		set_app_var timing_save_hier_model_data   false 
		set_app_var timing_save_hier_context_data true 
} else {
		set_app_var timing_save_hier_model_data true 
		set_app_var timing_save_hier_context_data false 
}

#check After Value
printvar hier_enable_analysis 
printvar timing_save_hier_model_data
printvar timing_save_hier_context_data


puts "Geneated HyperScale model"
write_hier_data  ${OUTPUT_DIR}/${DESIGN}.${MODE}.${CORNER}.hsc
exec touch done.hsc
