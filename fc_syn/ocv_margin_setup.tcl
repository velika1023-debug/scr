###################################################################################################
# File               : ocv_margin.tcl                                                             #
# Author             : ADT-DT (jblee)                                                             #
# Description        : Apply ocv derating values                                                  #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################
if { $is_AOCVM || $is_POCVM } {

	# pocvm application options setting
	set_app_options -name time.enable_constraint_variation                          -value true
	set_app_options -name time.enable_slew_variation                                -value true
	set_app_options -name time.ocvm_enable_distance_analysis                        -value true
	set_app_options -name time.pocvm_corner_sigma                                   -value $CORNER_SIGMA
	set_app_options -name time.pocvm_enable_analysis                                -value true
	set_app_options -name time.pocvm_precedence                                     -value "library"
	
	# translate and apply set_ocv_margin.*.log extracted from PrimeTime
	foreach_in_collection corner [all_corners] {
	    set c_name [get_attribute $corner name]
	
	    set INPUT "${COMMON_CON_DIR}/set_ocv_margin.$c_name.log"
	    set OUTPUT "ocv_derate.$c_name.tcl"
	
	    if { [file exists $INPUT] } {
	        current_corner $c_name
	
	        if { [string match "2nm" $TECHNOLOGY_NODE] } {
	            sh ${COMMON_TCL}/fc_syn/edit_ocv_margin_file.2nm.csh $INPUT $OUTPUT
	        } else {
	            sh ${COMMON_TCL}/fc_syn/edit_ocv_margin_file.csh $INPUT $OUTPUT
	        }
	        source -echo -verbose -continue_on_error $OUTPUT
	
	        ## report derating value
	        redirect -file ${REPORT_DIR}/${TOP_DESIGN}.ocv_derate.$c_name.rpt \
	        {report_timing_derate -pocvm_guardband -pocvm_coefficient_scale_factor -nosplit -corners $c_name}
	
	    } else {
	        puts "Error_ADF: $INPUT file dosen't exists. Please check !!!"
	    }
	}
	puts "Information_ADF: OCV derate from PrimeTime has beed applied. Check *ocv_derate*.rpt"
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
