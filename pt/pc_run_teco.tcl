################################################################################
# File Name     : pc_run_teco.tcl
# Author        : DT-PI
# Creation Date : 2024-08-28
# Last Modified : 2024-08-28
# Version       : v0.1
# Location      : ${STA_SCRIPT_DIR}/pc_run_teco.tcl
#-------------------------------------------------------------------------------
# Description   :
# 	This file is an example file. This header is used to track the version and
# 	change history of the file.
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-08-28] : jjh8744
# 		- Initial Version Release
# 	v0.2 [2025-06-12] : sjlee
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
# ${UTIL_SCRIPT_DIR}/util_procs.{tbc,tcl}              \ ;# Not supported in pc_shell
# ${UTIL_SCRIPT_DIR}/sec_infer_tech_by_lib.{tbc,tcl}   \ ;# Not supported in pc_shell

set req_files   [list \
    ${UTIL_SCRIPT_DIR}/sec_make_list_from_file.{tbc,tcl} \
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
#    set fname   ${RUN_DIR}/../../../config_teco_prj.tcl ;# Not support
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
;# Prepare hosts
;# you can set license limit lesser than the # of scenarios at the cost of extra runtime
;#------------------------------------------------------------------------------
set num_sessions    [llength $SCENARIOS]
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
set_host_options  -name PC_ECO_OPT \
		  -num_processes $num_sessions \
		  -max_cores $SLAVE_NTHREAD

# start_hosts
# report_host_usage


;#------------------------------------------------------------------------------
;# read eco_session
;#------------------------------------------------------------------------------
puts "Information_ADF: Read eco_session"
set cmd "read_eco_session ${PC_INPUT_DIR}/eco_session.dmsa"
puts "$cmd"
eval $cmd

read_physical_data -top_module_name ${DESIGN} \
				   -tech_lef ${TECH_LEF_FILE} \
                   -lef ${LEF_FILES} \
                   -def ${DEF_FILE}




;#------------------------------------------------------------------------------
;# remote_execute part (Slave settings for physical-aware ECO)
;#------------------------------------------------------------------------------
# source -e ${UTIL_SCRIPT_DIR}/sec_report_cell_usage.tbc ;# Not supported in pc_shell

set_app_var eco_insert_buffer_search_distance_in_site_rows $in_site_rows

;# to size cells only with identical pin names
set eco_strict_pin_name_equivalence                   "true"

if {$PBA_MODE == "exhaustive"} {
    set_app_var pba_exhaustive_endpoint_path_limit      500
}

;# settings for freeze silicon eco
if { [regexp -nocase "freeze" $ECO_MODE] } {
	foreach MECO_VAR { METAL_ECO_FILLERS METAL_ECO_FIX_BUFFERS } {
		foreach pat [set $MECO_VAR] {
			if { [llength $pat] > 0 } {
				set_dont_use_cell   ${pat} false
				set_dont_touch_cell ${pat} false
			}
		}
	}

    set eco_report_unfixed_reason_max_endpoints         5000
	set_eco_options \
		-physical_lib_path ${LEF_FILES} \
		-physical_design_path ${DEF_FILE} \
		-programmable_spare_cell_names ${METAL_ECO_FILLERS} \
		-log_file ${multi_scenario_working_directory}/lef_def.log

;# settings for physical-aware ECO
} elseif { [regexp -nocase "physical" $ECO_MODE] } {
    set eco_allow_filler_cells_as_open_sites            "true"
    set eco_report_unfixed_reason_max_endpoints         5000
    set_eco_options \
        -physical_lib_path ${LEF_FILES} \
        -physical_design_path ${DEF_FILE} \
        -log_file ${multi_scenario_working_directory}/lef_def.log

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

;# define_user_attribute "pt_dont_use" -quiet -type boolean -class lib_cell ;# Not used in pc_shell
if {[info exist ECO_DONT_USE_LIB_CELL_LIST] && $ECO_DONT_USE_LIB_CELL_LIST != ""} {
    foreach pattern $ECO_DONT_USE_LIB_CELL_LIST {
        if {[set target_lc [get_lib_cells -quiet $pattern]] != ""} {
            echo "** SEC_INFO: set dont_use [sizeof $target_lc] lib cells matching pattern '$pattern'"
            # set_pt_dont_use ${pattern}
			set_dont_use_cell ${pattern} true

        } else {
            echo "** SEC_WARN: no lib cell to set dont_use found by pattern '$pattern'"
        }
    }
}

if {[info exist ECO_DONT_TOUCH_LIB_CELL_LIST] && $ECO_DONT_TOUCH_LIB_CELL_LIST != ""} {
    foreach pattern $ECO_DONT_TOUCH_LIB_CELL_LIST {
        if {[set target_lc [get_lib_cells -quiet $pattern]] != ""} {
            echo "** SEC_INFO: set dont_touch [sizeof $target_lc] lib cells matching pattern '$pattern'"
            #set_user_attribute -class lib_cell $target_lc dont_touch true
			set_dont_touch_cell true $pattern
        } else {
            echo "** SEC_WARN: no lib cell to set dont_touch found by pattern '$pattern'"
        }
    }
}

if {![file exist ${ECO_USER_DONT_TOUCH_TCL}]} {
	puts "Error_ADF: No \"${ECO_USER_DONT_TOUCH_TCL}\" tcl file."
} else {
	source_wrap -e -v ${ECO_USER_DONT_TOUCH_TCL}
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
foreach_in_collection lc [get_lib_cells -quiet -regexp .*(base|flk)_.*/.*] {
    set_user_attribute -class lib_cell $lc "pwr_cost" [get_attribute -quiet $lc area]
}

;# assume less power for flat-fin cell, if there is any
foreach_in_collection lc [get_lib_cells -quiet -regexp .*(base|flk).*(flat|f2f).*/.*] {
    set_user_attribute -class lib_cell $lc "pwr_cost" [expr [get_attribute -quiet $lc area] * 0.9]
}

source ${STA_SCRIPT_DIR}/run_teco_restrict.tcl

# Boundary Timing is ignored when proceeding with 1B-STA.
if { [info exists ignore_boundary_dmsa] && $ignore_boundary_dmsa } {
	puts "Information_ADF: Boundary Timing is ignored when proceeding with 1B-STA."
	puts "Warning_ADF: set_false_path is enabled for Boundary Timing."
	puts "Warning_ADF: ( in2reg, reg2out, in2out)"
	puts "Warning_ADF: Used command : set_false_path -from \[all_inputs -exclude_clock_ports \]"
	puts "Warning_ADF: Used command : set_false_path -to   \[all_outputs\]"
	puts "Warning_ADF: Used command : set_false_path -from \[all_inputs -exclude_clock_ports \] -to \[all_outputs\]"
	puts ""
	set_false_path -from [all_inputs -exclude_clock_ports ]                   ;# in2reg
	set_false_path -to   [all_outputs]                   ;# reg2out
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

    unsuppress_message E11191

;#------------------------------------------------------------------------------
;# stop if interactive mode
;#------------------------------------------------------------------------------
if {[info exist RESTORE_SESSION_ONLY] && $RESTORE_SESSION_ONLY} {
	start_eco -mode dmsa -verbose
	if {[info exist whatif ] && $whatif } {
		set stage whatif
		remote_execute { set stage whatif }
	}
    return
}

#############################################################
#run_teco.tcl
#############################################################
set recipe_num 1
set st  [clock seconds]

set FIX_ECO_TCL "fix_eco.tcl"
set Fout [open $FIX_ECO_TCL "w"]

foreach recipe_target $targets {
	set cmd_line ""
	set recipe_type      [lindex [ split $recipe_target "/" ] 0]
	set recipe_method    [lindex [ split $recipe_target "/" ] 1]
	set recipe_restrict  [lindex [ split $recipe_target "/" ] 2]

	set PREFIX "${ECO_NUM_N}_${today}_[lindex [ split $recipe_type "-" ] 0]"
    set_app_var eco_instance_name_prefix  $PREFIX
    set_app_var eco_net_name_prefix		  $PREFIX

	puts $Fout "## $recipe_num"
	puts $Fout "##############################################"
	puts $Fout "# Recipe summary                              "
	puts $Fout "##############################################"
	puts $Fout "# recipe_type     : $recipe_type"
	puts $Fout "# recipe_method   : $recipe_method"
	puts $Fout "# recipe_restrict : $recipe_restrict"
	puts $Fout "# PREFIX          : $PREFIX"

	;#---------------------------------------------------------
	;# Special recipe management
	;#---------------------------------------------------------
	;# mttv-merge
	if { $recipe_type == "mttv-merge" } {
		puts "###############################################################################"
		puts "# Note (temp...)                                                               "
		puts "#------------------------------------------------------------------------------"
		puts "#The mttv-merge step does not work with pc_eco.                                "
		puts "#pc_eco is unconditionally executed as logical_only.                           "
		puts "###############################################################################"
		continue
	} elseif { $recipe_type == "seed" } {
		lappend PC_FIX_TARGET seed
		continue
	} else {
		if { [string match "mttv" $recipe_type] } {
			lappend PC_FIX_TARGET max_transition
		} elseif { [string match "maxcap" $recipe_type] } {
			lappend PC_FIX_TARGET max_capacitance
		} elseif { [string match "setup*" $recipe_type] || [string match "hold*" $recipe_type] || [string match "power*" $recipe_type] || [string match "noise*" $recipe_type] } {
			lappend PC_FIX_TARGET [lindex [split $recipe_type "-"] 0]
		} else {
			puts "Error_ADF: Fixed type is not supported in PrimeClosure."
		}
		set PC_FIX_TARGET [lsort -unique $PC_FIX_TARGET]
	}


	;# *-slvt
	if { [string match "*-slvt" $recipe_type] } {
		puts $Fout "set_dont_use_cell */*TL* false"
		set slvt_use_flag 1
	} else {
		if { [info exists slvt_use_flag ] &&  $slvt_use_flag == "1" } {
			puts $Fout "set_dont_use_cell */*TL* true"
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
	;# other_cmd append
	;#---------------------------------------------------------
	#CMD_other Other options the user wants
	if { [info exists other_cmd_array($recipe_type)] } {
		set cmd_other $other_cmd_array($recipe_type)
	} else {
		set cmd_other ""
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

# [RECOVERED_UNMAPPED_FROM 019b72db-44af-723b-8004-b5638c2fe910.txt] This block appeared before the first PATH marker in 019b72db-44af-723b-8004-b5638c2fe910.txt.
# [ATTACH_DECISION] Attached to previous file by sequential continuity.

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
	puts "Master Recipe : $recipe_target"
	puts $stage
	puts "Slave recipe : ${stage} "
	puts $Fout "set_app_var eco_alternative_cell_attribute_restrictions $restrict_var"

	;#---------------------------------------------------------
	;# Command Excute
	;#---------------------------------------------------------
	echo "** SEC_INFO: fixing $recipe_target timing with command:"
	echo "$cmd_line"
	puts $Fout "$cmd_line "
	puts $Fout "set_app_var eco_alternative_cell_attribute_restrictions -default"
	puts $Fout ""
	puts $Fout ""

	incr recipe_num
}
close $Fout

source ${COMMON_TCL_PT_PROC}/proc_sop_start_eco.tcl

# SMSA_SHELL
start_eco -mode smsa -verbose -smsa_data_types ${PC_FIX_TARGET}

# Redmine :  HM_Auto_Sensor_SoC_1M Task* #4957 [REQ] PI-sophia script #73
if {[info exist ECO_TOUCH_INST__LIB_CELL_LIST ] && $ECO_TOUCH_INST__LIB_CELL_LIST != "" } {
	foreach pattern $ECO_TOUCH_INST__LIB_CELL_LIST {
		set full_name 	[lindex [split $pattern "," ] 0 ]
		set ref_name 	[lindex [split $pattern "," ] 1 ]
		if {[set cells    [get_cells -quiet -hsc / $full_name -filter "ref_name =~ $ref_name" ]] != "" } {
			echo "** SEC_INFO: setting dont_touch for [sizeof $cells] instances with pattern '$pattern' : full_name -> $full_name : ref_name -> $ref_name "
			set_dont_touch_instance true [get_cells $cells]
		} else {
			echo "** SEC_INFO: setting dont_touch for [sizeof $cells] instances with pattern '$pattern' : full_name -> $full_name : ref_name -> $ref_name "
		}
	}
}

redirect -tee ./fix_eco.log {
	source -e -v $FIX_ECO_TCL
}

# DMSA_SHELL
start_eco -mode dmsa -verbose

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
;# Slave settings
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
    ignore_boundary_hold   ]


;#------------------------------------------------------------------------------
;# Required utility procedures
;#------------------------------------------------------------------------------
remote_execute {

	#==============================================================================
	# DT-PI_Add : source utility 
	#==============================================================================
	source ${COMMON_TCL_PROCS}/ST_trace_v2.tbc

	set req_files   [list \
			${UTIL_SCRIPT_DIR}/util_procs.{tbc,tcl}            \
			${UTIL_SCRIPT_DIR}/sec_infer_tech_by_lib.{tbc,tcl} \
			${UTIL_SCRIPT_DIR}/sec_report_cell_usage.tbc       \
	    ]
	foreach pattern $req_files {
	    set fname 	[lindex [glob -nocomplain $pattern] 0]
	    if {![file exist $fname] || ![file readable $fname]} {
	        echo "** SEC_ERROR: required file not found or not accessable - $fname"
	        exit
	    }
	    source $fname
	}
}


;#------------------------------------------------------------------------------
;# Timing reports before ECO
;#------------------------------------------------------------------------------
set M_DIR eco_rpt
file delete -force ${M_DIR}
file mkdir ${M_DIR}

foreach base_rpt [glob -nocomplain -directory ${DMSA_DIR}/eco_rpt *base*] {
	if { [file exist $base_rpt] } {
		exec ln -s ${base_rpt} ${M_DIR}
	} else {
		puts "Error_ADF: Please check existence ${base_rpt}"
	}
}

;#------------------------------------------------------------------------------
;# Timing reports after ECO
;#------------------------------------------------------------------------------
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
	save_session pc_save_session
}

exec touch done.pc_eco

if {$QUIT_ON_FINISH} {
  exit
}
