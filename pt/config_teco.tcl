################################################################################
# File Name     : config_teco.tcl (sample)
# Author        : DT-PI
# Creation Date : 2024-05-14
# Last Modified : 2025-04-17
# Version       : v0.8
# Location      : $PRJ_PT/design_scripts/run_sta.tcl
#-------------------------------------------------------------------------------
# Description   :
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-05-14] : iskim1001
#       - Initial Version Release
# 	v0.2 [2024-05-24] : iskim1001
#       - ADF Message Rule Change
#       	Before : <ADF_ERROR>: , <ADF_WARN>:  , <ADF_INFO>:
#       	After  : Error_ADF:   , Warning_ADF: , Information_ADF:
# 	v0.3 [2024-07-05] : iskim1001
#       - Remove power -type
# 	v0.4 [2025-01-22] : jaeeun1115
#       - Correct typo (insert_inverter_pair)
# 	v0.5 [2025-02-28] : iskim1001
# 		- Add other_opt_array
# 			When not using other_opt : setup/M1/R0
#				Result cmd > fix_eco_timing -type setup           -verbose -pba_mode ${PBA_MODE}" -methods size_cell
#			 When using other_opt     : setup/M1/R0/E0
#				Result cmd > fix_eco_timing -type setup           -verbose -pba_mode ${PBA_MODE}" -methods size_cell -max_iteration 2
#	v.0.6 [2025-03-25] : sjlee
#	    - Add guardband margin in array_set
#	v.0.7 [2025-03-31] : jaeeun1115
#	    - Read lef & def only for netlist sub design
#	v.0.8 [2025-04-17] : jaeeun1115
#	    - Move the part of reading lef & def to config_teco_physical.tcl
#   v.0.9 [2025-11-17] : mhkim616
#       - Add hold-load eco recipe
#   v.1.0 [2025-11-19] : mhkim616
#       - Add restore dmsa_save_session
#
#-------------------------------------------------------------------------------
# Useage        :
#
# Recipe Detail :
# 	gvim ${COMMON_IMPL_DIR}/common_tcl/pt/eco_recipe.config.help
#################################################################################

;#------------------------------------------------------------------------------
;# Technology definition
;#------------------------------------------------------------------------------
set TECH            $PROCESS ;# LN14LPP  or LN05LPE


;#------------------------------------------------------------------------------
;# Tool configuration
;#   Change queuing command environment according to your environment
;#   Following example is based on bsub queuing command
;#------------------------------------------------------------------------------
set SLAVE_NTHREAD	1	;# how many cores each slave process will use


;#------------------------------------------------------------------------------
;# ECO Targets and Strategy
;# 	-. freeze_silicon
;#  -. physical_aware <- Default
;#  -. logical_only
;#------------------------------------------------------------------------------
set ECO_MODE			$eco_mode


;#------------------------------------------------------------------------------
;# Physical mode
;#   -. occupied_site <- Default
;#   -. open_site
;#------------------------------------------------------------------------------
set PHY_MODE            ${phy_mode}


;#------------------------------------------------------------------------------
;# Split FIX_TARGETS based on "_".
;#------------------------------------------------------------------------------
set targets [split $FIX_TARGETS "_"]


;#------------------------------------------------------------------------------
;# Setting PBA_MODE
;#------------------------------------------------------------------------------
set PBA_MODE            	$pba_mode	;# "path" for PBA, "none" for GBA


if {![info exist QUIT_ON_FINISH]} {
  set QUIT_ON_FINISH 	1
}

;#------------------------------------------------------------------------------
;# Set the target end point file.
;#------------------------------------------------------------------------------
if {[info exists STA_USER] && ${STA_USER} == "PD" } {
    set ECO_CONST_DIR   ${RUN_DIR}/../../../ECO_CONST
} else {
    set ECO_CONST_DIR   ${RUN_DIR}/../../ECO_CONST
}

set TARGET_POINT_DRC_FILE		"${ECO_CONST_DIR}/fix_drc_point.list"        ;# means all violated
set TARGET_ENDPOINT_SETUP_FILE 	"${ECO_CONST_DIR}/fix_setup_endpoint.list"   ;# means all violated endpoint
set TARGET_ENDPOINT_HOLD_FILE 	"${ECO_CONST_DIR}/fix_hold_endpoint.list"    ;# means all violated endpoint

set ECO_USER_DONT_TOUCH_TCL     "${ECO_CONST_DIR}/dont_touch.tcl"            ;# user define dont_touch list

