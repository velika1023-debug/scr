# [PATH_CONFLICT] Original logical path: ./main.tcl
# [SOURCE_TXT] 019b72eb-1366-7073-b81a-b16f280d6641.txt
# [NOTE] Same PATH appeared with different content, so this variant was saved separately.
###################################################################################################
# File               : main.tcl  (Modification of run.tcl)                                        #
# Author             : DTPI jmpark                                                                #
# Description        : Synthesis Script using Design Compiler                                     #
# Usage              :                                                                            #
# Init Release Date  : 2023.03.31                                                                 #
# Last Update  Date  : 2023.06.09                                                                 #
# Last Update  Date  : 2024.10.07                                                                 #
# Last Update  Date  : 2024.10.10                                                                 #
# Last Update  Date  : 2024.10.18                                                                 #
# Last Update  Date  : 2024.10.24                                                                 #
# Last Update  Date  : 2025.02.18                                                                 #
# Script Version     : 0.6                                                                        #
# Revision History   :                                                                            #
#         2023.03.31 - first released                                                             #
#         2023.05.12 - Change not to use multibit more than 6                                     #
#         2023.05.18 - Add gen_elab option                                                        #
#         2023.05.23 - Modify multibit option                                                     #
#         2023.06.09 - Modify of non-upf flow                                                     #
#         2023.06.30 - Change the location of the create_port                                     #
#         2024.10.07 - 0_dc_lib_setup.tcl -> 1_dc_setup.tcl                                       #
#         2024.10.10 - Use Mega-switch for tech-dependent optimization                            #
#         2024.10.10 - saif flow 									                              #
#         2024.10.10 - select block scenario						                              #
#         2024.10.18 - write saif map file  						                              #
#         2024.10.18 - start saif map file  						                              #
#         2024.10.18 - record INCR COMPILE Run time					                              #
#         2024.10.24 - change_name condtion modfiy (rtl) 			                              #
#         2025.02.18 - added a part to source check_con.tcl file (jjh8744)                        #
#         2025.04.10 - added dft incr step (bmkim)                                                #
#         2025.06.19 - compile-ultra retime option add                                            #
#         2025.09.02 - set_dp_smartgen_option option add                                          #
###################################################################################################

# proc_time
set proc_files [lsort [glob -nocomplain ${COMMON_TCL_PROCS}/proc_time.v3.7.tcl]]
if {[llength $proc_files] > 0 } {
    puts "\nInformation_ADF : Loading Common procedure : \n"
    foreach FILE $proc_files {
        puts "\nInformation_ADF : Load Common proc -> $FILE \n"
        source $FILE
    }
}

proc_time TOTAL_START -enable_log -log_prefix runtime

# environment settup
set  REPORTS_DIR ${REPORT_DIR}
set  LOGS_DIR    ${LOG_DIR}
set  OUTPUTS_DIR ${OUTPUT_DIR}

#################################################################################
# Optional Variable settings
#################################################################################
puts "\nInformation_ADF : Setting environmental variables defined in user_design_setup.tcl \n"
source -echo -verbose ${RUN_DIR}/con/user_design_setup.tcl


#################################################################################
# DC library setting
#################################################################################
puts "\nInformation_ADF : Read the Deisgn Kit  \n"
source -echo -verbose ${COMMON_DC_SYN}/1_dc_setup.tcl
source -echo -verbose ${RUN_DIR}/con/user_setup.dc.tcl

if { ${NUM_CPUS} == "" } {	set NUM_CPUS "8" }
if { ${NUM_CPUS} > 8 } {
	set NUM_CPUS "8" 
	puts "\nInformation_ADF : max_core range 1~8 \n"
}

set_host_options -max_cores ${NUM_CPUS}


# The verification setup file for Formality
set cache_read {}
set cache_write {}

    if {$GEN_ELAB} {
        set_svf $OUTPUT_DIR/${TOP_DESIGN}.${RPT_POSTFIX}.elab.svf
        exec ln -sf  ${TOP_DESIGN}.${RPT_POSTFIX}.elab.svf  $OUTPUT_DIR/${TOP_DESIGN}.elab.svf
    } else {
        set_svf $OUTPUT_DIR/${TOP_DESIGN}.${RPT_POSTFIX}.svf
        exec ln -sf  ${TOP_DESIGN}.${RPT_POSTFIX}.svf  $OUTPUT_DIR/${TOP_DESIGN}.svf
    }
    if { [shell_is_dcnxt_shell] && $NDM_MODE } {
    	set ndm_load_mol_routing_layers true
    }

set search_path [concat $search_path $INDB_DIR]

