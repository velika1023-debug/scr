################################################################################
# File Name     : common_con.tcl
# Author        : jaeeun1115
# Last Modified : 2025-04-16
# Version       : v0.2
# Location      : $COMMON_IMPL_DIR/common_tcl/pt/comon_con.tcl
#-------------------------------------------------------------------------------
# Description   : check dont_touch, dont_use, size_only
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2025-02-24] : jaeeun1115
# 		- Initial Version Release
# 	v0.2 [2025-04-16] : jaeeun1115
# 		- Add dft stage & Remove default dont_use list
#-------------------------------------------------------------------------------
# Useage        :
#   pt_shell > source common_con.tcl
#################################################################################

if {[regexp -nocase {PRE} $PRE_POST]} {
    if {![file exists pd_info]} {sh mkdir pd_info}

    # dont_touch
    set out_dont_touch_net [open pd_info/${DESIGN}.dont_touch_net.tcl w+]
    set out_dont_touch_cell [open pd_info/${DESIGN}.dont_touch.tcl w+]

    if {[file exists [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.dft.user_dont_touch.rpt]} {
        set fname [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.dft.user_dont_touch.rpt
    } elseif {[file exists [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.final.user_dont_touch.rpt]} {
        set fname [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.final.user_dont_touch.rpt
    } elseif {[file exists [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.compile.user_dont_touch.rpt]} {
        set fname [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.compile.user_dont_touch.rpt]
    }

    if {[info exists fname] && [file exists $fname]} {
        set in_dont_touch [open $fname r]

        while {[gets $in_dont_touch line] >= 0} {
            if {[regexp "^net" $line]} {
                puts $out_dont_touch_net "[lindex $line 1]" 
            } elseif {[regexp "^cell" $line]} {
                puts $out_dont_touch_cell "[lindex $line 1]"
            }
        }
        unset fname
    } else {
        set DONT_TOUCH_CELL [get_cells -quiet -h -f "dont_touch==true"]
        set DONT_TOUCH_NET  [get_nets -quiet -h -f "dont_touch==true"]

        foreach_in_collection cell $DONT_TOUCH_CELL {
            puts $out_dont_touch_cell "[get_object_name $cell]"
        }
        foreach_in_collection net $DONT_TOUCH_NET {
            puts $out_dont_touch_net "[get_object_name $net]"
        }
    }
    close $out_dont_touch_net
    close $out_dont_touch_cell


    # dont_use
    if {[file exists [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.dft.user_dont_use.rpt]} {
        set fname [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.dft.user_dont_use.rpt
    } elseif {[file exists [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.final.user_dont_use.rpt]} {
        set fname [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.final.user_dont_use.rpt
    } elseif {[file exists [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.compile.user_dont_use.rpt]} {
        set fname [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.compile.user_dont_use.rpt
    }
    if {[info exists fname] && [file exists $fname]} {
        
        set out_dont_use [open pd_info/${DESIGN}.dont_use.tcl w+]
        set in_dont_use  [open $fname r] 

        while {[gets $in_dont_use line] >= 0} {
            if {[regexp {^#} $line]} { continue }
            puts $out_dont_use "[lindex [split $line "/"] end]"
        }
        unset fname
        close $out_dont_use
    } 


    # size_only
    set out_size_only [open pd_info/${DESIGN}.size_only.tcl w+]

    if {[file exists [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.dft.user_size_only.rpt]} {
        set fname [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.dft.user_size_only.rpt
    } elseif {[file exists [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.final.user_size_only.rpt]} {
        set fname [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.final.user_size_only.rpt
    } elseif {[file exists [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.compile.user_size_only.rpt]} {
        set fname [set ${DESIGN}(DB_DIR)]/report/${DESIGN}.compile.user_size_only.rpt
    }
    if {[info exists fname] && [file exists $fname]} {
        set in_size_only [open $fname r]

        while {[gets $in_size_only line] >= 0} {
            if {[regexp {^#} $line]} { continue }
            puts $out_size_only "[lindex $line 0]"
        }
        unset fname
    } else {
        set SIZE_ONLY [get_cells -quiet -h -f "size_only==true"]
        foreach_in_collection cell $SIZE_ONLY {
            puts $out_size_only "[get_object_name $cell]"
        }
    }
    close $out_size_only

} else {
    
    # dont_touch
    set dont_touch_rpt      [open $REPORT_DIR/dont_touch.rpt w+]

    if {[file exists ${PNR_SDC_DIR}/${DESIGN}.dont_touch.tcl]} {
        set dont_touch_cell_sdc [open ${PNR_SDC_DIR}/${DESIGN}.dont_touch.tcl r]

        while {[gets $dont_touch_cell_sdc line] >= 0} {
            set DONT_TOUCH_CELL [lindex $line 0]
            if {[sizeof_collection [get_cells -quiet $DONT_TOUCH_CELL]] < 1} {
                set CHECK_CELL_EX "FAIL"
            } else {
                set CHECK_CELL_EX "PASS"
            }
            puts $dont_touch_rpt "cell $CHECK_CELL_EX $DONT_TOUCH_CELL"
        }
        close $dont_touch_cell_sdc
    }

    if {[file exists ${PNR_SDC_DIR}/${DESIGN}.dont_touch_net.tcl]} {
        set dont_touch_net_sdc  [open ${PNR_SDC_DIR}/${DESIGN}.dont_touch_net.tcl r]

        while {[gets $dont_touch_net_sdc line] >= 0} {
            set DONT_TOUCH_NET [lindex $line 0]
            if {[sizeof_collection [get_nets -quiet $DONT_TOUCH_NET]] < 1} {
                set CHECK_NET_EX "FAIL"
            } else {
                set CHECK_NET_EX "PASS"
            }
            puts $dont_touch_rpt "net $CHECK_NET_EX $DONT_TOUCH_NET"
        }
        close $dont_touch_net_sdc
    }
    close $dont_touch_rpt


    # dont_use
    set dont_use_rpt [open $REPORT_DIR/dont_use.rpt w+]

    if {[file exists ${PNR_SDC_DIR}/${DESIGN}.dont_use.tcl]} {
        set dont_use_sdc [open ${PNR_SDC_DIR}/${DESIGN}.dont_use.tcl r]

        while {[gets $dont_use_sdc line] >= 0} {
            set DONT_USE_LIB_CELL [lindex $line 0]
            set CELL_COUNT [sizeof_collection [get_cells -quiet -h -f "ref_name =~ *${DONT_USE_LIB_CELL}*"]]
            puts $dont_use_rpt "$DONT_USE_LIB_CELL : $CELL_COUNT"
        }
        close $dont_use_sdc
    }
    close $dont_use_rpt


    # size_only
    set size_only_rpt [open $REPORT_DIR/size_only.rpt w+]

    if {[file exists ${PNR_SDC_DIR}/${DESIGN}.size_only.tcl]} {
        set size_only_sdc [open ${PNR_SDC_DIR}/${DESIGN}.size_only.tcl r]

        while {[gets $size_only_sdc line] >= 0} {
            set SIZE_ONLY [lindex $line 0]
            if {[sizeof_collection [get_cells -quiet $SIZE_ONLY]] < 1} {
                set CHECK_CELL_EX "FAIL"
            } else {
                set CHECK_CELL_EX "PASS"
            }
            puts $size_only_rpt "$CHECK_CELL_EX $SIZE_ONLY"
        }
        close $size_only_sdc
    }
    close $size_only_rpt
}
