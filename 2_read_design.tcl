###################################################################################################
# File               : 2_read_design.tcl                                                          #
# Author             : ADT-DT (jyjang)                                                            #
# Author2            : ADT-DT (jmpark)                                                            #
# Description        : Read design for synthesis                                                  #
# Script Version     : 0.8                                                                        #
# Revision History   :                                                                            #
#         2023.03.03 - first released                                                             #
#         2024.10.10 - blobk abs read design modfiy                                               #
#         2024.10.18 - create_link_block_abs condition modfiy                                     #
#         2024.11.05 - sub block elab ddc read flow add 	                                      #
#         2024.11.05 - sub block abs mapped ddc fix ("@hdl_template == ${block_abs_name}")		  # 
#         2024.12.02 - remove "create_link_block_abs"											  #
#         2024.12.02 - modify condition "create_link_block_abs"									  #
#         2024.12.10 - modify remove sub design 												  #
#         2024.12.26 - modify remove sub design (add if condition)								  #
#         2025.02.18 - modify sub block ddc read flow	              							  #
#                                                                                                 #
###################################################################################################

################################################################################
# Analyze RTL
#################################################################################
proc_time READ_DESIGN_START -enable_log -log_prefix runtime
# Create a code list according to the rtl code format.
set vcode        "$OUTFD_DIR/${TOP_DESIGN}/${INDB_VER}/indb/vcode.f"
if { [info exist USER_VCODE_LIST] && $USER_VCODE_LIST != "" } {
	set vcode_list   "${USER_VCODE_LIST}"
    puts "Information_ADF: Use user define vcode_list"
    puts "                   $vcode_list"

} else {
	set vcode_list   "${OUTFD_DIR}/${TOP_DESIGN}/${INDB_VER}/indb/vcode.list"
}
set elab_ddc     "$OUTFD_DIR/${TOP_DESIGN}/${INDB_VER}/indb/${TOP_DESIGN}.elab.ddc"
if { [info exist USER_NETLIST] && $USER_NETLIST != "" } {
	set target_netlist   "${USER_NETLIST}"
    puts "Information_ADF: Use user define USER_NETLIST"
    puts "                   $USER_NETLIST"

}



if { $IMPL_BLOCK_ABS_NAME != "NONE" || $IMPL_BLOCK_ABS_NLIB_NAME != "NONE" } {
	set ABS_BLOCK_NAME [regsub -all "NONE" "$IMPL_BLOCK_ABS_NAME $IMPL_BLOCK_ABS_NLIB_NAME" ""]
	set set_top_implementation_options_cmd "set_top_implementation_options -block_references \"$ABS_BLOCK_NAME\""
    puts "RM-info: Running $set_top_implementation_options_cmd"
    eval ${set_top_implementation_options_cmd}
}

if { $INDB_TYPE == "ddc" } { 
    if { [file exists $elab_ddc ] } {
       read_ddc $elab_ddc        
   } else  {                    
       puts "\n <ADF_ERROR> : The file to read does not exist!!! .\n"
   }
} elseif {$INDB_TYPE == "net"} {
    if { [file exists $target_netlist ] } {
        read_verilog -netlist $target_netlist
    } else  {                    
       puts "\n <ADF_ERROR> : The Netlist file to read does not exist!!! .\n"
   }
} else {
    if { [file exists $vcode_list ] } {
    puts "Read Vcode List : $vcode_list"
    redirect ${LOGS_DIR}/${TOP_DESIGN}.vcode_list.log     { source -echo  -verbose $vcode_list }
        if { [info exists VHDL_SOURCE_FILES ] } {
            puts "\n <ADF_INFO> : VHDL_SOURCE_FILES Reading ...\n"
            redirect ${LOGS_DIR}/${TOP_DESIGN}.analyze_vhdl.log     { analyze -format vhdl     $VHDL_SOURCE_FILES      }
        }
        if { [info exists SVERILOG_SOURCE_FILES ] } {
            puts "\n <ADF_INFO> : SVERILOG_SOURCE_FILES Reading ...\n"
            redirect ${LOGS_DIR}/${TOP_DESIGN}.analyze_sverilog.log { analyze -format sverilog $SVERILOG_SOURCE_FILES  }
        }
        
        if { [info exists VERILOG_SOURCE_FILES ] } {
            puts "\n <ADF_INFO> :  VERILOG_SOURCE_FILES Reading ...\n"
            redirect ${LOGS_DIR}/${TOP_DESIGN}.analyze_verilog.log { analyze -format verilog $VERILOG_SOURCE_FILES  }
        } 
    } elseif { [file exists $vcode ] } {
        set vcmd   "analyze  -vcs \"-f  ${vcode}\"  $IMPL_VCS_OPTION"
        redirect ${LOGS_DIR}/${TOP_DESIGN}.analyze_vcs.log { eval $vcmd }
        puts "Read Vcode List : $vcode"
        puts "$vcmd"
    } else {
   puts "\n <ADF_ERROR> : The file to read does not exist!!! .\n"
   }
}