# Multibit
if {$USE_MULTIBIT} {
    if {![info exists multibit_width_MIN] || $multibit_width_MIN == ""} {
        puts "Information_ADF : Multibit Min Width over 1"
        set multibit_width_MIN 1
    }
    if {![info exists multibit_width_MAX] || $multibit_width_MAX == ""} {
        puts "Information_ADF : Multibit Max Width under 6"
        set multibit_width_MAX 6
    }

    set_attribute [get_lib_cells */* -filter "multibit_width > $multibit_width_MIN && full_name !~ gtech*"] dont_use false
    set_attribute [get_lib_cells */* -filter "multibit_width > $multibit_width_MIN && full_name !~ gtech*"] dont_touch false
    set_attribute [get_lib_cells */* -filter "multibit_width > $multibit_width_MAX "] dont_use true

    set hdlin_infer_multibit default_all

    set_app_var bus_multiple_separator_style "_MB_"
    set_app_var bus_multiple_name_separator_style "_MB_"


    if {[shell_is_dcnxt_shell] && [shell_is_in_topographical_mode] } {
       set compile_enable_physical_multibit_banking true
       set compile_multibit_banking_ratio_limit_for_debanking ${BANKING_RATIO_LIMIT}
    }

} else {
      set_attribute [get_lib_cells */* -filter "multibit_width > 1 && full_name !~ gtech*"] dont_use true
}

#################################################################################
# Read design
#################################################################################
#----------------------------------------------------------------------------------
# Debug mode ( 0 - Normal Mode   1 - Until elaboration    2- ~ Until DK read )
#----------------------------------------------------------------------------------
if { $DEBUG_MODE == 2 } { puts "\[Debug Mode\] : Until DK read " ; return }

#################################################################################
# Setup SAIF Name Mapping Database
#
# Include an RTL SAIF for better power optimization and analysis.
#
# saif_map should be issued prior to RTL elaboration to create a name mapping
# database for better annotation.
################################################################################
if { $USE_SAIF_MAP_FILE != ""} {
	if {$USE_SAIF || $GENERATE_SAIFMAP_WITHOUT_SAIF} {
	  saif_map -start
	}
}

source -echo -verbose ${COMMON_DC_SYN}/2_read_design.tcl


if { [info exists ANALYZE_RTL_CONGESTION] && ${ANALYZE_RTL_CONGESTION} == "true"} {
	analyze_rtl_congestion -nosplit >  ${REPORT_DIR}/${TOP_DESIGN}.analyze_rtl_congestion.rpt
}

#################################################################################
# Link the Design
##################################################################################
proc_time link_START -enable_log -log_prefix runtime

current_design ${TOP_DESIGN}
link > ${LOGS_DIR}/${TOP_DESIGN}.link.log
current_design ${TOP_DESIGN}

if { $IMPL_BLOCK_ABS_NAME != "NONE"} {
    report_block_abstraction > ${REPORT_DIR}/${TOP_DESIGN}.initial.block_abstraction.rpt
}

proc_time link_END -enable_log -log_prefix runtime


current_design ${TOP_DESIGN}

if {$GEN_ELAB} {
    proc_time write_unmap_ddc_START -enable_log -log_prefix runtime
    write -format ddc -hierarchy -output ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.elab.ddc
    exec ln -sf  ${TOP_DESIGN}.${RPT_POSTFIX}.elab.ddc  ${OUTPUT_DIR}/${TOP_DESIGN}.elab.ddc

	set_svf -off

    set_svf $OUTPUT_DIR/${TOP_DESIGN}.${RPT_POSTFIX}.svf
    exec ln -sf  ${TOP_DESIGN}.${RPT_POSTFIX}.svf  $OUTPUT_DIR/${TOP_DESIGN}.svf

    proc_time write_unmap_ddc_END -enable_log -log_prefix runtime
}


set filename "${LOGS_DIR}/${TOP_DESIGN}.target.log"
set file [open $filename "w"]
puts $file [join [split $target_library ] "\n"]
close $file

current_design ${TOP_DESIGN}

if { $DEBUG_MODE == 1 } { puts "\[Debug Mode\] : Until elaboration " ; return }

# create port
if {[file exist ${TOP_DESIGN}.create_ports.tcl]} {
    source -e -v ${TOP_DESIGN}.create_ports.tcl
}

# Control DRC/Fanout for tie cells
# # This allows a fanout of 1 on tie cells to be set:
# EDIT
# set_auto_disable_drc_nets -constant false
if { ${COMPILE_FINAL_DRC_FIX} != "" } {
	set_app_var compile_final_drc_fix "$COMPILE_FINAL_DRC_FIX"
}

