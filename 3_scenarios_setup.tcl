###################################################################################################
# File               : 3_scenarios_setup.tcl                                                      #
# Author             : ADT-DT (jblee)                                                             #
# Description        : scenarios setup (single, MCMM)                                             #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################

###############################################################################
# Generate scenario
###############################################################################
remove_scenarios -all
remove_corners -all
remove_modes -all

set SCENARIO_NUM [llength $SCENARIO_NAMES]

for {set t 0} { $t < $SCENARIO_NUM} {incr t} {
    set SCENARIO(NAME)  [lindex $SCENARIO_NAMES $t]
    set SCENARIO(OPLIB) [lindex $OPCON_LIB_NAME $t ]
	set SCENARIO(OPCON) [lindex $OPCON_NAME $t]
    set SCENARIO(TLUP)  [lindex $TLUPLUS_MAX_FILES $t]
    set SCENARIO(CON)   [lindex $CONSTRAINTS_FILES $t]
	set SCENARIO(OPT)   [lindex $OPT_TARGET $t]


	puts "Information_ADF: Generating Library $SCENARIO(OPLIB).."

    #-- Read prj_lib_split.tcl
    set MODE          [lindex [split $SCENARIO(NAME) "." ] 0 ]
    set TARGET_CORNER [lindex [split $SCENARIO(NAME) "." ] 1 ]
    set CORNER_PROC   [lindex [split $TARGET_CORNER "._"] 0 ]
    set CORNER_VOLT   [lindex [split $TARGET_CORNER "._"] 1 ]
    set CORNER_TEMP   [lindex [split $TARGET_CORNER "._"] 2 ]
    set CORNER_RC_A   [lindex [split $TARGET_CORNER "._"] 3 ]
    set CORNER_RC_B   [lindex [split $TARGET_CORNER "._"] 4 ]
    set CORNER_RC     "${CORNER_RC_A}_${CORNER_RC_B}"

    puts "Information_ADF : proc = $CORNER_PROC , volt = $CORNER_VOLT , temp = $CORNER_TEMP"


	puts "Information_ADF: Generating Corner ${TARGET_CORNER}.."
    create_corner $TARGET_CORNER

    #-- Setting operating_conditions
	puts "Information_ADF : set_operating_conditions -library $SCENARIO(OPLIB) -max $SCENARIO(OPCON) -min $SCENARIO(OPCON)"
	set_operating_conditions -library [index_collection [get_lib $SCENARIO(OPLIB)] 0] -max $SCENARIO(OPCON) -min $SCENARIO(OPCON)

	puts "Information_ADF : Using TLUPlus file $SCENARIO(TLUP) for $SCENARIO(NAME)."
    read_parasitic_tech -tlup $SCENARIO(TLUP) -layermap $MAP_FILE -name $CORNER_RC
    set_parasitics_parameters -corner $TARGET_CORNER -late_spec $CORNER_RC -early_spec $CORNER_RC
    set_extraction_options -corners $TARGET_CORNER -reference_direction vertical
    report_parasitic_parameters


	if { [lsearch [get_object_name [get_modes *]] $MODE] == "-1" } {
		puts "Information_ADF: Generating Mode ${MODE}.."
	    create_mode $MODE
	} else {
		puts "Information_ADF: Skipping generation because mode \"${MODE}\" is defined."
	}


	puts "Information_ADF: Generating Scenario $SCENARIO(NAME).."
    create_scenario -mode $MODE -corner $TARGET_CORNER -name $SCENARIO(NAME)
    current_scenario $SCENARIO(NAME)

 	set scn_option "set_scenario_status $SCENARIO(NAME)"
 	if { ![string match "*S*" $SCENARIO(OPT)] } {
 	   append scn_option " -setup false"
 	}
 	if { ![string match "*H*" $SCENARIO(OPT)] } {
 	   append scn_option " -hold false"
 	}
 	if { ![string match "*L*" $SCENARIO(OPT)] } {
 	   append scn_option " -leakage_power false"
 	}
 	if { ![string match "*D*" $SCENARIO(OPT)] } {
 	   append scn_option " -dynamic_power false"
 	}
 	if {$SCENARIO(OPT) == ""} {
 	   puts "Warning_ADF: You didn't designate optimization target for $SCENARIO(NAME). Setup and Leakage optimization will be automatically selected."
 	   set scn_option "set_scenario_status $SCENARIO(NAME) -setup true -hold false -leakage_power true -dynamic_power false"
 	}
 	puts "Information_ADF : $scn_option"
 	eval $scn_option


    #-- Reading Constraint File
    puts "Information_ADF: Reading Constraint File"
    if { $SCENARIO(CON) != "" } {
        if {$USE_MCMM == "true"} {
            redirect -tee ${LOG_DIR}/${TOP_DESIGN}.read_constraint_scn${t}.log { source -echo -verbose $SCENARIO(CON) }
        } else {
            redirect -tee ${LOG_DIR}/${TOP_DESIGN}.read_constraint.log { source -echo -verbose $SCENARIO(CON) }
        }
    } else {
        if {$USE_MCMM == "true"} {
            redirect -tee ${LOG_DIR}/${TOP_DESIGN}.read_constraint_scn${t}.log { source -echo -verbose ${COMMON_SDC}/common_sdc.tcl }
        } else {
            redirect -tee ${LOG_DIR}/${TOP_DESIGN}.read_constraint.log { source -echo -verbose ${COMMON_SDC}/common_sdc.tcl }
        }
    }

    ## set ideal network
    remove_propagated_clock [all_clocks]
    remove_ideal_network [remove_from_collection [all_fanout -flat -clock_tree] [get_ports [all_outputs]]]
    set_ideal_network [remove_from_collection [all_fanout -flat -clock_tree] [get_ports [all_outputs]]]

}

## No boundary hold fix
foreach scenario [get_object_name [get_scenarios -filter "active == true && hold == true"]] {
    current_scenario $scenario
    set ports_clock_root [get_ports [all_fanout -flat -clock_tree -level 0]]
    set_false_path -hold -from [remove_from_collection [all_inputs] $ports_clock_root] -to [all_clocks]
    set_false_path -hold -from [all_clocks] -to [all_outputs]
}

redirect -file ${REPORT_DIR}/${TOP_DESIGN}.pvt.rpt       {report_pvt}
redirect -file ${REPORT_DIR}/${TOP_DESIGN}.scenarios.rpt {report_scenarios -mode [all_modes] -nosplit}

###############################################################################
# apply ocv margin
###############################################################################
rm_source -file ${COMMON_TCL}/fc_syn/ocv_margin_setup.tcl
