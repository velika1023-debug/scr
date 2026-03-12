################################################################################
# File Name     : check_con.tcl
# Author        : DT-PI
# Last Modified : 2024-02-18
# Version       : v0.1
# Location      : ${COMMON_TCL}/dc_syn,fc
#-------------------------------------------------------------------------------
# Description   :
#   Checking dont_touch, dont_use, and size_only cells.
#
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2025-02-20] : jjh8744
#       - Initial Version Release
# 	v0.2 [2025-02-26] : jjh8744
#       - Modify the command for finding user-defined size-only cells
# 	v0.3 [2025-07-25] : jjh8744
#       - Updated to be compatible with FC
# 	v0.4 [2025-07-30] : jjh8744
#       - changed DESIGN_STAGE variable setting 
#-------------------------------------------------------------------------------
# Useage        :
#		dc_shell >> source check_con.tcl
#		fc_shell >> source check_con.tcl
#################################################################################

if { $synopsys_program_name == "fc_shell" } {
	set TOP_DESIGN ${vars(design)}
	set ORG_REPORT_DIR $REPORT_DIR
	set REPORT_DIR ${REPORT_DIR}/compile
	if {![info exist DESIGN_STAGE]} {
		set DESIGN_STAGE before_compile
	} else {
		set DESIGN_STAGE final 
	}
} else {
	if {![info exist DESIGN_STAGE]} {
		set DESIGN_STAGE before_compile
	}
}

if [file exists "${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_dont_touch.rpt"] {
	sh rm -rf ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_dont_touch.rpt
}

if [file exists "${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_dont_use.rpt"] {
	sh rm -rf ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_dont_use.rpt
}

if [file exists "${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_size_only.rpt"] {
	sh rm -rf ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_size_only.rpt
}

if { ![info exist USER_DONT_TOUCH_CELL_NO_CHECK_NAMING_RULE] } {
	set USER_DONT_TOUCH_CELL_NO_CHECK_NAMING_RULE ""
}

if { ![info exist USER_DONT_TOUCH_NET_NO_CHECK_NAMING_RULE] } {
	set USER_DONT_TOUCH_NET_NO_CHECK_NAMING_RULE  ""
}

set USER_DONT_TOUCH_CELL_NO_CHECK_NAMING_RULE "u_hns_wrap/u_hns_l3sf/u_hns_sf_non_0k_u_hns_sf_tag/u_hns_sf_tagarrays/g_sf_tag_way_16__u_hns_sf_tag_way/u_cmn_hns_sf_tag_sram/* u_hns_wrap/u_hns_l3sf/u_hns_sf_non_0k_u_hns_sf_tag/u_hns_sf_tagarrays/g_sf_tag_way_23__u_hns_sf_tag_way/u_cmn_hns_sf_tag_sram/*"

if { $USER_DONT_TOUCH_CELL_NO_CHECK_NAMING_RULE != ""  } {
	set USER_DONT_TOUCH_CELL_NO_CHECK ""
	foreach naming_rule $USER_DONT_TOUCH_CELL_NO_CHECK_NAMING_RULE {
		lappend USER_DONT_TOUCH_CELL_NO_CHECK [get_cells -quiet -hierarchical -filter "full_name =~ ${naming_rule}"]
	}
	set USER_DONT_TOUCH_CELL_NO_CHECK [lsort -unique [get_object_name $USER_DONT_TOUCH_CELL_NO_CHECK]]
} else {
	set USER_DONT_TOUCH_CELL_NO_CHECK ""
}

if { $USER_DONT_TOUCH_NET_NO_CHECK_NAMING_RULE != ""  } {
	set USER_DONT_TOUCH_NET_NO_CHECK ""
	foreach naming_rule $USER_DONT_TOUCH_NET_NO_CHECK_NAMING_RULE {
		lappend USER_DONT_TOUCH_NET_NO_CHECK [get_nets -quiet -hierarchical -filter "full_name =~ ${naming_rule}"]
	}
	set USER_DONT_TOUCH_NET_NO_CHECK [lsort -unique [get_object_name $USER_DONT_TOUCH_NET_NO_CHECK]]

} else {
	set USER_DONT_TOUCH_NET_NO_CHECK ""
}


# Find dont_touch cell
if { $synopsys_program_name == "fc_shell" } {
	set USER_DONT_TOUCH_CELL_LIST     [get_cells -quiet -hierarchical -filter "is_hierarchical == false && user_dont_touch == true"]
} else {
	set USER_DONT_TOUCH_CELL_LIST     [remove_from_collection [get_dont_touch_cells -type user -hierarchical *] [get_dont_touch_cells -type cg_mo -hierarchical *]]
}
set USER_DONT_TOUCH_CELL_LIST_cnt [sizeof_collection $USER_DONT_TOUCH_CELL_LIST]

