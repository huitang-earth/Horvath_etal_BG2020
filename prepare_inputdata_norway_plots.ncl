load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

    plot_filename = "./plot_sel.txt"
    domain_dir    = "./domainfile/"
    grid_dir      = "./griddata/" 
    script_dir    = "./SCRIPgrid/"
    map_dir       = "./mapdata/"
    clim_output      = "./clm_clim_forcing/"
    clim_input    =  "./cordex/"
       
    plot_info=readAsciiTable(plot_filename, 6, "float", 1)

    delete(plot_info@_FillValue)
    printVarSummary(plot_info)
    print(plot_info(:,1))
        
    nplot=dimsizes(plot_info(:,1))
    PI=3.14159265358979323846
    re=6371.22
    
    domaincp=True      ; copy a template domain file, available at: https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/share/domains/domain.clm/
    domainm=True       ; modify template domain file to create domain file for each site
    gridcp =True       ; copy a template grid file, available at: https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/griddata/
    gridm  =True       ; modify template grid file to create grid file for each site
    scriptm=True       ; create script file for each site
    climcp=True        ; copy a template climate focing file, available at: https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/1pt_atmdata/vancouverCAN.c060920/  
    makeclim=True       ; modify template climate focing file to create climate forcing data

;###### copyp files
  if (domaincp)
    do m=0,nplot-1,1    
       system("cp "+domain_dir+"domain.lnd.1x1pt-vancouverCAN_navy.090715.nc "+domain_dir+"domain.lnd."+plot_info(m,1)+".norway.nc" )
    end do
  end if

  if (gridcp)
    do m=0,nplot-1,1    
       system("cp "+grid_dir+"griddata_1x1pt_vancouverCAN_c090715.nc "+grid_dir+"griddata_"+plot_info(m,1)+"_norway.nc" )
       system("cp "+grid_dir+"fracdata_1x1pt_vancouverCAN_navy_c090715.nc "+grid_dir+"fracdata_"+plot_info(m,1)+"_norway.nc" )
    end do
  end if

  if (scriptcp)
    do m=0,nplot-1,1    
       system("cp "+script_dir+"SCRIPgrid_1x1pt_vancouverCAN_nomask_c110308.nc "+script_dir+"SCRIPgrid_1x1pt_"+plot_info(m,1)+"_norway.nc")
    end do
  end if
  
;###### modify domain file

  if (domainm) then  
    do m=0,nplot-1,1
      fdomain  = addfile(domain_dir+"domain.lnd."+plot_info(m,1)+".norway.nc","w")
      fdomain->xc=plot_info(m,4)
      fdomain->yc=plot_info(m,5)   
      printVarSummary(plot_info(m,4))
      xfloor=plot_info(m,4)-0.05
      xceil =plot_info(m,4)+0.05
      yfloor=plot_info(m,5)-0.05
      yceil =plot_info(m,5)+0.05
      print(yceil)
      fdomain->xv=(/xfloor,xceil,xceil,xfloor/)
      fdomain->yv=(/yfloor,yfloor,yceil,yceil/)  
      fdomain->frac=1                
      fdomain->area=(xceil-xfloor)*PI/180.0*(sin(yceil*PI/180)-sin(yfloor*PI/180))
    end do
  end if
    
;######   

;###### modify grid file
  if (gridm) then
    do m=0,nplot-1,1
      fgrid  = addfile(grid_dir+"griddata_"+plot_info(m,1)+"_norway.nc","w")
      ffrac  = addfile(grid_dir+"fracdata_"+plot_info(m,1)+"_norway.nc","w")
      fgrid  ->LONGXY=plot_info(m,4)
      fgrid   ->LATIXY=plot_info(m,5)   
      printVarSummary(plot_info(m,4))
      xfloor=plot_info(m,4)-0.05
      xceil =plot_info(m,4)+0.05
      yfloor=plot_info(m,5)-0.05
      yceil =plot_info(m,5)+0.05
      print(yceil)
      fgrid->EDGEN=(/yceil/)
      fgrid->EDGEE=(/xceil/)  
      fgrid->EDGES=(/yfloor/)
      fgrid->EDGEW=(/xfloor/) 
      fgrid->LATN=(/yceil/)
      fgrid->LONE=(/xceil/)  
      fgrid->LATS=(/yfloor/)
      fgrid->LONW=(/xfloor/)
      fgrid->AREA=(xceil-xfloor)*PI/180.0*(sin(yceil*PI/180)-sin(yfloor*PI/180))*re*re      
      ffrac->LONGXY=plot_info(m,4)
      ffrac->LATIXY=plot_info(m,5)   
      ffrac->LANDFRAC=1                
    end do
  end if
    
