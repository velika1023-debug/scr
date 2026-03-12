#!/bin/tclsh
############################################################################
# File				 : mpnr.tcl
# Author  (v1.5)     : DongWookKim (DT-PD)
# Author2 (v1.2)     : HongKyoungPyo (DT-PD)
# Author3 (v1.4)     : LeeJoungBae (DT-PI)
# Author3 (v1.7)     : JoYeAn (DT-PD)
# Date               : 2024.07.04
# Usage              : 
# Init Release Date  : 
# Last Update  Date  : 2025.11.11
# Scipt Version      : v1.7
# Revision History   : 
#   -. v0.0          : Initial Version
#   -. v0.1          : Enhancement and feature addition to the clone section
#   -. v0.2          : Delete line that copy user_input_files.tcl, user_design_setup.tcl (create_dir)
#                      Delete line that copy user_input_files.tcl (clone_dir)
#                      Update dbs cloning process to only include step.enc.dat and step.enc files.
#   -. v0.3          : PRJ_INNOVUS/Makefile -> COMMON_INNOVUS/Makefile (create_dir).
#   -. v0.4          : Change log histroy file (rundir.pd.list)
#    				   Change date format used in log history
#   -. v0.5          : Rename PEX-related folder in clone_dir_post
#   -. v0.6          : Add outfeed/LOG directory permission setting. 
#   -. v0.7          : Add FC & ICC2 generation part
#   -. v0.8          : Clone PRJ.view.csv, user_pex_info.tcl, user_psi_info.tcl files generated from csv.
#   -. v0.9          : delete cloning user_psi_info.tcl files generated from csv.
#   -. v1.0          : Create a new proc clone_dir_extra and update the code to clone extra Tcl files. (Ex) vp_assoc.tcl
#   -. v1.1          : Seperate FC PI/PD flow
#   -. v1.2          : add user_psi_info.tcl in clone_dir_extra
#   -. v1.3          : Clone log/run_time.rpt.
#   -. v1.4          : link 'con', Add empty-tag case, Add 'init' step for cloning
#   -. v1.5          : Add link common_tcl
#   -. v1.6          : Change origin directory plug copy
#   -. v1.7          : Delete .backup plug file 
############################################################################
#####################################
## Procedures
#####################################
proc create_dir { } {

	global COMMON_INNOVUS
	global COMMON_ICC2
	global COMMON_FC
	global COMMON_PV
	global COMMON_PEX
	global COMMON_PSI
	global COMMON_TCL
	global PRJ_INNOVUS
	global PRJ_ICC2 
	global PRJ_FC 
	global PRJ_TCL
	global PROCESS
	global NET_VER
	global REVISION
	global RUN_NAME
	global TOOL
	global description
	global RUNDIR
	global TOP_MODULE
    global PROJECT
	global IMPL_DIR

	file mkdir $RUNDIR	

	if { $TOOL == "innovus" } {
        #pmj
		exec cp	/prj/${PROJECT}/scn/OUTPUT/PRJ.view.csv $RUNDIR/
		exec cp /prj/${PROJECT}/scn/OUTPUT/user_pex_info.tcl $RUNDIR/

        file copy  ${COMMON_INNOVUS}/Makefile					$RUNDIR/

		file mkdir $RUNDIR/plug/innovus
		set files [glob -nocomplain ${PRJ_INNOVUS}/plug/innovus/*.tcl ${PRJ_INNOVUS}/plug/innovus/${TOP_MODULE}]
		foreach f $files { file copy $f $RUNDIR/plug/innovus/ }

		file copy  ${PRJ_INNOVUS}/sod.list						$RUNDIR/        
		catch { file copy  ${PRJ_INNOVUS}/eco_recipe.config     $RUNDIR/ }
		exec ln -s ${COMMON_INNOVUS}/${PROCESS}/util			$RUNDIR/
		exec ln -s ${COMMON_INNOVUS}							$RUNDIR/common_innovus
		exec ln -s ${COMMON_PV}									$RUNDIR/common_pv
		exec ln -s ${COMMON_PEX}								$RUNDIR/common_pex
		exec ln -s ${COMMON_PSI}								$RUNDIR/common_psi
		exec ln -s ${COMMON_TCL}/innovus                        $RUNDIR/common_tcl
		exec ln -s ${PRJ_INNOVUS}								$RUNDIR/prj_innovus

		if { [file exists ${IMPL_DIR}/${PROJECT}/SOC/${TOP_MODULE}/user_script] } {
			exec ln -s ${IMPL_DIR}/${PROJECT}/SOC/${TOP_MODULE}/user_script $RUNDIR/
		}
	} elseif { $TOOL == "icc2" } {
		exec cp	/prj/${PROJECT}/scn/OUTPUT/PRJ.view.csv $RUNDIR/
		exec cp /prj/${PROJECT}/scn/OUTPUT/user_pex_info.tcl $RUNDIR/

		file copy ${COMMON_ICC2}/Makefile                       $RUNDIR/
		file copy ${PRJ_ICC2}/user_design_setup.tcl				$RUNDIR/

		exec ln -s ${COMMON_ICC2}								$RUNDIR/common_icc2
		exec ln -s ${COMMON_PV}									$RUNDIR/common_pv
		exec ln -s ${COMMON_PEX}								$RUNDIR/common_pex
		exec ln -s ${COMMON_PSI}								$RUNDIR/common_psi
		exec ln -s ${PRJ_ICC2}								    $RUNDIR/prj_icc2
	} elseif { $TOOL == "fc" } {
		exec cp	/prj/${PROJECT}/scn/OUTPUT/PRJ.view.csv $RUNDIR/
		exec cp /prj/${PROJECT}/scn/OUTPUT/user_pex_info.tcl $RUNDIR/

		
		file copy ${COMMON_FC}/Makefile                         $RUNDIR/
		file copy ${PRJ_FC}/user_design_setup.tcl				$RUNDIR/
		file copy ${PRJ_FC}/plug 								$RUNDIR/

		exec ln -s ${COMMON_FC}									$RUNDIR/common_fc
		exec ln -s ${COMMON_PV}									$RUNDIR/common_pv
		exec ln -s ${COMMON_PEX}								$RUNDIR/common_pex
		exec ln -s ${COMMON_PSI}								$RUNDIR/common_psi
		exec ln -s ${PRJ_FC}								    $RUNDIR/prj_fc
	}

	exec projconf.pl -print -format tcl    > $RUNDIR/sophia_vars.tcl
	exec projconf.pl -print -format tclenv > $RUNDIR/sophia_vars.env.tcl

	#== update POST_*_REVISION_* (sophia_vars.tcl, sophia_vars.env.tcl)
	source $RUNDIR/sophia_vars.tcl
	set lineNum [exec grep -rn " POST_${TOP_MODULE}_REVISION_PNR " $RUNDIR/sophia_vars.tcl | cut -d: -f1]
	exec sed -i "${lineNum}s/.*/set POST_${TOP_MODULE}_REVISION_PNR \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.tcl 
	set lineNum [exec grep -rn " POST_${TOP_MODULE}_REVISION_PV " $RUNDIR/sophia_vars.tcl | cut -d: -f1]
	exec sed -i "${lineNum}s/.*/set POST_${TOP_MODULE}_REVISION_PV \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.tcl 
	set lineNum [exec grep -rn " POST_${TOP_MODULE}_REVISION_PEX " $RUNDIR/sophia_vars.tcl | cut -d: -f1]
	exec sed -i "${lineNum}s/.*/set POST_${TOP_MODULE}_REVISION_PEX \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.tcl 
	set lineNum [exec grep -rn " POST_${TOP_MODULE}_REVISION_PSI " $RUNDIR/sophia_vars.tcl | cut -d: -f1]
	exec sed -i "${lineNum}s/.*/set POST_${TOP_MODULE}_REVISION_PSI \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.tcl 
	
	set lineNum [exec grep -rn "env(POST_${TOP_MODULE}_REVISION_PNR)" $RUNDIR/sophia_vars.env.tcl | cut -d: -f1]
	exec sed -i "${lineNum}s/.*/set env(POST_${TOP_MODULE}_REVISION_PNR) \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.env.tcl 
	set lineNum [exec grep -rn "env(POST_${TOP_MODULE}_REVISION_PV)" $RUNDIR/sophia_vars.env.tcl | cut -d: -f1]
	exec sed -i "${lineNum}s/.*/set env(POST_${TOP_MODULE}_REVISION_PV) \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.env.tcl 
	set lineNum [exec grep -rn "env(POST_${TOP_MODULE}_REVISION_PEX)" $RUNDIR/sophia_vars.env.tcl | cut -d: -f1]
	exec sed -i "${lineNum}s/.*/set env(POST_${TOP_MODULE}_REVISION_PEX) \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.env.tcl 
	set lineNum [exec grep -rn "env(POST_${TOP_MODULE}_REVISION_PSI)" $RUNDIR/sophia_vars.env.tcl | cut -d: -f1]
	exec sed -i "${lineNum}s/.*/set env(POST_${TOP_MODULE}_REVISION_PSI) \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.env.tcl 

	exec echo $description > $RUNDIR/:README

	puts "\n<ADF_INFO> Creating $RUNDIR\n"
	
	
}

#####################################
## clone procedures
#####################################

# 1. clone_common

proc clone_common { } {

	global COMMON_INNOVUS
	global COMMON_ICC2
	global COMMON_FC
	global COMMON_PV
	global COMMON_PEX
	global COMMON_PSI
	global COMMON_TCL
	global PRJ_INNOVUS
	global PRJ_ICC2 
	global PRJ_FC 
	global PROCESS
	global NET_VER
	global REVISION
	global RUN_NAME
	global TOOL
	global description
	global origin_dir
	global clone_method
	global RUNDIR
	global TOP_MODULE
	global PROJECT
	global IMPL_DIR

	if { $TOOL == "innovus" } {  

		if { [file exists $RUNDIR]} {} else { file mkdir $RUNDIR }
		checkCopyFail "copy ${origin_dir}/user_design_setup.tcl 		$RUNDIR/"
		checkCopyFail "copy ${origin_dir}/Makefile  					$RUNDIR/"

		file mkdir $RUNDIR/plug/innovus

		#set current_dir_plug_files	[glob -nocomplain ${PRJ_INNOVUS}/plug/innovus/*.tcl ${PRJ_INNOVUS}/plug/innovus/${TOP_MODULE}]
		set origin_dir_plug_files	[glob -nocomplain ${origin_dir}/plug/innovus/*.tcl ${origin_dir}/plug/innovus/${TOP_MODULE}]

		#foreach f $files { file copy $f $RUNDIR/plug/innovus/ }
		foreach f $origin_dir_plug_files { file copy $f $RUNDIR/plug/innovus/ } 


		checkCopyFail "copy ${origin_dir}/sod.list						$RUNDIR/"
		checkCopyFail "copy ${origin_dir}/eco_recipe.config             $RUNDIR/"
		checkCopyFail "copy ${origin_dir}/view_definition.tcl 			$RUNDIR/"

		checkExecFail "ln -s ${COMMON_INNOVUS}/${PROCESS}/util			$RUNDIR/"
		checkExecFail "ln -s ${COMMON_INNOVUS}							$RUNDIR/common_innovus"
		checkExecFail "ln -s ${COMMON_PV}								$RUNDIR/common_pv"
		checkExecFail "ln -s ${COMMON_PEX}								$RUNDIR/common_pex"
		checkExecFail "ln -s ${COMMON_PSI}								$RUNDIR/common_psi"
		checkExecFail "ln -s ${COMMON_TCL}/innovus						$RUNDIR/common_tcl"
		checkExecFail "ln -s ${PRJ_INNOVUS}								$RUNDIR/prj_innovus"

		if { [file exists ${IMPL_DIR}/${PROJECT}/SOC/${TOP_MODULE}/user_script] } {
			exec ln -s ${IMPL_DIR}/${PROJECT}/SOC/${TOP_MODULE}/user_script $RUNDIR/
		}

		file mkdir ${RUNDIR}/pass ${RUNDIR}/log ${RUNDIR}/dbs ${RUNDIR}/report ${RUNDIR}/output ${RUNDIR}/snapshot ${RUNDIR}/spec ${RUNDIR}/make_dir

		exec ln -s [exec readlink -e ${origin_dir}/vars.tcl]    $RUNDIR/vars.tcl


		catch { file copy ${origin_dir}/sophia_vars.tcl     $RUNDIR/sophia_vars.clone.tcl     }
		catch { file copy ${origin_dir}/sophia_vars.env.tcl $RUNDIR/sophia_vars.clone.env.tcl }

		exec projconf.pl -print -format tcl    > $RUNDIR/sophia_vars.tcl
		exec projconf.pl -print -format tclenv > $RUNDIR/sophia_vars.env.tcl

		#== update POST_*_REVISION_* (sophia_vars.tcl, sophia_vars.env.tcl)
		source $RUNDIR/sophia_vars.tcl
		set lineNum [exec grep -rn " POST_${TOP_MODULE}_REVISION_PNR " $RUNDIR/sophia_vars.tcl | cut -d: -f1]
		exec sed -i "${lineNum}s/.*/set POST_${TOP_MODULE}_REVISION_PNR \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.tcl 
		set lineNum [exec grep -rn " POST_${TOP_MODULE}_REVISION_PV " $RUNDIR/sophia_vars.tcl | cut -d: -f1]
		exec sed -i "${lineNum}s/.*/set POST_${TOP_MODULE}_REVISION_PV \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.tcl 
		set lineNum [exec grep -rn " POST_${TOP_MODULE}_REVISION_PEX " $RUNDIR/sophia_vars.tcl | cut -d: -f1]
		exec sed -i "${lineNum}s/.*/set POST_${TOP_MODULE}_REVISION_PEX \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.tcl 
		set lineNum [exec grep -rn " POST_${TOP_MODULE}_REVISION_PSI " $RUNDIR/sophia_vars.tcl | cut -d: -f1]
		exec sed -i "${lineNum}s/.*/set POST_${TOP_MODULE}_REVISION_PSI \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.tcl 
		
		set lineNum [exec grep -rn "env(POST_${TOP_MODULE}_REVISION_PNR)" $RUNDIR/sophia_vars.env.tcl | cut -d: -f1]
		exec sed -i "${lineNum}s/.*/set env(POST_${TOP_MODULE}_REVISION_PNR) \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.env.tcl 
		set lineNum [exec grep -rn "env(POST_${TOP_MODULE}_REVISION_PV)" $RUNDIR/sophia_vars.env.tcl | cut -d: -f1]
		exec sed -i "${lineNum}s/.*/set env(POST_${TOP_MODULE}_REVISION_PV) \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.env.tcl 
		set lineNum [exec grep -rn "env(POST_${TOP_MODULE}_REVISION_PEX)" $RUNDIR/sophia_vars.env.tcl | cut -d: -f1]
		exec sed -i "${lineNum}s/.*/set env(POST_${TOP_MODULE}_REVISION_PEX) \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.env.tcl 
		set lineNum [exec grep -rn "env(POST_${TOP_MODULE}_REVISION_PSI)" $RUNDIR/sophia_vars.env.tcl | cut -d: -f1]
		exec sed -i "${lineNum}s/.*/set env(POST_${TOP_MODULE}_REVISION_PSI) \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.env.tcl 
		
		checkCopyFail "copy ${origin_dir}/HPDF_vars.tcl           $RUNDIR/"
		catch { file copy ${origin_dir}/FPDB                    $RUNDIR/ }; # request irkim

		catch { exec cp -rpf ${origin_dir}/pass/setup $RUNDIR/pass/ }
	
	} elseif { $TOOL == "icc2" || $TOOL == "fc" } {

		if { [file exists $RUNDIR]} {} else { file mkdir $RUNDIR }
        checkCopyFail "copy ${origin_dir}/user_design_setup.tcl				$RUNDIR/"
        checkCopyFail "copy ${origin_dir}/Makefile							$RUNDIR/"
		checkCopyFail "copy ${origin_dir}/plug 								$RUNDIR/"
		checkCopyFail "copy ${origin_dir}/scenario_definition.tcl			$RUNDIR/"

		if { $TOOL == "icc2" } {
			checkExecFail "ln -s ${COMMON_ICC2}								$RUNDIR/common_icc2"
			checkExecFail "ln -s ${COMMON_PV}								$RUNDIR/common_pv"
			checkExecFail "ln -s ${COMMON_PEX}								$RUNDIR/common_pex"
			checkExecFail "ln -s ${COMMON_PSI}								$RUNDIR/common_psi"
			checkExecFail "ln -s ${PRJ_ICC2}								$RUNDIR/prj_icc2"
		} elseif { $TOOL == "fc" } {
			checkExecFail "ln -s ${COMMON_FC}								$RUNDIR/common_fc"
			checkExecFail "ln -s ${COMMON_PV}								$RUNDIR/common_pv"
			checkExecFail "ln -s ${COMMON_PEX}								$RUNDIR/common_pex"
			checkExecFail "ln -s ${COMMON_PSI}								$RUNDIR/common_psi"
			checkExecFail "ln -s ${PRJ_FC}								    $RUNDIR/prj_fc"
		}

		file mkdir ${RUNDIR}/pass ${RUNDIR}/log/backup_log ${RUNDIR}/nlib/old ${RUNDIR}/report ${RUNDIR}/output ${RUNDIR}/snapshot ${RUNDIR}/gen_file ${RUNDIR}/make_dir 

        exec ln -s [exec readlink -f ${origin_dir}/vars.tcl]    $RUNDIR/vars.tcl


        catch { file copy ${origin_dir}/sophia_vars.tcl     $RUNDIR/sophia_vars.clone.tcl     }
        catch { file copy ${origin_dir}/sophia_vars.env.tcl $RUNDIR/sophia_vars.clone.env.tcl }

        exec projconf.pl -print -format tcl    > $RUNDIR/sophia_vars.tcl
        exec projconf.pl -print -format tclenv > $RUNDIR/sophia_vars.env.tcl

        #== update POST_*_REVISION_* (sophia_vars.tcl, sophia_vars.env.tcl)
        source $RUNDIR/sophia_vars.tcl
        set lineNum [exec grep -rn " POST_${TOP_MODULE}_REVISION_PNR " $RUNDIR/sophia_vars.tcl | cut -d: -f1]
        exec sed -i "${lineNum}s/.*/set POST_${TOP_MODULE}_REVISION_PNR \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.tcl 
        set lineNum [exec grep -rn " POST_${TOP_MODULE}_REVISION_PV " $RUNDIR/sophia_vars.tcl | cut -d: -f1]
        exec sed -i "${lineNum}s/.*/set POST_${TOP_MODULE}_REVISION_PV \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.tcl 
        set lineNum [exec grep -rn " POST_${TOP_MODULE}_REVISION_PEX " $RUNDIR/sophia_vars.tcl | cut -d: -f1]
        exec sed -i "${lineNum}s/.*/set POST_${TOP_MODULE}_REVISION_PEX \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.tcl 
        set lineNum [exec grep -rn " POST_${TOP_MODULE}_REVISION_PSI " $RUNDIR/sophia_vars.tcl | cut -d: -f1]
        exec sed -i "${lineNum}s/.*/set POST_${TOP_MODULE}_REVISION_PSI \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.tcl 

        set lineNum [exec grep -rn "env(POST_${TOP_MODULE}_REVISION_PNR)" $RUNDIR/sophia_vars.env.tcl | cut -d: -f1]
        exec sed -i "${lineNum}s/.*/set env(POST_${TOP_MODULE}_REVISION_PNR) \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.env.tcl 
        set lineNum [exec grep -rn "env(POST_${TOP_MODULE}_REVISION_PV)" $RUNDIR/sophia_vars.env.tcl | cut -d: -f1]
        exec sed -i "${lineNum}s/.*/set env(POST_${TOP_MODULE}_REVISION_PV) \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.env.tcl 
        set lineNum [exec grep -rn "env(POST_${TOP_MODULE}_REVISION_PEX)" $RUNDIR/sophia_vars.env.tcl | cut -d: -f1]
        exec sed -i "${lineNum}s/.*/set env(POST_${TOP_MODULE}_REVISION_PEX) \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.env.tcl 
        set lineNum [exec grep -rn "env(POST_${TOP_MODULE}_REVISION_PSI)" $RUNDIR/sophia_vars.env.tcl | cut -d: -f1]
        exec sed -i "${lineNum}s/.*/set env(POST_${TOP_MODULE}_REVISION_PSI) \"[set PRE_${TOP_MODULE}_REVISION_PNRIN]_${RUN_NAME}-BE\"/" $RUNDIR/sophia_vars.env.tcl 

		catch { exec cp -rpf ${origin_dir}/pass/setup $RUNDIR/pass/ }

	}
}

# 2. main code of clone

proc clone_dir { origin_step } {

	global COMMON_INNOVUS
	global COMMON_ICC2
	global COMMON_FC
	global COMMON_PV
	global COMMON_PEX
	global COMMON_PSI
	global PRJ_INNOVUS
	global PRJ_ICC2 
	global PRJ_FC 
	global PROCESS
	global NET_VER
	global REVISION
	global RUN_NAME
	global TOOL
	global description
	global origin_dir
	global clone_method
	global RUNDIR
	global TOP_MODULE
	global PnR_all_done
	global Post_all_done
	global Eco_all_done
	global Eco_Post_all_done
	global PnR_flag 
	global flag_post_folder

	if { $TOOL == "innovus" } {

		if { [regexp {^(read_design|init|place_opt|cts|cts_opt|route|route_opt|chip_finish)$} $origin_step] } {
			set PnR_flag 1 
			foreach step "read_design init place_opt cts cts_opt route route_opt chip_finish" {
				
				# Run PnR
				set PnR_all_done 1
				clone_dir_PnR $step
				
				# Run Post
				set Post_all_done 1
				clone_dir_post $step
				
				if { $step == $origin_step } { break }
			}
			clone_dir_extra

		} else {
			foreach step $origin_step {
				# Run PnR
				set Eco_all_done 1
				clone_dir_PnR $step
				# Run Post
				set Eco_Post_all_done 1
				clone_dir_post $step

				if { $step == $origin_step } { break }
			}
			clone_dir_extra
		}
	} elseif { $TOOL == "icc2" || $TOOL == "fc" } {

		if { [regexp {^(read_design|floorplan|powerplan|init|compile|place_opt|clock_opt_cts|clock_opt_opto|route_auto|route_opt|chip_finish)$} $origin_step] } {
			set PnR_flag 1 
			foreach step "read_design floorplan powerplan init compile place_opt clock_opt_cts clock_opt_opto route_auto route_opt chip_finish" {
				
				# Run PnR
				set PnR_all_done 1
				clone_dir_PnR $step
				
				# Run Post
				set Post_all_done 1
				clone_dir_post $step
				
				if { $step == $origin_step } { break }
			}

		} else {	
			foreach step $origin_step {
				# Run PnR
				set Eco_all_done 1
				clone_dir_PnR $step
				# Run Post
				set Eco_Post_all_done 1
				clone_dir_post $step

				if { $step == $origin_step } { break }
			}
		}
	}
	exec echo "origin dir: $origin_dir" 	>  $RUNDIR/:README
	exec echo $description  				>> $RUNDIR/:README	
}

# 3. PnR

proc clone_dir_PnR { step } {

	global COMMON_INNOVUS
	global COMMON_ICC2
	global COMMON_FC
	global COMMON_PV
	global COMMON_PEX
	global COMMON_PSI
	global PRJ_INNOVUS
	global PRJ_ICC2 
	global PRJ_FC 
	global PROCESS
	global NET_VER
	global REVISION
	global RUN_NAME
	global TOOL
	global description
	global origin_dir
	global clone_method
	global RUNDIR
	global TOP_MODULE
	global PnR_all_done
	global Eco_all_done

# [RECOVERED_UNMAPPED_FROM 019b72db-449d-73af-92d6-831a0a16069b.txt] This block appeared before the first PATH marker in 019b72db-449d-73af-92d6-831a0a16069b.txt.
# [ATTACH_DECISION] Attached to previous file by sequential continuity.

	if { $TOOL == "innovus" } {
	
		if {[regexp {^(read_design|init|place_opt|cts|cts_opt|route|route_opt|chip_finish)$} $step ] } { 
			set checkProc "checkPnRFail" 
		} else { 
			set checkProc "checkEcoFail"
		}
        
        #pmj
        $checkProc "cp -rpf ${origin_dir}/PRJ.view.csv          $RUNDIR/"

		$checkProc "cp -rpf ${origin_dir}/report/${step}   $RUNDIR/report/"
		if {[file exists $RUNDIR/vars.tcl]} {
			if {[file exists $RUNDIR/report/${step}/vars.tcl]} {
				file delete $RUNDIR/vars.tcl
				catch { exec ln -s [exec readlink -e $RUNDIR/report/${step}/vars.tcl]    $RUNDIR/vars.tcl }
			}
		} else {}

		if { $step != "read_design" } { $checkProc "cp -rpf ${origin_dir}/snapshot/${step} $RUNDIR/snapshot/" }
		if { $step == "cts" } { $checkProc "cp -rpf ${origin_dir}/spec $RUNDIR/" }
			    
		foreach file "[glob -nocomplain ${origin_dir}/log/${step}*] [glob -nocomplain ${origin_dir}/log/run_time.rpt]" { $checkProc "cp -rpf $file $RUNDIR/log/" }
		foreach file "[glob -nocomplain ${origin_dir}/pass/${step}] [glob -nocomplain ${origin_dir}/pass/${step}.*]" { $checkProc "cp -rpf $file $RUNDIR/pass/" }

		if { $clone_method == "copy" } {
			if { $step != "read_design" } {
				$checkProc "cp -rpf ${origin_dir}/output/${step} $RUNDIR/output/"
				foreach file [glob -nocomplain ${origin_dir}/dbs/${step}.*] {
					if {[string first "backup" $file] == -1 && ([string match "*${step}.enc.dat" $file] || [string match "*${step}.enc" $file]) }  { 
						catch { file copy -force $file $RUNDIR/dbs/ }
					}
				}
			}
		} elseif { $clone_method == "link" } {
			if { $step != "read_design" } {
				if { [file exists ${origin_dir}/output/${step}] } { $checkProc "ln -s ${origin_dir}/output/${step} ${RUNDIR}/output/${step}" }
				foreach file [glob -nocomplain ${origin_dir}/dbs/${step}.*] {
					if {[string first "backup" $file] == -1 && ([string match "*${step}.enc.dat" $file] || [string match "*${step}.enc" $file]) } { 
						$checkProc "ln -s $file $RUNDIR/dbs/[exec basename $file]" }
				}
			}
		}
	} elseif { $TOOL == "icc2" || $TOOL == "fc" } {
		if {[regexp {^(read_design|floorplan|powerplan|init|compile|place_opt|clock_opt_cts|clock_opt_opto|route_auto|route_opt|chip_finish)$} $step ] } { 
			set checkProc "checkPnRFail" 
		} else { 
			set checkProc "checkEcoFail"
		}

        $checkProc "cp -rpf ${origin_dir}/PRJ.view.csv          $RUNDIR/"

		$checkProc "cp -rpf ${origin_dir}/report/${step}   $RUNDIR/report/"
		if {[file exists $RUNDIR/vars.tcl]} {
			if {[file exists $RUNDIR/report/${step}/vars.tcl]} {
				file delete $RUNDIR/vars.tcl
				catch { exec ln -s [exec readlink -e $RUNDIR/report/${step}/vars.tcl]    $RUNDIR/vars.tcl }
			}
		} else {}

		if {![file exists $RUNDIR/scenario_definition.tcl]} {
			if {[file exists $RUNDIR/report/read_design/scenario_definition.tcl]} {
				file delete $RUNDIR/scenario_definition.tcl
				catch { exec ln -s [exec readlink -e $RUNDIR/report/read_design/scenario_definition.tcl]    $RUNDIR/scenario_definition.tcl }
			}
		} else {}

		if { $step != "read_design" } { $checkProc "cp -rpf ${origin_dir}/snapshot/${step} $RUNDIR/snapshot/" }
			    
		foreach file [glob -nocomplain ${origin_dir}/log/${step}*] { $checkProc "cp -rpf $file $RUNDIR/log/" }
		foreach file [glob -nocomplain ${origin_dir}/log/*read_constraint.log] { $checkProc "cp -rpf $file $RUNDIR/log/" }
		foreach file "[glob -nocomplain ${origin_dir}/pass/${step}] [glob -nocomplain ${origin_dir}/pass/${step}.*]" { $checkProc "cp -rpf $file $RUNDIR/pass/" }

		if { $clone_method == "copy" } {
			if { $step != "read_design" } {
				$checkProc "cp -rpf ${origin_dir}/output/${step} $RUNDIR/output/"
				if { [file exists ${origin_dir}/nlib/${TOP_MODULE}_${step}.nlib] } { catch { file copy -force ${origin_dir}/nlib/${TOP_MODULE}_${step}.nlib $RUNDIR/nlib/ } }
			}
		} elseif { $clone_method == "link" } {
			if { $step != "read_design" } {
				if { [file exists ${origin_dir}/output/${step}] } { $checkProc "ln -s ${origin_dir}/output/${step} ${RUNDIR}/output/${step}" }
				if { [file exists ${origin_dir}/nlib/${TOP_MODULE}_${step}.nlib] } { $checkProc "ln -s ${origin_dir}/nlib/${TOP_MODULE}_${step}.nlib ${RUNDIR}/nlib/${TOP_MODULE}_${step}.nlib" }
			}
		}
	}
}

# 4. Post

proc clone_dir_post { step } {

	global NET_VER
	global REVISION
	global RUN_NAME
	global origin_dir
	global RUNDIR
	global clone_method 
	global post_folder
	global post_return
	global Post_all_done
	global Eco_Post_all_done
	global flag_post_folder

	# Run only once
	if { $flag_post_folder == 0} {
		# post_folders
		set post_folder {}
		set origin_folder [exec sh -c "find $origin_dir -maxdepth 1 -type d"]
		set post_folder_tmp "MERGE MERGE_PEX DUMMY_PEX DUMMY_FILL PEX DECOMP COLOR_MERGE DRC PM DFM LFD VRC V2LVS LVS LVL PERC PSI ECO PT"
	
		foreach line [split $origin_folder "\n"] {
			set folder_name [string trimleft $line "./"]
			set folder_name [file tail $folder_name]
			if {$folder_name in $post_folder_tmp} {
				lappend post_folder $folder_name
			}
		}
		
		foreach folder $post_folder {
			file mkdir $RUNDIR/$folder	
		}

		# make_dir
		set fileList [glob -nocomplain $origin_dir/make_dir/*]
		foreach f $fileList {
		  set make_dir_file [file tail $f]
		  catch { file copy ${origin_dir}/make_dir/$make_dir_file        $RUNDIR/make_dir/ }	
		}
		set last_folder [lindex $post_folder end]
		set flag_post_folder 1
	} else {}
		
	set last_folder [lindex $post_folder end]

	if { [regexp {^(read_design|init|floorplan|powerplan|init|compile|place_opt|cts|clock_opt_cts|cts_opt|clock_opt_opto|route|route_auto|route_opt|chip_finish)$} $step ]} {
		set checkProc "checkPostFail" 
	} else { 
		set checkProc "checkEcoPostFail"
	}
	
	catch { file copy ${origin_dir}/user_pex_info.tcl             $RUNDIR/ }
	catch { file copy ${origin_dir}/user_pv_info.tcl              $RUNDIR/ }
	catch { file copy ${origin_dir}/config_teco.tcl               $RUNDIR/ }

	if { $clone_method == "copy" } {
		foreach folder $post_folder {
			if {[file isdirectory $origin_dir/$folder/$step]} {
				$checkProc "cp -rpf ${origin_dir}/$folder/${step}   $RUNDIR/$folder"
			}
			if { $folder == "$last_folder" } { break }
		}
	} elseif { $clone_method == "link" } {
		foreach folder $post_folder {
			if {[file isdirectory $origin_dir/$folder/$step]} {
				$checkProc "ln -s ${origin_dir}/$folder/$step   $RUNDIR/$folder/$step "
				if { $folder == "$last_folder" } { break }
			}
		}
	}
}

proc clone_dir_extra {} {

	global NET_VER
	global REVISION
	global RUN_NAME
	global origin_dir
	global RUNDIR

    catch { file copy ${origin_dir}/vp_assoc.tcl    $RUNDIR/     }
    catch { file copy ${origin_dir}/user_psi_info.tcl    $RUNDIR/     }
	
}

#####################################
## check procedures
#####################################

proc checkCopyFail {command} {
	if {[catch { eval file $command } errMsg]} {
		if { ![string match "*Permission denied*" $errMsg]} {
			puts stderr "<ADF_WARN> $errMsg \n"
		}
	}
}

proc checkExecFail {command} {

	if {[catch { eval exec $command} errMsg]} {
		if { ![string match "*Permission denied*" $errMsg]} {
			puts stderr "<ADF_WARN> $errMsg \n"
		}
	}
}

proc checkPnRFail {command} {
	global PnR_all_done
	global PnR_errList

	if {[catch { eval exec $command} errMsg]} {
		if { ![string match "*Permission denied*" $errMsg]} {
			lappend PnR_errList $errMsg
			set PnR_all_done 0	
		}
	}	
}
	
proc checkPostFail {command} {
	global Post_all_done
	global Post_errList

	if {[catch { eval exec $command} errMsg]} {
		if { ![string match "*Permission denied*" $errMsg]} {
			lappend Post_errList $errMsg		
			set Post_all_done 0
		}
	}
}

proc checkEcoFail {command} {
	global Eco_all_done
	global Eco_errList

	if {[catch { eval exec $command} errMsg]} {
		if { ![string match "*Permission denied*" $errMsg]} {
			lappend ECO_errList $errMsg		
			set ECO_all_done 0
		}
	}
}

proc checkEcoPostFail {command} {
	global Eco_Post_all_done
	global Eco_Post_errList

	if {[catch { eval exec $command} errMsg]} {
		if { ![string match "*Permission denied*" $errMsg]} {
			lappend Eco_Post_errList $errMsg		
			set Eco_Post_all_done 0
		}
	}
}


#####################################
## Body
#####################################

eval [exec projconf.pl -print -format tcl]

set TOP_MODULE 	[lindex [split [exec pwd] "/"] end-1]
set TOOL 		[lindex [split [exec pwd] "/"] end]

if { [exec pwd] == "${IMPL_DIR}/${PROJECT}/SOC/${TOP_MODULE}/innovus" || [exec pwd] == "${IMPL_DIR}/${PROJECT}/SOC/${TOP_MODULE}/icc2" || [exec pwd] == "${IMPL_DIR}/${PROJECT}/SOC/${TOP_MODULE}/fc"} {

	set NET_VER		[set ${TOP_MODULE}_INDB_VER]
	set wsdir [lsearch -all -inline [lsort [glob -nocomplain -type d *]] "EVT*"]

	if { [info exists fc_pi] && $fc_pi } {
		set REVISION 	[set PRE_${TOP_MODULE}_REVISION_SYN]
		set ls [regsub -all " " [lsearch -all -inline -not $wsdir "*BE"] "\n"]
	} else {
		set REVISION 	[set PRE_${TOP_MODULE}_REVISION_PNRIN]
		set ls [regsub -all " " [lsearch -all -inline $wsdir "*BE"] "\n"]
	}

	puts "= Excute ls =================================================================="
	puts "Current Path: [exec pwd]"
	puts "\n$ls"
	puts "=============================================================================="
	
	puts "= Example ====================="
	puts "= create: 1	clone: 2"
	puts "==============================="
	puts -nonewline "Select number >> "
	flush stdout
	gets stdin mode
	
	switch $mode {
		1 { set mode create_dir ; puts "Starting $mode" }
		2 { set mode clone_dir ; puts "Starting $mode" }
		default { puts "Error: number($mode) is not valid!" ; exit }
	}

		
	if { $mode == "clone_dir" } {
		puts "= Only Clone ====================="
		puts -nonewline "Select original dir >> "
		flush stdout
		gets stdin origin_dir
		
		if { $TOOL == "innovus" } {
			set step_txt "step    : read_design / init / place_opt / cts / cts_opt / route / route_opt / chip_finish / eco (user defined)"
		} elseif { $TOOL == "icc2" || $TOOL == "fc" } {
			set step_txt "step    : read_design / floorplan / powerplan / init / compile / place_opt / clock_opt_cts / clock_opt_opto / route_auto / route_opt / chip_finish / eco (user defined)"
		}

		puts "===================================================                                                                  "
		puts "   DESCRIPTION                                                                                                       "
		puts "===================================================											                       "
		puts $step_txt
		puts "===================================================											                       "
		
		puts -nonewline "What steps do you want to take? >>"
		flush stdout
		gets stdin origin_steps

		puts -nonewline "Select preferred method, only dbs/nlib/output(copy/link) >> "
		flush stdout
		gets stdin clone_method


		if { ![regexp {^(copy|link)$} $clone_method] } {
			puts "Error : $clone_method is not valid input!! // not exist"
		return }

		puts "================================="
	}

	if { [info exists fc_pi] && $fc_pi } {
		while { 1 } {
			puts -nonewline "Write tag (Optional, Less than 80 characters) >> "
			flush stdout
			gets stdin RUN_NAME
			if { [string length $RUN_NAME] > 80 } { continue } else { break }
		}
        
        if { $RUN_NAME != "" } {
            if { $mode == "clone_dir" } {
    	    	set RUNDIR "${origin_dir}_${RUN_NAME}"
            } else {
    		    set RUNDIR "${NET_VER}_${REVISION}_${RUN_NAME}"
            }
        } else {
            if { $mode == "clone_dir" } {
    	    	set RUNDIR "${origin_dir}_clone"
            } else {
    	    	set RUNDIR "${NET_VER}_${REVISION}"
            }
        }
	} else {
		while { 1 } {
			puts -nonewline "Write BE-Comment (Less than 80 characters) >> "
			flush stdout
			gets stdin RUN_NAME

			if { $PROJECT == "ADP620" } {  
				break
			} else { 
				if { [string length $RUN_NAME] > 80 } { continue } else { break }
			}
		}

		set RUNDIR "${NET_VER}_${REVISION}_${RUN_NAME}-BE"
	}

	puts -nonewline "Write Description >> "
	flush stdout
	gets stdin description


	if { [info exists origin_dir] && [file exists $origin_dir] == "-1" } {
		puts "Error: Target Directory ($origin_dir) is not valid input!! // not exist" 
	} elseif { [lsearch $ls "${NET_VER}_${REVISION}_${RUN_NAME}-BE"] != "-1" } {
		puts "Error: Directory name ($RUN_NAME) is not valid input!! // exsited dir"
	} else {
		if { $mode == "create_dir" } { 
			create_dir 
			puts "<ADF_INFO> mpnr (create) finished"			
		}
		if { $mode == "clone_dir"  } { 
			set origin_dir [exec readlink -e $origin_dir] 
			puts "\n<ADF_INFO> Cloning $RUNDIR (ORIGIN: $origin_dir)\n"
			puts ""

			# This version does not report errList.  
			set PnR_errList ""
			set Post_errList ""
			set Eco_errList ""
			set Eco_Post_errList ""

			# Flag
			set PnR_flag 0
			set flag_post_folder 0

			# Execute clone
			clone_common
			foreach step $origin_steps {
				clone_dir $step
			}
			set ADF_report_list {}
			if { $TOOL == "innovus" } {
				set pnr_step_list "read_design init place_opt cts cts_opt route route_opt chip_finish"
			} elseif { $TOOL == "icc2" || $TOOL == "fc" } {
				set pnr_step_list "read_design floorplan powerplan init compile place_opt clock_opt_cts clock_opt_opto route_auto route_opt chip_finish"
			}
			set report_flag 0
				
			foreach origin_step $origin_steps {
				if {$origin_step in $pnr_step_list && $report_flag == 0} {
					foreach step $pnr_step_list { 
						lappend ADF_report_list $step
						if { $step == $origin_step } { set report_flag 1; break }
					}
				} else {
					lappend ADF_report_list $origin_step
				}
			}

			set ADF_info_string "<ADF_INFO> ("
			set ADF_info_string "${ADF_info_string}[join $ADF_report_list " / "]) cloning is finished"

			puts ""
			puts $ADF_info_string
			puts ""
		}
		if { [info exists fc_pi] && $fc_pi } {
			exec sed -i "/FC_FLOW_TYPE/s/FC_COMPILE_PLACE_OPT/FC_COMPILE_ONLY/" $RUNDIR/user_design_setup.tcl
            if { [file exists [exec pwd]/$RUNDIR/plug/fc/compile] } { exec ln -s [exec pwd]/$RUNDIR/plug/fc/compile $RUNDIR/con }
		} else {
			file mkdir $OUTFD_DIR/LOG
			exec echo "[exec date "+%y%m%d_%H%M%S"]\t$TOP_MODULE\t[exec pwd]/$RUNDIR" >> $OUTFD_DIR/LOG/rundir.pd.list
			if { [file owned $OUTFD_DIR/LOG]                } { exec chmod 770 $OUTFD_DIR/LOG                }
			if { [file owned $OUTFD_DIR/LOG/rundir.pd.list] } { exec chmod 660 $OUTFD_DIR/LOG/rundir.pd.list }
		}
	} 
} else {
	puts "Error: You should move to ${IMPL_DIR}/<TOP>/SOC/<BLOCK>/<TOOL>"
}
