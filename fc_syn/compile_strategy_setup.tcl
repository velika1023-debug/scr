###################################################################################################
# File               : compile_strategy_setup.tcl                                                 #
# Author             : ADT-DT (jblee)                                                             #
# Description        : Define the option user needs                                               #
# Usage              : Sourcing this file is included in 'main.tcl' file                          #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################
set SET_QOR_STRATEGY_METRIC         "timing"   ; # timing   | leakage_power | total_power ; It is a mandatory to active leakage/dynamic power scenario for leakage_power/total_power metric
set SET_QOR_STRATEGY_MODE           "balanced" ; # balanced | extreme_power | early_design; The settings will be configured for the target mode
set SET_QOR_STRATEGY_REDUCE_EFFORT  "false"    ; # Reduces effort for fast runtime; this command only works when mode is set to 'balanced'
set SET_QOR_STRATEGY_HET            "false"    ; # Increases effort for timing; Set it to true to enable '-high_effort_timing' option
set SET_QOR_STRATEGY_CONG_EFFORT    "medium"   ; # medium | high | ultra; Specifies the congestion flow effort level


#Strategy-Info: Metric(s) : timing
#+----------------------------------------------------+---------------+------------+------------+------------+
#|           Option Name                              | Metric Group  |  Tool      |  Current   |  Target    |
#|                                                    |               |  Default   |  Setting   |  Setting   |
#+----------------------------------------------------+---------------+------------+------------+------------+
#| time.enable_clock_to_data_analysis                 | *All metrics* | false      | false      | true       |
#| place.common.use_placement_model                   | *All metrics* | false      | false      | true       |
#| place.coarse.pin_density_aware                     | *All metrics* | false      | false      | true       |
#| compile.final_place.effort                         | timing        | medium     | medium     | high       |
#| place.coarse.enhanced_low_power_effort             | timing        | low        | low        | none       |
#| compile.flow.enable_power                          | timing        | false      | false      | false      |
#+----------------------------------------------------+---------------+------------+------------+------------+
#
#Strategy-Info: Metric(s) : leakage_power
#+----------------------------------------------------+---------------+------------+------------+------------+
#|           Option Name                              | Metric Group  |  Tool      |  Current   |  Target    |
#|                                                    |               |  Default   |  Setting   |  Setting   |
#+----------------------------------------------------+---------------+------------+------------+------------+
#| time.enable_clock_to_data_analysis                 | *All metrics* | false      | false      | true       |
#| place.common.use_placement_model                   | *All metrics* | false      | false      | true       |
#| place.coarse.pin_density_aware                     | *All metrics* | false      | false      | true       |
#| compile.final_place.effort                         | leakage_power | medium     | medium     | high       |
#| place.coarse.enhanced_low_power_effort             | leakage_power | low        | low        | none       |
#| compile.flow.enable_power                          | leakage_power | false      | false      | true       |
#+----------------------------------------------------+---------------+------------+------------+------------+
#
#Strategy-Info: Metric(s) : total_power
#+----------------------------------------------------+---------------+------------+------------+------------+
#|           Option Name                              | Metric Group  |  Tool      |  Current   |  Target    |
#|                                                    |               |  Default   |  Setting   |  Setting   |
#+----------------------------------------------------+---------------+------------+------------+------------+
#| time.enable_clock_to_data_analysis                 | *All metrics* | false      | false      | true       |
#| place.common.use_placement_model                   | *All metrics* | false      | false      | true       |
#| place.coarse.pin_density_aware                     | *All metrics* | false      | false      | true       |
#| compile.final_place.effort                         | total_power   | medium     | medium     | high       |
#| place.coarse.enhanced_low_power_effort             | total_power   | low        | low        | medium     |
#| compile.flow.enable_power                          | total_power   | false      | false      | true       |
#| compile.flow.enable_multibit                       | total_power   | false      | true       | true       |
#| place_opt.flow.enable_multibit_debanking           | total_power   | false      | false      | true       |
#+----------------------------------------------------+---------------+------------+------------+------------+

#################################################################################
# Apply optimization metrics using set_qor_strategy
#################################################################################
set set_qor_strategy_cmd "set_qor_strategy -stage synthesis -metric \"$SET_QOR_STRATEGY_METRIC\" -mode \"$SET_QOR_STRATEGY_MODE\""
if { $SET_QOR_STRATEGY_REDUCE_EFFORT } { 
    lappend set_qor_strategy_cmd -reduced_effort
} elseif { $SET_QOR_STRATEGY_HET } { 
    lappend set_qor_strategy_cmd -high_effort_timing 
}
lappend set_qor_strategy_cmd -congestion_effort $SET_QOR_STRATEGY_CONG_EFFORT

puts "Information_ADF: Running $set_qor_strategy_cmd"
eval ${set_qor_strategy_cmd}
