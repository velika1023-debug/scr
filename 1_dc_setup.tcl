###################################################################################################
# File               : 0_dc_setup.tcl                                                             #
# Author             : DTPI jmpark  				                                              #
# Description        : dc setup 																  #
# Usage              :                                                                            #
# Init Release Date  : 2023.03.31                                                                 #
# Last Update  Date  : 2023.06.09                                                                 #
# Last Update  Date  : 2024.10.07 (jmpark)                                                        #
# Script Version     : 0.4                                                                        #
# Revision History   :                                                                            #
#         2023.03.31 - first released                                                             #
#         2023.06.09 - add LIB_CORNER_TRANS                                                       #
#         2023.11.08 - SEC & ARM DK_TYPE Read                                                     #
#         2024.10.07 - merge setup_dc.tcl & 0_dc_lib_setup.tcl                                    #
#         2024.12.09 - add variable TARGET_PMK_LIB_NAME                                    		  #
#         2025.02.18 - change IMPL_BLK_ETM variable format                                   	  #
#                                                                                                 #
###################################################################################################

####################################################################################################
# LIBRARY_SETUP START
####################################################################################################

source -e -v ${PRJ_TOOLS_DIR}/sdc/add_prj_lib_option.tcl
set_app_var synthetic_library dw_foundation.sldb

if {$USE_MCMM} {
    set SET_SCENARIO $MCMM_SCENARIO_NAMES
} else {
    set SET_SCENARIO $SCENARIO_NAMES
}

####################################################################################################
# LINK_LIBRARY_FILES
####################################################################################################
set  LINK_LIBRARY_FILES     ""
set  IMPL_BLK_ETM_LIST      ""
set  MW_REFERENCE_LIB_DIRS  ""
set  SEARCH_PATH_DIRS       ""

puts "#########################################################################"
puts "## File : [info script]"
puts "#########################################################################"