;######   
 
;###### creat scriptgrid file; start with scriptgrid files, then mapping file, domain file and then grid/frac file
  if (scriptm) then
    lon = new( (/1, 1/), "double" );
    lat = new( (/1, 1/), "double" );
    delete(lon@_FillValue)
    delete(lat@_FillValue)
  do m=0,nplot-1,1
    xfloor=plot_info(m,4)-0.05
    xceil =plot_info(m,4)+0.05
    yfloor=plot_info(m,5)-0.05
    yceil =plot_info(m,5)+0.05
    lon(0,0) = plot_info(m,4)
    lat(0,0) = plot_info(m,5)
    
    Opt1                = True
    Opt1@ForceOverwrite = True
    Opt1@Mask2D         = (/1/)
    Opt1@GridCornerLat  = (/yfloor,yfloor,yceil,yceil/)
    Opt1@GridCornerLon  = (/xfloor,xceil,xceil,xfloor/)

    curvilinear_to_SCRIP(script_dir+"SCRIPgrid_1x1pt_"+plot_info(m,1)+"_norway.nc",lat,lon,Opt1)

  end do
  
  end if
    
;######       


;###### create climate forcing data for 1pt simulation;    
varFSDS=True    ; prepare shortwave radiation data from 3-hourly output of CORDEX Europe-11km SMHI-RCA4 simulation
varPREC=True    ; prepare precipitation data from 3-hourly output of CORDEX Europe-11km SMHI-RCA4 simulation
varTAS =True    ; prepare surface temperature from 3-hourly output of CORDEX Europe-11km SMHI-RCA4 simulation
varWIND=True    ; prepare surface wind from 3-hourly output of CORDEX Europe-11km SMHI-RCA4 simulation
varPSHUM=True   ; prepare surface pressure and humidy from daily output of CORDEX Europe-11km SMHI-RCA4 simulation
varCOMB=True    ; combine all the variables into one file
timCOMB=False   ; combine all time files into one file
varTIME=True    ; modify calendar to have no leap years. 

if (makeclim) then

if (varFSDS) then
  do year=1981,2010,1 
      frsds=addfile(clim_input+"rsds_EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr_"+year+"01010130-"+year+"12312230.nc","r")
      rsds=frsds->rsds(:,:,:)
      lon=frsds->lon(:,:)
      lat=frsds->lat(:,:)
      time=frsds->time(:)
      printVarSummary(rsds)
      rsds_plot=rcm2points(lat,lon,rsds,plot_info(:,5),plot_info(:,4),0)
      printVarSummary(rsds_plot)

      fclim_ori=addfile(clim_output+"clm1pt-1992-08.nc","r")  
      edgew   =fclim_ori->EDGEW
      edgee   =fclim_ori->EDGEE
      edges   =fclim_ori->EDGES
      edgen   =fclim_ori->EDGEN
      longxy  =fclim_ori->LONGXY
      latxy   =fclim_ori->LATIXY
      fsds    =fclim_ori->FSDS
    
    do m=0,20,1 
      system("rm -f "+clim_output+"clm1pt_"+plot_info(m,1)+"_FSDS_"+year+"01010130-"+year+"12312230.nc")    ; remove if exists
      fclim  = addfile(clim_output+"clm1pt_"+plot_info(m,1)+"_FSDS_"+year+"01010130-"+year+"12312230.nc","c")
      ntim  = dimsizes(time)                 ; get dimension sizes                                                 
      nlat  = 1  
      nlon  = 1
      nscalar = 1

      setfileoption(fclim,"DefineMode",True)

      fAtt               = True            ; assign file attributes
      fAtt@case_title    = "EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr: norway "  
      fAtt@conventions   = "CF-1.0" 
      fAtt@title         = "CLM single point datm input data"  
      fAtt@history       = "Original data from EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr"
      fAtt@creation_date = systemfunc ("date")        
      fileattdef( fclim, fAtt )            ; copy file attributes  

      dimNames = (/"scalar","lon","lat","time"/)  
      dimSizes = (/ nscalar, nlon, nlat, -1 /) 
      dimUnlim = (/ False, False, False, True/)   
      filedimdef(fclim,dimNames,dimSizes,dimUnlim)

      filevardef(fclim, "EDGEW" ,typeof(edgew),getvardims(edgew)) 
      filevardef(fclim, "EDGEE"  ,typeof(edgee),getvardims(edgee))                           
      filevardef(fclim, "EDGES"  ,typeof(edges),getvardims(edges))                          
      filevardef(fclim, "EDGEN"  ,typeof(edgen),getvardims(edgen))                          
      filevardef(fclim, "LONGXY" ,typeof(longxy)  ,getvardims(longxy))    
      filevardef(fclim, "LATIXY"  ,typeof(latxy) ,getvardims(latxy))          
      filevardef(fclim, "FSDS",typeof(fsds),getvardims(fsds))
      filevardef(fclim, "time",typeof(time),getvardims(time))          

      filevarattdef(fclim,"EDGEW",edgew)                           
      filevarattdef(fclim,"EDGEE",edgee)                   
      filevarattdef(fclim,"EDGES",edges)                    
      filevarattdef(fclim,"EDGEN",edgen)                    
      filevarattdef(fclim,"LONGXY",longxy)                     
      filevarattdef(fclim,"LATIXY",latxy)                      
      filevarattdef(fclim,"FSDS",fsds)
      filevarattdef(fclim,"time",time)  

      setfileoption(fclim,"DefineMode",False)
      
      fclim->time   = (/time/) 
      xfloor=plot_info(m,4)-0.05
      xceil =plot_info(m,4)+0.05
      yfloor=plot_info(m,5)-0.05
      yceil =plot_info(m,5)+0.05
      print(yceil)
      fclim->EDGEW  = (/xfloor/)
      fclim->EDGEE  = (/xceil/) 
      fclim->EDGES  = (/yfloor/) 
      fclim->EDGEN  = (/yceil/)

      printVarSummary(plot_info(m,4))
      fclim->LONGXY = (/plot_info(m,4)/)
      fclim->LATIXY  = (/plot_info(m,5)/)
      fclim->FSDS   = (/rsds_plot(:,m)/)    

    end do

   delete(rsds)
   delete(time)
   delete(rsds_plot)

 end do

