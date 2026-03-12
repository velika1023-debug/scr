###################################################################################################
# File               : proc_multibit_register_list.tcl                                            #
# Author             : ADT-DT (jmpark)                                                            #
# Description        : Multibit register list                                                     #
# Usage              :                                                                            #
# Init Release Date  : 2024.10.01                                                                 #
# Last Update  Date  : 2024.10.01                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.01.16 - first released                                                             #
###################################################################################################
proc rpt_multibit_register_list {args} {
    global sh_product_version
    global sh_dev_null
    parse_proc_arguments -args $args results

    redirect $sh_dev_null {set Design [get_object_name [current_design]]}
    if {$Design == ""} {
        return -code error "Current design is not defined"
    }

    #-======================================
    # Main Step
    #-======================================

    #puts "  Outfile name : $outfile"
	puts ""
	puts [format "%-35s %8s %22s \t %-30s" "MB_cell_name" "MB_ref_name" "MB_width" " MB_register_list"]
    puts "------------------------------------------------------------------------------------------"

	foreach_in_collection mb_reg [get_cells -hier -f "multibit_width >1"] {
        set mb_name     [get_attribute [get_cell $mb_reg] name]
        set mb_ref_name [get_attribute [get_cell $mb_reg] ref_name]
        set mb_width    [get_attribute [get_lib_cell */$mb_ref_name] multibit_width]
        set mb_reg_list [get_attribute [get_cell $mb_reg] register_list]
        set mb_reg_full [get_attribute [get_cell $mb_reg] full_name]
        puts [format "%-30s \t %30s  %1s \t %-20s  " $mb_reg_full $mb_ref_name $mb_width $mb_reg_list ]
        puts ""
	}

}
