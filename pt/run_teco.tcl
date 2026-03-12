################################################################################
# File Name     : run_teco.tcl
# Author        : DT-PI
# Creation Date : 2024-05-14
# Last Modified : 2025-04-17
# Version       : v1.2
# Location      : ${STA_SCRIPt_DIR}/run_teco.tcl
#-------------------------------------------------------------------------------
# Description   :
# 	This file is an example file. This header is used to track the version and
# 	change history of the file.
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-05-14] : iskim1001
# 		- Initial Version Release
# 	v0.2 [2024-06-26] : iskim1001
#       - Add Create ECO_DELIVERY_DIR part
# 	v0.3 [2024-07-05] : iskim1001
# 		- Modify :
# 			Before : source  ${STA_SCRIPT_DIR}/dmsa_report.tcl
# 			After  : source ${COMMON_TCL_PT}/dmsa_report.tcl
# 		- Modify : physical_mode append
# 	v0.4 [2024-07-09] : iskim1001
# 		- Add variable dmsa_save & whatif
# 	v0.5 [2024-07-29] : iskim1001
# 		- PREFIX Modify :
#		- Bef set PREFIX "${ECO_NUM_N}_${today}_${recipe_type}_"
#		- Aft set PREFIX "${ECO_NUM_N}_${today}_[lindex [ split $recipe_type "-" ] 0]"
# 	v0.5 [2024-08-02] : iskim1001
# 		- Add ECO_TOUCH_INST__LIB_CELL_LIST if statement
# 	v0.6 [2024-08-13] : iskim1001
# 		- Add ${STA_SCRIPT_DIR}/run_teco_restrict.tcl
# 	v0.7 [2025-02-25] : sjlee
# 		- apply_PD_dont_touch.tcl
# 	V0.8 [2025-02-28] : iskim1001
# 		- Add other_opt_array
# 	v0.9 [2025-03-14] : sjlee
# 		- check_eco added
# 	v1.0 [2025-03-21] :sjlee
# 		- exclude_clock_ports when ignore_boundary_dmsa
# 	v1.1 [2025-03-26] : jaeeun1115
# 		- setting CUR_JOB to dmsa_eco in slave session
# 	v1.2 [2025-03-26] : jaeeun1115
# 		- setting lef, def only for netlist sub design
# 	v1.3 [2025-06-12] : sjlee
# 	    - ignore_boundary_hold added
#-------------------------------------------------------------------------------
# Useage        :
#		Usage...
#################################################################################
suppress_message CMD-041

#==============================================================================
# DT-PI_Add : source utility
#==============================================================================
source ${COMMON_TCL_PROCS}/ST_trace_v2.tbc
source ${COMMON_TCL_PT_PROC}/proc_banner.tcl

;#------------------------------------------------------------------------------
;# Check required path variables
;#------------------------------------------------------------------------------
if { ![info exist env(STA_SCRIPT_DIR)] } {
    echo "** SEC_ERROR: required shell env variable not defined - STA_SCRIPT_DIR"
    return 0
} else {
    set STA_SCRIPT_DIR 	$env(STA_SCRIPT_DIR)
}

if { ![info exist env(UTIL_SCRIPT_DIR)] } {
    echo "** SEC_ERROR: required shell env variable not defined - UTIL_SCRIPT_DIR"
    return 0
} else {
    set UTIL_SCRIPT_DIR 		$env(UTIL_SCRIPT_DIR)
    set SEC_SNPS_TCL_UTIL_DIR	    $UTIL_SCRIPT_DIR
    setenv SEC_SNPS_TCL_UTIL_DIR	$UTIL_SCRIPT_DIR
}
set auto_path [linsert $auto_path 0 $UTIL_SCRIPT_DIR]


;#------------------------------------------------------------------------------
;# Required utility procedures
;#------------------------------------------------------------------------------
set req_files   [list \
    ${UTIL_SCRIPT_DIR}/util_procs.{tbc,tcl}              \
    ${UTIL_SCRIPT_DIR}/sec_make_list_from_file.{tbc,tcl} \
    ${UTIL_SCRIPT_DIR}/sec_infer_tech_by_lib.{tbc,tcl}   \
    ]
foreach pattern $req_files {
    set fname 	[lindex [glob -nocomplain $pattern] 0]
    if {![file exist $fname] || ![file readable $fname]} {
        echo "** SEC_ERROR: required file not found or not accessable - $fname"
        exit
    }
    source $fname
}
regexp {[A-Z]-([0-9]+\.[0-9]+)} $sh_product_version match pt_version


