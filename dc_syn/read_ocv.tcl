###################################################################################################
# File               : read_ocv.tcl                                                               #
# Author             : ADT-DT (bmkim)                                                             #
# Description        : read ocv derate                                                            #
# Usage              :                                                                            #
# Init Release Date  : 2025.01.16                                                                 #
# Last Update  Date  : 2025.01.16                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.07.28 - first released                                                             #
###################################################################################################

if {[info exists is_AOCVM] && $is_AOCVM == true } {

    set AOCVM_TECH_DIR "$STA_REF_HOME/AOCVM_TECH"
    puts "Information_ADF: Setting timing_aocvm_enable_analysis true "
    set_app_var timing_aocvm_enable_analysis true
    ;#------------------------------------------------------------------------------
    ;# Read AOCV tech for each library (Samsung LN14LPP AOCV compliant)
    ;# AOCVM tech files are supposed to have same fore names as linked libraries
    ;# e.g. "${lib_name}*.aocv*"
    ;#------------------------------------------------------------------------------
    foreach_in_collection lib_name [get_libs *] {
      #==============================================================================
      # DT-PI_Modi : edit method of read_aocvm
      #==============================================================================
      #DM_ORG set tech_file	[glob -nocomplain ${AOCVM_TECH_DIR}/${lib_name}*aocv*]
      set lib_name [get_object_name $lib_name]
      set tech_file_cmd "exec grep \"/${lib_name}.\*aocv.\*\" ${AOCVM_TECH_DIR}/aocv_path.list | head -n 1"
      if { [catch { eval $tech_file_cmd } Message] } { 
        echo "Warning_ADF : AOCV tech file not found for library - $lib_name"
        set tech_file ""
      } else {
        set tech_file $Message
      }
    
      if {[llength $tech_file] > 1} {
        echo "Warning_ADF : more than 1 AOCV techfile found - $tech_file"
      } elseif {$tech_file == ""} {
        # echo "Warning_ADF : AOCV tech file not found for library - $lib_name"
      } else {
        echo "Information_ADF : reading AOCVM tech file for library - $lib_name"
      }
      foreach fname $tech_file {
        echo "             $fname"
        if {[file readable $fname]} {
          read_ocvm $fname
        } else {
          echo "Error_ADF : AOCV tech file is unreadable - $fname"
        }
      }
    }
}

if {[info exists is_POCVM] && $is_POCVM == true} {
    if {![shell_is_in_topographical_mode]} {
        puts "Error_ADF: POCVM is available in topographical mode."
        return
    } else {
        puts "Information_ADF: Setting timing_pocvm_enable_analysis true "
    }
    set POCVM_TECH_DIR "$STA_REF_HOME/POCVM_TECH"
    set_app_var timing_pocvm_enable_analysis                       true
    set_app_var timing_pocvm_precedence                            library
   
    ;#------------------------------------------------------------------------------
    ;# Spatial variation table and default override 
    ;#------------------------------------------------------------------------------
    set tech_file [glob -nocomplain ${POCVM_TECH_DIR}/*[string tolower "${CORNER_PROC}*${CORNER_VOLT}*${CORNER_TEMP}"]*.pocv]
    if {$tech_file == ""} {
        set tech_file [glob -nocomplain ${POCVM_TECH_DIR}/*[string tolower "${CORNER_PROC}*${CORNER_TEMP}"]*.pocv]
        if {$tech_file == ""} {
            set tech_file [glob -nocomplain ${POCVM_TECH_DIR}/*[string tolower "${CORNER_PROC}"]*.pocv]
        }
    }
    if {[llength $tech_file] == 0 } {
        echo "Error_ADF : POCV tech file not found - ${POCVM_TECH_DIR}/*[string tolower ${CORNER_PROC}]*"
        return
    } elseif {[llength $tech_file] > 1} {
        echo "Warning_ADF : more than 1 POCV tech files found"
        foreach fname $tech_file {
            echo "             - reading $fname"
            read_ocvm $fname
        }
    } else {
        echo "Information_ADF : reading POCVM tech file - $tech_file"
        read_ocvm $tech_file
    }
    
    
    ;#------------------------------------------------------------------------------
    ;# Remove coefficient for user-defined skip-cells  
    ;#------------------------------------------------------------------------------
    if {[info exist POCVM_SKIP_CELLS]} {
        foreach _skip_cell $POCVM_SKIP_CELLS {
            echo "Information_ADF : zero POCVM coefficient for user-defined skip cell - $_skip_cell"
            set_timing_derate -cell_delay -pocvm_coefficient_scale_factor -early 0.0 [get_lib_cells */${_skip_cell}]
            set_timing_derate -cell_delay -pocvm_coefficient_scale_factor -late 0.0 [get_lib_cells */${_skip_cell}]
        }
    } else {
        echo "Information_ADF : POCVM_SKIP_CELLS variable has not been defined."
    }
    
}

if {[info exists USER_OCVM_FILE] && [file exists $USER_OCVM_FILE]} {
    set Guardband_file $USER_OCVM_FILE
} else {
    set Guardband_file "${COMMON_CON_DIR}/set_ocv_margin.${TARGET_CORNER}.log"
}
set Modify_Guardband_file "set_ocv_${TARGET_CORNER}.tcl"
if {[file exists $Guardband_file]} {
    echo "Information_ADF : Modify Guardband file - $Guardband_file"
    set fp [open $Guardband_file r]
    set fo [open $Modify_Guardband_file w+]
    
    while { [gets $fp line] >= 0 } {
        if { [string match "*_LIB_CELLS*" $line] && ![string match "*set_timing_derate*" $line] } {
            set str     [lindex $line 1]
            set str_com [lindex $line 2]
            puts $fo "lappend $str $str_com/*"
        } elseif {[string match "*aocvm_guardband*" $line]} {
            puts $fo "#Not Support \"-aocvm_guardband\" Command will be skipped - $line"
        } else {
            puts $fo "$line"
        }
    }
    close $fp
    close $fo

    source -e -v $Modify_Guardband_file
} else {
    echo "Information_ADF : Guardband file is not exist."
    echo "             - $Guardband_file"
}

if {[info exists is_AOCVM] && $is_AOCVM == true } {
    ;#------------------------------------------------------------------------------
    ;# Check AOCVM un-annotate cells 
    ;#------------------------------------------------------------------------------
    redirect ${REPORT_DIR}/AOCVM_unannotated.list {
        # report_aocvm -cell_delay -list_not_annotated 
        report_ocvm -type aocvm -list_not_annotated -nosplit
    }
} elseif {[info exists is_POCVM] && $is_POCVM == true} {
    ;#------------------------------------------------------------------------------
    ;# Check POCVM unannotated cells 
    ;#------------------------------------------------------------------------------
    redirect ${REPORT_DIR}/POCVM_unannotated.list {
        # report_ocvm -type pocvm -cell_delay -coefficient -lib_cell -list_not_annotated -nospl
        report_ocvm -type pocvm -list_not_annotated -nosplit
    }
}