# Find dont_touch net
if { $synopsys_program_name == "fc_shell" } {
	set USER_DONT_TOUCH_NET_LIST     [get_nets -quiet -hierarchical -filter "user_dont_touch == true"]
} else { 
	set USER_DONT_TOUCH_NET_LIST     [get_dont_touch_nets -type user -hierarchical *]
}
set USER_DONT_TOUCH_NET_LIST_cnt [sizeof_collection $USER_DONT_TOUCH_NET_LIST]


# Diff dont_touch cell, net
set ${DESIGN_STAGE}_USER_DONT_TOUCH_CELL_LIST $USER_DONT_TOUCH_CELL_LIST
set ${DESIGN_STAGE}_USER_DONT_TOUCH_NET_LIST  $USER_DONT_TOUCH_NET_LIST

if { $DESIGN_STAGE == "before_compile" } {
	set DIFF_RESULT "No check"
	set DIFF_CELL_LIST ""
	set	DIFF_NET_LIST  ""
	set BEFORE_DESIGN_STAGE ${DESIGN_STAGE}

	set DIFF_RESULT_CELL_PRINT_TAG ""
	set DIFF_RESULT_NET_PRINT_TAG ""

} else {
	set DIFF_LIST_temp                         [remove_from_collection [set ${BEFORE_DESIGN_STAGE}_USER_DONT_TOUCH_CELL_LIST] [set ${DESIGN_STAGE}_USER_DONT_TOUCH_CELL_LIST]       ]
	set DIFF_CELL_LIST      [add_to_collection [remove_from_collection [set ${DESIGN_STAGE}_USER_DONT_TOUCH_CELL_LIST]        [set ${BEFORE_DESIGN_STAGE}_USER_DONT_TOUCH_CELL_LIST]] $DIFF_LIST_temp]
	set DIFF_CELL_LIST                         [remove_from_collection $DIFF_CELL_LIST [get_cells $USER_DONT_TOUCH_CELL_NO_CHECK]]
	if {[sizeof_collection $DIFF_CELL_LIST] > 0} {
		set DIFF_CELL_RESULT "Fail"
	} else {
		set DIFF_CELL_RESULT "Pass"
	}
	lappend DIFF_RESULT_CELL_PRINT_TAG "#          $BEFORE_DESIGN_STAGE vs $DESIGN_STAGE : $DIFF_CELL_RESULT"

	set DIFF_LIST_temp                        [remove_from_collection [set ${BEFORE_DESIGN_STAGE}_USER_DONT_TOUCH_NET_LIST]  [set ${DESIGN_STAGE}_USER_DONT_TOUCH_NET_LIST]        ]
	set DIFF_NET_LIST      [add_to_collection [remove_from_collection [set ${DESIGN_STAGE}_USER_DONT_TOUCH_NET_LIST]         [set ${BEFORE_DESIGN_STAGE}_USER_DONT_TOUCH_NET_LIST] ] $DIFF_LIST_temp]
	set DIFF_NET_LIST                         [remove_from_collection $DIFF_NET_LIST [get_nets $USER_DONT_TOUCH_NET_NO_CHECK]]

	if {[sizeof_collection $DIFF_NET_LIST] > 0} {
		set DIFF_NET_RESULT "Fail"
	} else {
		set DIFF_NET_RESULT "Pass"
	}
	lappend DIFF_RESULT_NET_PRINT_TAG "#          $BEFORE_DESIGN_STAGE vs $DESIGN_STAGE : $DIFF_NET_RESULT"

	if { [string match "*Fail*" "$DIFF_RESULT_CELL_PRINT_TAG $DIFF_RESULT_NET_PRINT_TAG"] } {
		set DIFF_RESULT "Fail"
	} else {
		set DIFF_RESULT "Pass"
	}

	set BEFORE_DESIGN_STAGE ${DESIGN_STAGE}

	unset DIFF_LIST_temp
}

if { [info exist USER_DONT_TOUCH_CELL_NO_CHECK_NAMING_RULE] && $USER_DONT_TOUCH_CELL_NO_CHECK_NAMING_RULE != "" } {
	set NO_CHECK_CELL_NAMING_PRINT_TAG "#          Cell : $USER_DONT_TOUCH_CELL_NO_CHECK_NAMING_RULE"
} else {
	set NO_CHECK_CELL_NAMING_PRINT_TAG "#          Cell : No defined excluded naming rules"
}

if { [info exist USER_DONT_TOUCH_NET_NO_CHECK_NAMING_RULE] && $USER_DONT_TOUCH_NET_NO_CHECK_NAMING_RULE != "" } {
	set NO_CHECK_NET_NAMING_PRINT_TAG "#          Net  : $USER_DONT_TOUCH_NET_NO_CHECK_NAMING_RULE"
} else {
	set NO_CHECK_NET_NAMING_PRINT_TAG "#          Net  : No defined excluded naming rules"
}

