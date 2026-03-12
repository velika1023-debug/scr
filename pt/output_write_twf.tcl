################################################################################
# File Name     : output_write_twf.tcl
# Author        : iskim1001
# Last Modified : 2023-10-31
# Version       : v0.2
# Location      : ${PRJ_PT}/design_scripts/run_sta.tcl
#-------------------------------------------------------------------------------
# Description   : Create Timing Window
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-09-07] : iskim1001
#       - Initial Version Release
# 	v0.2 [2024-10-31] : iskim1001
#       - Command Change 
#       	|- getSTA --> write_rh_file 
#       - Refer Doc : /misc/dk/SEC/SF2/DM/Samsung_Foundry_SF2_ALLDK_Cell_Level_Static_IR_Drop_Analysis_RedHawk-SC_ApplicationNote_REV1.04.pdf ( 3.2.2 Generate STA File )
#-------------------------------------------------------------------------------
# Useage        :
#    pt_shell > source output_write_twf.tcl
#################################################################################

#------------------------------------------------------------------------------
# Create twf
#------------------------------------------------------------------------------
puts "Geneated Timing File"
#ORG     source ${STA_SCRIPT_DIR}/pt2timing.tcl
#ORG 	set fname "${STA_DIR}/../pt_config.tcl"
#ORG 	source_wrap -e -v $fname
#ORG     getSTA -noexit -o ${OUTPUT_DIR}/${DESIGN}.${MODE}.${CORNER}.timing
write_rh_file  -filetype irdrop  -significant_digits 6  \
			   -output ${OUTPUT_DIR}/${DESIGN}.${MODE}.${CORNER}.timing
exec touch done.twf
puts "Geneated Timing File End"
