###################################################################################################
# File               : app_option_setup.tcl                                                       #
# Author             : ADT-DT (jblee)                                                             #
# Description        : app_option setting                                                         #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################
#-==============================================================
# Place
#-==============================================================
set_app_options -name place.coarse.clock_gate_latency_aware                     -value auto ;# To prevent icg relocation
set_app_options -name place.coarse.enable_spare_cell_placement                  -value false ;# To alleviate icg latancy
set_app_options -name place.coarse.enable_enhanced_soft_blockages               -value true

if { $SET_QOR_STRATEGY_CONG_EFFORT == "ultra" } {
    set_app_options -name place.coarse.cong_restruct_iterations                     -value 3
    set_app_options -name place.coarse.legalizer_driven_placement                   -value true
    set_app_options -name place.legalize.use_eol_spacing_for_access_check           -value true 
    set_app_options -name place.legalize.enable_variant_aware                       -value true
    set_app_options -name place.legalize.optimize_pin_access_same_row_variants      -value true
    set_app_options -name place.legalize.optimize_pin_access_allow_row_swap         -value true
    set_app_options -name place.legalize.optimize_pin_access_using_cell_spacing     -value true
}

#----------------------------------------------------------------
#-==============================================================
# compile
#-==============================================================
# for timing
set_app_options -name compile.initial_place.effort                              -value high
set_app_options -name compile.final_place.effort                                -value high

# for congestion
set_app_options -name compile.het.dtdp_congestion                               -value true
set_app_options -name compile.flow.enable_rde_post_DTDP                         -value true
set_app_options -name compile.initial_drc.global_route_based                    -value true
set_app_options -name compile.initial_opto.placement_congestion_effort          -value high
set_app_options -name compile.final_place.placement_congestion_effort           -value high

# for clock gating
if { $ICG_OPT_EST_LATENCY } {
    set_app_options -name opt.common.estimate_clock_gate_latency                    -value true
} else {
    set_app_options -name opt.common.estimate_clock_gate_latency                    -value false
}
if { $ICG_OPT_MERGE } {
    set_app_options -name compile.flow.merge_clock_gates                            -value true
} else {
    set_app_options -name compile.flow.merge_clock_gates                            -value false
}
if { $ICG_OPT_EARLY_CTS } {
    set_app_options -name compile.flow.optimize_icgs                                -value true
} else {
    set_app_options -name compile.flow.optimize_icgs                                -value false
}

# for logic opt
if { $USE_SCANFF } {
    set_app_options -name compile.seqmap.scan                                       -value true
} else {
    set_app_options -name compile.seqmap.scan                                       -value false
}
if { $USE_BOUNDARY_OPT } {
    set_app_options -name compile.flow.boundary_optimization                        -value true
    set_app_options -name compile.optimization.enable_hierarchical_inverter         -value true
} else {
    set_app_options -name compile.flow.boundary_optimization                        -value false
    set_app_options -name compile.optimization.enable_hierarchical_inverter         -value false
}
if { $USE_AUTOUNGROUP } {
    set_app_options -name compile.flow.autoungroup                                  -value true
} else {
    set_app_options -name compile.flow.autoungroup                                  -value false
}
if { $USE_SEQ_INVERSION } {
    set_app_options -name compile.seqmap.enable_output_inversion                    -value true
} else {
    set_app_options -name compile.seqmap.enable_output_inversion                    -value false
}
if { $USE_DEAD_LOGIC_OPT } {
    set_app_options -name compile.optimization.constant_and_unloaded_propagation_with_no_boundary_optimization \
                                                                                    -value true
    set_app_options -name compile.seqmap.enable_register_merging                    -value true
    set_app_options -name compile.seqmap.remove_constant_registers                  -value true
    set_app_options -name compile.seqmap.remove_unloaded_registers                  -value true
} else {
    set_app_options -name compile.optimization.constant_and_unloaded_propagation_with_no_boundary_optimization \
                                                                                    -value false
    set_app_options -name compile.seqmap.enable_register_merging                    -value false
    set_app_options -name compile.seqmap.remove_constant_registers                  -value false
    set_app_options -name compile.seqmap.remove_unloaded_registers                  -value false
}
if { $USE_HIGH_AREA_EFFORT } {
    set_app_options -name compile.flow.high_effort_area                             -value true
} else {
    set_app_options -name compile.flow.high_effort_area                             -value false
}
if { $USE_CCD } {
    set_app_options -name compile.flow.enable_ccd                                   -value true 
} else {
    set_app_options -name compile.flow.enable_ccd                                   -value false 
}


#----------------------------------------------------------------
#-==============================================================
# opt
#-==============================================================
# for restrucring, buffering
set_app_options -name opt.common.buffer_area_effort                             -value medium
set_app_options -name opt.common.buffering_for_advanced_technology              -value true

# for congestion
set_app_options -name opt.common.enable_rde                                     -value true

#----------------------------------------------------------------
#-==============================================================
# Other
#-==============================================================
# for power
set_app_options -name power.leakage_mode                                        -value average

# time
set_app_options -name time.enable_normalized_slack                              -value false
set_app_options -name time.high_fanout_net_threshold                            -value 10000
set_app_options -name time.report_timing_enable_through_path                    -value false

# no assign statement
set_app_options -name opt.port.eliminate_verilog_assign                         -value true

# prefix of new cells with opt
set_app_options -name opt.common.user_instance_name_prefix                      -value compile_

# uniquify naming
set_app_options -name design.uniquify_naming_style -value                       "${TOP_DESIGN}_%s_%d"
set_app_options -name compile.datapath.module_name_prefix -value                "${TOP_DESIGN}_"