###############################################################################
# Load power intent
###############################################################################
proc_time load_upf_START -enable_log -log_prefix runtime

# Load upf if available
if {[file exist $IMPL_UPF]} {

	# Insert a level shifter on an ideal net
	set_app_var auto_insert_level_shifters_on_clocks   "all"
 	set_app_var mv_insert_level_shifters_on_ideal_nets "all"

    puts "\nInformation_ADF : IMPL_UPF -> $IMPL_UPF\n"
    load_upf  ${IMPL_UPF}  > ${LOGS_DIR}/${TOP_DESIGN}.load_upf.log
} else {
    puts "\nWarning_ADF : IMPL_UPF -> $IMPL_UPF is not exists" 
}

proc_time load_upf_END -enable_log -log_prefix runtime

#################################################################################
#  Scenario Setting
#################################################################################

source -echo -verbose ${COMMON_DC_SYN}/3_scenarios_setup.tcl

if {$USE_MCMM} {
    set all_active_scenario_saved [all_active_scenarios]
    set current_scenario_saved [current_scenario]
    set_active_scenarios -all
    foreach scenario [all_active_scenarios] {
        current_scenario ${scenario}
        #################################################################################
        #  Apply constraints for synthesis
        #################################################################################
        # size only list - add jmpark 231227
        source -e -v  ${RUN_DIR}/con/size_only.tcl
        # dont_touch cell or net
        source -e -v  ${RUN_DIR}/con/dont_touch.tcl
        # set do use  list
        source -e -v  ${RUN_DIR}/con/dont_use.tcl
        # set verification priority list
        source -e -v  ${RUN_DIR}/con/set_svp.tcl
    
        #################################################################################
        # User constraint
        #################################################################################
        # Applies when other constraints related to synthesis exist .
        source -e -v  ${RUN_DIR}/con/other_constraint.tcl
    }
	current_scenario ${current_scenario_saved}
	set_active_scenarios ${all_active_scenario_saved}
    set_active_scenarios -all
} else {
    #################################################################################
    #  Apply constraints for synthesis
    #################################################################################
    # size only list - add jmpark 231227
    source -e -v  ${RUN_DIR}/con/size_only.tcl
    # dont_touch cell or net
    source -e -v  ${RUN_DIR}/con/dont_touch.tcl
    # set do use  list
    source -e -v  ${RUN_DIR}/con/dont_use.tcl
    # set verification priority list
    source -e -v  ${RUN_DIR}/con/set_svp.tcl

    #################################################################################
    # User constraint
    #################################################################################
    # Applies when other constraints related to synthesis exist .
    source -e -v  ${RUN_DIR}/con/other_constraint.tcl
}

##################################################################################
# Read physical constraints (topographical mode only)
#
# Our reference script shows example physical constraint setting using:
# A) DEF file in $INPUT_DEF_FILE
# B) Tcl constraints generated by user
##################################################################################

if {[shell_is_in_topographical_mode]} {
proc_time read_physical_const_START -enable_log -log_prefix runtime

    #################################################################################
	#  Change names To match the port name in the def file
	##################################################################################
    if { $USE_SPG || [info exists DEF_INPUT_FILE] && $DEF_INPUT_FILE != "" && [file exists [which ${DEF_INPUT_FILE}]]} { ;# add jmpark 241024 , req ibcha
		change_names -rules verilog -hierarchy -verbose      > ${REPORT_DIR}/${TOP_DESIGN}.rtl.change_names
		change_names -rules sec_verilog -hierarchy -verbose >> ${REPORT_DIR}/${TOP_DESIGN}.rtl.change_names
	}

    # CHECK!!
    set physopt_enable_via_res_support true
	# Please fill out the preferred routing direction depending on the metal stack
    set_preferred_routing_direction -layers $VERTICAL_LAYER   -direction vertical
    set_preferred_routing_direction -layers $HORIZONTAL_LAYER -direction horizontal

	if { [info exists MIN_ROUTING_LAYER] && ${MIN_ROUTING_LAYER} != ""} {
		set_ignored_layers -min_routing_layer ${MIN_ROUTING_LAYER}
	}

	if { [info exists MAX_ROUTING_LAYER] && ${MAX_ROUTING_LAYER} != ""} {
		set_ignored_layers -max_routing_layer ${MAX_ROUTING_LAYER}
	}

	report_ignored_layers

    if { [info exists DEF_INPUT_FILE] && $DEF_INPUT_FILE != "" && [file exists [which ${DEF_INPUT_FILE}]] } {
        redirect -tee ${LOG_DIR}/read_fp.log {
		   extract_physical_constraints ${DEF_INPUT_FILE} -ignore_undefined_site_rows -verbose
        }
        puts "\nInformation_ADF : Read DEF  -> $DEF_INPUT_FILE"
    } elseif { [info exists TCL_PHYSICAL_CONSTRAINTS] && $TCL_PHYSICAL_CONSTRAINTS != "" && [file exists [which ${TCL_PHYSICAL_CONSTRAINTS}]] } {
	    set_app_var enable_rule_based_query true
        redirect -tee ${LOG_DIR}/read_fp.log { source -echo -verbose ${TCL_PHYSICAL_CONSTRAINTS} }
	    set_app_var enable_rule_based_query false
        puts "\nInformation_ADF : Read PHYSICAL_CONSTRAINTS -> $TCL_PHYSICAL_CONSTRAINTS"
    } elseif { $USE_AUTO_FLOORPLAN_CONSTRAINTS && [shell_is_dcnxt_shell] && $NDM_MODE } {
	      set AUTO_FP_CMD "set_auto_floorplan_constraints          \
                           -core_utilization ${BLOCK_CORE_UTIL}  \
                           -core_offset ${BLOCK_CORE_OFFSET}     \
                           -coincident_boundary false            \
                           -site_def unit"
         eval ${AUTO_FP_CMD}
    } else {
         set_utilization ${BLOCK_CORE_UTIL}
    }


	# Write applied floorplan and report applied physical constraints

	write_floorplan -all ${OUTPUT_DIR}/${TOP_DESIGN}.fp

	report_physical_constraints > ${REPORT_DIR}/${TOP_DESIGN}.physical_constraints.rpt

    proc_time read_physical_const_END -enable_log -log_prefix runtime
}