;#------------------------------------------------------------------------------
;# ECO run configuration
;#------------------------------------------------------------------------------
source_wrap -echo ${COMMON_TCL_PT}/config_teco.tcl

# 1B_STA
if {[info exists STA_USER] && ${STA_USER} == "PD" } {
    set fname   ${RUN_DIR}/../../../config_teco_prj.tcl
} else {
    set fname   ${RUN_DIR}/../../config_teco_prj.tcl
}

if {![file exist $fname]} {
    echo "** SEC_ERROR: required file not found - $fname"
    exit -1
} else {
    source_wrap -echo $fname
}


;#------------------------------------------------------------------------------
;# To confine the timing ECO to specific points ( DRC )
;#------------------------------------------------------------------------------
unset -nocomplain TARGET_POINTS_DRC_LIST
if {![file exist ${TARGET_POINT_DRC_FILE}]} {
	puts "Error_ADF: No \"${TARGET_POINT_DRC_FILE}\" list file."
} else {
	set fname 	[lindex [glob ${UTIL_SCRIPT_DIR}/sec_make_list_from_file.{tbc,tcl}] 0]
	if {![file exist $fname]} {
	    echo "** SEC_ERROR: required file not found - $fname"
	    exit -1
	} else {
	    source $fname
	}

	set TARGET_POINTS_DRC_LIST    [sec_make_list_from_file $TARGET_POINT_DRC_FILE]
	echo "** SEC_INFO: the ECO will consider [llength $TARGET_POINTS_DRC_LIST] specified endpoints"
}

;#------------------------------------------------------------------------------
;# To confine the timing ECO to specific endpoints ( SETUP )
;#------------------------------------------------------------------------------
unset -nocomplain TARGET_ENDPOINTS_SETUP_LIST
if {![file exist ${TARGET_ENDPOINT_SETUP_FILE}]} {
	puts "Error_ADF: No \"${TARGET_ENDPOINT_SETUP_FILE}\" list file."
} else {
	set fname 	[lindex [glob ${UTIL_SCRIPT_DIR}/sec_make_list_from_file.{tbc,tcl}] 0]
	if {![file exist $fname]} {
	    echo "** SEC_ERROR: required file not found - $fname"
	    exit -1
	} else {
	    source $fname
	}
	set TARGET_ENDPOINTS_SETUP_LIST 	[sec_make_list_from_file $TARGET_ENDPOINT_SETUP_FILE]
	echo "** SEC_INFO: the ECO will consider [llength $TARGET_ENDPOINTS_SETUP_LIST] specified endpoints"
}

;#------------------------------------------------------------------------------
;# To confine the timing ECO to specific endpoints ( HOLD )
;#------------------------------------------------------------------------------
unset -nocomplain TARGET_ENDPOINTS_HOLD_LIST
if {![file exist ${TARGET_ENDPOINT_HOLD_FILE}]} {
	puts "Error_ADF: No \"${TARGET_ENDPOINT_HOLD_FILE}\" list file."
} else {
	set fname 	[lindex [glob ${UTIL_SCRIPT_DIR}/sec_make_list_from_file.{tbc,tcl}] 0]
	if {![file exist $fname]} {
	    echo "** SEC_ERROR: required file not found - $fname"
	    exit -1
	} else {
	    source $fname
	}

	set TARGET_ENDPOINTS_HOLD_LIST 	[sec_make_list_from_file $TARGET_ENDPOINT_HOLD_FILE]
	echo "** SEC_INFO: the ECO will consider [llength $TARGET_ENDPOINTS_HOLD_LIST] specified endpoints"
}

;#------------------------------------------------------------------------------
;# build target sessions in ./session_list.tcl
;#------------------------------------------------------------------------------
if {![info exist SESSION_LIST_FILE] || $SESSION_LIST_FILE == "" || ![file readable $SESSION_LIST_FILE]} {
    echo "** SEC_ERROR: session list file not found or unreadable - ${SESSION_LIST_FILE}"
    exit -1
}

set TARGET_SESSIONS 	[sec_make_list_from_file $SESSION_LIST_FILE]
echo "** SEC_INFO: make images based on the session list file - ${SESSION_LIST_FILE}"
echo "             [llength $TARGET_SESSIONS] session"
set idx 1
foreach n $TARGET_SESSIONS {
    echo "             #[format {%02d} $idx]: $n"
    incr idx
}

foreach session ${TARGET_SESSIONS} {
    if {![file readable $session] || ![file isdirectory $session]} {
        echo "** SEC_ERROR: session directory does not exist or unreadable - $session"
        exit;
    }
}


