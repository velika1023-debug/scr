#############################################################################
## Title       : sort_clk_uncer.tcl
## Author      : DT-PI
## Date        : 2024.4.18
## Description : List up the uncertainty value for each clock.
## Usage       :
#  pt_shell > source sort_clk_uncer.tcl
#  pt_shell > sort_clk_uncer -output ${LOG_DIR}/clk_uncertainty.log
## Version     : v0.1
#############################################################################

proc sort_clk_uncer { args } {

	global DESIGN MODE CORNER LOG_DIR
	set output                "${LOG_DIR}/clk_uncertainty.log"

	parse_proc_arguments -args $args results
	foreach argname [array names results] {
	  switch -glob -- $argname {
	    "-output"    {
			set output				    $results($argname)
	    }
	  }
	}
	set uncer_csv_file		 ".uncet_csv.list"

	echo "#####################################################################################"  > $output
	echo "# Design : ${DESIGN}"																	 >> $output
	echo "# Mode   : ${MODE}"																	 >> $output
	echo "# Corner : ${CORNER}" 																 >> $output
	echo "#####################################################################################" >> $output
	echo ""																						 >> $output

	echo " Clocks, freq \[MHz\] , period \[ns\] , setup uncertainty , hold uncertainty " >  $uncer_csv_file	
	foreach_in_collection clk [sort_collection -dictionary [get_clocks] full_name] {
		set fname	[get_attr [get_clocks $clk] full_name]
		set period	[get_attr [get_clocks $clk] period]
		set freq	[expr 1000 / [get_attr [get_clocks $clk] period] ]
		set waveform [regsub -all "{|}" [get_attr [get_clocks $fname] waveform] ""]
		set edge_cnt [llength $waveform]
		set setup_uncer [get_attr [get_clocks $fname] setup_uncertainty]
		set hold_uncer  [get_attr [get_clocks $fname] hold_uncertainty ]

		set setup_percent	"[expr ${setup_uncer}*100/${period}]"

		# Hold uncertainty	
		set hold_uncertainty_log "${LOG_DIR}/set_hold_uncert.log"
        set Fin [open $hold_uncertainty_log r]
        while { [gets $Fin line] != -1 } {
            if { [regexp {^#} $line] || ![regexp {\w+} $line] } { continue }
			
			if { [string match "*set_clock_uncertainty*-hold *" $line] } {
				set DM_hold [lindex $line 2]
			}
		}
		close $Fin
		echo " $fname , [format "%10.1f" $freq] , [format "%11.3f" $period] , [format "%8.4f" $setup_uncer] ([format "%5.2f" $setup_percent]%) , [format "%11.4f" $hold_uncer] " >> $uncer_csv_file
	}
	
	exec /prj/sophia/repo/BIN/tcllib/csv2table.tclsh $uncer_csv_file 1 >> ${output}
	file delete -force $uncer_csv_file

}


define_proc_attributes sort_clk_uncer \
-info "List up the uncertainty value for each clock." \
-define_args {
    {-output  "output filename (default output path : \${LOG_DIR}/clk_uncertainty.log)"	"<filename>"  string    optional }
}
