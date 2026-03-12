################################################################################
# File Name     : lib_scaling_setup.tcl
# Author        : DT-PI
# Creation Date : 2024-07-08
# Last Modified : 2025-08-04
# Version       : v0.4
# Location      : ${PRJ_PT}/design_scripts/run_sta.tcl
#-------------------------------------------------------------------------------
# Description   :
#   setting for library scaling
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-07-08] : jjh8744
#       - Initial Version Release
# 	v0.2 [2024-11-21] : jjh8744
#       - Add condition (# 1ea ALL_VDD_LIST)
# 	v0.3 [2025-01-03] : jjh8744
#       - changed CHECK_VOLTAGE format
# 	v0.4 [2025-08-04] : jaeeun1115
#       - Setting upf & lib scaling file path
#
#-------------------------------------------------------------------------------
# Useage        :
#		pt_shell> source lib_scaling_setup.tcl
#################################################################################

# Before link ;#------------------------------------------------------------------------------
# Before link ;# Enabling Simultaneous Multi-Voltage Analysis for cross-domain paths analysis
# Before link ;#------------------------------------------------------------------------------
# Before link if {[info exist CROSS_VOLTAGE_ANALYSIS] && $CROSS_VOLTAGE_ANALYSIS } {
# Before link   echo "** SEC_INFO: enabling SMVA cross domain paths analysis"
# Before link   set_app_var timing_enable_cross_voltage_domain_analysis       true
# Before link   set_app_var timing_cross_voltage_domain_analysis_mode         only_crossing ;# "legacy" option has been removed.
# Before link   set_app_var scaling_calculation_compatibility         false
# Before link   if {$pt_main_version >= 2019.12} {
# Before link    set_app_var timing_enable_derate_scaling_for_library_cells_compatibility  false
# Before link    set_app_var timing_continue_on_scaling_error  true
# Before link   }
# Before link }