;#------------------------------------------------------------------------------
;# Prepare hosts
;# you can set license limit lesser than the # of scenarios at the cost of extra runtime
;#------------------------------------------------------------------------------
set num_sessions    [llength $TARGET_SESSIONS]
set max_licenses	$num_sessions

set_app_var  multi_scenario_license_mode        core
set_app_var  report_default_significant_digits  4


;#------------------------------------------------------------------------------
;# use 1 cpu for slave sessions : "-n 1"
;#------------------------------------------------------------------------------
;# Distributed host setting ( User setting )
;# Example :
;#    Total Scenario  : 20 ea
;#    Eacho Host      : 5 assigned to each host
;#set_host_options -name DMSA_MASTER   -num_processes 6 -max_cores 1 -submit_command "/usr/bin/ssh" dev01 (Server assigned to Project)
;#set_host_options -name DMSA_SLAVE1   -num_processes 5 -max_cores 1 -submit_command "/usr/bin/ssh" dev02 (Server assigned to Project)
;#set_host_options -name DMSA_SLAVE2   -num_processes 5 -max_cores 1 -submit_command "/usr/bin/ssh" dev03 (Server assigned to Project)
;#set_host_options -name DMSA_SLAVE3   -num_processes 5 -max_cores 1 -submit_command "/usr/bin/ssh" dev04 (Server assigned to Project)
set_host_options  -name DMSA_ECO_OPT \
		  -num_processes $num_sessions \
		  -max_cores $SLAVE_NTHREAD

start_hosts
report_host_usage


;#------------------------------------------------------------------------------
;# Build-up DMSA sessions
;#------------------------------------------------------------------------------
set id  0
foreach session_dir $TARGET_SESSIONS {
    set scn_name [regsub {.*session.} $session_dir [] ]
    echo "** SEC_INFO: creating image using - $session_dir"
    echo "             inferred scenario name = '$scn_name'"
    create_scenario -name $scn_name -image ${session_dir}
    incr id
}
current_session -all
current_scenario -all


;#------------------------------------------------------------------------------
;# Setting for Physical-aware ECO
;#------------------------------------------------------------------------------
source -e -v ${COMMON_TCL_PT}/config_teco_physical.tcl


;#------------------------------------------------------------------------------
;# Slave settings for physical-aware ECO
;#------------------------------------------------------------------------------
set_distributed_variables 	[list     \
    LEF_PATH                          \
    DEF_PATH                          \
    LEF_FILES                         \
    DEF_FILE                          \
    ECO_MODE                          \
    ECO_WORK_DIR                      \
    UTIL_SCRIPT_DIR                   \
    STA_SCRIPT_DIR                    \
    multi_scenario_working_directory  \
    eco_net_name_prefix               \
    eco_instance_name_prefix          \
    VTH_PRIORITY                      \
    PBA_MODE                          \
    ECO_DONT_USE_LIB_CELL_LIST        \
    ECO_DONT_TOUCH_LIB_CELL_LIST      \
	ECO_TOUCH_INST__LIB_CELL_LIST     \
	ECO_USER_DONT_TOUCH_TCL			  \
    ECO_NUM_N                         \
	METAL_ECO_FILLERS				  \
	METAL_ECO_FIX_BUFFERS			  \
	GROUP_PATH                        \
	in_site_rows                      \
	ignore_boundary_dmsa              \
    ignore_boundary_hold              \
    CUR_JOB ]



