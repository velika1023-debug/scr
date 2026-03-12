################################################################################
# File Name     : pre_sta_hfn.tcl
# Author        : DT-PI
# Creation Date : 2024-05-30 
# Last Modified : 2025-06-27 
# Version       : v0.4
# Location      : $COMMON_IMPL_DIR/common_tcl/pt/pre_sta_hfn.tcl
#-------------------------------------------------------------------------------
# Description   :
# 	During pre sta, a random value is set for nets with more than 30 fanouts.
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-05-30] : 
#       - Initial Version Release
#   v0.2 [2025-02-19] :
#       - Add 'set_ideal_network' for the big cap values
#   v0.3 [2025-06-17] :
#       - Remove 'set_ideal_network'
#   v0.4 [2025-06-27] :
#       - Consider input port 
#       - Add 'set_ideal_network' for the big cap values (fanout > 100)
#-------------------------------------------------------------------------------
# Useage        :
#		Usage...
#################################################################################

set hfn_threshold     30
set ideal_net_delay   0.015
set ideal_cell_delay  0.020
set ideal_transition  0.015

set ideal_threshold     100

set ALL_NETS   [get_nets -hier * -top_net]

foreach_in_collection net $ALL_NETS {
	set net_pins [all_connected $net -leaf]
	if { [sizeof $net_pins] < $hfn_threshold } {
		continue;
	}

	set net_name [get_attribute $net full_name]
	if { [string match "*/\*Logic1\*" $net_name] || [string match "*/\*Logic0\*" $net_name]}  {
		continue
	}
	
	foreach_in_collection pin $net_pins {
		set dir [get_attribute -quiet $pin direction]
        if {[get_attr $pin object_class]=="port"} {
            if {$dir == "in"} {
		    	set net_name  [get_attribute $net full_name]
		    	set pin_name  [get_attribute $pin full_name]
		    	echo "Information_ADF: ##high fanout net: $net_name ([sizeof $net_pins])"
		    	echo "  set_annotated_delay -net $ideal_net_delay -from \[get_ports $pin_name\]"
		    	echo "  set_annotated_transition $ideal_transition \[get_ports $pin_name\]"
		    	set_annotated_delay      -net  $ideal_net_delay  -from $pin
		    	set_annotated_transition $ideal_transition $pin

                if { [sizeof $net_pins] > $ideal_threshold } {
                    echo "  set_ideal_network \[get_ports $pin_name\]"
                    set_ideal_network [get_ports $pin]
                }
                echo ""
            }
        } else {
		    if {$dir == "out"} {
		    	set net_name  [get_attribute $net full_name]
		    	set pin_name  [get_attribute $pin full_name]
		    	echo "Information_ADF: ##high fanout net: $net_name ([sizeof $net_pins])"
		    	echo "  set_annotated_delay -net $ideal_net_delay -from \[get_pins $pin_name\]"
		    	echo "  set_annotated_delay -cell $ideal_cell_delay -to \[get_pins $pin_name\]"
		    	echo "  set_annotated_transition $ideal_transition \[get_pins $pin_name\]"
		    	set_annotated_delay      -net  $ideal_net_delay  -from $pin
		    	set_annotated_delay      -cell $ideal_cell_delay -to   $pin
		    	set_annotated_transition $ideal_transition $pin

                if { [sizeof $net_pins] > $ideal_threshold } {
                    echo "  set_ideal_network \[get_ports $pin_name\]"
                    set_ideal_network [get_pins $pin]
                }
                echo ""
		    }
        }
	}
}
