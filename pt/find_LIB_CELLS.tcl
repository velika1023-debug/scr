################################################################################
# File Name     : find_LIB_CELLS.tcl
# Author        : DT-PI
# Last Modified : 2024-11-11
# Version       : v0.3
# Location      : $PRJ_PT/design_scripts/run_sta.tcl
#-------------------------------------------------------------------------------
# Description   :
#	You can check the value of the declared _LIB_CELL(*) variable in set_ocv_margin.log.
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-01-19] : iskim1001
#       - Initial Version Release
# 	v0.2 [2024-05-24] : iskim1001
#   	- ADF Message Rule Change
#       	Before : <ADF_ERROR>: , <ADF_WARN>:  , <ADF_INFO>:
#       	After  : Error_ADF:   , Warning_ADF: , Information_ADF:
# 	v0.3 [2024-05-24] : iskim1001, jjh8744
#   	- foreach_in_collection bug fix (Not find $VALUE variable)
#			VALUE => $_LIB_CELLS($key)
#		- Added HVT to the order variable.
# 	v0.4 [2024-11-11] : iskim1001
#   	- Add set _LIB_CELLS variable
#-------------------------------------------------------------------------------
# Useage        :
# 	pt_shell > source find_LIB_CELLS.tcl
#################################################################################

# Retrieve the list of keys from the array
set keys [array names _LIB_CELLS]

# Define the sorting order using regular expressions
set order {^HVT ^RVT ^LVT ^SLVT}

#################################################################################
# proc customOrderCompare
#################################################################################
# Define the custom comparison function for sorting
proc customOrderCompare {a b} {
    global order

    # Initialize indexes for the keys
    set indexA -1
    set indexB -1

    # Determine the index of each key in the order list using regex
    foreach pattern $order {
        if {$indexA == -1 && [regexp $pattern $a]} { set indexA [lsearch -exact $order $pattern] }
        if {$indexB == -1 && [regexp $pattern $b]} { set indexB [lsearch -exact $order $pattern] }
    }

    # Assign a high index for keys not found in the order list to push them to the end
    if {$indexA == -1} { set indexA [llength $order] }
    if {$indexB == -1} { set indexB [llength $order] }

    # Compare the indexes to determine the sort order
          if {$indexA < $indexB} { return -1
    } elseif {$indexA > $indexB} { return 1
    } else {
        # If the indexes are the same, use alphabetical order as the second sorting criteria
        return [string compare $a $b]
    }
}


#################################################################################
# Main script
#################################################################################
# Sort the key list using the custom comparison function
set sortedKeys [lsort -command customOrderCompare $keys]

if {[array exists _LIB_CELLS]} {
	set fname     ${LOG_DIR}/set_ocv_margin.log__LIB_CELL_detail
	set openfname [open  $fname "w"]
	set dk_name_temp ""

	#Summary Header
	foreach key $sortedKeys {
		puts $openfname "[format "%-60s : %s " \$_LIB_CELLS($key)  [sizeof_collection $_LIB_CELLS($key) ]  ]"
	}
	puts $openfname ""
	puts $openfname ""

    ;# Main
    foreach key $sortedKeys {
        set lib_cnt "[sizeof_collection $_LIB_CELLS($key)]"

        puts $openfname "\$_LIB_CELLS($key) : $lib_cnt lib_cells"

        foreach_in_collection value $_LIB_CELLS($key) {
            set base_name [get_attribute [get_lib_cells $value] base_name ]
            set full_name [get_attribute [get_lib_cells $value] full_name ]

            puts $openfname [format "%50s : %45s : %s" "\$_LIB_CELLS($key)" $base_name $full_name]
        }
        puts $openfname ""
    }
	
	# for PD 
    foreach key $sortedKeys {
		set temp_value_list ""
		foreach_in_collection value $_LIB_CELLS($key) {
			set temp [get_attribute [get_lib_cells $value] full_name ]
			set temp_split [lindex  [split $temp "/"] 0 ]
            lappend  temp_value_list $temp_split
		}
		set temp_value_list [lsort -u $temp_value_list]
		foreach itr $temp_value_list  {
			puts $itr
        	#puts [format "set %50s   %s" "\$_LIB_CELLS($key)" $itr]
        	puts $openfname "set _LIB_CELLS($key) $itr "
		}
	}



close $openfname
} else {
	puts "Error_ADF: _LIB_CELLS Array Not Found"
	puts "Error_ADF: _LIB_CELLS Array Not Found"
	puts "Error_ADF: _LIB_CELLS Array Not Found"
}
