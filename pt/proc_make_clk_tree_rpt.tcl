################################################################################
# File Name     : proc_make_clk_tree_rpt.tcl
# Author        : DT-PI
# Creation Date : 2024-08-06
# Last Modified : 2024-08-06
# Version       : v0.1
# Location      : ${COMMON_TCL_PT}/make_clk_tree_rpt.tcl
#-------------------------------------------------------------------------------
# Description   :
#	Make clock tree report
#	Frequency and period can be checked.
#   The scaled frequency and period can be checked by referring to the violations in the clock group.
#-------------------------------------------------------------------------------
# Change Log    :
#   v0.1 [2023-08-06] : jjh8744
#   	- initial released
#   v0.2 [2025-02-06] : jjh8744
#		- Changed Target Freq/Period calculation to only calculate based on capture clock.
#       - In the case of multicycle paths, the violation is scaled to calculate the Target Freq/Period.
#
#-------------------------------------------------------------------------------
# Useage        :
# 	pt_shell > source proc_make_clk_tree_rpt.tcl
# 	pt_shell > make_clk_tree_rpt ...
#################################################################################


proc make_clk_tree_rpt {args} {
 	suppress_message UITE-416

 	global PBA_MODE RPT_DIR

 	set CSV2TABLE   "/prj/sophia/repo/BIN/tcllib/csv2table.tclsh"
	set temp_header "./.clk_tree_tmp_header"
	set temp_csv    "./.clk_tree_tmp_csv"
	set temp_output "./.clk_tree_tmp_rpt"

	parse_proc_arguments -args $args results
	foreach argname [array names results] {
		switch -glob -- $argname {
			"-output" {
				set output           $results($argname)
			}
			"-pba_mode" {
				set pba_mode         $results($argname)
			}
			"-include_boundary" {
				set include_boundary $results($argname)
			}
		}
	}

	set default_output           "${RPT_DIR}/clk_tree.rpt"
	set default_pba_mode         "${PBA_MODE}"
	set default_include_boundary "false"

	if { [info exists results(-output)]} {
		set	output $output
	} else {
		set output $default_output
	}

	if { [info exists results(-pba_mode)]} {
		set	pba_mode $pba_mode
	} else {
		set pba_mode $default_pba_mode
	}

	if { [info exists results(-include_boundary)]} {
		set	include_boundary $include_boundary
	} else {
		set include_boundary $default_include_boundary
	}

	if { [string match "false" $include_boundary] } {
		set ALL_START      [get_pins -of [get_cells -hierarchical -filter "is_sequential==true"] -filter "is_clock_pin==true" ]
		set ALL_END        [get_pins -of [get_cells -hierarchical -filter "is_sequential==true"] -filter "is_clock_pin==false"]
		set START_CMD " -from \${ALL_START}"
	 	set END_CMD   " -to \${ALL_END}"
	} else {
		set START_CMD ""
 		set END_CMD   "" 
	}
 	#set PBA_CMD   " -pba_mode ${PBA_MODE}"
 	set PBA_CMD   ""
 	set ALL_MASTER_CLK [get_object_name [get_clocks -filter "defined(sources) && is_generated == false"]]

 	echo " Clock ,    Freq / Period , Target Freq / Period ,           WNS" > $temp_csv
 	
 	foreach MASTER_CLK $ALL_MASTER_CLK {
 	
 		set ALL_GEN_CLK_LIST $MASTER_CLK
 		set GEN_CLK_LIST 	 $MASTER_CLK
 		set CLK(0)			 $MASTER_CLK
 	
 		# Make generated_clock lists
 		set flag "0"
 		set before_cnt "0"
 		set gen_depth "1"
 		while { $flag == "0" } {
 			set before_cnt	      [llength $ALL_GEN_CLK_LIST]
 			set GEN_CLK_LIST	  [get_attr -quiet [get_clocks $GEN_CLK_LIST] generated_clocks]
 			if { [sizeof_collection $GEN_CLK_LIST] > 0 } {
 				set CLK($gen_depth)   [get_object_name $GEN_CLK_LIST]
 				set COMBINE_LIST      "$ALL_GEN_CLK_LIST [set CLK($gen_depth)]"
 				set ALL_GEN_CLK_LIST  [lsort -unique $COMBINE_LIST]
 			}
 			set after_cnt         [llength $ALL_GEN_CLK_LIST]
 			if { $before_cnt == $after_cnt } { set flag "1" }
 			incr gen_depth
 		}
 	
 		# Sort master clock and generated clock
 		set SORT_CLK_LIST ""
 		for {set x 0} {$x < 9999} {incr x} {
 			if { [info exist CLK($x)] } {
 				if { $x == "0" } {
 					set SORT_CLK_LIST "[set CLK($x)]"
 				} else {
 					foreach gen_list [set CLK($x)] {
 						set M_CLK [get_attr [get_clocks $gen_list] master_clock.full_name]
 						if { $x > 1 } {
 							set idx [lsearch $SORT_CLK_LIST [expr $x-1]---$M_CLK]
 						} else {
 							set idx [lsearch $SORT_CLK_LIST $M_CLK]
 						}
 						set SORT_CLK_LIST [linsert $SORT_CLK_LIST [expr $idx + 1] "${x}---$gen_list"]
 					}
 				}
 			} else {
 				break
 			}
 		}
 	
 		# Print clock information
 		foreach print_value $SORT_CLK_LIST {
 			if { [regexp {^\d+---} $print_value] } {
 				set tab_cnt     [lindex [split $print_value "---"] 0  ]
 				set print_list  [lindex [split $print_value "---"] end]
 				set TAB         [string repeat "    " $tab_cnt]
 	
 				set period               [format %.3f [get_attr [get_clocks $print_list] period]]
 				set freq                 [format %.0f [expr 1000.0/$period]		  			    ]

 				set to_slack_path_cmd    "get_timing_paths -to   \[get_clocks $print_list\] $START_CMD $PBA_CMD"
 				set to_slack_path        [eval $to_slack_path_cmd]
 				set to_slack             [get_attr $to_slack_path slack]
 				set slack_list           "$to_slack"

 				set scal [lindex [lsort -decreasing $slack_list] end]

 				if { [string match "" $scal] || [regexp {[a-zA-Z]} $scal] } {
 					echo " ${TAB}${print_list} , [format %8d $freq] / [format %-8.3f $period] ,    No timing check" >> $temp_csv
 				} else {
					set scal_org [format %.3f $scal]

					set MULTICYCLE_CNT [get_attr $to_slack_path exception_shift]
					if { $MULTICYCLE_CNT == "UNINIT" } {
						set MULTICYCLE_CNT "1"
						set MULTICYCLE_TAG ""
					} else {
					    set scal           [expr $scal_org / $MULTICYCLE_CNT]
						set MULTICYCLE_TAG "([format %.3f $scal] * [format %.0f $MULTICYCLE_CNT])"
					}

	 				set target_period [format %.3f [expr $period - $scal]         ]
	 				set target_freq   [format %.0f [expr 1000.0/($period - $scal)]]

					set WNS_INFO "$scal_org $MULTICYCLE_TAG"

 					echo " ${TAB}${print_list} , [format %8d $freq] / [format %-8.3f $period] , [format %11d $target_freq] / [format %-7.3f $target_period] , [format %-24s $WNS_INFO] " >> $temp_csv
 				}

 			} else {
 				set period      [format %.3f [get_attr [get_clocks $print_value] period]]
 				set freq        [format %.0f [expr 1000.0/$period]					    ]

 				set to_slack_path_cmd    "get_timing_paths -to   \[get_clocks $print_value\] $START_CMD $PBA_CMD"
 				set to_slack_path        [eval $to_slack_path_cmd  ]
 				set to_slack             [get_attr $to_slack_path slack]
 				set slack_list           "$to_slack"
 	
 				set scal [lindex [lsort -decreasing $slack_list] end]

 				if { [string match "" $scal] || [regexp {[a-zA-Z]} $scal] } {
 					echo " $print_value , [format %8d $freq] / [format %-8.3f $period] ,    No timing check" >> $temp_csv
 				} else {
					set scal_org [format %.3f $scal]

					set MULTICYCLE_CNT [get_attr $to_slack_path exception_shift]
					if { $MULTICYCLE_CNT == "UNINIT" } {
						set MULTICYCLE_CNT "1"
						set MULTICYCLE_TAG ""
					} else {
					    set scal            [expr $scal_org / $MULTICYCLE_CNT]
						set MULTICYCLE_TAG "([format %.3f $scal] * [format %.0f $MULTICYCLE_CNT])"
					}

 					set target_period [format %.3f [expr $period - $scal]         ]
 					set target_freq   [format %.0f [expr 1000.0/($period - $scal)]]

					set WNS_INFO "$scal_org $MULTICYCLE_TAG"

 					echo " $print_value , [format %8d $freq] / [format %-8.3f $period] , [format %11d $target_freq] / [format %-7.3f $target_period] , [format %-24s $WNS_INFO] " >> $temp_csv
 				}
 			}
 		}
 		unset CLK
 	}
 	unsuppress_message UITE-416

	echo "###########################################################################################################################################"                                       > $temp_header
	echo "# Used options"																															                                        >> $temp_header
	echo "# Report location  : ${output}"																											                                        >> $temp_header
	echo "# PBA_MODE         : ${pba_mode}"																											                                        >> $temp_header
	echo "# include boundary : ${include_boundary}"																									                                        >> $temp_header
	echo "#     include boundary option => true           : When calculating the target frequency/period, both R2R and boundary timing are considered."                                     >> $temp_header
	echo "#                                false(default) :  When calculating the target frequency/period, only R2R is considered."                                                         >> $temp_header
	echo "#"							                                                                                                                                                    >> $temp_header
	echo "# - If WNS is the value of a multicycle path,the value in the WNS row will be displayed in the following format.(Target freq/period is calculated based on the Scaled violation)" >> $temp_header
	echo "#	    Format:"                                                                                                                                                                    >> $temp_header
	echo "#       Real violation (Scaled violation * Path multiplier)"                                                                                                                      >> $temp_header
	echo "#"                                                                                                                                                                                >> $temp_header
	echo "# -. Unit"                                                                                                                                                                        >> $temp_header
	echo "# Freq   : MHz"                                                                                                                                                                   >> $temp_header
	echo "# Period : ns"                                                                                                                                                                    >> $temp_header
	echo "# WNS    : ns"                                                                                                                                                                    >> $temp_header
	echo "############################################################################################################################################"                                     >> $temp_header
	echo ""																																				                                    >> $temp_header
	echo ""																																				                                    >> $temp_header

	exec tclsh $CSV2TABLE $temp_csv 1 > $temp_output
	
	exec cat $temp_header $temp_output > $output
	sh rm -rf $temp_csv $temp_header $temp_output
}

define_proc_attributes make_clk_tree_rpt \
-info "Make clock tree report.\n Frequency and period can be checked.\n The scaled frequency and period can be checked by referring to the violations in the clock group." \
-define_args {
    {-output             "output filename (default = \${RPT_DIR}/clk_tree.rpt)"                                                      "< filename >"   string    optional }
    {-pba_mode           "path-based timing analysis modes (default = \${PBA_MODE})"                 "< none | path | exhaustive | ml_exhaustive >"   string    optional }
    {-include_boundary   "Set to true to include boundary timing when calculating the scaled frequency/period (default = false)" "< true | false >"   string    optional }
}