end if


if (varPREC) then
  do year=1981,2010,1 
      frsds=addfile(clim_input+"pr_EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr_"+year+"01010130-"+year+"12312230.nc","r")
      rsds=frsds->pr(:,:,:)
      lon=frsds->lon(:,:)
      lat=frsds->lat(:,:)
      time=frsds->time(:)
      printVarSummary(rsds)
      rsds_plot=rcm2points(lat,lon,rsds,plot_info(:,5),plot_info(:,4),0)
      printVarSummary(rsds_plot)

      fclim_ori=addfile(clim_output+"clm1pt-1992-08.nc","r")  
      edgew   =fclim_ori->EDGEW
      edgee   =fclim_ori->EDGEE
      edges   =fclim_ori->EDGES
      edgen   =fclim_ori->EDGEN
      longxy  =fclim_ori->LONGXY
      latxy   =fclim_ori->LATIXY
      fsds    =fclim_ori->PRECTmms
    
    do m=0,20,1 
      system("rm -f "+clim_output+"clm1pt_"+plot_info(m,1)+"_PRECTmms_"+year+"01010130-"+year+"12312230.nc")    ; remove if exists
      fclim  = addfile(clim_output+"clm1pt_"+plot_info(m,1)+"_PRECTmms_"+year+"01010130-"+year+"12312230.nc","c")
      ntim  = dimsizes(time)                 ; get dimension sizes                                                 
      nlat  = 1  
      nlon  = 1
      nscalar = 1

      setfileoption(fclim,"DefineMode",True)

      fAtt               = True            ; assign file attributes
      fAtt@case_title    = "EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr: norway "  
      fAtt@conventions   = "CF-1.0" 
      fAtt@title         = "CLM single point datm input data"  
      fAtt@history       = "Original data from EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr"
      fAtt@creation_date = systemfunc ("date")        
      fileattdef( fclim, fAtt )            ; copy file attributes  

      dimNames = (/"scalar","lon","lat","time"/)  
      dimSizes = (/ nscalar, nlon, nlat, -1 /) 
      dimUnlim = (/ False, False, False, True/)   
      filedimdef(fclim,dimNames,dimSizes,dimUnlim)

      filevardef(fclim, "EDGEW" ,typeof(edgew),getvardims(edgew)) 
      filevardef(fclim, "EDGEE"  ,typeof(edgee),getvardims(edgee))                           
      filevardef(fclim, "EDGES"  ,typeof(edges),getvardims(edges))                          
      filevardef(fclim, "EDGEN"  ,typeof(edgen),getvardims(edgen))                          
      filevardef(fclim, "LONGXY" ,typeof(longxy)  ,getvardims(longxy))    
      filevardef(fclim, "LATIXY"  ,typeof(latxy) ,getvardims(latxy))          
      filevardef(fclim, "PRECTmms",typeof(fsds),getvardims(fsds))
      filevardef(fclim, "time",typeof(time),getvardims(time))          

      filevarattdef(fclim,"EDGEW",edgew)                           
      filevarattdef(fclim,"EDGEE",edgee)                   
      filevarattdef(fclim,"EDGES",edges)                    
      filevarattdef(fclim,"EDGEN",edgen)                    
      filevarattdef(fclim,"LONGXY",longxy)                     
      filevarattdef(fclim,"LATIXY",latxy)                      
      filevarattdef(fclim,"PRECTmms",fsds)
      filevarattdef(fclim,"time",time)  

      setfileoption(fclim,"DefineMode",False)
      
      fclim->time   = (/time/)        ; "(/", "/)" syntax tells NCL to only output the data values to the predefined locations on the file.
      xfloor=plot_info(m,4)-0.05
      xceil =plot_info(m,4)+0.05
      yfloor=plot_info(m,5)-0.05
      yceil =plot_info(m,5)+0.05
      print(yceil)
      fclim->EDGEW  = (/xfloor/)
      fclim->EDGEE  = (/xceil/) 
      fclim->EDGES  = (/yfloor/) 
      fclim->EDGEN  = (/yceil/)

      printVarSummary(plot_info(m,4))
      fclim->LONGXY = (/plot_info(m,4)/)
      fclim->LATIXY  = (/plot_info(m,5)/)
      fclim->PRECTmms   = (/rsds_plot(:,m)/)    

    end do

    delete(rsds)
    delete(time)
    delete(rsds_plot)
 
 end do

