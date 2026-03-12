# [PATH_CONFLICT] Original logical path: ./3_scenarios_setup.tcl
# [SOURCE_TXT] 019b72eb-1366-7073-b81a-b16f280d6641.txt
# [NOTE] Same PATH appeared with different content, so this variant was saved separately.
###################################################################################################
# File               : 3_scenarios_setup.tcl                                                      #
# Author             : ADT-DT (jyjang)                                                            #
# Author2            : ADT-DT (isaac)                                                             #
# Author3            : ADT-DT (jmpark)                                                            #
# Description        : Setting of Single or MCMM Scenarios.                                       #
# Usage              :                                                                            #
# Init Release Date  : 2023.03.31                                                                 #
# Last Update  Date  : 2023.08.22                                                                 #
# Last Update  Date  : 2024.10.10                                                                 #
# Script Version     : 0.3                                                                        #
# Revision History   :                                                                            #
#         2023.03.31 - first released                                                             #
#         2023.06.08 - Change MCMM constraint path , Change other cond variables                  #
#         2023.08.22 - Add Variable & Scenario Actvie                                             #
#                       -> select_block_scenario                                                  #
#                       -> active_scn                                                             #
#         2024.10.10 - Add Variable & Scenario Actvie                                             #
#                       -> Setting MCMM Scenario option                                           #
#                       -> Setting SET_QOR_STRATEGY_METRIC                                        #
#                                                                                                 #
###################################################################################################
proc_time scenario_START -enable_log -log_prefix runtime
set volt_file ${RUN_DIR}/con/${TOP_DESIGN}.set_voltage.tcl