;#------------------------------------------------------------------------------
;# remote_execute part (Slave settings for physical-aware ECO)
;#------------------------------------------------------------------------------
remote_execute {

	#==============================================================================
	# DT-PI_Add : source utility
	#==============================================================================
	source ${COMMON_TCL_PROCS}/ST_trace_v2.tbc

    source -e ${UTIL_SCRIPT_DIR}/sec_report_cell_usage.tbc

	set_app_var eco_insert_buffer_search_distance_in_site_rows $in_site_rows

    ;# to size cells only with identical pin names
    set eco_strict_pin_name_equivalence                   "true"

    if {$PBA_MODE == "exhaustive"} {
        set_app_var pba_exhaustive_endpoint_path_limit      500
    }

    ;# utility procedures
    proc set_pt_dont_use {lib_cell} {
        set_user_attribute -class lib_cell [get_lib_cell -quiet $lib_cell] pt_dont_use true
        set_user_attribute -class lib_cell [get_lib_cell -quiet $lib_cell] dont_use true
    }

    proc unset_pt_dont_use {lib_cell} {
        set_user_attribute -class lib_cell [get_lib_cell -quiet $lib_cell] pt_dont_use false
        set_user_attribute -class lib_cell [get_lib_cell -quiet $lib_cell] dont_use false
    }


    proc get_elapsed_time_string {start_time {end_time 0.0}} {
        if {$end_time == 0.0} {
            set end_time [clock seconds]
        }
        set secs [expr ${end_time} - ${start_time}]
        if {$secs >= 86400 } {
            return [clock format [expr [clock scan 2000-12-31] + $secs] -format "%d days %H hours %M mins %S secs"]
        } elseif {$secs >= 3600} {
            return [clock format [expr [clock scan 2000-12-31] + $secs] -format "%H hours %M mins %S secs"]
        } elseif {$secs >= 60} {
            return [clock format [expr [clock scan 2000-12-31] + $secs] -format "%M mins %S secs"]
        } else {
            return [clock format [expr [clock scan 2000-12-31] + $secs] -format "%S secs"]
        }
    }
    ;# settings for freeze silicon eco
	if { [regexp -nocase "freeze" $ECO_MODE] } {
		foreach MECO_VAR { METAL_ECO_FILLERS METAL_ECO_FIX_BUFFERS } {
			foreach pat [set $MECO_VAR] {
				if { [llength $pat] > 0 } {
					set_dont_use   [get_lib_cells ${pat}] false
					set_dont_touch [get_lib_cells ${pat}] false
				}
			}
		}

        set eco_report_unfixed_reason_max_endpoints         5000
		set_eco_options \
			-physical_lib_path ${LEF_FILES} \
			-physical_design_path ${DEF_FILE} \
			-programmable_spare_cell_names ${METAL_ECO_FILLERS} \
			-log_file ${multi_scenario_working_directory}/lef_def.log

			check_eco
    ;# settings for physical-aware ECO
    } elseif { [regexp -nocase "physical" $ECO_MODE] } {
        set eco_allow_filler_cells_as_open_sites            "true"
        set eco_report_unfixed_reason_max_endpoints         5000
        set_eco_options \
            -physical_lib_path ${LEF_FILES} \
            -physical_design_path ${DEF_FILE} \
            -log_file ${multi_scenario_working_directory}/lef_def.log

			check_eco
    ;# settings for only logical ECO
    } elseif { [regexp -nocase "logical" $ECO_MODE] } {
		if { $HIER_DESIGN != "NONE" } {
			source -e -v ${STA_SCRIPT_DIR}/sub_hier_inst_info.tcl
			foreach { blk VALUE } [array get FULL_HIER] {
				set value [regsub -all "{|}" $VALUE ""]
				set ${blk}_mim_inst ""

				foreach {inst_name x_loc y_loc rotation flip} $value {
					set ${blk}_mim_inst [lappend ${blk}_mim_inst $inst_name]
				}
				if { [llength [set ${blk}_mim_inst]] > 1 } {
					puts "# ${blk}_mim_inst"
					set cmd "set_eco_options -mim_group { [set ${blk}_mim_inst] }"
					puts "$cmd" ; eval $cmd
					puts ""
				}
			}
		}
	}

    ;# let dont_use specific cells during the ECO
    ;# usage example:
    ;#   remote_execute { set_pt_dont_use { ${lib_name}/BUF_X1M* ${lib_name}/BUF_X2M* } }
    ;#
    define_user_attribute "pt_dont_use" -quiet -type boolean -class lib_cell
    if {[info exist ECO_DONT_USE_LIB_CELL_LIST] && $ECO_DONT_USE_LIB_CELL_LIST != ""} {
        foreach pattern $ECO_DONT_USE_LIB_CELL_LIST {
            if {[set target_lc [get_lib_cells -quiet $pattern]] != ""} {
                echo "** SEC_INFO: set dont_use [sizeof $target_lc] lib cells matching pattern '$pattern'"
                set_pt_dont_use ${pattern}
            } else {
                echo "** SEC_WARN: no lib cell to set dont_use found by pattern '$pattern'"
            }
        }
    }

    if {[info exist ECO_DONT_TOUCH_LIB_CELL_LIST] && $ECO_DONT_TOUCH_LIB_CELL_LIST != ""} {
        foreach pattern $ECO_DONT_TOUCH_LIB_CELL_LIST {
            if {[set target_lc [get_lib_cells -quiet $pattern]] != ""} {
                echo "** SEC_INFO: set dont_touch [sizeof $target_lc] lib cells matching pattern '$pattern'"
                set_user_attribute -class lib_cell $target_lc dont_touch true
                #DM_ORG set_pt_dont_use ${pattern}
				set_dont_touch $target_lc true
            } else {
                echo "** SEC_WARN: no lib cell to set dont_touch found by pattern '$pattern'"
            }
        }
    }

	if {![file exist ${ECO_USER_DONT_TOUCH_TCL}]} {
		puts "Error_ADF: No \"${ECO_USER_DONT_TOUCH_TCL}\" tcl file."
	} else {
		source_wrap -e -v $ECO_USER_DONT_TOUCH_TCL
	}

    set DONT_TOUCH_APPLY_FILE  "${COMMON_TCL_PT}/apply_PD_dont_touch.tcl"
	if {![file exist ${DONT_TOUCH_APPLY_FILE}]} {
		puts "Error_ADF: No \"${DONT_TOUCH_APPLY_FILE}\" tcl file."
	} else {
	    source_wrap -e -v $DONT_TOUCH_APPLY_FILE
    }

#DM_ORG  ;#--------------------------------------------------------------------------
#DM_ORG  ;# to restrict cell sizing within a same Vth in setup/hold ECO
#DM_ORG  ;#--------------------------------------------------------------------------
#DM_ORG  define_user_attribute "eco_vth_group" -type string -class lib_cell
#DM_ORG  foreach vt_postfix ${VTH_PRIORITY} {
#DM_ORG    set target_lib_cells        [get_lib_cells -quiet */*${vt_postfix}]
#DM_ORG    if {$target_lib_cells != ""} {
#DM_ORG      set_user_attribute -quiet -class lib_cell $target_lib_cells "eco_vth_group" ${vt_postfix}
#DM_ORG    }
#DM_ORG  }
#DM_ORG  set_app_var eco_alternative_cell_attribute_restrictions       {eco_vth_group}

    ;#--------------------------------------------------------------------------
    ;# to let fix_eco_power based on user-defined power attribute
    ;#--------------------------------------------------------------------------
    define_user_attribute "pwr_cost" -type float -class lib_cell
    ;# assign cell area as user-defined power attribute
    foreach_in_collection lc [get_lib_cells -quiet -regexp .*(base_|flk|udl|hdl).*/.*] {
        set_user_attribute -class lib_cell $lc "pwr_cost" [get_attribute -quiet $lc area]
    }

    ;# assume less power for flat-fin cell, if there is any
    foreach_in_collection lc [get_lib_cells -quiet -regexp .*(base_|flk|udl|hdl).*(flat|f2f).*/.*] {
        set_user_attribute -class lib_cell $lc "pwr_cost" [expr [get_attribute -quiet $lc area] * 0.9]
    }

	source ${STA_SCRIPT_DIR}/run_teco_restrict.tcl

	# Boundary Timing is ignored when proceeding with 1B-STA.
	if { [info exists ignore_boundary_dmsa] && $ignore_boundary_dmsa } {
	puts "Information_ADF: Boundary Timing is ignored when proceeding with 1B-STA."
	puts "Warning_ADF: set_false_path is enabled for Boundary Timing."
	puts "Warning_ADF: ( in2reg, reg2out, in2out)"
	puts "Warning_ADF: Used command : set_false_path -from \[all_inputs -exclude_clock_ports\]"
	puts "Warning_ADF: Used command : set_false_path -to   \[all_outputs\]"
	puts "Warning_ADF: Used command : set_false_path -from \[all_inputs -exclude_clock_ports\] -to \[all_outputs\]"
	puts ""
	set_false_path -from [all_inputs -exclude_clock_ports ]                   ;# in2reg
	set_false_path -to   [all_outputs]                   					  ;# reg2out
	set_false_path -from [all_inputs -exclude_clock_ports ] -to [all_outputs] ;# in2out
	}

    # Redmine :  [REQUEST][PT_STA] DMSA option
	if { [info exists ignore_boundary_hold] && $ignore_boundary_hold } {
	puts "Information_ADF: Boundary Timing is ignored when proceeding with 1B-STA."
	puts "Warning_ADF: set_false_path is enabled for Boundary Timing."
	puts "Warning_ADF: ( in2reg, reg2out, in2out)"
	puts "Warning_ADF: Used command : set_false_path -hold -from \[all_inputs -exclude_clock_ports\]"
	puts "Warning_ADF: Used command : set_false_path -hold -to   \[all_outputs\]"
	puts "Warning_ADF: Used command : set_false_path -hold -from \[all_inputs -exclude_clock_ports\] -to \[all_outputs\]"
	puts ""
	set_false_path -hold -from [all_inputs -exclude_clock_ports ]                   ;# in2reg
	set_false_path -hold -to   [all_outputs]                   			  		    ;# reg2out
	set_false_path -hold -from [all_inputs -exclude_clock_ports ] -to [all_outputs] ;# in2out
	}

    # Redmine :  HM_Auto_Sensor_SoC_1M Task* #4957 [REQ] PI-sophia script #73
	if {[info exist ECO_TOUCH_INST__LIB_CELL_LIST ] && $ECO_TOUCH_INST__LIB_CELL_LIST != "" } {
		foreach pattern $ECO_TOUCH_INST__LIB_CELL_LIST {
			set full_name 	[lindex [split $pattern "," ] 0 ]
			set ref_name 	[lindex [split $pattern "," ] 1 ]
			if {[set cells    [get_cells -quiet -hier * -filter "full_name =~ $full_name && ref_name =~ $ref_name" ]] != "" } {
				echo "** SEC_INFO: setting dont_touch for [sizeof $cells] instances with pattern '$pattern' : full_name -> $full_name : ref_name -> $ref_name "
				set_dont_touch $cells false
			} else {
				echo "** SEC_INFO: setting dont_touch for [sizeof $cells] instances with pattern '$pattern' : full_name -> $full_name : ref_name -> $ref_name "
			}
		}
	}


}


