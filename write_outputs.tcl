###################################################################################################
# File               : write_outputs.tcl                                                          #
# Author             : ADT-DT (jblee)                                                             #
# Description        : generate outputs                                                           #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.20                                                                 #
# Script Version     : 1.1                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
#         2025.08.20 - Add GEN_NET_FOR_DEF                                                        #
###################################################################################################
###########################################################################################
## Pre configuration
###########################################################################################
if { $DFT_INSERTION == "true" } {
          if { [string match "dft"             ${DESIGN_STAGE}] && !$COMPILE_FINAL_STAGE } { set Final_stage 1
    } elseif { [string match "to_final_opto"   ${DESIGN_STAGE}]                          } { set Final_stage 1 }
} else {
          if { [string match "to_initial_opto" ${DESIGN_STAGE}] && !$COMPILE_FINAL_STAGE } { set Final_stage 1 
	} elseif { [string match "to_final_opto"   ${DESIGN_STAGE}]                          } { set Final_stage 1 }
}


#################################################################################
#  Change_Name
#################################################################################
change_names -rules verilog     -hierarchy -verbose  > ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.change_names
change_names -rules sec_verilog -hierarchy -verbose >> ${REPORT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.change_names

#################################################################################
# Write output DB
#################################################################################
# Write out design in .v format and .ddc format
write_verilog "${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.v" \
-exclude {leaf_module_declarations pg_objects corner_cells pad_spacer_cells end_cap_cell well_tap_cells filler_cells flip_chip_pad_cells}
exec ln -sf  ${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.v   ${OUTPUT_DIR}/${TOP_DESIGN}.v  

#################################################################################
# Check User Dont touch, Use, Sizeonly constraint
# If this Tcl script is not sourced, the summary report may not be generated correctly
#################################################################################
source ${COMMON_TCL}/fc_syn/check_con.tcl

# Write out floorplan data, spef, sdf, and sdc
if {$GEN_DEF} {
    write_def -version 5.8 -compress gzip "${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.def.gz" \
    -include {cells blockages bounds}
    exec ln -sf ${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.def.gz ${OUTPUT_DIR}/${TOP_DESIGN}.def.gz
}

if {$USE_MCMM} {
	foreach_in_collection scenario [all_scenarios] {
        set scn_name [get_object_name $scenario]
  	    current_scenario ${scn_name}
        if {$GEN_CAP} {
        	write_parasitics -compress -output ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.$scn_name.spef.gz
        }
        if {$GEN_SDF} {
            write_sdf -compress gzip ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.$scn_name.sdf.gz
        }
		write_sdc -nosplit -output ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.$scn_name.sdc
        exec ln -sf  ${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.$scn_name.sdc ${OUTPUT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.$scn_name.sdc
	}
} else {
    if {$GEN_CAP} {
	    write_parasitics -compress -output ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.spef.gz
    }
    if {$GEN_SDF} {
        write_sdf -compress gzip ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.sdf.gz
    }
	 write_sdc -nosplit -output ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.sdc
     exec ln -sf  ${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.sdc ${OUTPUT_DIR}/${TOP_DESIGN}.${DESIGN_STAGE}.sdc
}

# Write UPF
if {[file exist $IMPL_UPF] && [info exists Final_stage]} {
    save_upf                                 ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.syn.upf
    exec ln -sf ${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.syn.upf            ${OUTPUT_DIR}/${TOP_DESIGN}.upf
	if { $GEN_FULL_UPF } {
	    save_upf  -full_chip                     ${OUTPUT_DIR}/${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.syn.full.upf
	    exec ln -sf ${TOP_DESIGN}.${RPT_POSTFIX}.${DESIGN_STAGE}.syn.full.upf       ${OUTPUT_DIR}/${TOP_DESIGN}.full.upf
	}
}

# Write Saif Map
if {($USE_SAIF || $GENERATE_SAIFMAP_WITHOUT_SAIF == "true") && [info exists Final_stage]} {
  # Write out SAIF name mapping file for PrimeTime-PX and ICC2
  saif_map -type ptpx -essential -write_map ${OUTPUT_DIR}/${TOP_DESIGN}.mapped.saif.ptpx.map
  saif_map -write_map ${OUTPUT_DIR}/${TOP_DESIGN}.mapped.saif.dc.map
}

if {$DFT_INSERTION && [info exists Final_stage]} {
	write_scan_def -output ${OUTPUT_DIR}/${TOP_DESIGN}.scandef
}

if {$GEN_NET_FOR_DEF} {
    puts "Information_ADF : Synthesis Only Map Flow, Skip Report Step"
    exit 1
}
