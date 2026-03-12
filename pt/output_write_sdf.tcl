################################################################################
# File Name     : output_write_sdf.tcl
# Author        : iskim1001,emlee
# Creation Date : 2024-05-13
# Last Modified : 2025-12-02
# Version       : v1.4
# Location      : ${PRJ_PT}/design_scripts/run_sta.tcl
#-------------------------------------------------------------------------------
# Description   :
# 	This file is an example file. This header is used to track the version and
# 	change history of the file.
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2023-09-07] : iskim1001
#       - Initial Version Release
# 	v0.2 [2024-05-13] : iskim1001
#       - output_write_sdf.tcl and write_sdf.tcl have been integrated.
# 	v0.3 [2024-05-16] : iskim1001
#       - write_sdf option modify.
#       	-significant_digits value modify ( 6 -> 3 )
#       	-no_negative_values option remove
#       - The write_sdf option was modified as in the DM example.
#			- /misc/dk/SEC/LN05LPEA00/DM/Foundry/Samsung_Foundry_LN05LPE_SFDK_STA_PrimeTime_ApplicationNote_REV1.00.pdf (Example 8-1)
# 	v0.4 [2024-05-24] : iskim1001
#       - ADF Message Rule Change
#       	Before : <ADF_ERROR>: , <ADF_WARN>:  , <ADF_INFO>:
#       	After  : Error_ADF:   , Warning_ADF: , Information_ADF:
# 	v0.5 [2024-06-18] : iskim1001
#       - Removed the options from the "reset_timing_derate" command.
#   v0.6 [2025-02-13] : sjlee
#       - Added "remove_clock_uncertainty" for gen_fsdb
#   v0.7 [2025-02-14] : sjlee
#       - set_load 0 only data boundary
#       - Separated 'setup', 'hold' flow
#   v0.8 [2025-02-25] : sjlee
#       - setup, hold only scenario exceptions removed for hacking
#	v0.9 [2025-03-19] : sjlee
#		- remove exceptions selectively by $MINMAX when fsdf
#		- Margin options are moved to 'write_sdf' by RVP_1M (http://redmine.adtek.co.kr:21380/issues/6075#note-135)
#	v1.0 [2025-06-19] : sjlee
#	    - remove exceptions when sdf and fsdf
#	    - gba -> pba
#	    - write exceptions automatically by sourcing pt2tmax
#	v1.1 [2025-07-01] : sjlee
#	    - save_session when gen_sdf
#	v1.2 [2025-07-15] : sjlee
#	    - generate pba_gba report because write_sdf is in gba
#	v1.3 [2025-07-21] : sjlee
#	    - all flows in gba and pt2tmax not supported automatically
#	v1.4 [2025-09-23] : sjlee
#	    - adjust uncertainty and clock gating check value
#	v1.5 [2025-12-02] : iskim1001 ( eunjoole, jjang, pjm1023)
#       - write_sdf option modify.
#       	-significant_digits value modify ( 3 -> 4 )
#         The value of -significant in write_sdf has been changed to 4, matching the STA report.
#         (Because this is rounded, accumulated delays on extremely long paths can affect SIM failures.)
#
#-------------------------------------------------------------------------------
# Usage        :
# 	# FAKE_SDF
# 	pt_shell > set gen_fsdf 1
# 	pt_shell > source  ${COMMON_TCL_PT}/FAKE_setup_hold_violation.{tcl,tbc}
# 	pt_shell > source output_write_sdf.tcl
#
# 	# Real SDF
# 	pt_shell > set gen_sdf 1
# 	pt_shell > source  ${COMMON_TCL_PT}/FAKE_setup_hold_violation.{tcl,tbc}
# 	pt_shell > source output_write_sdf.tcl
#################################################################################

# Directory Create SDF & FSDF Common
set REPORT_DIR_SDF ${REPORT_DIR}/sdf ; file mkdir $REPORT_DIR_SDF
set OUTPUT_DIR_SDF ${OUTPUT_DIR}/sdf ; file mkdir $OUTPUT_DIR_SDF
set FILE_FAKE_TBC  ${COMMON_TCL_PT_PROC}/proc_FAKE_SETUP_HOLD.tbc
set FILE_FAKE_TCL  ${COMMON_TCL_PT_PROC}/proc_FAKE_SETUP_HOLD.tcl

if {[info exists gen_sdf]  && ${gen_sdf}  } {
    set FILE_SDF ${OUTPUT_DIR_SDF}/${DESIGN}.${MODE}.${CORNER}.sdf
} elseif {[info exists gen_fsdf] && ${gen_fsdf} } {
    set FILE_SDF ${OUTPUT_DIR_SDF}/${DESIGN}.${MODE}.${CORNER}_fake.sdf
}