end if

if (varTAS) then
  do year=1981,2010,1 
      frsds=addfile(clim_input+"tas_EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr_"+year+"01010000-"+year+"12312100.nc","r")
      rsds=frsds->tas(:,:,:)
      lon=frsds->lon(:,:)
      lat=frsds->lat(:,:)
      time=frsds->time(:)
      printVarSummary(rsds)
      rsds_plot=rcm2points(lat,lon,rsds,plot_info(:,5),plot_info(:,4),0)
      printVarSummary(rsds_plot)

      fclim_ori=addfile(clim_output+"clm1pt-1992-08.nc","r")  
      edgew   =fclim_ori->EDGEW
      edgee   =fclim_ori->EDGEE
      edges   =fclim_ori->EDGES
      edgen   =fclim_ori->EDGEN
      longxy  =fclim_ori->LONGXY
      latxy   =fclim_ori->LATIXY
      fsds    =fclim_ori->TBOT
    
    do m=0,20,1 
      system("rm -f "+clim_output+"clm1pt_"+plot_info(m,1)+"_TBOT_"+year+"01010130-"+year+"12312230.nc")    ; remove if exists
      fclim  = addfile(clim_output+"clm1pt_"+plot_info(m,1)+"_TBOT_"+year+"01010130-"+year+"12312230.nc","c")
      ntim  = dimsizes(time)                 ; get dimension sizes                                                 
      nlat  = 1  
      nlon  = 1
      nscalar = 1

      setfileoption(fclim,"DefineMode",True)

      fAtt               = True            ; assign file attributes
      fAtt@case_title    = "EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr: norway "  
      fAtt@conventions   = "CF-1.0" 
      fAtt@title         = "CLM single point datm input data"  
      fAtt@history       = "Original data from EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr"
      fAtt@creation_date = systemfunc ("date")        
      fileattdef( fclim, fAtt )            ; copy file attributes  

      dimNames = (/"scalar","lon","lat","time"/)  
      dimSizes = (/ nscalar, nlon, nlat, -1 /) 
      dimUnlim = (/ False, False, False, True/)   
      filedimdef(fclim,dimNames,dimSizes,dimUnlim)

      filevardef(fclim, "EDGEW" ,typeof(edgew),getvardims(edgew)) 
      filevardef(fclim, "EDGEE"  ,typeof(edgee),getvardims(edgee))                           
      filevardef(fclim, "EDGES"  ,typeof(edges),getvardims(edges))                          
      filevardef(fclim, "EDGEN"  ,typeof(edgen),getvardims(edgen))                          
      filevardef(fclim, "LONGXY" ,typeof(longxy)  ,getvardims(longxy))    
      filevardef(fclim, "LATIXY"  ,typeof(latxy) ,getvardims(latxy))          
      filevardef(fclim, "TBOT",typeof(fsds),getvardims(fsds))
      filevardef(fclim, "time",typeof(time),getvardims(time))          

      filevarattdef(fclim,"EDGEW",edgew)                           
      filevarattdef(fclim,"EDGEE",edgee)                   
      filevarattdef(fclim,"EDGES",edges)                    
      filevarattdef(fclim,"EDGEN",edgen)                    
      filevarattdef(fclim,"LONGXY",longxy)                     
      filevarattdef(fclim,"LATIXY",latxy)                      
      filevarattdef(fclim,"TBOT",fsds)
      filevarattdef(fclim,"time",time)  

      setfileoption(fclim,"DefineMode",False)
      
      fclim->time   = (/time/)        ; "(/", "/)" syntax tells NCL to only output the data values to the predefined locations on the file.
      xfloor=plot_info(m,4)-0.05
      xceil =plot_info(m,4)+0.05
      yfloor=plot_info(m,5)-0.05
      yceil =plot_info(m,5)+0.05
      print(yceil)
      fclim->EDGEW  = (/xfloor/)
      fclim->EDGEE  = (/xceil/) 
      fclim->EDGES  = (/yfloor/) 
      fclim->EDGEN  = (/yceil/)

      printVarSummary(plot_info(m,4))
      fclim->LONGXY = (/plot_info(m,4)/)
      fclim->LATIXY  = (/plot_info(m,5)/)
      fclim->TBOT  = (/rsds_plot(:,m)/)    

    end do

    delete(rsds)
    delete(time)
    delete(rsds_plot)

 end do

