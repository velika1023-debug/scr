###################################################################################################
# File               : proc_ungroup.tcl                                                           #
# Author             : ADT-DT (Ben)                                                               #
# Description        : Ungroup procedure                                                          #
# Usage              :                                                                            #
# Init Release Date  : 2025.04.30                                                                 #
# Last Update  Date  : 2025.04.30                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.04.30 - first released                                                             #
#                                                                                                 #
###################################################################################################

proc customUngroup { minThreshold } {

    if { $minThreshold > 0 } {
        set ungroupCount 0
        foreach_in_collection itr [get_designs *] {
            set allcells [get_cells -hierarchical -filter "ref_name =~ [get_object_name $itr] && full_name !~ *persistent* && full_name !~ *tessent* && full_name !~ *dft*"]
            set leaf_cell_count [sizeof_collection [get_cells [lindex [get_object_name [split [get_cells $allcells] "{}"]] 0]/* -filter "ref_name !~ \*\*logic_?\*\*"]]
            if { $leaf_cell_count < ${minThreshold} } {
               foreach_in_collection  cellName $allcells {

           if { $ungroupCount == 0 } {
              puts [format "%-5s | %-70s | %-13s" "Idx" "Ungroup Cell Name" "Num Of Leaf Cells"]
              puts [string repeat "-" 95]
          }

          puts [format "%-5d | %-70s | %-13d" $ungroupCount [get_object_name $cellName] $leaf_cell_count]
                    set_ungroup [get_cells [get_object_name $cellName]] true
                    incr ungroupCount

                }
            }
        }

        puts "Information : Ungrouped $ungroupCount hierarchical cells as leaf cell count was "
        puts "              below the threshold of $minThreshold"
        puts "\n"

        set allCells            [get_cells -hier * -filter { is_hierarchical == true }]
        set allUngroupTrueCells [get_cells -hier * -filter { is_hierarchical == true && ungroup == true }]
        set allUngroupFalseCells [remove_from_collection $allCells $allUngroupTrueCells]
        set_ungroup $allUngroupFalseCells false
    }
}

# dc_shell>> customUngroup 1500