##################################################################################
# DCNXT Features
#################################################################################
if {[shell_is_dcnxt_shell]} {

    if { $RPT_TRANSFORMED_REGISTERS } {
          set compile_enable_report_transformed_registers true
    }

	if {$NDM_MODE} {
        if { [shell_is_in_topographical_mode] } {
  		# Use ICC2 link in DCNXT-Topo
  		dcnxt_use_icc2_link -placement ${USE_ICC2_PLACEMENT} -auto_floorplan ${USE_AUTO_FLOORPLAN_CONSTRAINTS} -congestion_use_global_route ${USE_ICC2_GR_CONGESTION}

		set_app_var placer_buffering_aware 				true  ; # BAP
		set_app_var placer_auto_timing_control  		true  ; # ATC
		set_app_var spg_icc2_rc_correlation		 		false ; # set true if your design gets the low RC correlation with ICC2
        }

		# High effort of leakage pwr
		set_compile_power_high_effort -leakage true
		
		# add jmpark 241010
  		# Use Mega-switch for tech-dependent optimization
  		if { [string match "*28*" $TECHNOLOGY_NODE] } {
            puts "Error_ADF : Unsupported TECHNOLOGY_NODE value $TECHNOLOGY_NODE"
        } elseif { [string match "*2*" $TECHNOLOGY_NODE] || [string match "*3*" $TECHNOLOGY_NODE]} {
  		   set_technology -node s3
  		} elseif { [string match "*14*" $TECHNOLOGY_NODE] } {
  		   set_technology -node s14
  		} elseif { [string match "*5*" $TECHNOLOGY_NODE] } {
  		   set_technology -node s5
  		} elseif { [string match "*8*" $TECHNOLOGY_NODE] } {
  		   set_technology -node s8
  		} elseif { [string match "*4*" $TECHNOLOGY_NODE] } {
  		   set_technology -node s4
  		}

		if { $USE_LOGIC_RESTRUCTURING } {
         # Advanced restructuring for area: it may have some timing degradation
			set compile_advanced_logic_restruct 2
        }
    }
}

##################################################################################
# Run check_design before compile
#################################################################################
#add jmpark 241010
if { $IMPL_BLOCK_ABS_NAME != "NONE"} {
	if {[expr [llength $SUB_DESIGNS_SCENARIOS]%2] == 0 && $SUB_DESIGNS_SCENARIOS != ""} {
		foreach {itr1 itr2} $SUB_DESIGNS_SCENARIOS {
			puts "select_block_scenario -block_references $itr1 -block_scenario $itr2"
			select_block_scenario -block_references $itr1 -block_scenario $itr2
		}
    	check_block_abstraction  > ${REPORT_DIR}/${TOP_DESIGN}.check_block_abstration.rpt
    	report_block_abstraction > ${REPORT_DIR}/${TOP_DESIGN}.final.block_abstraction.rpt
	} else {
    	check_block_abstraction  > ${REPORT_DIR}/${TOP_DESIGN}.check_block_abstration.rpt
    	report_block_abstraction > ${REPORT_DIR}/${TOP_DESIGN}.final.block_abstraction.rpt
	}
}

