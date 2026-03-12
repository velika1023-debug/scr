###################################################################################################
# File               : insert_MV_cell_setup.tcl                                                   #
# Author             : ADT-DT (jblee)                                                             #
# Description        : ManualMV cell insert                                                       #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################

#################################################################################
#  Insert MV Cells
#################################################################################
if {[file exist $IMPL_UPF]} {
    proc_time insert_mv_START 
    create_mv_cells -all -verbose > ${LOG_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.insert_mv_cells.log
    proc_time insert_mv_END 
}
