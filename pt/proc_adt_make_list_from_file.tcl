#################################################################################################
##                                                                                             ##
## Title                : adt_make_list_file                                                   ##
## Description          : generate Tcl object list given the file that contains line-split     ##
##                        ( By referring to Samsung sec_make_list_from_file proc               ##
##                           It was changed to fit the ADT environment. )                      ##
##                        object names                                                         ##
## Author               : DT-PI                                                                ##
## Last Update Date     : 2024.10.28                                                           ##
## Script Version       : 0.1                                                                  ##
## Usage Example        : pt_shell> source adt_make_collection_from_file.tcl                   ##
##                        pt_shell> report_timing -to \                                        ##
##                                          [adt_make_collection_from_file endpoint_list.txt]  ##
##                                                                                             ##
#################################################################################################
suppress_message CMD-041
set __proc_name   						"adt_make_list_from_file"
set __adt_scr_version($__proc_name) 	"0.1 - 2024.10.28"

set debug_mode		0
set debug_level		0
set verbose_mode	0

;#------------------------------------------------------------------------------
;# proecdure main body
;#------------------------------------------------------------------------------
if {[info proc $__proc_name] == ""} {
  echo "## ADT_INFO: ADT custom procedure added - $__proc_name ($__adt_scr_version($__proc_name))"
}
proc adt_make_list_from_file { args } {
	set verbose_mode 	0
	set debug_mode 		0
	set unique_mode 	0


	parse_proc_arguments -args $args results
	foreach argname [array names results] {
		switch -glob -- $argname {
			"-verbose" {  set verbose_mode 1                }
			"-debug"   {  set debug_mode	 1              }
			"-unique"  {  set unique_mode	 1              }
			"files"    {  set files		$results($argname)  }
			default    {  puts stdout "## ADT_ERROR: unknown arguments - $argname" ; return}
		}
	}

	set objects 	[list ]

	foreach fname $files {
		if {![file exist $fname] || ![file readable $fname]} {
			echo "## ADT_ERROR: file not found or not readable - $fname"
			return ""
		}

		set fp 	[open $fname "r"]

		while {[gets $fp line_buf] >= 0 } {
			if { [regexp {^#} $line_buf] || ![regexp {\w+} $line_buf] } { continue }

			set obj_name	[lindex $line_buf 0]

			if {$unique_mode} {
				if {[lsearch $objects $obj_name] == -1} {
					lappend objects $obj_name
				}
			} else {
				lappend objects $obj_name
			}
		}
		close $fp
	}

	if {[info exist objects]} {
		if {$debug_mode} {echo "## DBG_MODE - [llength $objects] objects collected"}
		return $objects
	} else {
		return ""
	}
}

define_proc_attributes adt_make_list_from_file \
-info "return Tcl list given a file containing elements line by line" \
-define_args {
	{files	 	"filename(s)"  		  	  filename 	list	required}
	{-verbose 	"enable verbose message" 	"" 		boolean optional}
	{-unique 	"remove duplicated"		    "" 		boolean optional}
	{-debug 	"turn on debug mode" 		"" 		boolean {optional hidden}}
}