# This is for reset exceptions to one-side scenario
if {$MINMAX != "min_max"} {
	puts "\$MINMAX != min_max. So exception would be removed because it's setup or hold only scenario."
	puts "Constraints would be sourced again. It may take a long time."
    if {$MINMAX == "max"} {
        reset_path -hold -to [all_outputs]
        reset_path -hold -from $data_input_ports
        reset_path -hold -from [all_registers]
        reset_path -hold -to [all_registers]
        if {$cg_data_pins != ""} {
    	    reset_path -hold -to $cg_data_pins
        }
    	remove_disable_timing [get_lib_timing_arcs -of [get_lib_cells -of [all_registers]]]
    } else {
        reset_path -setup -to [all_outputs]
        reset_path -setup -from $data_input_ports
        reset_path -setup -from [all_registers]
        reset_path -setup -to [all_registers]
        if {$cg_data_pins != ""} {
    	    reset_path -setup -to $cg_data_pins
        }
    	remove_disable_timing [get_lib_timing_arcs -of [get_lib_cells -of [all_registers]]]
    }
	source ${COMMON_SDC}/common_sdc.tcl


    source ${UTIL_SCRIPT_DIR}/sec_set_hold_uncertainty.tbc
    sec_set_hold_uncertainty -verbose -tech $TECH       -data_file $hld_tech_file
    source ${STA_SCRIPT_DIR}/set_combo_clock_gator_margin.tcl

	# ideal generated clock propagation
	if {[regexp -nocase {POST} $PRE_POST]} {
		foreach_in_collection iclk [get_clocks -quiet * -filter "propagated_clock == false && defined(sources)"] {
	    	echo "** SEC_WARN: clock '[get_object_name $iclk]' is ideal mode in post-layout STA"
	    	echo "             forcing propagated mode for the clock"
	    	set_propagated_clock $iclk
		}
	}
    update_timing -full
}

# Timing check by report_global_timing in GBA mode
report_global_timing -sig 4            > ${REPORT_DIR_SDF}/${MODE}.${CORNER}.report_global_timing.before.gba.rpt



# Margins are removed because sdf is generated in GBA mode
set_app_var si_enable_analysis           false
set_app_var timing_pocvm_enable_analysis false
set_app_var timing_aocvm_enable_analysis false
#remove_clock_uncertainty [all_clocks]
report_global_timing -sig 4            > ${REPORT_DIR_SDF}/${MODE}.${CORNER}.report_global_timing.margin_off.gba.rpt


# Hack
if {[info exists gen_fsdf] && ${gen_fsdf} } {
	puts "Information_ADF: FAKE_SDF"
	puts "Information_ADF: Sets the load and resistance of the net connected to the port to 0."

    set ports_clock_root [filter_collection [get_attribute [get_clocks] sources] object_class==port]
    set port_nets [get_nets -of_object [remove_from_collection [get_ports *] $ports_clock_root]]

	foreach_in_collection each_net $port_nets {
		set_load 0 [get_nets $each_net]
		set_resistance 0 [get_nets $each_net]
	}

    # If both setup and hold are problematic, remove annotation
    #remove_clock_uncertainty [all_clocks]

	# setup & hold violation hacking
	puts "Information_ADF: FAKE_SDF"
	puts "Information_ADF: Hacking setup & hold violation."
	if { [file exists ${FILE_FAKE_TBC} ] } {
		source -e ${FILE_FAKE_TBC}
	} else {
		source -e ${FILE_FAKE_TCL}
	}
	# Create file "set_annotated_delay_for_{setup|hold}_hacking.list
    FAKE_SETUP_HOLD -type setup
	sh mv set_annotated_delay_for_setup_hacking.list*  ${REPORT_DIR_SDF}
	sh mv *_sep_*.summary                              ${REPORT_DIR_SDF}
	source -e ${REPORT_DIR_SDF}/set_annotated_delay_for_setup_hacking.list

    update_timing

    FAKE_SETUP_HOLD -type hold
	sh mv set_annotated_delay_for_hold_hacking.list*   ${REPORT_DIR_SDF}
	sh mv *_sep_*.summary                              ${REPORT_DIR_SDF}
	source -e ${REPORT_DIR_SDF}/set_annotated_delay_for_hold_hacking.list

}


# update_timing and save_session
update_timing          > ${REPORT_DIR_SDF}/update_timing_sdf_fsdf.log
report_global_timing   -sig 4        > ${REPORT_DIR_SDF}/${MODE}.${CORNER}.report_global_timing.after.gba.rpt

if {[info exists gen_fsdf] && ${gen_fsdf} } {
	save_session ${REPORT_DIR_SDF}/session.${MODE}.${CORNER}_fake_sdf
} else {
    save_session ${REPORT_DIR_SDF}/session.${MODE}.${CORNER}_sdf
}

## update_timing is done with proper margin at this point
## /misc/dk/SEC/LN05LPEA00/DM/Foundry/Samsung_Foundry_LN05LPE_SFDK_STA_PrimeTime_ApplicationNote_REV1.00.pdf
## Example 8-1 Example of Writing an SDF File
puts "Information_ADF: Not removing case analysis. SDF is mission mode"
write_sdf                             \
	-version 3.0                      \
	-context verilog                  \
	-no_internal_pins                 \
	-include {SETUPHOLD RECREM}       \
	-exclude {checkpins no_condelse}  \
	-input_port_nets -significant 4   \
	${FILE_SDF}


# For transition fault, check the location of pt2tmax tcl
puts "Information_ADF : source /misc/tool/SYNOPSYS/txs/W-2024.09-SP4/auxx/syn/tmax/pt2tmax.tcl"
