###################################################################################################
# File               : dcd.tcl  (Modification of dcd.tcl)                                         #
# Author             : ADT-DT (jmpark)                                                            #
# Description        : DCD (duty) check                                                           #
# Usage              :                                                                            #
# Init Release Date  : 2024.02.19                                                                 #
# Last Update  Date  : 2024.03.04                                                                 #
# Script Version     : 2.0                                                                        #
# Revision History   :                                                                            #
#         2024.02.19 - first released  (/prj/sophia/interface/to_pi/dcd.tcl)                      #
#         2024.03.04 - Check the duty cycle not only on IP pins but also on specific pins.        #
#					   Changed it to check based on Pin, not path group.						  #
#					   (In previous versions, only one Pin could be checked in one path group.)   #
#					   Added Duty_cycle column to summary report.                                 #
###################################################################################################
set dcd_script_version "V2.00"
set exclude_pad_delay "0"

set CSV2TABLE "/prj/Artemis/repo/BIN/csv2table.tclsh"

proc pt_dcd {args} {

	global dcd_script_version exclude_pad_delay CSV2TABLE
    puts "ADT_INFO: DCD Scrpts Ver - $dcd_script_version"
    puts "##############################"
    puts "# source dcd.tcl file        #"
    puts "# pt_dcd -info path.list     #"
    puts "##############################"
    puts "##################################################################################"
    puts "# path list file                                                                 #"
    puts "# <Group name> <To END PIN> <SDC CLock name at end pin> <Duty min> <Duty max>    #"
    puts "# DDR0 TOP/DDR/clk APLL_CLK 40 60                                                #"
    puts "##################################################################################"
	global synopsys_program_name
	set unset_list "final_clock Group duty_spec define_name c_name period final_pin"

	foreach value $unset_list {array unset $value}
		parse_proc_arguments -args $args results
			foreach argname [array names results] {
				switch -glob -- $argname {
				"-s*" {
					set s_duty_rpt $results($argname)
				}
				"-i*" {
					set path_rpt $results($argname)
				}
				"-p*" {
					set exclude_pad_delay $results($argname)
				}
				}
			}

	if {[file exist $path_rpt]} {
		puts "ADT INFO : read $path_rpt"
		if {[info exist s_duty_rpt]} {
			puts "ADT INFO : read source duty spec file : $s_duty_rpt"
			set file [open "$s_duty_rpt" r]
			while {[gets $file line] >= 0} {
				if {(![regexp "#" $line ]) && ([string length $line] !=0)} {
					set ref_name [lindex $line 0]
					set dcd_value [lindex $line 1]
					set s_duty($ref_name) $dcd_value
				}
			}
			close $file
		} else {
			puts "ADT INFO : no source dcd spec file"
		}

		if { $exclude_pad_delay != "1" } {
			puts "ADT INFO : If there is a pad in the path to check dcd, pad delay is \"included\" in the dcd calculation."
		} else {
			puts "ADT INFO : If there is a pad in the path to check dcd, pad delay is \"excluded\" in the dcd calculation."
		}

		set date [join [lrange [date] 1 2] _]
		set output_dir "./DCD_[get_object_name [current_design]]_${date}"
		if {[file isdirectory $output_dir]} {
			sh rm -rf $output_dir
		}
		file mkdir $output_dir
		set dir_name "${output_dir}/DCD_trace $output_dir/DCD_trace/DCD_details"
		foreach name $dir_name {
			file delete -force $name
			file mkdir $name
		}
		set all_groups ""
		set file [open "$path_rpt" r]
		puts "ADT INFO : Parsing path info begin"
		
		while { [gets $file line] >= 0} {
			if { ![regexp ^\s*#|^\s*$ $line]} {
				if {[llength $line] != "5"} {
					puts "ADT Error : not enough path info in $line"
				} else {
					set Group [lindex $line 0]
					puts "ADT INFO : Reading path info : $Group"
					if { [info exist final_end_pin($Group)] } {
						set final_end_pin($Group) [lappend final_end_pin($Group) [lindex $line 1]]
					} else {
						set final_end_pin($Group) [lindex $line 1]
					}
					set final_clock($Group) [lindex $line 2]
					set duty_spec([lindex $line 1]) [expr abs([lindex $line 3] - [lindex $line 4])/2]
					if {[sizeof_collection [get_pins $final_end_pin($Group) -quiet]] ==0} {
						puts "ADT ERROR : PIN - $final_end_pin($Group) dosen't exist in DESIGN"
					} elseif {[sizeof_collection [get_clocks $final_clock($Group) -quiet]] ==0 } {
						puts "ADT ERROR : CLOCK - $final_clock($Group) dosen't exist in DESIGN"
					} else {
						lappend all_groups $Group
					}
				}
			}
		}
		close $file
		puts "ADT INFO : Parsing path info completed"

		set output_rpt "${output_dir}/csv_DCD_summary.rpt"
		set final_output_rpt "${output_dir}/DCD_summary.rpt"
		redirect -file $output_rpt {puts [format " %s , %s , %s , %s , %s , %s , %s , %s , %s , %s , %s , %s" Group Clock_name END_PIN SPEC SOURCE SOURCE% DCD DCD% Total Slack Duty_cycle Pass/Fail]}
		#redirect -file $output_rpt -append {puts [format "%20s" ##########################################################################################################################################################################################################]}
		puts "*****************************"

		set all_groups_uniq ""
		foreach element $all_groups {
			if {[lsearch -exact $all_groups_uniq $element]<0} {
				lappend all_groups_uniq $element
			}
		}

		foreach group_name $all_groups_uniq {
			puts "ADT INFO : summarize $group_name"
			set clock_name $final_clock($group_name)
#			puts "$final_clock($group_name)"
			set to_pins [set final_end_pin($group_name)]

			foreach to_pin $to_pins {
				set dividing_count 0
				if {[llength [get_attr [get_clocks $clock_name] sources -quiet]] > 0} {
					set temp_related_clocks ""
					set related_clock($clock_name) ""
					set flag 1
					set cur_clk [get_clock $clock_name]
					while {$flag} {
						lappend related_clock($clock_name) [get_object_name $cur_clk]
						set from_clock [get_object_name $cur_clk]
						set cur_clk [get_attribute -quiet [get_clocks $cur_clk] master_clock]
						set from_pin [get_object_name [get_attribute [get_clock $from_clock] sources]]
						if { $cur_clk == ""} {
							set flag 0;
						}
						incr dividing_count
					}
				}
				set last_period [get_attr [get_clock $clock_name] period]
				set max_dcd_ratio [sec_get_dcd_value $from_pin $to_pin $clock_name $dividing_count]
				if {$max_dcd_ratio == "NULL"} {
					set max_dcd_value "NULL"
				} else {
					set max_dcd_value [expr $last_period * $max_dcd_ratio/100]
				}
				set source_clock [lindex $related_clock($clock_name) end]
				set value_flag 0
				set p_clock [get_attribute [get_clock $source_clock] period]
				if {[sizeof_collection [get_pins [get_attribute [get_clocks $source_clock] sources] -quiet]] ==0} {
					puts "ADT WARRING : source clock; $source_clock should be defined in pin not as port"
					set temp_source_ref [get_cells -quiet -of_objects [get_pins -quiet -of_objects [get_nets -quiet -of_objects [get_ports -quiet [get_attribute [get_clocks $source_clock] sources]]] -leaf -filter "direction=~*out*"]]
					if { $temp_source_ref != ""} {
						set source_ref [get_attr [get_cells $temp_source_ref] ref_name ]
					} else {
						set source_ref "NULL"
					}
				} else {
					set temp_source_ref [get_cells -quiet -of_objects [get_pins -quiet [get_attribute [get_clocks $source_clock ] sources]]]
					if { $temp_source_ref != ""} {
						set source_ref [get_attr [get_cells $temp_source_ref] ref_name]
					} else {
						set source_ref "NULL"
					}
				}				

				if {[lsearch -exact [array names s_duty] $source_ref] >=0} {
					if {![regexp % $s_duty($source_ref)]} {
						set source_duty_value $s_duty($source_ref)
						set source_duty_ratio [expr $source_duty_value/1000.000 / $last_period * 100]
					} else {
						set source_duty_ratio [lindex [split $s_duty($source_ref) %] 0]
						set source_duty_value [expr $p_clock * $source_duty_ratio /100]
					}
				} else {
					set source_duty_value 0
					set source_duty_ratio 0
				}

				set ref_name [get_attribute [get_cells -of_objects [get_pins $final_end_pin($group_name) ]] ref_name]
				set spec "[expr 50 - $duty_spec($to_pin)]:[expr 50 + $duty_spec($to_pin)]"
				if {$max_dcd_value != "NULL"} {
					set total_dcd [expr $max_dcd_ratio + $source_duty_ratio]
					set slack [expr $duty_spec($to_pin) - $total_dcd]
					set source_duty_ratio "[format "%2.2f" ${source_duty_ratio}]%"
					set duty_cycle "[expr 50 - $total_dcd]"
					if { $slack > 0} {
						set pass_fail "PASS"
					} else {
						set pass_fail "FAIL"
					}
						set max_dcd_ratio	"[format "%2.2f" ${max_dcd_ratio}]%"
						set total_dcd		"[format "%2.2f" ${total_dcd}]%"
						set slack			"[format "%2.2f" ${slack}]%"
						set duty_cycle		"[format "%2.2f" ${duty_cycle}]%"
						#redirect -file $output_rpt -append {puts [format "%10s %50s %40s %10s %10s %10s %5.2f %10s %10s %10s %11s %11s" $group_name $final_clock($group_name) $to_pin $spec $source_duty_value $source_duty_ratio $max_dcd_value $max_dcd_ratio $total_dcd $slack $duty_cycle $pass_fail]}
						redirect -file $output_rpt -append {puts [format " %s , %s , %s , %s , %s , %s , %.2f , %s , %s , %s , %s , %s" $group_name $final_clock($group_name) $to_pin $spec $source_duty_value $source_duty_ratio $max_dcd_value $max_dcd_ratio $total_dcd $slack $duty_cycle $pass_fail]}

				} else {
						set total_dcd "NULL"
						set slack "NULL"
						set pass_fail "NULL"
						set duty_cycle		"NULL"
						set source_duty_ratio "[format "%2.2f" ${source_duty_ratio}]%"
						#redirect -file $output_rpt -append {puts [format "%10s %50s %40s %10s %10s %10s %4s %10s %10s %10s %11s %11s" $group_name $final_clock($group_name) $to_pin $spec $source_duty_value $source_duty_ratio $max_dcd_value $max_dcd_ratio $total_dcd $slack $duty_cycle $pass_fail]}
						redirect -file $output_rpt -append {puts [format " %s , %s , %s , %s , %s , %s , %s , %s , %s , %s , %s , %s" $group_name $final_clock($group_name) $to_pin $spec $source_duty_value $source_duty_ratio $max_dcd_value $max_dcd_ratio $total_dcd $slack $duty_cycle $pass_fail]}
				}
			}
		}
		exec tclsh $CSV2TABLE $output_rpt 1 > $final_output_rpt
		file delete -force $output_rpt

	} else {
		puts "ADT ERROR : $path_rpt dosen't exist"
	}
}


###PROC

proc sec_get_dcd_value {from_pin to_pin clock_name dividing_count} {

	global exclude_pad_delay

	upvar output_dir output_dir_new
	upvar group_name Group_name
	upvar related_clock($clock_name) related_clocks
	set clock_source_pin [get_object_name [get_attr [get_clocks $clock_name] sources]]

	foreach {rise_fall delay_type} {rise max rise min fall max fall min} {
		set temp_output "${output_dir_new}/DCD_trace/DCD_details/${Group_name}_${rise_fall}_${delay_type}.rpt"
		if {[sizeof_collection [get_pins -quiet $to_pin]] == 0} {
			puts "ADT ERROR : no pin $to_pin in DESIGN"
		} else {
			if { $dividing_count == 1} {
				report_timing -from [get_clocks $clock_name] -from $clock_source_pin -${rise_fall}_to $to_pin -delay_type ${delay_type} -sig 4 -nos -path_type full_clock_exp > $temp_output
			} elseif {$dividing_count > 1} {
				report_timing -from [get_clocks $clock_name] -th   $clock_source_pin -${rise_fall}_to $to_pin -delay_type ${delay_type} -sig 4 -nos -path_type full_clock_exp > $temp_output
			}

			set search_flag "0"
			set pad_flag	"0"
			set pad_delay	"0.000"
			set file [open "$temp_output" r]
			while { [gets $file line] >= 0} {

				if { [regexp "/Y" $line] } {
					set pad_attr [get_attr [get_attr [get_pins -quiet $line] cell] is_pad_cell]
					if { $pad_attr == "true" } {
						set pad_flag "1"
					} else {
						set pad_flag "0"
					}
				}
				if {[regexp $from_pin $line]} {
					set search_flag 1
				}

				if { $pad_flag == "1" } {
					set pad_delay [lindex $line [expr [llength $line] -2]]
				}
				if {[lindex $line 0] == $to_pin} {
					if { $exclude_pad_delay != "1" } {
						set ${rise_fall}_${delay_type} [expr [lindex $line [expr [llength $line] -2]] - 0.000]
					} else {
						set ${rise_fall}_${delay_type} [expr [lindex $line [expr [llength $line] -2]] - $pad_delay]
					}
				}
			}
			close $file

			if {$search_flag == "0"} {
				puts "ADT ERROR : check the library on clock path or clock definition."
				set ${rise_fall}_${delay_type} 0
			}
		}
	}
	set dcd_max [expr abs($rise_max - $fall_max)]
	set dcd_min [expr abs($rise_min - $fall_min)]

	if { $dcd_max > $dcd_min} {
		set worst_dcd $dcd_max
		set rise_rpt ${output_dir_new}/DCD_trace/DCD_details/${Group_name}_rise_max.rpt
		set fall_rpt ${output_dir_new}/DCD_trace/DCD_details/${Group_name}_fall_max.rpt
	} else {
		set worst_dcd $dcd_min
		set rise_rpt ${output_dir_new}/DCD_trace/DCD_details/${Group_name}_rise_min.rpt
		set fall_rpt ${output_dir_new}/DCD_trace/DCD_details/${Group_name}_fall_min.rpt
	}

	sec_make_dcd_trace $rise_rpt $fall_rpt $clock_name $to_pin

	set pin_period [get_attr [get_clock $clock_name] period]
	if {$worst_dcd > 0} {
		set dcd_ratio [format "%2.2f" [expr $worst_dcd / $pin_period * 100]]
		return $dcd_ratio
	} else {
		return "NULL"
	}
}

proc sec_make_dcd_trace {rise_rpt fall_rpt clock_name to_pin} {

	upvar output_dir_new output_dir_new2
	upvar Group_name Group_name2
	upvar related_clocks related_clocks2
	set output_rpt "${output_dir_new2}/DCD_trace/${Group_name2}.rpt"
	set file [open "$rise_rpt" r]
	while { [gets $file line] >= 0} {
		set rise_fall [lindex $line end]
		if { $rise_fall == "r" || $rise_fall == "f"} {
			set cell_name [lindex $line 0]
			set index_num [expr [llength $line] -2]
			set path($cell_name) [lindex $line $index_num]
		}
	}
	close $file

	redirect -file $output_rpt {puts [format "%10s %10s %10s %10s %10s" Clock_name Period Cell_ref DCD DCD_ratio]}
	redirect -append -file $output_rpt {puts [format "%30s" Cell_name]}

	redirect -append -file $output_rpt {puts "----------------------------------------------------------------------------------------------------------------"}

	set file [open "$fall_rpt" r]
	while {[gets $file line] >= 0} {
		set rise_fall [lindex $line end]
		if { $rise_fall == "r" || $rise_fall == "f"} {
			set cell_name [lindex $line 0]
			if {[sizeof_collection [get_pins $cell_name -quiet ]] ==0} {
				puts "ADT WARRING : clock; $cell_name should be defined in pin not as port"
				set c_name [get_object_name [get_attr [get_ports $cell_name] launch_clocks]]
			} else {
				set c_name [get_object_name [get_attr [get_pins $cell_name] launch_clocks]]
			}

			foreach c $c_name  {
				foreach r $related_clocks2 {
					if {$r == $c} {
						set pin_clock_name $c
						set pin_period [get_attr [get_clock $pin_clock_name] period]
					}
				}
			}

			set index_num [expr [llength $line ] -2]

			if {[info exist path($cell_name)]} {
				set dcd "[expr abs([lindex $line $index_num] - $path($cell_name))]"
				set dcd_ratio "[format "%2.2f" [expr $dcd / $pin_period * 100]]"
			} else {
				set dcd "diff"
				set dcd_ratio "diff"
			}

			redirect -file ${output_rpt} -append {puts [lindex $line 0]}
			redirect -file ${output_rpt} -append {puts [format "%10s %2.3f %20s %10s %10s" $pin_clock_name $pin_period [lindex $line 1] $dcd $dcd_ratio]}
			redirect -file ${output_rpt} -append {puts ""}

			if {[regexp $to_pin $line]} {
				break;
			}
		}
	}
	close $file
}

define_proc_attributes pt_dcd \
-info "SET DCD Inputfile" \
-define_args {{-source "source DCD spec" filename string optional} \
	 		  {-info "path info" filename string required} \
			  {-pad_delay "set to 1 to exclude pad delay. <default = 0>" "" int optional}}
