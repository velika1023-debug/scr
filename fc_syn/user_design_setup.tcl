###################################################################################################
# File               : user_design_setup.tcl                                                      #
# Author             : ADT-DT (jblee)                                                             #
# Description        : Things the user can control                                                #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.20                                                                 #
# Script Version     : 1.1                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
#         2025.08.20 - Add USER_NETLIST, USET_COMPILE_END_STAGE                                   #
###################################################################################################

#################################################################################################
# compile_fusion stage control
# stage : initial_map -> logic_opto -> initial_place -> initial_drc -> initial_opto -> final_place -> final_opto
#
# COMPILE_FINAL_STAGE:
#   true  : Run from initial_map to final_opto
#   false : Run from initial_map to initial_opto
# USER_COMPILE_END_STAGE:
#   The default is "", From initial_map to final_opto, select the end stage according to your needs
#   When this variable is set, no report and output will be generated.
#################################################################################################
set COMPILE_FINAL_STAGE     "false"
set USER_COMPILE_END_STAGE  ""


#################################################################################################
# Essential variable settings for library setup & physical setup
# You should complete following variable settings before running Fusion Compiler
#################################################################################################
set TECHNOLOGY_NODE           ""  ;# 2nm/3nm/4nm/5nm/8nm/14nm.

set REUSE_NDM                 "false"  ;# If the library has already been created, the user can choose to regenerate or reuse it.
set NDM_DIR                   ""  ;# Path to the NDM directory. If left empty, the default design kit (DK) path will be used
set USER_NDM_REFERENCE_LIB    "[glob -nocomplain ${NDM_DIR}/*ndm]"  ;# List of NDM reference libraries

set TECH_FILE                 ""  ;# ICC technology file path
set MAP_FILE                  ""  ;# TLUPlus mapping file path

set MIN_ROUTING_LAYER         ""  ;# Minimum routing layer name (ex. M1)
set MAX_ROUTING_LAYER         ""  ;# Maximum routing layer name (ex. D13)

set HORIZONTAL_LAYER          [list]  ;# List of horizontal routing layers (ex. [list M1 M3 D5 D7 D9 D11 D13 IB])
set VERTICAL_LAYER            [list]  ;# List of vertical routing layers   (ex. [list M2 M4 D6 D8 D10 D12 IA LB])


#################################################################################################
# Essential variable setting for reading a design and constraining the design.
#################################################################################################
set GEN_ABS               "false"     ;# Generation of abstraction DB
set GEN_ABS_TIMING_LEVEL  "boundary"  ;# none/boundary/compact/full_interface
                                      ;# none           : No timing (physical-only)
                                      ;# boundary       : Minimal boundary timing
                                      ;# compact        : Critical boundary setup/hold paths
                                      ;# full_interface : Almost full boundary timing

set GEN_CAP       "false"  ;# Generation of spef
set GEN_SDF       "false"  ;# Generation of sdf
set GEN_DEF       "false"  ;# Generation of def
set GEN_FULL_UPF  "false"  ;# Generation of full-chip UPF

# Set the DB type of the sub-block to be loaded, Guide -> https://redmine.adtek.co.kr/issues/8412#note-2
set IMPL_BLK_INFO  "NONE"
set IMPL_BLK_NLIB  "NONE"

set IMPL_BLK_TIMING_IGNORE "true" ;# If set to true,all internal R2R timing paths inside sub-blocks will be disabled

# ICG Setup
set MAX_ICG_FANOUT   ""  ;# max fanout of clock gating cell
set MIN_ICG_FANOUT   ""  ;# min fanout of clock gating cell
set ICG_NAME         ""  ;# name of clock gating cell
set ICG_STAGES       "3"  ;# stage of clock gating

# ICG Opt
set ICG_OPT_EST_LATENCY  "true"  ;# Enables using estimated latency during clock gating optimization 
set ICG_OPT_LEVEL_EXP    "true"  ;# Enables expanding clock gates beyond defined levels
set ICG_OPT_MERGE        "true"  ;# Enables merging clock gates during optimization
set ICG_OPT_EARLY_CTS    "false"  ;# Controls ICG optimization that performs trial clock synthesis

