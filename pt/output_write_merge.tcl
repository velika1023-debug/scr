      if {[info exists gen_twf ] && ${gen_twf}  } { proc_time gen_twf_START  ;source -e -v ${COMMON_TCL_PT}/output_write_twf.tcl ; proc_time gen_twf_END  }
      if {[info exists gen_sdc ] && ${gen_sdc}  } { proc_time gen_sdc_START  ;source -e -v ${COMMON_TCL_PT}/output_write_sdc.tcl ; proc_time gen_sdc_END  }
      if {[info exists gen_etm ] && ${gen_etm}  } { proc_time gen_etm_START  ;source -e -v ${COMMON_TCL_PT}/output_write_etm.tcl ; proc_time gen_etm_END  }
      if {[info exists gen_hsc ] && ${gen_hsc}  } { proc_time gen_hsc_START  ;source -e -v ${COMMON_TCL_PT}/output_write_hsc.tcl ; proc_time gen_hsc_END  }
      if {[info exists gen_sdf ] && ${gen_sdf}  } { proc_time gen_sdf_START  ;source -e -v ${COMMON_TCL_PT}/output_write_sdf.tcl ; proc_time gen_sdf_END
} elseif {[info exists gen_fsdf] && ${gen_fsdf} } { proc_time gen_fsdf_START ;source -e -v ${COMMON_TCL_PT}/output_write_sdf.tcl ; proc_time gen_fsdf_END
}