###############################################################################
# Elaborate
###############################################################################
if { $INDB_TYPE == "rtl"  } {
proc_time elaborate_START -enable_log -log_prefix runtime
    if { [info exists IMPL_PARAMETER] && ${IMPL_PARAMETER} != ""} {
        redirect ${LOGS_DIR}/${TOP_DESIGN}.elaborate.log {  elaborate ${IMPL_ELAB_LEVEL} -parameters ${IMPL_PARAMETER} }
        puts "\n <ADF_INFO> : Elaborate ${IMPL_ELAB_LEVEL} -parameters ${IMPL_PARAMETER} \n"
    } elseif {[info exists IMPL_PARAMETER_FILE] && ${IMPL_PARAMETER_FILE} != ""} {
        redirect ${LOGS_DIR}/${TOP_DESIGN}.elaborate.log {  elaborate ${IMPL_ELAB_LEVEL} -file_parameters ${IMPL_PARAMETER_FILE} }
        puts "\n <ADF_INFO> : Elaborate ${IMPL_ELAB_LEVEL} -file_parameters ${IMPL_PARAMETER_FILE} \n"
    } else {
        redirect ${LOGS_DIR}/${TOP_DESIGN}.elaborate.log {  elaborate ${IMPL_ELAB_LEVEL} }
        puts "\n <ADF_INFO> : Elaborate ${IMPL_ELAB_LEVEL} \n"
    }
proc_time elaborate_END -enable_log -log_prefix runtime
}

set_verification_top

###############################################################################
# Rename Design
###############################################################################
set ORG_DESIGN_NAME [get_object_name [current_design]]
if {"$ORG_DESIGN_NAME" != "${TOP_DESIGN}"} {
    if {[info exists IMPL_RENAME_DESIGN] && $IMPL_RENAME_DESIGN  != ""} {
        puts "Information_ADF : current_design changed to \$IMPL_RENAME_DESIGN ($IMPL_RENAME_DESIGN)"
        rename_design $ORG_DESIGN_NAME $IMPL_RENAME_DESIGN
    } else {
        puts "Information_ADF : current_design changed to \$TOP_DESIGN ($TOP_DESIGN)"
        rename_design $ORG_DESIGN_NAME ${TOP_DESIGN}
    }
}

# ADP620 , https://redmine.adtek.co.kr/issues/9191#note-2
if { [info exist current_design] && $current_design == "css_flexible_hierarchy_compute_tile" } {
	set cmn_hns_rename "[get_attribute [get_cells u_hns0/g_hns_element.u_hns] ref_name]"
	puts "cmn_hns_rename: ${cmn_hns_rename}"
	rename_design $cmn_hns_rename cmn_hns
    puts "\n <ADF_INFO> : current_design_changed to css_flexible_hierarchy_compute_tile"
}

