###################################################################################################
# File               : LN05LPE_place_spacing_rules.tcl                                            #
# Author             : ADT-DT (jblee)                                                             #
# Description        : Physical option setting                                                    #
# Usage              :                                                                            #
# Init Release Date  : 2025.11.18                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################


# /dk/SF2/SEC/SF5A/DM/Foundry/Samsung_Foundry_LN05LPE_SFDK_PnR_Methodology_FusionCompiler_REV1.05/Script/Script/Script/rm_tech_scripts/init_design.tcl.5nm_s.place_spacing_rules
# puts "FRM_INFO: Running script [info script]\n"
if { $DK_TYPE != "SEC" } {
    puts "Information_ADF: The spacing rule in this Tcl file is only applied when using the \"SEC\" DK_TYPE"
	return
}


##########################################################################################
# Tool: IC Compiler II
# Script: init_design.tcl.5nm_s.place_spacing_rules
# Version: U-2023.12-SP6
# Copyright (C) 2014-2021 Synopsys, Inc. All rights reserved.
##########################################################################################
## Identify 6T or 7.5T sitedefs
set allSiteDefs [get_site_defs -filter is_default]

set is75track 0
set is6track 0

if { ![info exist USE_EWIMPY] } {
	set USE_EWIMPY "0"
}

foreach_in_collection siteDef $allSiteDefs {
	set siteHeight [get_attribute -quiet $siteDef height]
	set siteWidth [get_attribute -quiet $siteDef width]
	if {$siteHeight == 0.27 && $siteWidth == 0.06} {
		set is75track 1
	} elseif {$siteHeight == 0.216 && $siteWidth == 0.054} {
		set is6track 1
	}
}