# constraint 
set is_msdc  "0"  ;# merged sdc  enable ( 0 - disable (mode-dependent)  , 1 - enable) 
set user_max_fanout "0"

# UPF file
set IMPL_UPF            "$INDB_DIR/upf/${TOP_DESIGN}.upf"


#####################################################################################################
# Setup only when using the "-vcs" option in analyze
# Specify the top design and format
# ca53 ex> set VCS_OPTION "-format sverilog $INDB_DIR/RTL_DIR/cortexa53_mbist/verilog/CORTEXA53.v
#####################################################################################################
set USER_VCODE_LIST    ""  ;# User-defined path for vcode_list
set USER_NETLIST       ""  ;# User-defined path for Netlist

set IMPL_VCS_OPTION    ""  ;# analyze vcs option
set IMPL_PARAMETER     ""  ;# Parameter optional for elaborate
set IMPL_ELAB_LEVEL    "${TOP_DESIGN}"  ;# Specifiy top level in eralobation
set IMPL_RENAME_DESIGN ""  ;# This variable is used to change the name of the current design.

# set_top_module
set USER_STM           "false"  ;# Enable user-define module for 'set_top_module'
set USER_STM_HDL_FILE  ""  ;# Specify hdl_file of user-define module


##########################################################################################
# MCMM settings
# Please fill your MCMM scenario settings.
# You don't need to fill following variables if you are running single scenario synthesis. 
#
# Please note that below variables should be described using same serial order.
#
# Example)
# Single scenario
#	set SCENARIO_NAMES     "SCN0            "  ;# Fill in your scenario names
#	set OPCON_NAME         "SCN0_OPCON_NAME "  ;# Operating condition name for each scenario
#	set OPCON_LIB_NAME     "SCN0_LIBNAME    "  ;# Library name associated with each operating condition
#	set TLUPLUS_MAX_FILES  "SCN0_TLUP       "  ;# Only supported in Topographical mode or MCMM
#	set OPT_TARGET         ""  ;# Only supported in Topographical mode or MCMM
#	                                             Specify optimization targets for each scenario: S (Setup), H (Hold), L (Leakage), D (Dynamic)
#	set CONSTRAINTS_FILES  ""  ;# If you want to control the SDC, fill out this variable.
#	                                             If not, leave it blank. Sdc will control by ${COMMON_SDC}/common_sdc.tcl.
#
# MCMM scenario
#	set SCENARIO_NAMES     "SCN0             SCN1            "
#	set OPCON_NAME         "SCN0_OPCON_NAME  SCN1_OPCON_NAME "
#	set OPCON_LIB_NAME     "SCN0_LIBNAME     SCN1_LIBNAME    "
#	set OPT_TARGET         "SCN0_TARGET      SCN1_TARGET     "
#	set CONSTRAINTS_FILES  "SCN0_CONS.tcl    SCN1_CONS.tcl   "
#	set TLUPLUS_MAX_FILES  "SCN0_TLUP        SCN1_TLUP       "
# 
##########################################################################################
set SCENARIO_NAMES     ""  ;# ex) misn.sspg_0p6750v_m40c_SigCmaxDP_ErPlus_GlobalRvia
set OPCON_NAME         ""  ;# ex) sspg_0p6750v_m40c
set OPCON_LIB_NAME     ""  ;# ex) ln05lpe_sc_s6t_flk_slvt_c54l08_sspg_nominal_max_0p6750v_m40c
set TLUPLUS_MAX_FILES  ""  ;# ex) /prj/..../ln05lpe_15M_4Mx_9Dx_2Iz_LB_SigCmaxDP_ErPlus_MOL_nominal_detailed.tlup
set CONSTRAINTS_FILES  ""  ;# ex) ${COMMON_SDC}/common_sdc.tcl
set OPT_TARGET         ""  ;# ex) S L


