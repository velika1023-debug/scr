################################################################################
# File Name     : proc_sop_start_eco.tcl
# Author        : DT-PI(jjh8744)
# Creation Date : 2024-08-09
# Last Modified : 2024-08-09
# Version       : v0.1
# Location      : ${COMMON_TCL_PT}/pc_eco.tcl
#-------------------------------------------------------------------------------
# Description   :
#	When entering smsa_shell from dmsa_shell, an error occurs, so the start_mcmm and corner_data scripts must be modified using the sop_start_eco procedure before entering smsa_shell.
#-------------------------------------------------------------------------------
# Change Log    :
#   v0.1 [2023-08-09] : jjh8744
#   	- Initial release
#   v0.2 [2023-09-24] : jjh8744
#   	- Edit edited_start_eco_cmd variable
#-------------------------------------------------------------------------------
# Useage        :
# 	pc_shell > source proc_sop_start_eco.tcl
# 	pc_shell > sop_start_eco -mode ...
#################################################################################

proc sop_start_eco { args } {
	puts ""
	global aspen_pt_tim_lst asp_run_scr
	set cur_mode [get_current_eco_mode]
	if { ${cur_mode} == "dmsa" } {
		set flag "1"
	} else {
		set flag "0"
	}
	puts "Information_ADF: The current eco mode is set to \"$cur_mode\""
	
	if { $flag == "1" } {
		set script_only_start_eco_cmd "start_eco $args -script_only"
		puts "Information_ADF: Creating smsa scripts without execution."
		puts "                   => $script_only_start_eco_cmd"
		puts ""
		uplevel #0 "eval $script_only_start_eco_cmd"

		foreach lst $aspen_pt_tim_lst {
			set tim_scn         "[lindex $lst 0]"
			set tim_corner_data "[lindex $lst 1]/corner_data"
		
			set Pattern "set_timing_derate *filter_collection *area*|| is_memory_cell == true*"
		
			set Fin [open $tim_corner_data r]
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
				sh cp -rf $tim_corner_data ${tim_corner_data}_org
				puts "Information_ADF: There are patterns that need modification. ($tim_corner_data)"	
				puts "                 Pattern :"
				puts "                     $Pattern"
				puts ""
		
				foreach line_number $all_line_number {
					set sed_cmd_org  "exec sed -n \"${line_number}p\" $tim_corner_data"
					set org_cmd [eval $sed_cmd_org]
		
					regexp {.*\[filter_collection[^\]]*\]\s*\{(area\s*(<=|>=|<|>|==|!=)\s*\d+(\.\d+)?)\s*\|\|\s*(is_memory_cell == (true|false))\}} $org_cmd filter_Condition area_Condition oper_Condition dummy memory_Condition
					regsub {\[filter_collection} $filter_Condition "" filter_Condition
					regsub {\].*} $filter_Condition "" filter_Condition
					regsub "\}$" $filter_Condition " \\&\\& $area_Condition\}]"   new_cmd_1
					regsub "\}$" $filter_Condition " \\&\\& $memory_Condition\}]" new_cmd_2
		
					set tim_corner_data_edit_file "${tim_corner_data}_edit"
					if { ![file exist ${tim_corner_data_edit_file}] } {
						sh cp -rf $tim_corner_data $tim_corner_data_edit_file
					}
		
					set sed_cmd_head "exec sed -i \"${line_number}s/^/# /g\" $tim_corner_data_edit_file"
					set sed_cmd_tail "exec sed -i \"${line_number}s/$/ ;# The command is an error in smsa_shell./g\" $tim_corner_data_edit_file"
					eval $sed_cmd_head; eval $sed_cmd_tail
		
					exec echo ""		                                                            >> $tim_corner_data_edit_file
					exec echo "#########################################################"           >> $tim_corner_data_edit_file
					exec echo "# The ${line_number}-line command is replaced by the command below." >> $tim_corner_data_edit_file
					exec echo "#########################################################"           >> $tim_corner_data_edit_file
					exec echo "$new_cmd_1"                                                          >> $tim_corner_data_edit_file
					exec echo "$new_cmd_2"                                                          >> $tim_corner_data_edit_file
					exec echo ""		                                                            >> $tim_corner_data_edit_file
		
					set smsa_shell_run_file		 "${asp_run_scr}"
					set smsa_shell_edit_run_file "${asp_run_scr}_edit"
					if { ![file exist $smsa_shell_edit_run_file] } {
						sh cp -rf ${smsa_shell_run_file} ${smsa_shell_edit_run_file}
					}
					set sed_cmd "exec sed -i \"s#${tim_corner_data}#${tim_corner_data_edit_file}#g\" ${smsa_shell_edit_run_file}"
					eval $sed_cmd
		
					puts "Information_ADF: Edited the smsa_shell startup script. (${smsa_shell_edit_run_file})"
					puts ""
				}
			} else {
				puts "Information_ADF: No patterns need modification. ($tim_corner_data)"
				puts "                 Pattern :"
				puts "                     $Pattern"
				puts ""
			}
		}
		if { [info exist smsa_shell_edit_run_file] } {
			if { [file exist $smsa_shell_edit_run_file] } {
				set edited_start_eco_cmd "start_eco $args -custom_script $smsa_shell_edit_run_file"
			}
		} else {
			set smsa_shell_run_file		 "${asp_run_scr}"			
			set edited_start_eco_cmd "start_eco $args -custom_script $smsa_shell_run_file"
		}
		puts "Information_ADF: New execution command"
		puts "                   =>  $edited_start_eco_cmd"
		puts ""
		uplevel #0 "eval $edited_start_eco_cmd"
	} else {
		set not_edited_start_eco_cmd "start_eco $args"
		echo $not_edited_start_eco_cmd
		uplevel #0 "eval $not_edited_start_eco_cmd"
	}
}
