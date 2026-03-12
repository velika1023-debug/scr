###################################################################################################
# File               : hier_syn_setup.tcl                                                         #
# Author             : ADT-DT (jjh8744)                                                           #
# Description        : hierarchical synthesis setup                                               #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################

# Generate set_reference and set_block_to_top_map commands
set ALL_SET_REF_CMD            ""
set ALL_SET_BLK_TO_TOP_MAP_CMD ""
foreach BLK_INFO $IMPL_BLK_INFO {
	set SUB_BLK_NAME   [lindex $BLK_INFO 0]

	set SUB_BLK_MODE   [lindex [split [lindex $BLK_INFO 1] "."] 0]
	set SUB_BLK_CORNER [lindex [split [lindex $BLK_INFO 1] "."] 1]
	set TOP_MODE       [lindex [split [lindex $BLK_INFO 2] "."] 0]
	set TOP_CORNER     [lindex [split [lindex $BLK_INFO 2] "."] 1]

	set SUB_BLK_ABS    [set ${SUB_BLK_NAME}_NLIB]:${SUB_BLK_NAME}.abstract

	lappend ALL_SET_REF_CMD "set_reference -to_block $SUB_BLK_ABS ${SUB_BLK_NAME}_temp"
	lappend ALL_SET_BLK_TO_TOP_MAP_CMD "set_block_to_top_map -block { ${SUB_BLK_NAME}_temp } -mode { $SUB_BLK_MODE $TOP_MODE } -corner { $SUB_BLK_CORNER $TOP_CORNER }"
}

set ALL_SET_REF_CMD [lsort  -unique $ALL_SET_REF_CMD]
set ALL_SET_BLK_TO_TOP_MAP_CMD [lsort -unique $ALL_SET_BLK_TO_TOP_MAP_CMD]


# Execute the rename_module and set_ref commands
set cmd_exec_flag_cnt "0"

foreach cmd $ALL_SET_REF_CMD {
	set cmd_exec_flag     "0"

	set SUB_DESIGN_NAME [regsub "_temp" [lindex $cmd end] ""]
	set SUB_DESIGN_ALL_INST_NAME [get_cells -quiet -hierarchical -filter "ref_name == $SUB_DESIGN_NAME"]
	if { [sizeof_collection $SUB_DESIGN_ALL_INST_NAME] == "0" } {
		set cmd_exec_flag "1"
		incr cmd_exec_flag_cnt

		echo "Information_ADF: $SUB_DESIGN_NAME (Mismatch between sub-design name and the reference name in the top-level design)"
		echo "SUB_DESIGN_NAME : $SUB_DESIGN_NAME"
		set SUB_MODULE_NAME [get_object_name [get_modules -quiet * -filter "hdl_template == $SUB_DESIGN_NAME"]]
		if { [llength $SUB_MODULE_NAME] > 0 } {
			echo "rename_module $SUB_MODULE_NAME $SUB_DESIGN_NAME ;# execute command"
			set SUB_DESIGN_ALL_INST_NAME [get_cells -quiet -hierarchical -filter "ref_name == $SUB_MODULE_NAME"]
		} else {
			echo "Error_ADF: Cannot find a design that matches \"$SUB_DESIGN_NAME\""
		}
	} else {
		echo "Information_ADF: $SUB_DESIGN_NAME (Matching between sub-design name and reference name in the top-level design)"
	}


	if { [sizeof_collection $SUB_DESIGN_ALL_INST_NAME] > 0 } {
		echo "    $SUB_DESIGN_NAME :"
		foreach_in_collection SUB_DESIGN_INST_NAME $SUB_DESIGN_ALL_INST_NAME {
			echo "      [get_object_name $SUB_DESIGN_INST_NAME]"
		}
	}

	if { $cmd_exec_flag == "1" && [sizeof_collection $SUB_DESIGN_ALL_INST_NAME] > 0 } {
		set fields   [split $cmd " "]
		set last_idx [expr {[llength $fields] - 1}]
		set fields   [lreplace $fields $last_idx $last_idx \[get_cells \{[get_object_name $SUB_DESIGN_ALL_INST_NAME]\}\]]
		set new_cmd  [join $fields " "]
		echo "$new_cmd ;# execute command"

		rename_module $SUB_MODULE_NAME $SUB_DESIGN_NAME
		eval $new_cmd
	}
	echo ""
}

if { $cmd_exec_flag_cnt > 0 } {		
	echo "Information_ADF: relink is performed"
	redirect -file ${LOG_DIR}/${TOP_DESIGN}.after_set_ref_relink.log { link_block -force }
} else {
	echo "Information_ADF: relink is not performed"
}

if { $IMPL_BLK_TIMING_IGNORE == "true" } {
	echo "Information_ADF: all internal R2R timing paths inside sub-blocks will be disabled."
	set_timing_paths_disabled_blocks -all_sub_blocks
}
