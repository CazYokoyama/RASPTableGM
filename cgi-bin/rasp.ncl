;;; *** RASP USERS ***
;;        this file is formally named and herein referred to as "blipmap.ncl" since it is used for both RASP and non-RASP plotting
;;        but in RASP use/documentation it is called "rasp.ncl", i.e. "rasp.ncl" and "blipmap.ncl" are identical
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; PROGRAM ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Script to 
;;        (1) calc+plot BLIPMAP parameters from WRF output file (by RASP program _or_ command line)
;;        (2) plot BLIPMAP parameters from RASP _or_ BLIP produced datafiles (by program call only)
;;        (code is convoluted because it must do all the above, i.e. can be run 4 different ways and is used for both RASP and non-RASP BLIPMAP plotting)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CREDITS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Creator:  Dr. John W. (Jack) Glendening, Meterologist  2005
;;        utilizes National Center for Atmospheric Research (NCAR) NCL graphics
;;        requires file ncl_jack.ncl written by Jack Glendening
;;        requires library ncl_jack_fortran.so written by Jack Glendening
;;        requires files wrf_user_fortran_util_0.so, wrf_plot.ncl, wrf_user_mass.ncl from the WRF website
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  USAGE NOTES  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  WRFOUT/DATAFILE PLOT determined by absence/existence of ENV_NCL_INFOFILENAME variable (since dont need it for wrfout plot)
;;  INTERACTIVE/NON-INTERACTIVE USE determined by absence/existence of ENV_NCL_ID environmental variable
;;  NON-INTERACTIVE PLOT controlled by info in environmental variables
;;        for RASP program call its used as title - for datafiles it is id used as ncgm filename tail
;;  INTERACTIVE PLOT (for wrf output file only) ala command line "ncl blipmap.ncl"
;;         controlled via internally-set info but can be altered by command-line arguments
;;  Command-line argument(s) can be used to input following plot control variables:
;;      LOUT, FILENAMES, PARAMS, REGION, LFIXEDCOLOR, CONTOURS, UNITS
;;      ala 'LOUT=3' or 'FILENAMES=(/"/home/glendeni/DRJACK/WRF/WRFV2/RASP/PANOCHE/wrfout_d02_2005-04-02_15:00:00"/)' or 'PARAMS=(/"wstar","blwind"/)' or 'REGION="PANOCHE"' or 'CONTOURS=(/0.,8.,2./)' or 'UNITS="metric"'
;;      for example an interactive command line to plot two parameters from a single WRF output data file into ncarg output metafiles is:  
;;          ncl blipmap.ncl 'PARAMS=(/"wstar","press850"/)' 'FILENAMES=(/"/home/glendeni/DRJACK/WRF/WRFV2/RASP/PANOCHE/wrfout_d02_2005-04-02_15:00:00"/)' 'LOUT=3'
;;      note use of quotes:  NCL requires the indicated double-quotes (") and single quotes (') prevent command-line processing of the string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; PROGRAMMING NOTES  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; COMMON PROBLEMS: 
;;     Compiler "error line" count starts from 0 so must add 1 to get normal "file line number" !
;;     Using "endif" instead of ncl's "end if" statement
;;     Using single-quote ' instead of double-quote "  (ncl only uses the latter)
;;; SPECIFIC ERROR MESSAGES: 
;;     Syntax error in function will cause bomb with message
;;          fatal:Undefined identifier: (ROUTINE_NAME) is undefined, can't continue
;;     When using new files with _new_ domain and an array has not been undefined:
;;          fatal:Dimension sizes of left hand side and right hand side of assignment dont match
;;; WHEN SCRIPT TAKES VERY LONG TIME TO RUN:
;;     likely trying to plot noisy field - can reduce by increasing contour spacing with option ContourParameters=(/amin,amax,ainc/) [amin=amax => only ainc used]
;;; WARNINGS:
;;     INCONSISTENCY: 3d arrays use model units (mks) _except_ velocities ua,va use UNITS units
;;; OTHER:
;;      To test when envron.variab. set/unset, must use 'ismissing(name)'  - i.e. unset variable will not be '' and  cannot test using isvar("name") 
;;      Specified "float" number must contain decimal pt to avoid "coercing to integer" warning message
;;old      FULL NCGM FILENAME HAS 80 CHARACTER LIMIT !!!
;;old         so must keep parameter name and RASP/RUN/OUT/REGIONXYZ-WINDOW  directory names short enough to achieve this
;;old         longest "normal" parameterid = 11 chars (experimental1 & others) requires BASENAME + REGIONXYZ chars <= 42
;;old         BUT "special" parameterid ala xbl_-121.32_-36.19_windk_14 = 27 chars reduces this to 26 !
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; NCL NOTES  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    "0 contour" actually slightly negative i.e. zero values always treated as a "positive" value for contouring
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; ENVIRONMENTAL VARIABLES ;;;;;;;;;;;;;;;;;;;;;;;;;;
;RASP-RUN FOR NCL PLOT OF WRFOUT FILE USED BY RASP PROGRAM,
;RASP-RUN     --- SAMPLE RASP-PROGRAM ENVIRONMENTAL VARIABLE INPUT ---
;RASP-RUN   ENV_NCL_REGIONNAME='PANOCHE' 
;RASP-RUN   ENV_NCL_FILENAME='DATA/PANOCHE/wrfout_d02_2005-01-01_21-RUN00-RUN00' 
;RASP-RUN   ENV_NCL_OUTDIR='/home/glendeni/DRJACK/WRF/NCL/OUT' 
;RASP-RUN   ENV_NCL_ID='TEST ID'              <-- NON-INTERACTIVE USE determined by existence
;RASP-RUN   ENV_NCL_PARAMS='wstar-RUNblwind' 
;RASP-RUN   OR eg
;RASP-RUN   ENV_NCL_REGIONNAME='SW_SOUTHAFRICA-WINDOW' 
;RASP-RUN   ENV_NCL_FILENAME='DATA/SW_SOUTHAFRICA-WINDOW/wrfout_d02_2005-09-12_14-RUN00-RUN00' 
;RASP-RUN   ENV_NCL_OUTDIR='/home/glendeni/DRJACK/WRF/NCL/OUT' 
;RASP-RUN   ENV_NCL_ID='TEST ID' 
;RASP-RUN   ENV_NCL_PARAMS='wstar-RUNbsratio-RUNwstar_bsratio' 
;RUC/NAM   --- SAMPLE RUC/NAM DATAFILE ENVIRONMENTAL VARIABLE INPUT ---
;RUC/NAM-DATAFILE   ENV_NCL_REGIONNAME   = "${MODELTYPE}-${gridname}" 
;RUC/NAM-DATAFILE   ENV_NCL_FILENAME     = "$TMPDIR/${gridname}/dummy.${filedatimeid}.data" 
;RUC/NAM-DATAFILE   ENV_NCL_OUTDIR       = "$TMPDIR/${gridname}" 
;RUC/NAM-DATAFILE   ENV_NCL_ID           = " " (must be non-null)   <-- NON-INTERACTIVE USE determined by existence
;RUC/NAM-DATAFILE   ENV_NCL_PARAMS       = "$param" 
;RUC/NAM-DATAFILE   ENV_NCL_INFOFILENAME = "$DIR/PLOT/dummy.${MODELTYPE}-${gridname}.data" 
;RUC/NAM-DATAFILE   ENV_NCL_CONTOURS     = 'nonfixed' 
;RASP-DATAFILE   --- SAMPLE RASP DATAFILE ENVIRONMENTAL VARIABLE INPUT ---
;;; units read from file for region set by ENV_NCL_REGIONNAME
;RASP-DATAFILE   ENV_NCL_ID           = " " (id read from each file - this is non-blank to indicate non-interactive run) 
;RASP-DATAFILE   ENV_NCL_FILENAME     = "/home/glendeni/DRJACK/RASP/SAVE/GREATBRITAIN/2007/20070211/dummy.curr.1500lst.d2.data" 
;RASP-DATAFILE   ENV_NCL_REGIONNAME     = "GREATBRITAIN" 
;RASP-DATAFILE   ENV_NCL_OUTDIR       = "/home/glendeni/DRJACK/WRF/NCL/TEMP" 
;RASP-DATAFILE   ENV_NCL_PARAMS       = "wstar" 
;RASP-DATAFILE   ENV_NCL_PARAMS       = "wstar_bsratio" 
;RASP-DATAFILE   ENV_NCL_PARAMS       = "zsfclclmask"    
;RASP-DATAFILE   ENV_NCL_PARAMS       = "sfcwindspd_sfcwinddir" 
;RASP-DATAFILE   ENV_NCL_INFOFILENAME = "/home/glendeni/DRJACK/WRF/NCL/dummy.greatbritain.g2.data" 
;RASP-DATAFILE   ENV_NCL_CONTOURS     = "nonfixed" 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; GET ENVIRON PARAMS
  ENV_NCL_ID = getenv( "ENV_NCL_ID")
  ENV_NCL_REGIONNAME = getenv( "ENV_NCL_REGIONNAME")
  ENV_NCL_FILENAME = getenv( "ENV_NCL_FILENAME")
  ENV_NCL_OUTDIR = getenv( "ENV_NCL_OUTDIR")
  ENV_NCL_PARAMS = getenv( "ENV_NCL_PARAMS")
  ENV_NCL_DATIME = getenv( "ENV_NCL_DATIME")

;;; RUC/NAM DATAFILE ADDITION - add new environmental variables
  ;;; ENV_NCL_CONTOURS = 'fixed'/'nonfixed' controls contour colors
  ENV_NCL_CONTOURS = getenv( "ENV_NCL_CONTOURS")
     ;; ENV_NCL_CONTOURING now replaced by ENV_NCL_CONTOURS - use fixup to make backward compatible
     if( ismissing(ENV_NCL_CONTOURS) ) then
       ENV_NCL_CONTOURING = getenv( "ENV_NCL_CONTOURING")
       if( .not.ismissing(ENV_NCL_CONTOURING) ) then
       ENV_NCL_CONTOURS = ENV_NCL_CONTOURING
       end if
     end if
  ;;; ENV_NCL_INFOFILENAME = template for terrain,lat,long datafiles 
  ;;; !!! ONLY RASP RUN WILL HAVE NON-BLANK ENV_NCL_INFOFILENAME !!!
  ENV_NCL_INFOFILENAME = getenv( "ENV_NCL_INFOFILENAME")

;;; print all env params
  print("ENV_NCL_ID= "+ENV_NCL_ID+" = " )
  print("ENV_NCL_REGIONNAME= "+ENV_NCL_REGIONNAME+" = " )
  print("ENV_NCL_FILENAME= "+ENV_NCL_FILENAME+" = " )
  print("ENV_NCL_OUTDIR= "+ENV_NCL_OUTDIR+" = " )
  print("ENV_NCL_PARAMS= "+ENV_NCL_PARAMS+" = " )
  print("ENV_NCL_DATIME= "+ENV_NCL_DATIME+" = " )
  print("ENV_NCL_CONTOURS= "+ENV_NCL_CONTOURS+" = " )
  print("ENV_NCL_INFOFILENAME= "+ENV_NCL_INFOFILENAME+" = " )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;; LOAD NEEDED NEEDED ROUTINE

  ;;; ncar routines
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

  ;;; wrf ncl routines 
  ;  "./" _not_ required prior to filename !
  ;;; ! no longer use  "load "gsn_code.ncl"  !!! 
  load "wrf_plot.ncl"           ; modified by jack
  load "wrf_user_mass.ncl"      ; modified by jack
  load "skewt_func.ncl"         ; modified by jack

  ;;; my fortran routines - load before my ncl routines since so they can use fortran functions
  ;  "./" _IS_ required prior to filename !
  external NCL_JACK_FORTRAN "./ncl_jack_fortran.so"
  ;4test:  external NCL_JACK_FORTRAN_TEST "./ncl_jack_fortran_test.so"
  ; gives syntax error!   external NCL_JACK_FORTRAN nclrundir+"ncl_jack_fortran.so"

  ;;; my ncl routines - must be loaded _after_ external NCL_JACK_FORTRAN
  load "blipmap_jack.ncl"      

;;; ***********************************************************************************
;;;                    START OF REQUIRED DEFAULT INPUT 
;;;                      mainly for interactive use
;;; ***********************************************************************************

;;;;;- ********** SET PLOT OUTPUT TO SCREEN/FILE/FILES **********
;;; LOUT= 0=X11 1=single_ncgm_file(rasp.ncgm)BAD_END -1=postscript(rasp.ps)
;;;       2=individual_ncgm_files 3=individual_ncgm_files+data_files 
;;;       "zero"=X11 represents command line argument which over-rides normal environmental-param plot to file
if ( .not.isvar("LOUT") ) then 
 LOUT = 3
 LOUT = 0
end if

;;;;;;;;;;;;;;;;;;; START OF REGION DEPENDENT CHOICES ;;;;;;;;;;;;;;;;;;;;

;;; ********** SELECT A REGION ********* (selects file and frame)
if ( .not.isvar("REGION") ) then 
 REGION = "GREATBRITAIN+1"
 REGION = "MINDEN"
 REGION = "SIERRA"
 REGION = "GOVCUP"
 REGION = "S_NEWZEALAND"
 REGION = "CANV"
 REGION = "SW_SOUTHAFRICA-WINDOW"
 REGION = "GREATBRITAIN"
 REGION = "BLACKFOREST_CO"
 REGION = "PANOCHE-WINDOW"
 REGION = "SW_SOUTHAFRICA"
 REGION = "WILLIAMS"
 REGION = "GREATBRITAIN-WINDOW"
 REGION = "GREATBRITAIN"
 REGION = "PANOCHE"
end if
;;; UNITS:
;;;   american => hgt=ft w*=ft/min ws=kt temp=F
;;;   celsius => ala american except temp=C
;;;   metric => hgt=m w*=cm/s ws=m/s temp=C

;;; ********** SET DATA OUTPUT FILE (PLOT INPUT) **********
; not that last item in list must NOT have a comma after it !
if ( .not.isvar("FILENAMES") ) then 
if( REGION .eq. "PANOCHE" ) then
    UNITS="american"
    FILENAMES = (/ \
    ;   "DATA/PANOCHE/wrfout_d01_2005-01-01_21:00:00", \
    ;    "DATA/PANOCHE/wrfout_d02_2005-01-01_21:00:00", \
    ;  "DATA/PANOCHE/wrfout_d02_2005-01-01_12:00:00", \
       "DATA/PANOCHE/wrfout_d02_2007-04-12_18:00:00", \
    ;   "../WRFV2/RASP/PANOCHE/wrfout_d02_2005-04-03_00:00:00", \
    "" /)
   ;old a = addfile("../WRFV2/real/PANOCHE/wrfout_d01_2005-01-01_12:00:00.nc","r")
   ;caseETA(30dec2004-6z): a = addfile("../WRFV2/test/eta_example/wrfout_d01_2004-12-30_06:00:00.nc","r")
   ;caseTESTGUI1: a = addfile("../WRFV2/test/testgui1/wrfout_d01_2000-01-24_12:00:00.nc","r")
   ;caseAVN(jan00): a = addfile("../WRFV2/test/avn_example_test/wrfout_d01_2000-01-24_12:00:00.nc","r")
   ;caseJAN00grid2: a = addfile("../WRFV2/test/em_real/wrfout_d02_2000-01-24_12:00:00.nc","r")
   ;caseJAN00grid1: a = addfile("../WRFV2/test/em_real/wrfout_d01_2000-01-24_12:00:00.nc","r")
end if
if( REGION .eq. "PANOCHE-WINDOW" ) then
    UNITS="american"
    FILENAMES = (/ \
     ;  "DATA/PANOCHE-WINDOW/wrfout_d01_2005-02-04_21:00:00", \ 
     ; "DATA/PANOCHE-WINDOW/wrfout_d02_2005-02-04_21:00:00", \ 
     ;  "DATA/PANOCHE-WINDOW/wrfout_d01_2005-03-09_21:00:00", \ 
     ;  "DATA/PANOCHE-WINDOW/wrfout_d02_2005-03-09_21:00:00", \ 
     ; "../WRFV2/RASP/PANOCHE-WINDOW/previous.wrfout_d02_2006-02-19_21:00:00", \ 
      "../WRFV2/RASP/PANOCHE-WINDOW/wrfout_d02_2005-04-02_20:00:00", \ 
    "" /)
end if
if( REGION .eq. "WILLIAMS" ) then
    UNITS="american"
   FILENAMES = (/ \
   ;  "DATA/WILLIAMS/wrfout_d01_2005-02-04_21:00:00", \
   ;  "DATA/WILLIAMS/wrfout_d02_2005-02-04_21:00:00", \
     "DATA/WILLIAMS/wrfout_d02_2007-07-25_21:00:00", \
   ;  "../WRFV2/real/WILLIAMS/wrfout_d02_2005-02-04_12:00:00", \
   "" /)
end if
if( REGION .eq. "MINDEN" ) then
    UNITS="american"
   FILENAMES = (/ \
     "../WRFV2/RASP/MINDEN/wrfout_d02_2005-03-27_18:00:00", \
   ;  "../WRFV2/RASP/MINDEN/wrfout_d02_2005-03-27_21:00:00", \
    ""  /)
end if
if( REGION .eq. "SIERRA" ) then
    UNITS="american"
   FILENAMES = (/ \
   ;  "../WRFV2/RASP/SIERRA/wrfout_d02_2005-03-27_18:00:00", \
     "../WRFV2/RASP/SIERRA/wrfout_d02_2005-03-27_21:00:00", \
    ""  /)
end if
if( REGION .eq. "CANV" ) then
    UNITS="american"
   FILENAMES = (/ \
   ;  "../WRFV2/RASP/CANV/wrfout_d01_2005-03-15_12:00:00", \
   ;  "../WRFV2/RASP/CANV/wrfout_d02_2005-03-15_12:00:00", \
     "../WRFV2/RASP/CANV/wrfout_d02_2005-03-06_21:00:00", \
   "" /)
end if
if( REGION .eq. "SW_SOUTHAFRICA" ) then
    UNITS="celsius"
   FILENAMES = (/ \
   ;  "DATA/SW_SOUTHAFRICA/wrfout_d01_2005-02-19_03:00:00", \
     "DATA/SW_SOUTHAFRICA/wrfout_d02_2005-02-19_03:00:00", \
   ;  "DATA/SW_SOUTHAFRICA/wrfout_d03_2005-02-19_03:00:00", \
   ;  "../WRFV2/real/SW_SOUTHAFRICA/wrfout_d01_2005-02-15_12:00:00", \
   ;  "../WRFV2/real/SW_SOUTHAFRICA/wrfout_d02_2005-02-15_12:00:00", \
   ;  "../WRFV2/real/SW_SOUTHAFRICA/wrfout_d02_2005-02-15_21:00:00", \
   "" /)
end if
if( REGION .eq. "SW_SOUTHAFRICA-WINDOW" ) then
    UNITS="celsius"
   FILENAMES = (/ \
     "DATA/SW_SOUTHAFRICA-WINDOW/wrfout_d02_2005-09-12_14:00:00", \
   "" /)
end if
if( REGION .eq. "GREATBRITAIN" .or. REGION .eq. "GREATBRITAIN+1" ) then
    UNITS="celsius"
    ;4test: UNITS="metric"
   FILENAMES = (/ \
     "DATA/GREATBRITAIN/wrfout_d02_2007-04-21_15:00:00", \    
   ;  "DATA/GREATBRITAIN/wrfout_d02_2007-04-12_15:00:00", \
   ;  "DATA/GREATBRITAIN/wrfout_d01_2005-08-30_15:00:00", \
   ; "DATA/GREATBRITAIN/wrfout_d02_2005-08-18_15:00:00", \
   ;  "DATA/GREATBRITAIN/wrfout_d02_2005-10-01_14:00:00", \
   ; to investigate why dartmoor sounding shows explicit cloudwater but explicit cloudwater blipmap does not \
   ; "DATA/GREATBRITAIN/wrfout_d02_2006-10-13_12:00:00", \
   "" /)
end if
if( REGION .eq. "GREATBRITAIN-WINDOW" ) then
    UNITS="celsius"
   FILENAMES = (/ \
     "DATA/GREATBRITAIN-WINDOW/wrfout_d02_2005-08-18_15:00:00", \
   "" /)
end if
if( REGION .eq. "GOVCUP" ) then
    UNITS="american"
   FILENAMES = (/ \
   ;  "../WRFV2/RASP/GOVCUP_SOUTHCOURSE/wrfout_d01_2005-03-15_12:00:00", \
   ;  "../WRFV2/RASP/GOVCUP_SOUTHCOURSE/wrfout_d02_2005-03-15_12:00:00", \
   ;  "../WRFV2/RASP/GOVCUP_SOUTHCOURSE/wrfout_d02_2005-03-06_21:00:00", \
   "" /)
end if
;4test:  UNITS="metric"
if( REGION .eq. "S_NEWZEALAND" ) then
    UNITS="celsius"
   FILENAMES = (/ \
;     "DATA/S_NEWZEALAND/wrfout_d02_2006-01-19_18:00:00", \
     "DATA/S_NEWZEALAND/wrfout_d02_2006-01-20_03:00:00", \
   "" /)
end if
if( REGION .eq. "BLACKFOREST_CO" ) then
    UNITS="american"
   FILENAMES = (/ \
     "DATA/BLACKFOREST_CO/wrfout_d02_2006-10-21_19:00:00", \
   "" /)
end if
end if

;;; ********** SET DEFAULT UNITS **********
if ( .not.isvar("UNITS") ) then 
UNITS="american"
end if

;;; ********** ADD A FRAME TO PLOT **********  (kframe depends on region (file) to display subgrids)
;;; add a frame to plot (0=none, #=const.frame.width, -1=>use_array kframe) 
;;; kframe depends on file to display subgrids - xl,yb, xr,yt USE NAMELIST FORTRAN INDEXS (offset 1/2 from mass coords) !!!
;;; DATAFILE kfile value set further below !
;; 10dec2005 - changed ldoframe 5->10 as discovered increased topo smoothing in that region with new WRF V2.1.1
kframe = new( (/3, 4/), float)
;;; set default value
   ldoframe = 5
if( REGION .eq. "PANOCHE" ) then
   kframe(0,:) = (/ 12.,16., 29.,39. /)   ; panoche3 grid2 in grid1
   kframe(1,:) = (/ 18.,31., 41.,52. /)   ; panoche3 grid3b in grid2
  ;panoche3a  kframe(1,:) = (/ 18.,15., 41.,50. /)   ; panoche3 grid3a in grid2
   kframe(2,:) = (/ 0.,0., 0.,0. /)       ; no grid4 available
end if 

;;;;;;;;;;;;;;;;;;; END OF REGION DEPENDENT CHOICES ;;;;;;;;;;;;;;;;;;;;

;;;; ********** SET INTERVAL BETWEEN PLOTTED OUTPUT TIMES **********
itinterval = 1;

;;; ********** SPECIFY PARAMETERS FOR SINGLE PARAMETER SCALAR/VECTOR PLOTS **********
; use "" for NO plots  PARAMS = (/ "" /)   ; parameters to plot (""=>none)
;;; CAPS INDICATES VARIABLES INTERNAL TO WRF OUTPUT FILE
;;; lower case indicates variables calculated by this plotting program
;;; ter plots color-fill terrain, HGT plots b+w contours
;;; following tend to be very cpu consuming:  blcloudpct, sfcsunpct, cape, experimental*
; when test allows input via command-line argument
if ( ismissing(ENV_NCL_PARAMS) .or. ENV_NCL_PARAMS .eq. "" ) then
if( .not. isvar("PARAMS") ) then
;ONE: PARAMS = (/ "sfcsunpct" /)   ; gives colorbar max error for greatbritain d2 case !
;ONE: PARAMS = (/ "sfcsunpct" /)   ;
;ONE: PARAMS = (/ "sfctemp" /)  
;ONE: PARAMS = (/ "sfcdewpt" /)  
;ONE: PARAMS = (/ "wblmaxmin" /) 
;ONE: PARAMS = (/ "dbl" /) 
;ONE: PARAMS = (/ "hbl" /) 
;ONE: 
PARAMS = (/ "wstar" /) 
;ONE: PARAMS = (/ "sfcshf" /) 
;ONE: PARAMS = (/ "qcblhf" /) 
;ONE: PARAMS = (/ "vhf" /) 
;ONE: PARAMS = (/ "hwcrit" /) 
;ONE: PARAMS = (/ "blwind" /) 
;ONE: PARAMS = (/ "sfcwind" /) 
;ONE: PARAMS = (/ "bltopwind" /) 
;ONE: PARAMS = (/ "bltopvariab" /)  
;ONE: PARAMS = (/ "cape" /)  
;ONE: PARAMS = (/ "zsfclcl" /)  
;ONE: PARAMS = (/ "zsfclcldif" /)  
;ONE: PARAMS = (/ "zblcldif" /)  
;ONE: PARAMS = (/ "blwindshear" /) 
;ONE: PARAMS = (/ "zblclmask" /)  
;ONE: PARAMS = (/ "zsfclclmask" /)  
;ONE: PARAMS = (/ "mslpress" /) 
;ONE: PARAMS = (/ "press850" /)  
;ONE: PARAMS = (/ "sounding1" /)    ; also requires sounding default lat/lon below (region-dependent)
;ONE: PARAMS = (/ "sounding0_williamstest_39._-122." /)    ; also requires sounding default lat/lon below (region-dependent)
;ONE: PARAMS = (/ "sounding0_panochetest_37._-121." /)    ; also requires sounding default lat/lon below (region-dependent)
;ONE: PARAMS = (/ "boxwmax" /)  
;ONE: PARAMS = (/ "xbl_12_12_45" /)  
;ONE: PARAMS = (/ "xbl_12_12_windk_32" /)  
;ONE: PARAMS = (/ "xbl_-122.001_39.001_windk_32" /)  
;ONE: PARAMS = (/ "experimental1" /)  
;ONE: PARAMS = (/ "experimental2" /)  
;ONE: PARAMS = (/ "rhblmax" /)  
;ONE: PARAMS = (/ "wstar_bsratio" /) 
;ONE: PARAMS = (/ "bsratio" /) 
;ONE: PARAMS = (/ "zsfclclmask" /)  
;ONE: PARAMS = (/ "blcloudpct" /)  
;ONE: PARAMS = (/ "experimental1" /)  
;ONE: PARAMS = (/ "experimental2" /)  
;ONE: PARAMS = (/ "cwbase" /) 
;ONE: PARAMS = (/ "blcwbase" /) 
;ONE: PARAMS = (/ "blcloudpct" /) 
;ONE: PARAMS = (/ "hglider" /)   ;
;ONE: PARAMS = (/ "wrf=CFRACL" /)   ;
;ONE: PARAMS = (/ "wrf=LANDMASK" /)   ;
;ONE: PARAMS = (/ "sounding1" /)    ; also requires sounding default lat/lon below (region-dependent)
;TWO PARAMS = (/ "wstar","sounding2" /)  
;TWO: PARAMS = (/ "boxwmax","press850" /)  
;TWO: PARAMS = (/ "xbl_12_12_45","press850" /)  
;TWO: PARAMS = (/ "xbl_-122.0_39.0_windk_32","press500" /)  
;TWO: PARAMS = (/ "zsfclcl", "zsfclclmask" /)  
;THREE: PARAMS = (/  "hbl", "cwbase", "zsfclcldif" /)  
;THREE: PARAMS = (/  "wstar", "bsratio", "wstar_bsratio" /)  
;THREE PARAMS = (/ "blwind", "zsfclcl", "zsfclclmask" /)  
;THREE PARAMS = (/ "hwcrit","dwcrit" /)  
;HGT: PARAMS = (/ "HGT" /)  
;WRFparam-2D: PARAMS = (/ "wrf=SNOWC" /) 
;WRFparam-2D: PARAMS = (/ "wrf=QFX" /) 
;WRFparam-3D: PARAMS = (/ "wrf=TSLB_0" /) 
;WRFparam-3D: PARAMS = (/ "wrf=SMOIS_0" /) 
;4_TEST:  PARAMS = (/ "sfcsun", "wstar", "blwind", "boxwmax", "press850","press700", "sounding1" /)  
;pressure-WRFparam: PARAMS = (/ "press850_Z" /) 
;onceonly_background: PARAMS = (/ "wstar", "boxwmax", "press850", "blwind", "press700" /)  
  print( "USING INTERNAL PARAMS = "+PARAMS )
else
  print( "USING COMMAND-LINE PARAMS = "+PARAMS )
end if
end if

;;; PARAMETER DESCRIPTIONS
; sfcsun = downward shortwave (solar) radiaion at surface (data file variable)
; sfcsunpct = downward shortwave (solar) radiaion at surface normalized by cloudless sw rad
; sfcshf = upward surface sensible heat flux  (data file variable)
; vfl = upward surface virtual heat flux 
; dbl = BL Depth (data file variable)
; hbl = Height of BL Top
; hwcrit = Height of critical updraft
; dwcrit = Depth of critical updraft
; wstar = Thermal Updraft Velocity (BL turbulence scaling velocity)
; wblmaxmin = Max/min of vertical velocity within BL
; zwblmaxmin = Height at which wblmaxmin occurs
; swblmaxmin = Height above sfc. which wblmaxmin occurs
; pwblmaxmin = Pct. of BL depth at which wblmaxmin occurs
; blwind - vector average of wind in BL
; sfcwind - surface wind
; bltopwind - wind at BL Top
; rhblmax - max of relataive humidity within BL
; blcwbase - lowest height in BL where cloud water > 
; cwbase - lowest height where cloud water > 
; blcloudpct - max. cloud pct within BL
; zsfclcl - height of LCL based on surface Td
; zsfclcldif - "Cu Potential" = hbltop - zsfclcl
; bsratio = Buoyany/Shear ratio in BL
; sfctemp - Surface temperature
; sfcdewpt - Surface dew point temperature
; experimental1,experimental2 - varies
;;;LATEST ADDITIONS
; zlbcl - height of CL based on BL avereage water vapor
; zblcldif - "OD Potential" = hbltop - zblcl
; blwindshear - wind shear in BL
; bltopvariab - BL top variability (height change for Tsfc increase of ?F)
; cape - CAPE
; hglider = minimum of hwcrit, zsfclcl, zblcl
; qblhf = BL equiv. heat flux from integrated cloud condensation
; press?MB? OR press???=?WRFparam? - pressure level plot at ?MB? mb for W (default) or ?WRFparam?  
; boxwmax - cross-section slice at position of max w within box  NB: any later press??? will include slice line and info
; xbl_?X?_?Y?_?ANGLE? - bl slice at position ?X? ?Y? with MAP angle ?ANGLE?  NB: any later press??? will include slice line and info
;        to use angle parallelling wind, use ?ANGLE? = "windk_?K?" where ?K? is desired wind grid level
;        when EITHER ?X? or ?Y? contain decimalpt then ?X? & ?Y? must be long & lat (note order!)


;;; ********** SET "FIXED" COLORS *********
;;; LFIXEDCOLOR 1= use specified min/max for certain parameters
  ; allow command line argument for this variable
  if( .not.isvar("LFIXEDCOLOR") ) then
    if( ismissing(ENV_NCL_CONTOURS) .or. ENV_NCL_CONTOURS .eq. "nonfixed" .or. ENV_NCL_CONTOURS .eq. "unfixed" ) then
      ;;; this is the default value
      LFIXEDCOLOR = 0
      print ( ">>> using NON-FIXED COLORS" )
    else
    if( ENV_NCL_CONTOURS .eq. "fixed" ) then
      LFIXEDCOLOR = 1
      print ( ">>> enable FIXED COLORS" )
    else
      ;;; must be using explicitly set contouring
      LFIXEDCOLOR = 0
      contourargs = split_string_into_array( ENV_NCL_CONTOURS,"," ) 
      CONTOURS = new( (/ 3 /), float)
      CONTOURS(0) = stringtofloat( contourargs(0) )
      CONTOURS(1) = stringtofloat( contourargs(1) )
      CONTOURS(2) = stringtofloat( contourargs(2) )
      print ( ">>> using INPUT CONTOURS = "+ENV_NCL_CONTOURS )
    end if
    end if
  end if
        
;;; ********** BL CROSS-SECTION **********
;;; *NB* BOTH END POINTS *NOT* PLOTTED
;;; ldoblsection: 0=none (but over-ridden when ldowautosection=1)
  ldoblsection=0
;;; set point cross-section is to pass through
;;;   (this seems to be actual w location whereas plot locations themselves are offset)
;     angledeg=MAPangle(float)  0.=180.=bot->top 90.=left->right (must be floatingpt !) - use 0-180 to ensure left->right
  default_mapangledeg = 45.0
  default_xofblsection = 22.   ; note this is 0 based
  default_yofblsection = 44.   ; note this is 0 based
  blsectionztop = 0.    ; non-0 to override units-specific default (units depend on region)
  ;hollister-panoche-window: g1=24,45 g2=19,44
  ; default_xofblsection = 24.   ; note this is 0 based
  ; default_yofblsection = 45.   ; note this is 0 based
;;; lblsectionvar 1=thetac 2=rh
  lblsectionvar = 1

;;; ********** W AUTO BL CROSS-SECTION *********
;;; for parameter boxwmax, plot bl slice at location of max w within specified box
;;;   *NB* W CROSSSECTION 1/2 GRIDPT OFFSET FROM ACTUAL WMAX
;;;   FOR NOW USE SAME PARAMS FOR ALL GRIDS
;;; ldowautosection: 0=none
  ldowautosection = 0
;;; boxframe sets _horiz_ box grid locations used in finding max: >0=outer_gridpts_ignored -3=>middle-third -1=>use explicitly set boximin,boximax,boxjmin,boxjmax
  boxframe = 10
;old boxframe = -3
;older boxframe = 18
;;; boxkmin.max sets _vertical_ box grid levels used in finding max
;;;    note k=24,18,14 ~700,800,850mb (~9000,6000,4500ftAGL)
  boxkmin= 14  
  boxkmax= 14 
      
;;; ********** CLOUD CROSS-SECTION **********
;;; *NB* BOTH END POINTS *NOT* PLOTTED
; sets point cross-section is to pass through (0toN-2)
; angle  0.=S-N 90.=W-E (must be floatingpt !) (left-to-right except 0=180deg=>bottom-to-top)
  cloudsectionmapangledeg = 90.
  xofcloudsection = 20
  yofcloudsection = 20
;rhs  xofcloudsection = 43
;rhs  yofcloudsection = 20
;midgrid-panoche3:
  xofcloudsection = 25
;midgrid-panoche3:
  yofcloudsection = 31

;;; ********** CLOUD WATER CRITERION **********
cwbasecriteria = 0.000010
;old cwbasecriteria = 0.000100
;;; SET CLOUD WATER CRITERION HERE
;cloudbase=cloudwater:  criterion 1.e-6 used by routine cal_cldfra in module_radiation_driver.F (but its cloud fraction gives only values of ~0 or ~1!)
;cloudbase=cloudwater:  criterion 1.e-4 based on value seen used in a plot on-line
;cloudbase=cloudwater:  criterion 1.e-5 based on geometric avg of 10-4 & 10-6
;cloudbase=cloudwater:  criterion 5.e-5 based on 1/10 of obs. max of 0.5xe-3 in bl
;cloudbase=rh:          cwbasecriteria = 90.

;;; ********** SPECIFY SOUNDING PLOT DEFAULTS **********
;;; set *DOMAIN*DEPENDENT* id,lat,lon by building sounding list - 1st index=domain(1=>d01) 
;;; set default value of nsounding for internal sounding info (can re-set below to value up to dimension sounding_ids -1)
nsounding = 0
sounding_ids  = new( (/ 3 /), string)
sounding_lats = new( (/ 3 /), float)
sounding_lons = new( (/ 3 /), float)
;;; set test defaults for sounding1
if ( REGION .eq. "PANOCHE" .or. REGION .eq. "PANOCHE-WINDOW" ) then
  nsounding = 1
  sounding_ids(1) = "TEST-HOLLISTER" 
  sounding_lats(1) =   36.893         ; hollister airport
  sounding_lons(1) = -121.410         ; hollister airport
  sounding_ids(1) = "TEST-HERNANDEZ" 
  sounding_lats(1) = 36.360   ; actual hernandez lat
  sounding_lons(1) = -120.786 ; actual hernandez lon
  sounding_lats(1) = 36.34 ; adjusted hernandez to move g2 location 1 grid pt toward bottom
  sounding_lons(1) = -120.76  ; adjusted hernandez to move g2 location  1 grid pt toward bottom
  sounding_ids(1) = "TEST-PANOCHE" 
  sounding_lats(1) = 36.6105   ; actual panoche lat
  sounding_lons(1) = -120.8853  ; actual panoche lon
  sounding_lats(1) = 36.605 ; moved g2 location  right,down 2,1 gridpts so representative of valley
  sounding_lons(1) = -120.795  ; moved g2 location  right,down 2,1 gridpts so representative of valley
  sounding_lats(1) = 36.6 ; adjusted panoche to move g2 location  1 gridpt toward right so more representative of valley
  sounding_lons(1) = -120.87  ; adjusted panoche to move g2 location  1 gridpt toward right so more representative of valley
  sounding_lats(1) = 36.61 ; adjusted panoche to move g2 location  2 gridpts toward right so more representative of valley
  sounding_lons(1) = -120.85  ; adjusted panoche to move g2 location 2 gridpts toward right so more representative of valley
  sounding_lats(1) = 36.62 ; adjusted panoche to move g2 location  2 gridpts toward right so more representative of valley
  sounding_lons(1) = -120.84  ; adjusted panoche to move g2 location 2 gridpts toward right so more representative of valley
  sounding_ids(1) = "HOLLISTER AIRPORT" 
  sounding_lats(1) =   36.893         ; hollister airport
  sounding_lons(1) = -121.410         ; hollister airport
  sounding_ids(2)  = "PANOCHE STRIP" 
  sounding_lats(2) =   36.62   ; panoche - moved g2 location right 2 gridpts so more representative of valley
  sounding_lons(2) = -120.84   ; panoche - -120.84  moved g2 location right 2 gridpts so more representative of valley
  nsounding = 2
end if
if ( REGION .eq. "WILLIAMS" .or. REGION .eq. "WILLIAMS-WINDOW" ) then
  nsounding = 1
  sounding_ids(1) = "TEST-WILLIAMS" 
  sounding_lats(1) = 39.164 
  sounding_lons(1) = -122.132
end if
if ( REGION .eq. "S_NEWZEALAND" ) then
  nsounding = 1
  sounding_ids(1) = "TEST-S_NEWZEALAND" 
  sounding_lats(1) = -45. 
  sounding_lons(1) = 170.
end if
if ( REGION .eq. "GREATBRITAIN" ) then
  nsounding = 1
  sounding_ids(1) = "GREATBRITAIN-Dartmoor(#1)"
  sounding_lats(1) = 50.5
  sounding_lons(1) = -4.0  
;  sounding_ids(2) = "GREATBRITAIN-Newtown(#2)"
;  sounding_lats(2) = 52.5
;  sounding_lons(2) = -3.0  
;  sounding_ids(3) = "GREATBRITAIN-Nottingham(#3)"
;  sounding_lats(3) = 53.0
;  sounding_lons(3) = -1.2  
;  sounding_ids(4) = "GREATBRITAIN-Harrogate(#4)"
;  sounding_lats(4) = 54.0
;  sounding_lons(4) = -1.5  
end if
if ( REGION .eq. "BLACKFOREST_CO" ) then
  nsounding = 1
  sounding_ids(1) = "TEST-BLACKFOREST_CO" 
  sounding_lats(1) = 39.29 
  sounding_lons(1) = -104.57
end if

;;; SET ADDITIONAL INTERACTIVE VARIABLES HERE
;; ldatatype:  0=> plot from RASP wrfout  1,2=> plot from RASP,BLIP datafile
 ldatatype = 0
;;
 titleline3  = ""
 ;4test: titleline3  = "This is the Third plot Title Line"

;;; SET WORKSTATION SPACE when WANT MORE THAN DEFAULT 16777216 -  got space failure of GB grid 3 plot of blcloudpct
;;;     failure message: ContourPlotPreDraw: Workspace reallocation would exceed maximum size
;;; ( 33554432 value used in example at http://www.ncl.ucar.edu/Document/Graphics/error_msg.shtml)
;ok for most cases: 
; PAULS WORKSTATIONSPACE = 25165824
; PAULS - This is not enough!!WORKSTATIONSPACE = 36000000
WORKSTATIONSPACE = 50000000

;used for 116x311 GREATBRITAIN g3 case but still failure for blcloudpct: WORKSTATIONSPACE = 36000000

;;; ***********************************************************************************
;;;                    END OF REQUIRED DEFAULT INPUT
;;; ***********************************************************************************

;;;;;; PARAMETER VARIABLES
;;; bsratio PARAMETERS
;;; drag coeff - note that cdbl based on blavg windspeed, not sfc - so expect it to be smaller than sfc.cd
  cdbl = 0.003
;;;  plot display limit on bsratio for low windspeed cases
  limitbsratio = 20.

;;; MISC PARAMS
  ;;; default OUTDIR for interactive runs (when not re-set via environ.variable ENV_NCL_OUTDIR)
  OUTDIR = "OUT"
  ;;; radian->degree conversion
  rad2deg = 45.0/atan(1.0)
;;; for ruc/nam or interactive
  qdatimeinfo = ""
;;; for reading header info from datafile
  qblank_180 = "                                                                                                                                                                                    "
  qdummy = qblank_180
;;; for projection type
  qproj7 = "       "

;; ADDED FOR VIEWPORT ARGUMENTS
;;; main... used for all wrf_new_... calls EXCEPT map... used for wrf_new_map
;;; dont know significant when any of different values for main vs map height/width
;;; main seems to affect titles, labelbar, text
;;; map seems to affect plot itself
;;; methinks best to set both main... and map... variables to same value to avoid potential problems !
    mainvpwidth = 0.80   ; note that mainvpwidth or mainvpheight used (based on ratio), not both
    mainvpheight = 0.70  ; note that mainvpwidth or mainvpheight used (based on ratio), not both
    mainvpx = 0.5*( 1.-mainvpwidth )
    mainvpy = 0.87
    ;original mainvpwidth = 0.85   ; note that mainvpwidth or mainvpheight used (based on ratio), not both
    ;original mainvpheight = 0.65  ; note that mainvpwidth or mainvpheight used (based on ratio), not both
    ;original     mapvpx = 0.10
    ;original     mapvpy = 0.87
    ;original     mapvpwidth = 0.80   ; note that mapvpwidth or mapvpheight used (based on ratio), not both
    ;original     mapvpheight = 0.70  ; note that mapvpwidth or mapvpheight used (based on ratio), not both
;preAug2006(smaller_plotheight)  mainvpy = 0.89
;preAug2006(smaller_plotheight)  mainvpheight = 0.75   ; note that mainvpwidth or mainvpheight used (based on ratio), not both
;preAug2006(smaller_plotheight)  mainvpwidth = 0.75  ; note that mainvpwidth or mainvpheight used (based on ratio), not both
;larger_plotheight (instead of 0.75)

    mainvpy = 0.89  ; allow for title space above plot (title spacing set in procedure _SetMainTitle)
;cutoff_labelbar_soln=raise_entire_plot(dec2006): mainvpy = 0.895  ;  (instead of 0.890)
;old mainvpheight = 0.83   ; note that mainvpwidth or mainvpheight used (based on ratio), not both
;old mainvpwidth = 0.83  ; must allow room on side for axis labels on slice plots
;cutoff_labelbar_soln=reduce_plotsize(dec2006): 
    mainvpheight = 0.82   ; (instead of 0.83)
;cutoff_labelbar_soln=reduce_plotsize(dec2006): 
    mainvpwidth = 0.82  ; (instead of 0.83)
    ;;; calc others vp values based on above
    mainvpx = 0.5*( 1.0 - mainvpwidth )

    mapvpx = mainvpx
    mapvpy = mainvpy
    mapvpwidth = mainvpwidth   ; note that mapvpwidth or mapvpheight used (based on ratio), not both
    mapvpheight = mainvpheight ; note that mapvpwidth or mapvpheight used (based on ratio), not both

;;; set IWINDOW based on file name (for use by RASP users)
    if( .not.ismissing(ENV_NCL_FILENAME) .and. ( string_pattern_grep(ENV_NCL_FILENAME,"-WINDOW").gt.0 .or. string_pattern_grep(ENV_NCL_FILENAME,".w2.").gt.0 ) ) then
       IWINDOW = 1 
    else
       IWINDOW = 0 
    end if

    ;;; FOR SITE SUBSTITUTIONS  (jack: if alter filename also change BLIP/PLOT/filename)
    load "rasp.site_load.initialization.ncl" 

;********************************************************************************************
;*************************  NCL FUNCTIONS FOLLOW  *******************************************
;********************************************************************************************
;;; MOST NCL FUNCTIONS NOW  REPLACED BY FORTRAN ROUTINES TO IMPROVE EFFICIENCY  
;--------------------------------------------------------------------------------
  undef("uv2mapangle")
  function uv2mapangle( u:float,v:float )
  ;;; note that u,v are in _grid_ coordinate directions
  local mapangledeg
  begin
    ; note that final mapangledeg must have range 0-359.9
    mapangledeg = 57.29578*atan2( u,v )
    if( mapangledeg.lt.0.0 ) then
       ;4range0-360
       mapangledeg = mapangledeg + 360.
       ;4range0-180: mapangledeg = mapangledeg + 180.
    end if
    if( mapangledeg.gt.360.0 ) then
    ;4range0-180: if( mapangledeg.gt.180.0 ) then
       ;4range0-360
       mapangledeg = mapangledeg - 360.
       ;4range0-180: mapangledeg = mapangledeg - 180.
    end if
    return(mapangledeg)
  end
;--------------------------------------------------------------------------------
;********************************************************************************************
;*************************  END OF FUNCTIONS  ***********************************************
;********************************************************************************************

;;; FOR QUICK TESTS
; instring = "quicktest test"
; instring = "quicktest "
; instring = "quicktest"
; instring = "quicktest:test1:test2"
; outstring = extract_string_field( instring,3,":" )
; print ( "instring,outstring="+instring+"="+outstring+"=" )
; exit

;;; ***********************************************************************************
;;;                    START OF EXTERNAL DATA INPUT
;;; ***********************************************************************************

;;; NON-INTERACTIVE RUN indicated by existence of non-null ENV_NCL_ID variable - for rasp used as title - for datafiles is id used in ncgm filenames
if( .not. ismissing(ENV_NCL_ID) ) then

   ;;; NON-INTERACTIVE RUN indicated by existence of non-null ENV_NCL_ID variable - for rasp used as title - for datafiles is id used in ncgm filenames
   ;;; set here since ENV_NCL_ID overwritten later
   qfileid = trim_string( ENV_NCL_ID )

   ;;; FOR RASP NON-INTERACTIVE RUN, EXTRACT DATE/TIME FROM ENV_NCL_ID FOR DATAFILE 
   if( .not. ismissing(ENV_NCL_DATIME) ) then
     qdatimeinfo = ENV_NCL_DATIME
   end if

   ;;; ENVIRON.PARAM SETTINGS OVER-RIDE PREVIOUSLY SET DEFAULTS
   ;;; LOUT = "zero" represents command line argument which over-rides normal plot to file
   if( LOUT .eq. "zero" ) then
     LOUT = 0
   else 
     if( LOUT .eq. "two" ) then
       LOUT = 2
     else
       LOUT = 3
     end if
   end if
   OUTDIR = ENV_NCL_OUTDIR
   REGION = ENV_NCL_REGIONNAME
   delete( FILENAMES ) 
   FILENAMES = (/ ENV_NCL_FILENAME /)
   if ( isvar("PARAMS") ) then 
      delete ( PARAMS )
   end if

   ;temp start of section moved from below to correct misplacement
   ;;; READ RASP PARAMETER LIST - SET BY @imagenamelist IN rasp.pl
   if ( .not. ismissing(ENV_NCL_PARAMS) .and. ENV_NCL_PARAMS .ne. "" ) then
     ;;; convert colon-delimited environmental string into parameter array (what a mess!)
     ;4testprint: print ( "RASP STRING= "+ENV_NCL_PARAMS )
     string_chars = stringtochar( ENV_NCL_PARAMS )
     string_max  = dimsizes(string_chars)-2
     ;;; set PARAMS array size based on number of parameter names
     PARAMS = new( (string_pattern_grep(ENV_NCL_PARAMS,":")+1), string )
     ichar1=0
     kname=-1
     do ichar=1,string_max
      ; allow for either colon or no-colon at end of string
      if( string_chars(ichar).eq.":" .or. ichar.eq.string_max) then
        kname = kname +1
        if( ichar.eq.string_max) then
          ichar2 = string_max
        else
          ichar2 = ichar-1
        end if
        PARAMS(kname) = chartostring( string_chars(ichar1:ichar2) ) 
        ;4testprint: print ( "RASP PARAM= "+kname+" : "+ichar1+"-"+ichar2+" => "+temp_names(kname) )
        ichar1= ichar+1
       end if
     end do    
     print ( "PLOT PARAMS = "+PARAMS )
   else
     ;;; for missing ENV_NCL_PARAMS env parameter => rasp tests
     PARAMS = (/ "sfcsun", "wstar", "blwind", "boxwmax", "press850","press700", "sounding1" /)  
     ; PARAMS = (/ "sfcsun", "sfcshf", "dbl", "hbl", "hwcrit", "wstar", "wblmaxmin","zwblmaxmin", "blwind","sfcwind","bltopwind","rhblmax","blcwbase", "zsfclcl","zsfclcldif","zsfclclmask", "bsratio", "sfctemp","sfcdewpt", "zblcl","zblcldif","zblclmask", "bltopvariab", "blwindshear", "cape", "boxwmax", "press850","press700","press500", "sounding1" /)  
     ;single_params_only: PARAMS = (/ "sfcsun", "sfcshf", "dbl", "hbl", "hwcrit", "wstar", "wblmaxmin","zwblmaxmin", "blwind","sfcwind","bltopwind","rhblmax","blcwbase", "zsfclcl","zsfclcldif","zsfclclmask", "bsratio", "sfctemp","sfcdewpt", "zblcl","zblcldif","zblclmask", "bltopvariab", "blwindshear", "cape" /)  
     print ( "RASP *TEST* PARAMS ="+PARAMS )
   end if
  ;;; RUC/NAM ADDITION - set ldatatype
  ;;; DATAFILE RUN (VICE WRFOUT FILE) indicated by existence of ENV_NCL_INFOFILENAME variable
  ;;; RUC/NAM (non-RASP) ALWAYS PLOTS FROM DATAFILE, RASP NEVER PLOTS FROM DATAFILE
  if( .not. ismissing(ENV_NCL_INFOFILENAME) .and. ENV_NCL_INFOFILENAME.ne."" ) then
     ;;;;;; ------ SET DATAFILE-PLOT FLAG ------
     ;;; DETERMINE WHETHER RASP OR BLIP DATAFILE
     ;temp start of added part
     if ( string_pattern_grep(ENV_NCL_FILENAME,"RASP").gt.0 .or. string_pattern_grep(ENV_NCL_FILENAME,"ASP").gt.0 ) then
       ldatatype = 1
       ;;; set frame width for rasp case
       ldoframe = 5
     end if
     if ( string_pattern_grep(ENV_NCL_FILENAME,"BLIP").gt.0 ) then
       ldatatype = 2
       ;;; dont draw a frame for ruc/nam cases
       ldoframe = 0
       ;;; ensure american units used for BLIP runs
       UNITS="american"
     end if
     if ( ldatatype .eq. 0 ) then
        print ( "*** ERROR EXIT - cannot determine RASP or RUC/NAM datafile from "+ENV_NCL_FILENAME )
        exit      
     end if
     print( "PLOTTING FROM datafile (ldatatype="+ldatatype+")" )
     ;;; units set by env input variable
;testing     if( .not. ismissing(ENV_NCL_REGIONNAME ) ) then
;testing       UNITS = ENV_NCL_REGIONNAME
;testing     end if 
     ;;; set nsounding=0 to no plot sounding locations since wrfout needed to get lat,lon by add_sounding_locations
     nsounding = 0
     ;temp end of added part
  else
      ;;;;;; ------ SET WRFOUT-PLOT FLAG ------
     ldatatype = 0
     print( "PLOTTING FROM wrfout file (ldatatype="+ldatatype+")" )
  end if
   ;4testprint print( "LDATATYPE="+ldatatype )
   ;old region_chars = stringtochar( ENV_NCL_REGIONNAME )
   ;old if( region_chars(3).eq."-" ) then
   ;; ruc/nam addition - ruc/nam-only/rasp-only if
   if( ldatatype.ne.0 ) then
   ;;;;;; ------ START OF DATAFILE-PLOT SECTION ------
      ;;; set third title line
      titleline3  = ""
   ;;;;;; ------ END OF DATAFILE-PLOT SECTION ------
   else
   ;;;;;; ------ START OF WRFOUT-PLOT SECTION ------
      titleline3  = "RASP BLIPMAP - WRF Forecast"
     ;temp end of section moved from below to correct misplacement

      ;;; RASP UNITS AND SOUNDING INFO READ FROM FILE (ELSE USE DEFAULT UNITS SET HERE WITH NO SOUNDINGS)
      ;;; default is for no sounding plots (since no sounding location info!)
      ;;; set plot region info datafile name
      RegionInfoFilename = "rasp.ncl.region.data"
      ;;; READ REGION INFORMATION FILE
      delete( sounding_ids )
      delete( sounding_lats )
      delete( sounding_lons )
      sounding_ids  = new( (/ 30 /), string)
      sounding_lats = new( (/ 30 /), float)
      sounding_lons = new( (/ 30 /), float)
      ;4testprint:  print ( "ENV_NCL_REGIONNAME= "+ENV_NCL_REGIONNAME )
      ;;; read datafile strings
      regioninfo   = asciiread( RegionInfoFilename, -1, "string" ) ; read all rows as strings
      nregioninfo = dimsizes( regioninfo )
      ;4testprint: print ( "NREGIONINFO= "+nregioninfo )
      ;old nregionc = dimsizes(stringtochar(ENV_NCL_REGIONNAME))-1  ; dont need to account for added carriage return(CR)
      ;sounding_loc_plot
      nsounding = 0
      ;;; set truncated name for datafile search
      idregioninfo = ENV_NCL_REGIONNAME
      if ( string_pattern_grep(ENV_NCL_REGIONNAME,"-") .gt. 0 ) then
        ;;; allow REGIONXYZ-1 to use same info as REGIONXYZ
        idregioninfo = extract_string_field( ENV_NCL_REGIONNAME, 1, "-" )
      end if
      if ( string_pattern_grep(ENV_NCL_REGIONNAME,"+") .gt. 0 ) then
        ;;; allow REGIONXYZ+1 to use same info as REGIONXYZ
        idregioninfo = extract_string_field( ENV_NCL_REGIONNAME, 1, "+" )
      end if
     ;4test: 
;TESTTESTING
print( "ABBREV.REGIONINFO= "+ENV_NCL_REGIONNAME+" => "+idregioninfo )
      do iline=0,(nregioninfo-1)
         ;4testprint: print ( iline+" LINE= "+regioninfo(iline) )
         if( regioninfo(iline) .eq. "==="+idregioninfo  ) then
         ;old if( regioninfo(iline) .eq. "==="+ENV_NCL_REGIONNAME ) then
         ;ok    if( xc(0:nxc) .eq. ENV_NCL_REGIONNAME ) then
         ;ok    if ( nxc.ge.nregionc .and. ENV_NCL_REGIONNAME.eq.chartostring(xc(0:nregionc))) then
            print ( "REGION PLOT INFO READ for "+ENV_NCL_REGIONNAME )
            ; read units
            UNITS = extract_string_field( regioninfo(iline+1),1," " )
            ;old UNITS = regioninfo(iline+1)
            print ( "   UNITS= "+UNITS )
            ;;; read any sounding info
            ;4testprint: print ( "  ILINE== "+iline+" NREGIONINFO= "+nregioninfo )
            if( iline+5 .le. (nregioninfo-1) ) then
               do jline=iline+2,(nregioninfo-1),4
                  ;;; use only first string (blank delimited) so can append comment to data line
                  xc  = stringtochar( extract_string_field( regioninfo(jline),1," " ) )        
                  nxc = dimsizes(xc)-1
                  ;old                  xc  = stringtochar( regioninfo(jline) )          ; xc will have CR
                  ;old                  nxc = dimsizes(xc)-2
                  ;4testprint: print ( "JLINE= "+jline+" NXC= "+nxc+" XC= "+xc )
                  if ( nxc.ge.8 .and. chartostring(xc(0:7)).eq."sounding" ) then
                  ;sequential nsoundingp1 = nsounding + 1
                  ;sequential if ( nxc.ge.9 .and. chartostring(xc(0:8)).eq."sounding"+nsoundingp1 ) then
                     isounding = stringtointeger( chartostring( xc(8:nxc)  ) )
                     ;bad isounding = chartointeger( xc(8:nxc)  ) 
                     ;sounding_loc_plot
                     nsounding = nsounding + 1
                     ;4testprint: print ( "ISOUNDING= "+isounding )
                     ;4testprint: print ( "SOUNDING= "+regioninfo(jline) )
                     ;;; extract sounding id,lat,lon from file
                     sounding_ids(isounding) = extract_string_field( regioninfo(jline+1),1," " )
                     sounding_lats(isounding) = stringtofloat(  extract_string_field( regioninfo(jline+2),1," " ) )
                     sounding_lons(isounding) = stringtofloat(  extract_string_field( regioninfo(jline+3),1," " ) )
                     print( "   SOUNDING "+isounding+" : ID= "+sounding_ids(isounding)+" LAT= "+sounding_lats(isounding)+" LON= "+sounding_lons(isounding) )
                  else
                    break
                  end if
                  delete(xc)
               end do
            end if
            ;;; expect to exit loop here after all data read
            break
         end if
         ;4testprint: print ( " END OF LOOP" )
      end do
      ;;; test for successful read
      if( .not. isvar("UNITS") ) then
        ;;; RASP DEFAULT UNITS SET HERE
        UNITS="american"
        print( "*** NO REGIONAL DATA FOUND IN FILE READ so using default UNITS= "+UNITS )
        exit
      end if
      ;temp original location of section moved above to correct misplacement 

     ;;; SET VALUES WHICH DEPEND ON REGION UNITS
     ;;; set region-dependent bl section top
     if( UNITS .ne. "metric" ) then
       blsectionztop = 18.   ; in Kft
     else
       blsectionztop = 6.   ; in Km
     end if

     ;RASP: ;;; ********** IN rasp.pl, MUST SET NUMBER OF SOUNDINGS EXPECTED (immediately below set of @imagenamelist) **********
     ;4test_1plot: use following to reduce plots produced 
     ;4test_1plot+ delete ( PARAMS )
     ;4test_1plot+ bPARAMS = (/ "sfcsun" /)  
     ;4test_1plot+ ldowautosection = 0

   ;;;;;; ------ END OF WRFOUT-PLOT SECTION ------
   end if

end if
;4test: print ( "ENV_NCL_OUTDIR,OUTDIR= "+ENV_NCL_OUTDIR+", "+OUTDIR )

;;; ***********************************************************************************
;;;                    END OF EXTERNAL DATA INPUT
;;; ***********************************************************************************

;colors: some color examples from example cn14
;colors         (/1.00,1.00,1.00/), \  ; white
;colors         (/0.00,0.00,0.00/), \  ; black
;colors         (/0.00,0.00,1.00/), \  ; blue
;colors         (/0.20,0.56,0.80/), \  ; sky blue
;colors         (/0.00,1.00,1.00/), \  ; cyan
;colors         (/0.50,0.00,1.00/), \  ; blue magenta
;colors         (/0.00,1.00,0.00/), \  ; green
;colors         (/0.14,0.56,0.14/), \  ; forest green
;colors         (/1.00,1.00,0.00/), \  ; yellow
;colors         (/1.00,0.50,0.00/), \  ; orange
;colors         (/1.00,0.00,1.00/), \ ; magenta
;colors         (/1.00,0.00,0.00/), \ ; red
;colors         (/0.65,0.16,0.16/), \ ; brown
;colors         (/0.86,0.58,0.44/), \ ; tan
;colors         (/0.66,0.66,0.66/), \ ; light gray
;colors         (/0.40,0.40,0.40/) /) ; dark gray

;textcode: wrf_plot.ncl ~=delimiter (start+end)
;textcode: font= F21=helvetica F22=helvetica-bold
;textcode: degree= ~F34~0~F21~ 
;textcode: superscript= ~S~2~N~ 
;textcode: size(indexical)= ~I~x~P~ 

;jack - SETUP OUTPUT
if ( LOUT .eq. 0 ) then
  wks = wrf_open_X11()                ; output to screen
  ;;; INCREASE WORKSPACE ABOVE DEFAULT IF REQUESTED
  if( WORKSTATIONSPACE .gt. 0 ) then
    setvalues NhlGetWorkspaceObjectId()
       "wsMaximumSize": WORKSTATIONSPACE
     end setvalues
  end if
end if
if ( LOUT .eq. 1 ) then
  wks = wrf_open_ncgm("rasp")   ; output to ncgm
  ;alt wks = gsn_open_wks("ncgm","rasp")   ; output to ncgm
  ;;; INCREASE WORKSPACE ABOVE DEFAULT IF REQUESTED
  if( WORKSTATIONSPACE .gt. 0 ) then
    setvalues NhlGetWorkspaceObjectId()
       "wsMaximumSize": WORKSTATIONSPACE
     end setvalues
  end if
end if
if ( LOUT .eq. -1 ) then
  wks = wrf_open_PS("rasp")     ; output to postscript
  ;;; INCREASE WORKSPACE ABOVE DEFAULT IF REQUESTED
  if( WORKSTATIONSPACE .gt. 0 ) then
    setvalues NhlGetWorkspaceObjectId()
       "wsMaximumSize": WORKSTATIONSPACE
     end setvalues
  end if
end if
;;; LOUT= "zero"=>X11 represents command line argument which over-rides normal environmental-param plot to file
if ( LOUT .eq. "zero" ) then
  LOUT = 0
end if

;;; ALLOW PLOTTING TO INDIVIDUAL OUTPUT FILES
iframe=0

;;; IF NON-INTERACTIVE, PRINT ID
if ( .not. ismissing(ENV_NCL_ID) .and. ENV_NCL_ID .ne. "" ) then
  print ( "RUNID= "+ENV_NCL_ID+"=" )
end if

print ( "REGION= "+REGION )

;;; set initial wall clock time for elapsed time calc
wcStrt = systemfunc("date")  ; current ("now") time

;;; START LOOP OVER ALL OF THE FILES TO BE PROCESSED
nfiles = dimsizes(FILENAMES)  ; number of files
do ifile = 0,(nfiles-1)

  ;;; FOR SITE SUBSTITUTIONS  (jack: if alter filename also change BLIP/PLOT/filename)
  load "rasp.site_load.loop-top.ncl" 

;;; SET FILENAME
;       WRF MASS input file - dont remove ".nc" in following line

;;; START OF BLANK FILENAME IF TO EXIT
; allow blank filename to exit (allows easier alteration of FILENAMES array cant have comma after last entry)
if ( .not. ismissing(FILENAMES(ifile)) .and. FILENAMES(ifile) .ne. "" ) then

   ;;; ruc/nam addition - ruc/nam-only/rasp-only if
   if( ldatatype.ne.0 ) then
   ;;;;;; ------ START OF DATAFILE-PLOT SECTION ------
      ;;; SET RUC/NAM DATA VARIABLES
;TESTING-      UNITS = "american" 
;;;TESTING
print( "***TESTING UNITS="+UNITS )
;;;TESTING
print( "***TESTING LDOFRAME="+ldoframe )
;;;TESTING
;;; IS BELOW NEEDED ? OR DOES USE DEFAULT SET ABOVE ?
;unused if ( .not.isvar("UNITS") ) then 
;unused UNITS="american"
;unused end if
      times = new( (/1/), integer)
      it = 0
      times(0) = 0
      ;;; EXPECT TO ALWAYS NEED FOLLOWING VARIABLES SO SIMPLY GET THEM PRIOR TO VARIALBES
      blipdata_nnx = 0
      blipdata_nny = 0
      ;4test(blip-canv)      blipdata_nnx = 45
      ;4test(blip-canv)      blipdata_nny = 58
      terrain_filename = string_target_replace( ENV_NCL_INFOFILENAME, "dummy", "terrain" )
      if ( isfilepresent(terrain_filename) ) then
        NCL_JACK_FORTRAN :: read_blip_data_size( terrain_filename, blipdata_nnx,blipdata_nny ) 
      else
        print ( "*** ERROR EXIT - cannot find terrain file "+terrain_filename )
        exit
      end if
      ;old terrain_filename = ENV_NCL_INFOFILENAME+"/terrain."+ENV_NCL_REGIONNAME+".data"
      isize = blipdata_nnx
      jsize = blipdata_nny
      print ( "BLIP PARAMS:  NNX= "+blipdata_nnx+"  NNY="+blipdata_nny )
      terft = new( (/jsize,isize/), float)
      NCL_JACK_FORTRAN :: read_blip_datafile( terrain_filename, isize,jsize, terft, qdummy ) 
      ;;; terft used for some dimensioning purposes so also set it
      ter = 0.304800 * terft    
      ; get projection params - initialization needed to prevent "undefined" error
      NNX = 0
      NNY = 0
      dx = 0.
      dy = 0.
      projlat1 = 0.
      projlat2 = 0.
      projlon = 0.
      centerlat = 0.
      centerlon = 0.
      NCL_JACK_FORTRAN :: read_blip_data_info( terrain_filename, NNX,NNY, qproj7,dx,dy,projlat1,projlat2,projlon,centerlat,centerlon )
      ;old NCL_JACK_FORTRAN :: read_blip_data_info( terrain_filename, NNX,NNY, dx,dy,projlat1,projlat2,projlon,centerlat,centerlon )
      if( isize .ne. NNX .or.  jsize .ne. NNY ) then
         print ( "*** NCL ERROR EXIT *** terrain array mismatch: "+isize+","+jsize+" vs "+NNX+","+NNY )
         exit
      end if
      ;;; qgridinfo should not be needed for BLIP, but set just in case
      qgridinfo = "Model= blipmap.ncl Region= "+REGION+" Indexs="+" 1 "+sprinti("%i",isize)+" 1 "+sprinti("%i",jsize)+" Proj= lambert"+sprintf(" %.0f",dx)+sprintf(" %.0f",dy)+sprintf(" %.4f",projlat1)+sprintf(" %.4f",projlat2)+sprintf(" %.4f",projlon)+sprintf(" %.4f",centerlat)+sprintf(" %.4f",centerlon)
      ;old qgridinfo = "Model= rasp.ncl Region= "+REGION+" Indexs= 1 "+sprinti("%i",isize)+" 1 "+sprinti("%i",jsize)
      ;;; now also read/set lat/lon
      alat = new( (/jsize,isize/), float)
      alon = new( (/jsize,isize/), float)
      lat_filename = string_target_replace( ENV_NCL_INFOFILENAME, "dummy", "latitude" )
      lon_filename = string_target_replace( ENV_NCL_INFOFILENAME, "dummy", "longitude" )
      ;;; if lat,lon file not available then calculate it
      if ( isfilepresent(lat_filename) .and. isfilepresent(lon_filename) ) then
        NCL_JACK_FORTRAN :: read_blip_datafile( lat_filename, isize,jsize, alat, qdummy ) 
        NCL_JACK_FORTRAN :: read_blip_datafile( lon_filename, isize,jsize, alon, qdummy ) 
      else
        NCL_JACK_FORTRAN :: calc_latlon( isize,jsize,dx,dy,projlat1,projlat2,projlon,centerlat,centerlon, alat,alon )
      end if
      ;;; UGLY RUC/NAM COMPOSITE KLUDGE FORCES CONGRUENCE WITH NON-COMPOSITE BLIPMAP
      ;;; overwrite previously set viewport variables
      if( ldatatype .eq. 2 ) then
         ;;; set viewport info here to mimic corners of ruc/nam non-composite blipmaps
         mainvpheight = 0.839  ;
         mainvpwidth = 0.920 ; 
         mainvpy = 0.88  ;
         if( isize .gt. jsize ) then
            ;;; following is for image-limited-by-WIDTH regions
            testmainvpheight = mainvpwidth * jsize / isize  ;
            if( testmainvpheight .le. mainvpheight ) then
              mainvpheight = testmainvpheight 
            end if
         end if
         mainvpx = 0.5*( 1.-mainvpwidth )
         mapvpheight = mainvpheight ;
         mapvpwidth = mainvpwidth   ;
         mapvpx = mainvpx
         mapvpy = mainvpy
         print( "RUC/NAM COMPOSITE KLUDGE VIEWPORT => isize,jsize,mapvpwidth,mapvpheight,mapvpx,mapvpy= "+isize+","+jsize+","+mapvpwidth+","+mapvpheight+","+mapvpx+","+mapvpy )
      end if
   ;;;;;; ------ END OF DATAFILE-PLOT SECTION ------
   else
   ;;;;;; ------ START OF WRFOUT-PLOT SECTION ------

      expandedfilename = FILENAMES(ifile)+".nc"
      a = addfile( expandedfilename, "r" )
      ;old a = addfile( FILENAMES(ifile)+".nc", "r" )

      ;;; EXTRACT DOMAIN NUMBER, DATE, TIME FROM FILENAME
      filechars =  stringtochar( expandedfilename )
      string_length = dimsizes( filechars )-1
      do kk=0,(string_length-1-9)
      ;old do kk=0,150
        ; bombs here with "subscript out of range" if wrfout not found in filename
        if( filechars(kk:kk+5).eq."wrfout" ) then
         ;;; use character to get integer value
          kdomain = chartointeger( filechars(kk+9:kk+9) ) - 48
          datestring = chartostring( filechars(kk+11:kk+20) )
          timestring = chartostring( filechars(kk+22:kk+29) )
          YYYY = extract_string_field( datestring,1,"-" )
          MM = extract_string_field( datestring,2,"-" )
          DD = extract_string_field( datestring,3,"-" )
          hh = extract_string_field( timestring,1,":" )
          mm = extract_string_field( timestring,2,":" )
          ss = extract_string_field( timestring,3,":" )
          break
        end if 
      end do
      ;;; SET DOMAINID
      if ( string_pattern_grep(expandedfilename,"-WINDOW").eq.0 ) then
       domainid = "d"+kdomain
      else
       domainid = "w"+kdomain
      end if
              
      ;old print ( "FILE= "+expandedfilename+"  DOMAIN="+domainid+"  DATE="+datestring+"  TIME="+timestring  )
      ;old print ( "YYYY= "+YYYY+"  MM="+MM+"  DD="+DD+"  hh="+hh+"  mm="+mm+"  ss="+ss )

      ;;; big loop over all of the time periods to be processed

      ;frame(wks)  ; allow for window resize before beginning plots

      ;;; below printed file info in original version but now commented out
      ;;; sample "times": 2005-04-09_12:00

;TESTING - getting strange error in wrf_user_mass: fatal:NetCdf: An error occurred while attempting to read variable (Times) from file ...
;TESTING - see whether file might not be complete
;TESTING  ; if( ismissing(dims(0))  .or. dims(0).le.0 ) then
;TESTING  lsout = systemfunc( "ls -l "+FILENAMES(ifile) ) 
;TESTING  print("wrf_user_mass.ncl TESTING lsout= "+lsout )
;TESTING  times_in_file = a->Times
;TESTING  dims = dimsizes(times_in_file)
;TESTING  print("wrf_user_mass.ncl TESTING times_in_file= "+times_in_file )
;TESTING  print("wrf_user_mass.ncl TESTING dims= "+dims+" => "+dims(0) )
;TESTING  ; end if

      times = wrf_user_list_times(a)  ; get times in  the file
      ntimes = dimsizes(times)  ; number of times in the file

      ;jack: process times in output file
      ;jack: at present only valid for one time, what with the if(...isvar... tests
      ;jack:  to remove this limitation I need to add deletes at the bottom of the loop
      ;jack:     or in each section (but then have to keep reading data in each section)
      ;jack-1timeonly- do it = 0, ntimes-1,itinterval
      if( ntimes .gt.1 ) then
        print ( "*** ERROR EXIT - present treatment not valid for multiple-time files!" )
        exit
      end if
      it = 0

      time = it
      if (it.eq.0) then
              time_save = times(it)
      end if
      hours = it*3.

      ;;; IF INTERACTIVE RUN, USE FILE TIME AS ID INSTEAD OF ENV_NCL_ID
      if ( ismissing(ENV_NCL_ID) .or. ENV_NCL_ID .eq. "" ) then
        ENV_NCL_ID = times(it)
      end if

;;; TEST PRINT OF MODEL OUTPUT DIMENSIONS 
;;; print modeloutput_variable dimensions
;3dmodel: modelvar = a->HFX(time,:,:,:)
;2dmodel: modelvar = a->V10(time,:,:)
; dimmodelvar = dimsizes(modelvar)
; print ( "model dims= "+dimmodelvar )
; exit

;;; EXPECT TO ALMOST ALWAYS NEED FOLLOWING VARIABLES SO SIMPLY GET THEM
      z = wrf_user_getvar(a,"Z",time) ; grid point height (3D) in meters
      ;;; *NB* WARNING TOP-MOST LEVEL IN SOME ARRAYS HAS MISSING VALUES THERE ! eg qcloud
      ;;; 3D SIZES CHECKED SAME FOR Z,T,uz,wa,qcloud,
      paramdims = dimsizes(z)
      ksize = paramdims(0)   ; bottom_top
      jsize = paramdims(1)   ; south_north
      isize = paramdims(2)   ; west_east
      ;;; dims will contain length (size) of k,j,i
      dims3d = dimsizes(z)
      alat  = wrf_user_getvar(a,"XLAT",time)    ; in degrees
      alon  = wrf_user_getvar(a,"XLONG",time)    ; in degrees

      ;jack - TO PLOT TERRAIN HEIGHT
      ter = wrf_user_getvar(a,"HGT",time) ; for terrain height (2D) in meters
      ;jack - dont allow negative terrain  (to avoid plotting zero contour)
      NCL_JACK_FORTRAN :: trunc_2darray_min ( ter, isize,jsize, 1. )
      ; set terrain hgt in feet
      terft = 3.28084 * ter
      ;4test ;4test - detemine # of terrain values below zero
      ;4test npositive = 0
      ;4test nzero = 0
      ;4test nnegative = 0
      ;4test do ii = 0,(isize-1)
      ;4test do jj = 0,(jsize-1)
      ;4test   if( terft(jj,ii) .eq. 0.0 ) then
      ;4test     nzero = nzero +1
      ;4test   else
      ;4test     if( terft(jj,ii) .gt. 0.0 ) then
      ;4test       npositive = npositive +1
      ;4test     else
      ;4test       nnegative = nnegative +1
      ;4test     end if
      ;4test     terft(jj,ii) = -1.* terft(jj,ii)
      ;4test   end if
      ;4test end do 
      ;4test end do 
      ;4test print ( "TERRAIN Npositive,Nzero,Nnegative= "+npositive+" "+nzero+" "+nnegative )

      ;;; GET GRID INFO
      ;;; FIND GRID SPACING (m)
      dx = a@DX
      dy = a@DY
      gridspacing = sqrt(  0.5* ( dx^2 + dy^2 ) )
      if( gridspacing .lt. 10000. ) then
        gridspacingkm = sprintf ( "%.1f", (0.001*gridspacing) )
      else
        gridspacingkm = sprintf ( "%.0f", (0.001*gridspacing) )
      end if
      ;;; FIND PROJECTION INFO
      if( a@MAP_PROJ .ne. 1 ) then
        print ( "*** ERROR EXIT: projection must be lambert, instead is "+a@MAP_PROJ )
         exit
      else
        projection = "lambert"
      end if
      projlat1 = a@TRUELAT1
      projlat2 = a@TRUELAT2
      projlon = a@STAND_LON
      centerlat = a@CEN_LAT
      centerlon = a@CEN_LON
      ;;; FIND INITIATION MODEL INFO from (need tr of octal character to remove single quote!)
      ; PAULS initmodel = systemfunc( "grep 'INIT_ROOT' ../WRFSI/domains/"+REGION+"/static/wrfsi.nl | sed 's/^.*= *//;s/, *$//' | tr -d '\047'" ) 
             initmodel = systemfunc( "grep 'INIT_ROOT' /var/www/html/"+REGION+"/wrfsi.nl | sed 's/^.*= *//;s/, *$//' | tr -d '\047'" ) 
      ;4test:       print ( "INITMODEL= "+initmodel )
      ;;; GRID INFO FOR DATA FILE WRITE
      qgridinfo = "Model= RASP Region= "+REGION+" Grid= "+domainid+" Reskm= "+gridspacingkm+" Indexs="+" 1 "+sprinti("%i",isize)+" 1 "+sprinti("%i",jsize)+" Proj= lambert"+sprintf(" %.0f",dx)+sprintf(" %.0f",dy)+sprintf(" %.4f",projlat1)+sprintf(" %.4f",projlat2)+sprintf(" %.4f",projlon)+sprintf(" %.4f",centerlat)+sprintf(" %.4f",centerlon)
      ;old qgridinfo = "Model= RASP Region= "+REGION+" Grid= "+domainid+" Reskm= "+gridspacingkm+" Indexs="+" 1 "+sprinti("%i",isize)+" 1 "+sprinti("%i",jsize)+" PROJ= lambert"+sprintf(" %.0f",dx)+sprintf(" %.0f",dy)+sprintf(" %.4f",projlat1)+sprintf(" %.4f",projlat2)+sprintf(" %.4f",projlon)+sprintf(" %.4f",centerlat)+sprintf(" %.4f",centerlon)
      ;older qgridinfo = "Model= RASP Grid= "+REGION+" Res= "+gridspacingkm+" Subgrid= "+domainid+" Indexs="+" 1 "+sprinti("%i",isize)+" 1 "+sprinti("%i",jsize)+" PROJ= lambert"+sprintf(" %.0f",dx)+sprintf(" %.0f",dy)+sprintf(" %.4f",projlat1)+sprintf(" %.4f",projlat2)+sprintf(" %.4f",projlon)+sprintf(" %.4f",centerlat)+sprintf(" %.4f",centerlon)
      ;older qgridinfo = "Model= RASP Grid= "+REGION+" Res= "+gridspacingkm+" Subgrid= "+domainid+" Indexs="+" 1 "+sprinti("%i",isize)+" 1 "+sprinti("%i",jsize)
      ;last qgridinfo = "WRF_grid= RASP "+REGION+" d"+kdomain+" ="+" 1 "+sprinti("%i",isize)+" 1 "+sprinti("%i",jsize)

      ;;; PRINT FILE INFO
      print ( "RASP FILE= "+expandedfilename+"  DOMAIN="+domainid+" GRIDSPACINGkm="+gridspacingkm+" INITmodel= "+initmodel )

      ;;; CREATE EXPANSIVE 3rd TITLE LINE FROM GRID INFO
      titleline3 = "DrJack BLIPMAP from RASP "+gridspacingkm+"km "+initmodel+"-initiated WRF-ARW model"
      ;old titleline3 = "DrJack's RASP BLIPMAP from "+gridspacingkm+"km WRF-ARW model Forecast"
      ;older titleline3 = "DrJack RASP BLIPMAP from "+gridspacingkm+"km WRF-ARW model Forecast"
      print ( "SUBTITLE= "+titleline3 )
      print( "LOUT= "+LOUT )

;;;;;;;;;;;;;;;; START OF TEST SECTION ;;;;;;;;;;;;;;;;
; wa = wrf_user_getvar(a,"wa",0) ;  vertical velocity averaged to temp.level, in m/s
; print ( "WA DIMS= "+dimsizes(wa) )
; array = find_boxmax3d( wa, 0,50, 0,59, 0,47 )
; kmaxw = floattointeger( array(1) )
; jmaxw = floattointeger( array(2) )
; imaxw = floattointeger( array(3) )
; print ( "MAX= "+array(0)+" @kji="+array(1)+","+array(2)+","+array(3) )
; print ( "   height(m)="+z( kmaxw,jmaxw,imaxw ) )
; exit
;;;;;;;;;;;;;;;;; END OF TEST SECTION ;;;;;;;;;;;;;;;;;

   ;;;;;; ------ END OF WRFOUT-PLOT SECTION ------
   end if

   ;;; FOR SITE SUBSTITUTIONS  (jack: if alter filename also change BLIP/PLOT/filename)
   load "rasp.site_load.loop-init.ncl" 

;;; =======================================================================

;;; BELOW RESOURCES SET FOR ALL MAPS TO AVOID DUPLICATION (though may alter in a later section)

   ;        Plotting options for the terrain
   ;jack - put inside loop since sometimes add title via opts_ter
    opts_ter = True
    opts_ter@NoTitles = True
    ;original opts_ter@cnLineColor = "navy blue"
    opts_ter@cnLineColor = "black"
    opts_ter@cnInfoLabelOn = False
    opts_ter@cnHighLabelsOn = False
    opts_ter@cnLowLabelsOn = False
    opts_ter@cnLineLabelAngleF = -1.
    ;512x512:opts_ter@cnLineLabelFontHeightF = .015
    ;800x800
    opts_ter@cnLineLabelFontHeightF = .010
    opts_ter@cnLineLabelPerimOn = False
    ;original opts_ter@cnLineLabelPerimColor = "navy blue"
    opts_ter@cnLineLabelPerimColor = "black"
    ;original opts_ter@cnLineLabelFontColor = "navy blue"
    opts_ter@cnLineLabelFontColor = "black"
    opts_ter@cnHighLabelBackgroundColor = -1
    ;original opts_ter@cnHighLabelFontColor = "navy blue"
    opts_ter@cnHighLabelFontColor = "black"
    opts_ter@cnLowLabelBackgroundColor = -1
    ;original opts_ter@cnLowLabelFontColor = "navy blue"
    opts_ter@cnLowLabelFontColor = "black"
    ;old        opts_ter@LineThickness = 1.
   ;;errormsg="cnLineLabelDensityF is not a valid resource"   ;jack - add control for label spacing distance when cnLineLabelPlacementMode = Computed or Randomized
   ;;errormsg="cnLineLabelDensityF is not a valid resource"   opts_ter@cnLineLabelPlacementMode = "computed"
   ; ? no problem with this in topo.ncl ?     ;;errormsg="cnLineLabelDensityF is not a valid resource"   opts_ter@cnLineLabelDensityF = 0.5
   ;jack - eliminate box around terrain contour labels
   opts_ter@cnLineLabelBackgroundColor = -1
   ;;; set line label font
   opts_ter@cnConstFLabelFont = "helvetica-bold"
   opts_ter@cnLineLabelFont = "helvetica-bold"
   ;;; controls font of colorbar label
   opts_ter@lbTitleFont = "helvetica"
   opts_ter@lbLabelFont = "helvetica"
   opts_ter@lbTitleFontHeightF     = 0.015
   opts_ter@lbLabelFontHeightF     = 0.015
   opts_ter@lbTitleOffsetF     = -0.5  ; move colorbar and its title closer together
   opts_ter@lbTopMarginF     = -0.2  ; move colorbar and its title upward, closer to plot - but also expands height of colorbar !
   opts_ter@lbLabelOffsetF     = 0.05  ; move numbers close to colorbar

;;; TERRAIN ADDITION - plot contour lines of differing thickness
;;    (note that wrf_plot.ncl puts opts_ter@LineThickness into array cnLineThicknesses so dont use that variable for terrain as would overrides this)
;;; OVERRIDE LINE THICKNESS - make every 4th contour line thicker
   opts_ter@cnMonoLineThickness = False
   opts_ter@ContourLineThicknessInterval = 4 ;
   ;old        opts_ter@cnLineThicknesses = (/ 1., 1.,1.,1.,2., 1.,1.,1.,2., 1.,1.,1.,2., 1.,1.,1.,2., 1.,1.,1.,2., 1.,1.,1.,2., 1.,1.,1.,2. /)  ;; nb: wrf_plot.ncl also sets required cnMonoLineThickness=False
   ;;; do NOT label contour lines:
   opts_ter@cnLineLabelInterval = 0 ;
   ;4test: opts_ter@cnLineLabelInterval = 1 ;
   if( UNITS .ne. "metric" ) then
     opts_ter@ContourParameters = (/ 0.,0., 500. /)
   else
     opts_ter@ContourParameters = (/ 0.,0., 200. /)
   end if
   ;4test: opts_ter@ContourParameters = (/ 0.,0., 8000. /)

   ;;;  Map options
   ;jack  now set outside parameter loop so same for param & press plots
   opts_mp = True
   opts_mp@mpOutlineDrawOrder = "Draw" ; makes land/sea outline less obtrusive but state lines semi-hidden - so up thickness 1->2 if used
   opts_mp@mpGeophysicalLineThicknessF = 2.0
   ;without_mpOutlineDrawOrder=Draw: opts_mp@mpGeophysicalLineThicknessF = 1.0
   opts_mp@mpGeophysicalLineColor = "black"
   opts_mp@mpGeophysicalLineDashPattern = 6 ;  1=dash 2=thin_dot 5=thick_dot 6=dash
   opts_mp@mpUSStateLineThicknessF = 2.0 ; 
   ;without_mpOutlineDrawOrder=Draw: opts_mp@mpUSStateLineThicknessF = 1.0 
   opts_mp@mpUSStateLineColor = "white" 
   opts_mp@mpUSStateLineDashPattern = 1 ;  1=dash
   opts_mp@mpNationalLineThicknessF = 2.0
   opts_mp@mpNationalLineDashPattern = 1 ; "DashLine" ; 1=dash
   ;without_mpOutlineDrawOrder=Draw: opts_mp@mpNationalLineThicknessF = 1.0
   opts_mp@mpNationalLineColor = "white"
   opts_mp@mpNationalLineDashPattern = 1 ; 1=dash
   ;unused opts_mp@mpNationalLineDashSegLenF = 
   opts_mp@mpGridLineThicknessF = 0.5 ; think gives same result as 1.0
   opts_mp@mpGridLineColor = "white"
   opts_mp@mpLimbLineThicknessF = 1.0
   opts_mp@mpLimbLineColor = "white"
   opts_mp@mpPerimOn = True
   opts_mp@mpPerimLineThicknessF = 1.0
   opts_mp@mpPerimLineColor = "black"
   ;;; set lat/lon spacing (degrees)
   ;;; ruc/nam addition - ruc/nam-only/rasp-only if
   if( ldatatype.ne.0 ) then
   ;;;;;; ------ START OF DATAFILE-PLOT SECTION ------
     opts_mp@mpGridSpacingF = 2
   ;;;;;; ------ END OF DATAFILE-PLOT SECTION ------
   else
   ;;;;;; ------ START OF WRFOUT-PLOT SECTION ------
     opts_mp@mpGridSpacingF = 1
   ;;;;;; ------ END OF WRFOUT-PLOT SECTION ------
   end if
   ;jack - added since lat line labels currently stop at 50 for no apparent reason
   opts_mp@mpGridMaxLatF = 70
   ;dontuse opts_mp@mpGridMaskMode = 3  ; lat/lon lines disappear when this activated
   ;;; set geophysical coastline used
   opts_mp@mpDataBaseVersion = "NCARG4_1"  ; standard
   ;HighResCoastline: opts_mp@mpDataBaseVersion = "RANGS"     ; high-resolution (requires datafiles in $NCARG_ROOT/lib/ncarg/database/rangs)
   ;4test: opts_mp@mpDataResolution = "FinestResolution"
   ;latlongrid
   if( qproj7 .eq. "latlong" ) then
     opts_mp@mpProjection = "CylindricalEquidistant"
   end if

   ;;; ... and yet more map options galore!
   ;jack  now set outside parameter loop so same for param & press plots
   opts_map = True
   opts_map@LabelFont = "helvetica-bold"
   opts_map@LabelFontHeight = .01
   ;jack - add lat/lon labels along all sides
   opts_map@LatSide = (/ "Left", "Right" /)
   ;;; UGLY RUC/NAM COMPOSITE KLUDGE FORCES CONGRUENCE WITH NON-COMPOSITE BLIPMAP
   if( ldatatype .ne. 2 ) then
      opts_map@LonSide = (/ "Bottom", "Top" /)
   else
      opts_map@LonSide = (/ "Top" /)  ; do not add lat/lon labels to bottom
   end if

   ;;; for frame - set line options   
   opts_frame = True
   opts_frame@gsLineColor = "white"
   opts_frame@gsLineDashPattern = 1
   opts_frame@gsLineThicknessF = 2.0

   ;sounding_loc_plot
   ;;; for soundingloc - set color options   
   opts_soundingloc = True
   opts_soundingloc@txFont = "helvetica"
   opts_soundingloc@txFontColor = 0  ;white
   opts_soundingloc@txFontHeightF = 0.010
   opts_soundingloc@txJust = "CenterCenter"  ; should be default but make sure
   ;;; use following to plot sounding name instead of number
   ;4soundingname: opts_soundingloc@txFuncCode = ":"

   ;;; FOR SITE SUBSTITUTIONS  (jack: if alter filename also change BLIP/PLOT/filename)
   load "rasp.site_load.allmaps.ncl" 

;;; =======================================================================

 ;;; START OF LOOP OVER ALL PARAMS

 nparams = dimsizes(PARAMS)  ; number of single-variable plots
 do iparam=0,(nparams-1)
  lplotdone = 0
  qdatafile = ""
  iframe = iframe + 1
  plot_param = PARAMS(iparam)

  ;;; INITIALIZE
  ;;; set fixedcolor indicator
  kfixedcolor = 0

  ;;; set default lcompositetype = no compositing - change below for composite cases
  ;;;  lcompositetype = 1 for mask of bparam by cparam>0
  ;;;  lcompositetype = 2 for cparam stipple
  lcompositetype = 0

  ;;; USE FIRST PLOT CHARS FOR SPECIAL (NON-SINGLE-VARIABLE) PLOTS
  if ( isvar("name_chars") ) then 
    delete ( name_chars )
  end if
  name_chars = stringtochar( PARAMS(iparam) )
  name_max  = dimsizes(name_chars)-2
  ;4testprint: print( "NAME_MAX= "+name_max+" NAME_CHARS= "+name_chars )

  print( "=== PARAMETER LOOP: "+iframe+" "+PARAMS(iparam) )


;;; =======================================================================

;;;        BL CROSS-SECTION PLOT SECTION

   if( ( name_max .ge. 2 .and. name_chars(0:2) .eq. "xbl" ) .or. ( name_max .eq. 6 .and. name_chars(0:6) .eq. "boxwmax" ) ) then
      lplotdone = 1
      ldoblsection = 1
      ldowautosection = 0
      print ( "    DOING BL SECTION PLOT" )

     ;;; --------------------------------------------------------------------------------
     ;;; START OF EXTRACTION OF X,Y,ANGLE FROM PARAMETER NAME
     if( name_max .ge. 2 .and. name_chars(0:2) .eq. "xbl" ) then
       mapangledeg = default_mapangledeg
       xofblsection = default_xofblsection   ; note this is 0 based
       yofblsection = default_yofblsection   ; note this is 0 based
       if( name_max .gt. 2 ) then
         xfield = extract_string_field( PARAMS(iparam), 2, "_" )
         if ( xfield .ne. "" ) then
           xofblsection = stringtofloat(xfield)   ; note this is 0 based
         end if
         yfield = extract_string_field( PARAMS(iparam), 3, "_" )
         if ( yfield .ne. "" ) then
           yofblsection = stringtofloat(yfield)   ; note this is 0 based
         end if
         ;;; if either x or y field contains a decimalpt assume both are long,lat
         if ( string_pattern_grep( xfield,"." ) .or. string_pattern_grep( yfield,"." ) ) then
            locr = wrf_user_find_ij_lat_long( a, yofblsection, xofblsection )
            xofblsection = locr(1)   ; note this is 0 based
            yofblsection = locr(0)   ; note this is 0 based
           ;4testprint:
print( "*** xfield,yfield="+xfield+","+yfield+" X,Yofblsection="+xofblsection+","+yofblsection )
         end if
         anglefield = extract_string_field( PARAMS(iparam), 4, "_" )
         ;;;
         ;;; PAULS - MOD to take wind at pressure level to specify angle, ala "press850"
         ;;;
         ispot = floattointeger(xofblsection+1)  ; note this based on index 0 - Add 1
         jspot = floattointeger(yofblsection+1)  ; note this based on index 0
         if ( anglefield .ne. "" ) then
           if( anglefield .eq. "windk" ) then
             windk = stringtointeger( extract_string_field( PARAMS(iparam), 5, "_" ) )
             ;;; use wind at specified level for map angle
             if ( .not. isvar("ua") ) then 
               ua  = wrf_user_getvar(a,"ua",time)  ; in m/s
               ;;; convert to pilot units (english)
               if( UNITS .ne. "metric" ) then
                  ua = ua * 1.94386
               end if
             end if
             if ( .not. isvar("va") ) then 
               va  = wrf_user_getvar(a,"va",time)   ; in m/s
               ;;; convert to pilot units (english)
               if( UNITS .ne. "metric" ) then
                  va = va * 1.94386
               end if
             end if
             ;;; find map angle for wind vector
             mapangledeg = uv2mapangle( ua(windk,jspot,ispot),va(windk,jspot,ispot) )
             ;4testprint: print( "*** anglefield,windk="+anglefield+","+windk+" ua,va="+ua(windk,jspot,ispot)+","+va(windk,jspot,ispot)+" mapangledeg="+mapangledeg )
           end if

           tmpchr = stringtochar(anglefield)
           tmpstr = chartostring(tmpchr(0:4))
           if ( tmpstr .eq. "press" ) then
             char_str = stringtocharacter(anglefield)
             press = stringtofloat(charactertostring(char_str(5:)))
             if ( .not. isvar("ua") ) then 
               ua  = wrf_user_getvar(a,"umet",time)  ; in m/s
               ;;; convert to pilot units (english)
               if( UNITS .ne. "metric" ) then
                  ua = ua * 1.94386
               end if
             end if
             if ( .not. isvar("va") ) then 
               va  = wrf_user_getvar(a,"vmet",time)   ; in m/s
               ;;; convert to pilot units (english)
               if( UNITS .ne. "metric" ) then
                  va = va * 1.94386
               end if
             end if
             if ( .not. isvar("pmb") ) then 
               pmb = wrf_user_getvar(a,"p",time) ; pressure in mb
             end if
             ;; NOTE - We use METEOROLOGICAL wind direction here (== 180 opposite to vector representation)
             u_plane = -wrf_user_intrp3d(ua, pmb, ter, "h", press, 0.)
             v_plane = -wrf_user_intrp3d(va, pmb, ter, "h", press, 0.)
             mapangledeg = atan2(u_plane(jspot, ispot), v_plane(jspot, ispot)) * rad2deg
             if(ismissing(mapangledeg)) then
               mapangledeg = default_mapangledeg
             end if
             if(mapangledeg .lt. 0.0) then
               mapangledeg = mapangledeg + 360.0
             end if
             ; print("        mapangledeg = " + mapangledeg)
           else   
             mapangledeg = stringtofloat(anglefield)
           end if
         end if
       end if
       mapangledeginteger = floattointeger( mapangledeg )
       ;;; sanity check - skip locations outside the grid - note 0 IS an error condition
       ;;; print info
       if( xofblsection .gt. 0.0 .and. xofblsection .lt. isize .and. yofblsection .gt. 0.0 .and. yofblsection .lt. jsize ) then
         print ( "       SLICE AT X,Y="+xofblsection+","+yofblsection+" - angle="+mapangledeginteger )
       else
         print ( "       **SKIPPING** SLICE AT X,Y="+xofblsection+","+yofblsection+" - outside grid limits="+isize+","+jsize )
         continue
       end if
     end if
     ;;; END OF EXTRACTION OF X,Y,ANGLE FROM PARAMETER NAME
     ;;; --------------------------------------------------------------------------------
 
     ;;; --------------------------------------------------------------------------------
     ;;; START OF BOX W MAX ANALYSIS
     ;;; NB: any later press??? will include boxwmax info and position in plot (since ldowautosection=1 )
     if( name_max .eq. 6 .and. name_chars(0:6) .eq. "boxwmax" ) then
        print ( "    DOING BOXwMAX ANALYSIS" )

        ;;; ALLOW AUTO SECTION THROUGH LOCATION OF MAX W  (but presently off-set by 0.5*dx)
        ;;; SET AUTO SECTION FLAG SO LATER PRESSURE PLOTS WILL UTILIZE BOXWMAX INFO
        ldowautosection = 1
          if ( .not. isvar("w") ) then 
            w = wrf_user_getvar(a,"wa",time) ; vertical velocity, averaged to half levels in m/s
          end if
          ;;; SO AUTO-SECTION BASED ON MAX W IN 3D BOX
          ;;; set box - presently based on frame around horiz. border
          wdims = dimsizes(w)
          kwdim = wdims(0)
          jwdim = wdims(1)
          iwdim = wdims(2)
          ;;;  *NB* 0-based indexing used for boximin,...
          if( boxframe .gt. 0 ) then
            boximin = boxframe
            boximax = iwdim-boxframe-1
            boxjmin = boxframe 
            boxjmax = jwdim-boxframe-1
          end if
          if( boxframe .eq. -3 ) then
            boximin = iwdim/3
            boximax = iwdim-(iwdim/3)
            boxjmin = jwdim/3
            boxjmax = jwdim-(jwdim/3) 
          end if
          ;old kbox2_wautosection = kwdim -2
          ;;; find location of max w in box
          wmax = new( 1, float)
          imaxw = new( 1, integer)
          jmaxw = new( 1, integer)
          kmaxw = new( 1, integer)
          NCL_JACK_FORTRAN :: find_boxmax3d( w, boximin,boximax, \
                                  boxjmin,boxjmax, \
                                  boxkmin,boxkmax, \
                                  isize,jsize,ksize, wmax,imaxw,jmaxw,kmaxw )
          ;4test: 
 print ( "    DIMs= "+wdims(2)+" "+wdims(1)+" "+wdims(0) )
          ;4test: 
 print ( "    SIZEs= "+isize+" "+jsize+" "+ksize )
          ;4test: 
 print ( "    BOX= "+boximin+"-"+boximax+" "+boxjmin+"-"+boxjmax+" "+boxkmin+"-"+boxkmax )
          ;4test: 
 print ( "    I,Jmaxw= "+imaxw+" "+jmaxw )
          wmaxcmps = 100. * wmax 
          ;;; convert to integer for printing
          wmaxcmps = floattointeger( wmaxcmps )
          ;old alat  = wrf_user_getvar(a,"XLAT",time)
          ;old alon  = wrf_user_getvar(a,"XLONG",time)
          latmaxw = sprintf ( "%.2f", alat(jmaxw,imaxw) )
          lonmaxw = sprintf ( "%.2f", alon(jmaxw,imaxw) )
          zmaxw = floattointeger( z(kmaxw,jmaxw,imaxw) )
          ;old delete ( alat )
          ;old delete ( alon )
          ;;; use this location for vertical cross-section
          xofblsection = imaxw +0.0   ; note this is 0 based
          yofblsection = jmaxw +0.0   ; note this is 0 based
 ;;;jack - print z for info
 ;;; might want to set top of box based on z - but presently not done
 ;;; find z of each k at domain center
if ( .not. isvar("pmb") ) then 
  pmb = wrf_user_getvar(a,"p",time) ; pressure in mb
end if
ispot = floattointeger(xofblsection)  ; note this based on index 0
jspot = floattointeger(yofblsection)  ; note this based on index 0
;old  ispot = (iwdim-1)/2
;old  jspot = (jwdim-1)/2
;4test  ispot = 0
;4test  jspot = 0
 print ( "    Zlevels @ij(0based)="+ispot+","+jspot )
 do kk=0,(kwdim-1)
   kkreverse = kwdim-kk-1
   print ( "    @k="+kkreverse+"  Z= "+z(kkreverse,jspot,ispot)+"  P= "+pmb(kkreverse,jspot,ispot) )
 end do          
;old delete (pmb)
          ;;; set angle as that of wind at that location (0-180deg) (left-to-right except 0=180deg=>bottom-to-top)
          if ( .not. isvar("ua") ) then 
            ua  = wrf_user_getvar(a,"ua",time)  ; in m/s
            ;;; convert to pilot units (english)
            if( UNITS .ne. "metric" ) then
               ua = ua * 1.94386
            end if
          end if
          if ( .not. isvar("va") ) then 
            va  = wrf_user_getvar(a,"va",time)   ; in m/s
            ;;; convert to pilot units (english)
            if( UNITS .ne. "metric" ) then
               va = va * 1.94386
            end if
          end if
          ;;; find map angle for wind vector
          mapangledeg = uv2mapangle( ua(kmaxw,jmaxw,imaxw),va(kmaxw,jmaxw,imaxw) )
          mapangledeginteger = floattointeger( mapangledeg )
          ;old delete ( ua )
          ;old delete ( va )
          ;4test  mapangledeg = 90.
          ;4test  print ( "   U,V,ANGLE= "+ua(kmaxw,jmaxw,imaxw)+" "+va(kmaxw,jmaxw,imaxw)+" "+mapangledeg )
          ;;; print info
          print ( "       W MAX= "+wmaxcmps+"cm/s @ijk"+imaxw+","+jmaxw+","+kmaxw+" ="+latmaxw+","+lonmaxw+","+zmaxw+"m - angle="+mapangledeginteger )
          ;old print ( "W MAX= "+array(0)+" @ijk="+imaxw+","+jmaxw+","+kmaxw )
          ;old print ( "  at height(m)="+zmaxw+" (BoxTop@k="+boxkmax+"="+z(kmaxw,jmaxw,boxkmax)+"m)" )
          ;4test:  print ( "W MAX= "+w(kmaxw,jmaxw,imaxw)+" @ijk="+imaxw+","+jmaxw+","+kmaxw )
 
     end if
     ;;; END OF BOX W MAX ANALYSIS
     ;;; --------------------------------------------------------------------------------

        ;;; CROSS-SECTION PARAMS
        aspect_ratio = .75

;                   ^
;       angle  0 is |
;                   |
;                    ^ 
;       angle 45 is /
;                  /
;
;       angle= 90 is ---->
;
;                    \ 
;       angle 135 is  \
;                      v
  ;original=bad! ;;         Two different cross-sections, angle=90 is |, angle=0 is ------
        
;;;         ************************************************************

    ;;; ALLOW PLOTTING TO INDIVIDUAL OUTPUT FILES
    if ( LOUT .ge. 2 ) then
      ;RASP
      if( ismissing(ENV_NCL_OUTDIR) .or. ENV_NCL_OUTDIR .eq. "" ) then
        wks = wrf_open_ncgm(plot_param)   ; output to ncgm
        ;old wks = wrf_open_ncgm("rasp."+iframe)   ; output to ncgm
      else
        if( ldatatype.ne.0 .and. qfileid.ne."" ) then
          ;alt if( ENV_NCL_OUTDIR.eq."/tmp" .and. qfileid.ne."" ) then
          ;;; append tail for write to /tmp directory
          wks = wrf_open_ncgm(OUTDIR+"/"+plot_param+"."+qfileid)   ; output to ncgm
        else
          wks = wrf_open_ncgm(OUTDIR+"/"+plot_param)   ; output to ncgm
          ;old wks = wrf_open_ncgm(OUTDIR+"/rasp.wrf."+iframe)   ; output to ncgm
        end if
      end if
      ;;; INCREASE WORKSPACE ABOVE DEFAULT IF REQUESTED
      if( WORKSTATIONSPACE .gt. 0 ) then
        setvalues NhlGetWorkspaceObjectId()
           "wsMaximumSize": WORKSTATIONSPACE
        end setvalues
      end if
    end if

;;;         ************************************************************

      ;jack - these variables needed for bl cross-section
      if( lblsectionvar .eq. 1 ) then
        if ( .not. isvar("thetac") ) then 
           thetac = 26.85 + wrf_user_getvar(a,"T",time) ; perturb. potential temp. in degC
        end if
      else  
        if ( .not. isvar("rh") ) then 
            rh = wrf_user_getvar(a,"rh",time) ; perturb. potential temp. in degC
        end if
      end if
        if ( .not. isvar("w") ) then 
          w = wrf_user_getvar(a,"wa",time) ; vertical velocity, averaged to half levels in m/s
          ;;; convert w into cm/s
        end if
        if(UNITS .ne. "metric") then
          w4plot = 196.85039 * w
        else
          w4plot = 100 * w
        end if

;;;         ************************************************************
                ;        Build planes of data for w and thetac/rh
                plane = new(2,float)
                ;jack - plane sets point plane is to pass through
                ;jack plane = (/ dimsthetac(2)/2, dimsthetac(1)/2 /)
                plane = (/ xofblsection, yofblsection /)
                
                if( lblsectionvar .eq. 1 ) then
                   ;;; convert to pilot units (english)
                   if( UNITS .ne. "metric" ) then
                      var_plane = wrf_user_intrp3d(thetac,z,terft,"v",plane,mapangledeg)
                   else
                     var_plane = wrf_user_intrp3d(thetac,z,ter,"v",plane,mapangledeg)   
                   end if
                else
                   ;;; convert to pilot units (english)
                   if( UNITS .ne. "metric" ) then
                      var_plane = wrf_user_intrp3d(rh,z,terft,"v",plane,mapangledeg)
                   else
                      var_plane = wrf_user_intrp3d(rh,z,ter,"v",plane,mapangledeg)
                   end if
                end if
                ;;; convert to pilot units (english)
                if( UNITS .ne. "metric" ) then
                   w_plane = wrf_user_intrp3d(w4plot,z,terft,"v",plane,mapangledeg)
                else
                   w_plane = wrf_user_intrp3d(w4plot,z,ter,"v",plane,mapangledeg)
                end if

                ;;; PRINT MIN,MAX
                if( UNITS .eq. "metric") then
                  print( "    "+times(it)+" "+iframe+"= BL CROSS-SECTION: W [cm/s] MIN,MAX= "+min(w_plane)+"  "+max(w_plane) )
                else
                  print( "    "+times(it)+" "+iframe+"= BL CROSS-SECTION: W [ft/min] MIN,MAX= "+min(w_plane)+"  "+max(w_plane) )
                end if
                if( lblsectionvar .eq. 1 ) then
                  print( "                                           Theta [C] MIN,MAX= "+min(var_plane)+"  "+max(var_plane) )
                else
                  print( "                                           RH [%] MIN,MAX= "+min(var_plane)+"  "+max(var_plane) )
                end if

                ;        Plotting options for w
                opts_w = True
                if ( tmpstr .eq. "press" ) then
                    opts_w@MainTitle = "Section parallel to Wind at " + press + "mB: Vertical Velocity & Pot.Temp. ~I~(C)~P~"
                    ; opts_w@LevelLabel = "slice X,Y= "+xofblsection+","+yofblsection+"@"+mapangledeginteger+"~F34~0~F21~"
                    opts_w@LevelLabel = "slice through lat,lon = "+yfield+","+xfield+" @ "+mapangledeginteger+"~F34~0~F21~"
                else
                  if ( ldowautosection .eq. 0 .and. anglefield .ne. "windk" ) then
                    if( mapangledeg.ge.0.0 .and. mapangledeg.le.0.5 .or. mapangledeg.ge.179.5 .and. mapangledeg.le.180.5 ) then
                      if( lblsectionvar .eq. 1 ) then
                        opts_w@MainTitle = "Y-parallel Vertical Velocity & Pot.Temp. ~I~(C)~P~"
                      else
                        opts_w@MainTitle = "Y-parallel Vertical Velocity & Rel.Humid. ~I~(%)~P~"
                      end if
                    end if
                    if( mapangledeg.ge.89.5 .and. mapangledeg.le.90.5 ) then
                      if( lblsectionvar .eq. 1 ) then
                        opts_w@MainTitle = "X-parallel Section: Vertical Velocity & Pot.Temp ~I~(C)~P~"
                      else
                       opts_w@MainTitle = "X-parallel Section: Vertical Velocity & Rel.Humid. ~I~(%)~P~"
                      end if
                    end if
                    if( (mapangledeg.gt.0.5 .and. mapangledeg.lt.89.5 ) .or. ( mapangledeg.gt.90.5 .and. mapangledeg.lt.179.5 ) ) then
                       if( lblsectionvar .eq. 1 ) then
                         opts_w@MainTitle = "Angled Section: Vertical Velocity & Pot.Temp. ~I~(C)~P~"
                       else
                         opts_w@MainTitle = "Angled Section: Vertical Velocity & Rel.Humid. ~I~(%)~P~"
                       end if
                    end if
                    opts_w@LevelLabel = "slice X,Y= "+xofblsection+","+yofblsection+"@"+mapangledeginteger+"~F34~0~F21~"
                  else
                    if( lblsectionvar .eq. 1 ) then
                      opts_w@MainTitle = "Wind-Parallel Section at Max W: Vertical Velocity & Pot.Temp. ~I~(C)~P~"
                    else
                      opts_w@MainTitle = "Wind-Parallel Section at Max W: Vertical Velocity & RH ~I~(%)~P~"
                    end if
                    if ( ldowautosection .eq. 1 ) then
                      opts_w@LevelLabel = "boxWmax="+wmaxcmps+"@"+latmaxw+","+lonmaxw+","+zmaxw+"m"
                    else
                      opts_w@LevelLabel = "i,j,k,angle="+xofblsection+","+yofblsection+","+windk+","+mapangledeginteger
                    end if
                    ;prelatlon opts_w@LevelLabel = "angle@X,Y= "+mapangledeginteger+"@"+imaxw+","+jmaxw+" Z="+zmaxw+"m"
                  end if
                end if

                if( UNITS .eq. "metric") then
                  opts_w@UnitLabel = "Vertical Velocity [cm/s]"
                else
                  opts_w@UnitLabel = "Vertical Velocity [ft/min]"
                end if

                ;single_time_file:
                opts_w@TimeLabel = times(it)+"Z"
                  ;multiple_time_file: opts_w@TimeLabel = times(it) + " = " + time_save + " + " + hours + " h"
                ;;; IF NON-INTERACTIVERUN, USE ID AS TITLE
                if ( .not. ismissing(ENV_NCL_ID) .and. ENV_NCL_ID .ne. "" ) then
                  opts_w@TimeLabel = trim_string( ENV_NCL_ID )
                end if
                ;unused opts_w@ContourParameters = (/ -10., +10., 1. /)
                ;original opts_w@LevelLabel = "WRF MASS Forecast"
                ;original opts_w@cnFillColors = (/"white","white","white","white","chartreuse","green","green3","green4","forest green","PaleGreen4"/)
                opts_w@cnFillOn = True
                opts_w@cnMissingValPerimOn = True
                opts_w@cnMissingValFillColor = 0
                opts_w@cnMissingValFillPattern = 11
                opts_w@AspectRatio = aspect_ratio
                ;jack - now set top level based on data, not simply hard-wired!
                opts_w@tmYLMode          = "Automatic"     ; Set tick mark mode.
                ;jack - what a joke - simply assumes top of data/model always at 20km !
                ;original opts_w@tmYLMode          = "Explicit"     ; Set tick mark mode.
                ;original opts_w@tmYLValues        = (/ 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 /)
                ;original opts_w@tmYLLabels        = (/ 0,  2,  4,  6,  8, 10, 12, 14, 16, 18,  20 /)
                ; tiAxis is for alphabetic string
                ;old opts_w@tiXAxisString   = "Grid Point"  ; Label for the X axis
                ;;; convert to pilot units (english)
                if( UNITS .ne. "metric" ) then
                   opts_w@tiYAxisString   = "Height [Kft MSL]"      ; Label for the Y axis
                  ;jack - for x axis use length instead of grid point
                  opts_w@tiXAxisString   = "Distance [nm]"  ; Label for the X axis
                else
                   opts_w@tiYAxisString   = "Height [km MSL]"      ; Label for the Y axis
                  ;jack - for x axis use length instead of grid point
                  opts_w@tiXAxisString   = "Distance [km]"  ; Label for the X axis
                end if
                opts_w@tiXAxisFont     = "helvetica"        ; Font for X axis label
                opts_w@tiYAxisFont     = "helvetica"        ; Font for Y axis label
                opts_w@tiXAxisFontHeightF = 0.020
                opts_w@tiYAxisFontHeightF = 0.018
                ; tmLabel is for numbers
                opts_w@tmXBLabelFont     = "helvetica"        ; Font for X number label
                opts_w@tmXBLabelFontHeightF     = 0.020
                opts_w@tmYLLabelFont     = "helvetica"        ; Font for Y number label
                opts_w@tmYLLabelFontHeightF     = 0.020
                opts_w@cnInfoLabelOn = False
                ; move y label to right, away from left border             
                opts_w@tmYLLabelDeltaF        = -0.5
                ; move x label to top, away from bottom border             
                opts_w@tmXBLabelDeltaF        = -0.5

                ;;; FOR LABEL BAR (COLORBAR)
                opts_w@lbAutoManage = False
                opts_w@lbLabelFont     = "helvetica"   ; for numbers 
                opts_w@lbLabelFontHeightF     = 0.015
                opts_w@lbTitleFontHeightF     = 0.015
                opts_w@lbLabelOffsetF     = 0.05  ; move numbers close to colorbar
                opts_w@lbTitleFont     = "helvetica"   ; for string
                ;preAug2006(smaller_plotheight) opts_w@lbTitleFontHeightF     = 0.015
                ;preAug2006(smaller_plotheight) opts_w@lbTitleOffsetF     = -0.5  ; move colorbar and its title closer together
                ;preAug2006(smaller_plotheight) opts_w@lbTopMarginF     = -0.2  ; move colorbar and its title upward, closer to plot - but also expands height of colorbar !
                ;preAug2006(smaller_plotheight) opts_w@lbBottomMarginF  = 0.4

                ;;; LABELBAR OPTIONS TO ALLOW LARGER VERTICAL PLOT - but _with_ title
                ;;; specify label bar height,width to conform to my esthetics
                opts_w@pmLabelBarHeightF  = 0.08 ; 
                opts_w@pmLabelBarWidthF  = 0.80 ; 
                ;old opts_w@pmLabelBarWidthF  = 0.78 ; 
                opts_w@lbBottomMarginF     = 0.0 ; no apparnet effect
                opts_w@lbTopMarginF     = 0.0 ; no apparnet effect
                opts_w@pmLabelBarOrthogonalPosF  = 0.0 ; moves slightly upward
                ;unused  opts_w@lbJustification = "TopCenter" set in subroutine so not set here
                ;unused opts_w@pmLabelBarZone  = 1 ; when label bar perim extends beyond plot boundary this moves lb closer to plot 
                ;4test-display_lb_perim: opts_bparam@lbPerimOn = True ; opts_bparam@lbPerimColor = 1

                ;        Plotting options for thetac
                opts_thetac = True
                opts_thetac@NoTitles = True
                opts_thetac@ContourParameters = (/ 0.,0., 1. /)
                ;512x512:opts_thetac@cnLineLabelFontHeightF = .010
                ;800x800
                opts_thetac@cnLineLabelFontHeightF = .0022
                opts_thetac@cnInfoLabelOn = False
                ;jack - use of contour info label causes colorbar numbers to disappear
                opts_thetac@cnInfoLabelOn = False

                ;;;  Plot options for rh contour lines (no titles/labels)
                opts_rh = True
                opts_rh@NoTitles = True
                opts_rh@ContourParameters = (/ 10., 90., 10. /)
                opts_rh@cnLineLabelBackgroundColor = -1
                opts_rh@cnLineLabelFontHeightF = .005
                opts_rh@cnInfoLabelOn = False
                ;jack - use of contour info label causes colorbar numbers to disappear
                opts_rh@cnInfoLabelOn = False

                ;;;;;; this controls top height
                ;;; set default bl section top if not set above
                if( blsectionztop .le. 0 ) then
                   if( UNITS .ne. "metric" ) then
                      blsectionztop = 18.   ; in Kft
                   else
                      blsectionztop = 6.   ; in Km
                   end if
                end if
                ;jack - for vertical windowing, set min/max IN KM
                opts_w@trYMinF        = 0.
                opts_w@trYMaxF        = blsectionztop
                opts_rh@trYMinF        = 0.
                opts_rh@trYMaxF        = blsectionztop
                opts_thetac@trYMinF        = 0.
                opts_thetac@trYMaxF        = blsectionztop

                ;jack - for vertical windowing, use actual coordinate values of the data IN KM
                ;;; convert to pilot units (english)
                if( UNITS .ne. "metric" ) then
                   minZ = 0.0032808 * min(z) ; in kFT !
                   maxZ = 0.0032808 * max(z) ; in kFT !
                else
                   minZ = 0.001 * min(z) ; in KM !
                   maxZ = 0.001* max(z) ; in KM !
                   ;4test: print ( "Zmin,max[km]= "+minZ+" "+maxZ )
                end if
                w_plane@_MinY = minZ
                w_plane@_MaxY = maxZ
                var_plane@_MinY = minZ
                var_plane@_MaxY = maxZ

                ;jack - for x axis use length instead of grid point
                wplane_dims = dimsizes(w_plane)
                slicelength = (wplane_dims(1)-1) * 0.001 * dx
                ;;; for non-metric, convert slice length from km to nm (per x axis label)
                if( UNITS .ne. "metric" ) then
                  slicelength = 0.539956 * slicelength 
                end if
                w_plane@_MinX = 0.
                w_plane@_MaxX = slicelength
                var_plane@_MinX = 0.
                var_plane@_MaxX = slicelength

                ;;; FOR SITE SUBSTITUTIONS  (jack: if alter filename also change BLIP/PLOT/filename)
                load "rasp.site_load.bl-xsection.ncl" 

                ;        Get the contour info for the w and thetac/rh
                contour_w = wrf_new_fill_contour( wks,w_plane,opts_w,  mainvpx,mainvpy,mainvpwidth,mainvpheight )
                ;pre-viewport_params                contour_w = wrf_new_fill_contour(wks,w_plane,opts_w)
if( lblsectionvar .eq. 1 ) then
                contour_var = wrf_new_line_contour( wks, var_plane,opts_thetac,  mainvpx,mainvpy,mainvpwidth,mainvpheight )
               ;pre-viewport_params  contour_var = wrf_new_line_contour(wks, var_plane,opts_thetac)
else
               contour_var = wrf_new_line_contour( wks, var_plane,opts_rh,  mainvpx,mainvpy,mainvpwidth,mainvpheight )
               ;pre-viewport_params                contour_var = wrf_new_line_contour(wks, var_plane,opts_rh)
end if
                ;        Overlay the fields on the background
;jack - but no apparent difference
                wrf_mapoverlay(contour_w,contour_var)
                draw(contour_w)

                ;;; FINALLY, DRAW FRAME
                frame(wks)

                ;        Remove the dummy stuff
                delete(contour_var)
                delete(contour_w)
                delete(var_plane)
                delete(w_plane)
                ; must delete opts_w for multi-file plots with both press-level and bl-section plots
                delete( opts_w )
                delete( opts_thetac )
                delete( opts_rh )

      ;;; print current wall clock & elapsed time
      PrintWallClockElapseTime(wcStrt,"BL cross-section Plot end -")

      continue 
   end if        ;        end of bl cross-section plot section

;;; =======================================================================

;;;        CLOUD CROSS-SECTION PLOT SECTION

   if( name_max .eq. 5 .and. name_chars(0:5) .eq. "xcloud" ) then
     lplotdone = 1
     print ( "    DOING CLOUD SECTION PLOT" )

        ;;; CROSS-SECTION PARAMS
        aspect_ratio = .75
        
         mapangledeg = cloudsectionmapangledeg

;;;         ************************************************************

    ;;; ALLOW PLOTTING TO INDIVIDUAL OUTPUT FILES
    if ( LOUT .ge. 2 ) then
      ;RASP
      if( ismissing(ENV_NCL_OUTDIR) .or. ENV_NCL_OUTDIR .eq. "" ) then
        wks = wrf_open_ncgm(plot_param)   ; output to ncgm
        ;old wks = wrf_open_ncgm("rasp."+iframe)   ; output to ncgm
      else
        if( ldatatype.ne.0 .and. qfileid.ne."" ) then
          ;alt if( ENV_NCL_OUTDIR.eq."/tmp" .and. qfileid.ne."" ) then
          ;;; append tail for write to /tmp directory
          wks = wrf_open_ncgm(OUTDIR+"/"+plot_param+"."+qfileid)   ; output to ncgm
        else
          wks = wrf_open_ncgm(OUTDIR+"/"+plot_param)   ; output to ncgm
          ;old wks = wrf_open_ncgm(OUTDIR+"/rasp.wrf."+iframe)   ; output to ncgm
        end if
      end if
      ;;; INCREASE WORKSPACE ABOVE DEFAULT IF REQUESTED
      if( WORKSTATIONSPACE .gt. 0 ) then
        setvalues NhlGetWorkspaceObjectId()
           "wsMaximumSize": WORKSTATIONSPACE
        end setvalues
      end if
    end if

;jack - these variacloudes needed for cross-section
        if ( .not. isvar("rh") ) then 
          qcloud = wrf_user_getvar(a,"rh",time) ; relative humidity in percent
        end if
        if ( .not. isvar("qcloud") ) then 
          qcloud = wrf_user_getvar(a,"QCLOUD",time) ; cloud mixing ratio in kg/kg
        end if
        ;;; multiply mixing ratio by 1000
        qcloud4plot = 1000000*qcloud

        ;;; PRINT MIN,MAX
        print( times(it)+"  CLOUD CROSS-SECTION: CLOUD MIXING RATIO (g/Kgx1000) MIN,MAX= "+min(qcloud4plot)+"  "+max(qcloud4plot) )
        print( "                                          RELATIVE HUMIDTY (%) MIN,MAX= "+min(rh)+"  "+max(rh) )

;;;         ************************************************************

                ;        Build planes of data for temp and cloud
        
                dimscloud = dimsizes(qcloud4plot)
                plane = new(2,float)
                ;jack - plane sets point plane is to pass through
                ;jack plane = (/ dimscloud(2)/2, dimscloud(1)/2 /)
                plane = (/ xofcloudsection, yofcloudsection /)
                
                cloud_plane = wrf_user_intrp3d(qcloud4plot,z,ter,"v",plane,mapangledeg)
                rh_plane = wrf_user_intrp3d(rh,z,ter,"v",plane,mapangledeg)
                
                ;        Plotting options for cloud

                opts_cloud = True
                if(cloudsectionmapangledeg .eq. 1) then
                        opts_cloud@MainTitle = "X-parallel Cloud Mixing Ratio & Relative Humidity ~I~(%)~P~"
                else
                        opts_cloud@MainTitle = "Y-parallel Cloud Mixing Ratio & Relative Humidity ~I~(%)~P~"
                end if
                opts_cloud@UnitLabel = "CLOUD MIXING RATIO [g/Kg *1000]"
                ;single_time_file:
                opts_cloud@TimeLabel = times(it)+"Z"
                  ;multiple_time_file: opts_cloud@TimeLabel = times(it) + " = " + time_save + " + " + hours + " h"
                ;;; IF NON-INTERACTIVE RUN, USE ID AS TITLE
                if ( .not. ismissing(ENV_NCL_ID) .or. ENV_NCL_ID .eq. ""  ) then
                  opts_cloud@TimeLabel = trim_string( ENV_NCL_ID )
                end if
                opts_cloud@ContourParameters = (/ 0.0, 1000., 50. /)
                opts_cloud@LevelLabel = "slice @X,Y= "+xofcloudsection+","+yofcloudsection
                opts_cloud@cnFillOn = True
                opts_cloud@cnMissingValPerimOn = True
                opts_cloud@cnMissingValFillColor = 0
                opts_cloud@cnMissingValFillPattern = 11
                opts_cloud@AspectRatio = aspect_ratio
                
                ; jack - mimic some bparam settings
                ; this causes color bar labels to appear!      
                opts_cloud@lbBottomMarginF = 0.4
                opts_cloud@cnInfoLabelOn = False
                opts_cloud@lbAutoManage = False

                ;        Plotting options for relative humidity
                opts_rh = True
                opts_rh@NoTitles = True
                opts_rh@ContourParameters = (/ 10., 90., 10. /)
                ;512x512:opts_rh@cnLineLabelFontHeightF = .010
                ;800x800
                opts_rh@cnLineLabelFontHeightF = .005
                opts_rh@cnInfoLabelOn = False

                ;;; FOR SITE SUBSTITUTIONS  (jack: if alter filename also change BLIP/PLOT/filename)
                load "rasp.site_load.cloud-xsection.ncl"  
                
                ;        Get the contour info for the cloud and temp
                
                contour_cloud = wrf_new_fill_contour( wks,cloud_plane,opts_cloud, mainvpx,mainvpy,mainvpwidth,mainvpheight )
                ;pre-viewport_params                contour_cloud = wrf_new_fill_contour(wks,cloud_plane,opts_cloud)
                contour_rh = wrf_new_line_contour( wks, rh_plane,opts_rh, mainvpx,mainvpy,mainvpwidth,mainvpheight )
                ;pre-viewport_params                contour_rh = wrf_new_line_contour(wks, rh_plane,opts_rh)

                ;        Overlay the fields on the background
                
;jack - but no apparent difference
                wrf_mapoverlay(contour_cloud,contour_rh)
;original                overlay(contour_cloud,contour_rh)
                draw(contour_cloud)

                ;;; FINALLY, DRAW FRAME
                frame(wks)

                ;        Remove the dummy stuff
                delete(contour_rh)
                delete(contour_cloud)
                delete(rh_plane)
                delete(cloud_plane)

      ;;; print current wall clock & elapsed time
      PrintWallClockElapseTime(wcStrt,"Cloud cross-section Plot end -")
                
      continue 
   end if        ;        end of cloud cross-section plot section

;;; =======================================================================

;;;        SKEW-T SOUNDING PLOT SECTION

   if( name_max .gt. 7 .and. name_chars(0:7) .eq. "sounding" ) then
     lplotdone = 1
     ;;; determine sounding number
     char_str = chartostring( name_chars(8:name_max) ) 
     if( name_chars(8:8) .ne. "0" ) then
       ip = stringtointeger( char_str )
     else
       ;;; treat special case with input lat,lon = sounding0_id_lat_lon
       ip = 0
       param_array = split_string_into_array( plot_param,"_" ) 
       sounding_ids(0) = param_array(1)
       sounding_lats(0) = stringtofloat(param_array(2))
       sounding_lons(0) = stringtofloat(param_array(3))
       print( "    DOING SPECIAL SOUNDING PLOT at lat,lon="+sounding_lats(0)+","+sounding_lons(0)+" = "+sounding_ids(0) )
     end if

     ;;; check that valid data available
     if( ismissing(sounding_ids(ip)) ) then
       print( "*** SKIPPING SOUNDING *** missing region data for ip= "+ip )
       ;unused ;;; draw blank frame - will generate a black image
       ;unused frame(wks)
       continue          
     end if

     ;        We already have temp, get the rest of the cast assembled
     ;jack - these variables needed for sounding
        if ( .not. isvar("pmb") ) then 
          pmb   = wrf_user_getvar(a, "p",time) ; press is vertical coordinate in mb
        end if
        ;old z   = wrf_user_getvar(a, "Z",time) ; grid point height
        if ( .not. isvar("tc") ) then 
          tc = wrf_user_getvar(a,"tc",time)    ; temperature (C)
          ;old ;;;jack - convert temp to virtual temp and make dewpt depression correct
          ;old virttempadj = (tc +273.16)*0.61*qvapor
          ;old tc = tc + virttempadj
        end if
        if ( .not. isvar("qvapor") ) then 
          qvapor  = wrf_user_getvar(a,"QVAPOR",time)   ; water vapor mixing ratio in kg/kg
        end if
        if ( .not. isvar("td") ) then 
          td =  wrf_user_getvar(a,"td",time)       ; dew point temperature (C)
          ;old ;;;jack - convert temp to virtual temp and make dewpt depression correct
          ;old virttempadj = (tc +273.16)*0.61*qvapor
          ;old td = td + virttempadj
        end if
        if ( .not. isvar("uraw") ) then 
          uv = wrf_user_getvar(a,"umeta",time )   ; u,v NOT rotated to grid   in m/s
          ;jack - note u,v set to knots here
          ;;; convert to pilot units (english)
          if( UNITS .ne. "metric" ) then
            uraw =  uv(0,:,:,:)*1.94386
            vraw =  uv(1,:,:,:)*1.94386
          else
            uraw =  uv(0,:,:,:)
            vraw =  uv(1,:,:,:)
          end if
        end if
        ;jack - add plot of QCLOUD
        if ( .not. isvar("qcloud") ) then 
          qcloud = wrf_user_getvar(a,"QCLOUD",time) ; for cloud water mixing ratio in kg/kg
        end if
        ;jack - add plot of CLDFRA - allow for missing parameter in older files
        if ( .not. isvar("cldfra") ) then 
            ndims = dimsizes(filevardimsizes(a,"CLDFRA"))
            if( ndims .gt. 1 ) then
               cldfra = a->CLDFRA(time,:,:,:)
               ;old cldfra = wrf_user_getvar(a,"CLDFRA",time) ; for cloud fraction (0-1)
           else
               print( "** WARNING: NO CLDFRA DATA FOUND IN FILE so set to -1 => will not be plotted" )
               cldfra = new( (/ksize,jsize,isize/), float)
               cldfra = -1.0               
           end if
        end if
                
;;;     PLOT SOUNDINGS

      ;;; ALLOW PLOTTING TO INDIVIDUAL OUTPUT FILES
      if ( LOUT .ge. 2 ) then
        ;RASP
        if( ismissing(ENV_NCL_OUTDIR) .or. ENV_NCL_OUTDIR .eq. "" ) then
          wks = wrf_open_ncgm(plot_param)   ; output to ncgm
          ;old wks = wrf_open_ncgm("rasp."+iframe)   ; output to ncgm
        else
          if( ldatatype.ne.0 .and. qfileid.ne."" ) then
          ;alt if( ENV_NCL_OUTDIR.eq."/tmp" .and. qfileid.ne."" ) then
            ;;; append tail for write to /tmp directory
            wks = wrf_open_ncgm(OUTDIR+"/"+plot_param+"."+qfileid)   ; output to ncgm
          else
            wks = wrf_open_ncgm(OUTDIR+"/"+plot_param)   ; output to ncgm
            ;old wks = wrf_open_ncgm(OUTDIR+"/rasp.wrf."+iframe)   ; output to ncgm
          end if
        end if
        ;;; INCREASE WORKSPACE ABOVE DEFAULT IF REQUESTED
        if( WORKSTATIONSPACE .gt. 0 ) then
          setvalues NhlGetWorkspaceObjectId()
             "wsMaximumSize": WORKSTATIONSPACE
          end setvalues
        end if
      end if
                
                ;        Define a few skew-T plotting options

                skewtOpts               = True
                skewtOpts@units         = UNITS   
                ;;; convert to pilot units (english)
                if( UNITS .ne. "metric" ) then
                   skewtOpts@DrawHeightScaleFt = True
                else
                   skewtOpts@DrawHeightScaleFt = False
                end if
                dataOpts                = True
                dataOpts@Parcel         = 0
                dataOpts@WspdWdir       = False   ; wind speed and dir [else: u,v]
                dataOpts@PlotWindH      = False  ; plot wind barbs at h lvls [pibal; special]
                dataOpts@HspdHdir       = True   ; wind speed and dir [else: u,v]
                dataOpts@units       = UNITS   
              
                ;jack - use array to set sounding id,lat,long - function returns (lat=J,lon=I) pair as nearest integer value
                locr = wrf_user_find_ij_lat_long(a, sounding_lats(ip), sounding_lons(ip) )   ; note this is 0 based
                ;old locr = wrf_user_find_ij_lat_long(a, sounding_lats(kdomain,ip), sounding_lons(kdomain,ip) )
                loc = floattointeger(locr)   ; note this is 0 based
                fortranI = loc(1)+1
                fortranJ = loc(0)+1
                ;4test print( "*** SOUNDING lon/lat "+sounding_lons(ip)+"/"+sounding_lats(ip)+" => loc="+loc(1)+" "+loc(0)+" for dims= "+(dims3d(2)-1)+" "+(dims3d(1)-1) )
                ;;; treat case of lat/lon outside domain - skip plot
                ; use eq since seems to return border value in error cases (and border not too valid anyway)
                if( fortranI.lt. 1 .or. fortranI.gt.dims3d(2) .or. fortranJ.lt.1 .or. fortranJ.gt.dims3d(1) ) then
                ;old                if( loc(1).lt. 0 .or. loc(1).gt.(dims3d(2)-1) .or. loc(0).lt.0 .or. loc(0).gt.(dims3d(1)-1) ) then
                ;old                   print( "*** SKIPPING SOUNDING *** "+sounding_ids(ip)+"lon/lat "+sounding_lons(ip)+"/"+sounding_lats(ip)+" outside domain => loc="+loc(1)+" "+loc(0)+" for dims= "+(dims3d(2)-1)+" "+(dims3d(1)-1) )
                   print( "* SKIPPING SOUNDING * "+sounding_ids(ip)+"lon,lat "+sounding_lons(ip)+","+sounding_lats(ip)+" outside domain => mathI,J="+fortranI+","+fortranJ+" for dims= "+dims3d(2)+","+dims3d(1) )
                   ;unused ;;; draw blank frame - will generate a black image
                   ;unused frame(wks)
                   continue          
                   ;old - generate image rather than skipping, put error message in title
                   ;old loc_str = "***INVALID*** lat/lon outside domain ***INVALID*** ~I~"+sounding_ids(kdomain,ip)+" "+sounding_lats(kdomain,ip)+","+sounding_lons(kdomain,ip)+" ("+fortranI+","+fortranJ+")"+ENV_NCL_ID+"~P~"
                else
                      ;bad(after_eliminate_secs)!? loc_str = times(it)+"Z  "+sounding_ids(kdomain,ip)+" "+sounding_lats(kdomain,ip)+","+sounding_lons(kdomain,ip)+" ("+fortranI+","+fortranJ+")"
                      ;ok-butZnotprinted!
                      loc_str = sounding_ids(ip)+" "+sounding_lats(ip)+"~F34~0~F21~,"+sounding_lons(ip)+"~F34~0~F21~ ~I~("+fortranI+","+fortranJ+")~P~"+"   "+times(it)+"Z"
                      ;old loc_str = sounding_ids(kdomain,ip)+" "+sounding_lats(kdomain,ip)+"~F34~0~F21~,"+sounding_lons(kdomain,ip)+"~F34~0~F21~ ~I~("+fortranI+","+fortranJ+")~P~"+"   "+times(it)+"Z"
                      ;old_funccode loc_str = sounding_ids(kdomain,ip)+" "+sounding_lats(kdomain,ip)+":F34:0:F21:,"+sounding_lons(kdomain,ip)+":F34:0:F21: :I:("+fortranI+","+fortranJ+"):P:"+"   "+times(it)+"Z"
                      ;;; IF NON-INTERACTIVE RUN, USE ID AS TITLE
                      if ( .not. ismissing(ENV_NCL_ID) ) then
                        ENV_NCL_ID = trim_string( ENV_NCL_ID )
                        loc_str = "#"+ip+": "+sounding_ids(ip)+" ~I~"+sounding_lats(ip)+"~F34~0~F21~,"+sounding_lons(ip)+"~F34~0~F21~ ("+fortranI+","+fortranJ+")~P~"+"   "+ENV_NCL_ID
                        ;old loc_str = sounding_ids(ip)+" "+sounding_lats(ip)+"~F34~0~F21~,"+sounding_lons(ip)+"~F34~0~F21~ ~I~("+fortranI+","+fortranJ+")~P~"+"   "+ENV_NCL_ID
                        ;older loc_str = sounding_ids(kdomain,ip)+" "+sounding_lats(kdomain,ip)+"~F34~0~F21~,"+sounding_lons(kdomain,ip)+"~F34~0~F21~ ~I~("+fortranI+","+fortranJ+")~P~"+"   "+ENV_NCL_ID
                        ;old_funccode loc_str = sounding_ids(kdomain,ip)+" "+sounding_lats(kdomain,ip)+":F34:0:F21:,"+sounding_lons(kdomain,ip)+":F34:0:F21: :I:("+fortranI+","+fortranJ+"):P:"+"   "+ENV_NCL_ID
                      end if        
                end if
                print ( "    SOUNDING: "+loc_str )
                ;old print ( " SOUNDING: "+sounding_ids(ip)+" @"+sounding_lats(ip)+","+sounding_lons(ip)+" mathI,J=("+fortranI+","+fortranJ+")" ) 
                ;4test: print ( "LOCSTRING="+loc_str+"=" )
                ;        Get the skew-T background
                ;;; for some reason bad printed skewt title after removal of seconds from "times"
                ;;;   (containg a star and lacking the trailing Z)
                ;;; even though print of loc_string here shows no problems
                skewtOpts@tiMainString    = loc_str
               ;jack - to change main title font height had to alter skewt_func.ncl
                skewtOpts@tiMainFontHeightF    = 0.001
                skewt_bkgd    = skewT_BackGround (wks, skewtOpts)

                ;;; FOR SITE SUBSTITUTIONS  (jack: if alter filename also change BLIP/PLOT/filename)
                load "rasp.site_load.skewt.ncl"  

                ;        Draw the skew-T plot
                draw (skewt_bkgd )
;;; DANGER - NOTE REVERSAL OF SIGN FOR U,V HERE, WHICH WORKS FOR LOCAL skewt_func.ncl VERSION
;;;          BUT _NOT_ FOR LATEST SHEA VERSION - SO NEED TO USE _LOCAL_ skewt_func.ncl FILE
;jack - add plot of QCLOUD, CLDFRA
                  ;jack - ADD 2m Tc,Td TO SOUNDING PLOT
                  if ( .not. isvar("tc2") ) then 
                    tc2 =  wrf_user_getvar(a,"T2",time) - 273.16      ; 2m temp in C
                  end if
                  if ( .not. isvar("td2") ) then 
                    td2 =  wrf_user_getvar(a,"td2",time)       ; 2m dew point temp in C
                  end if
                  if ( .not. isvar("psfcmb") ) then 
                    psfcmb =  0.01 * wrf_user_getvar(a,"PSFC",time)       ; surface pressure in mb
                  end if
                  ; ;jack - ADD 10m windspeed TO SOUNDING PLOT
                  ; if ( .not. isvar("u10m") ) then 
                  ;   u10m =  wrf_user_getvar(a,"U10",time)   
                  ;   v10m =  wrf_user_getvar(a,"V10",time)
                  ;   ws10m = sqrt( u10m(loc(0),loc(1))^2 + v10m(loc(0),loc(1))^2 )       ; 10m windspeed
                  ;   if( UNITS .ne. "metric" ) then
                  ;    ws10m =  ws10m*1.94386
                  ;   end if
                  ;   ;4testprint print ( "  ws10m= "+ws10m )
                  ; end if

                print ( "  "+sounding_ids(ip)+" loc="+loc(0)+","+loc(1)+" P2m,0= "+psfcmb(loc(0),loc(1))+","+pmb(0,loc(0),loc(1))+" Zsfc,0= "+ter(loc(0),loc(1))+","+z(0,loc(0),loc(1)) )
                ;sanity check
                if( psfcmb(loc(0),loc(1)) .lt. pmb(0,loc(0),loc(1)) ) then
                print ( "**WARNING - Psfc < P0" )
                end if
                ;4testprint - output sounding data
                ; do kk=0,(ksize-1)
                ;   print ( "  z,p,T,Td,uraw,vraw= "+kk+" "+z(kk,loc(0),loc(1))+" "+pmb(kk,loc(0),loc(1))+" "+tc(kk,loc(0),loc(1))+" "+td(kk,loc(0),loc(1))+" "+uraw(kk,loc(0),loc(1))+" "+vraw(kk,loc(0),loc(1)) )
                ; end do 

                ;;; PLOT SKEWT
                ;;; note that cannot insert a ";" comment in following string of line continuations
                skewT_data = skewT_PlotData(wks, skewt_bkgd, pmb(:,loc(0), loc(1)), \
                tc(:,loc(0), loc(1)), \
                td(:,loc(0), loc(1)), \
                z(:,loc(0), loc(1)), \
                -uraw(:,loc(0), loc(1)), \
                -vraw(:,loc(0), loc(1)), \
                qcloud(:,loc(0), loc(1)), \
                cldfra(:,loc(0), loc(1)), \
                psfcmb(loc(0),loc(1)), tc2(loc(0),loc(1)), td2(loc(0),loc(1)), \
                dataOpts              )
                ;need to insert above should surface windspeed be plotted as dot ws10m, \
                ;4testprint-wind@sfc:  print ( sounding_ids(ip)+" "+times(it)+" Sfc.Z,U,V= "+z(0,loc(0), loc(1))+" "+uraw(0,loc(0), loc(1))+" "+vraw(0,loc(0), loc(1)) )
                ;4testprint-P,Tc,Td@iz=1: print ( sounding_ids(ip)+" "+times(it)+" Sfc.Z,P,Tc,Td= "+z(0,loc(0),loc(1))+" "+pmb(0,loc(0),loc(1))+" "+tc(0,loc(0),loc(1))+" "+td(0,loc(0),loc(1)) )
                ;4testprint-virttempadj:  print ( " Sfc.Tadj: "+tc(0,loc(0),loc(1))+","+qvapor(0,loc(0),loc(1))+" => "+virttempadj(0,loc(0),loc(1)) )
                ;4testprint-Zprofile:  print ( " Z Profile= "+z(:,loc(0), loc(1)) )
                ;4testprint-profile:  print ( " Profile for "+sounding_ids(ip)+" "+times(it) )
                ;4testprint-profile:  do kk=0,(ksize-1)
                ;4testprint-profile:   print ( sprinti("%2i",kk)+" "+sprintf("%8.1f",z(kk,loc(0),loc(1)))+" "+sprintf("%8.1f",pmb(kk,loc(0),loc(1)))+" "+sprintf("%6.1f",tc(kk,loc(0),loc(1)))+" "+sprintf("%6.1f",td(kk,loc(0),loc(1)))+" "+sprintf("%6.1f",uraw(kk,loc(0),loc(1)))+" "+sprintf("%6.1f",vraw(kk,loc(0),loc(1)))+" "+sprintf("%10.6f",qcloud(kk,loc(0),loc(1))) )
                ;4testprint-profile:  end do                
                ;;; FINALLY, DRAW FRAME
                frame(wks)

                ;        Delete the temporary arrays
                delete(skewtOpts)
                delete(dataOpts)
                delete(skewT_data)
                delete(skewt_bkgd)

      ;;; print current wall clock & elapsed time
      PrintWallClockElapseTime(wcStrt,"Skew-T Plot end -")
       
      continue 
   end if        ;        end of skewt sounding skewt plot section
        
;;; =======================================================================

;;;      CREATE BACKGROUND TERRAIN PLOT USED BY FOLLOWING VARIABLES

   ;onceonly_background: create back_ter_map, then copy to map for plotting (trying to "save" terplot)
   if( .not. isvar("back_ter_map") ) then

        ;;; set temporary workstation for background "back_ter_map" plot (but not actually used by a draw command)
        if( ismissing(ENV_NCL_OUTDIR) .or. ENV_NCL_OUTDIR .eq. "" .or. ENV_NCL_OUTDIR .eq. "/tmp" ) then
          srand( stringtoint( systemfunc( "date +%s" ) ) )
          terwks = wrf_open_ncgm("/tmp/bkgwks."+rand())   ; output to ncgm
          ;old terwks = wrf_open_ncgm("tmp.ncl.background_wks")   ; output to ncgm
        else
          ;;; *WARNING* FULL NCGM FILENAME HAS 80 CHARACTER LIMIT !!! - name will have .ncgm appended 
          terwks = wrf_open_ncgm(OUTDIR+"/tmp.bkgwks")   ; output to ncgm
        end if

        ;;; PLOT CONTOUR LINES
        if( isatt(opts_ter,"cnLinesOn") .and. .not. opts_ter@cnLinesOn ) then
           contour_ter = wrf_new_line_contour(terwks,ter(:,:),opts_ter, mainvpx,mainvpy,mainvpwidth,mainvpheight)      ; in meters
        else
          ;;; convert to pilot units (english)
          if( UNITS .ne. "metric" ) then
             contour_ter = wrf_new_line_contour(terwks,terft(:,:),opts_ter, mainvpx,mainvpy,mainvpwidth,mainvpheight)    ; in feet
             ;;; UGLY RUC/NAM COMPOSITE KLUDGE FORCES CONGRUENCE WITH NON-COMPOSITE BLIPMAP
             if( ldatatype .ne. 2 ) then
               ;write contour spacing info on plot
               anno_ter_contour(terwks,contour_ter,"ft")
             end if
          else  
             contour_ter = wrf_new_line_contour(terwks,ter(:,:),opts_ter, mainvpx,mainvpy,mainvpwidth,mainvpheight)      ; in meters
             ;write contour spacing info on plot
             anno_ter_contour(terwks,contour_ter,"m")
          end if
        end if
    ;onceonly_background:  if try to plot gray background here, overplot _everything_ if use  graybackgroundthingey = gsn_add_polygon( terwks, contour_ter, cirx,ciry, gsres )  ; Draw a filled polygon.

    ;onceonly_background:  add a frame to indicate boundary area (must be done here to get overlaid on top)
        if( ldoframe .gt. 0 ) then
          primitivethingey = add_frame( terwks, contour_ter, opts_frame, ldoframe, (/isize,jsize/) )
        end if
        if( ldoframe .lt. 0 ) then
          ;;; make kframe dependent on file so can display subgrids - xl,xr, yb,yt
          primitivethingey = add_frame( terwks, contour_ter, opts_frame, ldoframe, kframe(ifile,:)  )
        end if

        ;onceonly_background: - test setup for plotting sounding location identifier
        ;4test: delete ( sounding_ids )
        ;4test: delete ( sounding_lats )
        ;4test: delete ( sounding_lons )
        ;4test: sounding_ids  = new( (/ 3 /), string)
        ;4test: sounding_lats = new( (/ 3 /), float)
        ;4test: sounding_lons = new( (/ 3 /), float)
        ;4test: nsounding = 2
        ;4test: sounding_ids(1) = "TEST-PANOCHE" 
        ;4test: sounding_lats(1) = 36.6105   ; actual panoche lat
        ;4test: sounding_lons(1) = -120.8853  ; actual panoche lon
        ;4test: sounding_ids(2) = "TEST-HERNANDEZ" 
        ;4test: sounding_lats(2) = 36.360   ; actual hernandez lat
        ;4test: sounding_lons(2) = -120.786 ; actual hernandez lon
        ;4test: print( " NSOUNDING="+nsounding )
        ;onceonly_background:  plot sounding location identifiers
        if( isvar("nsounding") .and. nsounding .gt. 0 ) then
          ;;; must use array argument "thingeys" to keep graphic primitives created by gsn_add_test from being destroyed !!!
          sounding_thingeys = new( (/ nsounding+1 /), graphic)
          add_sounding_locations( terwks, contour_ter, a, ter(:,:), sounding_ids(:),sounding_lats(:),sounding_lons(:), opts_soundingloc, sounding_thingeys(:) )
        end if

        ; setup map plot
        ;; ruc/nam addition - ruc/nam-only/rasp-only if 
        if( ldatatype.ne.0 ) then
        ;;;;;; ------ START OF DATAFILE-PLOT SECTION ------
          lat_filename = string_target_replace( ENV_NCL_INFOFILENAME, "dummy", "latitude" )
          lon_filename = string_target_replace( ENV_NCL_INFOFILENAME, "dummy", "longitude" )
          ;old lat_filename = ENV_NCL_INFOFILENAME+"/latitude."+ENV_NCL_REGIONNAME+".data"
          ;old lon_filename = ENV_NCL_INFOFILENAME+"/longitude."+ENV_NCL_REGIONNAME+".data"
          ;;;    if not found get error message "read/internal file/attempt to read past end of file"
          back_ter_map = blip_new_map( terwks, alat,alon,isize,jsize,projlat1,projlat2,projlon, opts_mp, mapvpx,mapvpy,mapvpwidth,mapvpheight )
          ;old back_ter_map = blip_new_map( terwks, terrain_filename,lat_filename,lon_filename, opts_mp, mapvpx,mapvpy,mapvpwidth,mapvpheight )
          ;older map = blip_new_map(wks, lat_filename,lon_filename, opts_mp, mapvpx,mapvpy,mapvpwidth,mapvpheight )
        ;;;;;; ------ END OF DATAFILE-PLOT SECTION ------
        else
        ;;;;;; ------ START OF WRFOUT-PLOT SECTION ------
          back_ter_map = wrf_new_map( terwks, a, opts_mp, mainvpx,mainvpy,mainvpwidth,mainvpheight )
          ;old map = wrf_new_map( wks, a, opts_mp, mapvpx,mapvpy,mapvpwidth,mapvpheight )
        ;;;;;; ------ END OF WRFOUT-PLOT SECTION ------
        end if
        ;;; create plot
        wrf_maplabel(terwks,back_ter_map,opts_map)
        wrf_mapoverlay(back_ter_map,contour_ter)
        print( "   > BACK_TER_MAP CREATED" )

        ;4testprint:  ;;; for early display of a plot
        ;4testprint:  NhlChangeWorkstation( back_ter_map, wks )
        ;4testprint:   print("  --- DO TEST DRAW" )
        ;4testprint:   draw( back_ter_map )
        ;4testprint:   print("  --- DO TEST FRAME" )
        ;4testprint:   frame( wks )
        ;4testprint:   exit
        ;original        wrf_mapoverlay(map,contour_ter)

   end if     ;  end of background terrain plot section

;;; =======================================================================

;;;         PRESSURE-LEVEL PLOT SECTION
;;;         NB: PLOT WILL INCLUDE BOXwMAX DATA IF boxwmax CROSS-SECTION PLOTTED PRIOR TO THIS 

   if( name_max .gt. 4 .and. name_chars(0:4) .eq. "press" ) then
     lplotdone = 1
     ;;; wrf parameter case  indicated by "_" in filename
     if ( string_pattern_grep(plot_param,"=").eq.0 ) then
     ;old if ( string_pattern_grep(plot_param,"_").eq.0 ) then
        ;;; for default case = W
        pressparamid = "W [cm/sec]"
        ;;; determine pressure level
        char_str = chartostring( name_chars(5:name_max) ) 
        pressure = stringtofloat( char_str )
        ;jack - these variables _not_ needed for sounding
        if ( .not. isvar("w") ) then 
          w = wrf_user_getvar(a,"wa",time) ; vertical velocity, averaged to half levels in m/s
        end if
        ;;; convert w into cm/s for display
        w4plot = 100.*w ; vert vel in cm/s
     else
        param_array = split_string_into_array( plot_param,"=" ) 
        ;old param_array = split_string_into_array( plot_param,"_" ) 
        qparaminfo = "Param= "+plot_param+" Unit= ? Mult= 1"
        pressparamid = param_array(1)
        ;;; determine pressure level
        char_str = stringtochar( param_array(0) )
        str_max  = dimsizes(char_str)-2
        pressure = stringtofloat( chartostring( char_str(5:str_max) ) )
        ;4test print ( "PRESSURE "+pressure+" - WRF PARAMETER= "+pressparamid )
        ;;; use same variable name as w plot for convenience
        w4plot = wrf_user_getvar(a,param_array(1),time)
        ;;; for 3D array
        ;;; *NB* WARNING TOP-MOST LEVEL IN SOME ARRAYS HAS MISSING VALUES THERE ! eg qcloud
        ;;; 3D SIZES CHECKED SAME FOR Z,T,uz,wa,qcloud,
        datadims = dimsizes(w4plot)
        kkdata = datadims(0)
        jjsize = datadims(1)
        iisize = datadims(2)
        if ( ismissing(iisize) ) then
          print( "*** REQUESTED ARRAY "+plot_param+" IS NOT 3D - DIMS="+datadims )
          exit
        end if
      end if 
      print( "    DOING PRESSURE PLOT of "+pressparamid+" for mb= "+pressure )

       ;;; get velocity data
        if ( .not. isvar("ua") ) then 
          ua  = wrf_user_getvar(a,"ua",time) ; ua is u averaged to mass points in m/s
          ;;; convert to pilot units (english)
          if( UNITS .ne. "metric" ) then
            ua = ua * 1.94386
          end if
        end if
        if ( .not. isvar("va") ) then 
          va = wrf_user_getvar(a,"va",time) ; va is v averaged to mass points in m/s
          if( UNITS .ne. "metric" ) then
            va = va * 1.94386
          end if
        end if
        if ( .not. isvar("pmb") ) then 
          pmb = wrf_user_getvar(a, "p",time) ; pressure is our vertical coordinate in mb
        end if

          ;;; ALLOW PLOTTING TO INDIVIDUAL OUTPUT FILES
          if ( LOUT .ge. 2 ) then
            ;RASP
            if( ismissing(ENV_NCL_OUTDIR) .or. ENV_NCL_OUTDIR .eq. "" ) then
              wks = wrf_open_ncgm(plot_param)   ; output to ncgm
              ;old wks = wrf_open_ncgm("rasp."+iframe)   ; output to ncgm
            else
              if( ldatatype.ne.0 .and. qfileid.ne."" ) then
              ;alt if( ENV_NCL_OUTDIR.eq."/tmp" .and. qfileid.ne."" ) then
                ;;; append tail for write to /tmp directory
                wks = wrf_open_ncgm(OUTDIR+"/"+plot_param+"."+qfileid)   ; output to ncgm
              else
                wks = wrf_open_ncgm(OUTDIR+"/"+plot_param)   ; output to ncgm
                ;old wks = wrf_open_ncgm(OUTDIR+"/rasp.wrf."+iframe)   ; output to ncgm
              end if
            end if
            ;;; INCREASE WORKSPACE ABOVE DEFAULT IF REQUESTED
            if( WORKSTATIONSPACE .gt. 0 ) then
              setvalues NhlGetWorkspaceObjectId()
                 "wsMaximumSize": WORKSTATIONSPACE
               end setvalues
            end if
          end if      

          ;;; OLD LOCATION of w_plane creation (now moved to after site_load) 
           
                ;4tc ;        Plotting options for pressure level temperature
                ;4tc opts_tc = True
                ;4tc opts_tc@MainTitle = pressure + " mb Vertical Velocity & Winds "
                ;4tc opts_tc@UnitLabel = "T [C]"
                ;4tc ;single_time_file:
                ;4tc opts_tc@TimeLabel = times(it)+"Z"
                ;4tc ;multiple_time_file: opts_tc@TimeLabel = times(it) + " = " + time_save + " + " + hours + " h"
                ;4tc ;;; IF NON-INTERACTIVE RUN, USE ID AS TITLE
                ;4tc if ( .not. ismissing(ENV_NCL_ID)  .and. ENV_NCL_ID .ne. "" ) then
                ;4tc   opts_tc@TimeLabel =  ENV_NCL_ID
                ;4tc end if
                ;4tc opts_tc@LevelLabel = titleline3
                ;4tc opts_tc@cnLineColor = "red"
                ;4tc opts_tc@cnLineDashPattern = "1"
                ;4tc opts_tc@cnInfoLabelOn = True
                ;4tc opts_tc@cnLineLabelAngleF = 0.
                ;4tc opts_tc@cnLineLabelFontColor = "red"
                ;4tc ;512x512: opts_tc@cnLineLabelFontHeightF = .015
                ;4tc ;800x800:        
                ;4tc opts_tc@cnLineLabelFontHeightF = .010
                ;4tc opts_tc@cnLineLabelPerimOn = True
                ;4tc opts_tc@cnLineLabelPerimColor = "red"
                ;4tc opts_tc@cnHighLabelFontColor = "red"
                ;4tc opts_tc@cnLowLabelFontColor = "red"
                ;4tc opts_tc@LineThickness = 2.0
                ;4tc opts_tc@ContourParameters = (/ 0.,0., 5.0 /)
                
                ;4rh ;        Plotting options pressure level  for relative humidity
                ;4rh opts_rh = True
                ;4rh opts_rh@MainTitle = pressure + " mb Height ~I~[m, blue]~P~, T ~I~(C, red)~P~, RH ~I~(color)~P~ & Winds ~I~[kt]~P~"
                ;4rh opts_rh@UnitLabel = "RH [%]"
                ;4rh    ;single_time_file:
                ;4rh opts_rh@TimeLabel = times(it)+"Z"
                ;4rh ;multiple_time_file: opts_rh@TimeLabel = times(it) + " = " + time_save + " + " + hours + " h"
                ;4rh ;;; IF NON-INTERACTIVE RUN, USE ID AS TITLE
                ;4rh if ( .not. ismissing(ENV_NCL_ID) .or. ENV_NCL_ID .eq. ""  ) then
                ;4rh   opts_rh@TimeLabel =  ENV_NCL_ID
                ;4rh end if
                ;4rh opts_rh@LevelLabel = titleline3
                ;4rh opts_rh@ContourParameters = (/ 10., 90., 10. /)
                ;4rh opts_rh@cnFillColors = (/"white","white","white","white","chartreuse","green","green3","green4","forest green","PaleGreen4"/)
                ;4rh opts_rh@cnLineLabelBackgroundColor = -1
                ;4rh opts_rh@lbAutoManage = False
                ;4rh ;512x512:opts_rh@lbTitleFontHeightF = .02
                ;4rh ;800x800:        
                ;4rh opts_rh@lbTitleFontHeightF = .015
                ;4rh ;512x512:opts_rh@lbLabelFontHeightF = .020
                ;4rh ;800x800:        
                ;4rh opts_rh@lbLabelFontHeightF = .015
                ;4rh opts_rh@lbBottomMarginF = 0.4
                
                ;        Plotting options for pressure level vertical velocity
                opts_w = True
               ;;; wrf parameter case  indicated by "_" in filename
               if ( string_pattern_grep(plot_param,"_").eq.0 ) then
                  ;;; for default case = W
                  ;;; wind barb always in knots
                  opts_w@MainTitle = "Vertical Velocity & Wind [kt] at "+pressure+"mb"
                  opts_w@UnitLabel = "[cm/s]"
                  ;old opts_w@UnitLabel = "Vertical Velocity [cm/s]"

                  if( ldoblsection .eq. 0 ) then
                    opts_w@LevelLabel = titleline3
                  else  
                    if( ldowautosection .eq. 0 ) then
                      ;;; include slice position and angle
                      opts_w@LevelLabel = "slice X,Y= "+xofblsection+","+yofblsection+"@"+mapangledeginteger+"~F34~0~F21~"
                    else 
                      ;;; if follows boxwmax, include boxwmax info and position
                      ;without_angle:
                      opts_w@LevelLabel = "boxWmax="+wmaxcmps+"@"+latmaxw+","+lonmaxw+","+zmaxw+"m" 
                      ;with_angle: opts_w@LevelLabel = "boxWmax="+wmaxcmps+"@"+latmaxw+","+lonmaxw+","+zmaxw+"m"+"("+mapangledeginteger+"~F34~0~F21~)"
                      ;prelatlon opts_w@LevelLabel = "boxWmax=+wmaxcmps+"cm/s @X,Y= "+mapangledeginteger+"@"+imaxw+","+jmaxw+" Z="+zmaxw+"m"
                    end if
                  end if

                  ;jack - SET W CONTOURS
                  ;set_w_increment only:
                  opts_w@ContourParameters = (/ 0.,0., 25. /)
                  ; PAULS opts_w@ContourParameters = (/ -200.,200., 25. /)
                  ;old opts_w@ContourParameters = (/ 0.,0., 50. /)
                  ;with_w_limits: opts_w@ContourParameters = (/ -250., 250., 50. /)
                else
                  ;;; for wrf parameter case 
                  ;;; convert to pilot units (english)
                  opts_w@MainTitle = pressparamid+" [MKS Units]  & Wind [kt] at "+pressure+"mb"
                  opts_w@UnitLabel = pressparamid+" [MKS units]"
                  ;use automatic scaling by not setting  opts_w@ContourParameters = (/ 0.,0., 50. /)
                end if

               if(  LFIXEDCOLOR .eq. 1 ) then
                  opts_w@ContourParameters = (/ -200., 200., 25. /)
                  print( "    using FIXED COLOR for PRESSURE CROSS-SECTION vertical velocities" )
               end if

               ;;;  non-variable dependent plot params
               ;single_time_file:
               opts_w@TimeLabel = times(it)+"Z"
               ;multiple_time_file: opts_w@TimeLabel = times(it) + " = " + time_save + " + " + hours + " h"
               ;;; IF NON-INTERACTIVE RUN, USE ID AS TITLE
               if ( .not. ismissing(ENV_NCL_ID) .or. ENV_NCL_ID .eq. ""  ) then
                 opts_w@TimeLabel = trim_string( ENV_NCL_ID )
               end if
                opts_w@lbAutoManage = False
                opts_w@lbTitleFont = "helvetica"
                opts_w@lbLabelFont = "helvetica"
                opts_w@lbTitleOffsetF     = -0.5  ; move colorbar and its title closer together
                opts_w@lbTitleFontHeightF = .015
                opts_w@lbLabelFontHeightF = .015
                ;oldlb opts_w@lbTopMarginF     = -0.3  ; move colorbar and its title upward, closer to plot
                ;oldlb opts_w@lbBottomMarginF = .2

;;;test - but doesnt turn ticks on
;ticktest     ;;; jack - add ticks of gridpts to 
;ticktest     opts_w@tmXBMode          = "Automatic"     ; Set tick mark mode.
;ticktest     opts_w@tmYLMode          = "Automatic"     ; Set tick mark mode.
;ticktest     ; tmLabel is for numbers
;ticktest     opts_w@tmXBLabelFont     = "helvetica"        ; Font for X number label
;ticktest     opts_w@tmXBLabelFontHeightF     = 0.020
;ticktest     opts_w@tmYLLabelFont     = "helvetica"        ; Font for Y number label
;ticktest     opts_w@tmYLLabelFontHeightF     = 0.020
;trying to keep color spread consistent (now max is blue!?)
;not_valid_cn_resource: opts_w@gsnSpreadColors = True
;not_valid_cn_resource: set_attr(opts_w,"gsnSpreadColors",True)
;not_valid_cn_resource: set_attr(opts_w,"gsnSpreadColors",True)
;not_valid_cn_resource:
 opts_w@cnFillColor = (/ 2,3,4,5,6,7,8 /)

        ;;; LABELBAR OPTIONS TO ALLOW LARGER VERTICAL PLOT - put units & fixed flag to side of colorbar
        ;;; specify label bar height,width to conform to my esthetics
        opts_w@pmLabelBarHeightF  = 0.08 ; 
        opts_w@pmLabelBarWidthF  = 0.80 ; 
        ;old opts_w@pmLabelBarWidthF  = 0.78 ; 
        ;;; eliminate label title (units string)
        opts_w@lbTitleOn = False
        ;;; move label bar as close to plot as possible (without making orthogonal position negative)
        opts_w@lbTitleExtentF     = 0.0 ; no effect of changing from 0.6
        opts_w@lbBottomMarginF     = 0.0 ; no apparnet effect
        opts_w@lbTopMarginF     = 0.0 ; no apparnet effect
        opts_w@pmLabelBarOrthogonalPosF  = 0.0 ; moves slightly upward
        ;unused  opts_w@lbJustification = "TopCenter" set in subroutine so not set here
        ;4test-display_lb_perim: opts_w@lbPerimOn = True ; opts_w@lbPerimColor = 1

                ;4spd ;        Plotting options for pressure level wind speed
                ;4spd opts_spd = True
                ;4spd opts_spd@MainTitle = "300 mb Height ~I~(m, blue)~P~, Wind Speed ~I~(m/sec, green)~P~ & Winds ~I~[kt]~P~"
                ;4spd opts_spd@UnitLabel = "wpsd[kt])"
                ;4spd ;single_time_file:
                ;4spd opts_spd@TimeLabel = times(it)+"Z"
                ;4spd ;multiple_time_file: opts_spd@TimeLabel = times(it) + " = " + time_save + " + " + hours + " h"
                ;4spd ;;; IF NON-INTERACTIVE RUN, USE ID AS TITLE
                ;4spd if ( .not. ismissing(ENV_NCL_ID) .or. ENV_NCL_ID .eq. ""  ) then
                ;4spd   opts_spd@TimeLabel =  ENV_NCL_ID
                ;4spd end if
                ;4spd opts_spd@LevelLabel = titleline3
                ;4spd opts_spd@LineThickness = 3.0
                ;4spd opts_spd@cnLineColor = "medium sea green"
                ;4spd opts_spd@cnLineLabelFontColor = "medium sea green"
                ;4spd opts_spd@cnLineLabelAngleF = 0.
                ;4spd ;512x512:opts_spd@cnLineLabelFontHeightF = .015
                ;4spd ;800x800:        
                ;4spd opts_spd@cnLineLabelFontHeightF = .010
                ;4spd opts_spd@cnLineLabelPerimOn = True
                ;4spd opts_spd@cnLineLabelPerimColor = "medium sea green"
                ;4spd opts_spd@cnHighLabelBackgroundColor = -1
                ;4spd opts_spd@cnHighLabelFontColor = "medium sea green"
                ;4spd opts_spd@cnLowLabelBackgroundColor = -1
                ;4spd opts_spd@cnLowLabelFontColor = "medium sea green"
                ;4spd opts_spd@ContourParameters = (/ 0.,0., 10. /)
                ;4spd ;jack - turn off contour info label
                ;4spd ;4tc opts_tc@cnInfoLabelOn = False
                ;4spd ;original opts_spd@cnInfoLabelOn = True
                
                ;old    ;        Plotting options for pressure level terrain
                ;old   opts_ter = True
                ;old   opts_ter@NoTitles = True
                ;old   opts_ter@cnLineColor = "black"
                ;old   opts_ter@cnInfoLabelOn = False
                ;old   opts_ter@cnHighLabelsOn = True
                ;old   opts_ter@cnLowLabelsOn = True
                ;old   opts_ter@cnLineLabelAngleF = 0.
                ;old   ;512x512:opts_ter@cnLineLabelFontHeightF = .015
                ;old   ;800x800:        
                ;old   opts_ter@cnLineLabelFontHeightF = .010
                ;old   opts_ter@cnLineLabelPerimOn = True
                ;old   opts_ter@cnLineLabelPerimColor = "navy blue"
                ;old   opts_ter@cnLineLabelFontColor = "navy blue"
                ;old   opts_ter@cnHighLabelBackgroundColor = -1
                ;old   opts_ter@cnHighLabelFontColor = "navy blue"
                ;old   opts_ter@cnLowLabelBackgroundColor = -1
                ;old   opts_ter@cnLowLabelFontColor = "navy blue"
                ;old   opts_ter@LineThickness = 3.

                ;        Plotting options for  pressure level wind barbs
                opts_vct = True
                ;;; VectLen sets wind vector length in ndc EXCEPT negative uses gridpt spacing i.e. -1 plots every datapt, -2 every 2nd gridpt, etc
                opts_vct@VectLen = 0.03
                ;old opts_vct@VectLen = -2.0
                ;original opts_vct@NumVectors = 47
                opts_vct@WindBarbsOn = True
                opts_vct@NoTitles = True
                ;original opts_vct@vcWindBarbColor = "black"
                opts_vct@vcWindBarbColor = "navy blue"
                ;jack - tried to alter reference vector number format but nothing had an effect
                ;dontuse opts_vct@vcRefAnnoExplicitMagnitudeF = 1 ; doesnt do what I think it should do !
                ;bad-neverfinishes opts_vct@vcMagnitudeScalingMode = "AllIntegers"
                ;noeffect opts_vct@vcLabelScaleValueF = 2.0
                ;noeffect opts_vct@vcMagnitudeFormat = "f.3"
                ;jack - turn off reference arrow - cant see any value when length is constant
                opts_vct@vcRefAnnoOn = False
                
                ;        Plotting options for pressure level background
                ;jack- now set same for all plots

        ;;; for section line orientation on horiz.plot - set line options   
        opts_sectionline = True
        opts_sectionline@gsLineColor = "white"
        opts_sectionline@gsLineDashPattern = 5
        opts_sectionline@gsLineThicknessF = 2.0
                
                ;        OK, what to plot out of all of that mess?  Compute
                ;        the contour levels that we are going to have.


;trying to keep color spread consistent (now max is blue!?)
;no_effect: opts_w@cnFillColors = spread_colors(wks,contour_w,0,-1)

      ;;; COULD ALTER PLOT PARAMS FOR DIFFERENT PRESSURE LEVELS HERE BY INSERTING IF TESTS

      ;onceonly_background: create "blank" geographic map for plotting parameter data
      opts_blankmap = True
      opts_blankmap@mpOutlineOn = False
      opts_blankmap@mpGridAndLimbOn = False
      opts_blankmap@vpUseSegments = True

        ;onceonly_background: failed attmpet to get gray background 
        ;dontwork opts_blankmap@mpDefaultFillColor = 3
        ;dontwork opts_blankmap@mpDefaultFillColor = "red"

        ;;; FOR SITE SUBSTITUTIONS  (jack: if alter filename also change BLIP/PLOT/filename)
        load "rasp.site_load.pressure-level.ncl"  

        ;;;  allow command line argument override of contouring 
        if( isvar("CONTOURS") ) then
           opts_w@ContourParameters = CONTOURS
            print( "USING COMMAND-LINE CONTOURS = "+CONTOURS )
        end if


          ;;; MOVED w_plane creation here so after site_load 
                ;        Vertically interpolate the selected 3d fields to this
                ;        pressure surface.
                ;4hgt height_plane  = wrf_user_intrp3d( z,pmb,ter,"h",pressure,0.)
                ;4tc                tc_plane = wrf_user_intrp3d(tc,pmb,ter,"h",pressure,0.)
                u_plane  = wrf_user_intrp3d( ua,pmb,ter,"h",pressure,0.) ; u,v still in kts from above
                v_plane  = wrf_user_intrp3d( va,pmb,ter,"h",pressure,0.)
                ;;; wind barb always in kts
                if( UNITS .eq. "metric" ) then
                   u_plane = u_plane * 1.94386
                   v_plane = v_plane * 1.94386
                end if
                ;4rh rh_plane  = wrf_user_intrp3d( rh,pmb,ter,"h",pressure,0.)
                w_plane  = wrf_user_intrp3d( w4plot,pmb,ter,"h",pressure,0.)
     
        ;;; PRINT MIN,MAX
        print( "    "+times(it)+" "+iframe+"= "+pressure+"mb PRESSURE CROSS-SECTION: "+pressparamid+" MIN,MAX= "+min(w_plane)+"  "+max(w_plane) )
        ;old print( times(it)+" "+iframe+"= "+pressure+"mb PRESSURE CROSS-SECTION: W [cm/s] MIN,MAX= "+min(w_plane)+"  "+max(w_plane) )
      ;;; COULD ALTER PLOT PARAMS FOR DIFFERENT PRESSURE LEVELS HERE BY INSERTING IF TESTS

                        ;4hgt opts_ter@ContourParameters = (/ 0.,0., 20.0 /)
                        ;4tc opts_tc@NoTitles = True
                        ;jack - PLOT W 

                        contour_w     = wrf_new_fill_contour( wks,w_plane,opts_w, mainvpx,mainvpy,mainvpwidth,mainvpheight )
                        ;pre-viewport_params                        contour_w     = wrf_new_fill_contour(wks,w_plane,opts_w)
                        ;4rh                        contour_rh     = wrf_new_fill_contour(wks,rh_plane,opts_rh)
                        ;4tc                        contour_tc     = wrf_new_line_contour(wks,tc_plane,opts_tc)
                        ;4hgt contour_height = wrf_new_line_contour(wks, height_plane,opts_ter)
                        vector         = wrf_new_vector( wks,u_plane, v_plane,opts_vct, mainvpx,mainvpy,mainvpwidth,mainvpheight )
                        ;pre-viewport_params                        vector         = wrf_new_vector(wks,u_plane, v_plane,opts_vct)

         ;;; ADD LABEL BAR UNITS (and FIXED flag) to side of label bar (assumes units not ploted by label bar itself)
        if( isatt(opts_w,"ContourParameters") .and. opts_w@ContourParameters(0) .ne. opts_w@ContourParameters(1) ) then
          kfixedcolor = 1
        end if 
        add_labelbar_text( wks, contour_w, opts_w@UnitLabel, kfixedcolor )

        ;onceonly_background: 
        ;; ruc/nam addition - ruc/nam-only/rasp-only if - should never use this parameter for ruc/nam
        if( ldatatype.ne.0 ) then
        ;;;;;; ------ START OF DATAFILE-PLOT SECTION ------
          print ( "*** NCL ERROR EXIT *** tried to plot pressure-level parameter for RUC/NAM data !?" )
          exit
        ;;;;;; ------ END OF DATAFILE-PLOT SECTION ------
        else
        ;;;;;; ------ START OF WRFOUT-PLOT SECTION ------
          map = wrf_new_map( wks, a, opts_blankmap, mapvpx,mapvpy,mapvpwidth,mapvpheight )
        ;;;;;; ------ END OF WRFOUT-PLOT SECTION ------
        end if

                        ;4rh                        wrf_mapoverlay(map,contour_rh)
                        ;4tc                        wrf_mapoverlay(map,contour_tc)

                        ;jack - PLOT W CONTOURS AND WIND VECTORS
                         wrf_mapoverlay(map,contour_w)
                         wrf_mapoverlay(map,vector)

;test - tick creation
;ticktest pid = create "TickMarks" tickMarkClass wks
;ticktest end create
;ticktest ;old pid = create "TickMarks" tickMarkClass wks
;ticktest ;old    "vpXF" : .2
;ticktest ;old    "vpYF" : .8
;ticktest ;old    "vpWidthF" : .6
;ticktest ;old    "vpHeightF" : .6
;ticktest ;old end create
;ticktest ;plot, but different rectangle from map:  draw(pid)                
;ticktest ;nada overlay(map,pid)                
;ticktest ;nada wrf_mapoverlay(map,pid)                
;ticktest ;error NhlAddOverlay(map,pid,-1)                
               
       ;;; MUST DRAW MAP PRIOR TO GSN CALLS
          draw(map)

        ;onceonly_background: ;;; overplot with terrain map
        NhlChangeWorkstation( back_ter_map, wks )
        draw(back_ter_map)
        ;;; must change workstation back to avoid being deleted when new workstation created
        NhlChangeWorkstation( back_ter_map, terwks )
                
        ;;; for BL section, add line indicating cross-section location
        ;; (I think this is not exact, but offset by about 1/2 grid pt so emprically added 0.5 to x,y)
        ;;; wrf parameter case  indicated by "_" in filename
        if ( string_pattern_grep(plot_param,"_").eq.0 ) then
          if( ldoblsection .gt. 0 ) then
             ;;; returns section x,y values in grid pts
             sectionxy = wrf_user_set_xy( z, xofblsection,yofblsection, mapangledeg )
             xydims = dimsizes(sectionxy) 
             xx = new( 2, float)
             ;;; get viewport info
             getvalues map
  		"vpXF" : vpx
  		"vpYF" : vpy
  		"vpHeightF" : vph
  		"vpWidthF" : vpw
             end getvalues
             yy = new( 2, float)
             xx(0) = vpx + vpw* (0.5+ sectionxy(0,0) ) / ( dims3d(2)-1 ) 
             xx(1) = vpx + vpw* (0.5+ sectionxy( (xydims(0)-1),0 ) ) / ( dims3d(2)-1 ) 
             yy(0) = vpy -vph + vph* (0.5+ sectionxy(0,1) ) / ( dims3d(1)-1 ) 
             yy(1) = vpy -vph + vph* (0.5+ sectionxy(  (xydims(0)-1),1 ) ) / ( dims3d(1)-1 ) 
             gsn_polyline_ndc ( wks, xx,yy, opts_sectionline ) 
             delete ( sectionxy )
             delete ( xx )
             delete ( yy )
          end if
        end if
               
          ;;; FINALLY, DRAW FRAME
          frame(wks)
               
        ;        remove the dummy arrays

        ;jack - PLOT W 
        delete(opts_w)
        delete(w_plane)
        delete(contour_w)
        delete(u_plane)
        delete(v_plane)
        ;4tc        delete(opts_tc)
        ;4rh        delete(rh_plane)
        ;4rh        delete(contour_rh)
        ;4tc        delete(tc_plane)
        ;4tc        delete(contour_tc)
        ;old        delete(opts_ter)


      ;;; print current wall clock & elapsed time
      PrintWallClockElapseTime(wcStrt,"Pressure-Level Plot end -")

      continue 
   end if        ;        end of pressure level plot section

;;; =======================================================================

;;;        SCALAR/WIND CONTOUR PLOT SECTIONS

   ;;; if "none of the above" plots done then must be a scalar/wind parameter plot
   if( lplotdone .eq. 0 ) then
      lplotdone = 1

      ;;; ALLOW PLOTTING TO INDIVIDUAL OUTPUT FILES
      if ( LOUT .ge. 2 ) then
        ;RASP
         if( ismissing(ENV_NCL_OUTDIR) .or. ENV_NCL_OUTDIR .eq. "" ) then
          wks = wrf_open_ncgm(plot_param)   ; output to ncgm
          ;alt wks = gsn_open_wks("ncgm",plot_param)   ; output to ncgm
          ;old wks = wrf_open_ncgm("rasp."+iframe)   ; output to ncgm
         else
           if( ldatatype.ne.0 .and. qfileid.ne."" ) then
           ;alt if( ENV_NCL_OUTDIR.eq."/tmp" .and. qfileid.ne."" ) then
            ;;; append tail for write to /tmp directory
            wks = wrf_open_ncgm(OUTDIR+"/"+plot_param+"."+qfileid)   ; output to ncgm
            ;alt wks = gsn_open_wks("ncgm",OUTDIR+"/"+plot_param+"."+qfileid)   ; output to ncgm
            ;alt  wks = create "wks" ncgmWorkstationClass defaultapp
            ;alt      "wkMetaName" : OUTDIR+"/"+plot_param+"."+qfileid+".ncgm"
            ;alt  end create
          else
            wks = wrf_open_ncgm(OUTDIR+"/"+plot_param)   ; output to ncgm
            ;alt wks = gsn_open_wks("ncgm",OUTDIR+"/"+plot_param)   ; output to ncgm
            ;old wks = wrf_open_ncgm(OUTDIR+"/rasp.wrf."+iframe)   ; output to ncgm
          end if
        end if
        ;;; INCREASE WORKSPACE ABOVE DEFAULT IF REQUESTED
        if( WORKSTATIONSPACE .gt. 0 ) then
          setvalues NhlGetWorkspaceObjectId()
             "wsMaximumSize": WORKSTATIONSPACE
          end setvalues
        end if
      end if

;;; ==========================================================

      ;;; SCALAR CONTOUR PLOT SECTION

      ; treat vector case separately from scalars
      if ( plot_param .ne. "blwind" .and.  plot_param .ne. "sfcwind" .and.  plot_param .ne. "bltopwind"  .and.  plot_param .ne. "blwindspd_blwinddir"  .and.  plot_param .ne. "sfcwindspd_sfcwinddir"  .and.  plot_param .ne. "bltopwindspd_bltopwinddir"  .and.  plot_param .ne. "blwindkt_blwinddeg" ) then

        ;;; SCALAR PARAMETER INITIALIZATIONS
        ;;; cleanup for multiple plots
        composite_title = ""
                
        ;;; SET DEFAULT DATAFILE FORMAT (must be within parameter loop, so can be overwritten for a specific parmameter)
        ldatafmt = 0

        ;;; ruc/nam addition - ruc/nam-only/rasp-only if
        if( ldatatype.ne.0 ) then
        ;;;;;; ------ START OF DATAFILE-PLOT SECTION ------
           ;;; RUC/NAM PARAMETER DATA READ FROM FILE
           ;;; decide whether this is 3 parameter,  2parameter (mask & _), or single parameter variable (multi ifs simulate elseif)
           ;;; SPECIAL COMPOSITE CASE - REQUIRES 3 PARAMETERS
           ;;; do not just read+use hglider datafile as 1-parameter since lose stipple
           if ( plot_param .eq. "hglider" ) then
             bparam = new( (/jsize,isize/), float )
             cparam = new( (/jsize,isize/), float )
             if( ldatatype .eq. 1 ) then
               bparam_filename = string_target_replace( ENV_NCL_FILENAME, "dummy","hwcrit" )
             else
               bparam_filename = string_target_replace( ENV_NCL_FILENAME, "dummy","hwcritft" )
             end if
             ;;; create new TimeLabel string from datafile header line 1
             delete( "ENV_NCL_ID" ) 
             ENV_NCL_ID  = qblank_180
             NCL_JACK_FORTRAN :: read_blip_datafile( bparam_filename, isize,jsize, bparam, ENV_NCL_ID ) 
             ENV_NCL_ID = trim_string( ENV_NCL_ID )
             eparam = bparam
             cparam = 0.0
             if( ldatatype .eq. 1 ) then
               bparam_filename = string_target_replace( ENV_NCL_FILENAME, "dummy", "zsfclcl" )
             else
               bparam_filename = string_target_replace( ENV_NCL_FILENAME, "dummy", "zsfclclft" )
             end if
             NCL_JACK_FORTRAN :: read_blip_datafile( bparam_filename, isize,jsize, bparam, qdummy ) 
             NCL_JACK_FORTRAN :: min_2darrays( eparam,cparam, bparam,1.0, isize,jsize )
             if( ldatatype .eq. 1 ) then
               bparam_filename = string_target_replace( ENV_NCL_FILENAME, "dummy", "zblcl" )
             else
               bparam_filename = string_target_replace( ENV_NCL_FILENAME, "dummy", "zblclft" )
             end if
             NCL_JACK_FORTRAN :: read_blip_datafile( bparam_filename, isize,jsize, bparam, qdummy ) 
             NCL_JACK_FORTRAN :: min_2darrays( eparam,cparam, bparam,2.0, isize,jsize )
             print ( ">>> 3-parameter data CREATED: hglider" )
           else
           ;;; TWO-PARAMETER CASE  INDICATED BY "_" IN FILENAME
           if ( string_pattern_grep(plot_param,"_").eq.1 ) then
             param_array = split_string_into_array( plot_param,"_" ) 
             bparam = new( (/blipdata_nny, blipdata_nnx/), float )
             bparam_filename = string_target_replace( ENV_NCL_FILENAME, "dummy", param_array(0) )
             ;;; create new TimeLabel string from datafile header line 1
             delete( "ENV_NCL_ID" ) 
             ENV_NCL_ID = qblank_180 
             NCL_JACK_FORTRAN :: read_blip_datafile( bparam_filename, blipdata_nnx,blipdata_nny, bparam, ENV_NCL_ID ) 
             ENV_NCL_ID = trim_string( ENV_NCL_ID )
             cparam = new( (/blipdata_nny, blipdata_nnx/), float )
             cparam_filename = string_target_replace( ENV_NCL_FILENAME, "dummy", param_array(1) )
             NCL_JACK_FORTRAN :: read_blip_datafile( cparam_filename, blipdata_nnx,blipdata_nny, cparam, qdummy ) 
             print ( ">>> two-parameter data CREATED: "+param_array(0)+"_"+param_array(1) )
           else
           if( string_pattern_grep(plot_param,"mask").eq.1 ) then
              param1 = string_target_replace( plot_param,"mask","" )
              param2 = param1+"dif"
              bparam = new( (/blipdata_nny, blipdata_nnx/), float )
              bparam_filename = string_target_replace( ENV_NCL_FILENAME, "dummy", param1 )
              ;;; create new TimeLabel string from datafile header line 1
              delete( "ENV_NCL_ID" ) 
              ENV_NCL_ID = qblank_180 
              NCL_JACK_FORTRAN :: read_blip_datafile( bparam_filename, blipdata_nnx,blipdata_nny, bparam, ENV_NCL_ID ) 
              ENV_NCL_ID = trim_string( ENV_NCL_ID )
              cparam = new( (/blipdata_nny, blipdata_nnx/), float )
              cparam_filename = string_target_replace( ENV_NCL_FILENAME, "dummy", param2 )
              NCL_JACK_FORTRAN :: read_blip_datafile( cparam_filename, blipdata_nnx,blipdata_nny, cparam, qdummy ) 
             ;unneeded  lcompositetype = 1
              print ( ">>> mask data CREATED: "+param1+"+"+param2 )
           else
           ;;; SINGLE COMPONENT CASE
             ;;; UNITS determines units displayed on plot - SHOULD be same as in datafile but not tested
             bparam = new( (/blipdata_nny, blipdata_nnx/), float )
             bparam_filename = string_target_replace( ENV_NCL_FILENAME, "dummy", plot_param )
             ;;; create new TimeLabel string from datafile header line 1
             delete( "ENV_NCL_ID" ) 
             ENV_NCL_ID = qblank_180 
             NCL_JACK_FORTRAN :: read_blip_datafile( bparam_filename, blipdata_nnx,blipdata_nny, bparam, ENV_NCL_ID ) 
             ENV_NCL_ID = trim_string( ENV_NCL_ID )
             ;old NCL_JACK_FORTRAN :: read_blip_datafile( bparam_filename, blipdata_nnx,blipdata_nny, bparam, ENV_NCL_ID ) 
             print ( ">>> "+plot_param+" SINGLE COMPONENT TITLE READ: "+ENV_NCL_ID )
           end if
           end if
           end if

        ;;;;;; ------ END OF DATAFILE-PLOT SECTION ------
        else
        ;;;;;; ------ START OF WRFOUT-PLOT SECTION ------
          ;;; DO RASP CONTOUR PARAMETER CALCULATIONS
          load "rasp.bparam_calc.ncl" 
        ;;;;;; ------ END OF WRFOUT-PLOT SECTION ------
        end if

        ;original        ; smoothed SLP
        ;original        slvl = wrf_user_getvar(a,"slvl",time) ; psl amd tsl
        ;original        wrf_user_filter2d(slvl, 3) ; filter the fields

        ;;; SET CONTOUR PLOT bparam CONTOUR RANGE
        load "rasp.bparam_resources.ncl" 

        ;;; UGLY RUC/NAM COMPOSITE KLUDGE FORCES CONGRUENCE WITH NON-COMPOSITE BLIPMAP
        if( ldatatype .eq. 2 ) then
           opts_bparam@pmLabelBarOrthogonalPosF  = -0.02 ; move upward
        end if

        ;;;  allow command line argument override of contouring 
        if(  isvar("CONTOURS") ) then
            opts_bparam@ContourParameters = CONTOURS
            print( "USING COMMAND-LINE CONTOURS = "+sprintf("%.1f",CONTOURS(0))+","+sprintf("%.1f",CONTOURS(1))+","+sprintf("%.1f",CONTOURS(2)) )
        end if

        ;onceonly_background: ;;; create "blank" geographic map for plotting parameter data
        opts_blankmap = True
        opts_blankmap@mpOutlineOn = False
        opts_blankmap@mpGridAndLimbOn = False
        opts_blankmap@vpUseSegments = True
        ;latlongrid
        if( qproj7 .eq. "latlong" ) then
          opts_blankmap@mpProjection = "CylindricalEquidistant"
        end if
          ;onceonly_background:  failed attempt to get gray background
          ;dontwork opts_blankmap@mpDefaultFillColor = 3
          ;dontwork opts_blankmap@mpDefaultFillColor = "red"

        ;;; FOR SITE SUBSTITUTIONS  (jack: if alter filename also change BLIP/PLOT/filename)
        load "rasp.site_load.contour-parameter.ncl"  

        ;;; CHECK THAT AN ARRAY WAS CREATED
        if ( .not. isdefined("bparam") .or. .not. isvar("bparam") ) then
          print( "*** SKIPPING CONTOUR PARAMETER = "+plot_param+" *** no array found (bad name?)" )
          ;unused ;;; draw blank frame - will generate a black image
          ;unused frame(wks)
          continue
        end if  

          ;old ;;; ARRAY MIGHT CONTAIN ONLY MISSING VALUES DUE TO MASK OPERATION
          ;old ;    for this case set all values to zero to avoid "missing value" errors
          ;old if ( ismissing(min(bparam)) .or. ismissing(max(bparam)) ) then
          ;old   bparam = 0
          ;old   print( "* SET "+plot_param+" ARRAY=0 SINCE ALL VALUES MISSING" )
          ;old end if  
                    
        ;;; PRINT MIN,MAX
        print( "    "+times(it)+" "+iframe+"= PARAMETER "+plot_param+"  MIN,MAX= "+min(bparam)+"  "+max(bparam) )

        ;onceonly_background:  ;;; setup map plot
        ;; ruc/nam addition - ruc/nam-only/rasp-only if
        if( ldatatype.ne.0 ) then
        ;;;;;; ------ START OF DATAFILE-PLOT SECTION ------
          lat_filename = string_target_replace( ENV_NCL_INFOFILENAME, "dummy", "latitude" )
          lon_filename = string_target_replace( ENV_NCL_INFOFILENAME, "dummy", "longitude" )
          ;old lat_filename = ENV_NCL_INFOFILENAME+"/latitude."+ENV_NCL_REGIONNAME+".data"
          ;old lon_filename = ENV_NCL_INFOFILENAME+"/longitude."+ENV_NCL_REGIONNAME+".data"
          map = blip_new_map(wks, alat,alon,isize,jsize,projlat1,projlat2,projlon, opts_blankmap, mapvpx,mapvpy,mapvpwidth,mapvpheight )
          ;4test: print( "POST-blip_new_map mapvpwidth,mapvpheight,mapvpx,mapvpy= "+mapvpwidth+","+mapvpheight+","+mapvpx+","+mapvpy)
          ;old map = blip_new_map(wks, terrain_filename,lat_filename,lon_filename, opts_blankmap, mapvpx,mapvpy,mapvpwidth,mapvpheight )
        ;;;;;; ------ END OF DATAFILE-PLOT SECTION ------
        else
        ;;;;;; ------ START OF WRFOUT-PLOT SECTION ------
          map = wrf_new_map( wks, a, opts_blankmap, mapvpx,mapvpy,mapvpwidth,mapvpheight )
        ;;;;;; ------ END OF WRFOUT-PLOT SECTION ------
        end if

        ;jack - PLOT PARAMETER IF NOT A CONSTANT OR TERRAIN
        if ( plot_param .ne. "HGT" ) then
          ;;; ADD MASKING FOR CERTAIN COMPOUND PLOTS
          ;;; ARRAY MIGHT CONTAIN ONLY MISSING VALUES DUE TO MASK OPERATION SO NOW PUT contour_bparam= & wrf_mapoverlay INSIDE max/min TEST IF
          if ( lcompositetype .eq. 1 .and. .not. ismissing(min(bparam)) .and. .not. ismissing(max(bparam)) ) then
            ;    for this case set all values to zero to avoid "missing value" errors
            bparam  = mask( bparam, (cparam.ge.0), True )
            delete ( cparam )
            ;;; USE  _RASTER_ MASKING (since contour masking messes up contouring of adjacent locations)
            opts_bparam@cnFillMode = "CellFill"  ; use instead of RasterFill so can get gray background to show
            opts_bparam@cnMissingValFillColor = -1 ; transparent
          end if
          ;;; allow printing of composite parameter use info in title line
          if ( lcompositetype .eq. 0 ) then
            opts_bparam@LevelLabel = titleline3
          else
            opts_bparam@LevelLabel = ""
          end if

          ;;; PLOT SCALAR PARAMETER AS FILLED CONTOURS
          ;4testprint: print( "opts_bparam@ContourParameters="+opts_bparam@ContourParameters )
          contour_bparam = wrf_new_fill_contour( wks, bparam(:,:), opts_bparam, mainvpx,mainvpy,mainvpwidth,mainvpheight )
          ;pre-viewport_params          contour_bparam = wrf_new_fill_contour(wks,bparam(:,:),opts_bparam)
          wrf_mapoverlay(map,contour_bparam)
        end if

        ;4test: query_object( wks, contour_bparam, "pmLabelBarWidthF" ) ; query_object( wks, contour_bparam, "pmLabelBarHeightF" )

        ;;; ADD LABEL BAR UNITS (and FIXED flag) to side of label bar (assumes units not ploted by label bar itself)
        if( isatt(opts_bparam,"ContourParameters") .and. opts_bparam@ContourParameters(0) .ne. opts_bparam@ContourParameters(1) ) then
          kfixedcolor = 1
        end if 
        add_labelbar_text( wks, contour_bparam, opts_bparam@UnitLabel, kfixedcolor )
        ;old add_labelbar_text( wks, contour_bparam, opts_bparam@UnitLabel, LFIXEDCOLOR )
        ;4test: add_labelbar_text( wks, contour_bparam, opts_bparam@UnitLabel, 1 )

        ;onceonly_background: ;;; to add gray background
        ;;; PLOT MASK BACKGROUND - to create non-white background behind masked contour plot
        ;;  ideally would be done at parameter plot time by setting background color for masked region but I cant figure out how to do that! 
        ;;;   so draw gray rectangle over plot region prior to plot, so will be seen in "transparent" missing data region
        ;;;   only needed for "masked" plots but do for all so dont need to change if add another masked variable
        ;;; set polygon corner locations of data plot region (differs from viewport)
        getvalues contour_bparam
         "vpXF" : pltxo
         "vpYF" : pltyo
         "vpWidthF" : pltwidth
         "vpHeightF" : pltheight
        end getvalues
        ;4test: print(" pltxo,pltyo,pltwidth,pltheight= "+pltxo+","+pltyo+","+pltwidth+","+pltheight )
        ;4test: print(" mainvpx,mainvpy,mainvpwidth,mainvpheight="+mainvpx+","+mainvpy+","+mainvpwidth+","+mainvpheight )
        ;old ;;; kludge had been needed to get correct x start position for vertically-limited plots! - apparently plots somehow centered despite off-center viewport
        ;old ;;; but not for background-only version !   pltxo = pltxo + 0.5*(mainvpwidth-pltwidth)
        ;old ;;; but not for background-only version !   pltyo = pltyo - 0.5*(mainvpheight-pltheight)
        pltxmax = pltxo + pltwidth 
        pltymin = pltyo - pltheight
        cirx = (/ pltxo, pltxmax, pltxmax, pltxo /)
        ciry = (/ pltyo, pltyo, pltymin, pltymin /)
        ;;; must add gray color since not in color map
        gsres = True             ;  need to set some resources.
        grayindex = NhlNewColor(wks,0.8,0.8,0.8)
        ;old grayindex = NhlNewColor(wks,0.9,0.9,0.9)
        gsres@gsFillColor = grayindex
        ;4test:  print( "GrayIndex= "+grayindex )
        gsn_polygon_ndc(wks,cirx,ciry,gsres)  ; Draw a filled polygon.
          ;;; examples of failures attempting other methods of producing gray background
          ;noeffect opts_bparam@cnFillBackgroundColor = "red"
          ;noeffect opts_bparam@cnMissingValFillColor = "red"
        ;;; do not let this added color affect contour color plotting
        ;notvalid: opts_bparam@gsnSpreadColorEnd = grayindex-1
        NhlFreeColor(wks,grayindex)
        ;4test:  getvalues wks
        ;4test:      "wkColorMapLen" : len
        ;4test:   end getvalues
        ;4test:   print( "ColorMap len= "+len )
            
        ;;; ADD STIPPLE FOR CERTAIN COMPOUND PLOTS
        if ( lcompositetype .eq. 2 ) then
        ;old if ( plot_param .eq. "wstar_bsratio" .or. plot_param .eq. "wfpm_woustar" ) then
        ;old if ( plot_param .eq. "wstar_bsratio" ) then
          if ( min(cparam) .ne. max(cparam) ) then
            ;;; print composite parameter use info in header             
            opts_cparam@LevelLabel = composite_title 
            ;old-write_below_plot anno_pattern(wks,contour_cparam,composite_title)
            contour_cparam = wrf_new_fill_contour( wks, cparam(:,:), opts_cparam,  mainvpx,mainvpy,mainvpwidth,mainvpheight )
            ;pre-viewport_params            contour_cparam = wrf_new_fill_contour(wks,cparam(:,:),opts_cparam)
            wrf_mapoverlay(map,contour_cparam)
          end if
        end if

        ;;; CREATE DATAFILE if not datafile plot and not composite/mask plot
        ;;;   but add BLIP hglider parameter as special case
        qdatafile = plot_param + ".data"
        if ( ( ldatatype.eq.0 .or. (ldatatype.eq.2 .and. plot_param.eq."hglider") ) .and. LOUT .ge. 3 .and. qdatafile .ne. "" .and. string_pattern_grep(qdatafile,"_").eq.0 .and. string_pattern_grep(qdatafile,"mask").eq.0 ) then
        ;old if ( ldatatype .eq. 0 .and. LOUT .ge. 3 .and. qdatafile .ne. "" .and. string_pattern_grep(qdatafile,"_").eq.0 .and. string_pattern_grep(qdatafile,"mask").eq.0 ) then
          qdatatitle = string_target_replace_global( string_target_replace_global( opts_bparam@MainTitle+" "+opts_bparam@UnitLabel+" "+ENV_NCL_ID, "~I~", "" ), "~P~", "" )
          NCL_JACK_FORTRAN ::  output_mapdatafile( OUTDIR+"/"+qdatafile, qdatatitle,qgridinfo,qdatimeinfo+qparaminfo, bparam, isize,jsize, ldatafmt )
        end if

        delete(opts_bparam)
        delete(bparam)
        if ( isvar("opts_cparam") ) then 
          delete ( opts_cparam )
        end if
        if ( isvar("cparam") ) then 
          delete ( cparam )
        end if

        ;        Put on the map last, and then close the metacode frame.
        draw(map)

      else

;;; ==========================================================

   ;;; VECTOR WIND PLOT SECTION
        
        ;;; ruc/nam addition - ruc/nam-only/rasp-only if
        if( ldatatype.ne.0 ) then
        ;;;;;; ------ START OF DATAFILE-PLOT SECTION ------
           ;;; RUC/NAM PARAMETER DATA READ FROM FILE
           if ( plot_param .eq. "blwindkt_blwinddeg" .or.  plot_param .eq. "blwindspd_blwinddir" .or.  plot_param .eq. "sfcwindspd_sfcwinddir" .or.  plot_param .eq. "bltopwindspd_bltopwinddir" ) then
   ; now compute uplot,vplot from datafiles of ws,wd using projection info in datafile
             ;;; UNITS determines units displayed on plot - SHOULD be same as in datafile but not tested
             param_array = split_string_into_array( plot_param,"_" ) 
             ;;; note reversal here so that u contains direction and v contains speed
             u_filename = string_target_replace( ENV_NCL_FILENAME, "dummy", param_array(1) )
             v_filename = string_target_replace( ENV_NCL_FILENAME, "dummy", param_array(0) )
             uplot = new( (/blipdata_nny, blipdata_nnx/), float)
             vplot = new( (/blipdata_nny, blipdata_nnx/), float)
             ;  read ws,wd
             ;;; create new TimeLabel string from datafile header line 1
             delete( "ENV_NCL_ID" ) 
             ENV_NCL_ID = qblank_180 
             NCL_JACK_FORTRAN :: read_blip_datafile( u_filename, blipdata_nnx,blipdata_nny, uplot, qdummy ) 
             NCL_JACK_FORTRAN :: read_blip_datafile( v_filename, blipdata_nnx,blipdata_nny, vplot, ENV_NCL_ID ) 
             ENV_NCL_ID = trim_string( ENV_NCL_ID )
             ; convert ws,wd to uplot,vplot
             NCL_JACK_FORTRAN :: wdws2uv_4latlon( uplot,vplot, alat,alon, blipdata_nnx,blipdata_nny, qproj7,projlat1,projlon )
             ;old NCL_JACK_FORTRAN :: wdws2uv_4latlon( uplot,vplot, alat,alon, blipdata_nnx,blipdata_nny, projlat1,projlon )
             WindTitle = " ??? Wind"
             if ( plot_param .eq. "blwindspd_blwinddir" .or. plot_param .eq. "blwindkt_blwinddeg" ) then
                WindTitle = "BL Wind"
             end if                            
             if ( plot_param .eq. "sfcwindspd_sfcwinddir" .or. plot_param .eq. "sfcwindkt_sfcwinddeg" ) then
                WindTitle = "Surface Wind ~I~(10m AGL)~P~"
             end if                            
             if ( plot_param .eq. "bltopwindspd_bltopwinddir" .or. plot_param .eq. "bltopwindkt_bltopwinddeg" ) then
                WindTitle = "Wind at BL Top"
             end if                            
           end if
        ;;;;;; ------ END OF DATAFILE-PLOT SECTION ------
        else
        ;;;;;; ------ START OF WRFOUT-PLOT SECTION ------
          ;;; DO RASP WIND PARAMETER CALCULATIONS
          load "rasp.wind_calc.ncl" 

        ;;;;;; ------ END OF WRFOUT-PLOT SECTION ------
        end if
    
        ;;; add contours of wind speed
        windspeed = new( (/jsize, isize/), float)
        windspeed = sqrt( uplot^2 + vplot^2 )
        ;old windspeed = ( uplot^2 + vplot^2 )^0.5
        ;oldunits ;;; convert to pilot units (english)
        ;oldunits if( UNITS .ne. "metric" ) then
        ;oldunits   windspeed = 1.94385 * windspeed  ; in knots
        ;oldunits end if

        ;;; PRINT MIN,MAX
        print( times(it)+" "+iframe+"= PARAMETER "+PARAMS(iparam)+"  MIN,MAX= "+min(windspeed)+"  "+max(windspeed) )

        ;;;; Plotting options for streamlines
        opts_st = True
        opts_st@NoTitles = True
        ;unused opts_st@tiMainString = "GRD_6_ISBL"
        ;unused opts_st@tiXAxisString = "streamlines"
        ;unused opts_st@tiMainFont    = "Times-Roman"
        ;;; set line width
        opts_st@stLineThicknessF = 1.0
        ;;; set line color
        opts_st@stLineColor = "magenta"
        ;old opts_st@stLineColor = "blue"
        ;old opts_st@stLineColor = "navy blue"
        ;old  opts_st@stLineColor = "white"
        ;old opts_st@stLineColor = "red"
        ;;; for streamline using a color not in color map
        ; tintindex = NhlNewColor(wks,0.3,0.3,0.3)  ; gray
        ; opts_st@stLineColor = tintindex 
        ;;; set line spacing 
        ;;; use stMinDistanceFinstead of stlinestartstride to prevent too-dense spacing for grids with very large number of grid points
        opts_st@stMinDistanceF = 0.05 ; to prevent too-dense spacing for grids with very large number of grid points
        ;old ;;; decided dynamic worked better - these often too close together: opts_st@stMinLineSpacingF = 0.004  ; dynamic default => secondGREATBRITAIN-WINDOW-d2=0.0012 SW_SOUTHAFRICA=0.0025 (doesnt change stStepSizeF value)
        ;paulscorer_suggestion: opts_st@stMinLineSpacingF = 0.005 
        ;old opts_st@stlinestartstride = 4      ; default=2  larger number tends to give lines in bunches
        ;unused ;;; set step size ?? seems all or nothing and not too useful (it is supposed to be dynamically adjusted - manual setting has no effect !?)
        ;;unused       opts_st@stStepSizeF = 40.0
        ;;; set arrow params
        opts_st@stArrowStride = 4          ; default=2
        opts_st@stArrowLengthF = 0.0125
        opts_st@stMinArrowSpacingF = 0.05 
        ;for_test_view_sans_arrows:   opts_st@stArrowStride = 20 
        ;first opts_st@stArrowLengthF = 0.0075

        ;onceonly_background: cannot alter terrain options for individual plot
        ;onceonly_background- ;;;; Alter Terrain Plotting options when plotting streamlines
        ;onceonly_background- ;;; use thin terrain lines for streamline case
        ;onceonly_background- ;;; MUST RESET BELOW TO "NORMAL" VALUE !
        ;onceonly_background- opts_ter@cnMonoLineThickness = True
        ;onceonly_background- opts_ter@cnLineThicknessF = 0.5

        ;        Plotting options for windspeed
        opts_ws = True
        opts_ws@MainTitle = WindTitle
        ;old opts_ws@MainTitle = "BL Avg. Wind"
        ;single_time_file:
        opts_ws@TimeLabel = times(it)+"Z"
        ;multiple_time_file: opts_ws@TimeLabel = times(it) + " = " + time_save + " + " + hours + " h"
        ;;; IF NON-INTERACTIVE RUN, USE ID AS TITLE
        if ( .not. ismissing(ENV_NCL_ID) .and. ENV_NCL_ID .ne. "" ) then
          opts_ws@TimeLabel = trim_string( ENV_NCL_ID )
        end if
        ;;; convert to pilot units (english)
        if( UNITS .ne. "metric" ) then
          opts_ws@UnitLabel = "[kt]"
        else
          opts_ws@UnitLabel = "[m/s]"
        end if
        ;overwrites_long_time_label
        opts_ws@LevelLabel = titleline3
        opts_ws@LineThickness = 0.5
        opts_ws@cnInfoLabelOn = False
        opts_ws@cnLineLabelsOn = False

        ;;; FOR LABEL BAR (COLORBAR)
        opts_ws@lbAutoManage = False
        ;old-unneeded opts_ws@lbLabelStrings = (/ 0., 200., 400., 600., 800. /)
        opts_ws@lbLabelFont = "helvetica"
        ;800x800:        
        opts_ws@lbLabelFontHeightF = .015
        ;512x512: opts_ws@lbLabelFontHeightF = .02
        opts_ws@lbLabelOffsetF     = 0.05  ; move numbers close to colorbar
        opts_ws@lbTitleFont = "helvetica"
        ;preAug2006(smaller_plotheight) ;800x800: opts_ws@lbTitleFontHeightF = .015
        ;preAug2006(smaller_plotheight) ;512x512: opts_ws@lbTitleFontHeightF = .02
        ;preAug2006(smaller_plotheight) opts_ws@lbBottomMarginF = 0.4
        ;preAug2006(smaller_plotheight) opts_ws@lbTitleOffsetF     = -0.5  ; move colorbar and its title closer together
        ;preAug2006(smaller_plotheight) opts_ws@lbTopMarginF     = -0.3  ; move colorbar and its title upward, closer to plot
        ;;; LABELBAR OPTIONS TO ALLOW LARGER VERTICAL PLOT - put units & fixed flag to side of colorbar
        ;;; specify label bar height,width to conform to my esthetics
        opts_ws@pmLabelBarHeightF  = 0.08 ; 
        opts_ws@pmLabelBarWidthF  = 0.80 ; 
        ;old opts_ws@pmLabelBarWidthF  = 0.78 ; 
        ;;; eliminate label title (units string)
        opts_ws@lbTitleOn = False
        ;;; move label bar as close to plot as possible (without making orthogonal position negative)
        opts_ws@lbTitleExtentF     = 0.0 ; no effect of changing from 0.6
        opts_ws@lbBottomMarginF     = 0.0 ; no apparnet effect
        opts_ws@lbTopMarginF     = 0.0 ; no apparnet effect
        opts_ws@pmLabelBarOrthogonalPosF  = 0.0 ; moves slightly upward
        ;unused  opts_ws@lbJustification = "TopCenter" set in subroutine so not set here
        ;4test-display_lb_perim: opts_ws@lbPerimOn = True ; opts_ws@lbPerimColor = 1
        ;;; UGLY RUC/NAM COMPOSITE KLUDGE FORCES CONGRUENCE WITH NON-COMPOSITE BLIPMAP
        if( ldatatype .eq. 2 ) then
           opts_ws@pmLabelBarOrthogonalPosF  = -0.02 ; move upward
        end if
     
        ;;; SET FIXED COLORS FOR WINDS
        ;;; set color contouring option
        if( LFIXEDCOLOR .eq. 1 ) then
          opts_ws@ContourParameters = (/ 0., 44., 2. /)
          print( "    using FIXED COLOR for WIND windspeed" )
        else
          opts_ws@ContourParameters = (/ 0.,0., 2. /)
          ;old opts_ws@ContourParameters = (/ 0.,0., 5. /)
        end if 

        ;old-vector ;        Plotting options for the overlayed wind vectors.
        ;old-vector opts_vct = True
        ;old-vector ;;; convert to pilot units (english)
        ;old-vector if( UNITS .ne. "metric" ) then
        ;old-vector opts_vct@MainTitle = "BLavg WIND ~I~[kt]~P~"
        ;old-vector  else
        ;old-vector opts_vct@MainTitle = "BLavg WIND ~I~[m/s]~P~"
        ;old-vector  end if
        ;old-vector ;single_time_file:
        ;old-vector opts_vct@TimeLabel = times(it)+"Z"
        ;old-vector ;multiple_time_file: opts_vct@TimeLabel = times(it) + " = " + time_save + " + " + hours + " h"
        ;old-vector ;old opts_vct@NoTitles = True
        ;old-vector opts_vct@NumVectors = 47
        ;old-vector opts_vct@WindBarbsOn = True
        ;old-vector ;original opts_vct@vcWindBarbColor = "black"
        ;old-vector opts_vct@vcWindBarbColor = "navy blue"
        ;old-vector opts_vct@vcRefAnnoOn = False

        ;;; plot wind vectors
        ;old-vector vector = wrf_new_vector(wks,uplot, vplot, opts_vct)
        ;old-vector wrf_mapoverlay(map,vector)
        ;old-vector delete(opts_vct)
        ;old-vector delete(opts_vct)

        ;onceonly_background: ;;; create "blank" geographic map for plotting parameter data
        opts_blankmap = True
        opts_blankmap@mpOutlineOn = False
        opts_blankmap@mpGridAndLimbOn = False
        opts_blankmap@vpUseSegments = True
        ;latlongrid
        if( qproj7 .eq. "latlong" ) then
          opts_blankmap@mpProjection = "CylindricalEquidistant"
        end if

        ;;; FOR SITE SUBSTITUTIONS  (jack: if alter filename also change BLIP/PLOT/filename)
        load "rasp.site_load.wind.ncl"  

        ;;;  allow command line argument override of contouring 
        if( isvar("CONTOURS") ) then
           opts_ws@ContourParameters = CONTOURS
            print( "USING COMMAND-LINE CONTOURS = "+CONTOURS )
        end if
        
        ;onceonly_background: ;;; setup map plot
        ;; ruc/nam addition - ruc/nam-only/rasp-only if
        if( ldatatype.ne.0 ) then
        ;;;;;; ------ START OF DATAFILE-PLOT SECTION ------
          lat_filename = string_target_replace( ENV_NCL_INFOFILENAME, "dummy", "latitude" )
          lon_filename = string_target_replace( ENV_NCL_INFOFILENAME, "dummy", "longitude" )
          ;old lat_filename = ENV_NCL_INFOFILENAME+"/latitude."+ENV_NCL_REGIONNAME+".data"
          ;old lon_filename = ENV_NCL_INFOFILENAME+"/longitude."+ENV_NCL_REGIONNAME+".data"

          map = blip_new_map(wks, alat,alon,isize,jsize,projlat1,projlat2,projlon, opts_blankmap, mapvpx,mapvpy,mapvpwidth,mapvpheight )
          ;old map = blip_new_map(wks, terrain_filename,lat_filename,lon_filename, opts_blankmap, mapvpx,mapvpy,mapvpwidth,mapvpheight )
        ;;;;;; ------ END OF DATAFILE-PLOT SECTION ------
        else
        ;;;;;; ------ START OF WRFOUT-PLOT SECTION ------
          map = wrf_new_map( wks, a, opts_blankmap, mapvpx,mapvpy,mapvpwidth,mapvpheight )
        ;;;;;; ------ END OF WRFOUT-PLOT SECTION ------
        end if

        ;;; plot wind streamlines  (using my streamline function added to wrf_plot.ncl)
        streamline = wrf_new_streamline( wks,uplot, vplot, opts_st,  mainvpx,mainvpy,mainvpwidth,mainvpheight )
        ;pre-viewport_params        streamline = wrf_new_streamline(wks,uplot, vplot, opts_st)
        wrf_mapoverlay(map,streamline)

        ;;; plot windspeed contours
        ;old-vector contour_windspeed    = wrf_new_line_contour(wks,windspeed,opts_ws)
        contour_windspeed = wrf_new_fill_contour( wks,windspeed,opts_ws, mainvpx,mainvpy,mainvpwidth,mainvpheight )
        ;pre-viewport_params        contour_windspeed = wrf_new_fill_contour(wks,windspeed,opts_ws)
        wrf_mapoverlay(map,contour_windspeed)

        ;;; ADD LABEL BAR UNITS (and FIXED flag) to side of label bar (assumes units not ploted by label bar itself)
        if( isatt(opts_ws,"ContourParameters") .and. opts_ws@ContourParameters(0) .ne. opts_ws@ContourParameters(1) ) then
          kfixedcolor = 1
        end if 
        add_labelbar_text( wks, contour_windspeed, opts_ws@UnitLabel, kfixedcolor )
        ;old add_labelbar_text( wks, contour_windspeed, opts_ws@UnitLabel, LFIXEDCOLOR )
        ;4test: add_labelbar_text( wks, contour_windspeed, opts_ws@UnitLabel, 1 )

        ;;; CREATE WIND SPEED AND DIRECTION DATAFILES if not datafile plot and not composite plot
        if (  ldatatype .eq. 0 .and. LOUT .ge. 3 .and. plot_param .ne. "" .and. string_pattern_grep(plot_param,"_").eq.0 ) then
          ;;; will be called only for rasp input file case so can use its attributes in call
          NCL_JACK_FORTRAN :: uv2wdws_4latlon( uplot,vplot, alat,alon, isize,jsize, a@TRUELAT1,a@STAND_LON )
          ;alt NCL_JACK_FORTRAN :: uv2wdws_4latlon( uplot,vplot, alat,alon, isize,jsize, projlat1,projlon )
          ;;; OUTPUT WIND SPEED DATA
          qdatafile = plot_param+ "spd.data"
          ;;; convert to pilot units (english)
          if( UNITS .ne. "metric" ) then
            qparaminfo = "Param= "+plot_param+"spd Unit= kt Mult= 1"
          else
            qparaminfo = "Param= "+plot_param+"spd Unit= m/s Mult= 1"
          end if
          qdatatitle = string_target_replace_global( string_target_replace_global( opts_ws@MainTitle+" Speed "+opts_ws@UnitLabel+" "+ENV_NCL_ID, "~I~", "" ), "~P~", "" )
          NCL_JACK_FORTRAN ::  output_mapdatafile( OUTDIR+"/"+qdatafile, qdatatitle,qgridinfo,qdatimeinfo+qparaminfo, windspeed, isize,jsize, 0 )
          ;;; OUTPUT WIND DIRECTION DATA
          qdatafile = plot_param+ "dir.data"
          qparaminfo = "Param= "+plot_param+"dir Unit= deg Mult= 1"
          ; strip ncarg format strings from title
          qdatatitle = string_target_replace_global( string_target_replace_global( opts_ws@MainTitle+" Direction [deg]"+" "+ENV_NCL_ID, "~I~", "" ), "~P~", "" )
          NCL_JACK_FORTRAN ::  output_mapdatafile( OUTDIR+"/"+qdatafile, qdatatitle,qgridinfo,qdatimeinfo+qparaminfo, uplot, isize,jsize, 0 )
        end if

        ;onceonly_background: cannot alter terrain options for individual plot
        ;onceonly_background- ;;;; Alter Terrain Plotting options when plotting streamlines
        ;onceonly_background- ;;; RESET ALTERED VALUES TO "NORMAL" VALUE !
        ;onceonly_background- opts_ter@cnMonoLineThickness = False

        delete ( uplot )
        delete ( vplot )
        delete(opts_st)
        delete(opts_ws)
        delete(streamline)
        delete(windspeed)

        ;        Put on the map last, and then close the metacode frame.
        draw(map)

        ;;; for streamline using a color not in color map -  must put after draw !? - might this color affect contour color plotting ?
        ; NhlFreeColor(wks,tintindex)

      ; end of scalar/wind section if
      end if

      ;onceonly_background:  ;;; overplot with terrain map
      NhlChangeWorkstation( back_ter_map, wks )
      draw(back_ter_map)
      ;;; must change workstation back to avoid being deleted when new workstation created
      NhlChangeWorkstation( back_ter_map, terwks )
                
      ;;; FINALLY, DRAW FRAME
      frame(wks)

      ;onceonly_background: cannot alter terrain options for individual plot
      ;onceonly_background- ; blank any opts_ter title set above
      ;onceonly_background- opts_ter@MainTitle = ""
      ;original NhlRemoveOverlay(map,contour_bparam,False)

      ;;; print current wall clock & elapsed time
      PrintWallClockElapseTime(wcStrt,"Single Parameter Plot end -")

      continue 
   end if ;  end of scalar/wind plot sections

;;; =======================================================================

 ; jack - END OF LOOP OVER ALL PARAMS
 end do

;;; =======================================================================

;jack-1timeonly- end do         ;        end of the time loop

   ;;; end of loop cleanup
   if ( isvar("ter") ) then 
      delete ( ter )
   end if
   if ( isvar("terft") ) then 
      delete ( terft )
   end if
   if ( isvar("z") ) then 
      delete ( z )
   end if
   if ( isvar("w") ) then 
      delete ( w )
   end if
   if ( isvar("pmb") ) then 
      delete ( pmb )
   end if
   if ( isvar("pb") ) then 
      delete ( pb )
   end if
   if ( isvar("ppert") ) then 
      delete ( ppert )
   end if
   if ( isvar("psfc") ) then 
      delete ( psfc )
   end if
   if ( isvar("ua") ) then 
      delete ( ua )
   end if
   if ( isvar("va") ) then 
      delete ( va )
   end if
   if ( isvar("uv") ) then 
      delete ( uv )
   end if
   if ( isvar("w") ) then 
      delete ( w )
   end if
   if ( isvar("wa") ) then 
      delete ( wa )
   end if
   if ( isvar("bparam") ) then 
      delete ( bparam )
   end if
   if ( isvar("pblh") ) then 
      delete ( pblh )
   end if
   if ( isvar("hfx") ) then 
      delete ( hfx )
   end if
   if ( isvar("vhf") ) then 
      delete ( vhf )
   end if
   if ( isvar("qcloud") ) then 
      delete ( qcloud )
   end if
   if ( isvar("cldfra") ) then 
      delete ( cldfra )
   end if
   if ( isvar("qvapor") ) then 
      delete ( qvapor )
   end if
   if ( isvar("rh") ) then 
      delete ( rh )
   end if
   if ( isvar("tc") ) then 
      delete ( tc )
   end if
   if ( isvar("td") ) then 
      delete ( td )
   end if
   if ( isvar("thetac") ) then 
      delete ( thetac )
   end if
   if ( isvar("w4plot") ) then 
      delete ( w4plot )
   end if
   if ( isvar("wstar") ) then 
      delete ( wstar )
   end if
   if ( isvar("blavgwindspeed") ) then 
      delete ( blavgwindspeed )
   end if
   if ( isvar("blavgwindspeed") ) then 
      delete ( blavgwindspeed )
   end if
   if ( isvar("qvaporblavg") ) then 
      delete ( qvaporblavg )
   end if

;;; END OF BLANK FILENAME IF TO EXIT
else
  print( "PLOTTING ENDED BY BLANK FILENAME" )
end if 

  ;;; NB: ABSENCE OF "NORMAL END" IN RASP PRINTOUT TRIGGERS RASP ERROR MESSAGE
  print( "=== NORMAL END OF NCL PLOTTING SCRIPT" )
end do ;  end of file loop

;;; final cleanup
;notnecessary delete(wks)