if { $IMPL_BLOCK_ABS_NAME != "NONE" } {
    foreach block_abs_name $IMPL_BLOCK_ABS_NAME {
		#modify BMK 250103
		if {[string length [get_designs -quiet $block_abs_name]] == 0} {
		    puts "Design ${block_abs_name} not found. skip remove designs"
		} else {
			#add jmpark 241210 start
			if {[filter [get_designs -quiet *] "@hdl_template == $block_abs_name"] == "" } {
				echo "\"$block_abs_name\" hdl_template name is \"[get_attribute [get_designs $block_abs_name] hdl_template]\" , RTL design name and elaborate design name are mismatched. The reason is the parameter value."

				if {[string match [get_object_name [filter [get_designs -quiet *] "@hdl_template == [get_attribute [get_designs $block_abs_name] hdl_template]"]] $block_abs_name]} { ;# for double check 
					remove_design -hierarchy [get_designs $block_abs_name]
				}

			} else {
				remove_design -hierarchy [filter [get_designs -quiet *] "@hdl_template == ${block_abs_name}"]
			}
        }
		#end
        set abs_ddc_file "${OUTFD_DIR}/${block_abs_name}/$SUB_INDB_VER($block_abs_name)/dc_syn/$SUB_NET_REVISION_SYN($block_abs_name)/${OUTPUT_DIR}/${block_abs_name}.mapped.ddc"
        if {[info exists Black_box]} {
            set Black_box [regsub {$sub_block_name} $Black_box {}]
        } else {
            set Black_box [regsub {$sub_block_name} $HIER_DESIGN {}]
        }

        if {[file exists $abs_ddc_file]} {
            puts "Information_ADF : sub block -> ${block_abs_name} , sub ddc_file -> $abs_ddc_file\n"
		    redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "\n $block_abs_name"}
		    redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "    DDC : $abs_ddc_file"}

            read_ddc  $abs_ddc_file
        } else { 
            puts "Error_ADF : ddc_file ($abs_ddc_file) is not exist\n" 
		    redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "\n $block_abs_name"}
		    redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "    BlackBox : $abs_ddc_file does not exist"}
        }

		#BMK	#add jmpark 241226
		#BMK	if {[string length [get_designs -quiet $block_abs_name]] == 0} {
		#BMK	    puts "Design ${block_abs_name} not found. skip remove designs"
		#BMK	} else {
		#BMK		#add jmpark 241210 start
		#BMK		if {[filter [get_designs -quiet *] "@hdl_template == $block_abs_name"] == "" } {
		#BMK			echo "\"$block_abs_name\" hdl_template name is \"[get_attribute [get_designs $block_abs_name] hdl_template]\" , RTL design name and elaborate design name are mismatched. The reason is the parameter value."

		#BMK			if {[string match [get_object_name [filter [get_designs -quiet *] "@hdl_template == [get_attribute [get_designs $block_abs_name] hdl_template]"]] $block_abs_name]} { ;# for double check 
		#BMK				remove_design -hierarchy [get_designs $block_abs_name]
		#BMK			}

		#BMK		} else {
		#BMK			remove_design -hierarchy [filter [get_designs -quiet *] "@hdl_template == ${block_abs_name}"]
		#BMK		}
		#BMK		#end
        #BMK	set abs_ddc_file "${OUTFD_DIR}/${block_abs_name}/$SUB_INDB_VER($block_abs_name)/dc_syn/$SUB_NET_REVISION_SYN($block_abs_name)/${OUTPUT_DIR}/${block_abs_name}.mapped.ddc"
        #BMK	puts "\n <ADF_INFO> : ddc_file -> $abs_ddc_file \n"
        #BMK	read_ddc  $abs_ddc_file
		#BMK	}
    } 
}

if { $IMPL_BLOCK_ABS_NLIB_NAME != "NONE" } {
    foreach block_abs_name $IMPL_BLOCK_ABS_NLIB_NAME {
		#modify BMK 250103
		if {[string length [get_designs -quiet $block_abs_name]] == 0} {
		    puts "Design ${block_abs_name} not found. skip remove designs"
		} else {
			#add jmpark 241210 start
			if {[filter [get_designs -quiet *] "@hdl_template == $block_abs_name"] == "" } {
				echo "\"$block_abs_name\" hdl_template name is \"[get_attribute [get_designs $block_abs_name] hdl_template]\" , RTL design name and elaborate design name are mismatched. The reason is the parameter value."

				if {[string match [get_object_name [filter [get_designs -quiet *] "@hdl_template == [get_attribute [get_designs $block_abs_name] hdl_template]"]] $block_abs_name]} { ;# for double check 
					remove_design -hierarchy [get_designs $block_abs_name]
				}

			} else {
				remove_design -hierarchy [filter [get_designs -quiet *] "@hdl_template == ${block_abs_name}"]
			}
        }
		#end

        set abs_ddc_file "${OUTFD_DIR}/${block_abs_name}/$SUB_INDB_VER($block_abs_name)/dc_syn/$SUB_NET_REVISION_SYN($block_abs_name)/${OUTPUT_DIR}/${block_abs_name}.nlib.ddc"
        if {[info exists Black_box]} {
            set Black_box [regsub {$sub_block_name} $Black_box {}]
        } else {
            set Black_box [regsub {$sub_block_name} $HIER_DESIGN {}]
        }

        if {[file exists $abs_ddc_file]} {
            puts "Information_ADF : sub block -> ${block_abs_name} , sub nlib_ddc_file -> $abs_ddc_file\n"
		    redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "\n $block_abs_name"}
		    redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "    NLIB_DDC : $abs_ddc_file"}
            read_ddc  $abs_ddc_file
        } else { 
            puts "Error_ADF : nlib_ddc_file ($abs_ddc_file) is not exist\n" 
		    redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "\n $block_abs_name"}
		    redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "    BlackBox : $abs_ddc_file does not exist"}
        }
    } 
}

