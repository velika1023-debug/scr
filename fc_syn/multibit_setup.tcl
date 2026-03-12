###################################################################################################
# File               : multibit_setup.tcl                                                         #
# Author             : ADT-DT (jblee)                                                             #
# Description        : Multibit setting                                                           #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################
if {![info exists multibit_width_MIN] || $multibit_width_MIN == ""} {
    puts "Information_ADF : Multibit Min Width over 1"
    set multibit_width_MIN 1
}
if {![info exists multibit_width_MAX] || $multibit_width_MAX == ""} {
    puts "Information_ADF : Multibit Max Width under 6"
    set multibit_width_MAX 6
}

set default_none_mbit_cells [get_lib_cells -f "multibit_width > 1 && is_sequential && included_purposes==none"]
set_lib_cell_purpose [get_lib_cells -f "multibit_width > 1 && is_sequential"] -include none

set mbit_edit1 [get_lib_cells -f "multibit_width > $multibit_width_MIN && is_sequential"]
set mbit_edit2 [remove_from_collection $mbit_edit1 [get_lib_cells -f "multibit_width > $multibit_width_MAX && is_sequential"]]
set ALLOWED_MBIT_CELLS [remove_from_collection $mbit_edit2 $default_none_mbit_cells]

set MBIT_LIST_CNT [sizeof_collection $ALLOWED_MBIT_CELLS]
puts "### Information_ADF: Found $MBIT_LIST_CNT (ea) multibit cells !!"

foreach mbit_cell [get_attr $ALLOWED_MBIT_CELLS name] {
    puts "Info : $mbit_cell are MBIT FF"
    set_lib_cell_purpose [get_lib_cells */${mbit_cell}] -include optimization
}

if { $MBIT_OPT_MODE == "timing" } {
    set_multibit_options -slack_threshold 0.00
    set_app_options -name multibit.debanking.effort -value high
} elseif { $MBIT_OPT_MODE == "area_power" } {
    set_app_options -name compile.seqmap.prefer_registers_with_multibit_equivalent -value true
}

# Exclude cells from multibit optimization
if { [file exist $MBIT_EXCLUDE_LIST] } {
	set Fin [open $MBIT_EXCLUDE_LIST r]
	set EXCLUDE_MBIT_CELLS ""
	while { [ gets $Fin line ] != -1 } {
		if { [regexp {^#} $line] || ![regexp {\w+} $line] } { continue }
		set EXCLUDE_MBIT_CELLS [concat $EXCLUDE_MBIT_CELLS $line]
	}
	close $Fin

	puts "Information_ADF: The lists in \$MBIT_EXCLUDE_LIST are excluded from multibit banking."
	set_multibit_options -exclude [get_cells $EXCLUDE_MBIT_CELLS]

} else {
	if { $MBIT_EXCLUDE_LIST == "" } {
		puts "Information_ADF: There is no exclusion list for multibit banking"
	} else {
		puts "Error_ADF: $MBIT_EXCLUDE_LIST file does not exist"
	}
}
