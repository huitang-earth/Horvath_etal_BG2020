# Horvath_etal_BG2020

## Model code
   - https://github.com/metno/noresm/tree/trunk2.0-4
   - To obtain the model code, please follow the instructions on: https://wiki.met.no/noresm/start

### Modification of the code
   - The modification of the original code for each site simulation are kept in each case folder (in 'cases' folder) under "SourceMods/src.clm".
      - For all the default simulations, only one code file is modified to remove the bug in calculating 20-year averaged climatology. 
        * CNDVMod.F90

   - For sensitivity experiments with new climate thresholds for establishment, additional code modifications are required and are kept in "SourceMods/src.clm" in corresponding folders. The code files modified are:
      * accFldsMod.F90
      * accumulMod.F90
      * clmtype.F90
      * clmtypeInitMod.F90
      * CNDVEcosystemDynIniMod.F90
      * CNDVEstablishmentMod.F90
      * CNrestMod.F90
 
   - Model configuration and namelist files are also modified to allow the site simulation being setup correctly. The changes are kept in folder 'configure_changes'. They are:
      * models/atm/datm/bld/build-namelist (bug fixing)
      * models/atm/datm/bld/namelist\_files/namelist\_defaults\_datm.xml  (modification to set up single site simultion correctly)
      * models/lnd/clm/bld/namelist\_files/namelist\_defaults\_usr\_files.xml (modification to set up user defined single site simultion correctly)
      * models/drv/bld/build-namelist (bug fixing)
        
## Model input and output data 
   - Can be downloaded from: https://ns2806k.webs.sigma2.no/EMERALD/Horvath\_etal\_BG2020/ 

## Content of the repository:
   - **cases** folder: cases created for running the 20 site experiments.
      -  ****swe: sensitivity experiments adding snow water equivalent as a threshold for establishment. 
      -  ****swe_tmin: sensitivity experiments adding snow water equivalent in October, minimum temperature in May as thresholds for establishment.
      -  ****swe\_tmin\_bioclim15: sensitivity experiments adding snow water equivalent in October, minimum temperature in May, bioclim15 as thresholds for establishment. 
   - **configure_changes** folder: changes in model configuration files. The files are kept in the original model folder structure. These files have to be copied to the original model folder to replace the old ones.
   - **plot_sel.txt**: geographic information of each plot.
   - **workflow\_norway\_plots**: workflow for setting up the model simulations
   - **prepare\_inputdata\_norway\_plots.ncl**: NCL script for preparing inpudata needed for single-site simulation
   - **aerdepregrid\_norway\_plot.ncl**: NCL script for prepare aerosol deposition file needed for single-site simulation
