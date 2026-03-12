#################################################################################################
# Title       : proc_high_fanout.tcl
# Author      : DT-PI
# Date        : 2024.11.22
# Version     : v0.1
# Description : Ideal_network for High Fanout setting
# Change Log  :
# 	v0.1 [2024-11-22] : bm5418
#       - Initial Version Release
#------------------------------------------------------------------------------------------------
# Usage : Use in DC 
#         Set Ideal_network for High Fanout
##################################################################################################
proc high_fanout {args} {
    parse_proc_arguments -args $args resarr
    global sh_dev_null
    global sh_product_version

    redirect $sh_dev_null {set cur_des [get_object_name [current_design]]}
    if { $cur_des == "" } {
        unsuppress_message CMD-041
        return -code error "Current design is not defined"
    }

    set outfile "$cur_des.high_fanout_net.rpt"
    if {[info exists resarr(-output)]} {
        set outfile $resarr(-output)
    }
    
    set threshold 64
    if {[info exists resarr(-threshold)]} {
        set threshold $resarr(-threshold)
    }
    puts stderr "[sh date] : procedure high fanout starts";
    puts stderr "[sh date] : check $threshold fanout ";

    if { ![file exists report/$outfile] } {
        puts stderr "\n**************************************************************\n"
        puts stderr "[sh date] : Write high_fanout_net.rpt "
        report_net_fanout -threshold $threshold -nosplit > report/$outfile
    }
    set fpin [open report/$outfile "r"]
    set fpout [open ideal_high_fanout_net.tcl "w"]
    
    set START 0
    puts stderr "\n**************************************************************\n"
    puts stderr "[sh date] : Write ideal_high_fanout_net.tcl "

while {[gets $fpin line] >= 0} {
    if { $line == "--------------------------------------------------------------------------------"} {
        puts $fpout "# ****************************************"
        puts $fpout "# Script : ideal_high_fanout_net"
        puts $fpout "# Design : $cur_des"
        puts $fpout "# Version: $sh_product_version"
        puts $fpout "# date   : [date]"
        puts $fpout "# ****************************************"
        puts $fpout ""
        puts $fpout "#****************** set_ideal_network ******************";
        incr START ; continue ;
    }
    if { $line == "1" } {continue}
    if { $START == "1" } {
        set High_fanout_net [lindex $line 0]
        set Driver_fanout [lindex $line 1] 
        set Driver [lindex $line end] 
        regsub -all {\]} $High_fanout_net {\\]} High_fanout_net
        regsub -all {\[} $High_fanout_net {\\[} High_fanout_net
        regsub -all {\]} $Driver {\\]} Driver
        regsub -all {\[} $Driver {\\[} Driver

        puts $fpout [format "# Driver : %-s , Fanout : %-d , Net : %-s" "$Driver" "$Driver_fanout" "$High_fanout_net"]
        if {"[get_pins -quiet $Driver]" != ""} {
            puts $fpout [format "set_ideal_network -no_propagate \[get_pins %-s\]" "$Driver"]
            puts $fpout ""
        } elseif {"[get_nets -quiet $High_fanout_net]" != ""} {
            puts $fpout [format "set_ideal_network -no_propagate \[get_nets %-s\]" "$High_fanout_net"]
            puts $fpout ""
        } else {
            puts $fpout "# Warning_ADF : The target was skipped because it could not be found."
            puts $fpout ""
        }
    }
}

    close $fpin
    close $fpout
    puts stderr "\n**************************************************************\n"
    puts stderr "[sh date] : Source ideal_high_fanout_net.tcl "
    
    source -e -v ideal_high_fanout_net.tcl
    
    return
}

define_proc_attributes high_fanout \
  -hide_body \
  -info "ideal high fanout point" \
  -define_args { \
    {-output "Name of output file" "outfile" string optional}
    {-threshold "Fanout threshold of listed nets" "threshold" int optional} }
puts stderr "Procedures provided in this tool kit:"
help -verbose high_fanout
