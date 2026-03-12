#!/bin/tclsh
################################################################################
# File Name     : mpi.tcl
# Author        : DT-PI
# Creation Date : 2023-03-31
# Last Modified : 2025-09-05
# Version       : v0.9
# Location      : ${COMMON_TCL}/mpi.tcl
#-------------------------------------------------------------------------------
# Description   :
#   This file is an example file. This header is used to track the version and
#   change history of the file.
#-------------------------------------------------------------------------------
# Change Log    :
#   v0.1 [2023-03-31] : iskim1001
#       - Initial Version Release
#   v0.2 [2024-06-03] : iskim1001
#       - pt_sta part modify
#   v0.3 [2024-06-11] : iskim1001
#       - Change log histroy file (rundir.pi.list)
#       - Change date format used in log history
#   v0.4 [2024-11-13] : iskim1001
#       - line 180 Modify
#   v0.5 [2025-03-14] : jblee0513
#       - Add fc_pi part
#   v0.6 [2025-05-27] : jjh8744
#       - updated to automatically create the rundir_pi_list_file using touch if it does not exist
#   v0.7 [2025-07-18] : ljh0914
#       - add FM_ECO Flow
#   v0.8 [2025-08-14] : jblee0513
#       - add fc_syn part
#   v0.9 [2025-09-05] : jaeeun1115
#       - add dc_scan part
#-------------------------------------------------------------------------------
#################################################################################


