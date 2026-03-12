################################################################################
# File Name     : memory_case_check.tcl
# Author        : jjh8744
# Last Modified : 2025-09-09
# Version       : v0.4
# Location      : execute file
#-------------------------------------------------------------------------------
# Description   :
# 	Check case_value based on memory_case_check.info file
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2023-11-06] : jjh8744
#       - Initial Version Release
# 	v0.2 [2025-02-04] : iskim1001
#       - Update
# 	v0.3 [2025-02-18] : iskim1001
#       - Added logic to compare the memory in the current design with
#         the memory described in memory_case_check.info
# 	v0.4 [2025-09-09] : jaeeun1115
#       - typ_volt_type : OD -> ${typ_volt_type}
#-------------------------------------------------------------------------------
# Usage        :
#		1. Write the memory_case_value.info file in the format.
#			(Written by the Memory Generation manager, and double-checked by PM or PI leader.)
#		2. File Sourcing
#			pt_shell > source memory_case_cehck.tcl
#		3. Report Check
#			cmd > gvim report/memory_case_check.rpt
#################################################################################
puts "Information_ADF: memory_case_check START"


#################################################################
# PROC Define
#################################################################
proc get_typ_volt_value {typ_volt_type val_list} {
    array set volt_map {SOD 0 OD 1 ND 2 UD 3 SUD 4}
    return [lindex $val_list $volt_map($typ_volt_type)]
}

proc FILE_CHECK { FILE } {
    return [file exists ${FILE}]
}

proc debug_log {level category message} {
    global debug_file first_run DEBUG
	set debug_file  "./debug_report.log"
	if { $DEBUG } {
    	# Open file in 'w' mode for the first run, then 'a' mode for subsequent logs
    	if {$first_run} {
    	    set mode "w" ;set first_run 0  ;# Set flag to indicate first run is done
    	} else {
    	    set mode "a"
    	}

    	# Open the file in the determined mode
    	set fp [open $debug_file $mode]

    	# Generate timestamp
    	set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]

    	# Format level and category with fixed width
    	set level_fmt [format "%-7s"     "\[$level\]"]      ;# Fix width for Level
    	set category_fmt [format "%-12s" "\[$category\]"]  ;# Fix width for Category

    	# Default log format: [Timestamp] [LEVEL] [CATEGORY] Message
    	set log_msg "\[$timestamp\] $level_fmt $category_fmt $message"
    	# Print to terminal
    	puts $log_msg

    	# Save to file
    	puts $fp $log_msg
    	flush $fp  ;# Ensure data is written immediately

    	# Close the file after each log entry to ensure correct mode switching
    	close $fp
	}
}

proc process_ref_bit  {} {
	global ref_bit
	global check_result
	global check_mem_pin
	global mem DEBUG
	global typ_volt_type
	global temp_output0
	global FO_output0

	if { $ref_bit == "" } {
		set ref_bit "No info"
		set user_set_value [get_attr [get_pins $check_mem_pin] case_value]
		if { $user_set_value == "" } {
			set user_set_value "No"
		}
	} else {
		set user_set_value [get_attr [get_pins $check_mem_pin] case_value]
		if { $user_set_value == "" } {
			set user_set_value "No"
		}
	}
		  if { $ref_bit == "No info"       } { set check_result $ref_bit
	} elseif { $ref_bit != $user_set_value } { set check_result "*** FAIL ***"
	} elseif { $ref_bit == $user_set_value } { set check_result "PASS"
	} else                                   { set check_result "other case"
	}

	set temp_line " $check_result , $ref_bit : $user_set_value , [get_object_name $check_mem_pin] , [get_attr [get_cells $mem] ref_name] , $typ_volt_type "
	debug_log "DEBUG" "LINE" "\t$temp_line"
	puts $FO_output0 [format "\t %-12s %-10s : %s" $check_result "( $ref_bit : $user_set_value )" [get_object_name $check_mem_pin] ]
	set ref_bit        ""
	set user_set_value ""
}


#################################################################
# Debug Setting
#################################################################
# Processing debug Message & Define the debug report file
set DEBUG       0
set debug_file  ""
set first_run   1  ;# Flag to check if it's the first execution


#################################################################
# Setting File
#################################################################
set scr_version v0.3
set MEMORY_CASE_CHECK_INFO_FILE ${STA_SCRIPT_DIR}/memory_case_check.info
set MEMORY_CASE_CHECK_REPORT        ${REPORT_DIR}/memory_case_check.rpt
if { $DEBUG } {
	set MEMORY_CASE_CHECK_INFO_FILE ./memory_case_check.info
	set MEMORY_CASE_CHECK_REPORT    ./memory_case_check.rpt
}
set temp_header                 .temp.header
set temp_output0                .temp.output0
set temp_output1                .temp.output1