;#------------------------------------------------------------------------------
;# stop if interactive mode
;#------------------------------------------------------------------------------
if {[info exist RESTORE_SESSION_ONLY] && $RESTORE_SESSION_ONLY} {
	if {[info exist whatif ] && $whatif } {
		set stage whatif
		remote_execute { set stage whatif }
	}
  return
}

;#------------------------------------------------------------------------------
;# Create eco_session
;#------------------------------------------------------------------------------
if {[info exist GEN_ECO_SESSION] && $GEN_ECO_SESSION} {
	source ${COMMON_TCL_PT}/output_write_eco_session.tcl
}

;#------------------------------------------------------------------------------
;# Timing reports before ECO
;#------------------------------------------------------------------------------
set M_DIR eco_rpt
file mkdir ${M_DIR}

set stage 0_base
remote_execute { set stage 0_base }
source ${COMMON_TCL_PT}/dmsa_report.tcl

if {[info exist GEN_ECO_SESSION] && $GEN_ECO_SESSION} {
	exit
}

;#------------------------------------------------------------------------------
;# setup & Hold vio check
;#------------------------------------------------------------------------------
set base_gt_temp "./eco_rpt/0_base_GT"
redirect  $base_gt_temp {  report_global_timing -pba_mode $PBA_MODE }
set OpenFILE [open $base_gt_temp "r"]
while {[gets $OpenFILE line ] >= 0 } {
	if {[regexp "No setup violations" $line]  } {
		puts "Since there is no setup violation, setup\* is excluded from targets."
		puts "    |- Before targets : $targets"
		set targets [string trim [regsub -all {setup\S*} $targets  ""]]
		puts "    |- After  targets : $targets"

		file mkdir eco_list
		echo "#There is no setup violation"                                           > eco_list/${ECO_NUM_N}.no_setup_violation.tcl
		echo "#Since there is no setup violation, setup\* is excluded from targets." >> eco_list/${ECO_NUM_N}.no_setup_violation.tcl

	} elseif {[regexp "No hold violations" $line]   } {
		puts "Since there is no hold violation, hold\* is excluded from targets."
		puts "    |- Before targets : $targets"
		set targets [string trim [regsub -all {hold\S*} $targets  ""]]
		puts "    |- After  targets : $targets"

		file mkdir eco_list
		echo "#There is no hold violation"                                          > eco_list/${ECO_NUM_N}.no_hold_violation.tcl
		echo "#Since there is no hold violation, hold\* is excluded from targets." >> eco_list/${ECO_NUM_N}.no_hold_violation.tcl
	}
}
close $OpenFILE


