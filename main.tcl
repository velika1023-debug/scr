###################################################################################################
# File               : main.tcl                                                                   #
# Author             : ADT-DT (jblee)                                                             #
# Description        : FC main flow                                                               #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.20                                                                 #
# Script Version     : 1.1                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
#         2025.08.20 - Add USER_NETLIST, GEN_NET_FOR_DEF                                          #
###################################################################################################

# proc_time
set proc_files [lsort [glob -nocomplain ${COMMON_TCL_PROCS}/fc_syn/*.tcl]]
if {[llength $proc_files] > 0 } {
    puts "Information_ADF : Loading Common procedure : "
    foreach FILE $proc_files {
        puts "Information_ADF : Load Common proc -> $FILE "
        source $FILE
    }
}

proc_time TOTAL_START
#################################################################################
# User Variable settings
#################################################################################
puts "Information_ADF : Setting environmental variables defined in user_design_setup.tcl "
set DESIGN_STAGE "before_compile"
source -echo -verbose ${RUN_DIR}/con/user_design_setup.tcl


#################################################################################
# FC Option setting
#################################################################################
puts "Information_ADF : Setting FC environmental option  "
source -echo -verbose ${COMMON_FC_SYN}/0_fc_setup.tcl


#################################################################################
# SVF setup
#################################################################################
set_app_options -name formality.svf.integrate_in_ndm -value true
set_svf ${TOP_DESIGN}.before_compile.svf

if { $USE_SAIF || $USE_SAIF_MAP_FILE != ""} {
    set_app_options -name hdlin.naming.upf_compatible -value true
}


#################################################################################
# FC Library Setup
#################################################################################
proc_time Lib_setup_START
puts "Information_ADF : Setup NDM & Design Lib  "
source -echo -verbose ${COMMON_FC_SYN}/1_lib_setup.tcl
proc_time Lib_setup_END

if { [info exists DEBUG_MODE] && $DEBUG_MODE == 1 } { puts "\[Debug Mode\] : Until DK read " ; return }


#################################################################################
# FC Design Setup, Link the Design
#################################################################################
if { $REUSE_ELAB == "false" } {
    proc_time DESIGN_SETUP_START
    puts "Information_ADF : Setup Deisgn  "
    source -echo -verbose ${COMMON_FC_SYN}/2_design_setup.tcl
    proc_time DESIGN_SETUP_END
    
    if { $INDB_TYPE == "rtl" } {
        proc_time link_START
        redirect ${LOG_DIR}/${TOP_DESIGN}.link.log { set_top_module ${TOP_DESIGN} }
        save_block ${TOP_DESIGN}
        proc_time link_END
    }
} else {
    open_block ${TOP_DESIGN}
    link_block -rebind -force
}

if { [info exist IMPL_BLK_INFO] && $IMPL_BLK_INFO != "NONE" && $is_flat } {
	source -echo -verbose ${COMMON_TCL}/fc_syn/hier_syn_setup.tcl 
}

# Prevent assignment statements
set_fix_multiple_port_nets -all -buffer_constants

if { [info exists DEBUG_MODE] && $DEBUG_MODE == 2 } { puts "\[Debug Mode\] : Until elaboration " ; return }

if {$GEN_ELAB} {
    proc_time copy_unmapped_lib_START 
    copy_lib -to ${OUTPUT_DIR}/${TOP_DESIGN}_elab.nlib
    proc_time copy_unmapped_lib_START 
}


###############################################################################
# Clock gating setup
###############################################################################
source -echo -verbose ${PRJ_FC}/clock_gating_setup.tcl


###############################################################################
# Load power intent
###############################################################################
# Load upf if available
if {[file exist $IMPL_UPF]} {
    proc_time load_upf_START 
        
    puts "Information_ADF : IMPL_UPF -> $IMPL_UPF"
	redirect ${LOG_DIR}/${TOP_DESIGN}.load_upf.log {
		puts "Information_ADF : load_upf ($IMPL_UPF)"
		load_upf $IMPL_UPF
		puts ""
		puts "Information_ADF : commit_upf"
		puts ""
	    commit_upf
	}
    connect_pg_net -automatic -v

    # PRE MV Checks
    redirect ${REPORT_DIR}/${TOP_DESIGN}.check_mv_design.presynth.rpt { check_mv_design }
    proc_time load_upf_END
} else {
    puts "Information_ADF : NO UPF FLOW"
}


#################################################################################
# Scenario Setting
#################################################################################
proc_time scenario_START
source -echo -verbose ${COMMON_FC_SYN}/3_scenarios_setup.tcl
proc_time scenario_END


#################################################################################
# Read Saif infomation
#################################################################################
proc_time read_saif_START
source -echo -verbose ${PRJ_FC}/saif_flow.tcl
proc_time read_saif_END


#################################################################################
# uniquify & Change_Name
#################################################################################
source -echo -verbose ${PRJ_FC}/name_rule_setup.tcl
uniquify -force
change_names -rules verilog     -hierarchy -verbose  > ${REPORT_DIR}/${TOP_DESIGN}.rtl.change_names
change_names -rules sec_verilog -hierarchy -verbose >> ${REPORT_DIR}/${TOP_DESIGN}.rtl.change_names


###############################################################################
# Multibit
###############################################################################
if {$USE_MULTIBIT} {
    set_app_options -name compile.flow.enable_multibit -value true
	# set_app_options -name multibit.naming.rtl_banking_concatenate_single_bit_names -value true
    set_app_options -name multibit.naming.multiple_name_separator_style -value "_MB_"
	source -echo -verbose ${PRJ_FC}/multibit_setup.tcl
} else {
    set_app_options -name compile.flow.enable_multibit -value false
}


#################################################################################
# Match sub-block scenarios with top-level scenarios
#################################################################################
if { [info exist IMPL_BLK_INFO] && $IMPL_BLK_INFO != "NONE" && $is_flat } {

	# If abstraction DBs of sub-blocks are not fully legalized, "compile_fusion -check_only" may report Errors. The command below converts them to warnings instead.
	set_early_data_check_policy -policy normal
	set_early_data_check_policy -policy tolerate -checks hier.block.missing_leaf_cell_location
	set_early_data_check_policy -policy tolerate -checks hier.block.leaf_cell_outside_boundary

	# Execute the set_block_to_top_map command
	foreach cmd $ALL_SET_BLK_TO_TOP_MAP_CMD {
		set SUB_DESIGN_NAME [regsub "_temp" [lindex [split $cmd " "] 3] ""]
		set SUB_DESIGN_ALL_INST_NAME [get_cells -quiet -hierarchical -filter "ref_name == $SUB_DESIGN_NAME"]
		if { [sizeof_collection $SUB_DESIGN_ALL_INST_NAME] > 0 } {
			echo "Information_ADF: Match the scenarios between the top and sub-designs"
			echo "    $SUB_DESIGN_NAME"
			foreach_in_collection SUB_DESIGN_INST_NAME $SUB_DESIGN_ALL_INST_NAME {
				set fname [get_object_name $SUB_DESIGN_INST_NAME]
				set new_cmd [regsub "block \{ ${SUB_DESIGN_NAME}_temp" $cmd "block \{ $fname"]
				echo "      $new_cmd ;# execute command"
				eval $new_cmd
			}
			echo ""
		} else {
			echo "Error_ADF: Not find sub-design Instance name ($SUB_DESIGN_NAME)"
		}
	}
	redirect -tee -file ${REPORT_DIR}/sub_abstract_view.rpt { report_abstracts }
	redirect -tee -file ${REPORT_DIR}/sub_to_top_map.rpt    { report_block_to_top_map }
	# check_design > before_compile.check_design.rpt
}


##################################################################################
# Read physical constraints
##################################################################################
if {!$GEN_NET_FOR_DEF} {
    source -echo -verbose ${PRJ_FC}/physical_option_setup.tcl
}


#################################################################################
# Compile Strategy Setup
#################################################################################
source -echo -verbose ${RUN_DIR}/con/compile_strategy_setup.tcl


#################################################################################
# Compile app_option Setup
#################################################################################
source -echo -verbose ${PRJ_FC}/app_option_setup.tcl

if { [info exists DEBUG_MODE] && $DEBUG_MODE == 3 } { puts "\[Debug Mode\] : Before Compile " ; return }


#################################################################################
# Compile the design using pre-defined flags
#################################################################################
proc_time compile_START 
redirect -tee ${LOG_DIR}/${TOP_DESIGN}.compile.log { source ${COMMON_FC_SYN}/4_run_compile.tcl }
proc_time compile_END 


save_lib -all
##################################################################################
# Create Abstration
##################################################################################
if  { $GEN_ABS }  {
    puts "Information_ADF : Create  ABSTRACTION_DESIGNS (Timing level : ${GEN_ABS_TIMING_LEVEL})  ..."
	set_scenario_status [all_scenarios] -active true -setup true -max_transition true -max_capacitance true -min_capacitance true -hold true -leakage_power true -dynamic_power false
	set_app_options -as_user_default -name abstract.allow_all_level_abstract -value true
	set_app_options -as_user_default -name time.si_enable_analysis -value true
	set_app_options -as_user_default -name abstract.include_aggressor_nets -value true
	create_abstract -read_only -timing_level ${GEN_ABS_TIMING_LEVEL} -force_recreate -preserve_block_instance true

	create_frame -block_all true
}


redirect -tee ${LOG_DIR}/${TOP_DESIGN}.message_summmary.log { report_msg -summary }

proc_time TOTAL_END 

if {$QUIT_ON_FINISH} {
    quit
}
