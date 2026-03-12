#!/bin/tclsh
# mdft.tcl --
# Author: kykim
#	This file is for seting up user workspace "dc_scan"
#
# Revision History
# 0.1
#	First released

# 01.	Set Environment Variables
# 01.1.

# 01.2.	Scan Step Information
set steps {all 01.insertion 02.atpg 03.sim}
# 02.	Parsing Project Configuration
eval [exec projconf.pl -print -format tcl]
set TOP_MODULE	[lindex [split [exec pwd] "/"] end-1]
set TOOL		[lindex [split [exec pwd] "/"] end]

# 03.	Setup Directories and Basic Files
if { [pwd] == "${IMPL_DIR}/$env(PROJECT_NAME)/SOC/${TOP_MODULE}/dc_scan" } {
	puts "$steps all"
	puts -nonewline "make what? all, 1, 2, or 3. > "
	flush stdout
	gets stdin targets
	if { $targets == "all" || $targets == "ALL" } {
		set targets ""
		for { set i 1 } { $i < [ llength $steps] } { incr i } {
			lappend targets $i
		}
	} elseif { 0 < $targets && $targets < [ llength $steps ] } {
	} else {
		puts "Invalid input. Please enter 'all' or a number less than [llength $steps]."
		exit 1
	}
	foreach target $targets {
		if { [file exists [lindex $steps $target] ] } {
			puts "CAUTION! [lindex $steps $target] is exists."
			puts "Are you sure you want to overwite it?(y/n)"
			gets stdin userinput
			if { $userinput != "y" } {
				puts "Then, create a backup or delete it and try again."
				exit 1
			}
		}
		file delete -force ./[lindex $steps $target]
		file copy -force ${PRJ_DC_SCAN}/[lindex $steps $target] .
	}
} else {
	puts "This command is for 'dc_scan' directory."
	puts "Please use command 'goscan' and execute this script in 'dc_scan' directory"
}