if {$USE_MCMM} {
    mcmm_sanity_checker
    #-- MCMM_SCN_NUM foreach START
    for {set t 0} { $t < $MCMM_SCN_NUM} {incr t} {
        set MCMM_SCN2(NAME)  [lindex $SET_SCENARIO $t]
		set MCMM_SCN2(TLUP)  [lindex $MCMM_TLUPLUS_MAX_FILES $t]
		set MCMM_SCN2(OPCON) [lindex $MCMM_MAX_OPCON_NAME $t]
		set MCMM_SCN2(OPT)   [lindex $MCMM_OPT_TARGET $t]
		set MCMM_SCN2(CON)   [lindex $MCMM_CONSTRAINTS_FILES $t]

        if { [info exists MCMM_OPCON_LIB_NAME] && ${MCMM_OPCON_LIB_NAME} != ""} {
            set MCMM_SCN2(OPLIB) [lindex $MCMM_OPCON_LIB_NAME $t ]
        } else {
            set MCMM_SCN2(OPLIB)  $mcmm_opcon_lib_name($MCMM_SCN2(NAME))
        }

		puts "\n <ADF_INFO>: Generating Library $MCMM_SCN2(OPLIB)..\n"
		puts "\n <ADF_INFO>: Generating Scenario $MCMM_SCN2(NAME)...\n"

		create_scenario $MCMM_SCN2(NAME)

        #-- Read prj_lib_split.tcl
        source -e -verbose ${PRJ_DC_SYN}/prj_lib_split.tcl

        puts "\n<ADF_INFO> : proc = $CORNER_PROC , volt = $CORNER_VOLT , temp = $CORNER_TEMP"

        #-- Reading volt_file
        if { [file exists $volt_file ] } {
            puts  "\n<ADF_INFO> : Voltage setting : $volt_file"
            source -e -v  $volt_file
        }

        #-- Reading Constraint File
		puts "\n <ADF_INFO>: Reading Constraint Fil\n "
        redirect -tee ${LOG_DIR}/${TOP_DESIGN}.read_constraint_scn${t}.log {
            source -echo -verbose $MCMM_SCN2(CON)
        }

        #-- Setting operating_conditions
		puts "\n<ADF_INFO> : set_operating_conditions -max_library   $MCMM_SCN2(OPLIB) -max $MCMM_SCN2(OPCON)\n"
		puts "\n<ADF_INFO> : Using TLUPlus file $MCMM_SCN2(TLUP) for $MCMM_SCN2(NAME).\n"
		set_operating_conditions -max_library $MCMM_SCN2(OPLIB)   -max $MCMM_SCN2(OPCON)

		set_tlu_plus_files -max_tluplus $MCMM_SCN2(TLUP) -tech2itf_map ${MAP_FILE}
		set_extraction_options -reference_direction vertical
		check_tlu_plus_files

		#-- Setting MCMM Scenario option
		#modfiy jmpark 241010
        
	 	set scn_option "set_scenario_options"
     	if { [string match "*S*" $MCMM_SCN2(OPT)] } {
     	   append scn_option " -setup true"
     	}
     	if { [string match "*H*" $MCMM_SCN2(OPT)] } {
     	   append scn_option " -hold true"
     	}
     	if { [string match "*L*" $MCMM_SCN2(OPT)] } {
     	   append scn_option " -leakage_power true"
     	}
     	if { [string match "*D*" $MCMM_SCN2(OPT)] } {
     	   append scn_option " -dynamic_power true"
     	}
     	if {$MCMM_SCN2(OPT) == ""} {
     	   puts "ADT-WARNING: You didn't designate optimization target for $MCMM_SCN2(NAME). Setup and Leakage optimization will be automatically selected."
     	   set scn_option "set_scenario_options -setup true -hold false -leakage_power true -dynamic_power false"
     	}
     	puts "ADT-INFORMATION: $scn_option for $MCMM_SCN2(NAME)."
     	eval $scn_option
     	report_scenario_options

        #-- Abstraction Flow Top <--> Block Scenario Mapping
        if { $IMPL_BLOCK_ABS_NAME != "NONE"} {
            foreach block_abs_name $IMPL_BLOCK_ABS_NAME {
                select_block_scenario -scenarios $MCMM_SCN2(NAME) -block_references ${block_abs_name} -block_scenario $MCMM_SCN2(NAME)
            }
        }

	}
    #-- MCMM_SCN_NUM foreach END
    #-- Setting active scenario
    if { [info exist active_scn] } {
        set_active_scenarios  $active_scn
    }

	report_scenarios         > ${REPORT_DIR}/${TOP_DESIGN}.scenarios.rpt
    report_block_abstraction > ${REPORT_DIR}/${TOP_DESIGN}.block_abstraction_after_scn_setup.rpt


} else {
    #-- Create Scenario
	if {[shell_is_in_topographical_mode]} {
        create_scenario $SCENARIO_NAMES
    }

    #-- Read prj_lib_split.tcl
    source -e -verbose ${PRJ_DC_SYN}/prj_lib_split.tcl

    puts "\n<ADF_INFO> : proc = $CORNER_PROC , volt = $CORNER_VOLT , temp = $CORNER_TEMP"

    #-- Reading volt_file
    if { [file exists $volt_file ] } {
        puts  "\n<ADF_INFO> : Voltage setting : $volt_file"
        source -e -v  $volt_file
    }

    #-- Reading Constraint File
	puts "\n <ADF_INFO>: Reading Constraint File \n"
    redirect -tee ${LOG_DIR}/${TOP_DESIGN}.read_constraint.log {
        source -echo -verbose ${COMMON_SDC}/common_sdc.tcl
    }

    #-- Setting operating_conditions
	# add jmpark USE_SAIF option (for dynamic_power)
    if {[shell_is_in_topographical_mode]} {
	    if {$SET_QOR_STRATEGY_METRIC == "total_power" || $USE_SAIF == "true"} {
    	   set_scenario_options -setup true -hold true -leakage_power true -dynamic_power true
      	} else {
      	   set_scenario_options -setup true -hold true -leakage_power true
      	}
		set_operating_conditions -max_library $OPCON_LIB_NAME -max $OPCON_NAME
		set_tlu_plus_files -max_tluplus $TLUPLUS_MAX_FILE -tech2itf_map ${MAP_FILE}
		set_extraction_options -reference_direction vertical
		check_tlu_plus_files
    } else {
		set_operating_conditions -max_library $OPCON_LIB_NAME -max $OPCON_NAME
	}

    #-- Abstraction Flow Top <--> Block Scenario Mapping
    if {[shell_is_in_topographical_mode]} {
        if { $IMPL_BLOCK_ABS_NAME != "NONE"} {
            foreach block_abs_name $IMPL_BLOCK_ABS_NAME {
                select_block_scenario -block_references ${block_abs_name} -block_scenario $SCENARIO_NAMES
            }
        }
        report_scenarios         > ${REPORT_DIR}/${TOP_DESIGN}.scenarios.rpt
        report_block_abstraction > ${REPORT_DIR}/${TOP_DESIGN}.block_abstraction_after_scn_setup.rpt
    }
}


