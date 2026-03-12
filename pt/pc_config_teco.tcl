################################################################################
# File Name     : config_teco.tcl (sample)
# Author        : DT-PI
# Creation Date : 2024-08-28
# Last Modified : 2025-01-22
# Version       : v0.2
# Location      : $PRJ_PT/design_scripts/pc_run_teco.tcl
#-------------------------------------------------------------------------------
# Description   :
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-08-28] : jjh8744
#       - Initial Version Release
# 	v0.2 [2025-01-22] : jaeeun1115
#       - Correct typo (insert_inverter_pair)
#-------------------------------------------------------------------------------
# Useage        :
#
# Recipe Detail :
# 	gvim ${COMMON_IMPL_DIR}/common_tcl/pt/eco_recipe.config.help
#################################################################################

suppress_message E11191

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
set TARGET_ENDPOINT_FILE_SETUP 	"${RUN_DIR}/../../setup_target.list" ;# means all violated endpoint
set TARGET_ENDPOINT_FILE_HOLD 	"${RUN_DIR}/../../hold_target.list"	 ;# means all violated endpoint


;#------------------------------------------------------------------------------
;# Collaterals for Physical-aware ECO
;#------------------------------------------------------------------------------
set ECO_WORK_DIR        ./
set ECO_SCRIPT_PATH     ./
set LEF_PATH            ${SPEF_DIR}
set DEF_PATH            ${SPEF_DIR}
set LEF_FILES           [glob -nocomplain ${LEF_PATH}/*.lef]
set DEF_FILE            ${DEF_PATH}/${DESIGN}.def.gz


;#------------------------------------------------------------------------------
;# flat_dmsa Hier Design Info setting
;#------------------------------------------------------------------------------
if { ([info exist is_flat] && $is_flat ) && $HIER_DESIGN != "NONE" } {
	puts "Information_ADF: Hierarchy  designs  -  $HIER_DESIGN "
	foreach BLK  $HIER_DESIGN  {
		puts "Information_ADF: Hierarchy  designs  -  $BLK "
		set BLK_NAME         [ set ${BLK}(NAME)         ];#set sub_name          $SUB_NAME($BLK)
		set BLK_INDB_VER     [ set ${BLK}(INDB_VER)     ];#set sub_net_ver       $SUB_INDB_VER($BLK)
		set BLK_PNR_TOOL     [ set ${BLK}(PNR_TOOL)     ];#set sub_pnr_tool      $SUB_PNR_TOOL($BLK)
		set BLK_NET_REVISION [ set ${BLK}(NET_REVISION) ];#set sub_net_revision  $SUB_NET_REVISION_POST($BLK)
		set BLK_ECO_NUM      [ set ${BLK}(NET_ECO_NUM)  ];#set sub_net_eco_num   $SUB_NET_ECO_NUM($BLK)

		set BLK_SUB_SPEF_DIR ${OUTFD_DIR}/$BLK_NAME/$BLK_INDB_VER/$BLK_PNR_TOOL/$BLK_NET_REVISION/$BLK_ECO_NUM/output

		set SUB_LEF_FILES($BLK)   [glob -nocomplain ${BLK_SUB_SPEF_DIR}/*.lef]
		set SUB_DEF_FILE($BLK)    ${BLK_SUB_SPEF_DIR}/${BLK}.def.gz
		puts "$SUB_LEF_FILES($BLK)"
		puts "$SUB_DEF_FILE($BLK)"

		set LEF_FILES [concat $LEF_FILES $SUB_LEF_FILES($BLK)]
		set DEF_FILE [concat $DEF_FILE $SUB_DEF_FILE($BLK)]
	}
}
puts ""
puts "ALL_LEF_FILES : $LEF_FILES"
puts "ALL_DEF_FILE  : $DEF_FILE"
puts ""


;#------------------------------------------------------------------------------
;# ECO instance naming convention:
;#   inferred = pteco$MMDD_$idx or specify your own ECO step
;#   modify if needed
;#------------------------------------------------------------------------------
set today  	[clock format [clock seconds] -format "%m%d_%H"]
set_app_var multi_scenario_working_directory ./eco_dir
set_app_var multi_scenario_merged_error_log  ./eco_dir/merged_error.log


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
	{mttv}            "fix_eco_drc    -type max_transition  -verbose "
	{mttv-merge}      "skip : mttv-merge recipe is not work in dmsa_eco"
	{maxcap}          "fix_eco_drc    -type max_capacitance -verbose "
	{noise}           "fix_eco_drc    -type noise           -verbose "
	{delta}           "fix_eco_drc    -type delta_delay     -verbose "
	{cellem}          "fix_eco_drc    -type cell_em         -verbose "
	{setup}           "fix_eco_timing -type setup           -verbose -pba_mode ${PBA_MODE}"
	{setup-slvt}      "fix_eco_timing -type setup           -verbose -pba_mode ${PBA_MODE}"
	{hold}            "fix_eco_timing -type hold            -verbose -pba_mode ${PBA_MODE}"
	{hold-force}      "fix_eco_timing -type hold            -verbose -pba_mode ${PBA_MODE} -setup_margin -99999"
	{power}           "fix_eco_power                        -verbose -pba_mode ${PBA_MODE}"
    {power-rm-buf}    "fix_eco_power -methods remove_buffer -verbose -pba_mode ${PBA_MODE} -setup_margin ${setup_guardband_power} -hold_margin ${hold_guardband_power} "
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
