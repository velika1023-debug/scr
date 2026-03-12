################################################################################
# File Name     : proc_create_false_path_sdc.tcl
# Author        : iskim1001
# Last Modified : 2024-09-04 
# Version       : v0.1
# Location      : ${COMMON_TCL_PT_PROC}
#-------------------------------------------------------------------------------
# Description   :
# 	After performing the Pre-STA in PI, if deemed necessary, 
# 	please adjust the gen_false_path_sdc(slack_lesser_than) value to generate the *.set_false_path.pnr.sdc file 
# 	and provide this information to PD.
# 	1. To conduct SDC review at PI and PnR at PD simultaneously.
# 	2. To reduce PnR Run Time.
# 	3. To identify timing issues that were not visible due to Big Violation.
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-09-04] : iskim1001
#       - Initial Version Release
#-------------------------------------------------------------------------------
# Example :
# 	cmd > make sta gen_false_path_sdc=${on_off}_${slack}
# Usage :
# 1) cmd > make sta gen_false_path_sdc=0
#    Do not create *set_false_path.pnr.sdc.
#    Default is 0.
# 
# 2) cmd > make sta gen_false_path_sdc=1_-0.111
#    Create *set_false_path.pnr.sdc.
#    Standard slack is -0.111ns.
# 
# 3) cmd > make sta gen_false_path_sdc=1
#    Create *set_false_path.pnr.sdc.
#    Standard slack is applied as Default. ( Default is -0.050ns )
#
# Usage :
#if {[info exists gen_false_sdc] && [lindex [split $gen_false_sdc "_"] 0] } { 
#	set on_off [lindex [split $gen_false_sdc "_"] 0 ]
#	set slack  [lindex [split $gen_false_sdc "_"] 1 ]
#	source ${COMMON_TCL_PT_PROC}/proc_create_false_path_sdc.tcl
#	puts "Information_ADF: gen_false_sdc < on_off > --> ${on_off}"
#	puts "Information_ADF: gen_false_sdc < slack  > --> ${slack}" 
#	if { $slack == "" } { 
#		create_false_path_sdc -slack -0.0500  -start_end_type all -output ${OUTPUT_DIR}/${DESIGN}.${MODE}-${typ_volt}.set_false_path.pnr.sdc
#	} else { 
#		create_false_path_sdc -slack ${slack} -start_end_type all -output ${OUTPUT_DIR}/${DESIGN}.${MODE}-${typ_volt}.set_false_path.pnr.sdc
#	}
#}

proc create_false_path_sdc {args} {
	global OUTPUT_DIR
	global DESIGN
	global MODE
	global typ_volt
	parse_proc_arguments -args $args p_args

	if {[info exists p_args(-start_end_type)]    } { set start_end_type $p_args(-start_end_type)     } else { set start_end_type "all"    }
	if {[info exists p_args(-slack_lesser_than)] } { set slack          $p_args(-slack_lesser_than)  } else { set slack          "-0.050" }
	if {[info exists p_args(-output)]            } { set OUTPUT_FILE    $p_args(-output)             } else { set OUTPUT_FILE ${OUTPUT_DIR}/${DESIGN}.set_false_path.pnr.sdc }

	if {$p_args(-start_end_type) == "all" } {
		set start_end_type "reg_to_reg in_to_reg reg_to_out in_to_out"
	}
	

    set FOUT  [open ${OUTPUT_FILE} w]
	puts "OUTPUT_FILE  : $OUTPUT_FILE"
	puts "Target Slack : $slack"
	foreach temp $start_end_type {
		#set timing_path_collection     [get_timing_paths -start_end_pair -start_end_type $temp -slack_lesser_than $slack -nworst 1]
		#set timing_path_collection     [get_timing_paths -start_end_pair -start_end_type $temp -slack_lesser_than $slack -nworst 1 -max_path 9999]
		set timing_path_collection     [get_timing_paths -start_end_pair -start_end_type $temp -slack_lesser_than $slack -nworst 999999 -max_path 999999 ]
		set timing_path_collection_num [sizeof_collection $timing_path_collection]
		puts "# timing_path_collection_num ($temp) : $timing_path_collection_num ( slack_lesser_than : $slack )"

		if { $timing_path_collection_num == "0" } {
			puts $FOUT "# timing_path_collection_num ($temp) : $timing_path_collection_num ( slack_lesser_than : $slack )"
			puts $FOUT "#    There is no slk that satisfies the conditions."

		} else {
			puts $FOUT "# timing_path_collection_num ($temp) : $timing_path_collection_num"
			foreach_in_collection itr $timing_path_collection {
				set SP         [get_object_name [get_attribute $itr startpoint] ]
				set EP         [get_object_name [get_attribute $itr endpoint  ] ]
				set SLK        [get_attribute    $itr slack ]

				if { $temp == "reg_to_reg" } {
					set SP_mem_att [get_attribute   [get_cell -of $SP  ] is_memory_cell]
					set EP_mem_att [get_attribute   [get_cell -of $EP  ] is_memory_cell]
					if { $SP_mem_att == "true" || $EP_mem_att == "true" } {
						puts $FOUT "#skip(reg2mem, mem2reg) : set_false_path -from ($SP_mem_att) $SP -to (${EP_mem_att}) $EP \;# $SLK"
						continue
					}
				}
				puts $FOUT "set_false_path -from ${SP} -to ${EP} \;# $SLK"
			}
		}
		puts $FOUT ""
	}
	close $FOUT
}

define_proc_attributes create_false_path_sdc \
-info "Create an SDC that applies set_false_path to a timing path larger than the specific slack value." \
-define_args {
    {-start_end_type      "Type of timing_path"   "" one_of_string {required value_help {values {all reg_to_reg reg_to_out in_to_reg in_to_out} }}}
	{-slack_lesser_than   "slack"                 "" float   required }
	{-output              "output file name "     "" string optional }
}