# leakge derate
if { $DK_TYPE == "SEC" && $PROCESS == "LN05LPEA00" } {
	# Logic
    set CNT [get_lib_cells -quiet *_sc_*6t_*_hvt*/*]     ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.598 \[get_lib_cells -quiet *_sc_*6t_*_hvt*/*\]"     ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*6t_*_rvt*/*]     ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.591 \[get_lib_cells -quiet *_sc_*6t_*_rvt*/*\]"     ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*6t_*_lvt*/*]     ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.660 \[get_lib_cells -quiet *_sc_*6t_*_lvt*/*\]"     ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*6t_*_slvt*/*]    ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.881 \[get_lib_cells -quiet *_sc_*6t_*_slvt*/*\]"    ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*m7p5t_*_hvt*/*]  ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.486 \[get_lib_cells -quiet *_sc_*m7p5t_*_hvt*/*\]"  ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*m7p5t_*_rvt*/*]  ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.416 \[get_lib_cells -quiet *_sc_*m7p5t_*_rvt*/*\]"  ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*m7p5t_*_lvt*/*]  ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.353 \[get_lib_cells -quiet *_sc_*m7p5t_*_lvt*/*\]"  ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*m7p5t_*_slvt*/*] ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.486 \[get_lib_cells -quiet *_sc_*m7p5t_*_slvt*/*\]" ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*_flkp_*/*]       ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.000 \[get_lib_cells -quiet *_sc_*_flkp_*/*\]"       ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*_pmkp_*/*]       ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.000 \[get_lib_cells -quiet *_sc_*_pmkp_*/*\]"       ; puts "$cmd" ; eval $cmd }

	# SRAM
    set CNT [get_lib_cells -quiet *_mc_*/*]              ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.416 \[get_lib_cells -quiet *_mc_*/*\]"              ; puts "$cmd" ; eval $cmd }
}

if { $DK_TYPE == "SEC" && $PROCESS == "LN05LPE" } {
	# Logic
    set CNT [get_lib_cells -quiet *_sc_*6t_*_hvt*/*]     ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.598 \[get_lib_cells -quiet *_sc_*6t_*_hvt*/*\]"     ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*6t_*_rvt*/*]     ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.591 \[get_lib_cells -quiet *_sc_*6t_*_rvt*/*\]"     ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*6t_*_lvt*/*]     ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.660 \[get_lib_cells -quiet *_sc_*6t_*_lvt*/*\]"     ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*6t_*_slvt*/*]    ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.881 \[get_lib_cells -quiet *_sc_*6t_*_slvt*/*\]"    ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*m7p5t_*_hvt*/*]  ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.486 \[get_lib_cells -quiet *_sc_*m7p5t_*_hvt*/*\]"  ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*m7p5t_*_rvt*/*]  ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.416 \[get_lib_cells -quiet *_sc_*m7p5t_*_rvt*/*\]"  ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*m7p5t_*_lvt*/*]  ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.353 \[get_lib_cells -quiet *_sc_*m7p5t_*_lvt*/*\]"  ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*m7p5t_*_slvt*/*] ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.486 \[get_lib_cells -quiet *_sc_*m7p5t_*_slvt*/*\]" ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*_flkp_*/*]       ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.000 \[get_lib_cells -quiet *_sc_*_flkp_*/*\]"       ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cells -quiet *_sc_*_pmkp_*/*]       ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.000 \[get_lib_cells -quiet *_sc_*_pmkp_*/*\]"       ; puts "$cmd" ; eval $cmd }

	# SRAM
    set CNT [get_lib_cells -quiet *_mc_*/*]              ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.416 \[get_lib_cells -quiet *_mc_*/*\]"              ; puts "$cmd" ; eval $cmd }
}

