###################################################################################################
# File               : restore.tcl                                                                #
# Author             : ADT-DT (jblee)                                                             #
# Description        : restore design                                                             #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################

#################################################################################
# User Variable settings
#################################################################################
puts "Information_ADF : Setting environmental variables defined in user_design_setup.tcl "
source -echo -verbose ${RUN_DIR}/con/user_design_setup.tcl

#################################################################################
# FC Option setting
#################################################################################
puts "Information_ADF : Setting FC environmental option  "
source -echo -verbose ${COMMON_FC_SYN}/0_fc_setup.tcl

#################################################################################
# Design Setup
#################################################################################
set NDM_DESIGN_LIB "${TOP_DESIGN}.nlib"
open_block ${OUTPUT_DIR}/$NDM_DESIGN_LIB:${TOP_DESIGN} ; link_block

puts "Information_ADF : Restore Design"
return
