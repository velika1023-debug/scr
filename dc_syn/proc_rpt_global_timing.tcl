###################################################################################################
# File               : proc_rpt_global_timing.tcl                                                 #
# Author             : ADT-DT (bmkim)                                                             #
# Description        : global timing check                                                        #
# Usage              :                                                                            #
# Init Release Date  : 2025.01.16                                                                 #
# Last Update  Date  : 2025.02.03                                                                 #
# Script Version     : 2.1                                                                        #
# Revision History   :                                                                            #
#         2025.01.16 - first released                                                             #
#         2025.02.03 - Modify Path Analysis method                                                #
#         2025.02.13 - Modify export path                                                         #
#         2025.02.13 - timing path for MCMM mode                                                  #
###################################################################################################
proc rpt_global_timing {args} {
    global sh_product_version
    global sh_dev_null
    global USE_MCMM
    parse_proc_arguments -args $args results

    redirect $sh_dev_null {set Design [get_object_name [current_design]]}
    if {$Design == ""} {
        return -code error "Current design is not defined"
    }
    
    set Design_stage NONE
    if {[info exists results(-design_stage)]} {
        set Design_stage $results(-design_stage)
        set outfile "$Design.${Design_stage}.global_timing.rpt"
    } else {
        set outfile "$Design.global_timing.rpt"
    }

    if {[info exists results(-output)]} {
        set outfile $results(-output)
    }
    puts "  Outfile name : $outfile"

    #-======================================
    # Main Step
    #-======================================

    puts "\[[date]\] > Start Path Analysis"
    if {$USE_MCMM} {
        set paths_max [get_timing_path -max_paths 999999 -slack_lesser_than 0 -delay_type max -scenarios [all_scenarios]]
        set paths_min [get_timing_path -max_paths 999999 -slack_lesser_than 0 -delay_type min -scenarios [all_scenarios]]
    } else {
        set paths_max [get_timing_path -max_paths 999999 -slack_lesser_than 0 -delay_type max]
        set paths_min [get_timing_path -max_paths 999999 -slack_lesser_than 0 -delay_type min]
    }

    # Variable
    array set Path_max_group {
        i2r {}
        r2r {}
        r2o {}
        i2o {}
    }
    
    array set Path_min_group {
        i2r {}
        r2r {}
        r2o {}
        i2o {}
    }
    
    # Start Sort Path group
    foreach_in_collection path $paths_max {
        set Startpoint [get_attr $path startpoint]
        set Endpoint   [get_attr $path endpoint]
        set Slack      [get_attr $path slack]
        set Start_type [get_attr $Startpoint object_class]
        set End_type   [get_attr $Endpoint object_class]
    
        set Path_group ""
        if {$Start_type == "port" && $End_type == "pin"} {
            set Path_group i2r
        } elseif {$Start_type == "pin" && $End_type == "pin"} {
            set Path_group r2r
        } elseif {$Start_type == "pin" && $End_type == "port"} {
            set Path_group r2o
        } elseif {$Start_type == "port" && $End_type == "port"} {
            set Path_group i2o
        }
        lappend Path_max_group($Path_group) $Slack
    }
    
    foreach_in_collection path $paths_min {
        set Startpoint [get_attr $path startpoint]
        set Endpoint   [get_attr $path endpoint]
        set Slack      [get_attr $path slack]
        set Start_type [get_attr $Startpoint object_class]
        set End_type   [get_attr $Endpoint object_class]
    
        set Path_group ""
        if {$Start_type == "port" && $End_type == "pin"} {
            set Path_group i2r
        } elseif {$Start_type == "pin" && $End_type == "pin"} {
            set Path_group r2r
        } elseif {$Start_type == "pin" && $End_type == "port"} {
            set Path_group r2o
        } elseif {$Start_type == "port" && $End_type == "port"} {
            set Path_group i2o
        }
        lappend Path_min_group($Path_group) $Slack
    }

    unset paths_max
    unset paths_min

    puts "\[[date]\] > End Path Analysis"

    #-======================================
    # Report Step
    #-======================================
    puts "\[[date]\] > Start Path reporting"
    set br_char "-"
    set rpt_width 73
    set fpout [open report/$outfile w+]

    puts $fpout "****************************************"
    puts $fpout "Report : rpt_global_timing"
    puts $fpout "Design : $Design"
    puts $fpout "Version: $sh_product_version"
    puts $fpout "date   : [date]"
    puts $fpout "****************************************"

    puts $fpout ""
    puts $fpout "Setup violations"
    foreach t_group {i2r r2r r2o i2o} {
        set ${t_group}_wns 0; set ${t_group}_tns 0; set ${t_group}_num 0; set sum 0
    
        set ${t_group}_wns [lindex [lsort -increasing -real $Path_max_group($t_group)] 0]
        if {[set ${t_group}_wns] == ""} { set ${t_group}_wns 0 }
        foreach num $Path_max_group($t_group) {
            set sum [expr $sum + $num]
        }
        set ${t_group}_tns $sum
        set ${t_group}_num [llength $Path_max_group($t_group)]
    }
    
    set total_wns [expr {min($r2r_wns, $i2r_wns, $r2o_wns, $i2o_wns)}]
    set total_tns [expr {$r2r_tns + $i2r_tns + $r2o_tns + $i2o_tns}]
    set total_num [expr {$r2r_num + $i2r_num + $r2o_num + $i2o_num}]
    
    puts $fpout "[string repeat $br_char $rpt_width]"
    puts $fpout [format "%-s %13s %12s %13s %12s" "           Total" "reg->reg" "in->reg" "reg->out" "in->out"]
    puts $fpout "[string repeat $br_char $rpt_width]"
    puts $fpout [format "%s %12.3f %12.3f %12.3f %12.3f %12.3f" "WNS" "$total_wns" "$r2r_wns" "$i2r_wns" "$r2o_wns" "$i2o_wns"]
    puts $fpout [format "%s %12.3f %12.3f %12.3f %12.3f %12.3f" "TNS" "$total_tns" "$r2r_tns" "$i2r_tns" "$r2o_tns" "$i2o_tns"]
    puts $fpout [format "%s %12s %12s %12s %12s %12s" "NUM" "$total_num" "$r2r_num" "$i2r_num" "$r2o_num" "$i2o_num"]

    puts $fpout ""
    puts $fpout "Hold violations"
    foreach t_group {i2r r2r r2o i2o} {
        set ${t_group}_wns 0; set ${t_group}_tns 0; set ${t_group}_num 0; set sum 0
        
        set ${t_group}_wns [lindex [lsort -increasing -real $Path_min_group($t_group)] 0]
        if {"[set ${t_group}_wns]" == ""} { set ${t_group}_wns 0 }
        foreach num $Path_min_group($t_group) {
            set sum [expr $sum + $num]
        }
        set ${t_group}_tns $sum
        set ${t_group}_num [llength $Path_min_group($t_group)]
    
    }
    
    set total_wns [expr {min($r2r_wns, $i2r_wns, $r2o_wns, $i2o_wns)}]
    set total_tns [expr {$r2r_tns + $i2r_tns + $r2o_tns + $i2o_tns}]
    set total_num [expr {$r2r_num + $i2r_num + $r2o_num + $i2o_num}]
    
    puts $fpout "[string repeat $br_char $rpt_width]"
    puts $fpout [format "%-s %13s %12s %13s %12s" "           Total" "reg->reg" "in->reg" "reg->out" "in->out"]
    puts $fpout "[string repeat $br_char $rpt_width]"
    puts $fpout [format "%s %12.3f %12.3f %12.3f %12.3f %12.3f" "WNS" "$total_wns" "$r2r_wns" "$i2r_wns" "$r2o_wns" "$i2o_wns"]
    puts $fpout [format "%s %12.3f %12.3f %12.3f %12.3f %12.3f" "TNS" "$total_tns" "$r2r_tns" "$i2r_tns" "$r2o_tns" "$i2o_tns"]
    puts $fpout [format "%s %12s %12s %12s %12s %12s" "NUM" "$total_num" "$r2r_num" "$i2r_num" "$r2o_num" "$i2o_num"]
    close $fpout
    unset Path_max_group
    unset Path_min_group
    puts "\[[date]\] > End Path reporting"
}

define_proc_attributes rpt_global_timing \
        -info "report global timing of the design" \
        -define_args { \
            {-design_stage "Current Design Stage" "<compile | dft | incr>" string optional} \
            {-output        "Name of output file" "outfile" string optional} }
help -verbose rpt_global_timing