check_design > ${REPORT_DIR}/${TOP_DESIGN}.check_design.presyn.rpt

current_design ${TOP_DESIGN}

##################################################################################
# SAIF Flow
##################################################################################
if {$USE_SAIF} {
   if { [shell_is_in_topographical_mode] && $SAIF_FILE != "" }  {
      foreach SCN [get_scenarios -active true -dynamic_power true] {
          current_scenario $SCN
		  if { $USE_SAIF_MAP_FILE != ""} {
		  	saif_map -read_map $USE_SAIF_MAP_FILE
		  }
          reset_switching_activity
          puts "Information_ADF: SAIF file is applied for power optimization"
          set read_saif_cmd "read_saif -input $SAIF_FILE -auto_map_names"
          if {$STRIP_PATH != ""} {lappend read_saif_cmd -instance_name $STRIP_PATH}
          puts "Information_ADF: Running $read_saif_cmd"
          eval {eval ${read_saif_cmd}}

          saif_map -report >  ${REPORTS_DIR}/${TOP_DESIGN}.$SCN.saif_map.rpt
          propagate_switching_activity
          report_saif -hier  -rtl_saif -missing   > ${REPORTS_DIR}/${TOP_DESIGN}.$SCN.report_saif.rtl_missing.rpt
          report_saif -hier  -missing             > ${REPORTS_DIR}/${TOP_DESIGN}.$SCN.report_saif.missing.rpt
          report_activity -driver -scenarios $SCN
      }
   }
}

#################################################################################
# Apply optimization metrics using set_qor_strategy
#################################################################################
if { [shell_is_dcnxt_shell] && [shell_is_in_topographical_mode] } {
   if { [info exists SET_QOR_STRATEGY_METRIC] && ${SET_QOR_STRATEGY_METRIC} != ""} {
      puts "Information_ADF: DC-NXT set_qor_strategy -stage synthesis -metric ${SET_QOR_STRATEGY_METRIC}"
      set_qor_strategy -stage synthesis -metric ${SET_QOR_STRATEGY_METRIC}
   }
   if { [info exists SET_QOR_STRATEGY_METRIC] && ${SET_QOR_STRATEGY_METRIC} == "total_power"} {
      set_app_var placer_enhanced_low_power_effort medium
   }
}

#################################################################################
#  datapath Strategy for arithmetic and shift operators
#################################################################################
if {[info exists USE_OPERATOR_OPT ] && ${USE_OPERATOR_OPT}} {
    set SMARTGEN_COMMAND "set_dp_smartgen_option"
    if {$OPTIMIZE_FOR != "" } { set SMARTGEN_COMMAND [concat $SMARTGEN_COMMAND -optimize_for ${OPTIMIZE_FOR}]  }
    if {$ADDER_ALGOR  != "" } { set SMARTGEN_COMMAND [concat $SMARTGEN_COMMAND -${ADDER_ALGOR} true ]          }
    puts "Information_ADF : Running following set_dp_smartgen_option command using pre-defined datapath Strategy for arithmetic and shift operators"
    puts "Information_ADF : $SMARTGEN_COMMAND"
}

#################################################################################
# Optional variable settings for low power opt. w/ SAIF
#################################################################################
if { ![shell_is_dcnxt_shell] && $SAIF_FILE != ""} {
    puts "Information_ADF: DC set variables for SAIF flow"
    set_app_var power_low_power_placement true
    set_app_var power_enable_minpower true
    set_app_var compile_timing_high_effort true
}

###############################################################################
# Pre MV Checks
###############################################################################
redirect -tee ${REPORT_DIR}/${TOP_DESIGN}.check_mv_design.presynth.rpt { check_mv_design -verbose }

###############################################################################
# Clock gating setup
###############################################################################
set_app_var compile_clock_gating_through_hierarchy true
set timing_separate_clock_gating_group TRUE

if {[info exists ICGN_NAME] && $ICGN_NAME ne "" } {
    set_clock_gating_style \
        -sequential_cell latch \
        -max_fanout ${MAX_ICG_FANOUT} \
        -minimum_bitwidth ${MIN_ICG_FANOUT} \
        -positive_edge_logic ${ICGP_NAME} \
        -negative_edge_logic ${ICGN_NAME} \
        -control_point before \
        -control_signal scan_enable \
        -num_stages $ICG_STAGES
} else {
    set_clock_gating_style \
        -sequential_cell latch \
        -max_fanout ${MAX_ICG_FANOUT} \
        -minimum_bitwidth ${MIN_ICG_FANOUT} \
        -positive_edge_logic ${ICGP_NAME} \
        -control_point before \
        -control_signal scan_enable \
        -num_stages $ICG_STAGES
}

