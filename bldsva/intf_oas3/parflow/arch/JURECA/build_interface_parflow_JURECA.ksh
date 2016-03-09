#! /bin/ksh

always_pfl(){
print "${cblue}>> always_pfl${cnormal}"
print "${cblue}<< always_pfl${cnormal}"
}

configure_pfl(){
print "${cblue}>> configure_pfl${cnormal}"


    if [[ $withOAS == "true" ]]; then
      cplLib="$liboas $libpsmile"
      cplInc="$incpsmile"
    fi  

    flagsSim+="CC=$mpiPath/bin/mpicc  CXX=$mpiPath/bin/mpic++ FC=$mpiPath/bin/mpif90 F77=$mpiPath/bin/mpif77 "
    flagsTools+="CC=$mpiPath/bin/mpicc FC=$mpiPath/bin/mpif90 F77=$mpiPath/bin/mpif77 "
    libsSim="$cplLib -L$ncdfPath/lib -lnetcdff"
    fcflagsSim="$cplInc -Duse_libMPI -Duse_netCDF -Duse_comm_MPI1 -DVERBOSE -DDEBUG -DTREAT_OVERLAY -I$ncdfPath/include "
    c_configure_pfl

  print -n "   sed correct linker command in pfsimulator"
    sed -i 's@\" \-lmpi \-lifport \-lifcoremt \-limf \-lsvml \-lm \-lipgo \-lirc \-lpthread \-lgcc \-lgcc_s \-lirc_s \-ldl \-lm  \-lmpifort \-lmpi\"@@' $pfldir/pfsimulator/config/Makefile.config >> $log_file 2>> $err_file
  check
  print -n "   sed correct linker command in pftools"
    sed -i 's@\" \-lmpi \-lifport \-lifcoremt \-limf \-lsvml \-lm \-lipgo \-lirc \-lpthread \-lgcc \-lgcc_s \-lirc_s \-ldl \-lm  \-lmpifort \-lmpi\"@@' $pfldir/pftools/config/Makefile.config >> $log_file 2>> $err_file
check



print "${cblue}<< configure_pfl${cnormal}"
}

make_pfl(){
print "${cblue}>> make_pfl${cnormal}"
  c_make_pfl
print "${cblue}<< make_pfl${cnormal}"
}


substitutions_pfl(){
print "${cblue}>> substitutions_pfl${cnormal}"
  print -n "   cp new pf_pfmg_octree.c to /parflow_lib/"
    cp $rootdir/bldsva/intf_oas3/parflow/arch/JURECA/src/pf_pfmg_octree.c  $pfldir/pfsimulator/parflow_lib/ >> $log_file 2>> $err_file
  check
  print -n "   cp new Makefile.in to /pfsimulator/parflow_exe/"
    cp $rootdir/bldsva/intf_oas3/parflow/arch/JURECA/config/Makefile.in $pfldir/pfsimulator/parflow_exe/ >> $log_file 2>> $err_file
  check
    if [[ $withOASMCT == "true" ]] ; then 
      print -n "   sed replace old mod_prism includes from pfl oas files"
        sed -i "s/mod_prism_proto/mod_prism/" $pfldir/pfsimulator/amps/oas3/oas_pfl_vardef.F90 >> $log_file 2>> $err_file
      check
        sed -i "s/USE mod_prism.*//" $pfldir/pfsimulator/amps/oas3/oas_pfl_define.F90 >> $log_file 2>> $err_file
      check
        sed -i "s/USE mod_prism.*//" $pfldir/pfsimulator/amps/oas3/oas_pfl_snd.F90 >> $log_file 2>> $err_file
      check
        sed -i "s/USE mod_prism.*//" $pfldir/pfsimulator/amps/oas3/oas_pfl_rcv.F90 >> $log_file 2>> $err_file
      check
    fi

print "${cblue}<< substitutions_pfl${cnormal}"
}


setup_pfl(){
print "${cblue}>> setup_pfl${cnormal}"
  cp $namelist_pfl $rundir/coup_oas.tcl
  sed "s/__nprocx_pfl_bldsva__/$px_pfl/" -i $rundir/coup_oas.tcl
  sed "s/__nprocy_pfl_bldsva__/$py_pfl/" -i $rundir/coup_oas.tcl
  sed "s/__ngpflx_bldsva__/$gx_pfl/" -i $rundir/coup_oas.tcl
  sed "s/__ngpfly_bldsva__/$gy_pfl/" -i $rundir/coup_oas.tcl
  sed "s,__forcingdir__,$rundir," -i $rundir/coup_oas.tcl
  sed "s/__dt_pfl_bldsva__/$dt_pfl/" -i $rundir/coup_oas.tcl
  sed "s/__stop_pfl_bldsva__/$runhours/" -i $rundir/coup_oas.tcl

  sed "s/__start_cnt_pfl__/0/" -i $rundir/coup_oas.tcl
  if [[ $restart == 0 ]] then
    sed "s/__pfl_ICPpressureType__/HydroStaticPatch/" -i $rundir/coup_oas.tcl        # HydrostaticPatch > PFBFile
    sed "s/__pfl_ICPpressureValue__/-5.0/" -i $rundir/coup_oas.tcl        # comment this during restart run
  else
    pfbfilename="/work/slts/slts06/tsmp/TSMPForecastNRW$restDate-00/run/rurlaf.out.press.00024.pfb"

    sed "s/__pfl_ICPpressureType__/PFBFile/" -i $rundir/coup_oas.tcl        # HydrostaticPatch > PFBFile
    sed "s,__pfl_ICPpressureFileName__,$pfbfilename," -i $rundir/coup_oas.tcl        # comment this during restart run
  fi
  export PARFLOW_DIR="$pfldir"
  cd $rundir
  tclsh $rundir/coup_oas.tcl
print "${cblue}<< setup_pfl${cnormal}"
}