#####################################
## Procedure
#####################################
proc init_dir { } {

    global PRJ_DESIGN
    global ALL_DESIGN

    global PRJ_DC_SYN
    global PRJ_FC_SYN
    global PRJ_VCLP
    global PRJ_FM_EQ
    global PRJ_FM_ECO
    global PRJ_PT_STA
    global PRJ_PT_GCA
    global PRJ_DC_SCAN
    global PRJ_ATPG
    global PRJ_NC_SIM
    global PRJ_DC_LDRC
    global PRJ_PTPX
    global PRJ_DFT_TESSENT

    global COMMON_IMPL_DIR

    global DIR_NAME

    global TOP_MODULE
    global TOOL
    global description

    #== remove existed files
    foreach file [glob -nocomplain *] {
        if {[file tail $file] eq "makefile" || [file tail $file] eq "con"} { file delete -force $file }
    }
    set dirs "none"

    set DIR_NAME  [exec basename  [pwd] ]
    set RUNDIR    [pwd]
    #== copy
    if {  $DIR_NAME == "dc_syn" || $DIR_NAME == "dc_scan" } {
        set common_dir $PRJ_DC_SYN
        exec cp -rf ${PRJ_DC_SYN}/con ./
        #foreach file [glob -nocomplain -type f ${PRJ_DC_SYN}/con/*] {
        #    file mkdir ./con
        #    set firstIndex [lindex [split [exec basename $file] "."] 0]
        #    if { [lsearch "$PRJ_DESIGN $ALL_DESIGN" $firstIndex] == "-1" || $firstIndex == $TOP_MODULE } {
        #        file copy $file ./con/
        #    }
        #}
    } elseif { $DIR_NAME == "fc_syn" } {
        set common_dir $PRJ_FC_SYN
        exec cp -rf ${PRJ_FC_SYN}/con ./
    } elseif { $DIR_NAME == "vclp" } {
        set dirs "pre post pgnet"
        set common_dir $PRJ_VCLP
    } elseif { $DIR_NAME == "fm_eq" } {
        set dirs "pre/r2n pre/r2n_upf pre/n2n pre/n2n_upf post/n2n post/n2n_upf"
        set common_dir $PRJ_FM_EQ
    } elseif { $DIR_NAME == "fm_eco" } {
        set dirs "rtl_eco netlist_eco"
        set common_dir $PRJ_FM_ECO
    } elseif { $DIR_NAME == "pt_sta" } {
        set dirs "pre post"
        set common_dir $PRJ_PT_STA
    } elseif { $DIR_NAME == "pt_gca" } {
        set dirs "pre post"
        set common_dir $PRJ_PT_GCA
    } elseif { $DIR_NAME == "dc_scan"} {
        set common_dir $PRJ_DC_SCAN
    } elseif { $DIR_NAME == "atpg"} {
        set dirs "pre post"
        set common_dir $PRJ_ATPG
    } elseif { $DIR_NAME == "nc_sim"} {
        set dirs "pre post"
        set common_dir $PRJ_NC_SIM
    } elseif { $DIR_NAME == "dc_ldrc"} {
        set dirs "pre post"
        set common_dir $PRJ_DC_LDRC
    } elseif { $DIR_NAME == "ptpx"} {
        set dirs "pre post"
        set common_dir $PRJ_PTPX
    } elseif { $DIR_NAME == "ndm"} {
        set common_dir $COMMON_IMPL_DIR/common_tcl/NDM_GEN
        exec cp -rf ${common_dir}/con ./
    } elseif { $DIR_NAME == "verdi"} {
        set common_dir $COMMON_IMPL_DIR/common_tcl/verdi
    } else  {
      puts "No matching condition found."
      exit
    }


    if {  $dirs == "none" } {
        file copy -force $common_dir/makefile ./
    } elseif { $DIR_NAME == "pt_sta"  } {
        foreach dir $dirs {
            file mkdir $dir
            file copy  -force $common_dir/makefile  $dir
#            file copy  -force $common_dir/_run_${dir}_sta $dir
            file copy  -force $common_dir/_run_sta.csh $dir
            file copy  -force $common_dir/_run_restore_etc.csh  $dir
        }
    } elseif { $DIR_NAME == "atpg"  } {
        foreach dir $dirs {
            file mkdir $dir
            file copy  -force $common_dir/makefile $dir
            file copy  -force $common_dir/_run_atpg $dir
        }
    } elseif { $DIR_NAME == "ptpx" } {
        foreach dir $dirs {
            file mkdir $dir
            file copy  -force $common_dir/makefile $dir
            file copy  -force $common_dir/user_design_setup.tcl $dir
        }
    } elseif { $DIR_NAME == "pt_gca"  } {
        foreach dir $dirs {
            file mkdir $dir
            file copy  -force $common_dir/makefile $dir
        }
    } elseif { $DIR_NAME == "dft_tessent" } {
        file copy -force $common_dir/* ./
    } elseif { $DIR_NAME == "ndm" } {
        file copy -force $common_dir/makefile ./
    } elseif { $DIR_NAME == "verdi" } {
        file copy -force $common_dir/makefile ./
    } else {
        foreach dir $dirs {
            file mkdir $dir
            file copy  -force $common_dir/makefile $dir
        }
    }
}


#####################################
## Body
#####################################
eval [exec projconf.pl -print -format tcl]

set TOP_MODULE  [lindex [split [exec pwd] "/"] end-1]
set TOOL        [lindex [split [exec pwd] "/"] end]

if { [exec dirname [pwd]] == "${IMPL_DIR}/$env(PROJECT_NAME)/SOC/${TOP_MODULE}" } {
    if { [exec basename  [pwd] ] == "dc_syn" || [exec basename  [pwd] ] == "dc_scan" || [exec basename  [pwd] ] == "fc_syn" } {
    puts "= Notification================================================================================================"
    puts "= Please modify the files within the \"con\" directory according to the design and perform a synthesis        "
    puts "= To import Makefile and con, please input \"y\"                                                              "
    puts "=============================================================================================================="
    } elseif { [exec basename [pwd] ] == "pt_sta" } {
    puts "= Notification================================================================================================"
    puts "= Please be sure to declare the target corner within the run_s before proceeding.                             "
    puts "= To import Makefile and con, please input \"y\"                                                              "
    puts "=============================================================================================================="
    } elseif { [exec basename [pwd] ] == "fc" } {
    set mode fc
    } else {
    puts "= Notification====================================================================="
    puts "= To import Makefile , please input \"y\"                                          "
    puts "==================================================================================="
    }

    if { [exec basename [pwd] ] != "fc" } {
        puts -nonewline "Answer y or n : "
        flush stdout
        gets stdin mode
    }

    switch $mode {
        y   { set mode init_dir ; puts "Starting $mode" }
        fc  { set mode "source $COMMON_IMPL_DIR/common_tcl/mpnr.tcl" ; set fc_pi 1 }
        default { puts "Error: number($mode) is not valid!" ; exit }
    }

    eval $mode
    file mkdir $OUTFD_DIR/LOG
    set rundir_pi_list_file $OUTFD_DIR/LOG/rundir.pi.list
    if { ![file exist $rundir_pi_list_file] } {
        exec touch $rundir_pi_list_file
    }
    set open_file [open $rundir_pi_list_file] ; set check_ex [regexp [exec pwd] [read $open_file]] ; close $open_file
    #241112 Modify exec echo "[exec date "+%y%m%d_%H%M%S"]\t$TOP_MODULE\t[exec pwd]/$DIR_NAME" >> $rundir_pi_list_file
    if { !$check_ex } {exec echo "[exec date "+%y%m%d_%H%M%S"]\t$TOP_MODULE\t[exec pwd]" >> $rundir_pi_list_file}
    if { [file owned $OUTFD_DIR/LOG       ] } { exec chmod 770 $OUTFD_DIR/LOG       }
    if { [file owned $rundir_pi_list_file ] } { exec chmod 660 $rundir_pi_list_file }

} else {
    puts "Error: You should move to ${IMPL_DIR}/<TOP>/SOC/<BLOCK>/<TOOL>"
}
