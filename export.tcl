###################################################################################################
# File               : export.tcl                                                                 #
# Author             : ADT-DT (jblee)                                                             #
# Description        : Export data in RUNDIR to outfd                                             #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################

# If OUTFD_CONFIG_UPDATE Value is set to 0, OUTFD_CONFIG_FILE is not updated.
puts "#-------------------------------#"
puts ""
puts "Do you want to replace Gen3 version with lastest ? (y or n) : "
puts ""
puts "#-------------------------------#"
puts -nonewline "Answer y or n : "
flush stdout
gets stdin OUTFD_CONFIG_UPDATE
    
# Export Directory Check & Create
exec echo "Copying ${DESIGN} synthesis results into ${EXPORT_DIR} " > export.log
if { ![file exists ${EXPORT_DIR}] } {
    file mkdir ${EXPORT_DIR}

    set WS_COFIG_FILE        "${PROJECT_ENV}/DESIGN/${DESIGN}.config"    
    set OUTFD_CONFIG_FILE    "${OUTFD_DIR}/CONFIG/PI/${DESIGN}.config"
    
    if { ${OUTFD_CONFIG_UPDATE} == "y" } {
        if { ![file exist $OUTFD_CONFIG_FILE] } {
            puts "<INFO> : == Design.config Copy (W/S --> OUTFD) =="
            puts "    Design.config file does not exist."
            puts "    Copy the config file that currently exists in WorkSpace."
            set DIR_NAME [file dirname "$OUTFD_CONFIG_FILE"]
            set UMASK_CMD "umask 002 && mkdir -p $DIR_NAME" ;# The umask setting is temporarily set to 002.
            exec sh -c $UMASK_CMD
            exec cp -rf $WS_COFIG_FILE $OUTFD_CONFIG_FILE
            exec echo "Copy ${WS_COFIG_FILE} into ${DIR_NAME} " >> export.log

        } else {

            puts "<INFO> : == Design.config modify ( In OUTFD ) =="
            puts "    Design.config file exists."
            puts "    Update the outfed_config file with the currently set information."
            exec sed -i "s/^PRE_${DESIGN}_REVISION_SYN\s.*/PRE_${DESIGN}_REVISION_SYN  ${EXP_TAG}/g" ${OUTFD_CONFIG_FILE}
            exec echo "Update the version info in ${OUTFD_CONFIG_FILE} " >> export.log
        }

        # Gen3 Latest Link path
        if { [file exists ${EXPORT_DIR}/latest] } {
            exec rm -rf ${EXPORT_DIR}/latest
        }
        puts "<INFO> : == Latest link modify ( In OUTFD ) =="
        exec ln -sf ${EXPORT_DIR} ${OUTFD_DIR}/${DESIGN}/${INDB_VER}/fc_syn/latest

    } else {
        puts "<INFO> : == Neither the CONFIG nor the latest link will be updated for Gen3.  =="
        puts "<INFO> : == Neither the CONFIG nor the latest link will be updated for Gen3.  =="
        puts "<INFO> : == Neither the CONFIG nor the latest link will be updated for Gen3.  =="
        puts "<INFO> : == Neither the CONFIG nor the latest link will be updated for Gen3.  =="
        exec echo "Neither the CONFIG nor the latest link will be updated for Gen3." >> export.log
    }

    exec echo "exported_by_${USER} from: ${RUN_DIR}"        > ${EXPORT_DIR}/EXPORT.INFO

    # Directory Copy
    #== log
    puts -nonewline "\n<INFO> Copy log ... "
    file copy -force ${RUN_DIR}/${LOG_DIR}                     ${EXPORT_DIR}
    set fileNum [exec find ${EXPORT_DIR}/${LOG_DIR} -maxdepth 1 -type f | wc -l]
    puts "done! (${fileNum}ea)"
    exec echo "log files(${fileNum}ea)"                     >> ${EXPORT_DIR}/EXPORT.INFO
    exec tree -L 1 ${EXPORT_DIR}/${LOG_DIR}                 >> ${EXPORT_DIR}/EXPORT.INFO
    exec echo ""                                            >> ${EXPORT_DIR}/EXPORT.INFO
    exec echo "Copy done(log) - ${EXPORT_DIR}/${LOG_DIR}"   >> export.log

    #== report
    puts -nonewline "\n<INFO> Copy report ... "
    file copy -force ${RUN_DIR}/${REPORT_DIR}                  ${EXPORT_DIR}
    set fileNum [exec find ${EXPORT_DIR}/${REPORT_DIR} -maxdepth 1 -type f | wc -l]
    puts "done! (${fileNum}ea)"
    exec echo "report files(${fileNum}ea)"                  >> ${EXPORT_DIR}/EXPORT.INFO
    exec tree -L 1 ${EXPORT_DIR}/${REPORT_DIR}              >> ${EXPORT_DIR}/EXPORT.INFO
    exec echo ""                                            >> ${EXPORT_DIR}/EXPORT.INFO
    exec echo "Copy done(report) - ${EXPORT_DIR}/${REPORT_DIR}" >> export.log

    #== output
    puts -nonewline "\n<INFO> Copy output ... "
    file copy -force ${RUN_DIR}/${OUTPUT_DIR}                  ${EXPORT_DIR}
    set fileNum [exec find ${EXPORT_DIR}/${OUTPUT_DIR} -maxdepth 1 | wc -l]
    puts "done! (${fileNum}ea)"
    exec echo "output files(${fileNum}ea)"                  >> ${EXPORT_DIR}/EXPORT.INFO
    exec tree -L 1 ${EXPORT_DIR}/${OUTPUT_DIR}              >> ${EXPORT_DIR}/EXPORT.INFO
    exec echo ""                                            >> ${EXPORT_DIR}/EXPORT.INFO
    exec echo "Copy done(output) - ${EXPORT_DIR}/${OUTPUT_DIR}" >> export.log

    #== con
    puts -nonewline "\n<INFO> Copy con ... "
    file copy -force ${RUN_DIR}/${CON_DIR}                     ${EXPORT_DIR}
    set fileNum [exec find ${EXPORT_DIR}/${CON_DIR} -maxdepth 1 -type f | wc -l]
    puts "done! (${fileNum}ea)"
    exec echo "con files(${fileNum}ea)"                     >> ${EXPORT_DIR}/EXPORT.INFO
    exec tree -L 1 ${EXPORT_DIR}/${CON_DIR}                 >> ${EXPORT_DIR}/EXPORT.INFO
    exec echo ""                                            >> ${EXPORT_DIR}/EXPORT.INFO
    exec echo "Copy done(con) - ${EXPORT_DIR}/${CON_DIR}"   >> export.log


    file copy -force ${RUN_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt ${EXPORT_DIR}
    exec ln -svf     ${RUN_DIR}                                ${EXPORT_DIR}

    # Gen3 Report Link
    if { ![file exists ${EXPORT_DIR}/to_ADF] } {
        file mkdir ${EXPORT_DIR}/to_ADF
    }

    set Gen3_list " \
    ${EXPORT_DIR}/report/${DESIGN}.final.user_dont_touch.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.final.user_dont_use.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.final.clock_gating.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.final.global_timing.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.final.mbit.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.final.physical.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.final.power.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.final.transformed_register.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.final.vth_ratio.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.adf_info.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.check_mv_design.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.check_timing.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.clocks.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.latches.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.include_lockup_latches.rpt \
    ${EXPORT_DIR}/report/${DESIGN}.unmapped.rpt \
    ${EXPORT_DIR}/report/runtime.log \
    ${EXPORT_DIR}/log/${DESIGN}.syn.log \
    ${EXPORT_DIR}/${RPT_POSTFIX}.${RUN}.info.rpt \
    "

    foreach Gen3_file $Gen3_list {
        if { [file exist $Gen3_file] } {
            exec ln -sf $Gen3_file ${EXPORT_DIR}/to_ADF/
        } else {
		    puts "<ERROR> File not found. \[ $Gen3_file \] "
            exec echo "Gen3 link error : $Gen3_file is NOT exist" >> export.log
        }
    }
    set Gen3_file [glob -nocomp ${EXPORT_DIR}/log/${DESIGN}.read_constraint*.log]
    if { [llength $Gen3_file] > 0 } {
        foreach tt $Gen3_file { exec ln -sf $tt ${EXPORT_DIR}/to_ADF/ }
    } else {
		puts "<ERROR> File not found. \[ read_constraint \] "
        exec echo "Gen3 link error : read_constraint is NOT exist" >> export.log
    }

    puts "Export Done to ${EXPORT_DIR}"
    exec touch export.${DESIGN}.${RUN}.done
    exec touch ${EXPORT_DIR}/export.done
    exec chmod -R 775 ${EXPORT_DIR}
    
    exec echo "Exporting Finised" >> export.log

} else {
    puts "<INFO> : ${EXPORT_DIR} Directory already exist. Check and export again"
    exec echo "${EXPORT_DIR} Directory already exist. Check and export again " >> export.log
}