#################################################################
# Array Define
#################################################################
array unset MEMORY_INFO
array unset MEMORY
array set MEMORY_INFO ""
array set MEMORY      ""

#################################################################
# Convert memory_case_check.info --> MEMORY_INFO Array
#################################################################
debug_log "CREATE" "ARRAY" "MEMORY_INFO START"
if { [FILE_CHECK $MEMORY_CASE_CHECK_INFO_FILE] } {
    set FI [open $MEMORY_CASE_CHECK_INFO_FILE r]
    while {[gets $FI line] >= 0} {
        if { ![regexp {\w+} $line] || [regexp {^#} $line] } { continue }
        set ref_name [lindex $line 0]
        set port     [lindex $line 1]
        set value    [lrange $line 2 end]
        set MEMORY_INFO(${ref_name},${port}) $value
		debug_log "CREATE" "ARRAY" "\tMEMORY_INFO(${ref_name},${port}) = $value"
    }
    close $FI
} else {
    puts "Error: File Not Exists --> $MEMORY_CASE_CHECK_INFO_FILE"
    return
}
debug_log "CREATE" "ARRAY" "MEMORY_INFO END"


#################################################################
# iskim Test
#################################################################
if { [file exists $temp_header  ] } { file delete $temp_header  }; set FO_header  [open $temp_header   w  ]
if { [file exists $temp_output0 ] } { file delete $temp_output0 }; set FO_output0 [open $temp_output0  w  ]
if { [file exists $temp_output1 ] } { file delete $temp_output1 }; set FO_output1 [open $temp_output1  w  ]
if { $DEBUG } {
	source ./add_prj_typ_volt.tcl__TSABI
}


#################################################################
# Print Header
#################################################################
puts $FO_header "********************************************"
puts $FO_header "Report      : Memory Case Value Check"
puts $FO_header "Design      : ${DESIGN}"
puts $FO_header "User        : [getenv USER]"
puts $FO_header "Version     : ${sh_product_version}"
puts $FO_header "Date        : [exec date]"
puts $FO_header "Scr Version : ${scr_version}"
puts $FO_header "Input File  : ${MEMORY_CASE_CHECK_INFO_FILE}"
puts $FO_header "********************************************"
puts $FO_header "** R : Reference case value"
puts $FO_header "** S : set_case_analysis Value"
puts $FO_header "** typ_volt_type : ${typ_volt_type}"
puts $FO_header ""


#################################################################
# Compare the existing Memory based on the current Design
# with the Memory in memory_case_check.info and allocate it to the MEMORY Array.
#################################################################
set ALL_MEM     [get_cells -quiet -hierarchical -filter "is_memory_cell == true && ref_name !~ sf_otp*"]
set ALL_MEM_REF [lsort -u [get_attr [get_cell  $ALL_MEM] ref_name ] ]
set ALL_MEM_CNT [llength $ALL_MEM_REF]
set unmatched_list {}
set matched_list   {}
debug_log "CREATE" "ARRAY" "MEMORY START"
set MEMORY_INFO_keys [array names MEMORY_INFO]
set CASE_CHECK 0
if { $ALL_MEM_CNT > 0 } {
	set CASE_CHECK 1
	# Design Memory vs memory_case_check Memory
	foreach MEM_REF $ALL_MEM_REF {
	    set is_matched 0
	    foreach key $MEMORY_INFO_keys {
	 		set ref [lindex [split $key ","] 0]
	 		set port [lindex [split $key ","] 1]
	        if {[string match $ref $MEM_REF]} {
				set MEMORY($MEM_REF,$port) [set MEMORY_INFO($key)]
				debug_log "CREATE" "ARRAY" "\tMEMORY($MEM_REF,$port) = $MEMORY_INFO($key)"
				lappend matched_list $MEM_REF
	            set is_matched 1
	        }
	    }
	    if {!$is_matched} {
	        lappend unmatched_list $MEM_REF
	    }
	}
}
debug_log "CREATE" "ARRAY" "MEMORY END"

#################################################################
# debug: matched_list & unmatched_list print
#################################################################
set matched_list   [ lsort -u $matched_list   ]
set unmatched_list [ lsort -u $unmatched_list ]
if { $DEBUG } {
	debug_log "CHECK" "VARIABLE" "matched_list   = $matched_list"
	debug_log "CHECK" "VARIABLE" "unmatched_list = $unmatched_list"
}


#################################################################
# Main Program
#################################################################
if { !$CASE_CHECK } {
	# There is no memory in the current design.
	debug_log "CHECK" "VARIABLE" "\nCASE_CHECK = $CASE_CHECK"
	puts "Information_ADF: There is no memory in the current design."
	puts "Information_ADF: There is no memory in the current design."
	puts "Information_ADF: There is no memory in the current design."
	puts $FO_output0 "There is no memory in the current design."
	puts $FO_output0 "There is no memory in the current design."
	puts $FO_output0 "There is no memory in the current design."
} else {
	foreach MEM_REF $ALL_MEM_REF {
		set found_keys [lsearch -glob [array names MEMORY] "${MEM_REF},*"]
		debug_log "CHECK" "VARIABLE" "\nCASE_CHECK = $CASE_CHECK"
		puts [format "%-16s %-30s %-s" "Information_ADF:" "$MEM_REF" "Memory Case Check in Progress"]
		puts $FO_output0 "\n${MEM_REF}"
		puts $FO_output0 [format "#\t %-12s %-10s : %s" "PASS or FAIL" "( R : S )" "Instance Pin"]

		if { $found_keys != -1 } {
			debug_log "CHECK" "VARIABLE" "found_keys = $found_keys"
			debug_log "CHECK" "MEMORY"   "$MEM_REF exists"

			foreach key [array names MEMORY] {
				if { [string match "${MEM_REF}*" $key ]} {
					set ref  [lindex [split $key ","] 0]
					set port [lindex [split $key ","] 1]
					set Cval [get_typ_volt_value $typ_volt_type $MEMORY($key)]
					debug_log "DEBUG" "VARIABLE" "KEY= $key / VAL_LIST=$MEMORY($key) / SEL_VAL=$Cval"

					if { [regexp "'b" $Cval] } {
						set ref_bit_cnt			 [lindex [split $Cval "'"] 0]
						set ref_bit_info    	 [string range [lindex [split $Cval "'"] 1] 1 end]
						set binary_bit_info      $ref_bit_info
					} else   {
						debug_log "DEBUG" "ERROR"   "\tMemory EMA check Error"
						debug_log "DEBUG" "ERROR"   "\tCheck memory bit info in reference file. (Need to set 'b, ex) 2'b10)"
					}


					foreach_in_collection mem [sort_collection -dict  [get_cells -h * -f "ref_name == $MEM_REF"] full_name]  {
						set mem_check_pin [get_pins -quiet -of_objects [get_cells $mem] -filter "lib_pin_name == ${port}"]
						set mem_bit_cnt   [sizeof_collection $mem_check_pin]
						if { $mem_bit_cnt != "1"} {
							set mem_check_pin [get_pins -quiet -of_objects [get_cells $mem] -filter "lib_pin_name =~ ${port}\[*"]
							set mem_bit_cnt   [sizeof_collection $mem_check_pin]
						}

						#-------------------------------------------
						# 1 bit
						#-------------------------------------------
						if { $mem_bit_cnt == "1" } {
							set check_mem_pin	[get_pins $mem_check_pin -filter "lib_pin_name =~ ${port}"]
							set ref_bit			[string index $binary_bit_info end]
							process_ref_bit


						#-------------------------------------------
						# 2 bit or more
						#-------------------------------------------
						} else {
							for {set i [expr $mem_bit_cnt - 1]} {$i >=0} {incr i -1 } {
								set check_mem_pin	[get_pins $mem_check_pin -filter "lib_pin_name =~ ${port}\[${i}\]"]
								set ref_bit			[string index $binary_bit_info end-${i}]
								process_ref_bit
							}
						}
					}
				}
			}
		} else {
			debug_log "CHECK" "VARIABLE" "found_keys = $found_keys ( If no item is found, -1 is returned. )"
			debug_log "DEBUG" "MESSAGE"  "\tNot Exists Memory --> $MEM_REF"
			debug_log "DEBUG" "MESSAGE"  "\tThere is no matching line for <$MEM_REF> Memory in the memory_case_check.info file."
			debug_log "DEBUG" "MESSAGE"  "\tIt exists in Design but not in memory_case_check.info file."
			debug_log "DEBUG" "MESSAGE"  "\tPlease check the memory_case_check.info file."
			puts $FO_output0 "Error_ADF: There is no matching line for <$MEM_REF> Memory in the memory_case_check.info file."
			puts $FO_output0 "Error_ADF: It exists in Design but not in memory_case_check.info file."
			puts $FO_output0 "Error_ADF: Please check the memory_case_check.info file."
		}
	}
}


close $FO_header
close $FO_output0
close $FO_output1

exec cat $temp_header $temp_output0    > ${MEMORY_CASE_CHECK_REPORT}

file delete $temp_header
file delete $temp_output0
file delete $temp_output1
puts "Information_ADF: memory_case_check END"
