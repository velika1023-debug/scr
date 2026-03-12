################################################################################
# File Name     : find_dly_cell_chain.tcl
# Author        : DT-PI
# Creation Date : 2024-01-25 
# Last Modified : 2024-01-25 
# Version       : v0.1
# Location      : ${PRJ_PT}/design_scripts/misc_reports.tcl
#-------------------------------------------------------------------------------
# Description   :
# 	Find long delay chain path (reference file : sec_find_dly_cell_chain.v1.4.tcl of FDS)
#-------------------------------------------------------------------------------
# Change Log    :
# 	[2024-01-25] v0.1 : jjh8744
#       - Initial Version Release
#-------------------------------------------------------------------------------
# Useage        :
# 	pt_shell > find_dly_cell_chain -length_greater_than 8
#################################################################################
suppress_message        CMD-041

global __proc_name __sec_scr_version

set __proc_name                       "find_dly_cell_chain"
set __sec_scr_version($__proc_name)   "V1.4 - Mar. 23, 2021"

global verbose_mode debug_mode debug_level
global length_threshold max_chain_legnth __trace_all_arcs num_detected_chain num_short_chain

echo "**SEC_INFO: custom procedure added - $__proc_name ($__sec_scr_version($__proc_name))"
proc find_dly_cell_chain { args } {
	global verbose_mode debug_mode debug_level __proc_name __sec_scr_version
	global max_chain_length length_threshold num_short_chain num_detected_chain __trace_all_arcs IS_DLY
	
	set length_threshold    0
	set num_short_chain     0
	set num_detected_chain  0
	set debug_mode          0
	set debug_level         0
	set verbose_mode        0
	set max_chain_length    0
	set lib_cell_pattern    {.*/((IP|NE|GP)?DLY\\d|.*_DEL_).*}
	set __trace_all_arcs    0
	
	parse_proc_arguments -args $args results
	foreach argname [array names results] {
		switch -glob -- $argname {
			"-length_greater_than" {
				set length_threshold  $results($argname)
			}
			"-lib_cell_pattern" {
				set lib_cell_pattern  $results($argname)
			}
			"verbose" {
				set verbose_mode      1
			}
			"-debug" {
				set debug_mode        1
			}
			"trace_disabled_arcs" {
				set __trace_all_arcs  1
			}
			"-debug_level" {
				set debug_level       $results($argname)
			}
			default {
				puts "** ERROR: unknown arguments - $argname"
				return 0
			}
		}
	}
	
	unset -nocomplain IS_DLY DLY_CELLS
	if {$lib_cell_pattern != ""} {
		set target_lib_cells      [get_lib_cells -quiet -regexp $lib_cell_pattern -filter "is_instantiated == true"]
		if {$debug_mode} { echo "DBG: [sizeof $target_lib_cells] used lib cells with pattern {$lib_cell_pattern}"}
		set USED_DLY_LIB_CELLS    [lsort -unique [get_attribute $target_lib_cells base_name]]
	} else {
		set USED_DLY_LIB_CELLS    [lsort -unique [get_attribute [get_lib_cells -quiet -regexp {.*/((IP|NE|GP)?DLY\\d|.*_DEL_).*} -filter "is_instantiated ==true"] base_name]]
	}
	foreach ref_name $USED_DLY_LIB_CELLS {
		set IS_DLY($ref_name)     1
		append_to_collection DLY_CELLS [get_cells -quiet -of [get_lib_cells -quiet */${ref_name}]]
	}
	if {![info exist DLY_CELLS] || $DLY_CELLS == ""} {
		echo "** SEC_INFO: design doesn't have any used lib cells with pattern $lib_cell_pattern"
		return
	}
	echo "**SEC_INFO: examining [sizeof $DLY_CELLS] DLY cells for consecutive chain > $length_threshold"
	echo "**SEC_INFO: finding foremost DLY cells..."

	;#---------------------------------------------------------------------------------------------------
	;# find head cells
	;#---------------------------------------------------------------------------------------------------
	remove_user_attribute -quiet is_visited -class cell $DLY_CELLS
	define_user_attribute -quiet is_visited -class cell -type boolean
	set_user_attribute -class cell -quiet $DLY_CELLS is_visited "false"
	unset -nocomplain temp_head_cells head_dly_cells
	foreach_in_collection cell $DLY_CELLS {
		if {[get_attribute -quiet $cell is_visited] == "true"} {
			continue
		}
		set headcell   [find_foremost_dly_cell_to $cell]
		if {$headcell != ""} {
			append_to_collection temp_head_cells $headcell
		}
	}
	append_to_collection -unique head_dly_cells $temp_head_cells
	echo "     [sizeof $head_dly_cells] head cells found"
	set_user_attribute -class cell -quiet $DLY_CELLS is_visited "false"
	
	;#---------------------------------------------------------------------------------------------------
	;# trace from head cells and report if met criteria 
	;#---------------------------------------------------------------------------------------------------
	foreach_in_collection headcell $head_dly_cells {
		if {$debug_mode} { echo "** SEC_INFO: tracing forward from [get_object_name $headcell]" }
		set chain_stack [list ]
		trace_dly_chain_from $headcell $chain_stack
	}
	
	echo "** SEC_INFO: found $num_detected_chain DLY cell chains whose length is greater than $length_threshold"
	echo "             $num_short_chain chains (including single cell) are shorter than the threshold"
	echo "** SEC_INFO: maximum chain length found = $max_chain_length"
}