#############################################################
#run_teco.tcl
#############################################################
set recipe_num 1
set st  [clock seconds]

foreach recipe_target $targets {
	set cmd_line ""
	set recipe_type      [lindex [ split $recipe_target "/" ] 0]
	set recipe_method    [lindex [ split $recipe_target "/" ] 1]
	set recipe_restrict  [lindex [ split $recipe_target "/" ] 2]
	set recipe_etc       [lindex [ split $recipe_target "/" ] 3]

	;#---------------------------------------------------------
	;# Special recipe management
	;#---------------------------------------------------------
	;# mttv-merge
	if { $recipe_type == "mttv-merge" } {
		puts "###############################################################################"
		puts "# Note (temp...)                                                               "
		puts "#------------------------------------------------------------------------------"
		puts "#The mttv-merge step does not work with dmsa_eco.                              "
		puts "#dmsa_eco is unconditionally executed as logical_only.                         "
		puts "###############################################################################"
		continue
	}

	;# *-slvt
	if { [string match "*-slvt" $recipe_type] } {
		remote_execute -v {	unset_pt_dont_use "*base*/*TSL*"  }
		set slvt_use_flag 1
	} else {
		if { [info exists slvt_use_flag ] &&  $slvt_use_flag == "1" } {
			remote_execute -v {	  set_pt_dont_use "*base*/*TSL*"  }
			set slvt_use_flag 0
		}
	}

	;#---------------------------------------------------------
	;# Init cmd_line setting
	;#---------------------------------------------------------
	set cmd_line $default_cmd_array($recipe_type)

	;#---------------------------------------------------------
	;# -method append
	;#---------------------------------------------------------
	if { $recipe_method != "" } {
		set method_append ""
		# Concatenate methods
		foreach my_method [split $recipe_method ","] {
			set method_append [ concat $method_append $method_array($my_method) ]
		}
		append cmd_line " -method {$method_append}"
	}

	;#---------------------------------------------------------
	;# other_opt array
	;#---------------------------------------------------------
	if { $recipe_etc != "" } {
		append cmd_line " $other_opt_array($recipe_etc)"
	}

	;#---------------------------------------------------------
	;# -physical_mode append
	;#---------------------------------------------------------
    ;# -physical_mode ( open_site || occupied_site )
    if { [string match -nocase "physical*" $ECO_MODE] && ![string match "power*" $recipe_type] } {
		append cmd_line 	" -physical_mode ${PHY_MODE}"
	}

    	#FIXED BY TK  because fix_eco_drc command doesnt have -group option by 0709
    if {[info exist GROUP_PATH] && $GROUP_PATH != "" } {
        if { ![string match  "fix_eco_drc*"                $cmd_line] }  {
		append cmd_line " -group \$GROUP_PATH"
		}
    }

	;#---------------------------------------------------------
	;# -buffer_list append
	;#---------------------------------------------------------
	;# -buffer_list
	      if { [string match -nocase "freeze*"              $ECO_MODE] } { append cmd_line " -buffer_list \$METAL_ECO_FIX_BUFFERS "
	} elseif { [string match  "fix_eco_drc*"                $cmd_line] } { append cmd_line " -buffer_list \$DRC_FIX_BUFFERS       "
	} elseif { [string match  "fix_eco_timing -type setup*" $cmd_line] } { append cmd_line " -buffer_list \$SETUP_FIX_BUFFERS     "
	} elseif { [string match  "fix_eco_timing -type hold*"  $cmd_line] } { append cmd_line " -buffer_list \$HOLD_FIX_BUFFERS      "
	} else   { puts "-buffer_list setting part check plz..."
	}

	;#---------------------------------------------------------
	;# -to append
	;#---------------------------------------------------------
	if { [string match "*-type setup*" $cmd_line ] } {
		if { [info exists TARGET_ENDPOINTS_SETUP_LIST] && ${TARGET_ENDPOINTS_SETUP_LIST} != "" } { append cmd_line " -to \$TARGET_ENDPOINTS_SETUP_LIST" }
	} elseif { [string match "*-type hold*" $cmd_line ] } {
		if { [info exists TARGET_ENDPOINTS_HOLD_LIST]  && ${TARGET_ENDPOINTS_HOLD_LIST}  != "" } { append cmd_line " -to \$TARGET_ENDPOINTS_HOLD_LIST" }
	} elseif { [string match "fix_eco_drc*" $cmd_line ] } {
		if { [info exists TARGET_POINTS_DRC_LIST]      && ${TARGET_POINTS_DRC_LIST}      != "" } { append cmd_line " \$TARGET_POINTS_DRC_LIST" }
	}

	;#---------------------------------------------------------
    ;# -slack_lesser   append
    ;# -slack_greater  append
	;#---------------------------------------------------------
	if { [string match "*-type setup*" $cmd_line ] } {
        if { $slack_lesser(setup)  != 0.0  } { append cmd_line " -slack_lesser $slack_lesser(setup)"    }
        if { $slack_greater(setup) != -Inf } { append cmd_line " -slack_greater $slack_greater(setup)"  }
	} elseif { [string match "*-type hold*" $cmd_line ] } {
		if { $slack_lesser(hold) != 0.0   } { append cmd_line " -slack_lesser  $slack_lesser(hold)"  }
	    if { $slack_greater(hold) != -Inf } { append cmd_line " -slack_greater $slack_greater(hold)" }
	}

	;#---------------------------------------------------------
	;# recipe restrict_var setting
	;#---------------------------------------------------------
	;# Master : recipe_restrict
	if { $recipe_restrict == "" } {
		set restrict_var "-default"
	} else {
		foreach my_restrict [split $recipe_restrict ","] {
			if { [string match "R3" $my_restrict] } {
				append cmd_line " -cell_type clock_network"
				if { ![info exist restrict_var] } {
					set restrict_var "-default"
				}
			} else {
				;# Declaration of variable to set eco_alternative_cell_attribute_restrictions variable
				set restrict_var $restrict_var_array($my_restrict)
			}
		}
	}
	;# Slave : recipe_restrict
	set stage ${recipe_num}_${recipe_type}
	set_distributed_variables {stage recipe_type restrict_var}
	puts "Master Recipe : $recipe_target"
	remote_execute -v {
		puts $stage
		puts "Slave recipe : ${stage} "
		set_app_var eco_alternative_cell_attribute_restrictions $restrict_var
	}

	set PREFIX "${ECO_NUM_N}_${today}_[lindex [ split $recipe_type "-" ] 0]"
    set_app_var eco_instance_name_prefix  $PREFIX
    set_app_var eco_net_name_prefix		  $PREFIX

	;#---------------------------------------------------------
	;# Command Excute
	;#---------------------------------------------------------
	echo "** SEC_INFO: fixing $recipe_target timing with command:"
	echo "$cmd_line"
	redirect -tee ./${stage}.log {
		puts "##############################################"
		puts "# Recipe summary                              "
		puts "##############################################"
		puts "recipe_type     : $recipe_type"
		puts "recipe_method   : $recipe_method"
		puts "recipe_restrict : $recipe_restrict"
		puts "PREFIX          : $PREFIX"
		puts ""
		puts "command_use >>  $cmd_line "
		eval $cmd_line
	}
	source ${COMMON_TCL_PT}/dmsa_report.tcl
	echo "** SEC_INFO: took '[get_elapsed_time_string $st]' for $recipe_target timing fix"
	set_app_var   eco_alternative_cell_attribute_restrictions -default
	set_distributed_variables  eco_alternative_cell_attribute_restrictions
	puts ""
	puts ""

	incr recipe_num
}