end if

if (varWIND) then
  do year=1981,2010,1 
      frsds=addfile(clim_input+"sfcWind_EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr_"+year+"01010000-"+year+"12312100.nc","r")
      rsds=frsds->sfcWind(:,:,:)
      lon=frsds->lon(:,:)
      lat=frsds->lat(:,:)
      time=frsds->time(:)
      printVarSummary(rsds)
      rsds_plot=rcm2points(lat,lon,rsds,plot_info(:,5),plot_info(:,4),0)
      printVarSummary(rsds_plot)

      fclim_ori=addfile(clim_output+"clm1pt-1992-08.nc","r")  
      edgew   =fclim_ori->EDGEW
      edgee   =fclim_ori->EDGEE
      edges   =fclim_ori->EDGES
      edgen   =fclim_ori->EDGEN
      longxy  =fclim_ori->LONGXY
      latxy   =fclim_ori->LATIXY
      fsds    =fclim_ori->WIND
    
    do m=0,20,1 
      system("rm -f "+clim_output+"clm1pt_"+plot_info(m,1)+"_WIND_"+year+"01010130-"+year+"12312230.nc")    ; remove if exists
      fclim  = addfile(clim_output+"clm1pt_"+plot_info(m,1)+"_WIND_"+year+"01010130-"+year+"12312230.nc","c")
      ntim  = dimsizes(time)                 ; get dimension sizes                                                 
      nlat  = 1  
      nlon  = 1
      nscalar = 1

      setfileoption(fclim,"DefineMode",True)

      fAtt               = True            ; assign file attributes
      fAtt@case_title    = "EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr: norway "  
      fAtt@conventions   = "CF-1.0" 
      fAtt@title         = "CLM single point datm input data"  
      fAtt@history       = "Original data from EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr"
      fAtt@creation_date = systemfunc ("date")        
      fileattdef( fclim, fAtt )            ; copy file attributes  

      dimNames = (/"scalar","lon","lat","time"/)  
      dimSizes = (/ nscalar, nlon, nlat, -1 /) 
      dimUnlim = (/ False, False, False, True/)   
      filedimdef(fclim,dimNames,dimSizes,dimUnlim)

      filevardef(fclim, "EDGEW" ,typeof(edgew),getvardims(edgew)) 
      filevardef(fclim, "EDGEE"  ,typeof(edgee),getvardims(edgee))                           
      filevardef(fclim, "EDGES"  ,typeof(edges),getvardims(edges))                          
      filevardef(fclim, "EDGEN"  ,typeof(edgen),getvardims(edgen))                          
      filevardef(fclim, "LONGXY" ,typeof(longxy)  ,getvardims(longxy))    
      filevardef(fclim, "LATIXY"  ,typeof(latxy) ,getvardims(latxy))          
      filevardef(fclim, "WIND",typeof(fsds),getvardims(fsds))
      filevardef(fclim, "time",typeof(time),getvardims(time))          

      filevarattdef(fclim,"EDGEW",edgew)                           
      filevarattdef(fclim,"EDGEE",edgee)                   
      filevarattdef(fclim,"EDGES",edges)                    
      filevarattdef(fclim,"EDGEN",edgen)                    
      filevarattdef(fclim,"LONGXY",longxy)                     
      filevarattdef(fclim,"LATIXY",latxy)                      
      filevarattdef(fclim,"WIND",fsds)
      filevarattdef(fclim,"time",time)  

      setfileoption(fclim,"DefineMode",False)
      
      fclim->time   = (/time/)        ; "(/", "/)" syntax tells NCL to only output the data values to the predefined locations on the file.
      xfloor=plot_info(m,4)-0.05
      xceil =plot_info(m,4)+0.05
      yfloor=plot_info(m,5)-0.05
      yceil =plot_info(m,5)+0.05
      print(yceil)
      fclim->EDGEW  = (/xfloor/)
      fclim->EDGEE  = (/xceil/) 
      fclim->EDGES  = (/yfloor/) 
      fclim->EDGEN  = (/yceil/)

      printVarSummary(plot_info(m,4))
      fclim->LONGXY = (/plot_info(m,4)/)
      fclim->LATIXY  = (/plot_info(m,5)/)
      fclim->WIND  = (/rsds_plot(:,m)/)    

    end do

   delete(rsds)
   delete(time)
   delete(rsds_plot)

 end do