;#------------------------------------------------------------------------------
;# Scenarios to use for DMSA fix timing
;#------------------------------------------------------------------------------
if { $CUR_JOB == "dmsa_eco" } {
	set SESSION_LIST_FILE   ${RUN_DIR}/session_list.txt
	if { [file exist $SESSION_LIST_FILE ] } {
	    file delete $SESSION_LIST_FILE
	}
	if {[info exist whatif] && $whatif} {
		set out_file "session_list.txt"										;# Define output file
		set fp [open $out_file "w"]											;# Initialize again for writing

		set dmsa_dirs [list "$RUN_DIR/dmsa_save_session"]					;# Set dmsa_dirs as a list (even if only one path)

		foreach dir $dmsa_dirs {
			if {![file exists $dir]} {
				puts "Directory does not exist: $dir"
				continue
			}

			set corners [glob -nocomplain -directory $dir *]				;# Get all entries under dmsa_save_session

			foreach path $corners {
				if {![file isdirectory $path]} {
					continue
				}

				set name [file tail $path]

				if {$name eq "common_data"} {
					continue
				}

				puts $fp $path
			}
		}

		close $fp
	} else {
		set STA_DIR  [regsub {/dmsa_eco.*} ${RUN_DIR} []]
		foreach scenario $SCENARIOS {
			;# scenario == func.ss28_0p90V_0p00V_0p00V_0p00V_125C_SigRCmax
			set scn_mode         [lindex [split $scenario "."] 0] ;#func
			set scn_corner       [lindex [split $scenario "."] 1] ;#ss28_0p90V_0p00V_0p00V_0p00V_125C_SigRCmax
			set scn_session_done "${STA_DIR}/${scn_mode}/${scn_corner}/session.done"
			set scn_session      "${STA_DIR}/${scn_mode}/${scn_corner}/session.${scenario}"
			set done 0
			while { $done == 0 } {
				if { [ file exists $scn_session_done ] } {
					echo "... PT_save_session Completed @ ${scn_session_done}"
					echo "${scn_session}" >> $SESSION_LIST_FILE
					set done 1
					sh sleep 1
				} else {
					echo "... Waiting for PT_save_session @${scn_session_done}"
					sh sleep 10
				}
			}
		}
	}
} else {
	;#------------------------------------------------------------------------------
	;# Configuration of eco_session, pc_libin.tcl, and _LIB_CELLS for PrimeClosure
	;#------------------------------------------------------------------------------
	suppress_message E11191

	# Waiting for eco_session_done file
	set eco_session_done   "${DMSA_DIR}/eco_session.done"

	set done 0
	while { $done == 0 } {
	    if { [ file exists $eco_session_done ] } {
	        echo "... eco_session Completed @ ${eco_session_done}"
	        set done 1
	        sh sleep 1
	    } else {
	        echo "... Waiting for eco_session @ ${eco_session_done}"
	        sh sleep 10
	    }
	}

	# Copy and link the pc_input files
	set PC_INPUT_DIR           "${RUN_DIR}/pc_input"
	if {[file exists $PC_INPUT_DIR]} {
	    file delete -force $PC_INPUT_DIR
	}
	file mkdir $PC_INPUT_DIR

	set DMSA_PC_INPUT_DIR        "${DMSA_DIR}/pc_input"
	set DMSA_PC_ECO_SESSION_DIR  "${DMSA_DIR}/eco_session.dmsa"

	file copy  ${DMSA_PC_INPUT_DIR}/pc_libin.tcl ${PC_INPUT_DIR}
	file copy  ${DMSA_PC_INPUT_DIR}/ocv_list     ${PC_INPUT_DIR}
	exec ln -s ${DMSA_PC_ECO_SESSION_DIR}        ${PC_INPUT_DIR}

	set README_FILE "${PC_INPUT_DIR}/eco_session.dmsa/README"
	if { ![file exist ${README_FILE}_org] } {
		file copy ${PC_INPUT_DIR}/eco_session.dmsa/README ${PC_INPUT_DIR}/eco_session.dmsa/README_org
	}

	set Fin  [open ${README_FILE}_org "r"]
	set Fout [open ${README_FILE}     "w"]
	while { [gets $Fin line] != -1 } {
		if { [string match "SCENARIOS*" $line] } {
			regsub [lindex [split $line ":"] end] $line " $SCENARIOS" new_line
			puts $Fout "$new_line"
		} else {
			puts $Fout "$line"
		}
	}
	close $Fin
	close $Fout

	# library setting
	set pc_libin_file       "${PC_INPUT_DIR}/pc_libin.tcl"
	if { [file exist $pc_libin_file] } {
		puts "Information_ADF: PrimeClosure Library tcl file ($pc_libin_file)"
		source $pc_libin_file
	} else {
		puts "Error_ADF: \"$linin_file\" does not exist."
		exit
	}
	get_lib_cells */*

	# OCV library list setting
	foreach scenario $SCENARIOS {
		set ALL_OCV_INFO_FILE [glob ${PC_INPUT_DIR}/ocv_list/*.list]
		foreach OCV_INFO_FILE $ALL_OCV_INFO_FILE {
			set VAR_NAME [regsub -all {\-\-} [regsub ".list" [lindex [split $OCV_INFO_FILE "/"] end] ""] {,}]
			if { [info exist _LIB_CELLS($VAR_NAME)] } {
				set _LIB_CELLS($VAR_NAME) "$_LIB_CELLS($VAR_NAME) [sh cat $OCV_INFO_FILE]"
				set _LIB_CELLS($VAR_NAME) [lsort -unique $_LIB_CELLS($VAR_NAME)]
			} else {
				set _LIB_CELLS($VAR_NAME) [lsort -unique [sh cat $OCV_INFO_FILE]]
			}
		}
	}
}

;#------------------------------------------------------------------------------
;# ECO instance naming convention:
;#   inferred = pteco$MMDD_$idx or specify your own ECO step
;#   modify if needed
;#------------------------------------------------------------------------------
set today  	[clock format [clock seconds] -format "%m%d_%H"]
if { $CUR_JOB == "dmsa_eco" } {
	set_app_var multi_scenario_working_directory ./eco_dir
	set_app_var multi_scenario_merged_error_log  ./eco_dir/merged_error.log
} else {
	set_app_var multi_scenario_working_directory ${RUN_DIR}/eco_dir
	set_app_var multi_scenario_merged_error_log  ${RUN_DIR}/eco_dir/merged_error.log
}

;#------------------------------------------------------------------------------
;# For power attribute based power optimization
;#------------------------------------------------------------------------------
# set leakage_attr_file "$file_path"
# set dynamic_attr_file "$file_path"

;#------------------------------------------------------------------------------
;# Setting for MIM block list
;#------------------------------------------------------------------------------
if { $HIER_DESIGN != "NONE" } {
	set_app_var eco_enable_mim true
}


;#------------------------------------------------------------------------------
;# Recipe Array
;# Version : 0.5
;#------------------------------------------------------------------------------
array set default_cmd_array {
	{mttv}            "fix_eco_drc    -type max_transition  -verbose -setup_margin ${setup_guardband_drc} -hold_margin ${hold_guardband_drc}"
	{mttv-merge}      "skip : mttv-merge recipe is not work in dmsa_eco"
	{maxcap}          "fix_eco_drc    -type max_capacitance -verbose -setup_margin ${setup_guardband_drc} -hold_margin ${hold_guardband_drc}"
	{noise}           "fix_eco_drc    -type noise           -verbose -setup_margin ${setup_guardband_drc} -hold_margin ${hold_guardband_drc}"
	{delta}           "fix_eco_drc    -type delta_delay     -verbose -setup_margin ${setup_guardband_drc} -hold_margin ${hold_guardband_drc}"
	{cellem}          "fix_eco_drc    -type cell_em         -verbose -setup_margin ${setup_guardband_drc} -hold_margin ${hold_guardband_drc}"
	{setup}           "fix_eco_timing -type setup           -verbose -pba_mode ${PBA_MODE} -hold_margin  ${hold_guardband_timing}"
	{setup-slvt}      "fix_eco_timing -type setup           -verbose -pba_mode ${PBA_MODE} -hold_margin  ${hold_guardband_timing}"
	{hold}            "fix_eco_timing -type hold            -verbose -pba_mode ${PBA_MODE} -setup_margin ${setup_guardband_timing}"
	{hold-load}       "fix_eco_timing -type hold            -verbose -pba_mode ${PBA_MODE} -setup_margin ${setup_guardband_timing} -load_cell_list ${HOLD_FIX_LOAD_CELLS}"
	{hold-force}      "fix_eco_timing -type hold            -verbose -pba_mode ${PBA_MODE} -setup_margin -99999"
	{power}           "fix_eco_power                        -verbose -pba_mode ${PBA_MODE} -setup_margin ${setup_guardband_power} -hold_margin ${hold_guardband_power}"
    {power-rm-buf}    "fix_eco_power -methods remove_buffer -verbose -pba_mode ${PBA_MODE} -setup_margin ${setup_guardband_power} -hold_margin ${hold_guardband_power}"
    {power-down-size} "fix_eco_power -methods size_cell     -verbose -pba_mode ${PBA_MODE} -setup_margin ${setup_guardband_power} -power_attribute pwr_cost"
    {power-vt-swap}   "fix_eco_power -methods size_cell     -verbose -pba_mode ${PBA_MODE} -setup_margin ${setup_guardband_power} -power_attribute pwr_cost -pattern_priority  \$VTH_PRIORITY "
}


array set method_array {
	{M1}   "size_cell"
	{M2}   "insert_buffer"
	{M3}   "insert_buffer_at_load_pins"
	{M4}   "insert_buffer_at_driver_pins"
	{M5}   "insert_inverter_pair"
	{M6}   "size_cell_side_load"
	{M7}   "bypass_buffer"
	{M8}   "remove_buffer"
}

array set restrict_var_array {
	{R0} "-default"
	{R1} "eco-only-vth"
	{R2} "eco-only-drive"
}

# User Defined
# -max_iteration integer
# -timeout seconds
# 	|- 3600   == 1H
# 	|- 18000  == 5H
# When not using other_opt : setup/M1/R0
#	cmd > fix_eco_timing -type setup           -verbose -pba_mode ${PBA_MODE}" -methods size_cell
#
# When using other_opt     : setup/M1/R0/E0
#	cmd > fix_eco_timing -type setup           -verbose -pba_mode ${PBA_MODE}" -methods size_cell -max_iteration 2
array set other_opt_array {
	{E0} "-max_iteration 2"
	{E1} "-timeout 3600"
}
