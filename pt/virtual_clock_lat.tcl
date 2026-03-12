################################################################################
# File Name     : virtual_clock_lat.tcl
# Author        : DT-PI
# Creation Date : 2024-03-15
# Last Modified : 2025-07-01
# Version       : v0.8
# Location      : ${PRJ_PT}/design_scripts/run_sta.tcl
#-------------------------------------------------------------------------------
# Description   :
# 	This file is an example file. This header is used to track the version and
# 	change history of the file.
#-------------------------------------------------------------------------------
# Change Log    :
# 	[2024-03-15] v0.1 : iskim1001
#       - Initial Version Release
#   [2024-03-15] v0.2 : iskim1001
#		- add variable vclk_name_temp
#	[2024-05-03] v0.3 : iskim1001
#		- fixed the Tcl limit below
#			Warning: Size of list created by get_object_name exceeds Tcl limit of 2147483647 characters. (UIAT-9)
# 	 		 Error: can't read "clk_pin_count": no such variable
# 	 		 Use error_info for more info. (CMD-013)
# 	[2025-02-10] v0.4 : jaeeun1115
# 	    - Setting vclk latency only for its sync clocks
# 	[2025-05-12] v0.5 : jaeeun1115
# 	    - Modify the condition to determine sync clock
# 	    - Calculating mean value of latency (not sorting)
# 	[2025-05-12] v0.6 : iskim1001
# 		- Change the location of the "source -e -v vclk_latency.tcl" syntax
# 	[2025-06-30] v0.7 : jaeeun1115
# 	    - Ignore CLK with no sink
# 	[2025-07-01] v0.8 : jaeeun1115
# 	    - Consider real clock related with vclk
#-------------------------------------------------------------------------------
# Useage        :
# 	pt_shell > sources virtual_clock_lat.tcl
#################################################################################

set VCLK_COL   [get_clocks -quiet -filter !defined(sources)] 
set CLK_COL    [get_clocks * -filter "defined(sources)" ]