end if

if (varPSHUM) then
  k=0
  ndaya=0
  do year=1981,2010,1       
      frsds=addfile(clim_input+"psl_EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr_"+year+"01010000-"+year+"12312100.nc","r")
      fshum=addfile(clim_input+"SHUM_ERAinterim_"+year+".nc","r")   ; 6hr output from ERA interim is used to depict the hourly changes of surface pressure and humidity.
      psl=frsds->psl(:,:,:)
      lon=frsds->lon(:,:)
      lat=frsds->lat(:,:)
      time=frsds->time(:)
      printVarSummary(psl)
      psl_plot=rcm2points(lat,lon,psl,plot_info(:,5),plot_info(:,4),0)
      printVarSummary(psl_plot)
      printVarSummary(time)

      shum_ori=fshum->q(:,::-1,:)
      slon=fshum->lon(:)
      slat=fshum->lat(::-1)
      printVarSummary(shum_ori)
      shum=shum_ori*shum_ori@scale_factor+shum_ori@add_offset
      printVarSummary(shum)
      shum!0="time"
      shum!1="lat"
      shum!2="lon"
      shum&time=shum_ori&time
      shum&lat=slat
      shum&lon=slon
      printVarSummary(shum)
         
      shum_era_plot=linint2_points(slon,slat,shum,True,plot_info(:,4),plot_info(:,5),0)
      printVarSummary(shum_era_plot) 
      shum_plot=new(dimsizes(psl_plot),typeof(psl_plot))
      printVarSummary(shum_plot)
      ntim  = dimsizes(time)
      print(ntim)
      do t=1,ntim-2,2
        shum_plot(t,:)=doubletofloat((shum_era_plot((t-1)/2,:)+shum_era_plot((t+1)/2,:))/2)     ; interpolate 6 hr ERA interim data into 3 hr data.
      end do 
      do t=0,ntim-1,2
        shum_plot(t,:)=doubletofloat(shum_era_plot(t/2,:))    ; interpolate 6 hr ERA interim data into 3 hr data.
      end do 

      print(shum_plot(0:32,0))

    if ( (k%5) .eq. 0) then
      year1=year
      year5=year1+4
      
      if(k .gt. 0) then
        delete(ps)
        delete(ps_day_plot)
        delete(tas_day)
        delete(tas_day_plot)
        delete(huss)
        delete(huss_day_plot)
        delete(shum_day_plot)
      end if 
           
      fps=addfile(clim_input+"ps_EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_day_"+year1+"0101-"+year5+"1231.nc","r")
      ps=fps->ps(:,:,:)
      ps_day_plot=rcm2points(lat,lon,ps,plot_info(:,5),plot_info(:,4),0)
      printVarSummary(ps_day_plot)

      ftas_day=addfile(clim_input+"tas_EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_day_"+year1+"0101-"+year5+"1231.nc","r")
      tas_day=ftas_day->tas(:,:,:) 
      tas_day_plot=rcm2points(lat,lon,tas_day,plot_info(:,5),plot_info(:,4),0)
      printVarSummary(tas_day_plot)      

      fhuss=addfile(clim_input+"huss_EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_day_"+year1+"0101-"+year5+"1231.nc","r")
      huss=fhuss->huss(:,:,:) 
      huss_day_plot=rcm2points(lat,lon,huss,plot_info(:,5),plot_info(:,4),0)
      printVarSummary(huss_day_plot)

