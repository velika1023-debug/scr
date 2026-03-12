###################################################################################################
# File               : main.tcl                                                                   #
# Author             : ADT-DT (bmkim)                                                             #
# Description        : NDM Gen flow                                                               #
# Usage              :                                                                            #
# Init Release Date  : 2025.06.04                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.06.04 - first released                                                             #
#         2025.08.19 - Remove the step that splits the DB list based on scenario                  #
#         2025.09.03 - Setting DB list based on all scenario                                      #
###################################################################################################

#################################################################
##  create reference NDM library
#################################################################
# proc_time
set proc_files [lsort [glob -nocomplain ${COMMON_TCL_PROCS}/proc_time.v3.7.tcl]]
if {[llength $proc_files] > 0 } {
    puts "\nInformation_ADF : Loading Common procedure : \n"
    foreach FILE $proc_files {
        puts "\nInformation_ADF : Load Common proc -> $FILE \n"
        source $FILE
    }
}

proc_time TOTAL_START 
#################################################################################
# variable
#################################################################################
source -e -v ${RUN_DIR}/con/user_design_setup.tcl

#################################################################################
# Common_ndm
#################################################################################
proc_time FC_SETUP_START 
source -e -v ${COMMON_TCL}/NDM_GEN/0_fc_setup.tcl
proc_time FC_SETUP_END 


#################################################################################
# NDM PATH SETUP
#################################################################################
# Backup old ndm files
set backup_ndm_files  ""

set old [sh date +%m%d_%H:%M:%S]
if {![catch {set backup_ndm_files [glob ${NDM_DIR}/*.ndm]}]} {
    echo "Information_ADF: Moving old ndm files to ${NDM_DIR_OLD}/ndm_${old}"
    sh mkdir -p ${NDM_DIR_OLD}/ndm_${old}
    sh mv ${NDM_DIR}/*.ndm ${NDM_DIR_OLD}/ndm_${old}
}

#################################################################################
# DK setting
#################################################################################
proc_time DK_SETUP_START 
source -e -v ${COMMON_TCL}/NDM_GEN/1_dk_setup.tcl
proc_time DK_SETUP_END 

#################################################################################
# NDM Gen
#################################################################################
proc_time NDM_GEN_START
if {![info exist SCALE_FACTOR] || $SCALE_FACTOR == ""} {
    set value [exec cat $TECH_FILE | grep lengthPrecision]
    regexp {lengthPrecision\s*=\s*(\d+)} $value match SCALE_FACTOR
    puts "Information_ADF : tech : $TECH_FILE , Scale_factor : $SCALE_FACTOR"
}

create_workspace EXPLORATION -flow exploration -scale_factor $SCALE_FACTOR -technology $TECH_FILE

foreach ll $LINK_LIBRARY_FILES {
    if {[file exists $ll]} {
    puts "Information_ADF : Read DB - $ll"
    set lib_name [lindex [split $ll "/"] end]
    read_db  $ll -process_label $lib_name
    } else {
        puts ""
        puts "#####################################################################"
        puts "Warning_ADF : File $ll is not exists"
        puts "Warning_ADF : File $ll is not exists"
        puts "Warning_ADF : File $ll is not exists"
        puts "#####################################################################"
        puts ""
    }
}
read_lef $LEF_FILES

group_libs
write_workspace -file ${SCRIPT_DIR}/EXPLORATION.tcl -commit_output ${NDM_DIR}
check_workspace
report_workspace > ${REPORT_DIR}/report_workspace.rpt
remove_workspace 
source ${SCRIPT_DIR}/EXPLORATION.tcl

proc_time NDM_GEN_END


#################################################################################
# Check NDM
#################################################################################
if {$GEN_NDM_RPT} {
    proc_time REPORT_START 
    
    create_workspace VERIFY -flow normal -technology $TECH_FILE -scale_factor ${SCALE_FACTOR}
    source ${COMMON_TCL}/NDM_GEN/proc_libs_validation.tcl
    set NDM_FILES   [glob -nocomplain ${NDM_DIR}/*ndm]
    libs_validation -cell_libs ${NDM_FILES}  -output_dir ${REPORT_DIR}
    remove_workspace
    
    proc_time REPORT_END
}
#################################################################################
# Exit
#################################################################################
proc_time TOTAL_END

if {$QUIT_ON_FINISH} {
    quit
}
