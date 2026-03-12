###################################################################################################
# File               : clock_gating_setup.tcl                                                     #
# Author             : ADT-DT (jblee)                                                             #
# Description        : Clock gating setting                                                       #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################
# purpose setting
set_lib_cell_purpose -exclude {hold cts} [get_lib_cells */*]
set_dont_touch [get_lib_cells -q $ICG_NAME -f is_integrated_clock_gating_cell] false
set_lib_cell_purpose -include cts [get_lib_cells -q $ICG_NAME -f is_integrated_clock_gating_cell]

# Prevent inferring ICG for negative-edge triggered flops
set NEG_FF_CELL [get_cells [all_registers] -filter "is_fall_edge_triggered"]
if {[sizeof $NEG_FF_CELL] > 0} {set_clock_gating_objects -exclude $NEG_FF_CELL}

# test point, register target
set_clock_gate_style -test_point before -target pos_edge_flip_flop

# mim/max fanout
if {[info exist MIN_ICG_FANOUT] && $MIN_ICG_FANOUT != ""} {
    set cmd "set_clock_gating_options -minimum_bitwidth \$MIN_ICG_FANOUT"
} else {
    set cmd "set_clock_gating_options -minimum_bitwidth 3"
}
if {[info exist MAX_ICG_FANOUT] && $MAX_ICG_FANOUT != ""} {append cmd " -max_fanout \$MAX_ICG_FANOUT"}
eval $cmd

# max level
if {[info exist ICG_STAGES] && $ICG_STAGES != ""} {
    set_clock_gating_tree_options -max_total_levels $ICG_STAGES
}
