###################################################################################################
# File               : 1_lib_setup.tcl                                                            #
# Author             : ADT-DT (jblee)                                                             #
# Description        : lib setup (ndm, nlib)                                                      #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################

####################################################################################################
# NDM LIB Setup
####################################################################################################
set  NDM_REFERENCE_LIB_DIRS ""

if {${USER_NDM_REFERENCE_LIB} == "" } {
    foreach ABS_READ ${ABS_READS} {
        switch $ABS_READ {
            "prim"  {  set NDM_FILE "${LIB_DIR}/abs/00_PRIM/${ABS_PRIM_VERSION}/10_NDM/ndm.abs.list"             ; set i 0  }
            "mem"   {  set NDM_FILE "${LIB_DIR}/abs/01_MEM/${TOP_DESIGN}/${ABS_MEM_VERSION}/10_NDM/ndm.abs.list" ; set i 0  }
            "ip"    {  set NDM_FILE "${LIB_DIR}/abs/02_IP/${TOP_DESIGN}/${ABS_IP_VERSION}/10_NDM/ndm.abs.list"   ; set i 0  }
            default {  set NDM_FILE "unknow variable ABS_READS"   }
        }
        puts ""
        puts "#####################################################################"
        puts "## DESIGN   : $DESIGN"
        puts "## ABS_READ : $ABS_READ"
        puts "## DK_TYPE  : $DK_TYPE"
        puts "## NDM_FILE : $NDM_FILE"
        puts "#####################################################################"
        puts ""

        if {[file exists [which $NDM_FILE ]]} {
            set Fin [open $NDM_FILE r]
            while { [ gets $Fin line ] != -1 } {
                if { [regexp {^#} $line] || ![regexp {\w+} $line] } { continue } ; #Exclude comments or leading blanks
                incr i
                puts "LINK_NDM($i) : $line"
                set NDM_REFERENCE_LIB_DIRS [concat $NDM_REFERENCE_LIB_DIRS $line]
            } ;close $Fin ;# while end
        }
    }
} else {
    set NDM_REFERENCE_LIB_DIRS ${USER_NDM_REFERENCE_LIB}
}

#################################################################################
# Extract sub-block NLIB paths/names and update NDM_REFERENCE_LIB_DIRS
#################################################################################
if { [info exist HIER_DESIGN] && $HIER_DESIGN != "" } {
	set Black_box " $HIER_DESIGN "
}

if { [info exist IMPL_BLK_INFO] && $IMPL_BLK_INFO != "NONE" && $is_flat } {

	# Initialize and collect extracted sub-block NLIB information
	set ALL_SUB_NLIB      ""
	set ALL_SUB_NLIB_NAME ""
	foreach NLIB $IMPL_BLK_NLIB {
		set SUB_BLK_NAME          [lindex $NLIB 0]
		set ${SUB_BLK_NAME}_NLIB  [lindex $NLIB 1]

		if { [set ${SUB_BLK_NAME}_NLIB] == "AUTO" } {
			set BLK_INDB_VER          [ set ${SUB_BLK_NAME}(INDB_VER) ]
	    	set BLK_NET_REVISION_SYN  [ set ${SUB_BLK_NAME}(NET_REVISION_SYN) ]
			set ${SUB_BLK_NAME}_NLIB "${OUTFD_DIR}/${SUB_BLK_NAME}/$BLK_INDB_VER/fc_syn/$BLK_NET_REVISION_SYN/${OUTPUT_DIR}/${SUB_BLK_NAME}.nlib"
			set DESIGN_TAG "(AUTO_DETECT)"
		} else {
			set DESIGN_TAG "(USER_DEFINE)"
		}

		if { [file exist [set ${SUB_BLK_NAME}_NLIB]] } {
			echo "Information_ADF : ${SUB_BLK_NAME} -> [set ${SUB_BLK_NAME}_NLIB]"
			# Updating info.rpt
		    redirect -tee -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "\n ${SUB_BLK_NAME}"}
		    redirect -tee -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "    NLIB : [set ${SUB_BLK_NAME}_NLIB] ${DESIGN_TAG}"}

			lappend ALL_SUB_NLIB      [set ${SUB_BLK_NAME}_NLIB]
			set SUB_BLK_NLIB_NAME     [lindex [split [set ${SUB_BLK_NAME}_NLIB] "/"] end]
			lappend ALL_SUB_NLIB_NAME $SUB_BLK_NLIB_NAME


		} else {
			echo "Error_ADF : ${SUB_BLK_NAME} -> [set ${SUB_BLK_NAME}_NLIB] does not exist"
		    redirect -tee -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "\n ${SUB_BLK_NAME}"}
		    redirect -tee -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "    BlackBox : [set ${SUB_BLK_NAME}_NLIB] does not exist ${DESIGN_TAG}"}
		}
		regsub -all " ${SUB_BLK_NAME} " $Black_box " " Black_box
	}

	set ALL_SUB_NLIB      [lsort  -unique $ALL_SUB_NLIB]
	set ALL_SUB_NLIB_NAME [lsort  -unique $ALL_SUB_NLIB_NAME]

	# Append sub-block NLIB to the NDM_REFERENCE_LIB_DIRS variable
	set  NDM_REFERENCE_LIB_DIRS       [lsort -unique "$NDM_REFERENCE_LIB_DIRS $ALL_SUB_NLIB"]

}

