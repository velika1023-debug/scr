################################################################################
# File Name     : output_write_sdc.tcl
# Author        : iskim1001
# Creation Date : 2023-09-07 
# Last Modified : 2025-05-09 
# Version       : v0.2
# Location      : ${PRJ_PT}/design_scripts/run_sta.tcl
#-------------------------------------------------------------------------------
# Description   : Create SDC
#-------------------------------------------------------------------------------
# Change Log    :
# 	[2023-09-07 v0.1] : Initial Version Release
# 	[2025-05-09 v0.2] : Change sdc naming for PnR
#-------------------------------------------------------------------------------
# Useage        :
# 	pt_shell > source output_write_sdc.tcl
#################################################################################

#------------------------------------------------------------------------------
# Create sdc
#------------------------------------------------------------------------------
puts "Geneated SDC File"
    write_sdc -nosp  ${OUTPUT_DIR}/${DESIGN}.${MODE}-${typ_volt}.${CORNER}.sdc
	if { [file exists ${OUTPUT_DIR}/${DESIGN}.${MODE}-${typ_volt}.sdc] } {
		exec unlink ${OUTPUT_DIR}/${DESIGN}.${MODE}-${typ_volt}.sdc
	}
exec ln -s ./${DESIGN}.${MODE}-${typ_volt}.${CORNER}.sdc ${OUTPUT_DIR}/${DESIGN}.${MODE}-${typ_volt}.sdc
exec touch done.sdc

set PRatio_CLK  0.1
set PRatio_DATA 0.4

source -e -v  ${COMMON_TCL_PT}/compare_max_transition_lib_vs_constraint.tcl