if { $DEBUG_MODE == 3 } { puts "\[Debug Mode\] : before Compile" ; return }

#################################################################################
# Compile the design using pre-defined flags
#
# Please note that this script does not cover the commands and variable settings
# related with Clock Gating and DFT insertion. You should define variables and
# options related with clock gating before compile if you want to use CG.
# After the completion of 1st compile, SEC recommends do DFT insertion
# followed by incremental compile.
#################################################################################
proc_time compile_START -enable_log -log_prefix runtime

if {$DFT_INSERTION} {
    source -e -v ${RUN_DIR}/con/insert_scan.before_compile.tcl
}

set COMPILE_COMMAND "compile_ultra -gate_clock"

if {$USE_SCANFF        } { set COMPILE_COMMAND [concat $COMPILE_COMMAND -scan]   }
if { $USE_RETIME       } { set COMPILE_COMMAND [concat $COMPILE_COMMAND -retime]                    }
if {!$USE_BOUNDARY_OPT } { set COMPILE_COMMAND [concat $COMPILE_COMMAND -no_boundary_optimization]  }
if {!$USE_AUTOUNGROUP  } { set COMPILE_COMMAND [concat $COMPILE_COMMAND -no_autoungroup]            }
if {!$USE_SEQ_INVERSION} { set COMPILE_COMMAND [concat $COMPILE_COMMAND -no_seq_output_inversion]   }
if { $USE_SPG } {
	if {![shell_is_in_topographical_mode]} {
		puts "Warning_ADF: Using -spg option can be enabled only in topographical mode."
	} else {
        	set COMPILE_COMMAND [concat $COMPILE_COMMAND -spg]
    }
}

# Check dont_touch, dont_use, size_only
source ${COMMON_TCL}/dc_syn/check_con.tcl

puts "Information_ADF: Running following compile_ultra command using pre-defined compile strategy"
puts "$COMPILE_COMMAND"
redirect -tee ${LOG_DIR}/${TOP_DESIGN}.compile.log { eval $COMPILE_COMMAND }
proc_time compile_END -enable_log -log_prefix runtime

# #################################################################################
# #  Insert MV Cells
# #################################################################################

# if {[file exist $IMPL_UPF]} {
#     if {$DFT_INSERTION == "false"} {
#         if {$NUM_INCR_COMPILE == 0} {

# 			#add jmpark 241209
# 			foreach itr $TARGET_PMK_LIB_NAME {
# 		        remove_attribute [get_lib_cells *$itr*/*] dont_use
# 		        remove_attribute [get_lib_cells *$itr*/*] dont_touch
# 		        puts "remove_attribute  \[get_lib_cells *$itr*/*\] dont_use"
# 		        puts "remove_attribute  \[get_lib_cells *$itr*/*\] dont_touch"
# 			}

#             proc_time insert_mv_START -enable_log -log_prefix runtime
#             insert_mv_cells -all -verbose > ${LOGS_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.insert_mv_cells.log
#             proc_time insert_mv_END -enable_log -log_prefix runtime

# 			#add jmpark 241209
# 			foreach itr $TARGET_PMK_LIB_NAME {
# 				set_dont_use [get_lib_cells *$itr*/*]
# 				set_dont_touch [get_lib_cells *$itr*/*]
# 				puts "set_dont_touch \[get_lib_cells *$itr*/*\]"
# 				puts "set_dont_use \[get_lib_cells *$itr*/*\]"
# 			}
#         }
#     }
# }


#################################################################################
#  Change names before output
##################################################################################

set_app_var uniquify_naming_style "${TOP_DESIGN}_%s_%d"
uniquify -force
change_names -rules verilog -hierarchy -verbose      > ${REPORT_DIR}/${TOP_DESIGN}.change_names
change_names -rules sec_verilog -hierarchy -verbose >> ${REPORT_DIR}/${TOP_DESIGN}.change_names

