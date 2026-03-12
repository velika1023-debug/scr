###################################################################################################
# File               : 2_design_setup.tcl                                                         #
# Author             : ADT-DT (jblee)                                                             #
# Description        : load design and elaborate                                                  #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.20                                                                 #
# Script Version     : 1.1                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
#         2025.08.20 - Add USER_NETLIST                                                           #
###################################################################################################

################################################################################
# Generate RTL File Lists
################################################################################
set vcode        "${OUTFD_DIR}/${TOP_DESIGN}/${INDB_VER}/indb/vcode.f"
if { [info exist USER_VCODE_LIST] && $USER_VCODE_LIST != "" } {
	set vcode_list   "${USER_VCODE_LIST}"
    puts "Information_ADF: Use user define vcode_list"
    puts "                   $vcode_list"

} else {
	set vcode_list   "${OUTFD_DIR}/${TOP_DESIGN}/${INDB_VER}/indb/vcode.list"
}

if { [info exist USER_NETLIST] && $USER_NETLIST != "" } {
	set target_netlist   "${USER_NETLIST}"
    puts "Information_ADF: Use user define USER_NETLIST"
    puts "                   $USER_NETLIST"

}

################################################################################
# Reading indb files
################################################################################
if { $INDB_TYPE == "rtl" } {
    proc_time analyze_START -enable_log -log_prefix runtime
    if { [file exists $vcode_list] } {
        puts "Read Vcode List : $vcode_list"
        redirect ${LOG_DIR}/${TOP_DESIGN}.vcode_list.log     { source -echo  -verbose $vcode_list }
    
        if { [info exists VHDL_SOURCE_FILES ] } {
            puts "Information_ADF : Reading \$VHDL_SOURCE_FILES"
            redirect ${LOG_DIR}/${TOP_DESIGN}.analyze_vhdl.log     { analyze -format vhdl     $VHDL_SOURCE_FILES      }
        }
        if { [info exists SVERILOG_SOURCE_FILES ] } {
            puts "Information_ADF: Reading \$SVERILOG_SOURCE_FILES"
            redirect ${LOG_DIR}/${TOP_DESIGN}.analyze_sverilog.log { analyze -format sverilog $SVERILOG_SOURCE_FILES  }
        }
        
        if { [info exists VERILOG_SOURCE_FILES ] } {
            puts "Information_ADF: Reading \$VERILOG_SOURCE_FILES"
            redirect ${LOG_DIR}/${TOP_DESIGN}.analyze_verilog.log { analyze -format verilog $VERILOG_SOURCE_FILES  }
        }
    
    } elseif { [file exists $vcode ] } {
        puts "Information_ADF: Analyze RTL by reading vcode file"
        puts "Read Vcode List : $vcode"
        set vcmd "analyze  -vcs \"-f  ${vcode}\"  $IMPL_VCS_OPTION"
        puts "$vcmd"
        redirect ${LOG_DIR}/${TOP_DESIGN}.analyze_vcs.log { eval $vcmd }
    } else {
        puts "Error_ADF : The file to read does not exist"
        exit
    }
    proc_time analyze_END -enable_log -log_prefix runtime
} elseif { $INDB_TYPE == "net" } {
    if { [file exists $target_netlist] } {
        read_verilog -top $TOP_DESIGN $target_netlist
        link_block
    } else  {                    
       puts "Error_ADF : The Netlist file to read does not exist."
       exit
	}
}

## checkpoint off for EQ check
set_verification_checkpoints -off

###############################################################################
# Elaborate
###############################################################################
if { $INDB_TYPE == "rtl"  } {
    proc_time elaborate_START -enable_log -log_prefix runtime
    if { [info exists IMPL_PARAMETER] && ${IMPL_PARAMETER} != ""} {
        redirect ${LOG_DIR}/${TOP_DESIGN}.elaborate.log {  elaborate ${IMPL_ELAB_LEVEL} -parameters ${IMPL_PARAMETER} }
        puts "Information_ADF : Elaborate ${IMPL_ELAB_LEVEL} -parameters ${IMPL_PARAMETER} "
    } else {
        redirect ${LOG_DIR}/${TOP_DESIGN}.elaborate.log {  elaborate ${IMPL_ELAB_LEVEL} }
        puts "Information_ADF : Elaborate ${IMPL_ELAB_LEVEL} "
    }
    proc_time elaborate_END -enable_log -log_prefix runtime
}

###############################################################################
# Rename Design
###############################################################################
if { $INDB_TYPE == "rtl"  } {
    if { $USER_STM } {
        if { [info exists USER_STM_HDL_FILE] && $USER_STM_HDL_FILE != ""} {
            set USER_TOP_MODULE [get_modules * -filter "hdl_file =~*$USER_STM_HDL_FILE*"]
            puts "Information_ADF: Set the module with hdl_file as the top module ([get_attribute $USER_TOP_MODULE name]) "
            rename_module $USER_TOP_MODULE ${TOP_DESIGN}
        } else {
            puts "Error_ADF: Module with hdl_file ($USER_STM_HDL_FILE) does not exist!!"
            exit
        }
    } else {
        set ORG_DESIGN_NAME [get_attribute [current_design] top_module_name]
        if {"$ORG_DESIGN_NAME" != "${TOP_DESIGN}"} {
            if {[info exists IMPL_RENAME_DESIGN] && $IMPL_RENAME_DESIGN  != ""} {
                puts "Information_ADF : current_design changed to \$IMPL_RENAME_DESIGN ($IMPL_RENAME_DESIGN)"
                rename_module $ORG_DESIGN_NAME $IMPL_RENAME_DESIGN
            } else {
                puts "Information_ADF : current_design changed to \$TOP_DESIGN ($TOP_DESIGN)"
                rename_module $ORG_DESIGN_NAME ${TOP_DESIGN}
            }
        }
    }
}
