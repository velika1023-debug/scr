###################################################################################################
# File               : proc_top_300.tcl                                                           #
# Author             : ADT-DT (pjm1023)                                                           #
# Description        : report cirtical path                                                       #
# Usage              :                                                                            #
# Init Release Date  : 2025.01.16                                                                 #
# Last Update  Date  : 2025.02.03                                                                 #
# Script Version     : 2.1                                                                        #
# Revision History   :                                                                            #
#         2025.01.16 - first released                                                             #
###################################################################################################

proc rpt_top_300 {args} {
    global sh_product_version
    global sh_dev_null
    parse_proc_arguments -args $args results
    
    redirect $sh_dev_null {set Design [get_object_name [current_design]]}
    if {$Design == ""} {
        return -code error "Current design is not defined"
    }
    
    set Design_stage NONE
    if {[info exists results(-design_stage)]} {
        set Design_stage $results(-design_stage)
    }

    set Path_group [remove_from_collection [get_path_groups] [get_path_groups *default*]]
    if {[info exists results(-path_group)]} {
        set Path_group $results(-path_group)
    }
    #-======================================
    # Main Step
    #-======================================

    foreach P_group [get_object_name $Path_group] {
        set Path_300 [get_timing_path -group $P_group -max_path 300 -slack_lesser_than 1]
        if {[info exists results(-design_stage)]} {
            set FILE [open report/${Design_stage}/${Design}.${P_group}.300.CRIT.INFO.${Design_stage} w]
        } else {
            set FILE [open report/${Design}.${P_group}.300.CRIT.INFO.${Design_stage} w]
        }
        set slacks       [get_attr $Path_300 slack]
        set end_clk      [get_attri [get_timing_path -group $P_group -max_path 1 -slack_lesser_than 1] endpoint_clock]
        set clk_period   [get_attri $end_clk period]
        
        set sum 0.0
        foreach v $slacks {set sum [expr $sum + $v]}
        set avg         [expr $sum / double([llength $slacks])]
        set avg_freq    [expr 1/(($clk_period) - $avg) *1000]
        
        puts $FILE "------------------------------------------------------------------------------------------------------"
        puts $FILE [format "Top Critical 300 Path's Average Slack is ...   %7.3f  ns" $avg]
        puts $FILE [format "Top Critical 300 Path's Average Freq is ...   %7.2f  Mhz" $avg_freq]
        puts $FILE "------------------------------------------------------------------------------------------------------"
        puts $FILE ""
        puts $FILE "Endpoints                                                                       Slack  Achieved(Mhz)  "
        puts $FILE "------------------------------------------------------------------------------------------------------"
        foreach_in_collection  itr $Path_300 {
            set END_PNT [get_attribute $itr endpoint]
            set END_CLK [get_attribute $itr endpoint_clock]
            set CLK_PERIOD [get_attribute $END_CLK period]
            set SLACK [get_attribute $itr slack]
            set ACH_FREQ   [format %3.2f [expr 1/(($CLK_PERIOD) - $SLACK)*1000]]
            puts $FILE [format "%-80s %7.4f    %7.2f" [get_object_name $END_PNT] $SLACK $ACH_FREQ]
        }
        close $FILE
    }
}
define_proc_attributes rpt_top_300 \
  -info "report Top Critical 300 Path's average Slack and Freq" \
  -define_args { \
    {-design_stage "Current Design Stage" "<compile | dft | incr>" string optional} \
    {-path_group "Target Path group (default = all)" "path_group" string optional}}
help -verbose rpt_top_300
