;************************************
; multiplot.ncl
;************************************

;;; assumes same x axis for multiple variables

;;; normally called by passing in data via arguments ala (note that quoting combos are necessary!)
;;;   $NCARG_ROOT/bin/ncl rasptrackavg.multiplot.ncl 'wks="ncgm"' 'data_filename="/tmp/rasptrackavg.out"' 'plot_filename="/tmp/rasptrackavg.multiplot.ncgm"'`;
;;; to plot to X11, use null wks and  plot_filename

;;; $NCARG_ROOT must be in the calling environment

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;unneeded load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;unneeded load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

   ;4testprint:  print ( "wks="+wks+"=" )
   ;4testprint:  print ( "data_filename="+data_filename+"=" )
   ;4testprint:  print ( "plot_filename="+plot_filename+"=" )

  ;;; set default output workstation type (x11,ncgm)
  if( .not. isdefined( "wks" ) ) then
    if( getenv("DISPLAY") .ne. "" ) then
      wks = "x11"
    else
      wks = "ncgm"
    end if
    ;4test: print( "internally set wks = "+wks )
  end if

  ;;; set default data file if not input (primarily for tests) 
  BASEDIR = "/home/admin/DRJACK"
  default_data_filename = BASEDIR + "/RASP/ANAL/TRACK/calc.rasptrackavg.out"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;  SET PLOT-SPECIFIC PARAMETERS  ;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;; (MIGHT BE INPUT VIA ARGUMENT) ;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;; Set the top title plot
    top_title = ""
    ;old top_title = "Along-Track Variation"

  ;;; SET X VARIABLE INFORMATION
  ;;; set data column of X variable (counting from 0)
    xcolno = 4
  ;;; set conversion of data x to plot x - "input" or "avg" (to conform to location of y variable)
    xtype = "avg"
  ;;; set factor to multiply X variable 
    ;x=km
    xmult = 0.001 ; m->km
    ;x=nm    xmult = 0.000539957 ; m->nm
  ;;; set plot Xmin,max (automatic if -999.)
    xmin = 0.
    xmax = -999.
  ;;; set data column of turnpoint info  (counting from 0)
    xmarkerlinecolno = 1
  ;;; set column value indicating this is a turnpoint x (set to -999. to disable)
    xmarkerlinevalue = 0 

  ;;; SET Y VARIABLE INFORMATION
  ;;; set Y variable name (also sets parameter nvars) 
    var_name   = (/ "Thermal Climb Rate (m/s)","Tail Wind (kt)","Thermalling Percent","Opt. GroundSpeed (kt)" /)
    nvars       = dimsizes(var_name)
    ;4test  var_name   = (/ "Var1","Var2","Var3" /)
  ;;; set data column of each Y variable  (counting from 0)
    var_colno        = (/ 7, 9, 11, 10 /)
  ;;; set factor to multiply each Y variable 
    var_mult        = (/ 1.0, 1.943849, 1.0, 1.943849 /)  ; m/s->kt
    ;unused var_units   = (/ "units1","units2","units3","units4","units5" /)
  ;;; set plot Ymin,max (automatic if -999.)
    var_ymin        = (/    0.,-999.,  0.,   0. /)
    var_ymax        = (/ -999.,-999.,100.,-999. /)

  ;;; Set up plotting labels and line attributes.
    linecolor = "maroon" 
    linethickness = 2
    linedash   = 0 ;
    ;x=km
    xaxistitle = "Distance (km)"
    ;x=nm xaxistitle = "Distance (nm)"
    xmarkerlinecolor = "red"

  ;;; Set up plot attributes.
    plotwidth = 0.6
    ;full-width: plotwidth = 0.98

  ;;; Input file that containing values to be plotted IF not provided via argument.
  if( .not. isdefined( "data_filename" ) ) then
    data_filename = default_data_filename
  end if
  ;;; number of columns of data
    incols = 13
  ;;; number of rows to skip before reading data
    inskip = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;  BELOW SHOULD NOT BE PLOT-SPECIFIC  ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Read in Data

  ;;; Read Data File
  data = readAsciiTable(data_filename,incols,"float",inskip)
  datadims = dimsizes(data)
  inpts = datadims(0)
  ;4test: print ( "input pts="+inpts )

  ;;; Set X Values 
  ;;; set x to _input_ or _avg_ to agree with location of y variables 
  if( xtype .eq. "input" ) then
    npts = inpts 
    xarray = new(npts,float)
    xarray = xmult * data(:,xcolno) 
  end if
  if( xtype .eq. "avg" ) then
    npts = inpts -1
    xarray = new(npts,float)
    do i=0,(npts-1)
      xarray(i) = 0.5 * xmult * ( data(i,xcolno) + data(i+1,xcolno) )
    end do
  end if
  ;;; Set X Marker Line values
  xmarkerline = new(inpts,float)
  nxmarkerline = 0
  if( xmarkerlinevalue .ne. -999. ) then
    do i=0,(inpts-1)
      ;;; also create array of turnpoint locations
      if( data(i,xmarkerlinecolno) .eq. xmarkerlinevalue ) then
        xmarkerline(nxmarkerline) = xmult * data(i,xcolno)
        nxmarkerline = nxmarkerline + 1
      end if
    end do 
  end if
  ;;; Set Y array
  yarray = new(npts,float)
  ;4test:  xarray = (/ 1.,2.,3.,4.,5.,6 /)
  ;4test:  yarray = (/ 1.,2.,3.,4.,5.,6 /)
  ;4testprint: print ( "xmarkerline count ="+nxmarkerline )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;; Set up workstation and change color map.
  ;;; set output file name when specified
  if( wks .eq. "ncgm" .and. isdefined( "plot_filename" ) ) then
  ; Create an NCGM workstation.
   ;4testprint:  print ( "Opening ncgm file for plot output = "+plot_filename )
    wksid = create "multiplot" ncgmWorkstationClass defaultapp
            "wkMetaName": plot_filename
            end create     
  else
    ;4testprint:  print ( "Opening workstation "+wks )
    wksid = gsn_open_wks(wks,"multplot")
  end if
  gsn_define_colormap(wksid,"amwg")
  ;;; for white background, black foreground
  setvalues wksid            
    "wkColorMap"        : "amwg"  
    "wkBackgroundColor" : (/1.,1.,1./) 
    "wkForegroundColor" : (/0.,0.,0./)  
  end setvalues

  ;;; Create arrays to hold plots - THESE *MUST* BE AVAILABLE WHEN FINAL PLOT DONE !
  plotarray = new(nvars,graphic)
  ;;; need array to hold markerline line plots
  dumplot = new( (/nxmarkerline,nvars/), graphic )
  ;;; ADD HORIZ ZERO REFERENCE LINE
  ;;; need array to hold zero reference line plots
  reflineplot = new( (/nvars/), graphic )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; FOLLOWING RESOURCES *NOT* CHANGED FOR EACH VARIABLE

  xyres                        = True
  xyres@gsnDraw                = False
  xyres@gsnFrame               = False
  
  ;;; Set Plot Height/Width
  panelvpbottom = 0.06
  panelvptop = 0.97
  xyres@vpHeightF              = ( panelvptop - panelvpbottom ) / nvars
  xyres@vpWidthF               = plotwidth 

  ;;; set x plot limits 
  if ( xmin .ne. -999.) then
    ;for specified Xmin:
    xyres@trXMinF = xmin
  end if
  if ( xmax .ne. -999. ) then
    ;for specified Xmax:
    xyres@trXMaxF = xmax
  end if
  xyres@xyMonoDashPattern      = False
  xyres@xyMonoLineColor        = False
  xyres@xyLineColors           = linecolor
  xyres@xyLineThicknessF       = linethickness
  xyres@xyDashPatterns         = linedash

  ;bad? xyres@txFontHeightF          = .015
  ;bad? xyres@xyCurveDrawOrder       = "PreDraw"
  xyres@tfPolyDrawOrder        = "Draw"

  xyres@tmXBLabelsOn           = False
  xyres@tmYRLabelsOn           = True
  xyres@tmYLLabelsOn           = False

;;;JACK
    xyres@tiXAxisString = xaxistitle
    ;;; display variable name on left
    xyres@tiYAxisOn = True
    ;gives_strange_results:  ;;; set bottom label to integer ;  xyres@tmXBPrecision = 1
    xyres@tiXAxisOn = False      
    xyres@tiXAxisFontHeightF = 0.015
    xyres@tmXBLabelFontHeightF = 0.015
    xyres@tiYAxisFontHeightF = 0.015
    ; for some reason YL controls size of numbers on _right_ axis !?
    xyres@tmYLLabelFontHeightF = 0.015
    xyres@tiMainFont = "helvetica"
    xyres@tiXAxisFont = "helvetica"
    xyres@tiYAxisFont = "helvetica"
    xyres@tmXTLabelFont = "helvetica"
    xyres@tmXBLabelFont = "helvetica"
    xyres@tmYLLabelFont = "helvetica"
    xyres@tmYRLabelFont = "helvetica"

    ;;; try to add a zero reference line using gsn resource
    ;nowork    xyres@gsnYRefLine = 0.0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; START OF LOOP OVER VARIABLES.
  do ivar = 0,nvars-1  

    ;;; set data for this plot
    do i=0,(npts-1)
      yarray(i) = var_mult(ivar) * data(i,var_colno(ivar))
      ;4testprint: print ( ivar+" Y "+i+" = "+yarray(i) )
    end do 

    ;;; Set up resources for current plot
    if (ivar .eq. nvars-1) then
      xyres@tmXBLabelsOn = True      ; Turn on labels for bottom plot.
      xyres@tiXAxisOn = True      ; Turn on labels for bottom plot.
    end if
    ;;; set y plot limits   
    if ( var_ymin(ivar) .ne. -999.) then
     ;for specified Ymin:
      xyres@xyComputeYMin = False
      xyres@trYMinF = var_ymin(ivar)
    else
      ;for automatic Ymin:
      xyres@xyComputeYMin = True
      if( isatt(xyres,"trYMinF") ) then
         delete(xyres@trYMinF)
      end if
    end if
    if ( var_ymax(ivar) .ne. -999.) then
      ;for specified Ymx:
      xyres@xyComputeYMax = False
      xyres@trYMaxF = var_ymax(ivar)
    else
      ;for automatic Ymax:
      xyres@xyComputeYMax = True
      if( isatt(xyres,"trYMaxF") ) then
        delete(xyres@trYMaxF)
      end if
    end if
    xyres@tiYAxisString = var_name(ivar)

   ;;; Do XY plot
    xyplot = gsn_xy( wksid, xarray,yarray, xyres )
    ;bad=0_line_addi    xyplot = gsn_csm_xy( wksid, xarray,yarray, xyres )

    ;;; Add Xmarkerline Vertical Lines
    xmarkerlineres = True
    xmarkerlineres@gsLineColor = xmarkerlinecolor
    do ixmarkerline=0,(nxmarkerline-1)
      getvalues xyplot
        "trYMinF" : ymin
        "trYMaxF" : ymax
      end getvalues
      dumplot(ixmarkerline,ivar) = gsn_add_polyline( wksid, xyplot, (/xmarkerline(ixmarkerline),xmarkerline(ixmarkerline)/), (/ymin,ymax/), xmarkerlineres )
      ;4test: print ( "Xmarkerline "+ixmarkerline+" @ X="+xmarkerline(ixmarkerline)+" Y="+ymin+","+ymax )
    end do
    delete ( xmarkerlineres )

    ;;; ADD HORIZ ZERO REFERENCE LINE
    reflineres = True
    reflineres@gsLineColor = "black"
    getvalues xyplot
      "trXMinF" : xmin
      "trXMaxF" : xmax
    end getvalues
    reflineplot(ivar) = gsn_add_polyline( wksid, xyplot, (/xmin,xmax/), (/0.0,0.0/), reflineres )
    delete ( reflineres )

    ;;; overlay and add to panel plot array
    plotarray(ivar) = xyplot
    ;original plotarray(ivar) = gsn_xy( wksid, xarray,yarray, xyres )

;;; End of Loop over variables.
  end do       ; Loop over variables.
  delete ( xyres )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Do panel plot after setting resources
  pres                              = True
  pres@gsnFrame                     = False
  pres@gsnPanelBottom               = panelvpbottom
  pres@gsnPanelTop                  = panelvptop
  ;unused pres@gsnPanelFigureStrings        = (/"a","b","c","d","e","f","g","h","i","j"/)
  pres@gsnPanelFigureStringsPerimOn = False
  gsn_panel(wksid, plotarray, (/nvars,1/), pres)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Add label at top of plot.
  if( top_title .ne. "" ) then
    txres               = True
    txres@txJust = "CenterLeft"
    txres@txFontHeightF = 0.015
    txres@txFont = "helvetica"
    gsn_text_ndc(wksid,top_title,0.10,0.98,txres)
  end if

;;; Finally do actual plotting
  frame(wksid)

end  