set DESIGN_STAGE "compile"
if {$GEN_COMPILE_RPT || $NUM_INCR_COMPILE == 0} {
    proc_time write_output_compile_report_START -enable_log -log_prefix runtime
    source -echo -verbose ${SCRDIR}/report_design.tcl
    proc_time write_output_compile_report_END -enable_log -log_prefix runtime
} else {
    write -format verilog -hierarchy -output ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.v
    write -format ddc -hierarchy -output ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.ddc
    exec ln -sf  ${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.v   ${OUTPUT_DIR}/${TOP_DESIGN}.v  
    exec ln -sf  ${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.ddc ${OUTPUT_DIR}/${TOP_DESIGN}.ddc
}
#################################################################################
# Placement-aware multibit banking
#################################################################################
if {$USE_MULTIBIT} {
    if {$USE_DEBANKING && [shell_is_in_topographical_mode] } {
        set_multibit_options -mode timing_driven -critical_range default
	    identify_register_banks -multibit_components_only -output_file ./${TOP_DESIGN}.mbit
        if {[file exist ${TOP_DESIGN}.mbit]} { source ./${TOP_DESIGN}.mbit }
    }
}


#################################################################################
# Additional Steps such as insert_dft should be located here
#################################################################################

set COMPILE_COMMAND [concat $COMPILE_COMMAND -incremental]

# Area optimization with incremental compile
if { [shell_is_dcnxt_shell] && $USE_OPTIMIZE_NETLIST } {
	set compile_optimize_netlist_area_in_incremental true ; # ON-A will perform with incremental compile
	set compile_high_effort_area_in_incremental true ; # for high effort ON-A
}

if {$NUM_INCR_COMPILE > 0} {
	for {set t 1} {$t <= $NUM_INCR_COMPILE} {incr t} {
        set flag "0"
        if { $t == $NUM_INCR_COMPILE } {
            set flag "1"
        }
        set DESIGN_STAGE "incr_compile$t"
		proc_time INCR_COMPILE_START -enable_log -log_prefix runtime
        redirect -tee ${LOG_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.log { eval $COMPILE_COMMAND }
		proc_time INCR_COMPILE_END -enable_log -log_prefix runtime

		# #################################################################################
		# #  Insert MV Cells
		# ##################################################################################

		# if {[file exist $IMPL_UPF]} {
		#     if {$DFT_INSERTION == "false"} {
		#         if {$DESIGN_STAGE == "final"} {
		#    		#add jmpark 241209
		#    		foreach itr $TARGET_PMK_LIB_NAME {
		#    		    remove_attribute [get_lib_cells *$itr*/*] dont_use
		#    		    remove_attribute [get_lib_cells *$itr*/*] dont_touch
		#    		    puts "remove_attribute  \[get_lib_cells *$itr*/*\] dont_use"
		#    		    puts "remove_attribute  \[get_lib_cells *$itr*/*\] dont_touch"
		#    		}
		#             proc_time insert_mv_START -enable_log -log_prefix runtime
		#             insert_mv_cells -all -verbose > ${LOGS_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.insert_mv_cells.log
		#             proc_time insert_mv_END -enable_log -log_prefix runtime

		#    		#add jmpark 241209
		#    		foreach itr $TARGET_PMK_LIB_NAME {
		#    			set_dont_use [get_lib_cells *$itr*/*]
		#    			set_dont_touch [get_lib_cells *$itr*/*]
		#    			puts "set_dont_touch \[get_lib_cells *$itr*/*\]"
		#    			puts "set_dont_use \[get_lib_cells *$itr*/*\]"
		#    		}
		#         }
		#     }
		# }
		        
		#23.10.04 BOS_N1 Requset Task #3883 (#83)
		# module overlap
		uniquify -force

        if { $flag == "0" } {
		    change_names -rules verilog -hierarchy -verbose      > ${REPORT_DIR}/${TOP_DESIGN}.change_names_${DESIGN_STAGE}
		    change_names -rules sec_verilog -hierarchy -verbose >> ${REPORT_DIR}/${TOP_DESIGN}.change_names_${DESIGN_STAGE}

   		    write -format verilog -hierarchy -output ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.v
   		    write -format ddc -hierarchy -output ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.ddc
   		    exec ln -sf  ${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.v   ${OUTPUT_DIR}/${TOP_DESIGN}.v  
   		    exec ln -sf  ${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.ddc ${OUTPUT_DIR}/${TOP_DESIGN}.ddc
        }
	}
    set DESIGN_STAGE incr_compile
    
    if {![shell_is_dcnxt_shell]} {      ;  # ON-A will perform in DCG
       	optimize_netlist -area
    }
    source -echo -verbose ${SCRDIR}/report_design.tcl
}

if {$DFT_INSERTION == "true"} {

    ###############################################################################
    # INSERT_DFT
    ###############################################################################

    #23.12.05 BOS_N1 Requset Task 3916
    proc_time INSERT_DFT_START -enable_log -log_prefix runtime
    set DESIGN_STAGE "dft"
    set_svf -off
    set_svf $OUTPUT_DIR/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.svf

    #hmjo
    #23.12.06 BOS_N1 Requset Task #3916
    if {[file exist ${RUN_DIR}/con/read_ctl.tcl]} {
        source -e -v ${RUN_DIR}/con/read_ctl.tcl
    }
    #

    current_design ${TOP_DESIGN}

    source -e -v ${RUN_DIR}/con/insert_scan.after_compile.tcl
    source -e -v ${RUN_DIR}/con/insert_scan.before_exit.tcl

    # #################################################################################
    # #  Insert MV Cells
    # #################################################################################
    # 
    # if {[file exist $IMPL_UPF]} {
    #     proc_time insert_mv_START -enable_log -log_prefix runtime
    #     insert_mv_cells -all -verbose > ${LOGS_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.insert_mv_cells.log
    #     proc_time insert_mv_END -enable_log -log_prefix runtime
    # }

    uniquify -force
    
    change_names -rules verilog -hierarchy -verbose      > ${REPORT_DIR}/${TOP_DESIGN}.change_names_${DESIGN_STAGE}
    change_names -rules sec_verilog -hierarchy -verbose >> ${REPORT_DIR}/${TOP_DESIGN}.change_names_${DESIGN_STAGE}
    
    source -e -v ${SCRDIR}/report_design.tcl
    proc_time INSERT_DFT_END -enable_log -log_prefix runtime
    
    if {[info exists NUM_INCR_AFTER_DFT] && "$NUM_INCR_AFTER_DFT" == "true" } {
        proc_time INCR_COMPILE_AFTER_DFT_START
        ###############################################################################
        # INCR COMPILE
        ###############################################################################
        if {![string match "-incremental" $COMPILE_COMMAND]} {
            set COMPILE_COMMAND [concat $COMPILE_COMMAND -incremental]
        }
    
        set DESIGN_STAGE "incr_dft"
        redirect -tee ${LOG_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.log { eval $COMPILE_COMMAND }
        proc_time INCR_COMPILE_AFTER_DFT_END
        source -e -v ${SCRDIR}/report_design.tcl
    }
}

###############################################################################
# Post MV Checks
###############################################################################
if {[file exist $IMPL_UPF]} {
    redirect -tee ${REPORT_DIR}/${TOP_DESIGN}.check_mv_design.postsynth.rpt { check_mv_design -verbose }
}

source -echo -verbose ${COMMON_DC_SYN}/4_add_report.tcl

##################################################################################
# Create Abstration
##################################################################################
if  { $GEN_ABS }  {
    puts "\nInformation_ADF : Create  ABSTRACTION_DESIGNS  ...\n"
    create_block_abstraction
    write -hierarchy -format ddc -output  ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.mapped.ddc
    exec ln -sf ${TOP_DESIGN}.${RPT_POSTFIX}.mapped.ddc ${OUTPUT_DIR}/${TOP_DESIGN}.mapped.ddc
}

if { $GEN_ABS_NLIB } {
	puts "\nInformation_ADF : Create  ABSTRACTION_NLIB  ...\n"
	create_block_abstraction
	create_link_block_abstraction -top_block -output_ddc_file ${OUTPUT_DIR}/${NDM_DESIGN_LIB}/${TOP_DESIGN}.nlib.ddc -output_ndm_dir ${OUTPUT_DIR}/${NDM_DESIGN_LIB}
	set NDM_FILE_LIST [glob -nocomplain -directory ${OUTPUT_DIR}/${NDM_DESIGN_LIB} *]
	foreach NDM_FILE $NDM_FILE_LIST {
	    if {[string match "${TOP_DESIGN}*nlib" [file tail ${NDM_FILE}]]} {
			set BLK_NLIB [file tail $NDM_FILE]
	    }
	}
	exec ln -sf ${NDM_DESIGN_LIB}/${TOP_DESIGN}.nlib.ddc ${OUTPUT_DIR}/${TOP_DESIGN}.nlib.ddc
	exec ln -sf ${NDM_DESIGN_LIB}/${BLK_NLIB}  ${OUTPUT_DIR}/${TOP_DESIGN}.nlib
}

redirect -tee ${LOGS_DIR}/${TOP_DESIGN}.message_summmary.log { print_message_info }

set_svf -off
proc_time TOTAL_END -enable_log -log_prefix runtime


if {$QUIT_ON_FINISH} {
    quit
}


if {$USE_SAIF || $GENERATE_SAIFMAP_WITHOUT_SAIF} {
    # Write out SAIF name mapping file for PrimeTime-PX and ICC2
    saif_map -type ptpx -essential -write_map ${OUTPUTS_DIR}/${TOP_DESIGN}.mapped.saif.ptpx.map
    saif_map -write_map ${OUTPUTS_DIR}/${TOP_DESIGN}.mapped.saif.dc.map
}
