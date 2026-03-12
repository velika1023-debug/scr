###################################################################################################
# File               : proc_clock.tcl                                                             #
# Author             : ADT-DT (bmkim)                                                             #
# Description        : no clock check                                                             #
# Usage              :                                                                            #
# Init Release Date  : 2025.01.16                                                                 #
# Last Update  Date  : 2025.02.13                                                                 #
# Script Version     : 1.1                                                                        #
# Revision History   :                                                                            #
#         2025.01.16 - first released                                                             #
#         2025.01.16 - update report                                                              #
###################################################################################################
proc rpt_clock {args} {

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

    set outfile "$Design.${Design_stage}.no_clock.rpt"
    if {[info exists results(-output)]} {
        set outfile $results(-output)
    }
    puts "  Outfile name : $outfile"

    #-======================================
    # Main Step
    #-======================================
    puts "\[[date]\] > Start Analysis Clock"
    set clocks [get_clocks -f "defined(sources)"]
    set MIN [lindex [lsort -unique -increasing [get_attr $clocks period]] 0]
    set FREQ [format "%.3f" [expr 1/$MIN]]
    set clock_name [get_clocks -filter "period == $MIN"]
    
    set NO_CLOCK ""
    set Count 0
    set pins [get_pins -hierarchical -filter "is_clock_pin == true"]   
    foreach_in_collection pin $pins {
        set is_clock [get_attr -quiet [get_pins $pin] clocks]
        if {$is_clock  == ""} {
            lappend NO_CLOCK [get_object_name $pin]
            incr Count
        }
    }
    puts "\[[date]\] > END Analysis Clock"
    #-======================================
    # Report Step
    #-======================================
    puts "\[[date]\] > Start Report No Clock"
    set br_char "-"
    set rpt_width 80
    set fpout [open report/$outfile w+]

    puts $fpout "****************************************"
    puts $fpout "Report : rpt_clock"
    puts $fpout "Design : $Design"
    puts $fpout "Version: $sh_product_version"
    puts $fpout "date   : [date]"
    puts $fpout "****************************************"
    puts $fpout ""
    puts $fpout "High Frequency Clock : [get_object_name $clock_name] ($FREQ GHz)"
    puts $fpout ""
    puts $fpout "Total NO Clock Count : $Count"
    puts $fpout [format "%s %5s" "Type" "Object"]
    puts $fpout [string repeat $br_char $rpt_width]
    if {$NO_CLOCK != ""} {
        foreach item $NO_CLOCK {
            puts $fpout [format "%s %5s" "Pin " "$item"]
        }
    } else {puts $fpout "No Clock List Empty"}
    puts $fpout [string repeat $br_char $rpt_width]
    close $fpout
    puts "\[[date]\] > END Report No Clock"
}
define_proc_attributes rpt_clock \
  -info "No Clock rpt" \
  -define_args { \
    {-design_stage "Current Design Stage" "<compile | dft | incr>" string optional} \
    {-output "Name of output file" "outfile" string optional}}
help -verbose rpt_clock