;      shum_day_plot=mixhum_ptrh(ps_day_plot,tas_day_plot,huss_day_plot,2)
      shum_day_plot=huss_day_plot
      print(shum_day_plot(:,1))

      ndaya=0
    end if

    k=k+1    

    ps_hour_plot=new(dimsizes(psl_plot),typeof(psl_plot))
    shum_hour_plot=new(dimsizes(psl_plot),typeof(psl_plot))
    
    if (isleapyear(year)) then 
       nday=366
    else
       nday=365
    end if
       
    do p=0,nday-1,1
      do q=0,7,1
        ps_hour_plot(8*p+q,:)=ps_day_plot(ndaya+p,:)+ ps_day_plot(ndaya+p,:)*(psl_plot(8*p+q,:)-psl_plot(8*p,:))/psl_plot(8*p,:) ; use 3 hourly sea level pressure date to derive 3 hourly surface pressure.
        shum_hour_plot(8*p+q,:)=shum_day_plot(ndaya+p,:)+ shum_day_plot(ndaya+p,:)*(shum_plot(8*p+q,:)-shum_plot(8*p,:))/shum_plot(8*p,:)                 ; use 3 hourly humidiy data from ERAinterim to derive 3 hourly preassure data.
      end do
    end do
    ndaya=ndaya+nday

    printVarSummary(ps_hour_plot)
    printVarSummary(shum_hour_plot)
    print(year)
    print(k)
    print(ndaya)

;###

      fclim_ori=addfile(clim_output+"clm1pt-1992-08.nc","r")  
      edgew   =fclim_ori->EDGEW
      edgee   =fclim_ori->EDGEE
      edges   =fclim_ori->EDGES
      edgen   =fclim_ori->EDGEN
      longxy  =fclim_ori->LONGXY
      latxy   =fclim_ori->LATIXY
      fsds    =fclim_ori->PSRF
      rh      =fclim_ori->RH
      rh@long_name="specific_humidity at the lowest atm level (SHUM)"
      rh@units    ="kg kg**-1"
      printVarSummary(rh)

    do m=0,20,1 
      system("rm -f "+clim_output+"clm1pt_"+plot_info(m,1)+"_PSHUM_"+year+"01010130-"+year+"12312230.nc")    ; remove if exists
      fclim  = addfile(clim_output+"clm1pt_"+plot_info(m,1)+"_PSHUM_"+year+"01010130-"+year+"12312230.nc","c")
      ntim  = dimsizes(time)                 ; get dimension sizes                                                 
      nlat  = 1  
      nlon  = 1
      nscalar = 1

      setfileoption(fclim,"DefineMode",True)

      fAtt               = True            ; assign file attributes
      fAtt@case_title    = "EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr: norway "  
      fAtt@conventions   = "CF-1.0" 
      fAtt@title         = "CLM single point datm input data"  
      fAtt@history       = "Original data from EUR-11_ECMWF-ERAINT_evaluation_r1i1p1_SMHI-RCA4_v1_3hr"
      fAtt@creation_date = systemfunc ("date")        
      fileattdef( fclim, fAtt )            ; copy file attributes  

      dimNames = (/"scalar","lon","lat","time"/)  
      dimSizes = (/ nscalar, nlon, nlat, -1 /) 
      dimUnlim = (/ False, False, False, True/)   
      filedimdef(fclim,dimNames,dimSizes,dimUnlim)

      filevardef(fclim, "EDGEW" ,typeof(edgew),getvardims(edgew)) 
      filevardef(fclim, "EDGEE"  ,typeof(edgee),getvardims(edgee))                           
      filevardef(fclim, "EDGES"  ,typeof(edges),getvardims(edges))                          
      filevardef(fclim, "EDGEN"  ,typeof(edgen),getvardims(edgen))                          
      filevardef(fclim, "LONGXY" ,typeof(longxy)  ,getvardims(longxy))    
      filevardef(fclim, "LATIXY"  ,typeof(latxy) ,getvardims(latxy))          
      filevardef(fclim, "PSRF",typeof(fsds),getvardims(fsds))
      filevardef(fclim, "SHUM",typeof(rh),getvardims(rh)) 
      filevardef(fclim, "time",typeof(time),getvardims(time))          

      filevarattdef(fclim,"EDGEW",edgew)                           
      filevarattdef(fclim,"EDGEE",edgee)                   
      filevarattdef(fclim,"EDGES",edges)                    
      filevarattdef(fclim,"EDGEN",edgen)                    
      filevarattdef(fclim,"LONGXY",longxy)                     
      filevarattdef(fclim,"LATIXY",latxy)                      
      filevarattdef(fclim,"PSRF",fsds)
      filevarattdef(fclim,"SHUM",rh)
      filevarattdef(fclim,"time",time)  

      setfileoption(fclim,"DefineMode",False)

      printVarSummary(time)
      fclim->time   = (/time/)        ; "(/", "/)" syntax tells NCL to only output the data values to the predefined locations on the file.
      xfloor=plot_info(m,4)-0.05
      xceil =plot_info(m,4)+0.05
      yfloor=plot_info(m,5)-0.05
      yceil =plot_info(m,5)+0.05
      print(yceil)
      fclim->EDGEW  = (/xfloor/)
      fclim->EDGEE  = (/xceil/) 
      fclim->EDGES  = (/yfloor/) 
      fclim->EDGEN  = (/yceil/)

      printVarSummary(plot_info(m,4))
      fclim->LONGXY = (/plot_info(m,4)/)
      fclim->LATIXY  = (/plot_info(m,5)/)
      fclim->PSRF   = (/ps_hour_plot(:,m)/)    
      fclim->SHUM   = (/shum_hour_plot(:,m)/)
    end do

    delete(psl)
    delete(time)
    delete(psl_plot)
    delete(shum_ori)
    delete(shum)
    delete(shum_era_plot)
    delete(shum_plot)
    delete(ps_hour_plot)
    delete(shum_hour_plot)
    

 end do

