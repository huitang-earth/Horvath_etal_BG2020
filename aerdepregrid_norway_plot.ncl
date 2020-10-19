;
; Regrid CLM Aerosol-Deposition file (aerdep) to a new resolution. 
; Works for climatology monthly aerdep files.
; Uses input environment variables to determine resolution and other 
; parameters to describe set of files to use.
; Uses bld query to get input filenames. Also uses env variable CSMDATA for location
; of input files.
;
;  Erik Kluzek
;  Apr/10/2008
;  $Id: aerdepregrid.ncl 28400 2011-05-16 05:46:46Z erik $
;  $HeadURL;
;
begin
  ; ===========================================================================================================
  ;
  ; IMPORTANT NOTE: EDIT THE FOLLOWING TO CUSTOMIZE
  ; Edit the following as needed to interpolate to a new resolution.
  ;
  ; Input and output resolution
  ;

  plot_num       =(/405,513,622,801,922,1131,1304,1322,1623,2015,2108,2238,2332,2425,2948,2962,4268,5369,6380,6473/)
  nplot=dimsizes(plot_num)
do mm=0,nplot-1,1
  resin          = "1.9x2.5";              ; Input resolution:  1.9x2.5 (normally NOT changed)
  gridfile       = "/home/huitang/Documents/peter_data/single_point_input/griddata/griddata_"+plot_num(mm)+"_norway.nc";       ; Get input grid file to use  for output resolution
  res            = "0.05x0.05"        ; Get output resolution from env variable
  rcp            = getenv("RCP");          ; Get input representative concen. pathway
  sim_year       = getenv("SIM_YR");       ; Get input simulation year from env variable
  sim_year_range = getenv("SIM_YR_RNG");   ; Get input simulation year range from env variable
  ldate     = systemfunc( "date" );
  
  filename    = "/home/huitang/Documents/peter_data/single_point_input/aerosoldep/aerosoldep_monthly_2000_mean_1.9x2.5_c090421.nc";
  gridinfile  = "/home/huitang/Documents/peter_data/single_point_input/griddata/griddata_1.9x2.5_060404.nc";
  filenameout = "/home/huitang/Documents/peter_data/single_point_input/aerosoldep/aerosoldep_2000_mean_"+plot_num(mm)+"_norway.nc";

  ;
  ; Open files
  ;
  print( "Interpolate from file: "+filename );
  if ( systemfunc("test -f "+filename+"; echo $?" ) .ne. 0 )then
     print( "Input faerdep file does not exist or not found: "+filename );
     exit
  end if
  nc       = addfile( filename,    "r" );
  print( "Use gridin file:       "+gridinfile );
  if ( systemfunc("test -f "+gridinfile+"; echo $?" ) .ne. 0 )then
     print( "Input gridinfile does not exist or not found: "+gridinfile );
     exit
  end if
  ncgi     = addfile( gridinfile,  "r" );
  print( "Use grid file:         "+gridfile );
  if ( systemfunc("test -f "+gridfile+"; echo $?" ) .ne. 0 )then
     print( "Input gridfile does not exist or not found: "+gridfile );
     exit
  end if
  ncg      = addfile( gridfile,    "r" );
  print( "Output file:           "+filenameout );
  if ( systemfunc("test -f "+filenameout+"; echo $?" ) .eq. 0 )then
     system( "/bin/rm -f "+filenameout );
  end if
  nco      = addfile( filenameout, "c" );
  ;
  ; Define dimensions
  ;
  dimnames  = (/ "time", "lat", "lon" /);
  latgg     = ncg->LATIXY(lsmlat|:,lsmlon|0);
  longg     = ncg->LONGXY(lsmlat|0,lsmlon|:);
  nlat      = dimsizes( latgg );
  nlon      = dimsizes( longg );
  ntime     = getfilevardimsizes(nc,"time");
  dsizes    = (/ ntime, nlat,  nlon  /);
  is_unlim  = (/ True,  False, False /);
  filedimdef( nco, dimnames, dsizes, is_unlim );
  print( "Number of times: "+ntime );
  ;
  ; Define vars and add attributes from original file
  ;
  print( "Define vars" );
  vars = getfilevarnames( nc );
  i = dimsizes(vars) - 1
  do while ( i .ge. 0 )
     print( "Define "+vars(i) );
     filevardef (    nco, vars(i), typeof(nc->$vars(i)$), getfilevardims( nc, vars(i) ) );
     filevarattdef ( nco, vars(i), nc->$vars(i)$ );
     i = i - 1
  end do
  fileattdef ( nco, nc );
  ;
  ; Add global attributes to output file
  ;
  print( "Global attributes" );
  nco@history              = ldate+": Regrid from "+resin+" resolution to "+res+" by aerdepregrid.ncl";
  nco@source               = "Regrid from:"+filename;
  nco@gridfile             = gridfile;
  nco@aerdepregridVersion  = "$HeadURL: https://svn-ccsm-models.cgd.ucar.edu/clm2/branch_tags/cesm1_0_rel_tags/cesm1_0_3_n05_clm4_0_32/models/lnd/clm/tools/ncl_scripts/aerdepregrid.ncl $";
  nco@aerdepregridRevision = "$Id: aerdepregrid.ncl 28400 2011-05-16 05:46:46Z erik $";
  ;
  ; Copy coordinate variables over
  ;
  if ( isfilevar( nc, "date" ) ) then
     nco->date= (/nc->date/);
  end if
  if ( isfilevar( nc, "time" ) ) then
     nco->time= (/nc->time/);
  end if
  nco->lon   = doubletofloat( (/longg/) );
  nco->lat   = doubletofloat( (/latgg/) );
  lon  = (/ nc->lon /);
  lat  = (/ nc->lat /);
  lono = (/ nco->lon /);
  lato = (/ nco->lat /);
  areai   = doubletofloat( (/ ncgi->AREA /) );
  sumarea = sum(areai);
  areai   = areai / sumarea;
  areao   = doubletofloat( (/ ncg->AREA /) );
  sumarea = sum(areao);
  areao   = areao / sumarea;
  print( "areai sum = "+sum(areai) );
  print( "areao sum = "+sum(areao) );
  if ( abs(sum(areai)-sum(areao)) .gt. 5.e-4 ) then
     print( "Input and output areas are significantly different" );
     print( "Area-in:  "+sum(areai) );
     print( "Area-out: "+sum(areao) );
     exit
  end if
  ;
  ; loop over variables
  ;
  if ( nlon .eq. 1 )then
     Cyclic = False
  else
     dx = lono(1) - lono(0);
     ; The last longitude should equal 360-(dx-first_longitude)
     ; So for example if first_longitude=0,  last will be 360-dx
     ;                If first_longitude=dx, last will be 360
     expLast = 360.0 - (dx - lono(0));
     if ( abs(lono(nlon-1) - expLast) .lt. 1.e-4 )then
        Cyclic = True;
     else
        Cyclic = False
     end if
  end if

  print( "Cyclic grid: "+Cyclic );

  do i = 0, dimsizes( vars )-1

     vardimnames = getfilevardims( nc, vars(i) );
     ;
     ; If variable is not one of the dimensions -- regrid it and write to output file
     ;
     if ( (vars(i) .ne. "date") .and. (vars(i) .ne. "time") .and. (vars(i) .ne. "lat") .and. (vars(i) .ne. "lon") )then
       print( "Write variable: "+vars(i)+" to output file" );
       ;
       ; If time dimension
       ;
       if ( vardimnames(0) .eq. "time" )then
          do t = 0, ntime-1
             vart  = (/nc->$vars(i)$(t,:,:)/);
             varto = linint2 ( lon,  lat,  vart, Cyclic, lono, lato, 0 );
             if ( all(ismissing(varto(nlat-1,:))) )then
                print( "Copy last latitude over" );
                varto(nlat-1,:) = varto(nlat-2,:);
             end if
             if ( any(ismissing(varto)) )then
                print( "There are some missing values on output no="+num(ismissing(varto)) );
                exit
             end if
             nco->$vars(i)$(time|t,lat|:,lon|:) = (/varto/);
             vart  = vart*areai;
             varto = varto*areao;
             print( "Month: "+t+" Input w-sum: "+sum(vart)+" Output: "+sum(varto) );
          end do
       ;
       ; without time dimension
       ;
       else
          var  = (/nc->$vars(i)$/);
          varo = linint2 ( lon, lat,  var, Cyclic, lono, lato, 0 );
          if ( all(ismissing(varo(nlat-1,:))) )then
             print( "Copy last latitude over" );
             varo(nlat-1,:) = varo(nlat-2,:);
          end if
          if ( any(ismissing(varo)) )then
             print( "There are some missing values on output no="+num(ismissing(varo)) );
             exit
          end if
          nco->$vars(i)$ = (/varo/);
          var  = var*areai;
          varo = varo*areao;
          print( "Input w-sum: "+sum(var)+" Output: "+sum(varo) );
       end if
     end if
     delete( vardimnames );

  end do
  if ( isvar("varto") )then
     delete(varto);
  end if
  if ( isvar("vart") )then
     delete(vart);
  end if
  delete(areao);
  delete(areai);
  if ( isvar("varo") )then
     delete(varo);
  end if
  if ( isvar("var") )then
     delete(var)
  end if

  print( "================================================================================================" );
  print( "Successfully created output aerdep file: "+filenameout );

end do
end
