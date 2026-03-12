
###################################################################################################
# File               : name_rule_setup.tcl                                                       #
# Author             : ADT-DT (jblee)                                                             #
# Description        : naming rule setting                                                         #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.27                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.27 - first released                                                             #
###################################################################################################

#******************************************************************************
# define_name_rules
#******************************************************************************
# during change_names
define_name_rules sec_verilog -type port \
                              -equal_ports_nets \
                              -allowed {A-Z a-z 0-9 _ [] !} \
                              -first_restricted {0-9 _ !} \
                              -last_restricted {_ !} \
                              -map {{"_$","_0"}}
define_name_rules sec_verilog -type net \
                              -equal_ports_nets \
                              -allowed {A-Z a-z 0-9 _ !} \
                              -first_restricted {0-9 _ !} \
                              -last_restricted {_ !} \
                              -map {{"_$","_0"}}
define_name_rules sec_verilog -type cell \
                              -allowed {A-Z a-z 0-9 _ !} \
                              -first_restricted {0-9 _ !} \
                              -last_restricted {_ !} \
                              -map {{"_$","_0"}}

define_name_rules verilog -case_insensitive -dont_change_ports


#******************************************************************************
# app_option
#******************************************************************************
# during uniquify
set_app_options -name design.uniquify_naming_style -value                       "${TOP_DESIGN}_%s_%d"

# during compile_fusion
set_app_options -name compile.datapath.module_name_prefix -value                "${TOP_DESIGN}_"
