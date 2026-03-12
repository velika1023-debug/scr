###################################################################################################
# File               : before_logic_opto.tcl                                                      #
# Author             : ADT-DT (jblee)                                                             #
# Description        : Things the user can control before logic_opto                              #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################
#################################################################################
## Setting for expand_level of ICG (Do not edit!!)
#################################################################################
if { $ICG_OPT_LEVEL_EXP == "false" } {
    set_clock_gate_transformations -expand_levels false [get_cells -hier -f "!is_hierarchical && ref_name =~ *PREICG*"] true
    puts "Information_ADF: Limit level expansion of ICG!!"
}
