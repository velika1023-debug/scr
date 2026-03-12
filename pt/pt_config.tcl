################################################################################
# File Name     : pt_config.tcl
# Author        : DT-PI
# Creation Date : 2024-05-13 
# Last Modified : 2024-05-13 
# Version       : v0.1
# Location      : ${PRJ_PT}/design_scripts/run_sta.tcl
#-------------------------------------------------------------------------------
# Description   : configuration file for PrimeTime flow
#-------------------------------------------------------------------------------
# Change Log    :
# 	[2024-05-13 v0.1] : Initial Version Release
#-------------------------------------------------------------------------------
# Useage        :
#   pt_shell > source pt_config.tcl
#################################################################################

if {[info exists gen_twf] && $gen_twf } {
	#set ADS_ALLOWED_PCT_OF_NON_CLOCKED_REGISTERS "10"	;# If the timing window file is not made due to many no clock FFs, increase the value.
}