if {[info exists Black_box] && $Black_box != ""} {
	foreach blk_name $Black_box {
	    puts "Information_ADF : sub block -> ${blk_name} , blackbox\n"
		redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "\n $blk_name"}
		redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "    BlackBox : No information"}
	}
}

#if { $IMPL_BLK_ELAB_DDC == "NONE" && $IMPL_BLOCK_ABS_NAME != "NONE" } {
#    foreach block_abs_name $IMPL_BLOCK_ABS_NAME {
#		#add jmpark 241226
#			if {[string length [get_designs -quiet $block_abs_name]] == 0} {
#			    puts "Design ${block_abs_name} not found. skip remove designs"
#			} else {
#				#add jmpark 241210 start
#				if {[filter [get_designs -quiet *] "@hdl_template == $block_abs_name"] == "" } {
#					echo "\"$block_abs_name\" hdl_template name is \"[get_attribute [get_designs $block_abs_name] hdl_template]\" , RTL design name and elaborate design name are mismatched. The reason is the parameter value."
#
#					if {[string match [get_object_name [filter [get_designs -quiet *] "@hdl_template == [get_attribute [get_designs $block_abs_name] hdl_template]"]] $block_abs_name]} { ;# for double check 
#						remove_design -hierarchy [get_designs $block_abs_name]
#					}
#
#				} else {
#					remove_design -hierarchy [filter [get_designs -quiet *] "@hdl_template == ${block_abs_name}"]
#				}
#				#end
#        	set abs_ddc_file "${OUTFD_DIR}/${block_abs_name}/$SUB_INDB_VER($block_abs_name)/dc_syn/$SUB_NET_REVISION_SYN($block_abs_name)/${OUTPUT_DIR}/${block_abs_name}.mapped.ddc"
#        	puts "\n <ADF_INFO> : ddc_file -> $abs_ddc_file \n"
#        	read_ddc  $abs_ddc_file
#			}
#    } 
#} elseif { $IMPL_BLK_ELAB_DDC != "NONE" && $IMPL_BLK_ELAB_DDC != "NONE" } {
#	foreach block_abs_name $IMPL_BLK_ELAB_DDC {
#        set abs_ddc_file "${OUTFD_DIR}/${block_abs_name}/$SUB_INDB_VER($block_abs_name)/dc_syn/$SUB_NET_REVISION_SYN($block_abs_name)/${OUTPUT_DIR}/${block_abs_name}.elab.ddc"
#        puts "\n <ADF_INFO> : ddc_file -> $abs_ddc_file \n"
#        read_ddc  $abs_ddc_file
#	}
#}

# current_design ${TOP_DESIGN}
# link

# if { $IMPL_BLOCK_ABS_NAME != "NONE"} {
# 	if { [shell_is_dcnxt_shell] && $NDM_MODE && [shell_is_in_topographical_mode] } {
# 		create_link_block_abstraction -output_ndm_dir hier_ndm
# 	}
# }

# add jmpark 241010
# Prevent assignment statements
if { $PROJECT == "N1B0" } {
	set_fix_multiple_port_nets -output -constants -buffer_constants
} else {
	set_fix_multiple_port_nets -all -buffer_constants
}

proc_time READ_DESIGN_END -enable_log -log_prefix runtim
