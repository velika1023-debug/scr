#!/bin/tclsh
#####################################
## Procedure
#####################################
proc create_dir { } {

	global COMMON_INNOVUS
	global COMMON_ICC2
	global COMMON_PV
	global COMMON_PEX
	global COMMON_COMPARE
	global COMMON_PSI
	global PRJ_INNOVUS
	global PRJ_ICC2 
	global PROCESS
	global NET_VER
	global REVISION
	global RUN_NAME
	global TOOL
	global description
	global RUNDIR

	set RUNDIR "${NET_VER}_${REVISION}_${RUN_NAME}-BE"

	if { $TOOL == "innovus" } {
		file mkdir $RUNDIR	
		file copy  ${PRJ_INNOVUS}/user_input_files.tcl		 	$RUNDIR/
		file copy  ${PRJ_INNOVUS}/user_design_setup.tcl			$RUNDIR/
		file copy  ${PRJ_INNOVUS}/Makefile						$RUNDIR/
		file copy  ${PRJ_INNOVUS}/plug							$RUNDIR/
		exec ln -s ${COMMON_INNOVUS}/${PROCESS}/util			[exec pwd]/$RUNDIR/
		exec ln -s ${COMMON_INNOVUS}							[exec pwd]/$RUNDIR/common_innovus
		exec ln -s ${COMMON_PV}									[exec pwd]/$RUNDIR/common_pv
		exec ln -s ${COMMON_PEX}								[exec pwd]/$RUNDIR/common_pex
		exec ln -s ${COMMON_COMPARE}							[exec pwd]/$RUNDIR/common_compare
		exec ln -s ${COMMON_PSI}								[exec pwd]/$RUNDIR/common_psi
		exec ln -s ${PRJ_INNOVUS}								[exec pwd]/$RUNDIR/prj_innovus
	} elseif { $TOOL == "icc2" } {
		file mkdir $RUNDIR	
		file copy  ${PRJ_ICC2}/user_input_files.tcl		 		$RUNDIR/
		file copy  ${PRJ_ICC2}/user_design_setup.rough.tcl 		$RUNDIR/
		file copy  ${PRJ_ICC2}/Makefile					 		$RUNDIR/
		file copy  ${PRJ_ICC2}/plug						 		$RUNDIR/
		exec ln -s ${COMMON_ICC2}/${PROCESS}/util				[exec pwd]/$RUNDIR/
		exec ln -s ${COMMON_ICC2}								[exec pwd]/$RUNDIR/common_icc2
		exec ln -s ${COMMON_PV}									[exec pwd]/$RUNDIR/common_pv
		exec ln -s ${COMMON_PEX}								[exec pwd]/$RUNDIR/common_pex
		exec ln -s ${COMMON_PSI}								[exec pwd]/$RUNDIR/common_psi
		exec ln -s ${PRJ_ICC2}									[exec pwd]/$RUNDIR/prj_icc2
	}

	exec echo $description > $RUNDIR/:README

	puts "INFO: Creating [exec pwd]/$RUNDIR"
	
	
}

