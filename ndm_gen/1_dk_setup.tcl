###################################################################################################
# File               : 1_dk_setup.tcl                                                             #
# Author             : ADT-DT (bmkim)                                                             #
# Description        : dk setup (db,lef)                                                          #
# Usage              :                                                                            #
# Init Release Date  : 2025.06.04                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.06.04 - first released                                                             #
#         2025.08.19 - Remove the step that splits the DB list based on scenario                  #
#         2025.09.03 - Setting DB list based on all scenario                                      #
###################################################################################################

####################################################################################################
# LIBRARY_SETUP START
####################################################################################################
if {[file exists ${LOG_DIR}/block_abs_list.csv ]} {
    sh rm -v ${LOG_DIR}/block_abs_list.csv
}

source -e -v ${PRJ_TOOLS_DIR}/sdc/add_prj_lib_option.tcl

set LINK_LIBRARY_FILES  ""
set tmp_LINK_LIBRARY_FILES ""


puts "#########################################################################"
puts "## File : [info script]"
puts "#########################################################################"
if {[file exists $USER_LIB_FILE]} {
    puts ""
    puts "#####################################################################"
    puts "## USER LIB_FILE : $USER_LIB_FILE"
    puts "#####################################################################"
    puts ""
    set i 0
    set Fin [open $USER_LIB_FILE r ]
    while { [gets $Fin line] != -1 } { 
        if { [regexp {^#} $line ] || ![regexp {\w+} $line] } { continue }
        incr i
        puts "LINK_LIB($i) : $line"
        set LINK_LIBRARY_FILES [concat $LINK_LIBRARY_FILES $line]
    }
    close $Fin
         
} else {
    foreach BLK ${READ_DESIGN} {
        set BLK_DK_TYPE          [ set ${BLK}(DK_TYPE) ]
        set BLK_ABS_MEM_VERSION  [ set ${BLK}(ABS_MEM_VERSION) ]
        set BLK_ABS_IP_VERSION   [ set ${BLK}(ABS_IP_VERSION)  ]
        set BLK_TRACK_FULL       [ set ${BLK}(TRACK_FULL)     ]

        foreach ABS_READ ${ABS_READS} {
            switch $ABS_READ {
                "prim"  {  set  LIB_PATH  "${LIB_DIR}/abs/00_PRIM/${ABS_PRIM_VERSION}"     }
                "mem"   {  set  LIB_PATH  "${LIB_DIR}/abs/01_MEM/${BLK}/${BLK_ABS_MEM_VERSION}" }
                "ip"    {  set  LIB_PATH  "${LIB_DIR}/abs/02_IP/${BLK}/${BLK_ABS_IP_VERSION}"}
                default {  set  LIB_PATH  "unknow variable ABS_READS"   }
            }

            if {[info exists USER_SCENARIO_NAMES] && $USER_SCENARIO_NAMES != ""} {
                set SCENARIO_NAMES $USER_SCENARIO_NAMES
            } else {
                if {![file exists ${LIB_PATH}/00_DB]} {
                    puts ""
                    puts "#####################################################################"
                    puts "Warning_ADF : Path $LIB_PATH is not exists"
                    puts "Warning_ADF : Path $LIB_PATH is not exists"
                    puts "Warning_ADF : Path $LIB_PATH is not exists"
                    puts "#####################################################################"
                    puts ""
                    continue
                }
                set SCENARIO_NAMES ""
                set FL [ls -f ${LIB_PATH}/00_DB/*.list]
                foreach fl $FL {
                    set file_name [lindex [split $fl "/"] end]
                    set file_scn  [lindex [split $file_name "."] 0]
                    set SCENARIO_NAMES [concat $SCENARIO_NAMES $file_scn]
                }
            }

            foreach SCN $SCENARIO_NAMES {
                switch $ABS_READ {
                    "prim"  {  set  LIB_FILE  "${LIB_DIR}/abs/00_PRIM/${ABS_PRIM_VERSION}/00_DB/${SCN}.db.abs.list"      ; set i 0  }
                    "mem"   {  set  LIB_FILE  "${LIB_DIR}/abs/01_MEM/${BLK}/${BLK_ABS_MEM_VERSION}/00_DB/${SCN}.db.abs.list" ; set i 0  }
                    "ip"    {  set  LIB_FILE  "${LIB_DIR}/abs/02_IP/${BLK}/${BLK_ABS_IP_VERSION}/00_DB/${SCN}.db.abs.list"   ; set i 0  }
                    default {  set  LIB_FILE  "unknow variable ABS_READS"   }
                }
                puts ""
                puts "#####################################################################"
                puts "## DESIGN   : $BLK"
                puts "## ABS_READ : $ABS_READ"
                puts "## DK_TYPE  : $BLK_DK_TYPE"
                puts "## LIB_FILE : $LIB_FILE"
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
                                    redirect -append ${LOG_DIR}/block_abs_list.csv { puts "${BLK},${ABS_PRIM_VERSION},PRIM,${lib_name}"}
                                    set LINK_LIBRARY_FILES [concat $LINK_LIBRARY_FILES $line]
                                }
                            }
                        # Only mem ip
                        } elseif { $ABS_READ == "mem" } {
                            incr i
                            puts "LINK_LIB($i) : $line"
                            set LINK_LIBRARY_FILES [concat $LINK_LIBRARY_FILES $line]
                            redirect -append ${LOG_DIR}/block_abs_list.csv {puts "${BLK},${BLK_ABS_MEM_VERSION},MEM,${lib_name}"}

                        } elseif { $ABS_READ == "ip" } {
                            incr i
                            puts "LINK_LIB($i) : $line"
                            set LINK_LIBRARY_FILES [concat $LINK_LIBRARY_FILES $line]
                            redirect -append ${LOG_DIR}/block_abs_list.csv {puts "${BLK},${BLK_ABS_IP_VERSION},IP,${lib_name}"}

                        }
    
                    } ;close $Fin ;# while end
                } 
            }
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

########################################################################################
## LEF_FILES
########################################################################################
set LEF_FILES ""
if {[file exists $USER_LEF_FILE]} {
    puts ""
    puts "#####################################################################"
    puts "## USER LEF_FILE : $USER_LEF_FILE"
    puts "#####################################################################"
    puts ""
    set i 0
    set Fin [open $USER_LEF_FILE r ]
    while { [gets $Fin line] != -1 } { 
        if { [regexp {^#} $line ] || ![regexp {\w+} $line] } { continue }
        incr i
        puts "LINK_LIB($i) : $line"
        set LEF_FILES [concat $LEF_FILES $line]
    } 
    close $Fin
} else {
    foreach BLK ${READ_DESIGN} {
        set BLK_DK_TYPE          [ set ${BLK}(DK_TYPE) ]
        set BLK_ABS_MEM_VERSION  [ set ${BLK}(ABS_MEM_VERSION) ]
        set BLK_ABS_IP_VERSION   [ set ${BLK}(ABS_IP_VERSION)  ]
        set BLK_TRACK_FULL       [ set ${BLK}(TRACK_FULL)      ]
    
        foreach ABS_READ ${ABS_READS} {
            switch $ABS_READ {
                "prim"  {  set  LEF_FILE  "$LIB_DIR/abs/00_PRIM/$ABS_PRIM_VERSION/02_LEF/lef.abs.list"     ; set i 0  }
                "mem"   {  set  LEF_FILE  "${LIB_DIR}/abs/01_MEM/${BLK}/${BLK_ABS_MEM_VERSION}/02_LEF/lef.abs.list" ; set i 0  }
                "ip"    {  set  LEF_FILE  "${LIB_DIR}/abs/02_IP/${BLK}/${BLK_ABS_IP_VERSION}/02_LEF/lef.abs.list"   ; set i 0  }
                default {  set  LEF_FILE  "unknow variable ABS_READS"   }
            }
            puts ""
            puts "#####################################################################"
            puts "## DESIGN   : $BLK"
            puts "## ABS_READ : $ABS_READ"
            puts "## DK_TYPE  : $BLK_DK_TYPE"
            puts "## LEF_FILE : $LEF_FILE"
            puts "#####################################################################"
            puts ""
    
            if {[file exists [which $LEF_FILE ]]} {
                set Fin [open $LEF_FILE r]
                while { [ gets $Fin line ] != -1 } {
                    if { [regexp {^#} $line] || ![regexp {\w+} $line] } { continue }
    
                    set lef_name [lindex [split $line "/"] end]
                    set lef_dir  [regsub "\/$lef_name" $line ""]
    
                    #Only Prim
                    if { $ABS_READ == "prim" } {
                        foreach blk_track_full $BLK_TRACK_FULL {
                            if { [string match "*${blk_track_full}*${lef_name}*" $line] } {
                                incr i
                                puts "LEF($i) : $line"
                                set LEF_FILES [concat $LEF_FILES $line]
                            }
                        }
                    # Only mem ip
                    } elseif { $ABS_READ == "mem" } {
                        incr i
                        puts "LEF_FILE($i) : $line"
                        set LEF_FILES [concat $LEF_FILES $line]
                    } elseif { $ABS_READ == "ip" } {
                        incr i
                        puts "LEF_FILE($i) : $line"
                        set LEF_FILES [concat $LEF_FILES $line]
                    }

    
                } ;close $Fin ;# while end
            } 
        }
    }
}
set LEF_FILES_org $LEF_FILES
set LEF_FILES ""

foreach li $LEF_FILES_org {
    if {[lsearch $LEF_FILES $li] == -1} {
        lappend LEF_FILES $li
    }
}
unset LEF_FILES_org

####################################################################################################
# DK SETUP LOG
####################################################################################################
# TARGET DB Log
set filename "${LOG_DIR}/block_abs_list.log"
set file [open $filename "w"]
puts $file "# LIST DB LIST"
puts $file [join [split $LINK_LIBRARY_FILES ] "\n"]
puts $file ""
# TARGET DB Log
puts $file "# LIST LEF LIST"
puts $file [join [split $LEF_FILES ] "\n"]
close $file