if { $DK_TYPE == "SEC"  && $PROCESS == "LN04LPP" } {
	# Logic
    set CNT [get_lib_cell -quiet *_sc_*/*]               ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.370 \[get_lib_cells -quiet *_sc_*s6p25t*/*\]"     ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cell -quiet *_sc_*_flkp_*/*]        ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.370 \[get_lib_cells -quiet *_sc_*s7p94t*/*\]"     ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cell -quiet *_sc_*_pmkp_*/*]        ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.000 \[get_lib_cells -quiet *_sc_*_flkp_*/*\]"     ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cell -quiet *_sc_*_pmkp_*/*]        ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.000 \[get_lib_cells -quiet *_sc_*_pmkp_*/*\]"     ; puts "$cmd" ; eval $cmd }

	# SRAM
    set CNT [get_lib_cell -quiet *_mc_*/*]               ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.370 \[get_lib_cells -quiet *_mc_*/*\]"            ; puts "$cmd" ; eval $cmd }
}

if { $DK_TYPE == "SEC"  && $PROCESS == "SF2P" } {
	# Logic
    set CNT [get_lib_cell -quiet *_sc_*/*]               ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.421 \[get_lib_cells -quiet *_sc_*/*\]"            ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cell -quiet *_sc_*_flkp_*/*]        ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.000 \[get_lib_cells -quiet *_sc_*_flkp_*/*\]"     ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cell -quiet *_sc_*_pmkp_*/*]        ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.000 \[get_lib_cells -quiet *_sc_*_pmkp_*/*\]"     ; puts "$cmd" ; eval $cmd }

	# SRAM
    set CNT [get_lib_cell -quiet *_mc_*/*]               ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.421 \[get_lib_cells -quiet *_mc_*/*\]"            ; puts "$cmd" ; eval $cmd }
}

if { $DK_TYPE == "SEC"  && $PROCESS == "SF2" } {
	# # /dk/SF2/SEC/SF2/DM/Samsung_Foundry_SF2_SFDK_Design_Methodology_Overview_REV1.03.pdf (Page : 113)
	# puts "Information_ADF: When the temperature is 125c, the leakage derate is applied as 1.366, and in all other cases, it is applied as 1.500"	
	# if { $CORNER_TEMP == "125c" } {
	# 	set D_VALUE "1.366"
	# } else {
	# 	set D_VALUE "1.500"
	# }

	# # Logic
    # set CNT [get_lib_cell -quiet *_sc_*/*]               ; if { $CNT > 0 } { set cmd "set_power_derate -leakage ${D_VALUE} \[get_lib_cells -quiet *_sc_*/*\]"            ; puts "$cmd" ; eval $cmd }
    # set CNT [get_lib_cell -quiet *_sc_*_flkp_*/*]        ; if { $CNT > 0 } { set cmd "set_power_derate -leakage ${D_VALUE} \[get_lib_cells -quiet *_sc_*_flkp_*/*\]"     ; puts "$cmd" ; eval $cmd }
    # set CNT [get_lib_cell -quiet *_sc_*_pmkp_*/*]        ; if { $CNT > 0 } { set cmd "set_power_derate -leakage ${D_VALUE} \[get_lib_cells -quiet *_sc_*_pmkp_*/*\]"     ; puts "$cmd" ; eval $cmd }

	# Logic
    set CNT [get_lib_cell -quiet *_sc_*/*]               ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.421 \[get_lib_cells -quiet *_sc_*/*\]"            ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cell -quiet *_sc_*_flkp_*/*]        ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.000 \[get_lib_cells -quiet *_sc_*_flkp_*/*\]"     ; puts "$cmd" ; eval $cmd }
    set CNT [get_lib_cell -quiet *_sc_*_pmkp_*/*]        ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.000 \[get_lib_cells -quiet *_sc_*_pmkp_*/*\]"     ; puts "$cmd" ; eval $cmd }

	# SRAM
    set CNT [get_lib_cell -quiet *_mc_*/*]               ; if { $CNT > 0 } { set cmd "set_power_derate -leakage 1.421 \[get_lib_cells -quiet *_mc_*/*\]"            ; puts "$cmd" ; eval $cmd }
}

proc_time scenario_END -enable_log -log_prefix runtime
