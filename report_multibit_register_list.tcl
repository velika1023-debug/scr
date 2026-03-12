# ?2015 Synopsys, Inc.  All rights reserved.             
#                                                                  
# This script is proprietary and confidential information of        
# Synopsys, Inc. and may be used and disclosed only as authorized   
# per your agreement with Synopsys, Inc. controlling such use and   
# disclosure.                                                       
#     

proc report_multibit_register_list {} {
	puts "\n"
	puts [format "%-35s %8s %22s \t %-30s" "MB_cell_name" "MB_ref_name" "MB_width" " MB_register_list"]
        puts "------------------------------------------------------------------------------------------"

	foreach_in_collection mb_reg [get_cells -hier -f "multibit_width >1"] {
      		set mb_name [get_attribute [get_cell  $mb_reg] name]
      		set mb_ref_name [get_attribute [get_cell $mb_reg] ref_name]
      		set mb_width [get_attribute [get_lib_cell */$mb_ref_name] multibit_width]
        	set mb_reg_list [get_attribute [get_cell $mb_reg] register_list]
        	set mb_reg_full [get_attribute [get_cell $mb_reg] full_name]
	        puts [format "%-30s \t %30s  %1s \t %-20s  " $mb_reg_full $mb_ref_name $mb_width $mb_reg_list ]  
		puts "\n"
		         }

}
