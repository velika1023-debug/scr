###################################################################################################
# File               : before_initial_map.tcl                                                     #
# Author             : ADT-DT (jblee)                                                             #
# Description        : Things the user can control before initial_map                             #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################
foreach scn_name $SCENARIO_NAMES {

    if { $USE_MCMM } {  
        current_scenario $scn_name
    }

    #################################################################################
    # Please modify constraint
    # User constraint
    #################################################################################
    # Default
    set FILE_dont_touch      ${RUN_DIR}/con/user_dont_touch.tcl
    set FILE_dont_use        ${RUN_DIR}/con/user_dont_use.tcl
    set FILE_size_only       ${RUN_DIR}/con/user_size_only.tcl
     
    # # User Define
    # set FILE_set_svp         ${RUN_DIR}/con/${TOP_DESIGN}.set_svp.tcl
    # set FILE_volt_file       ${RUN_DIR}/con/${TOP_DESIGN}.set_voltage.tcl
    # set FILE_latency         ${RUN_DIR}/con/${TOP_DESIGN}.latency.tcl
    # set FILE_power_hookup    ${RUN_DIR}/con/${TOP_DESIGN}.power_hookup.tcl
    # set FILE_set_group       ${RUN_DIR}/con/${TOP_DESIGN}.set_group.tcl
       
    if {[ file exist ${FILE_dont_touch}   ] } { source -e -v ${FILE_dont_touch}   } else { puts "Warning_ADF : Nof Found File --> $FILE_dont_touch"   }
    if {[ file exist ${FILE_dont_use}     ] } { source -e -v ${FILE_dont_use}     } else { puts "Warning_ADF : Nof Found File --> $FILE_dont_use"     }
    if {[ file exist ${FILE_size_only}    ] } { source -e -v ${FILE_size_only}    } else { puts "Warning_ADF : Nof Found File --> $FILE_size_only"    }
     
    # if {[ file exist ${FILE_set_svp}      ] } { source -e -v ${FILE_set_svp}      } else { puts "Warning_ADF : Nof Found File --> $FILE_set_svp"      }
    # if {[ file exist ${FILE_volt_file}    ] } { source -e -v ${FILE_volt_file}    } else { puts "Warning_ADF : Nof Found File --> $FILE_volt_file"    }
    # if {[ file exist ${FILE_latency}      ] } { source -e -v ${FILE_latency}      } else { puts "Warning_ADF : Nof Found File --> $FILE_latency"      }
    # if {[ file exist ${FILE_power_hookup} ] } { source -e -v ${FILE_power_hookup} } else { puts "Warning_ADF : Nof Found File --> $FILE_power_hookup" }
    # if {[ file exist ${FILE_set_group}    ] } { source -e -v ${FILE_set_group}    } else { puts "Warning_ADF : Nof Found File --> $FILE_set_group"    }
    
}

###################################################################################################
# Auto dont_use_track cell 
###################################################################################################
set dont_use_track_cell_list "${OUTFD_DIR}/common/dont_use_track_cell/${ABS_PRIM_VERSION}/${DK_TYPE}_${TRACK}_dont_use.track.list"
if { [file exists $dont_use_track_cell_list ] } { 
	puts "Information_ADF: File exists. --> $dont_use_track_cell_list"
	puts "Information_ADF: Apply the file."
	puts "Information_ADF: dont_use_track_cell_list begin"
	set FILE [open $dont_use_track_cell_list "r"] ; set i 1 
	while { [gets $FILE line ] >= 0 } {
		if { [regexp "^#" $line] } { 
			continue 
		} else {
			set CellRefName [lindex $line 0]
			set CmdLine "set_lib_cell_purpose -include none \[get_lib_cells */${CellRefName} \]"
			catch { get_lib_cells */${CellRefName} } CellRefNameFull ErrMsg 
			
			if { [sizeof_collection $CellRefNameFull] == 1 } { 
				puts "Information_ADF: PASS ($i) --> $CmdLine " ; eval $CmdLine
			} else { 
				puts "Waring_ADF: FAIL ($i) --> $CmdLine"
			}
			incr i
		}
	}
	close $FILE
	puts "Information_ADF: dont_use_track_cell_list end"

} else { 
	puts "Error_ADF: File does not exists. --> $dont_use_track_cell_list"
	puts "Error_ADF: Please request Project DK Manager to create it."
}


###################################################################################################
#-- Define MAX fanout 
#-- user_max_fanout define user define
#-- ex> set_max_fanout $user_max_fanout [current_design]
###################################################################################################
if {$user_max_fanout != "0"} {
    set_app_options -name opt.common.max_fanout -value $user_max_fanout
}

#################################################################################
# Check User Dont touch, Use, Sizeonly constraint
# If this Tcl script is not sourced, the summary report may not be generated correctly
#################################################################################
source ${COMMON_TCL}/fc_syn/check_con.tcl

# define vth group, DO NOT EDIT!!
unset -nocomplain DESIGN_VTH
foreach vth {HVT HVT_WIMPY RVT RVT_WIMPY MVT MVT_WIMPY LVT LVT_WIMPY VLVT VLVT_WIMPY SLVT SLVT_WIMPY ULVT ULVT_WIMPY} {
    if {[info exists LIB_PATTERN($vth)] && [set LIB_PATTERN($vth)] != ""} {
        set tmp [get_lib_cells -quiet $LIB_PATTERN($vth) -f "view_name!=frame"]

        if {[sizeof_collection $tmp]} {
            lappend DESIGN_VTH $vth
            foreach_in_collection j $tmp { set_attr $j threshold_voltage_group $vth }
        }
    } else {
        puts "Warning_ADF: The pattern of lib_cell is not specified - LIB_PATTERN($vth)"
    }
}
if { [info exists DESIGN_VTH] && [llength $DESIGN_VTH] > 0 } { puts "Information_ADF: Set Vth Group - $DESIGN_VTH" }


###################################################################################################
#-- Define low vth percetage limit and cost type for leakage power
#-- If you want to change the range of 'low_vt', modify the vth range inside the braces '{}'
###################################################################################################
#set_threshold_voltage_group_type -type low_vt    {VLVT VLVT_WIMPY SLVT SLVT_WIMPY ULVT ULVT_WIMPY}
#set_threshold_voltage_group_type -type normal_vt {HVT HVT_WIMPY RVT RVT_WIMPY MVT MVT_WIMPY LVT LVT_WIMPY}
#set_multi_vth_constraint -low_vt_percentage 10 -cost cell_count
#report_multi_vth_constraint
#puts "Information_ADF: Voltage Group Setting"


###################################################################################################
# place_spacing_rules Loading Control
#   - Checks whether ${PROCESS}.place_spacing_rules.tcl exists.
#   - If present, the rule file is sourced and a message is printed.
###################################################################################################
if { [file exists ${PRJ_FC}/${PROCESS}.place_spacing_rules.tcl] } {
	puts "Information_ADF: Using place_spacing_rules"
	source -e -v ${PRJ_FC}/${PROCESS}.place_spacing_rules.tcl
} else {
	puts "Warning_ADF: Not using place_spacing_rules"
}