# Print dont_touch cell , net , Diff result
echo "###################################################################################"                         > .header.rpt
echo "# User define dont_touch"                                                                                   >> .header.rpt
echo "# Cell count  : $USER_DONT_TOUCH_CELL_LIST_cnt"                                                             >> .header.rpt
echo "# Net count   : $USER_DONT_TOUCH_NET_LIST_cnt"                                                              >> .header.rpt
echo "# Diff Result : $DIFF_RESULT"                                                                               >> .header.rpt
echo "#"                                                                                                          >> .header.rpt
echo "#     -. Dont touch Cell"                                                                                   >> .header.rpt
foreach PRINT_TAG $DIFF_RESULT_CELL_PRINT_TAG {
	echo $PRINT_TAG                                                                                               >> .header.rpt
}
echo "#"                                                                                                          >> .header.rpt
echo "#     -. Dont touch Net"                                                                                    >> .header.rpt
foreach PRINT_TAG $DIFF_RESULT_NET_PRINT_TAG {
	echo $PRINT_TAG                                                                                               >> .header.rpt
}
echo "#"                                                                                                          >> .header.rpt
echo "#     -. No check naming rules"                                                                             >> .header.rpt
echo $NO_CHECK_CELL_NAMING_PRINT_TAG                                                                              >> .header.rpt
echo $NO_CHECK_NET_NAMING_PRINT_TAG                                                                               >> .header.rpt
echo "#"                                                                                                          >> .header.rpt
echo "#"                                                                                                          >> .header.rpt
echo "# Description:"                                                                                             >> .header.rpt
echo "#     This report checks the number of dont_touch cells and nets at each step "                             >> .header.rpt
echo "#     and determines the Pass/Fail status."                                                                 >> .header.rpt
echo "#"                                                                                                          >> .header.rpt
echo "#     Objects marked with 'X' in the Diff_check field are not checked for Pass/Fail "                       >> .header.rpt
echo "#     because they are classified under the No check naming rule."                                          >> .header.rpt
echo "#"                                                                                                          >> .header.rpt
echo "###################################################################################"                        >> .header.rpt
echo ""                                                                                                           >> .header.rpt
echo ""                                                                                                           >> .header.rpt

exec touch .No_check_temp
exec touch .Fail_temp
exec touch .temp

if { $USER_DONT_TOUCH_CELL_LIST_cnt > 0 } {

	exec touch .cell_No_check_temp
	exec touch .cell_Fail_temp
	exec touch .cell_temp

	foreach_in_collection itr $USER_DONT_TOUCH_CELL_LIST {
		if { [string match "* [get_object_name $itr] *" " $USER_DONT_TOUCH_CELL_NO_CHECK "] } {
			echo "cell    [get_object_name $itr] ([get_attr $itr ref_name])    No_Check"   >> .cell_No_check_temp
		} elseif { [string match "* [get_object_name $itr] *" " [get_object_name $DIFF_CELL_LIST] "]  } {
			echo "cell    [get_object_name $itr] ([get_attr $itr ref_name])    Fail" >> .cell_Fail_temp
		} else {
			echo "cell    [get_object_name $itr] ([get_attr $itr ref_name])" >> .cell_temp
		}
	}
	exec sort -k2 .cell_No_check_temp > .No_check_temp
	exec sort -k2 .cell_Fail_temp     > .Fail_temp
	exec sort -k2 .cell_temp          > .temp

}
 
# Find dont_touch net
if { $USER_DONT_TOUCH_NET_LIST_cnt > 0 } {
	exec touch .net_No_Check_temp
	exec touch .net_Fail_temp    
	exec touch .net_temp         

	foreach_in_collection itr $USER_DONT_TOUCH_NET_LIST {
		if { [string match "* [get_object_name $itr] *" " $USER_DONT_TOUCH_NET_NO_CHECK "] } {
			echo "net    [get_object_name $itr] ()    No_Check" >> .net_No_Check_temp
		} elseif { [string match "* [get_object_name $itr] *" " [get_object_name $DIFF_NET_LIST] "]  } {
			echo "net    [get_object_name $itr] ()    Fail" >> .net_Fail_temp
		} else {      
			echo "net    [get_object_name $itr] ()"   >> .net_temp
		}
	}
	exec sort -k1 .net_No_Check_temp >> .No_check_temp
	exec sort -k1 .net_Fail_temp     >> .Fail_temp
	exec sort -k1 .net_temp          >> .temp
}

exec cat .Fail_temp      > .temp_2
exec cat .temp          >> .temp_2
exec cat .No_check_temp >> .temp_2

exec sed -i "1 i\Type Object Ref_name Diff_Check" .temp_2
exec column -t .temp_2 > .temp_3
exec sed -i "s#()#  #g" .temp_3

