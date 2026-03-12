###################################################################################################
# File               : saif_flow.tcl                                                              #
# Author             : ADT-DT (bmkim)                                                             #
# Description        : Power Optimize when saif file exist                                        #
# Usage              :                                                                            #
# Init Release Date  : 2025.01.16                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.01.16 - first released                                                             #
###################################################################################################

##################################################################################
# SAIF Flow
##################################################################################
if { $USE_SAIF }  {
	if { ![file exist $SAIF_FILE] } { puts "Error_ADF : $SAIF_FILE does not exist" ; exit }

	set SAIF_SCENARIO [get_scenarios -quiet -filter "active == true && dynamic_power == true"]

	if { [sizeof_collection $SAIF_SCENARIO] > 0 } {
		saif_map -start
		if { $USE_SAIF_MAP_FILE != ""} {
			saif_map -read_map $USE_SAIF_MAP_FILE
		}
		puts "Information_ADF : SAIF file is applied for power optimization"
		
		set read_saif_cmd "read_saif $SAIF_FILE -scenarios \"[get_object_name $SAIF_SCENARIO]\""
		if {$STRIP_PATH  != ""           } { lappend read_saif_cmd -strip_path $STRIP_PATH }
		if {$TARGET_INST != ""           } { lappend read_saif_cmd -path $TARGET_INST      }
		if {$SKIP_NAME_MAPPING == "true" } { lappend read_saif_cmd -ignore_name_mapping    }

		puts "Information_ADF : Running read_saif_cmd"
		puts "                    $read_saif_cmd"
		eval ${read_saif_cmd}

        if { $SAIF_SCENARIO != "" } {
            reset_switching_activity -non_essential -scenarios $SAIF_SCENARIO
			report_activity -driver -scenarios $SAIF_SCENARIO > ${REPORT_DIR}/${TOP_DESIGN}.report_activity.rpt 
        } else {
            reset_switching_activity -non_essential
			report_activity -driver > ${REPORT_DIR}/${TOP_DESIGN}.report_activity.rpt
        }
		saif_map -report >  ${REPORT_DIR}/${TOP_DESIGN}.saif_map.rpt

	} else {
		puts "Error_ADF : No scenario has dynamic power enabled."
		puts "            Please refer to the scenario settings in user_design_setup.tcl"
	}
}
