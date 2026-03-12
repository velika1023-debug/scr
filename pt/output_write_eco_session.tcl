################################################################################
# File Name     : output_write_eco_session.tcl
# Author        : jjh8744
# Creation Date : 2024-07-22
# Last Modified : 2024-07-22
# Version       : v0.1
# Location      : ${PRJ_PT}/design_scripts/run_teco.tcl
#-------------------------------------------------------------------------------
# Description   :
# 	This file creates input files for Primeclosure. (eco_session, pc_libin.tcl, ocv lib list)
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-07-22] : jjh8744
#       - Initial Version Release
#-------------------------------------------------------------------------------
# Useage        :
# 	pt_shell > source ${COMMON_TCL_PT}/output_write_eco_session.tcl
#################################################################################

set RUN_DIR [pwd]
if { [info exist multi_scenario_enable_analysis] && $multi_scenario_enable_analysis == "true" } {
	set ECO_SESSION_DIR "${RUN_DIR}/eco_session.dmsa"
} else {
	set ECO_SESSION_DIR "${RUN_DIR}/eco_session.${MODE}.${CORNER}"
}

# Check $PC_FIX_TARGET
if { ![info exist FIX_TARGETS] || $FIX_TARGETS == "" } {
	puts "Not define \$FIX_TARGET"
	exit
}

set PC_INPUT "${RUN_DIR}/pc_input"
if {[file exist ${PC_INPUT}]} {
   file delete -force ${PC_INPUT}
}
file mkdir ${PC_INPUT}

set targets [split $FIX_TARGETS "_"] ;# max_transition max_capacitance setup hold power noise seed max_fanout
set all_fix_type ""
foreach li $targets {
	if { [string match "mttv-merge" $li ] } {
		puts "Skip \"mttv-merge\""
	} else {
		regexp {^([^/-]+)} $li match fix_type
		puts $fix_type
		lappend all_fix_type $fix_type
	}
}
set all_fix_type [lsort -unique $all_fix_type]
set PC_FIX_TARGET ""
foreach fix_type $all_fix_type {
	if { [string match "mttv" $fix_type] } {
		lappend PC_FIX_TARGET max_transition
	} elseif { [string match "seed" $fix_type] } {
		if { [info exist multi_scenario_enable_analysis] && $multi_scenario_enable_analysis == "true" } {
			lappend PC_FIX_TARGET seed
		} else {
			puts "Error_ADF: \"seed\" can only be generated in DMSA."
		}
	} elseif { [string match "maxcap" $fix_type] } {
		lappend PC_FIX_TARGET max_capacitance
	} elseif { [string match "setup" $fix_type] || [string match "hold" $fix_type]|| [string match "power" $fix_type]} {
		lappend PC_FIX_TARGET $fix_type
	} else {
		puts "Error_ADF: Fixed type is not supported in PrimeClosure."
	}
}

# Make eco session for PrimeClousure
puts "#############################################################"
puts "# Fix target      : $PC_FIX_TARGET"
puts "# PBA mode        : $PBA_MODE"
if { [info exist multi_scenario_enable_analysis] && $multi_scenario_enable_analysis == "true" } {
	puts "# ECO session Dir : eco_session.dmsa"
} else {
	puts "# ECO session Dir : [lindex [split $ECO_SESSION_DIR "/"] end]"
}
puts "#############################################################"
set cmd "write_eco_session -smsa_data_types \"${PC_FIX_TARGET}\" -smsa_pba_mode \"${PBA_MODE}\" \\\n\t$ECO_SESSION_DIR"
puts "$cmd"
eval $cmd

# Edit corner_data
if { [info exist multi_scenario_enable_analysis] && $multi_scenario_enable_analysis == "true" } {
	foreach scn $SCENARIOS {
		lappend ALL_EDIT_FILE "${ECO_SESSION_DIR}/timing/${scn}/corner_data"
	}
} else {
	set ALL_EDIT_FILE "${ECO_SESSION_DIR}/timing/corner_data"
}

