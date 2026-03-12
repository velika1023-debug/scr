#################################################################################################
##                                                                                             ##
## SAMSUNG FOUNDRY RESERVES THE RIGHT TO CHANGE PRODUCTS, INFORMATION AND SPECIFICATIONS       ##
## WITHOUT NOTICE.                                                                             ##
##                                                                                             ##
## No part of this publication may be reproduced, stored in a retrieval system, or transmitted ##
## in any form or by any means, electric or mechanical, by photocopying, recording,            ##
## or otherwise, without the prior written consent of Samsung. This publication is intended    ##
## for use by designated recipients only. This publication contains confidential information   ##
## (including trade secrets) of Samsung protected by Competition Law, Trade Secrets Protection ## 
## Act and other related laws, and therefore may not be, in part or in whole, directly or      ##
## indirectly publicized, distributed, photocopied or used (including in a posting on the      ##
## Internet where unspecified access is possible) by any unauthorized third party. Samsung     ##
## reserves its right to take any and all measures both in equity and law available to it and  ##
## claim full damages against any party that misappropriates Samsung's trade secrets and/or    ##
## confidential information                                                                    ##
##                                                                                             ##
## All brand names, trademarks and registered trademarks belong to their respective owners.    ##
##                                                                                             ##
## 2021 Samsung Foundry                                                                        ##
##                                                                                             ##
#################################################################################################
##                                                                                             ##
## Title                : read_design.tcl                                                      ##
## Description          : read and link design                                                 ##
## Process              : Any SEC Process                                                      ##
## Author               : Deokkeun Oh, Chul Rim                                                ##
## Initial Release Date : Mar. 31, 2016                                                        ##
## Last Update Date     : Jun. 11, 2021                                                        ##
## Script Version       : V1.00                                                                ##
## Usage                : pt_shell> source read_design.tcl                                     ##
## Tool Version         : SEC guided PrimeTime version                                         ##
##                                                                                             ##
#################################################################################################

;#------------------------------------------------------------------------------
;# import netlists 
;#------------------------------------------------------------------------------
#DM_ORG foreach fname $NETLISTS {
#DM_ORG   if {[info exist WAIT_FOR_FILE] && $WAIT_FOR_FILE} {
#DM_ORG     set ack_file	"${fname}.ack"
#DM_ORG     sec_wait_for_ack_file $ack_file
#DM_ORG     if {![file exist $fname]} {
#DM_ORG       echo "** SEC_ERROR: ack file exist but actual file not found - $fname"
#DM_ORG       exec touch :ERROR:ABNORMAL_EXIT; if {![info exist EXIT_ON_SCRIPT_ERROR] || $EXIT_ON_SCRIPT_ERROR} { exit -1 }
#DM_ORG     }
#DM_ORG   }
#DM_ORG   echo "** Info: reading netlist file - $fname"
#DM_ORG   read_verilog $fname
#DM_ORG }
#==============================================================================
# DT-PI_Add : Change the method for reading designs.
#==============================================================================
foreach DB_LIST $READ_DB_LISTS {
	set BLK_NAME [lindex [split ${DB_LIST} ,] 0]
	set BLK_TYPE [lindex [split ${DB_LIST} ,] 1]
	set BLK_PATH [lindex [split ${DB_LIST} ,] 2]

	set fname "$BLK_PATH"
	if {![file exist $fname]} {
		echo "** SEC_ERROR: ack file exist but actual file not found - $fname"
		exec touch :ERROR:ABNORMAL_EXIT; exit -1
	}

	if { $BLK_TYPE == "NET" } {
		;#------------------------------------------------------------------------------
		;# import netlists
		;#------------------------------------------------------------------------------
		 echo "Information_ADF: reading netlist file - $fname"
		 read_verilog $fname

	} elseif { $BLK_TYPE == "ETM" } {
		;#------------------------------------------------------------------------------
		;# import etmlists
		;#------------------------------------------------------------------------------
		 echo "Information_ADF: reading etm file - $fname"
		 read_db $fname

	} elseif  { $BLK_TYPE == "HSC" } {
		;#------------------------------------------------------------------------------
		;# import hsclists
		;#------------------------------------------------------------------------------
		 echo "Information_ADF: reading hsc file - $fname"
		 set_app_var hier_enable_analysis true
		 set_app_var timing_save_hier_context_data false

		 set_hier_config -block ${BLK_NAME} -path $fname
	} else { 
		echo "Error_ADF: Please Check BLK_TYPE Variable ...."
		echo "Error_ADF: Please Check BLK_TYPE Variable ...."
		echo "Error_ADF: Please Check BLK_TYPE Variable ...."
		echo "Error_ADF: Please Check BLK_TYPE Variable ...."
		echo "Error_ADF: Please Check BLK_TYPE Variable ...."
		echo "Error_ADF: Please Check BLK_TYPE Variable ...."
		exec touch :ERROR:ABNORMAL_EXIT; exit -1
	}
}

# ;#------------------------------------------------------------------------------
# ;# linking design
# ;#------------------------------------------------------------------------------
# echo "** SEC_INFO: linking design - $TOP_DESIGN"
# echo "** SEC_INFO: search path is: $search_path"
# redirect -tee ${LOG_DIR}/link_design.log {
#   current_design $TOP_DESIGN
#   link -verbose
# }
# 
# ;#------------------------------------------------------------------------------
# ;# check if design is properly linked
# ;#------------------------------------------------------------------------------
# set link_fail 	0 	
# if {[set num_msg [get_message_count "LNK-001"]] > 0} {
#   echo "** SEC_ERROR: link_path file not found for $num_msg files (LNK-001)"
#   set link_fail 	1
# }
# if {[set num_msg [get_message_count "LNK-005"]] > 0} {
#   echo "** SEC_ERROR: $num_msg unresolved references (LNK-005)"
#   set link_fail 	1
# }
# if {$link_fail} {
#   echo "** SEC_ERROR: unresolved reference and/or broken link_path found during linking design."
#   echo "              check the log file - \${LOG_DIR}/link_design.log"
#   exec touch :ERROR_DURING_DESIGN_LINKING
# }
# 