;#------------------------------------------------------------------------------
;# Convert ECO file for Cadence EDI
;#   - identical file will be generate in each snapshot directory
;#------------------------------------------------------------------------------
set E_DIR eco_list
file mkdir ${E_DIR}
write_changes -format icctcl  -output ./${E_DIR}/${ECO_NUM_N}.final.icc.tcl
write_changes -format icc2tcl -output ./${E_DIR}/${ECO_NUM_N}.final.icc2.tcl
write_changes -format text    -output ./${E_DIR}/${ECO_NUM_N}.final.text.tcl
write_changes -format eco     -output ./${E_DIR}/${ECO_NUM_N}.final.eco.tcl


;#------------------------------------------------------------------------------
;# ECO_DELIVERY_DIR Create & Auto Deliv
;#------------------------------------------------------------------------------
if { [info exists STA_USER] && ${STA_USER} == "PD" } {
    file mkdir ${ECO_DELIVERY_DIR}
	set fnames "./${E_DIR}/${ECO_NUM_N}.final.icc2.tcl         \
                ./${E_DIR}/${ECO_NUM_N}.no_setup_violation.tcl \
                ./${E_DIR}/${ECO_NUM_N}.no_hold_violation.tcl  "

	foreach fname $fnames {
		if {[file exists $fname]} {
			echo "Found File : $fname "
			echo "File Copy ... "
			exec sh -c "umask 002 && mkdir -p ${ECO_DELIVERY_DIR}"
		    file copy -force $fname  ${ECO_DELIVERY_DIR}
		}
		echo ""
	}
    exec touch ${ECO_DELIVERY_DIR}/done.pt_eco
    exec touch ${PD_PASS_DIR}/${ECO_NUM}.dmsa_eco
}


set stage final
remote_execute {set stage final}
source ${COMMON_TCL_PT}/dmsa_report.tcl

#==============================================================================
# DT-PI_Add : Add Save session
#==============================================================================
if {[info exist dmsa_save ] && $dmsa_save } {
	puts "Information_ADF: After completing dmsa_eco, proceed with save_session.                        "
	puts "Information_ADF: Please use it for what_if purposes.                                          "
	puts "Information_ADF: Please make sure to erase it after use.                                      "
	puts "Information_ADF: The session takes up a lot of disk space, so be sure to delete it after use. "
	save_session dmsa_save_session
}




#exec touch DONE_PT_ECO
exec touch done.pt_eco

if {$QUIT_ON_FINISH} {
  exit
}