proc clone_dir { } {

	global COMMON_INNOVUS
	global COMMON_ICC2
	global COMMON_PV
	global COMMON_PEX
	global COMMON_COMPARE
	global COMMON_PSI
	global PRJ_INNOVUS
	global PRJ_ICC2 
	global PROCESS
	global NET_VER
	global REVISION
	global RUN_NAME
	global TOOL
	global description
	global origin_dir
	global origin_step
	global clone_method
	global RUNDIR

	set RUNDIR "${NET_VER}_${REVISION}_${RUN_NAME}-BE"

	if { $TOOL == "innovus" } {
		file mkdir $RUNDIR
		file copy ${origin_dir}/user_input_files.tcl		 	$RUNDIR/
		file copy ${origin_dir}/user_design_setup.tcl 			$RUNDIR/
		file copy ${origin_dir}/Makefile  						$RUNDIR/
		file copy ${origin_dir}/plug 							$RUNDIR/
		file copy ${origin_dir}/view_definition.tcl 			$RUNDIR/
		exec ln -s ${COMMON_INNOVUS}/${PROCESS}/util			[exec pwd]/$RUNDIR/
		exec ln -s ${COMMON_INNOVUS}							[exec pwd]/$RUNDIR/common_innovus
		exec ln -s ${COMMON_PV}									[exec pwd]/$RUNDIR/common_pv
		exec ln -s ${COMMON_PEX}								[exec pwd]/$RUNDIR/common_pex
		exec ln -s ${COMMON_COMPARE}							[exec pwd]/$RUNDIR/common_compare
		exec ln -s ${COMMON_PSI}								[exec pwd]/$RUNDIR/common_psi
		exec ln -s ${PRJ_INNOVUS}								[exec pwd]/$RUNDIR/prj_innovus

		file mkdir ${RUNDIR}/pass ${RUNDIR}/log ${RUNDIR}/dbs ${RUNDIR}/report ${RUNDIR}/output ${RUNDIR}/snapshot ${RUNDIR}/spec ${RUNDIR}/make_dir

        exec ln -s [exec readlink -f ${origin_dir}/vars.tcl]    [exec pwd]/$RUNDIR/vars.tcl
        
        catch { file copy ${origin_dir}/HPDF_vars.tcl           $RUNDIR/ }
        catch { file copy ${origin_dir}/FPDB                    $RUNDIR/ } ; # request irkim

		catch { exec cp -rpf ${origin_dir}/pass/setup $RUNDIR/pass/ }

        if { [regexp {read_design|init|place_opt|cts|cts_opt|route|route_opt|chip_finish} $origin_step] } {

	 	    foreach step "read_design init place_opt cts cts_opt route route_opt chip_finish" {
		    	catch { exec cp -rpf ${origin_dir}/pass/${step}     $RUNDIR/pass/     }
		    	catch { exec cp -rpf ${origin_dir}/report/${step}   $RUNDIR/report/   }
		    	catch { exec cp -rpf ${origin_dir}/snapshot/${step} $RUNDIR/snapshot/ }

		    	if { $step == "cts" } { catch { exec cp -rpf ${origin_dir}/spec $RUNDIR/ } }
		    	
		    	foreach file [glob -nocomplain ${origin_dir}/log/${step}*] { catch { exec cp -rpf $file $RUNDIR/log/ } }

		    	if { $clone_method == "copy" } {
		    		if { $step != "read_design" } {
		    			catch { exec cp -rpf ${origin_dir}/output/${step} $RUNDIR/output/ }
		    			foreach file [glob -nocomplain ${origin_dir}/dbs/${step}.*] { catch { file copy -force $file $RUNDIR/dbs/ } }
		    		}
		    	} elseif { $clone_method == "link" } {
		    		if { $step != "read_design" } {
                        if { [file exists [exec pwd]/${origin_dir}/output/${step}] } { catch { exec ln -s [exec pwd]/${origin_dir}/output/${step} ${RUNDIR}/output/${step} } }
		    			foreach file [glob -nocomplain ${origin_dir}/dbs/${step}.*]  { catch { exec ln -s [exec pwd]/$file $RUNDIR/dbs/[exec basename $file] } }
		    		}
		    	}
		    	if { $step == $origin_step } { break }	
		    }
        } else {
            foreach step $origin_step {
		        catch { exec cp -rpf ${origin_dir}/pass/${step}     $RUNDIR/pass/     }
		        catch { exec cp -rpf ${origin_dir}/report/${step}   $RUNDIR/report/   }
		        catch { exec cp -rpf ${origin_dir}/snapshot/${step} $RUNDIR/snapshot/ }
    
    		    foreach file [glob -nocomplain ${origin_dir}/log/${step}*] { catch { exec cp -rpf $file $RUNDIR/log/ } }
    
    		    if { $clone_method == "copy" } {
    		    	catch { exec cp -rpf ${origin_dir}/output/${step} $RUNDIR/output/ }
    		    	foreach file [glob -nocomplain ${origin_dir}/dbs/${step}.*] { catch { file copy -force $file $RUNDIR/dbs/ } }
    		    } elseif { $clone_method == "link" } {
    		    	if { [file exists [exec pwd]/${origin_dir}/output/${step}] } { catch { exec ln -s [exec pwd]/${origin_dir}/output/${step} ${RUNDIR}/output/${step} } }
    		    	foreach file [glob -nocomplain ${origin_dir}/dbs/${step}.*]  { catch { exec ln -s [exec pwd]/$file $RUNDIR/dbs/[exec basename $file] } }
    		    }
            }
        }
	} elseif { $TOOL == "icc2" } {
		file mkdir $RUNDIR	
		file copy  ${origin_dir}/user_input_files.tcl		 		$RUNDIR/
		file copy  ${origin_dir}/user_design_setup.rough.tcl 		$RUNDIR/
		file copy  ${origin_dir}/Makefile					 		$RUNDIR/
		file copy  ${origin_dir}/plug						 		$RUNDIR/
		exec ln -s ${COMMON_ICC2}/${PROCESS}/util					[exec pwd]/$RUNDIR/
		exec ln -s ${COMMON_ICC2}									[exec pwd]/$RUNDIR/common_icc2
		exec ln -s ${COMMON_PV}										[exec pwd]/$RUNDIR/common_pv
		exec ln -s ${COMMON_PEX}									[exec pwd]/$RUNDIR/common_pex
		exec ln -s ${COMMON_PSI}									[exec pwd]/$RUNDIR/common_psi
		exec ln -s ${PRJ_ICC2}										[exec pwd]/$RUNDIR/prj_icc2
	}

	exec echo "origin dir: [exec pwd]/$origin_dir" 	>  $RUNDIR/:README
	exec echo $description  						>> $RUNDIR/:README

	puts "INFO: Cloning [exec pwd]/$RUNDIR"

}