;#---------------------------------------------------------------------------------------------------
;# find foremost delay cell to certain delay cell
;#---------------------------------------------------------------------------------------------------
proc find_foremost_dly_cell_to { cell } {
	global __trace_all_arcs debug_mode IS_DLY

	if {[get_attribute -quiet $cell is_visited] == "true"} {
		return ""
	}
	set_user_attribute -class cell -quiet $cell is_visited "true"
	set ipin      [get_pins -quiet -of $cell -filter "direction == in"]
	if {$__trace_all_arcs} {
		set driver_pin [filter_collection [all_fanin -quiet -flat -pin_level 1 -to $ipin -trace_arc all] "direction != in"]
	} else {
		set driver_pin [filter_collection [all_fanin -quiet -flat -pin_level 1 -to $ipin] "direction != in"]
	}
	if {$driver_pin == ""} {
		return $cell  ;# dangling
	}
	set driver_cell    [get_cells -quiet -of $driver_pin]
	set driver_ref     [get_attr -quiet $driver_cell ref_name]
	if {[info exist IS_DLY($driver_ref)]} {
		if {$debug_mode} {
			echo "DBG_TRACE: [get_object_name $cell] ([get_attr -quiet $cell ref_name])"
			echo "        <- [get_object_name $driver_cell] ($driver_ref)"
		}
	return [find_foremost_dly_cell_to $driver_cell]
	} else {
		return $cell
	}
}


;#---------------------------------------------------------------------------------------------------
;# trace backward and print delay cell chain
;#---------------------------------------------------------------------------------------------------
proc trace_dly_chain_from { cell chain_stack } {
	global length_threshold num_short_chain num_detected_chain max_chain_length __trace_all_arcs IS_DLY

	lappend chain_stack $cell ;# push stack
	set opin      [get_pins -quiet -of $cell -filter "direction == out"]
	if {$__trace_all_arcs} {
		set load_pins [filter_collection [all_fanout -quiet -flat -pin_level 1 -from $opin -trace_arc all] "direction != out"]
	} else {
		set load_pins [filter_collection [all_fanout -quiet -flat -pin_level 1 -from $opin] "direction != out"]
	}
	foreach_in_collection load_pin $load_pins {
		set load_cell [get_cells -quiet -of $load_pin]
		set load_ref  [get_attr -quiet $load_cell ref_name]
		if {[info exist IS_DLY($load_ref)]} {
			trace_dly_chain_from $load_cell $chain_stack
			set chain_stack   [lrange $chain_stack 0 [expr [llength $chain_stack] - 2]]  ;# pop stack
		} else {
			set chain_length  [llength $chain_stack]
			if {$chain_length > $length_threshold} {
				incr num_detected_chain
				print_chain_stack $chain_stack
				if {$chain_length > $max_chain_length} {
					set max_chain_length $chain_length
				}
			} else {
				incr num_short_chain
			}
		return
		}
	}
}

proc print_chain_stack {chain} {
	global num_detected_chain length_threshold
	echo ""
	echo "**** DLY cell chain # $num_detected_chain (length = [llength $chain])"
	set line   [string repeat "=" 100]
	
	for {set i 0} {$i < [llength $chain]} { incr i } {
		set obj				[lindex $chain $i]
		set obj_name		[get_object_name $obj]
		set obj_name_outpin [get_object_name [get_pins -of [get_cells $obj_name] -filter "direction==out"]]
		set ref_name		[get_attr -quiet $obj ref_name]
		set check_flag		[expr [expr $i + 2] % ${length_threshold}]
		if { $check_flag == "0"} {
			echo [format "%4d. %-100s (%-15s) <== check point" [expr $i+1] $obj_name_outpin $ref_name]
		} else {
			echo [format "%4d. %-100s (%-15s)" [expr $i+1] $obj_name_outpin $ref_name]
		}
	}
	echo ""
}

define_proc_attributes find_dly_cell_chain \
	-info "find DLY cell chian whose length is greater than the threshold" \
	-define_args {
		{-length_greater_than "DLY cell chian length greater than" "<level>" int optional}
		{-verbose             "verbose message" "" boolean optional}
		{-trace_disabled_arcs "trace disabled arcs also" "" boolean optional}
		{-lib_cell_pattern    "regexp pattern of delay cells to be used for 'get_lib_cells -regexp' command (e.g. .*/DLY\\\\d.*)" "<pattern>" string optional}
		{-debug               "turn on debug mode" "" boolean {optional hidden}}
		{-debug_level         "debug message verbosity level" "<1~5>" int {optional hidden}}
	}