##########################################################################################
# Select OCVM MODE
##########################################################################################
set is_AOCVM       "false"  ;# Enables usage of Advanced OCV (AOCV) modeling for timing analysis  
set is_POCVM       "false"  ;# Disables usage of Parametric OCV (POCV) modeling for timing analysis  
set CORNER_SIGMA   "4.5"  ;# Sets the sigma value for Parametric OCV corner analysis


##########################################################################################
# DFT strategy
#
# DFT_FLOW
#   in_compile   : DFT insertion after logic_opto
#   post_compile : DFT insertion after initial_opto
#
# COMPILE_OPT_SCAN_CHAIN
#   If set to true, scan chain optimization is performed at every compile_fusion step, which increases runtime.
#
# SCAN_DEF_FILE
#   Specify the path to the scan DEF file.
#   This variable is optional and does not need to be set if no scan DEF file is used.
##########################################################################################
set DFT_INSERTION    "false"       ;# true/false
set DFT_FLOW         "in_compile"  ;# in_compile/post_compile

set COMPILE_OPT_SCAN_CHAIN "false" ;# true/false
set SCAN_DEF_FILE          ""      ;# /prj/..../${TOP_DESIGN}.scandef

set USER_DFT_SCRIPT  ""  ;# Path to user-defined DFT script


##########################################################################################
# Select compile strategy 
##########################################################################################
set USE_SCANFF                  "true"  ;# true/false. Must be true if DFT insertion is required to use scan flip-flops  
set USE_BOUNDARY_OPT            "false"  ;# true/false. Enables optimization across hierarchical boundaries  
set USE_AUTOUNGROUP             "false"  ;# true/false. Automatically ungroups hierarchy during compile for optimization  
set USE_SEQ_INVERSION           "false"  ;# true/false. Allows sequential cell inversion for optimization purposes  
set USE_DEAD_LOGIC_OPT          "false"  ;# true/false. Removes unused or redundant logic to reduce area/power  
set USE_HIGH_AREA_EFFORT        "false"  ;# true/false. Increases compile effort to minimize area usage  
set USE_CCD                     "false"  ;# true/false. Enables CCD (Clock Concurrent Data) optimization during place/route
set USE_EWIMPY                  "false"	 ;# true/false. Set true when using E08 cells in LN05LPE* process


##########################################################################################
# Select multi-bit strategy 
##########################################################################################
set USE_MULTIBIT                "false"  ; # true/false
set multibit_width_MIN          "1"
set multibit_width_MAX          "6"

set MBIT_EXCLUDE_LIST           "" ;# Path to file containing the exclusion list

set MBIT_OPT_MODE               "timing"  ;# timing | area_power


##########################################################################################
# Physical information
##########################################################################################
set PHYSICAL_CONSTRAINT_TYPE        ""  ;# DEF/TCL_FP/AUTO_FP, When left as "", the tool defaults to auto floorplaning.

# DEF
set DEF_INPUT_FILE                  "${OUTFD_DIR}/${TOP_DESIGN}/${INDB_VER}/${PNR_TOOL}/[set ${TOP_DESIGN}(NET_REVISION_POST)]/[set ${TOP_DESIGN}(NET_ECO_NUM)]/output/${TOP_DESIGN}.phy_syn.def.gz"  ;# Path to input file in .def.gz format 
set DEF_SITE_MAPPING                "{ def_site unit }"  ;# def_site and unit must have the same size.
                                    ;# When defined as "AUTO", the mapping is automatically performed by referring to the LEF file.

# TCL_FP
set TCL_FP_INPUT_FILE               ""  ;# Tcl floorplan script (e.g., generated by 'write_floorplan' in FC/ICC2)

# AUTO_FP
set AUTO_FP_CORE_UTIL               "0.7"  ;# Target core utilization ratio (e.g., 0.70 = 70%)
set AUTO_FP_CORE_OFFSET             "0.34"  ;# Offset between core area and block boundary (e.g., 0.34 = 0.34um)