if {[info exists USER_LINK_LIB_LOAD] && [file exists $USER_LINK_LIB_LOAD] } {
    puts "\n<ADF_INFO> : Loading user link library \n"
    set Fin [open $USER_LINK_LIB_LOAD r ]
    while { [gets $Fin line] != -1 } { puts "$line"
        if { [regexp {^#} $line ] } { continue }
        set LINK_LIBRARY_FILES [concat $LINK_LIBRARY_FILES $line]
    } ; close $Fin

} else  {
    # SCENARIO_NAMES is set your makefile
    foreach SCN $SET_SCENARIO {
        foreach BLK ${READ_DESIGN} {
            set BLK_DK_TYPE          [ set ${BLK}(DK_TYPE) ]
	        set BLK_ABS_MEM_VERSION  [ set ${BLK}(ABS_MEM_VERSION) ]
	        set BLK_ABS_IP_VERSION   [ set ${BLK}(ABS_IP_VERSION)  ]
	        set BLK_TRACK_FULL       [ set ${BLK}(TRACK_FULL)      ]

            # LIB_CORNER_TRANS variable is set in prj_lib_option file.
            if {[info exists LIB_CORNER_TRANS] && $LIB_CORNER_TRANS ne "" } {
                set LIB_CORNER $LIB_CORNER_TRANS
            } else {
                set LIB_CORNER [lindex [split $SCN "."] end ]
            }
            #LIB_CORNER : Before => misn.sspg_0p765v_m40c_sigcmax_globalRvia
            #LIB_CORNER : After  => sspg_0p765v_m40c_sigcmax_globalRvia

            foreach ABS_READ ${ABS_READS} {
                switch $ABS_READ {
                    "prim"  {  set  LIB_FILE  "${LIB_DIR}/abs/00_PRIM/${ABS_PRIM_VERSION}/00_DB/${LIB_CORNER}.db.abs.list"         ; set i 0  }
                    "mem"   {  set  LIB_FILE  "${LIB_DIR}/abs/01_MEM/${BLK}/${ABS_MEM_VERSION}/00_DB/${LIB_CORNER}.db.abs.list" ; set i 0  }
                    "ip"    {  set  LIB_FILE  "${LIB_DIR}/abs/02_IP/${BLK}/${ABS_IP_VERSION}/00_DB/${LIB_CORNER}.db.abs.list"   ; set i 0  }
                    default {  set  LIB_FILE  "unknow variable ABS_READS"   }
                }
                puts ""
                puts "#####################################################################"
                puts "## DESIGN   : $BLK   "
                puts "## ABS_READ : $ABS_READ "
                puts "## DK_TYPE  : $BLK_DK_TYPE  "
                puts "## LIB_FILE : $LIB_FILE "
                puts "#####################################################################"
                puts ""

                if {[file exists [which $LIB_FILE ]]} {
                    set Fin [open $LIB_FILE r]
                    while { [ gets $Fin line ] != -1 } {
                        if { [regexp {^#} $line] || ![regexp {\w+} $line] } { continue }

                        set lib_name [lindex [split $line "/"] end]
                        set lib_dir  [regsub "\/$lib_name" $line ""]

                        #Only Prim
                        if { $ABS_READ == "prim" } {
                            foreach blk_track_full $BLK_TRACK_FULL {
                                if { [string match "*${blk_track_full}*${lib_name}*" $line] } {
                                    incr i
                                    puts "LINK_LIB($i) : $line"
                                    set LINK_LIBRARY_FILES [concat $LINK_LIBRARY_FILES $line]
                                    set SEARCH_PATH_DIRS [ concat $SEARCH_PATH_DIRS $lib_dir]
                                }
                            }
                        # Only mem ip
                        } else {
                            incr i
                            puts "LINK_LIB($i) : $line"
                            set LINK_LIBRARY_FILES [concat $LINK_LIBRARY_FILES $line]
                            set SEARCH_PATH_DIRS [ concat $SEARCH_PATH_DIRS $lib_dir]
                        }

                    } ;close $Fin ;# while end
                } 
            }
        }
    } 
}
if {$IMPL_BLK_ETM != "" } {
    foreach block_abs_name $IMPL_BLK_ETM {
        set split_value        [split $block_abs_name ","]
        set sub_block_name     [lindex $split_value 0]
        set sub_block_etm_path [lindex $split_value 1]

        if {[info exists Black_box]} {
            set Black_box [regsub {$sub_block_name} $Black_box {}]
        } else {
            set Black_box [regsub {$sub_block_name} $HIER_DESIGN {}]
        }

        if {[file exists $sub_block_etm_path]} {
            set IMPL_BLK_ETM_LIST [concat $IMPL_BLK_ETM_LIST $sub_block_etm_path]
            echo "Information_ADF : sub block -> $sub_block_name , sub etm_file -> $sub_block_etm_path\n"
		    redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "\n $sub_block_name"}
		    redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "    ETM : $sub_block_etm_path"}
        } else { 
            puts "Error_ADF : etm_file ($sub_block_etm_path) is not exist\n"
		    redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "\n $sub_block_name"}
		    redirect -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "    BlackBox : $sub_block_etm_path does not exist"}
        }
    }
}

set LINK_LIBRARY_FILES_org $LINK_LIBRARY_FILES
set LINK_LIBRARY_FILES ""

foreach li $LINK_LIBRARY_FILES_org {
    if {[lsearch $LINK_LIBRARY_FILES $li] == -1} {
        lappend LINK_LIBRARY_FILES $li
    }
}
unset LINK_LIBRARY_FILES_org
set_app_var link_library "* ${LINK_LIBRARY_FILES} $synthetic_library $IMPL_BLK_ETM_LIST"


########################################################################################
## TARGET_LIBRARY_FILES
########################################################################################
set TARGET_LIBRARY_FILES ""
if { [info exists USER_TARGET_LIB_LOAD ] && [file exists $USER_TARGET_LIB_LOAD] } {
    puts "\n<ADF_INFO> : Loading user target library"
    set Fin [open $USER_TARGET_LIB_LOAD r ]
    while { [gets $Fin line ] != -1 } {
        if { [regexp {^#} $line] || ![regexp {\w+} $line] } { continue } ; #Exclude comments or leading blanks
        set TARGET_LIBRARY_FILES [concat $TARGET_LIBRARY_FILES $line]
    } close $Fin

} else {
    foreach SCN $SET_SCENARIO {
        set mcmm_opcon_lib_name($SCN) ""

        # LIB_CORNER_TRANS variable is set in prj_lib_option file.
        if {[info exists LIB_CORNER_TRANS] && $LIB_CORNER_TRANS ne "" } {
            set LIB_CORNER $LIB_CORNER_TRANS
        } else {
            set LIB_CORNER [lindex [split $SCN "."] end ]
        }

        set i 0
        set LIB_FILE "${LIB_DIR}/abs/00_PRIM/${ABS_PRIM_VERSION}/00_DB/${LIB_CORNER}.db.abs.list"
		#add jmpark 241209
		append TARGET_LIB_NAME " " $TARGET_PMK_LIB_NAME
        puts ""
        puts "#####################################################################"
        puts "## DESIGN          : $DESIGN   "
        puts "## TARGET_LIB_NAME : $TARGET_LIB_NAME"
        puts "## LIB_FILE        : $LIB_FILE "
        puts "#####################################################################"
        puts ""
        set Fin [open $LIB_FILE r]
        while { [gets $Fin line ] != -1 } {
            if { [regexp {^#} $line] || ![regexp {\w+} $line] } { continue }

            foreach lib_name $TARGET_LIB_NAME {
                foreach blk_track_full $BLK_TRACK_FULL {
                    if { [string match "*${blk_track_full}*${lib_name}_*" $line] } {
                        incr i
                        set mcmm_opcon_lib_name($SCN) [concat $mcmm_opcon_lib_name($SCN) [regsub {\.db.*} [lindex [split $line "/"] end] ""] ]
                        set TARGET_LIBRARY_FILES [concat $TARGET_LIBRARY_FILES $line]
                        puts "TARGET_LIB($i) ( $lib_name ) : $line"
#                        puts "<ADF_INFO> : mcmm_opcon_lib_name($SCN)  : $mcmm_opcon_lib_name($SCN) "
#                        puts "<ADF_INFO> : Target Library ($lib_name) : $line "
#                        puts ""
                        break
                    }
                }
            }
        }
    }
}; close $Fin
set_app_var target_library ${TARGET_LIBRARY_FILES}

####################################################################################################
# DB SETUP LOG
####################################################################################################
# TARGET DB Log
set filename "${LOG_DIR}/${TOP_DESIGN}.DB.log"
set file [open $filename "w"]
puts $file "# LINK DB LIST"
puts $file [join [split $link_library ] "\n"]
puts $file ""
# TARGET DB Log
puts $file "# Target DB LIST"
puts $file [join [split $target_library ] "\n"]
close $file


####################################################################################################
# MW LIB
####################################################################################################
if {[shell_is_in_topographical_mode] && !${NDM_MODE}  } {
    foreach ABS_READ ${ABS_READS} {
        switch $ABS_READ {
            "prim"  {  set MW_FILE "${LIB_DIR}/abs/00_PRIM/${ABS_PRIM_VERSION}/11_MW/mw.abs.list"             ; set i 0  }
            "mem"   {  set MW_FILE "${LIB_DIR}/abs/01_MEM/${TOP_DESIGN}/${ABS_MEM_VERSION}/11_MW/mw.abs.list" ; set i 0  }
            "ip"    {  set MW_FILE "${LIB_DIR}/abs/02_IP/${TOP_DESIGN}/${ABS_IP_VERSION}/11_MW/mw.abs.list"   ; set i 0  }
            default {  set MW_FILE "unknow variable ABS_READS"   }
        }
        puts ""
        puts "#####################################################################"
        puts "## DESIGN   : $DESIGN   "
        puts "## ABS_READ : $ABS_READ "
        puts "## DK_TYPE  : $DK_TYPE  "
        puts "## LIB_FILE : $LIB_FILE "
        puts "#####################################################################"
        puts ""

        if {[file exists [which $MW_FILE ]]} {
            set Fin [open $MW_FILE r]
            while { [ gets $Fin line ] != -1 } {
                if { [regexp {^#} $line] || ![regexp {\w+} $line] } { continue } ; #Exclude comments or leading blanks
                incr i
                puts "LINK_MW($i) : $line"
                set MW_REFERENCE_LIB_DIRS [concat $MW_REFERENCE_LIB_DIRS $line]
            } ;close $Fin ;# while end
        }
    }
}

####################################################################################################
# LIBRARY_SETUP END
####################################################################################################

#################################################################################################
##                                                                                             ##
## Title                : setup_dc.tcl                                                         ##
## Description          : Synthesis variable setup described in user_design_setup.tcl          ##
## Author               : DTPI jmpark 				                                           ##
## Initial Release Date : Apr. 24th, 2019                                                      ##
## Last Update Date     : May. 27th, 2024                                                      ##
## Last Update Date     : Oct. 07th, 2024                                                      ##
## Last Update Date     : Oct. 10th, 2024                                                      ##
## 						 -> prevent assignment statements
## Usage                : Sourcing this file is included in 'main.tcl' file                    ##
## Tool Version         : Samsung Foundry guided Design Compiler version                       ##
##                                                                                             ##
#################################################################################################

#Specifies a single path, similar to a search path, for reading and writing the alib files that correspond to the target libraries.
#The alib file is a pseudo library that maps from Boolean functional circuits to actual gates from the technology library. 
#You can place the alib file in your specified directory by setting the following command in Design Compiler
if { [info exist ALIB_DIR] && $ALIB_DIR != "" } {
   set_app_var alib_library_analysis_path ${ALIB_DIR}
}

if { [info exist CACHE_DIR] && ${CACHE_DIR} != ""} {
   set_app_var cache_read ${CACHE_DIR}
   set_app_var cache_write ${CACHE_DIR}
}

if {[info exist WORK_DIR] && ${WORK_DIR} != ""} {
   define_design_lib WORK -path ${WORK_DIR}
}

#################################################################################
# Recommended Variable settings 
#################################################################################
if {[shell_is_in_topographical_mode]} {

   # compile_timing_high_effort
   set_app_var compile_timing_high_effort       true
   puts [printvar compile_timing_high_effort]

   # Zroute-based congestion estimation for congestion-driven placement
   set_app_var placer_enable_enhanced_router 	true ; # default false
   puts [printvar placer_enable_enhanced_router]

} else {
   set_app_var auto_wire_load_selection 		false ;# default true
   puts [printvar auto_wire_load_selection]
}

set_app_var timing_enable_multiple_clocks_per_reg true
set_app_var enable_recovery_removal_arcs true
set_app_var timing_input_port_default_clock true

set_app_var compile_register_replication false

#Declares three-state nets as Verilog wire instead  of  tri.
set_app_var verilogout_no_tri true
set_app_var verilogout_show_unconnected_pins true

#jmpark 240524
#Controls printing error messages when there are unmapped cells, PVT mismatches or placer errors in the design being synthesized
set_app_var compile_report_on_unmapped_cells true

#jmpark 240612
#Allows Design Compiler to read RTL containing a limited set of PG (power/ground) nets and pin connections.
set_app_var dc_allow_rtl_pg true

#jmpark 240903
#Controls whether inverters can be moved across hierarchical boundaries during boundary optimization.
set_app_var compile_disable_hierarchical_inverter_opt true

# Identifies clock-gating circuitry inserted by power compiler form a strctural netlist.
set_app_var power_cg_auto_identify   true 

# Check for latches in RTL - add jmpark
set_app_var hdlin_check_no_latch true

#When this variable is set to true (the default), 
#the compile command tries to identify and merge registers in the current design that are equal or opposite. 
#This improves the area of the design.
set_app_var compile_enable_register_merging true

# Case analysis required to support EMA value setting for memories
set_app_var case_analysis_with_logic_constants true

# Specifies to the tool that nets are to receive the same names as the ports to which the nets are connected.
set_app_var write_name_nets_same_as_ports true

#This variable controls whether the Presto HDL Compiler compresses  long names for elaborated modules.
set_app_var hdlin_shorten_long_module_name true 

# Resolved an issue where the SVF was incorrectly applied due to logical hierarchy differences between Design Compiler and Formality.
set_app_var hdlin_enable_hier_map true

if {[info exists ELAB_CHAR_LIMIT]} {
# Project : N1B0, Issue : [JIRA] (N1ADT-539)
# This variable controls long module names. Check LINK-26(Warning).
set hdlin_module_name_limit ${ELAB_CHAR_LIMIT} ; # default  256
}

#******************************************************************************
# Define naming rule 
#******************************************************************************
# MultiBit Naming
if {$USE_MULTIBIT} {
    set_app_var bus_multiple_separator_style "_DCGMB_"
    set_app_var bus_multiple_name_separator_style "_DCGMB_"
}
set_app_var bus_extraction_style {%s[%d:%d]}                                                                                                                                                                                                                                                                                        
set_app_var bus_inference_style {%s[%d]}
set_app_var change_names_dont_change_bus_members {true}
set_app_var verilogout_higher_designs_first {true}

#******************************************************************************
#** NAMING RULE FOR Verilog HDL:                                             **
#******************************************************************************
define_name_rules sec_verilog -type port \
                              -equal_ports_nets  \
                              -map {{"_$","_0"}} \
                              -allowed {A-Z a-z 0-9 _ [] !} \
                              -first_restricted {0-9 _ !}   \
                              -last_restricted {_ !}
 
define_name_rules sec_verilog -type cell \
                              -map {{"_$","_0"}} \
                              -allowed {A-Z a-z 0-9 _ !} \
                              -first_restricted {0-9 _ !} \
                              -last_restricted {_ !} 
 
define_name_rules sec_verilog -type net \
                              -map {{"_$","_0"}} \
                              -equal_ports_nets \
                              -allowed {A-Z a-z 0-9 _ !} \
                              -first_restricted {0-9 _ !} \
                              -last_restricted {_ !} 

define_name_rules verilog -case_insensitive -dont_change_ports

#################################################################################
# Library Setup using information described in user_design_setup.tcl
#################################################################################
# Create and open NDM or milkyway library only when topographical mode is activated
if {[shell_is_in_topographical_mode]} {

   if { $NDM_MODE && [shell_is_dcnxt_shell] } {
   
      # ADD 241121 
      if {![info exist DESIGN_LIBRARY_SCALE_FACTOR] || $DESIGN_LIBRARY_SCALE_FACTOR == ""} {
      set value [exec cat $TECH_FILE | grep lengthPrecision]
      regexp {lengthPrecision\s*=\s*(\d+)} $value match DESIGN_LIBRARY_SCALE_FACTOR
      puts $DESIGN_LIBRARY_SCALE_FACTOR
      }

      # Append block-based reference libs if specified
      if {$IMPL_BLOCK_ABS_NLIB_NAME != "NONE" && $IMPL_BLOCK_ABS_NLIB_NAME != "" } {
            foreach block_abs_name $IMPL_BLOCK_ABS_NLIB_NAME {
              set NDM_REFERENCE_LIB "$NDM_REFERENCE_LIB ${OUTFD_DIR}/${block_abs_name}/$SUB_INDB_VER($block_abs_name)/dc_syn/$SUB_NET_REVISION_SYN($block_abs_name)/${OUTPUT_DIR}/${block_abs_name}.nlib"
          }
      }
      
      # Use existing NDM library if allowed and available
      if {${REUSE_NDM} && [file exist ${OUTPUT_DIR}/${NDM_DESIGN_LIB}]} {
          open_lib ${OUTPUT_DIR}/${NDM_DESIGN_LIB}
      } else {
          create_lib ${OUTPUT_DIR}/${NDM_DESIGN_LIB} -technology $TECH_FILE -ref_libs $NDM_REFERENCE_LIB -scale_factor $DESIGN_LIBRARY_SCALE_FACTOR
          #create_lib $NDM_DESIGN_LIB -technology $TECH_FILE -ref_libs $NDM_REFERENCE_LIB
      }
   } else {
      extend_mw_layers
      set_app_var ignore_tf_error true
      set_app_var spg_enable_via_resistance_support true
   
   
      if {![file isdirectory ${MW_LIBRARY_NAME} ]} {
         create_mw_lib -technology $TECH_FILE \
                       -mw_reference_library ${MW_REFERENCE_LIB_DIRS} \
                       ${MW_LIBRARY_NAME}
      } else {
         set_mw_lib_reference ${MW_LIBRARY_NAME} -mw_reference_library ${MW_REFERENCE_LIB_DIRS}
      }
      
      open_mw_lib $MW_LIBRARY_NAME
   }

    check_library > ${REPORTS_DIR}/${TOP_DESIGN}.check_library.rpt

}

#######################################################################################################
# Exit Design Compiler if topograhpical mode was not activated although related options are turned on.
#######################################################################################################

if {![shell_is_in_topographical_mode]} {
   if {$USE_SPG} {
      puts "ADT-ERROR: SPG flow is available in topographical mode."
      exit 1
   }
   if {$USE_MCMM} {
      puts "ADT-ERROR: MCMM synthesis is available in topographical mode."
      exit 1
   }
}

source ${SCRDIR}/mcmm_sanity_checker.tcl 