if {$is6track} {
	## DO NOT ALLOW 1cpp filler placed consecutively(RC2.W.5.or, FILLERRC.C.4, FILLERRC.C.2).
	set_placement_spacing_label -name {1cpp_filler}  -side both -lib_cells [get_lib_cells */FILL1P*]
	set_placement_spacing_rule -labels {1cpp_filler 1cpp_filler} {0 1}
	# to check if Ewimpy is used
	if { $USE_EWIMPY == 1 } {
		set wimp "E08"
	} elseif { $USE_EWIMPY == 0 } {
		set wimp "L10"
	}
	## ICC2 has limitation could not considered spacing constraint to filler cell during placement(legalization), 
	## So, workaround to appying spacing rule to 2cpp inverters for preventing 1CPP filler abutment.
	set 2cpp_wimpy    [get_lib_cells -quiet -f {width == 0.108 && block_name =~ *_C54${wimp} && design_type == lib_cell}]
	set 2cpp_nonwimpy [get_lib_cells -quiet -f {width == 0.108 && block_name =~ *_C54L08 && design_type == lib_cell}]
	if {[sizeof_collection $2cpp_wimpy]} {
		set_placement_spacing_label -name {2cpp_inv_wimpy}      -side both -lib_cells $2cpp_wimpy
	}
	if {[sizeof_collection $2cpp_nonwimpy]} {
		set_placement_spacing_label -name {2cpp_inv_non_wimpy}  -side both -lib_cells $2cpp_nonwimpy
	}
	set_placement_spacing_rule -labels {2cpp_inv_wimpy 2cpp_inv_non_wimpy} {2 2}
	
	set 2cpp_lvt  [get_lib_cells -quiet -f {width == 0.108 && block_name =~ *_S6TL_* && design_type == lib_cell}]
	set 2cpp_rvt  [get_lib_cells -quiet -f {width == 0.108 && block_name =~ *_S6TR_* && design_type == lib_cell}]
	set 2cpp_slvt [get_lib_cells -quiet -f {width == 0.108 && block_name =~ *_S6TSL_* && design_type == lib_cell}]
	set 2cpp_hvt [get_lib_cells -quiet -f {width == 0.108 && block_name =~ *_S6TH_* && design_type == lib_cell}] 
	set 2cpp_ulvt [get_lib_cells -quiet -f {width == 0.108 && block_name =~ *_S6TUL_* && design_type == lib_cell}] 
	if {[sizeof_collection $2cpp_lvt]} {
		set_placement_spacing_label -name {2cpp_inv_lvt}   -side both -lib_cells $2cpp_lvt
	}
	if {[sizeof_collection $2cpp_rvt]} {
		set_placement_spacing_label -name {2cpp_inv_rvt}   -side both -lib_cells $2cpp_rvt
	}
	if {[sizeof_collection $2cpp_slvt]} {
		set_placement_spacing_label -name {2cpp_inv_slvt}  -side both -lib_cells $2cpp_slvt
	} 
	if {[sizeof_collection $2cpp_hvt]} {
		set_placement_spacing_label -name {2cpp_inv_hvt}  -side both -lib_cells $2cpp_hvt
	}
	
	set_placement_spacing_rule -labels {2cpp_inv_lvt 2cpp_inv_hvt} {2 2}
	set_placement_spacing_rule -labels {2cpp_inv_lvt 2cpp_inv_rvt} {2 2}
	set_placement_spacing_rule -labels {2cpp_inv_lvt 2cpp_inv_slvt} {2 2}
	set_placement_spacing_rule -labels {2cpp_inv_rvt 2cpp_inv_slvt} {2 2}
	set_placement_spacing_rule -labels {2cpp_inv_rvt 2cpp_inv_hvt} {2 2}
	set_placement_spacing_rule -labels {2cpp_inv_slvt 2cpp_inv_hvt} {2 2}
	
	if {[sizeof_collection $2cpp_ulvt]} {
		set_placement_spacing_label -name {2cpp_inv_ulvt}  -side both -lib_cells $2cpp_ulvt
		set_placement_spacing_rule -labels {2cpp_inv_ulvt 2cpp_inv_hvt} {2 2}
		set_placement_spacing_rule -labels {2cpp_inv_ulvt 2cpp_inv_rvt} {2 2}
		set_placement_spacing_rule -labels {2cpp_inv_ulvt 2cpp_inv_slvt} {2 2}
		set_placement_spacing_rule -labels {2cpp_inv_ulvt 2cpp_inv_lvt} {2 2}
	}
	
	## DO NOT ALLOW abutment between 1cpp filler and GQ cell.
	if { $wimp == "L10" } {
		set all_wimpy_cells [get_lib_cells -quiet */*${wimp}]
		set all_non_wimpy_cells [get_lib_cells -quiet */*L08]
		
		if {[sizeof_collection $all_wimpy_cells]} {
			set_placement_spacing_label -name {all_wimpy} -side both -lib_cells $all_wimpy_cells
		}
		if {[sizeof_collection $all_non_wimpy_cells]} {
			set_placement_spacing_label -name {all_non_wimpy}  -side both -lib_cells $all_non_wimpy_cells
		}
		set_placement_spacing_rule -labels {all_wimpy 2cpp_inv_non_wimpy} {1 1}
		set_placement_spacing_rule -labels {all_non_wimpy 2cpp_inv_wimpy} {1 1}
	}
	
	
	
	set 2cpp_1fin [get_lib_cells -quiet -f {width == 0.108 && lib_name =~ *flk1fin*}]
	if {[sizeof_collection $2cpp_1fin]} {
		set_placement_spacing_label -name {2cpp_1fin_cell}  -side both -lib_cells $2cpp_1fin
	}
	set all_lib_cells [get_lib_cells */*]
	#remove_from_collection $all_lib_cells [get_lib_cells -f {design_type == filler}]
	set_placement_spacing_label -name {all_lib_cell}  -side both -lib_cells $all_lib_cells
	set_placement_spacing_rule -labels {2cpp_1fin_cell all_lib_cell} {1 1}
	
	set 1fin_filler [get_lib_cells -quiet */FILL1P1*]
	append_to_collection 1fin_filler [get_lib_cells -quiet */FILL1P*N1*]
	if {[sizeof_collection $1fin_filler]} {
		set_placement_spacing_label -name {filler_w_1fin}  -side both -lib_cells $1fin_filler
		set_placement_spacing_rule -labels {2cpp_1fin_cell filler_w_1fin} {0 0}
	}

} elseif {$is75track} {
	## Prohibit abutment between 1-CPP filler and 2-CPP filler to prevent Wide-FC pattern.
	set 75t_1cpp_filler [get_lib_cells -quiet */FILL1P*]
	if {[sizeof_collection $75t_1cpp_filler]} {
		set_placement_spacing_label -name {1cpp_filler}  -side both -lib_cells [get_lib_cells */FILL1P*]
		set_placement_spacing_label -name {2cpp_filler}  -side both -lib_cells [get_lib_cells */FILL2_*]
		set_placement_spacing_rule -labels {1cpp_filler 2cpp_filler} {0 0}
		set_placement_spacing_rule -labels {2cpp_filler 2cpp_filler} {0 0}
	}

}


# puts "FRM_INFO: Completed script [info script]\n"
