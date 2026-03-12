################################################################################
# File Name     : lppi_setup.tcl
# Author        : DT-PI
# Creation Date : 2024-02-02
# Last Modified : 2024-06-25
# Version       : v0.4
# Location      : ${PRJ_PT}/design_scripts/run_sta.tcl
#-------------------------------------------------------------------------------
# Description   : Set "link_path_per_instance" by referring to the POWER_DOMAIN_INFO variable defined in sub_hier_inst_info.tcl
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-02-02 ] : jjh8744
# 		- Initial Version Release
# 	v0.2 [2024-05-13 ] : jjh8744
# 		- updated variable ( SORT_BLK_NAME, BLK(POWER_DOMAIN_VOLTAGE_INFO) )
# 	v0.3 [2024-05-24] : iskim1001
#       - ADF Message Rule Change
#       	Before : <ADF_ERROR>: , <ADF_WARN>:  , <ADF_INFO>:
#       	After  : Error_ADF:   , Warning_ADF: , Information_ADF:
# 	v0.4 [2024-06-25] : jjh8744
#       - Remove ${BLK_DOMAIN_INFO} variable
# 	v0.5 [2024-07-03] : jjh8744
#       - Remove source sub_hier_inst_info.tcl
#       - sub_hier_inst_info.tcl file is sourced in run_sta.tcl.
# 	v0.6 [2024-12-19] : jjh8744
#       - Updated to exclude DBs with different core power and VDD.
#-------------------------------------------------------------------------------
# Useage        :
#		pt_shell> source lppi_setup.tcl
#################################################################################

set fname "${STA_SCRIPT_DIR}/sub_hier_inst_info.tcl"
if { [file exist $fname ] } {
	# puts "Information_ADF: source the $fname"
	# source $fname
} else {
	puts "Error_ADF: When is_lppi=1, \"$fname\" file must be sourced."
	exit
}
unset fname

# link_path_per_instance is set only for blocks in the POWER_DOMAIN_INFO variable.
set SORT_BLK_NAME ""

foreach blk $READ_DESIGN {
	if { [info exist ${blk}(POWER_DOMAIN_INFO)] && [set ${blk}(POWER_DOMAIN_INFO)] != "" } {
		set lppi_blk $blk
		set SORT_BLK_NAME [concat $SORT_BLK_NAME $lppi_blk]
	}
}

# Define ${BLK}(POWER_DOMAIN_VOLTAGE_INFO) variable
if { $SORT_BLK_NAME != "" } {
	foreach BLK $SORT_BLK_NAME {
		set ${BLK}(POWER_DOMAIN_VOLTAGE_INFO) ""
		set INFO			[regsub -all "{|}" [set ${BLK}(POWER_DOMAIN_INFO)] ""]
		for {set i 0} { $i < [llength $INFO] } { incr i } {

			set CONTENT [lindex $INFO $i]
			set flag [expr $i%2]
			if { $flag == "0" } {
				set BLK_INST $CONTENT
			} else {
				set BLK_VOLTAGE_INFO [regsub {\.} [format "%.4f" $CONTENT] "p"]
				lappend ${BLK}(POWER_DOMAIN_VOLTAGE_INFO) "$BLK_INST $BLK_VOLTAGE_INFO"
			}
		}
	}

	# Setting link_path_per_instance
	set link_path_per_instance ""

	foreach BLK $SORT_BLK_NAME {
		set INFO			[regsub -all "{|}" [set ${BLK}(POWER_DOMAIN_VOLTAGE_INFO)] ""]
		for {set i 0} { $i < [llength $INFO] } { incr i } {
			set CONTENT [lindex $INFO $i]
			set flag [expr $i%2]
			if { $flag == "0" } {
				set BLK_INST $CONTENT
			} elseif { $flag == "1" } {
				set ${BLK}(LPPI_LIB) "*"

				set BLK_VOLTAGE_INFO $CONTENT
				set LPPI_LIB_CORNER [regsub $CORNER_VOLT $LIB_CORNER $BLK_VOLTAGE_INFO]

				puts ""
	    		puts "#####################################################################"
	    		puts "## HIER_DESIGN        : $BLK"
	    		puts "## SUB_INSTANCE       : $BLK_INST"
	    		puts "## SUB_VOLTAGE_DOMAIN : $BLK_VOLTAGE_INFO"
	    		puts "## SUB_DK_TYPE        : [set ${BLK}(DK_TYPE)]"
	    		puts "## SUB_DK_NAME        : [set ${BLK}(TRACK_FULL)]"
	    		puts "#####################################################################"

				set j 0
				foreach ABS_READ {prim mem ip} {
	    		    switch $ABS_READ {
						"prim"  {  set LIB_FILE "${LIB_DIR}/abs/00_PRIM/${ABS_PRIM_VERSION}/00_DB/${LPPI_LIB_CORNER}.db.abs.list"           }
						"mem"   {  set LIB_FILE "${LIB_DIR}/abs/01_MEM/${BLK}/${BLK_ABS_MEM_VERSION}/00_DB/${LPPI_LIB_CORNER}.db.abs.list"  }
						"ip"    {  set LIB_FILE "${LIB_DIR}/abs/02_IP/${BLK}/${BLK_ABS_IP_VERSION}/00_DB/${LPPI_LIB_CORNER}.db.abs.list"    }
						default {  set LIB_FILE  "unknow variable ABS_READS"   }
	    		    }

	    		    if { [file exists [which $LIB_FILE]] } {
	    		        set Fin [open $LIB_FILE r ]
	    		        while { [gets $Fin line] != -1 } {
	    		            if { [regexp {^#} $line] || ![regexp {\w+} $line] } { continue }
	    		            set lib_name [lindex [split $line "/"] end ]

	    		            # Only prim
	    		            if { $ABS_READ == "prim" } {
	    		                if { [string match "*[set ${BLK}(TRACK_FULL)]*" ${lib_name}] } {
									if { [regexp {pmk.*?(\d+p\d+v)_(\d+p\d+v)} ${lib_name} match other vdd] } {
										regsub -nocase "v" [regsub -nocase "p" $vdd "."] "" vdd
										regsub -nocase "v" [regsub -nocase "p" $BLK_VOLTAGE_INFO "."] "" BLK_VOLTAGE_INFO_temp
										if { [expr $vdd != $BLK_VOLTAGE_INFO_temp] } {
											continue
										}
									}
									incr j
	    		                	puts "${BLK}(LPPI_LIB) ($j) : $line"
	    		                	set ${BLK}(LPPI_LIB) [lappend ${BLK}(LPPI_LIB) $line]
	    		                }
	    		            # Only mem, ip
	    		            } else {
								incr j
	    		                puts "${BLK}(LPPI_LIB) ($j) : $line"
	    		                set ${BLK}(LPPI_LIB) [lappend ${BLK}(LPPI_LIB) $line]
	    		            }
	    		        } ; close $Fin
	    		    }
	    		}
				puts ""
				lappend link_path_per_instance [list $BLK_INST [set ${BLK}(LPPI_LIB)]]
			}
		}
	}
}