set char_cnt_cmd    {grep "^Type " .temp_3 | wc -c}
set char_cnt        [exec sh -c $char_cnt_cmd]

set dash [string repeat "-" [expr $char_cnt + 2]]
exec sed -i "2 i\\$dash" .temp_3

exec cat .header.rpt .temp_3 >  ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_dont_touch.rpt
exec rm -rf .header.rpt .cell_No_check_temp .cell_Fail_temp .cell_temp .net_No_Check_temp .net_Fail_temp .net_temp .No_check_temp .Fail_temp .temp .temp_2 .temp_3

# Find dont_use library cell

if { $synopsys_program_name == "fc_shell" } {
	set USER_DONT_USE_CELL_LIST     [get_lib_cells */* -filter "(dont_use(block) == true || included_purposes(block) == none) && dont_use(lib) == false"]
} else {
	set USER_DONT_USE_CELL_LIST     [remove_from_collection [get_lib_cells */* -filter "dont_use == true && syn_library == true && full_name !~ *gtech*"] [get_lib_cells */* -filter "dont_touch == true"]]
}

set USER_DONT_USE_CELL_LIST_cnt [sizeof_collection $USER_DONT_USE_CELL_LIST]

# Print dont_use library cell
echo "#################################################################"          > ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_dont_use.rpt
echo "# User define dont_use library cell count : $USER_DONT_USE_CELL_LIST_cnt"  >> ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_dont_use.rpt
echo "#################################################################"         >> ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_dont_use.rpt
echo ""                                                                          >> ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_dont_use.rpt
if { $USER_DONT_USE_CELL_LIST_cnt > 0 } {
	foreach_in_collection USER_DONT_USE_CELL $USER_DONT_USE_CELL_LIST {
		echo "[get_object_name $USER_DONT_USE_CELL]" >> ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_dont_use.rpt
	}
}

# Find size_only cell
# size only cell
##set SIZE_ONLY_CELL  [get_cells -hierarchical -filter "is_hierarchical==false && const_prop_off == true && del_unloaded_gate_off == true && resyn_off == true && local_optz_off == true && structure_off == true"]
#set SIZE_ONLY_CELL  [get_cells -hierarchical -filter "is_hierarchical==false && const_prop_off == true && del_unloaded_gate_off == true && resyn_off == true && local_optz_off == true"]

if { $synopsys_program_name == "fc_shell" } {
	set USER_SIZE_ONLY_CELL			 [get_cells -hierarchical -filter "user_size_only == true && is_hierarchical == false"]
	set USER_SIZE_ONLY_CELL_INFO_cnt [sizeof_collection $USER_SIZE_ONLY_CELL]
} else {
	report_size_only -nosplit > ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.size_only.rpt
	set flag [catch {exec grep -E " user|,user" ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.size_only.rpt | grep -v ":" | grep -v "^ "} USER_SIZE_ONLY_CELL_INFO]
	set USER_SIZE_ONLY_CELL_INFO_cnt "0"
	if {$flag != 0} {
		sh touch .temp_2.rpt
	} else {
		foreach {cell_name size_only_info} $USER_SIZE_ONLY_CELL_INFO {
			incr USER_SIZE_ONLY_CELL_INFO_cnt
			echo "$cell_name ([get_attr [get_cells $cell_name] ref_name])" >> .temp.rpt
		}
		exec column -t .temp.rpt > .temp_2.rpt
	}
}
# Print size_only cell
echo "#################################################################"        > .header.rpt
echo "# User define set_size_only cell count : $USER_SIZE_ONLY_CELL_INFO_cnt"  >> .header.rpt
echo "#################################################################"       >> .header.rpt
echo ""                                                                        >> .header.rpt
if { $synopsys_program_name == "fc_shell" } {
	sh touch .temp_2.rpt
	if { $USER_SIZE_ONLY_CELL_INFO_cnt > 0 } {
		foreach_in_collection CELL $USER_SIZE_ONLY_CELL {
			echo "[get_object_name $CELL]" >> .temp_2.rpt
		}
		exec cat .header.rpt .temp_2.rpt > ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_size_only.rpt
		exec rm -rf .header.rpt .temp_2.rpt
	}

} else {
	exec cat .header.rpt .temp_2.rpt > ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.user_size_only.rpt

# [RECOVERED_UNMAPPED_FROM 019b72db-43ff-71fb-bc4b-a93381e467e2.txt] This block appeared before the first PATH marker in 019b72db-43ff-71fb-bc4b-a93381e467e2.txt.
# [ATTACH_DECISION] Attached to previous file by sequential continuity.
	exec rm -rf .header.rpt .temp.rpt .temp_2.rpt
}


if { $synopsys_program_name == "fc_shell" } {
	set REPORT_DIR $ORG_REPORT_DIR
}
