


set FILE_A ${LOG_DIR}/set_ocv_margin.log
set FILE_B ${LOG_DIR}/set_ocv_margin.log__LIB_CELL_detail
set FILE_C ${LOG_DIR}/set_ocv_margin.${CORNER}.log

if { [file exists $FILE_A ] } { puts "Information_ADF: File Found --> $FILE_A" } else { puts "Error_ADF: File Not Found --> $FILE_A"; exit}
if { [file exists $FILE_B ] } { puts "Information_ADF: File Found --> $FILE_B" } else { puts "Error_ADF: File Not Found --> $FILE_B"; exit}

set FI_A [open $FILE_A "r"]
set FI_B [open $FILE_B "r"]
set FO_C [open $FILE_C "w"]

# Read FILE_B -> Get Data -> write FILE_C
puts $FO_C "# Get data from file $FILE_B "
while {[gets $FI_B line ] >= 0 } {
	if { [regexp {^set} $line ] } {
		puts $FO_C $line
	}
}
puts $FO_C "\n\n"
close $FI_B

# Read FILE_A -> Get Data -> Write FILE_C
puts $FO_C "# Get data from file $FILE_A "
while {[gets $FI_A line] >= 0 } {
	if { [regexp {^\s+set target_lib_cells} $line ] } { puts $FO_C [string trimleft $line] }
	if { [regexp {^\s+set_timing_derate}    $line ] } { puts $FO_C [string trimleft $line] }
    if { [regexp {\*\* SEC_INFO: \(!\) }    $line ] } { break  } ;# Example Messge Skip ...
}
puts $FO_C "\n\n"
close $FI_A
close $FO_C