end if

if (varCOMB) then
  do year=1981,2010,1 
  do m=0,20,1
    system("cp "+clim_output+"clm1pt_"+plot_info(m,1)+"_FSDS_"+year+"01010130-"+year+"12312230.nc "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc")
    system("ncks -h -A "+clim_output+"clm1pt_"+plot_info(m,1)+"_PRECTmms_"+year+"01010130-"+year+"12312230.nc "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc")
    system("ncks -h -A "+clim_output+"clm1pt_"+plot_info(m,1)+"_TBOT_"+year+"01010130-"+year+"12312230.nc "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc")
    system("ncks -h -A "+clim_output+"clm1pt_"+plot_info(m,1)+"_WIND_"+year+"01010130-"+year+"12312230.nc "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc")
    system("ncks -h -A "+clim_output+"clm1pt_"+plot_info(m,1)+"_PSHUM_"+year+"01010130-"+year+"12312230.nc "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc")
  end do
  end do
end if



if (varTIME) then
   do m=1,20,1
     print(m)
     shiftt=8
     do year=1981,2010,1 
        print(year)
        system("ncatted -O -a bounds,time,d,, "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc")
        system("ncatted -O -a axis,time,d,, "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc")
        system("ncatted -O -a standard_name,time,d,, "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc")
        system("ncatted -O -a calendar,time,m,c,'noleap' "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc")
        system("ncatted -O -a long_name,time,m,c,'observation time' "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc")
       
        if (isleapyear(year)) then
          system("ncrcat -O -d time,0,471 "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc test1.nc")
          system("ncrcat -O -d time,480, "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc test2.nc")
          system("ncap2 -O -s 'time=time-1' test2.nc test2.nc")
          system("ncrcat -O test1.nc test2.nc "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc")
          system("ncap2 -O -s time=time-"+shiftt+" "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc ")
          shiftt=shiftt+1 
        else
          system("ncap2 -O -s time=time-"+shiftt+" "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc "+clim_output+"clm1pt_"+plot_info(m,1)+"_"+year+".nc ")
        end if
     end do
   end do
end if

if (timCOMB) then
  do m=0,20,1
    system("ncrcat -O "+clim_output+"clm1pt_"+plot_info(m,1)+"_*.nc "+clim_output+"clm1pt_"+plot_info(m,1)+"_1981-2010.nc")
  end do
end if
     
end if

end
  