##########################################################################################
# Optional variable settings 
##########################################################################################
set GEN_INIT_STAGE_RPT  "true"  ;# true/false. Generates report/output for 'initial_opto' stage when COMPILE_FINAL_STAGE is true

# reuse flow
set REUSE_ELAB          "false"  ;# true/false. Reuses elaboration results from a previous run  
set REUSE_ELAB_NLIB     ""  ;# Path to the reused elaboration nlib file (used only if REUSE_ELAB is true)  

# qor data
set WRITE_QOR_DATA      "false"  ;# true/false. Writes QoR data to files for analysis


##########################################################################################
# SAIF Flow
# to run SAIF low power optimization flow, please set SAIF_FILE, STRIP_PATH correctly
##########################################################################################
set USE_SAIF   "false" ;# Set to true to enable using SAIF information
set SAIF_FILE  ""      ;# Path to the input SAIF file

set USE_SAIF_MAP_FILE  ""      ;# Use an existing SAIF map file if available
set SKIP_NAME_MAPPING  "false" ;# When true, read_saif uses -ignore_name_mapping (same netlist SAIF, no mapping needed)

set STRIP_PATH   ""  ;# Top instance name in SAIF, used to align hierarchy with the design
set TARGET_INST  ""  ;# Instance where SAIF activity will be applied, defaults to current block if empty

set GENERATE_SAIFMAP_WITHOUT_SAIF  ""      ;# Initialize SAIF map when there is no SAIF_FILE


###################################################################################################
#-- Define Vth group
#-- ex> If 'DK_TYPE' is set to 'SEC'  set_PATTERN(RVT) "*/*_RVT*"
#-- ex> If 'DK_TYPE' is set to 'ARM'  set_PATTERN(RVT) "*/*TR_*"
#-- ex> If 'DK_TYPE' is set to 'SNPS' set_PATTERN(RVT) "*/*BSVT*"
###################################################################################################
set LIB_PATTERN(HVT)  "" ; set LIB_PATTERN(HVT_WIMPY)  ""
set LIB_PATTERN(RVT)  "" ; set LIB_PATTERN(RVT_WIMPY)  ""
set LIB_PATTERN(MVT)  "" ; set LIB_PATTERN(MVT_WIMPY)  ""
set LIB_PATTERN(LVT)  "" ; set LIB_PATTERN(LVT_WIMPY)  ""
set LIB_PATTERN(VLVT) "" ; set LIB_PATTERN(VLVT_WIMPY) ""
set LIB_PATTERN(SLVT) "" ; set LIB_PATTERN(SLVT_WIMPY) ""
set LIB_PATTERN(ULVT) "" ; set LIB_PATTERN(ULVT_WIMPY) ""


##########################################################################################
# Optional FC variable settings 
##########################################################################################
set NUM_CPUS                    "16"


##########################################################################################
# Optional settings for Constraint files
##########################################################################################
# Synthesis stage
set BEFORE_INIT_MAP    "${RUN_DIR}/con/before_initial_map.tcl"
set BEFORE_LOGIC_OPTO  "${RUN_DIR}/con/before_logic_opto.tcl"
set AFTER_LOGIC_OPTO   "${RUN_DIR}/con/after_logic_opto.tcl"

# Initial stage
set BEFORE_INIT_PLACE  "${RUN_DIR}/con/before_initial_place.tcl"
set BEFORE_INIT_DRC    "${RUN_DIR}/con/before_initial_drc.tcl"
set BEFORE_INIT_OPTO   "${RUN_DIR}/con/before_initial_opto.tcl"
set AFTER_INIT_OPTO    "${RUN_DIR}/con/after_initial_opto.tcl"

# final stage
set BEFORE_FINAL_PLACE "${RUN_DIR}/con/before_final_place.tcl"
set BEFORE_FINAL_OPTO  "${RUN_DIR}/con/before_final_opto.tcl"
set AFTER_FINAL_OPTO   "${RUN_DIR}/con/after_final_opto.tcl"