#####################################
## Body
#####################################
eval [exec projconf.pl -print -format tcl]

set TOP_MODULE 	[lindex [split [exec pwd] "/"] end-1]
set TOOL 		[lindex [split [exec pwd] "/"] end]

if { [exec pwd] == "${IMPL_DIR}/${TOP_DESIGN}/SOC/${TOP_MODULE}/innovus" || [exec pwd] == "${IMPL_DIR}/${TOP_DESIGN}/SOC/${TOP_MODULE}/icc2"} {

	set NET_VER		[set ${TOP_MODULE}_INDB_VER]
	set REVISION 	[set PRE_${TOP_MODULE}_PNRIN_REVISION]

	set ls [regsub -all " " [glob -type d *] "\n"]
	
	puts "= Excute ls =================================================================="
	puts "Current Path: [exec pwd]"
	puts "\n$ls"
	puts "=============================================================================="
	
	puts "= Example ====================="
	puts "= create: 1	clone: 2"
	puts "==============================="
	puts -nonewline "Select number: "
	flush stdout
	gets stdin mode
	
	switch $mode {
		1 { set mode create_dir ; puts "Starting $mode" }
		2 { set mode clone_dir ; puts "Starting $mode" }
		default { puts "Error: number($mode) is not valid!" ; exit }
	}

		
	if { $mode == "clone_dir" } {
		puts "= Only Clone ====================="
		puts -nonewline "Select original dir "
		flush stdout
		gets stdin origin_dir

		puts -nonewline "What do you wanted step?(read_design/init/place_opt/cts/cts_opt/route/route_opt/chip_finish etc..) "
		flush stdout
		gets stdin origin_step

		puts -nonewline "Select preferred method, only dbs/output(copy/link) "
		flush stdout
		gets stdin clone_method
		puts "================================="
	}

	puts -nonewline "Write RunDir name (Do not use \"_\"): "
	flush stdout
	gets stdin RUN_NAME
	
	puts -nonewline "Write Description: "
	flush stdout
	gets stdin description
	
	if { [regexp "_" $RUN_NAME] } {
		puts "Error: Directory name ($RUN_NAME) is not valid input!! // include \"_\""
	} elseif { [info exists origin_dir] && [lsearch $ls $origin_dir] == "-1" } {
		puts "Error: Target Directory ($origin_dir) is not valid input!! // not exist" 
	} elseif { [lsearch $ls "${NET_VER}_${REVISION}_${RUN_NAME}-BE"] != "-1" } {
		puts "Error: Directory name ($RUN_NAME) is not valid input!! // exsited dir"
	} else {
		$mode
		exec echo "[exec date "+%y%m%d"]\t$TOP_MODULE\t[exec pwd]/$RUNDIR" >> $OUTFD_DIR/$TOP_DESIGN/LOG/rundir.list	
	}
} else {
	puts "Error: You should move to ${IMPL_DIR}/<TOP>/SOC/<BLOCK>/<TOOL>"
}