if { $MULTI_VDD || $CROSS_VOLTAGE_ANALYSIS || $DVD_AWARE } {

	# Setting and source $UPF
	if { ${UPF} == "AUTO_DETECT" } {
		# UPF Auto detect
		set prio1_UPF "$STA_SCRIPT_DIR/${TOP_DESIGN}.upf"
		set prio2_UPF "[set ${TOP_DESIGN}(UPF_DIR)]/${TOP_DESIGN}.upf"

        if { [file exist $prio1_UPF] } {
            set UPF "$prio1_UPF"
        } else {
            set UPF "$prio2_UPF"
        }

		if { [file exist $UPF] } {
			puts "Information_ADF: Auto detect UPF ($UPF)"
			puts "Information_ADF: Read UPF ($UPF)"
			source -e -v $UPF
        } else {
			puts "Warning_ADF: \"$UPF\" file does not exist."
			incr exit_cnt
		}
	} else {
		# UPF User define
		if { [file exist $UPF] } {
			puts "Information_ADF: User define UPF ($UPF)"
			puts "Information_ADF: Read UPF ($UPF)"
			source $UPF
		} else {
			puts "Error_ADF: User define UPF does not exist. ($UPF)"
			exit -1
		}
	}
	
	# Source set_voltage
	set SET_VOLTAGE "[set ${BLK}(UPF_DIR)]/${TOP_DESIGN}_set_power_domains.tcl"
	if { [file exist $SET_VOLTAGE] } {
		puts "Information_ADF: Setting for set_voltage ($SET_VOLTAGE)"
		source $SET_VOLTAGE
	} else {
		puts "Warning_ADF: \"$SET_VOLTAGE\" does not exist."
		puts "Warning_ADF: If the supply nets in the UPF file are defined as set_voltage, this Warning_ADF is waived."
		incr exit_cnt
	}
	
	# Check if the file exists. 
	if { [info exist exit_cnt] && $exit_cnt == "2" } {
		puts "Error_ADF: Both \${UPF} and ${TOP_DESIGN}_set_power_domains.tcl files do not exist."
		exit -1
	}
	
	# Setting for library scaling
	set prio1_file "$STA_SCRIPT_DIR/lib_scaling_group.$CORNER.tcl"
	set prio2_file "[set ${BLK}(UPF_DIR)]/scaling_lib_list.[string tolower $CORNER_PROC]_[string tolower $CORNER_TEMP].txt"
	set prio3_file "${RUN_DIR}/scaling_lib_list_autogen.[string tolower $CORNER_PROC]_[string tolower $CORNER_TEMP].txt"
	
	if {[file exist ${prio1_file}]} {
		echo "** SEC_INFO: Sourcing library scaling group - $prio1_file"
		source -e -v ${prio1_file}
	} elseif {[file exist ${prio2_file}]} {
		set lib_list_file	 [glob -nocomplain $prio2_file]
		sec_generate_scaling_lib_groups \
		  	  -lib_files [sec_make_list_from_file $lib_list_file] \
		  	  -output ./lib_scaling_group.autogen.tcl
		echo "** SEC_WARN: 1st priority library scaling file does not exist - ${prio1_file}"
		echo "** SEC_WARN: Sourcing auto generated library scaling group - ./lib_scaling_group.autogen.tcl"
		source ./lib_scaling_group.autogen.tcl
	} else {
		echo "Information_ADF: 1st priority library scaling file does not exist - ${prio1_file}"
		echo "Information_ADF: 2st scaling library list file does not exist     - ${prio2_file}"
		echo "Information_ADF: Auto generation \"$prio3_file\" file."
		
		set CORE_VDD  [lindex [regexp -all -inline {\d+p[^_]*v} $CORNER] 0]
		set PRIM_LIB_FILE "${LIB_DIR}/abs/00_PRIM/${ABS_PRIM_VERSION}/00_DB/${LIB_CORNER}.db.abs.list"
	
		set MAX_VDD_LIST [get_attr -quiet [get_supply_nets *] voltage_max]
		set MIN_VDD_LIST [get_attr -quiet [get_supply_nets *] voltage_min]
	
		set MAX_MIN_VDD_LIST "$MAX_VDD_LIST $MIN_VDD_LIST"
		set MAX_MIN_VDD_LIST [lsort -unique -increasing $MAX_MIN_VDD_LIST]
	
		set SUPPLY_GROUP_RPT "${RPT_DIR}/report_supply_group.rpt"
		report_supply_group > ${SUPPLY_GROUP_RPT}
	
		set Fin [open $SUPPLY_GROUP_RPT r]
		set TEMP_VDD_LIST ""
		while { [gets $Fin line] != -1 } {
		    if { [regexp {^#} $line] || ![regexp {\w+} $line] } { continue }
		    if { [string match "*delay Voltage*" $line] } {
				set VDD [lindex $line end]
				lappend TEMP_VDD_LIST $VDD
		    }
		}
		close $Fin 
	
		set TEMP_VDD_LIST "$TEMP_VDD_LIST $MAX_MIN_VDD_LIST"
		set MAX_VOLTAGE [lindex [lsort -unique -increasing $TEMP_VDD_LIST] end]
		set MIN_VOLTAGE [lindex [lsort -unique -increasing $TEMP_VDD_LIST] 0]
		if { $MIN_VOLTAGE == "0" } {
			set MIN_VOLTAGE [lindex [lsort -unique -increasing $TEMP_VDD_LIST] 1]
		}
	
		set ALL_VDD_LIST ""
		set CHECK_VOLTAGE "[format "%.4f" $MIN_VOLTAGE]"
		set CHECK_FLAG    "1"
		while { $CHECK_FLAG } {
			if {[file exist [regsub "$CORE_VDD" $PRIM_LIB_FILE [regsub {\.} ${CHECK_VOLTAGE}v "p"]]]} {
				lappend ALL_VDD_LIST $CHECK_VOLTAGE
				puts "$ALL_VDD_LIST"
			}
		
			if { $CHECK_VOLTAGE > $MAX_VOLTAGE } {
				set CHECK_FLAG "0"
			}
			set CHECK_VOLTAGE [format "%.4f" [expr $CHECK_VOLTAGE + 0.0050]]
		}
	
		if { [llength $ALL_VDD_LIST] > 1 } {
			foreach VDD $ALL_VDD_LIST {
				set VDD "[regsub {\.} [string range $VDD 0 5] "p"]v"
				set VDD_LIB_LIST [regsub $CORE_VDD $PRIM_LIB_FILE ${VDD}]
				if { [file exist $VDD_LIB_LIST] } {
					lappend ALL_VDD_LIB_LIST $VDD_LIB_LIST
					set ALL_VDD_LIB_LIST [lsort -unique $ALL_VDD_LIB_LIST]
				} else {
					puts "Warning_ADF: \"$VDD_LIB_LIST\" file does not exist."
					puts "Warning_ADF: Ignore the other voltage DB lists except for the Standard cell voltage.(Ex. IO, IP,...)"
				}
			}
		} else {
			# 1ea ALL_VDD_LIST
			set CHECK_VOLTAGE "[format "%.4f" $ALL_VDD_LIST]"
			set CHECK_VOLTAGE_org $CHECK_VOLTAGE
	
			foreach MAX_MIN {MAX MIN} {
				set CHECK_VOLTAGE $CHECK_VOLTAGE_org
				set CHECK_FLAG    "1"
				set CHECK_CNT     "0"
			
				while { $CHECK_FLAG } {
					if { ($CHECK_CNT > 1) || ($CHECK_VOLTAGE <= 0.000) || ($CHECK_VOLTAGE > 1.000) } {
						set CHECK_FLAG "0"
					}
					set VDD_LIB_NAME [regsub "$CORE_VDD" $PRIM_LIB_FILE [regsub {\.} ${CHECK_VOLTAGE}v "p"]]
					if {[file exist $VDD_LIB_NAME]} {
						lappend ALL_VDD_LIST $CHECK_VOLTAGE
						puts "$ALL_VDD_LIST"
						lappend ALL_VDD_LIB_LIST $VDD_LIB_NAME
						set ALL_VDD_LIB_LIST [lsort -unique $ALL_VDD_LIB_LIST]
						incr CHECK_CNT
					}
					if { ${MAX_MIN} == "MAX" } {
						set CHECK_VOLTAGE [format "%.4f" [expr $CHECK_VOLTAGE + 0.0050]]
					} else {
						set CHECK_VOLTAGE [format "%.4f" [expr $CHECK_VOLTAGE - 0.0050]]
					}
				}
			}
		}
		set CAT_CMD "exec cat $ALL_VDD_LIB_LIST | sort -u | sed \"/^#/d\" > ${prio3_file}"
		eval $CAT_CMD
	
		if {[file exist ${prio3_file}]} {
			set lib_list_file	 [glob -nocomplain $prio3_file]
			sec_generate_scaling_lib_groups \
			  	  -lib_files [sec_make_list_from_file $lib_list_file] \
			  	  -output ./lib_scaling_group.autogen.tcl
			echo "Information_ADF: Sourcing auto generated library scaling group - ./lib_scaling_group.autogen.tcl"
			source ./lib_scaling_group.autogen.tcl
		} else {
			echo "Error_ADF: Library scaling file does not exist, Check your library scaling file"
			exit -1
		}
	}
}