if { [sizeof_collection $VCLK_COL] > 0 } {

    if {[file exists vclk_latency.tcl]} { sh rm vclk_latency.tcl }
    if {[file exists vclk_latency.tcl]} { sh rm vclk_latency.rpt }
    set output_tcl [open vclk_latency.tcl w+]
    set output_rpt [open vclk_latency.rpt w+]

    suppress_message "UITE-416"

    puts $output_rpt "#IO Latency report"

    # Calculating latency for each clock
    foreach_in_collection CLK $CLK_COL {
        set CLK_NAME [get_object_name $CLK]
        set ${CLK_NAME}(lat_total)     0
        set ${CLK_NAME}(min_lat_total) 0
        puts $output_rpt ""
        puts $output_rpt "# $CLK_NAME"
        
        #org(UIAT-9)        
        #set clk_netw_obj_col [get_object_name [get_pins -quiet -of_objects [get_cells  -quiet  [all_registers  -clock [get_object_name $i]] -filter "ref_name!~ *ICG* || is_integrated_clock_gating_cell==false && is_memory_cell==false && full_name !~ *LOCKUP*" ] -filter "is_clock_pin"]]
        set clk_netw_obj_col [get_pins -quiet -of_objects [get_cells  -quiet  [all_registers  -clock $CLK] -filter "ref_name!~ *ICG* || is_integrated_clock_gating_cell==false && is_memory_cell==false && full_name !~ *LOCKUP*" ] -filter "is_clock_pin"]

        if {$clk_netw_obj_col != "" && [sizeof_collection $clk_netw_obj_col] >  0} {

            #org(UIAT-9)  		
            #set clk_pin_count [llength $clk_netw_obj_col]
            set ${CLK_NAME}(clk_pin_count) [sizeof_collection  $clk_netw_obj_col]
            set max_p [set ${CLK_NAME}(clk_pin_count)]
            set lat_max [get_attribute [get_timing_paths -max $max_p -to $clk_netw_obj_col -from [get_attribute [get_clocks $CLK_NAME] sources] ] arrival]
            set lat_min [get_attribute [get_timing_paths -max $max_p -to $clk_netw_obj_col -from [get_attribute [get_clocks $CLK_NAME] sources]  -del min] arrival]

            if {$lat_max != ""} {
                set max 0
                foreach a $lat_max {
                    if {$a > 2} {
                        puts $output_rpt "found high latency point for clock $CLK_NAME : latency value : $a"              
                        set max [expr $max + 2]
                    } else {
                        set max [expr $max + $a]
                    }
                }

                set min 0
                foreach a $lat_min {
                    if {$a > 2} {
                        puts $output_rpt "found high latency point for clock $CLK_NAME : latency value : $a"               
                        set min [expr $min + 2]
                    } else {
                        set min [expr $min + $a]
                    }
                }

                set ${CLK_NAME}(lat_total)     [format "%8.6f" $max]
                set ${CLK_NAME}(min_lat_total) [format "%8.6f" $min]
            }
        } else {
            ## Remove CLK with no sink
            set CLK_COL [remove_from_collection $CLK_COL $CLK]
            puts $output_rpt "Sink pin not found -> Exclude from CLK_COL"
            continue
        }
        set ${CLK_NAME}(mean)      [expr [set ${CLK_NAME}(lat_total)]/[set ${CLK_NAME}(clk_pin_count)]]
        set ${CLK_NAME}(min_mean)  [expr [set ${CLK_NAME}(min_lat_total)]/[set ${CLK_NAME}(clk_pin_count)]]
    }

    puts $output_rpt "# VCLK <-> CLK relationship"
    foreach_in_collection VCLK_E $VCLK_COL {
        set VCLK_NAME [get_object_name $VCLK_E]
        puts $output_rpt "# VCLK : $VCLK_NAME"

        # Finding only sync clock for each VCLK
        foreach_in_collection CLK $CLK_COL {
            set CLK_NAME [get_object_name $CLK]
            set clock_relationship [get_clock_relationship "$VCLK_NAME $CLK_NAME"]

            if { ![regexp {asynchronous} $clock_relationship] && ![regexp {logically_exclusive} $clock_relationship] && ![regexp {physically_exclusive} $clock_relationship] && ![regexp {allow_paths} $clock_relationship]} {

                set from_tag [sizeof_collection [get_timing_paths -from $VCLK_E -to $CLK]]
                set to_tag   [sizeof_collection [get_timing_paths -from $CLK    -to $VCLK_E]]

                if { $from_tag | $to_tag } {
                    puts $output_rpt "   CLK : $CLK_NAME $clock_relationship"
                    lappend ${VCLK_NAME}(sync_clk) $CLK_NAME
                } else {
                    puts $output_rpt "   CLK : $CLK_NAME $clock_relationship ;# -> No paths."
                }
            } else {
                puts $output_rpt "   CLK : $CLK_NAME $clock_relationship"
            }
        }
        if { [info exists ${VCLK_NAME}(sync_clk)] } {

            set ${VCLK_NAME}(lat_total)     0
            set ${VCLK_NAME}(lat_min_total) 0
            set ${VCLK_NAME}(pin_cnt_total) 0

            foreach CLK [set ${VCLK_NAME}(sync_clk)] {
                set ${VCLK_NAME}(lat_total)     [expr [set ${VCLK_NAME}(lat_total)] + [set ${CLK}(lat_total)]]
                set ${VCLK_NAME}(lat_min_total) [expr [set ${VCLK_NAME}(lat_min_total)] + [set ${CLK}(min_lat_total)]]
                set ${VCLK_NAME}(pin_cnt_total) [expr [set ${VCLK_NAME}(pin_cnt_total)] + [set ${CLK}(clk_pin_count)]]
            }
        } else {
            puts $output_rpt "   => NO RELATED CLK"
        }
        puts $output_rpt ""
    }

    foreach_in_collection VCLK_E $VCLK_COL {
        set VCLK_NAME [get_object_name $VCLK_E]

        if { [ info exists ${VCLK_NAME}(sync_clk) ] } {

            set ${VCLK_NAME}(mean) [expr [set ${VCLK_NAME}(lat_total)] / [set ${VCLK_NAME}(pin_cnt_total)]]
            set ${VCLK_NAME}(min_mean) [expr [set ${VCLK_NAME}(lat_min_total)] / [set ${VCLK_NAME}(pin_cnt_total)]]

            puts $output_tcl "set_clock_latency [format "%8.6f" [set ${VCLK_NAME}(mean)]] -source -late [list $VCLK_NAME]"
            puts $output_tcl "set_clock_latency [format "%8.6f" [set ${VCLK_NAME}(min_mean)]] -source -early [list $VCLK_NAME]"
        }
    }

    close $output_tcl
    close $output_rpt

    echo "################################################################################################"
    echo "## Sourcing virtual clock latency file"
    echo "################################################################################################"
    source -e -v vclk_latency.tcl
    unsuppress_message "UITE-416"
}
