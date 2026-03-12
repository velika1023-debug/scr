;#------------------------------------------------------------------------
;# Reporting After ECO stage in Master
;#------------------------------------------------------------------------
report_global_timing -pba_mode $PBA_MODE -sig 4 -separate_all_groups -include { inter_clock per_clock_violations }  -format wide \
                                                                                                                         > ${M_DIR}/${stage}_GT_detail
report_global_timing -pba_mode $PBA_MODE -sig 4                                                                          > ${M_DIR}/${stage}_GT
report_constraints -all_violator -sig 4 -nosp   -max_transition                                                          > ${M_DIR}/${stage}_mttv
report_constraints -all_violator -sig 4 -nosp   -max_capacitance                                                         > ${M_DIR}/${stage}_maxcap
report_constraints -all_violator -sig 4 -nosp   -max_delay -pba_mode $PBA_MODE                                           > ${M_DIR}/${stage}_maxdelay
report_constraints -all_violator -sig 4 -nosp   -min_delay -pba_mode $PBA_MODE                                           > ${M_DIR}/${stage}_mindelay


;#------------------------------------------------------------------------
;# Directory create and ECO script Write Slave
;#------------------------------------------------------------------------
remote_execute { 
    set DIR    $stage
    file mkdir $stage
    write_changes -format icctcl  -output ./$DIR/${ECO_NUM_N}.${stage}.icc.tcl
    write_changes -format icc2tcl -output ./$DIR/${ECO_NUM_N}.${stage}.icc2.tcl
    write_changes -format text    -output ./$DIR/${ECO_NUM_N}.${stage}.text.tcl
    write_changes -format eco     -output ./$DIR/${ECO_NUM_N}.${stage}.eco.tcl
}



;#------------------------------------------------------------------------
;# Reporting After ECO stage in Slave
;#------------------------------------------------------------------------
remote_execute {
    report_global_timing -pba_mode $PBA_MODE -sig 4 -separate_all_groups -include { inter_clock per_clock_violations }  -format wide \
                                                                                                                             > ${DIR}/${stage}_GT_detail
    report_global_timing -pba_mode $PBA_MODE -sig 4                                                                          > ${DIR}/${stage}_GT
    report_constraints -all_violator -sig 4 -nosp   -max_transition                                                          > ${DIR}/${stage}_mttv
    report_constraints -all_violator -sig 4 -nosp   -max_capacitance                                                         > ${DIR}/${stage}_maxcap
    report_constraints -all_violator -sig 4 -nosp   -max_delay -pba_mode $PBA_MODE                                           > ${DIR}/${stage}_maxdelay
    report_constraints -all_violator -sig 4 -nosp   -min_delay -pba_mode $PBA_MODE                                           > ${DIR}/${stage}_mindelay
    sec_report_cell_usage -verbose  -output ${DIR}/${stage}_cell_usage.rpt

}