if {[info exists Black_box] && [lindex $Black_box 0] != "NONE"} {
	foreach blk_name $Black_box {
		redirect -tee -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "\n ${blk_name}"}
		redirect -tee -a ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt {echo "    BlackBox : No information"}
	}
}


#################################################################################
# Library Setup using information described in user_design_setup.tcl
#################################################################################
# Create and open NDM

set NDM_DESIGN_LIB "${TOP_DESIGN}.nlib" ; # NDM library name

if { $REUSE_ELAB == "true" } {
    if {[file exists $REUSE_ELAB_NLIB]} {
        if {[file exists ${OUTPUT_DIR}/$NDM_DESIGN_LIB]} {sh mv ${OUTPUT_DIR}/$NDM_DESIGN_LIB ${OUTPUT_DIR}/${NDM_DESIGN_LIB}_${old}}
        copy_lib -from $REUSE_ELAB_NLIB -to ${OUTPUT_DIR}/$NDM_DESIGN_LIB
        open_lib ${OUTPUT_DIR}/${NDM_DESIGN_LIB}

        set_ref_libs -clear
        set_ref_libs -ref_libs $NDM_REFERENCE_LIB_DIRS
    } else {
        puts "Error_ADF: $REUSE_ELAB_NLIB not exists. Please check reuse elab nlib or re-generate elab nlib"
        exit
    }
} else {
    if {![info exist DESIGN_LIBRARY_SCALE_FACTOR] || $DESIGN_LIBRARY_SCALE_FACTOR == ""} {
        set value [exec cat $TECH_FILE | grep lengthPrecision]
        regexp {lengthPrecision\s*=\s*(\d+)} $value match DESIGN_LIBRARY_SCALE_FACTOR
        puts $DESIGN_LIBRARY_SCALE_FACTOR
    }
    
    if {${REUSE_NDM} && [file exist ${OUTPUT_DIR}/${NDM_DESIGN_LIB}]} {
        open_lib ${OUTPUT_DIR}/${NDM_DESIGN_LIB}
        remove_blocks [get_blocks -all] -force
    } else {
        if {[file exists ${OUTPUT_DIR}/$NDM_DESIGN_LIB]} { sh mv ${OUTPUT_DIR}/$NDM_DESIGN_LIB ${OUTPUT_DIR}/${NDM_DESIGN_LIB}_${old} }
        create_lib ${OUTPUT_DIR}/$NDM_DESIGN_LIB -technology $TECH_FILE -ref_libs $NDM_REFERENCE_LIB_DIRS -scale_factor $DESIGN_LIBRARY_SCALE_FACTOR
    }
}

# Loads libraries contained in the sub-block NLIB
if { [info exist IMPL_BLK_INFO] && $IMPL_BLK_INFO != "NONE" && $is_flat } {
	puts "# Information_ADF: Loads libraries contained in the sub-block NLIB"
	set_attribute -objects [get_lib "${ALL_SUB_NLIB_NAME}"] -name use_hier_ref_libs -value true
}

## Change symmetry attribute
set_attribute -objects [get_site_def] -name symmetry -value {Y}

#################################################################################
# Check Library
#################################################################################
redirect -file ${REPORT_DIR}/${TOP_DESIGN}.check_library.rpt {report_ref_libs -library $NDM_DESIGN_LIB}
