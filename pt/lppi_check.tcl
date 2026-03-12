################################################################################
# File Name     : lppi_check.tcl
# Author        : DT-PI
# Creation Date : 2024-05-13
# Last Modified : 2024-05-13 
# Version       : v0.1
# Location      : ${PRJ_PT}/design_scripts/run_sta.tcl 
#-------------------------------------------------------------------------------
# Description   : Check whether design is linked only to the DBs defined in the LPPI_LIB variable.
#-------------------------------------------------------------------------------
# Change Log    :
# 	[2024-02-02 v0.1] : Initial Version Release
# 	[2024-07-03 v0.2] : The checking method has been changed.
#-------------------------------------------------------------------------------
# Useage        :
#		pt_shell> source lppi_check.tcl
#################################################################################

foreach BLK ${READ_DESIGN} {
	if { [info exist ${BLK}(POWER_DOMAIN_VOLTAGE_INFO)] && [set ${BLK}(POWER_DOMAIN_VOLTAGE_INFO)] != "" } {
		sh rm -rf ${RPT_DIR}/lppi_check.rpt
		foreach INFO [set ${BLK}(POWER_DOMAIN_VOLTAGE_INFO)] {
			# Power lppi
			set INFO            [regsub -all "{|}" $INFO ""]
			set BLK_INST        [lindex $INFO 0			   ]
			set BLK_DOMAIN_INFO [regsub "p" [lindex $INFO 1] "."]
	
			echo "#################################################################################"  >> ${RPT_DIR}/lppi_check.rpt
			echo "# Design name   : ${BLK}"															  >> ${RPT_DIR}/lppi_check.rpt
			echo "# Instance name : ${BLK_INST}"													  >> ${RPT_DIR}/lppi_check.rpt
			echo "# Voltage       : ${BLK_DOMAIN_INFO}"												  >> ${RPT_DIR}/lppi_check.rpt
			echo "#################################################################################"  >> ${RPT_DIR}/lppi_check.rpt
			echo ""																					  >> ${RPT_DIR}/lppi_check.rpt
			report_timing -th ${BLK_INST} -nos -vol -delay_type min_max -sig 4 -slack_lesser_than inf >> ${RPT_DIR}/lppi_check.rpt
			echo ""																					  >> ${RPT_DIR}/lppi_check.rpt
		}
	} else {
		puts "Information_ADF: \"${BLK}\" does not set link_path_per_instance."
	}
}


#v0.1 # Check link_path_per_instance
#v0.1 foreach BLK $SORT_BLK_NAME  {
#v0.1 	if { [info exist ${BLK}(POWER_DOMAIN_VOLTAGE_INFO)] && [set ${BLK}(POWER_DOMAIN_VOLTAGE_INFO)] != "" } {
#v0.1 		foreach INFO [set ${BLK}(POWER_DOMAIN_VOLTAGE_INFO)] {
#v0.1 			# Power lppi
#v0.1 			set INFO			[regsub -all "{|}" $INFO ""]
#v0.1 			set BLK_INST        [lindex $INFO 0			   ]
#v0.1 			set BLK_DOMAIN_INFO [lindex $INFO 1			   ]
#v0.1 
#v0.1 			set check_lib_cell [get_attr [get_cells -hierarchical -filter "is_hierarchical==false && full_name =~ ${BLK_INST}/*"] lib_cell]
#v0.1 			set uniq_check_lib_cell [add_to_collection $check_lib_cell $check_lib_cell -unique]
#v0.1 			set use_lib_list ""
#v0.1 			foreach_in_collection lib_cell $uniq_check_lib_cell {
#v0.1 				set lib_cell_fname [get_object_name $lib_cell]
#v0.1 				set lib_name [lindex [split $lib_cell_fname "/"] 0]
#v0.1 				lappend use_lib_list $lib_name
#v0.1 			}
#v0.1 			set use_lib_list [lsort -decreasing -unique $use_lib_list]
#v0.1 		}
#v0.1 
#v0.1 		set remain_list "$use_lib_list"
#v0.1 		foreach remain_db $remain_list {
#v0.1 			foreach LPPI_LIB [set ${BLK}(LPPI_LIB)] {
#v0.1 				if { $LPPI_LIB != "*"} {
#v0.1 					set cmd "filter_collection \[get_libs\] {source_file_name == $LPPI_LIB}"
#v0.1 					set cmd_result [eval $cmd]
#v0.1 					if { $cmd_result != "" } {
#v0.1 						set LPPI_LIB_NAME [get_object_name [eval $cmd]]
#v0.1 						if { [lsearch -exact $LPPI_LIB_NAME $remain_db] == "0" } {
#v0.1 				   			regsub $LPPI_LIB_NAME $remain_list "" remain_list
#v0.1 				   		}
#v0.1 					}
#v0.1 				}
#v0.1 			}
#v0.1 		}
#v0.1 		
#v0.1 		if { [llength $remain_list] > 0 } {
#v0.1 			puts ""
#v0.1         	puts "#####################################################################"
#v0.1         	puts "## HIER_DESIGN        : $BLK"
#v0.1         	puts "## SUB_INSTANCE       : $BLK_INST"
#v0.1         	puts "## SUB_VOLTAGE_DOMAIN : $BLK_DOMAIN_INFO\($BLK_VOLTAGE_INFO\)"
#v0.1         	puts "## SUB_DK_TYPE        : $SUB_DK_TYPE($BLK)"
#v0.1         	puts "## SUB_DK_NAME        : $sub_track($BLK)"
#v0.1         	puts "#####################################################################"
#v0.1         	puts "# The DBs below are undefined for the ${BLK}(LPPI_LIB) variable."
#v0.1         	puts "# Need to check which cells are linked to the DBs below."
#v0.1 			foreach db_list $remain_list {
#v0.1 				echo "  $db_list"
#v0.1 			}
#v0.1 		}
#v0.1 	}
#v0.1 }
