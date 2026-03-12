###################################################################################################
# File               : physical_option_setup.tcl                                                  #
# Author             : ADT-DT (jblee)                                                             #
# Description        : Physical option setting                                                    #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################

##################################################################################
# technolog setup
#################################################################################

# Use Mega-switch for tech-dependent optimization
if { [string match "*28*" $TECHNOLOGY_NODE] } {
    puts "Error_ADF : Unsupported TECHNOLOGY_NODE value $TECHNOLOGY_NODE"
} elseif {[string match "*2*" $TECHNOLOGY_NODE] || [string match "*3*" $TECHNOLOGY_NODE]} {
    set tech_node s3
} elseif { [string match "*14*" $TECHNOLOGY_NODE] } {
    set tech_node s14
} elseif { [string match "*5*" $TECHNOLOGY_NODE] } {
    set tech_node s5
} elseif { [string match "*8*" $TECHNOLOGY_NODE] } {
    set tech_node s8
} elseif { [string match "*4*" $TECHNOLOGY_NODE] } {
    set tech_node s4
}

set_technology -node $tech_node

##################################################################################
# Read physical constraints
##################################################################################
proc_time read_physical_const_START 

# Please fill out the preferred routing direction depending on the metal stack
foreach layer $VERTICAL_LAYER   {set_attribute [get_layers $layer] routing_direction vertical}
foreach layer $HORIZONTAL_LAYER {set_attribute [get_layers $layer] routing_direction horizontal}

if { [info exists MIN_ROUTING_LAYER] && ${MIN_ROUTING_LAYER} != ""} {
	set_ignored_layers -min_routing_layer ${MIN_ROUTING_LAYER}
}
if { [info exists MAX_ROUTING_LAYER] && ${MAX_ROUTING_LAYER} != ""} {
	set_ignored_layers -max_routing_layer ${MAX_ROUTING_LAYER}
}
set_ignored_layers -rc_congestion_ignored_layers {LB IA IB}

report_ignored_layers

if { $PHYSICAL_CONSTRAINT_TYPE == "DEF" } {
    if { [file exists ${DEF_INPUT_FILE}] } {
        set read_def_cmd "read_def -add_def_only_objects cells ${DEF_INPUT_FILE}"
    	if { [string match -nocase "*AUTO*" ${DEF_SITE_MAPPING}] } {
    		set DEF_SITE_MAPPING [source ${COMMON_TCL}/fc_syn/auto_site_mapping.tcl]
    		lappend read_def_cmd -convert ${DEF_SITE_MAPPING}
    	} elseif { ${DEF_SITE_MAPPING} != "" } {
    		puts "Information_ADF: User defined DEF site mapping"
    		lappend read_def_cmd -convert ${DEF_SITE_MAPPING}
    	} else {
    		puts "Information_ADF: No DEF_SITE_MAPPING"
    	}
    
        suppress_message {DEFR-025 DEFR-041 DEFR-065}
        redirect -tee ${LOG_DIR}/read_fp.log { eval $read_def_cmd }
    
        puts "Information_ADF : Read DEF  -> $DEF_INPUT_FILE"
    } else {
        puts "Error_ADF : DEF does not exist - $DEF_INPUT_FILE"
        exit
    }
} elseif { $PHYSICAL_CONSTRAINT_TYPE == "TCL_FP" } {
    if { [file exists ${TCL_FP_INPUT_FILE}] } {
        set_app_options -name design.enable_rule_based_query -value true
        redirect -tee ${LOG_DIR}/read_fp.log { source -echo -verbose ${TCL_FP_INPUT_FILE} }

        set_app_options -name design.enable_rule_based_query -value false
        puts "Information_ADF : Read Tcl floorplan script -> $TCL_FP_INPUT_FILE"
    } else {
        puts "Error_ADF : Tcl floorplan script does not exist - $TCL_FP_INPUT_FILE"
        exit
    }
} elseif { $PHYSICAL_CONSTRAINT_TYPE == "AUTO_FP" } {
    set AUTO_FP_CMD "set_auto_floorplan_constraints  \
                       -core_utilization ${AUTO_FP_CORE_UTIL}  \
                       -core_offset ${AUTO_FP_CORE_OFFSET}  \
                       -coincident_boundary false  \
                       -flip_first_row false  \
                       -use_site_row "
    eval ${AUTO_FP_CMD}
} else {
    puts "Warning_ADF : No PHYSICAL_CONSTRAINT_TYPE set!! - the tool runs the default auto floorplan"
}


# Write applied floorplan and report applied physical constraints
redirect -file ${REPORT_DIR}/${TOP_DESIGN}.physical_constraints.rpt {check_physical_constraints}
proc_time read_physical_const_END 