foreach EDIT_FILE $ALL_EDIT_FILE {
	set Pattern "set_timing_derate *filter_collection *area*|| is_memory_cell == true*"
	
	set Fin [open $EDIT_FILE r]
	set all_line_number ""
	set line_number 0
	
	while {[gets $Fin line] >= 0} {
		incr line_number
	    if { [string match $Pattern $line] } {
			lappend all_line_number $line_number
	    }
	}
	close $Fin
	
	if { [llength $all_line_number] > 0 } {
		sh cp -rf ${EDIT_FILE} ${EDIT_FILE}_org
		puts "Information_ADF: There are patterns that need modification. ($EDIT_FILE)"	
		puts "                 Pattern :"
		puts "                     $Pattern"
		puts ""
	
		foreach line_number $all_line_number {
			set sed_cmd_org  "exec sed -n \"${line_number}p\" $EDIT_FILE"
			set org_cmd [eval $sed_cmd_org]
	
			regexp {.*\[filter_collection[^\]]*\]\s*\{(area\s*(<=|>=|<|>|==|!=)\s*\d+(\.\d+)?)\s*\|\|\s*(is_memory_cell == (true|false))\}} $org_cmd filter_Condition area_Condition oper_Condition dummy memory_Condition
			regsub {\[filter_collection} $filter_Condition "" filter_Condition
			regsub {\].*} $filter_Condition "" filter_Condition
			regsub "\}$" $filter_Condition " \\&\\& $area_Condition\}]"   new_cmd_1
			regsub "\}$" $filter_Condition " \\&\\& $memory_Condition\}]" new_cmd_2
	
			set sed_cmd_head "exec sed -i \"${line_number}s/^/# /g\" $EDIT_FILE"
			set sed_cmd_tail "exec sed -i \"${line_number}s/$/ ;# The command is an error in smsa_shell./g\" $EDIT_FILE"
			eval $sed_cmd_head; eval $sed_cmd_tail
	
			exec echo ""		                                                            >> $EDIT_FILE
			exec echo "#########################################################"           >> $EDIT_FILE
			exec echo "# The ${line_number}-line command is replaced by the command below." >> $EDIT_FILE
			exec echo "#########################################################"           >> $EDIT_FILE
			exec echo "$new_cmd_1"                                                          >> $EDIT_FILE
			exec echo "$new_cmd_2"                                                          >> $EDIT_FILE
			exec echo ""		                                                            >> $EDIT_FILE
		}
	} else {
		puts "Information_ADF: No patterns need modification. ($EDIT_FILE)"
		puts "                 Pattern :"
		puts "                     $Pattern"
		puts ""
	}
}


# Create ocv lists and pc_libin.tcl
if {[file exists ${PC_INPUT}/ocv_list]} {
    file delete -force ${PC_INPUT}/ocv_list
}
file mkdir ${PC_INPUT}/ocv_list

# DMSA
if { [info exist multi_scenario_enable_analysis] && $multi_scenario_enable_analysis == "true" } {

	remote_execute {
		set_distributed_variables {PC_INPUT LIB_SOURCE_FILE_NAME_OUTPUT}
	
		# ocv lists
		foreach array_name [array name _LIB_CELLS] {
			set NAME $array_name
			regsub -all "," $NAME "--" fname
			get_object_name $_LIB_CELLS($NAME) > ${PC_INPUT}/ocv_list/${fname}.list
		}
		set All_File_path [sh ls ${PC_INPUT}/ocv_list/*.list]
		
		foreach File_path $All_File_path {
			exec sed -i {s/ /\n/g} $File_path
		}
	}

	set LIB_SOURCE_FILE_NAME_OUTPUT "${PC_INPUT}/pc_libin.tcl"
	sh rm -rf ${LIB_SOURCE_FILE_NAME_OUTPUT}
	foreach scn $SCENARIOS {
		current_scenario $scn
		remote_execute {
			set_distributed_variables {LIB_SOURCE_FILE_NAME_OUTPUT}

			# pc_libin.tcl
			set ALL_LIB_SOURCE_FILE_NAME [get_attr [get_lib] source_file_name]
			echo "if \{ \[string match \"*${MODE}.${CORNER}*\" \$SCENARIOS\] \} \{"      >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
			echo "##################################################################"    >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
			echo "# This pc_libin.tcl file is used as an input file for PrimeClosure.  " >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
			echo "# MODE   : $MODE                                                  "    >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
			echo "# CORNER : $CORNER                                                "    >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
			echo "##################################################################"    >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
			echo "libin -timing_type best worst -name ${MODE}.${CORNER} \" \\"		     >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
			foreach FILE_NAME $ALL_LIB_SOURCE_FILE_NAME {
				echo "$FILE_NAME \\"												     >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
			}
			echo "\""																     >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
			echo "\}"																     >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
		}
	}
	current_scenario -all

} else {

	# Single
	# ocv lists
	foreach array_name [array name _LIB_CELLS] {
		set NAME $array_name
		regsub -all "," $NAME "--" fname
		get_object_name $_LIB_CELLS($NAME) > ${PC_INPUT}/ocv_list/${fname}.list
	}
	set All_File_path [sh ls ${PC_INPUT}/ocv_list/*.list]
	
	foreach File_path $All_File_path {
		exec sed -i {s/ /\n/g} $File_path
	}
	
	# libin.tcl
	set LIB_SOURCE_FILE_NAME_OUTPUT "${PC_INPUT}/pc_libin.tcl"
	sh rm -rf ${LIB_SOURCE_FILE_NAME_OUTPUT}
	set ALL_LIB_SOURCE_FILE_NAME [get_attr [get_lib] source_file_name]
	echo "if \{ \[string match \"*${MODE}.${CORNER}*\" \$SCENARIOS\] \} \{"      >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
	echo "##################################################################"    >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
	echo "# This pc_libin.tcl file is used as an input file for PrimeClosure.  " >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
	echo "# MODE   : $MODE                                                  "    >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
	echo "# CORNER : $CORNER                                                "    >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
	echo "##################################################################"    >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
	echo "libin -timing_type best worst -name ${MODE}.${CORNER} \" \\"		     >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
	foreach FILE_NAME $ALL_LIB_SOURCE_FILE_NAME {
		echo "$FILE_NAME \\"												     >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
	}
	echo "\""																     >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
	echo "\}"																     >> ${LIB_SOURCE_FILE_NAME_OUTPUT}
}

sh touch ${RUN_DIR}/eco_session.done
