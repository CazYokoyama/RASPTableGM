;============================================================================================================
;;; JACK CHANGES
;;; changed color map
;;; added streamline plotting function
;;; hard-wired fonts to helvetica (since can't change using txFont,tiMainFont,etc)
;jack - change height,location of title text in _SetMainTitle

;jack - dont constrain ratio
;jack-fix_bad_colorbar_max:nicer_colorbar_labels-but-smaller_tint_range+
;jack - make specified contours (from zero contour) thicker

;============================================================================================================

undef("wrf_open_ncgm")
undef("wrf_open_X11")
undef("wrf_open_PS")
undef("wrf_new_fill_contour")
undef("wrf_new_line_contour")
undef("wrf_new_vector_contour")
undef("wrf_update_contour_data")
undef("wrf_update_vector_data")
undef("wrf_new_map")
undef("wrf_mapoverlay")
undef("wrf_maplabel")
undef("_GetAnnoInfo")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function wrf_open_ncgm(filename[1]:string)
begin
         tmp = create filename ncgmWorkstationClass defaultapp
                  "wkMetaName" : filename + ".ncgm"
         "wkBackgroundColor" : "white"
         "wkForegroundColor" : "black"
;original               "wkColorMap" : "WhViBlGrYeOrReWh"
;               "wkColorMap" : "temp1"
;               "wkColorMap" : "default"
;first          "wkColorMap" : "BlAqGrYeOrRe" ; no dark violet/blue
;ok
                "wkColorMap" : "BlAqGrYeOrReVi200" ; probably best though somewhat dark and max is dark violet for press level plot
        end create
        return(tmp)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function wrf_open_X11()
begin
        tmp = create "X11Workstation" xWorkstationClass defaultapp
;original               "wkColorMap" : "WhViBlGrYeOrReWh"
;jack - no dark violet/blue
;first          "wkColorMap" : "BlAqGrYeOrRe" ; no dark violet/blue but  blue at max for press level plot
;ok
                "wkColorMap" : "BlAqGrYeOrReVi200" ; probably best though somewhat dark and max is dark violet for press level plot
;ok             "wkColorMap" : "rainbow+white" ; blue very dark but range ok even for press level plot
;bad            "wkColorMap" : "nrl_sirkeys" ; wierd
;bad            "wkColorMap" : "gui_default" ; crashed
;bad            "wkColorMap" : "WhViBlGrYeOrReWh" ; blue much too dark but range ok even for press level plot
;bad            "wkColorMap" : "rainbow" ; blue very dark and blue at top for press level plot
;bad            "wkColorMap" : "ncview_default" ;bad - blue at max for press level plot
;bad            "wkColorMap" : "BkBlAqGrYeOrReViWh200" ; blue too dark, too much violet at max end for press level plot
;               "wkColorMap" : "temp1"
;               "wkColorMap" : "default"
         "wkBackgroundColor" : "white"
         "wkForegroundColor" : "black"
        end create
        return(tmp)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function wrf_open_PS(filename[1]:string)
begin
        tmp = create filename psWorkstationClass defaultapp
;               "wkColorMap" : "temp1"
;original               "wkColorMap" : "WhViBlGrYeOrReWh"
;first          "wkColorMap" : "BlAqGrYeOrRe" ; no dark violet/blue
;ok
                "wkColorMap" : "BlAqGrYeOrReVi200" ; probably best though somewhat dark and max is dark violet for press level plot
                "wkPSFileName" : filename + ".ps"
;;;JACK - USE SQUARE BOUNDING BOX TO MATCH VIEWPORT
;;; normal ps plot has margin on each side ala plot form ncgm metafile
;pagetop
"wkDeviceLowerX" : 0
;pagetop 
 "wkDeviceLowerY" : 180
;pagetop 
 "wkDeviceUpperX" : 612
;pagetop 
 "wkDeviceUpperY" : 792
;pagebottom  "wkDeviceLowerX" : 0
;pagebottom  "wkDeviceLowerY" : 0
;pagebottom  "wkDeviceUpperX" : 612
;pagebottom  "wkDeviceUpperY" : 612
;;; USE EPS FORMAT
;;; removes margins so title scrunched at top with extra white space at bottom with both "pagetop" & "pagebottom" params 
; "wkPSFormat" : "eps" 
;;; removes margins so  title scrunched at top with extra white space at bottom with both "pagetop" & "pagebottom" params 
;  "wkPSFormat" : "epsi" 
        end create
        return(tmp)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure _ReSetMainTitle(wks[1]:graphic,cn[1]:graphic,data,opts)
        
begin
        if(isatt(opts,"NoTitles"))
                delete(opts@NoTitles)
        else
                if((.not.opts).or.(.not.isatt(opts,"MainTitle")))

                        if(isatt(data,"description"))
                                var_title = data@description
                        else
                                if(isatt(data,"DESCRIPTION"))
                                        var_title = data@DESCRIPTION
                                else
                                        var_title= "No description provided"
                                end if
                        end if
                else
                        var_title = opts@MainTitle
                        delete(opts@MainTitle)
                end if  
                if((.not.opts).or.(.not.isatt(opts,"TimeLabel")))
                        if(isatt(data,"time"))
                                time_title = "Time: " + data@time
                        else
                                time_title = "No time provided"
                        end if
                else
                        time_title = opts@TimeLabel
                        delete(opts@TimeLabel)
                end if
                if((.not.opts).or.(.not.isatt(opts,"LevelLabel")))
                        if(isatt(data,"level"))
                ; lev_title = "Level: " + data@level
                lev_title = "Level: " + data@level
                        else
                ; lev_title = "No level provided"
                lev_title = ""
                        end if
                else 
                        lev_title = opts@LevelLabel
                        delete(opts@LevelLabel)
                end if
        
                getvalues cn
                        "pmAnnoViews" : vws
                end getvalues
                if(.not.all(ismissing(vws)))
                
                        if(isatt(opts,"NoTitles"))
                                delete(opts@NoTitles)
                        else
                                setvalues vws(0)
                                        "txString" : var_title
                                end setvalues
                                setvalues vws(1)        
                                        "txString" : lev_title
                                end setvalues
                                        setvalues vws(2)
                                        "txString" : time_title 
                                end setvalues
                        end if
                end if
        end if
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure _SetMainTitle(wks[1]:graphic,cn[1]:graphic,data,opts)
begin
        if((.not.opts).or.(.not.isatt(opts,"MainTitle")))

                if(isatt(data,"description"))
                        var_title = data@description
                else
                        if(isatt(data,"DESCRIPTION"))
                                var_title = data@DESCRIPTION
                        else
                                var_title= "No description provided"
                        end if
                end if
        else
                var_title = opts@MainTitle
                delete(opts@MainTitle)
        end if  
        if((.not.opts).or.(.not.isatt(opts,"TimeLabel")))
                if(isatt(data,"time"))
                        time_title = "Time: " + data@time
                else
                        time_title = "No time provided"
                end if
        else
                time_title = opts@TimeLabel
                delete(opts@TimeLabel)
        end if
        if((.not.opts).or.(.not.isatt(opts,"LevelLabel")))
                if(isatt(data,"level"))
                ; lev_title = "Level: " + data@level
               lev_title = data@level
                else
                        ; lev_title = "No level provided"
                        lev_title = ""
                end if
        else 
                lev_title = opts@LevelLabel
                delete(opts@LevelLabel)
        end if

        if(isatt(opts,"NoTitles"))
                delete(opts@NoTitles)
        else
;JACK-FONT - BELOW AFFECTS MODEL MAIN TITLE PLOT (1st title line)
                txt0 = create "var_title" textItemClass wks
                        "txFuncCode" : "~"
                        "txString" : var_title
                        "txFontHeightF" : .018
                        "txFont" : "helvetica-bold"
                end create
                anno = NhlAddAnnotation(cn,txt0)
                setvalues anno
                        "amResizeNotify" : True
                        "amSide" : "Top"
;original                       "amZone" : 10
;original                       "amJust" : "CenterLeft"
;original                       "amOrthogonalPosF" : .065
                        "amZone" : 0
                        "amJust" : "CenterCenter"
                        "amSide" : "Top"
                        "amParallelPosF" : 0.0
                        "amOrthogonalPosF" : .595  ; decrease to move downward - need to adjust Main/Time/Level Title together with mainvpy in main routine
                        ;preAug2006(smaller_plotheight) "amOrthogonalPosF" : .615
                end setvalues

;JACK-FONT - BELOW AFFECTS TIME LABEL PLOT (2nd title line)
                txt2 = create "time_title" textItemClass wks
                        "txFuncCode" : "~"
                        "txString" : time_title 
                        "txFontHeightF" : .015
                        "txFont" : "helvetica"
                end create
                anno = NhlAddAnnotation(cn,txt2)
                setvalues anno
                        "amResizeNotify" : True
                        "amSide" : "Top"
;original                       "amZone" : 10
;original                       "amParallelPosF" : 1.0
;original                       "amJust" : "CenterRight"
;original                       "amOrthogonalPosF" : .015
                        "amZone" : 0
                        "amJust" : "CenterCenter"
                        "amSide" : "Top"
                        "amParallelPosF" : 0.0
                        "amOrthogonalPosF" : .565  ; decrease to move downward - need to adjust Main/Time/Level Title together with mainvpy in main routine
;old                        "amOrthogonalPosF" : .567  ; decrease to move downward - need to adjust Main/Time/Level Title together with mainvpy in main routine
                        ;preAug2006(smaller_plotheight) "amOrthogonalPosF" : .575
                end setvalues

;JACK-FONT - BELOW AFFECTS LEVEL LABEL PLOT (3rd title line)
                txt1 = create "lev_title" textItemClass wks
                        "txFuncCode" : "~"
                        "txString" : lev_title
;jack - change height of text at top-right 
                        "txFontHeightF" : .010
;pre-enhanced_titleline3                        "txFontHeightF" : .012
;original                       "txFontHeightF" : .015
;jack-font - affects "level" font to top left of plot
                        "txFont" : "helvetica"
                end create
                anno = NhlAddAnnotation(cn,txt1)
                setvalues anno
                        "amResizeNotify" : True
                        "amSide" : "Top"
;original                       "amZone" : 10
;original                       "amParallelPosF" : 0.0
;original                       "amJust" : "CenterLeft"
;original                       "amOrthogonalPosF" : .015
                        "amZone" : 0
                        "amJust" : "CenterCenter"
                        "amSide" : "Top"
                        "amParallelPosF" : 0.0
                        "amOrthogonalPosF" : .542  ; decrease to move downward - need to adjust Main/Time/Level Title together with mainvpy in main routine
                end setvalues

        end if
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function wrf_new_fill_contour( wks[1]: graphic, data[*][*]:numeric, opt_args[1]:logical, vpx[1]:float,vpy[1]:float,vpwidth[1]:float,vpheight[1]:float )
;pre-viewport_params function wrf_new_fill_contour(wks[1]: graphic, data[*][*]:numeric, opt_args[1]:logical)
local dims
begin

;jack - made nclev = no. of contour LINES & clevel(0),clevel(1) = lowest,highest contour LINE value (so #COLORS=nlev+1)
;jack   (re-named array levels to clevels to avoid confustion with use of levels array in other routines)

;JACK - print to indicate this routine being used
; print("    wrf_plot.ncl FUNCTION wrf_new_fill_contour ENTERED")

        opts =  opt_args

        sf = create "sf" scalarFieldClass defaultapp
                "sfDataArray" : data
        end create
        if(isatt(data,"_FillValue"))
                setvalues sf
                        "sfMissingValueV" : data@_FillValue
                end setvalues
        end if

;jack - use to specify min/max of x,y (vertical) coord for easy tick mark plotting
        if(isatt(data,"_MinX"))
                setvalues sf
                        "sfXCStartV" : data@_MinX
                end setvalues
        end if
        if(isatt(data,"_MaxX"))
                setvalues sf
                        "sfXCEndV" : data@_MaxX
                end setvalues
        end if
        if(isatt(data,"_MinY"))
                setvalues sf
                        "sfYCStartV" : data@_MinY
                end setvalues
        end if
        if(isatt(data,"_MaxY"))
                setvalues sf
                        "sfYCEndV" : data@_MaxY
                end setvalues
        end if

        dims = new(2,float)
        dims = dimsizes(data)


        if((opts).and.(isatt(opts,"AspectRatio")))
           ratio = opts@AspectRatio
           delete(opts@AspectRatio)
        else
          ;jack - shouldnt be an integer divide here !
          ratio = (dims(0)+0.00) / (dims(1)+0.00)
          ;original         ratio = dims(0)/dims(1)
          ;jack - dont constrain ratio
          ;jack-         if(ratio .gt. 1.2) then
          ;jack-           ratio = 1.2
          ;jack-         end if
          ;jack-         if(ratio .lt. .6667) then
          ;jack-          ratio = .6667
          ;jack-         end if
        end if
       ;4testprint: print("       wrf_plot.ncl wrf_new_fill_countour RATIO= "+ratio+" " )

        getvalues wks
                "wkColorMap" : cmap
        end getvalues
        clen = dimsizes(cmap)-2

        ;jack - add "fixed color range" to label title
        fixedlabelid = ""

        mx = max(data)
        mn = min(data)
        ;jack - allow for constant AND "all missing" data
        if( (.not.ismissing(mx)) .and. (.not.ismissing(mn)) .and. (mx-mn.ge.1.e-30) )
        ;old if( (.not.ismissing(mx)).and.(.not.ismissing(mn)).and.(mx.ne.mn) )
        ;older if(mx.ne.mn)

          if( (opts).and.(isatt(opts,"ContourParameters")).and.(opts@ContourParameters(2).gt.0) )
          ;old if((opts).and.(isatt(opts,"ContourParameters")))
            if( opts@ContourParameters(0) .ge. opts@ContourParameters(1) )  ; c_interval specified
              ;old if( dimsizes(opts@ContourParameters) .eq. 1)  ; c_interval specified
              nlev = floattointeger( (mx-mn)/opts@ContourParameters(2) )+1
              clevels = nice_mnmxintvl(mn,mx,nlev,True)
              if(clevels(0) .lt. 0.)  ;  set a zero contour
                nlev = floattointeger( clevels(0)/opts@ContourParameters(2) ) - 1
                clevels(0) = nlev*opts@ContourParameters(2)
              end if
              nlev = floattointeger( (clevels(1)-clevels(0))/opts@ContourParameters(2) )+1
              clevels(1) = clevels(0) + nlev*opts@ContourParameters(2)
              clevels(2) = opts@ContourParameters(2)
              ;jack - made nclev = no. of contour LINES & clevel(0),clevel(1) = lowest,highest contour LINE value (so #COLORS=nlev+1)
              clevels(0) = clevels(0)+clevels(2)
              clevels(1) = clevels(1)-clevels(2)
            else  ; c_min, c_max and c_int are specified
              clevels = opts@ContourParameters
              ;jack - add "fixed color range" to label title
              fixedlabelid = " ~I~ Fixed Color Range ~P~ "
            end if
            ;original delete(opts@ContourParameters)
          else  ; choose nice contour parameters
            clevels = nice_mnmxintvl(mn,mx,28,True)
            ;jack - made nclev = no. of contour LINES & clevel(0),clevel(1) = lowest,highest contour LINE value (so #COLORS=nlev+1)
            clevels(0) = clevels(0)+clevels(2)
            clevels(1) = clevels(1)-clevels(2)
          end if
          ;jack - made nclev = no. of contour LINES & clevel(0),clevel(1) = lowest,highest contour LINE value (so #COLORS=nlev+1)
          ;jack -    so cant re-set clevels(2) here since could be used above to set clevels(0)&clevels(1)
          ;original          if (clevels(2) .lt. 1) then
          ;original            clevels(2) = 1
          ;original          end if
          ;jack - ala original but renamed nlev to nclev
          nclev = floattointeger( ((clevels(1)-clevels(0))/clevels(2)) )+1
          ;original nlev = floattointeger(((clevels(1)-clevels(0))/clevels(2)))+1
          ;4testprint: print("    wrf_plot.ncl wrf_new_fill_countour MN,MX= "+mn+" "+mx )
          ;4testprint: print("    wrf_plot.ncl wrf_new_fill_contour CLEVELS= "+clevels )
          ;jack - made nclev = no. of contour LINES & clevel(0),clevel(1) = lowest,highest contour LINE value (so #COLORS=nlev+1)
          ;4test: print(" wrf_plot.ncl wrf_new_fill_countour MN,MX="+mn+","+mx )
          ;4test: print(" wrf_plot.ncl wrf_new_fill_countour CLEVELS="+clevels(0)+","+clevels(1)+","+clevels(2)+" ISPAN="+clen(0)+","+nclev )
          print("    wrf_plot.ncl wrf_new_fill_contour NCLEV,CLEVELS= "+nclev+" "+clevels(0)+","+clevels(1)+","+clevels(2) )
          fill_colors = ispan(2,clen(0),clen(0)/(nclev+1))
          ;original          fill_colors = ispan(2,clen(0),clen(0)/nlev)
          ;jack-fix_bad_colorbar_max:nicer_colorbar_labels-but-smaller_tint_range+fill_colors = ispan( 2, clen(0), clen(0)/(nlev+1) )
          ;4testprint: print("    wrf_plot.ncl wrf_new_fill_contour CLEN(0),NCLEV= "+clen(0)+" "+nclev )
          ;4testprint: print("    wrf_plot.ncl wrf_new_fill_contour FILL_COLORS= "+fill_colors )

          ;jack - made nclev = no. of contour LINES & clevel(0),clevel(1) = lowest,highest contour LINE value (so #COLORS=nlev+1)
          ;jack -   so added test to avoid array creation problem when nclev=0 and moved explicitlables section ahead of test
          ;jack - so moved this section 
          k = clevels(0)
          sp = clevels(2)
          explicitlabels = new(nclev+2,float)
          do i = 0, (nclev+1) 
              explicitlabels(i) = k + (i-1)*sp
          end do
          if( nclev.gt.0 ) then
             dash_patterns = new(nclev,integer)
             line_thicknesses = new(nclev,float)
             ;original          dash_patterns = new(nlev+1,integer)
             ;original          line_thicknesses = new(nlev+1,float)
             ;jack - made nclev = no. of contour LINES & clevel(0),clevel(1) = lowest,highest contour LINE value (so #COLORS=nlev+1)
             do i = 0, (nclev-1) 
             ;original          do i = 0, nlev 
                 ;; makes negative lines dashed
                 if((k + i*sp).lt.0.0)
                         dash_patterns(i) = 1
                         line_thicknesses(i) = 1.0
                 else
                 ;; makes 0 lines doubly thick
                         if(k+i*sp.eq.0.0)
                                 line_thicknesses(i) = 2.0
                         else
                                 line_thicknesses(i) = 1.0
                         end if
                         dash_patterns(i) = 0
                 end if
             end do
             ;jack - set_explicit_externaledge_labels_for_nice_min/max+
             ;jack - line_thicknesses assignment now depends upon nclev
             if((opts).and.(isatt(opts,"LineThickness")))
               line_thicknesses = line_thicknesses*opts@LineThickness
               delete(opts@LineThickness)
             end if
          ;jack - made nclev = no. of contour LINES & clevel(0),clevel(1) = lowest,highest contour LINE value (so #COLORS=nlev+1)
          else
            ;jack - make no contour line (nclev=0) values same as for mx=mn case
            dash_patterns = 1
            line_thicknesses = 1
          end if

        else
          ;jack - allow for constant AND "all missing" data
          if( (.not.ismissing(mx)).and.(.not.ismissing(mn)) )
            clevels  = (/mx,mx,0.0/)
            ;4testprint: print(" ***MX=MN wrf_plot.ncl wrf_new_fill_countour MX=MN" )
          else
            clevels  = (/0.0,0.0,0.0/)
            ;4testprint: print(" ***MISSING wrf_plot.ncl wrf_new_fill_countour ALL MISSING" )
          end if
          ;old clevels  = (/mx,mx,0.0/)
          ;original-unneeded nlev = 1
          fill_colors = 2
          dash_patterns = 1
          line_thicknesses = 1
;TESTING - explicitlabels UIV when mx-min=1.e-32
explicitlabels = new(3,float)
explicitlabels(0) = clevels(0)
explicitlabels(1) = 0.5*(clevels(0)+clevels(1))
explicitlabels(2) = clevels(1)
print ( "TESTING - check explicitlabels set="+explicitlabels(0)+","+explicitlabels(1)+","+explicitlabels(2) )
        end if

        if(ratio .gt. 1) 
                height = vpheight
                width = height * 1.0/ratio
                ;pre-viewport_params                height = .65
                labelbarside = "bottom"
                lbOrientation = "HORIZONTAL"
                ;for vertical colorbar also need to alter some additional lb resources
                ;for vertical colorbar: lbOrientation = "VERTICAL"
                ;for vertical colorbar: lbOrientation = "VERTICAL"
        else
                width = vpwidth
                height = width * ratio
                ;pre-viewport_params                width = .85 
                labelbarside = "bottom"
                lbOrientation = "HORIZONTAL"
;               labelbarside = "right"
;               lbOrientation = "VERTICAL"
        end if

        if((.not.opts).or.(.not.isatt(opts,"UnitLabel")))
                if(isatt(data,"units"))
                        units = data@units
                else
                        if(isatt(data,"UNITS"))
                                units = data@UNITS
                        else
                                units = "No units provided"
                        end if
                end if
        else
                units = opts@UnitLabel
                delete(opts@UnitLabel)
        end if  

;jack - original position of line_thicknesses assignment - now moved to depend upon nclev

        cn = create "cn" contourPlotClass wks
                "cnScalarFieldData" : sf
                "vpXF" : vpx
                "vpYF" : vpy
                ;pre-viewport_params                "vpXF" : .1
                ;pre-viewport_params                "vpYF" : .87
                ;original "vpYF" : .90
                "vpWidthF" : width
                "vpHeightF" : height 
                "cnInfoLabelOn" : False
                "cnFillOn" : True
                "cnFillColors" : fill_colors
                "cnMonoLineDashPattern" : False
                "cnMonoLineThickness" : False
                "cnLineThicknesses" : line_thicknesses
                "cnLineDashPatterns" : dash_patterns
                "cnFillDrawOrder" : "PreDraw"
                "pmLabelBarDisplayMode" : "ALWAYS"
                "pmLabelBarSide" : labelbarside
                "lbOrientation" : lbOrientation
                "lbPerimOn" : False
                "lbOrientation" : lbOrientation
                "lbTitleOn" : True
                "lbTitleFuncCode" : "~"
                ;;;JACK - since addition of add_labelbar_text, lbTitleString now obsolete 
                ;jack - add "fixed color range" to label title
                "lbTitleString" :  fixedlabelid + units + fixedlabelid
                ;original "lbTitleString" : units
                "lbLabelJust" : "CenterLeft"
                "lbLabelAngleF" : -0.0
                "cnLinesOn" : False
                "cnLineLabelsOn" : False
                "lbBoxMinorExtentF" : .10
                ;old   "lbTitleExtentF" : .060
                ;for label title at bottom:
                 "lbTitlePosition" : "Bottom"
                 "lbTitleJust" : "TopCenter"  ; use for bottom title
                 "lbJustification" : "TopCenter"
                 "pmLabelBarOrthogonalPosF" : 0.015  ; move lb up vertically as much as possible  ideally this would be in rasp.ncl but has no effect there !?
;new "pmLabelBarOrthogonalPosF" : 0.0  ; ideally this would be in rasp.ncl but has no effect there !?
                ;old-often_works_but_GBtopo3_labels_overlap_so_use_larger_value "pmLabelBarOrthogonalPosF" : 0.010  ; move lb up vertically as much as possible  ideally this would be in rasp.ncl but has no effect there !?
                ;unused "pmLabelBarKeepAspect" :  True 
                ;bad "pmLabelBarHeightF" : .25 ; cannot figure this out - get strange parim with blank inside for values >0.3
                ;for_vertical_colorbar: "pmLabelBarParallelPosF" : 1.0
                ;for_vertical_colorbar: "lbTitleExtentF" : 0.1
                ;4test              "lbPerimOn" : "True"
        end create

        ;jack - allow for constant AND "all missing" data
        if( (.not.ismissing(mx)).and.(.not.ismissing(mn)).and.(mx.ne.mn) )
        ;old if(mx.ne.mn)

          ;jack - now treat "nice" range differently from original since know mn>clevels(0)-clevels(2) & mx<clevels(1)+clevels(2)
          if( (opts) .and. (isatt(opts,"ContourParameters")) )
                delete(opts@ContourParameters)
                setvalues cn
                        "cnLevelSelectionMode" : "MANUALLEVELS"
                        "cnLevelSpacingF" : clevels(2)
                        "cnMinLevelValF" : clevels(0)
                        "cnMaxLevelValF" : clevels(1)
                end setvalues
          else
                ;jack - now treat "nice" range differently from original since know mn>clevels(0)-clevels(2) & mx<clevels(1)+clevels(2)
                ;jack - set_explicit_externaledge_labels_for_nice_min/max+
                ;jack - nb: must use explicit labels to put label at external edges of colorbar !!
                setvalues cn
                        "cnLevelSelectionMode" : "MANUALLEVELS"
                        "cnLevelSpacingF" : clevels(2)
                        "cnMinLevelValF" : clevels(0)
                        "cnMaxLevelValF" : clevels(1)
                        ;jack - set_explicit_externaledge_labels_for_nice_min/max+
                        "cnExplicitLabelBarLabelsOn" : True        ; differs from original
                        "lbLabelAlignment" : "ExternalEdges"       ; differs from original
                        "lbLabelStrings" : explicitlabels          ; differs from original 
                end setvalues
          end if

       ;jack - for constant or missing data dont display labelbar
        else
           if( (.not.ismissing(mx)).and.(.not.ismissing(mn)) )
              setvalues cn
                ;skip_constantdata_annotation  "cnConstFLabelOn" : False
                "pmLabelBarDisplayMode" : "NoCreate"
              end setvalues
           else
              setvalues cn
                ;skip_nodata_annotation
                "cnNoDataLabelOn" : False
                "pmLabelBarDisplayMode" : "NoCreate"
              end setvalues
           end if
        end if

        ok = False
        lbstride = 1
        do while(.not.ok)
                setvalues cn
                        "lbLabelStride" : lbstride
                end setvalues
                getvalues cn
                        "lbLabelFontHeightF" : lbf
                end getvalues
               if(lbf.gt..013)
                        ok = True
                else
                        lbstride = lbstride + 1
                        setvalues cn
                                "lbLabelStride" : lbstride
                        end setvalues
                end if
        end do

        _SetMainTitle(wks,cn,data,opts)

        ;jack - input opts override previously set ones ?? (doesnt seem to work for pm resources)
        if(opts) 
            ;;; JACK - TO ELIMINATE WARNING MESSAGE: warning:LineThickness is not a valid resource in cn at this time
            if( isatt(opts,"LineThickness") )
               delete(opts@LineThickness)
            end if
            if( isatt(opts,"ContourParameters") )
                delete(opts@ContourParameters)
            end if
                atts = getvaratts(opts)
                if(.not.all(ismissing(atts)))
                        attsetvalues(cn,opts)
                end if
        end if

;;; JACK: print colorbar error diagnostic values
;old print("    wrf_plot.ncl wrf_new_fill_contour MN,MX,CLEVELS= "+clevels(0)+" "+clevels(1)+" "+clevels(2) )
;4testprint: print("    wrf_plot.ncl wrf_new_fill_contour LBSTRIDE= "+lbstride )
;4testprint: print("    wrf_plot.ncl wrf_new_fill_contour CLEVELS= "+clevels )
;4testprint: print("    wrf_plot.ncl wrf_new_fill_contour FILL_COLORS= "+fill_colors )

;;; JACK: print final subroutine values
;;; *NB* these seem to be over-ridden by mp (map) viewport values when those are set
;  getvalues cn
;    "vpXF" : cn_vpx
;    "vpYF" : cn_vpy
;    "vpWidthF" : cn_vpwidth
;    "vpHeightF" : cn_vpheight
;  end getvalues
;  print("    wrf_plot.ncl wrf_new_fill_contour VIEWPORT: "+cn_vpwidth+"x"+cn_vpheight+"+"+cn_vpx+"+"+cn_vpy+" " )

       ;4test_use_of_new_parameter_data: if here insert "cn@data = sf"
       ;4test_use_of_new_parameter_data: in plot routine can use "setvalues contour_bparam@data ; "sfDataArray" : bparam(:,:) ; end setvalues"

        return(cn)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function wrf_new_line_contour( wks[1]: graphic, data[*][*]:numeric, opt_args[1]:logical, vpx[1]:float,vpy[1]:float,vpwidth[1]:float,vpheight[1]:float )
;pre-viewport_params function wrf_new_line_contour(wks[1]: graphic, data[*][*]:numeric, opt_args[1]:logical)
local dims
begin

;;;JACK - print to indicate this routine being used
; print("    wrf_plot.ncl FUNCTION wrf_new_line_contour ENTERED")

        opts =  opt_args

        sf = create "sf" scalarFieldClass defaultapp
                "sfDataArray" : data
        end create
        if(isatt(data,"_FillValue"))
                setvalues sf
                        "sfMissingValueV" : data@_FillValue
                end setvalues
        end if

;jack - use to specify min/max of x,y (vertical) coord for easy tick mark plotting
        if(isatt(data,"_MinX"))
                setvalues sf
                        "sfXCStartV" : data@_MinX
                end setvalues
        end if
        if(isatt(data,"_MaxX"))
                setvalues sf
                        "sfXCEndV" : data@_MaxX
                end setvalues
        end if
        if(isatt(data,"_MinY"))
                setvalues sf
                        "sfYCStartV" : data@_MinY
                end setvalues
        end if
        if(isatt(data,"_MaxY"))
                setvalues sf
                        "sfYCEndV" : data@_MaxY
                end setvalues
        end if

        dims = new(2,float)
        dims = dimsizes(data)

        if((opts).and.(isatt(opts,"AspectRatio")))
                ratio = opts@AspectRatio
    delete(opts@AspectRatio)
        else
;jack - shouldnt be an integer divide here !
    ratio = (dims(0)+0.00) / (dims(1)+0.00)
;original    ratio = dims(0)/dims(1)
;jack - dont constrain ratio
;jack-    if(ratio .gt. 1.2) then
;jack-        ratio = 1.2
;jack-    end if
;jack-    if(ratio .lt. .6667) then
;jack-       ratio = .6667
;jack-    end if
        end if

        if((opts).and.(isatt(opts,"ContourLineThicknessInterval")))
                ContourLineThicknessInterval = opts@ContourLineThicknessInterval
    delete(opts@ContourLineThicknessInterval)
        else
    ; default is for no thickened lines
    ContourLineThicknessInterval = 0
        end if

        mx = max(data)
        mn = min(data)
  ;4testprint: print("    wrf_plot.ncl wrf_new_line_countour MN,MX= "+mn+" "+mx )
        if(mx.ne.mn)
          if( (opts).and.(isatt(opts,"ContourParameters")).and.(opts@ContourParameters(2).gt.0) )
          ;old if((opts).and.(isatt(opts,"ContourParameters")))
            if( opts@ContourParameters(0) .ge. opts@ContourParameters(1) )  ; c_interval specified
            ;old if( dimsizes(opts@ContourParameters) .eq. 1)  ; c_interval specified
              nlev = floattointeger( (mx-mn)/opts@ContourParameters(2) )+1
              levels = nice_mnmxintvl(mn,mx,nlev,True)
              if(levels(0) .lt. 0.)  ;  set a zero contour
                nlev = floattointeger( levels(0)/opts@ContourParameters(2) ) - 1
                levels(0) = nlev*opts@ContourParameters(2)
              end if
              nlev = floattointeger( (levels(1)-levels(0))/opts@ContourParameters(2) )+1
              levels(1) = levels(0) + nlev*opts@ContourParameters(2)
              levels(2) = opts@ContourParameters(2)
            else  ; c_min, c_max and c_int are specified
              levels = opts@ContourParameters
            end if
            delete(opts@ContourParameters)
          else  ; choose nice contour parameters
            levels = nice_mnmxintvl(mn,mx,28,True)
          end if
         ;4testprint: print("    wrf_plot.ncl wrf_new_line_countour NICE LEVELS= "+levels )
          nlev = floattointeger(((levels(1)-levels(0))/levels(2)))+1
          dash_patterns = new(nlev+1,integer)
          line_thicknesses = new(nlev+1,float)
          k = levels(0)
          sp = levels(2)
          do i = 0, nlev 
            ;4testprint: print("    wrf_plot.ncl wrf_new_line_countour LINES: "+i+" "+k+" "+sp+"=>"+(k+i*sp)+" " )
            ;jack - make specified contours (from zero contour) thicker
            cvalue = k+i*sp 
            ;; makes negative lines dashed
            if( cvalue .lt. 0.0 )
              ;original                       if((k + i*sp).lt.0.0)
              ;original                               line_thicknesses(i) = 1.0
              ;jack - make specified contours (from zero contour) thicker
              if( ( ContourLineThicknessInterval .gt. 0.0 ) .and. (cvalue/(ContourLineThicknessInterval*sp)) .eq. floattointeger(cvalue/(ContourLineThicknessInterval*sp)) ) 
                line_thicknesses(i) = 2.0
              else
                line_thicknesses(i) = 1.0
              end if
              dash_patterns(i) = 1
            else
              ;; makes 0 lines doubly thick
              ;original                           if(k+i*sp.eq.0.0)
              ;jack - make specified contours (from zero contour) thicker
              if( ( ContourLineThicknessInterval .gt. 0.0 ) .and. (cvalue/(ContourLineThicknessInterval*sp)) .eq. floattointeger(cvalue/(ContourLineThicknessInterval*sp)) ) 
                line_thicknesses(i) = 2.0
              else
                line_thicknesses(i) = 1.0
              end if
                dash_patterns(i) = 0
            end if
          end do
        else 
    levels  = (/mx,mx,0.0/)
    nlev = 1
    fill_colors = 2
    dash_patterns = 1
    line_thicknesses = 1
        end if
  ;4testprint: print("    wrf_plot.ncl wrf_new_line_countour LINE_THICKNESSES= "+line_thicknesses )

        if(ratio .gt. 1) 
                height = vpheight
                width = height* 1.0/ratio
                ;pre-viewport_params                height = .65
                labelbarside = "right"
                lbOrientation = "VERTICAL"
  ;4testprint: print("    wrf_plot.ncl wrf_new_line_countour RATIO>1 => "+height+","+width )
        else
                width = vpwidth
                height = width * ratio
                ;pre-viewport_params                width = .95 
                labelbarside = "bottom"
                lbOrientation = "HORIZONTAL"
  ;4testprint: print("    wrf_plot.ncl wrf_new_line_countour RATIO<1 => "+height+","+width )
        end if


        if((.not.opts).or.(.not.isatt(opts,"UnitLabel")))
                if(isatt(data,"units"))
                        units = data@units
                else
                        if(isatt(data,"UNITS"))
                                units = data@UNITS
                        else
                                units = "No units provided"
                        end if
                end if
        else
                units = opts@UnitLabel
                delete(opts@UnitLabel)
        end if  

        if((opts).and.(isatt(opts,"LineThickness")))
                line_thicknesses = line_thicknesses*opts@LineThickness
    delete(opts@LineThickness)
        end if

        cn = create "cn" contourPlotClass wks
                "cnScalarFieldData" : sf
                "vpXF" : vpx
                "vpYF" : vpy
                ;pre-viewport_params                "vpXF" : .1
                ;pre-viewport_params                "vpYF" : .87
                ;pre-viewport_params                ;original "vpYF" : .90
                "vpWidthF" : width
                "vpHeightF" : height 
                "cnInfoLabelOn" : True
                "cnMonoLineDashPattern" : False
                "cnMonoLineThickness" : False
                "cnLineThicknesses" : line_thicknesses
                "cnLineDashPatterns" : dash_patterns
        end create
        if(mx.ne.mn)
                setvalues cn
                        "cnLevelSelectionMode" : "MANUALLEVELS"
                        "cnMinLevelValF" : levels(0)
                        "cnMaxLevelValF" : levels(1)
                        "cnLevelSpacingF" : levels(2)
                end setvalues
        end if

        _SetMainTitle(wks,cn,data,opts)

        if(opts) 
                atts = getvaratts(opts)
                if(.not.all(ismissing(atts)))
                        attsetvalues(cn,opts)
                end if
        end if

;;; JACK: print final subroutine values
;;; *NB* these seem to be over-ridden by mp (map) viewport values when those are set
;  getvalues cn
;  "vpXF" : cn_vpx
;  "vpYF" : cn_vpy
;  "vpWidthF" : cn_vpwidth
;  "vpHeightF" : cn_vpheight
;  end getvalues
;  print("    wrf_plot.ncl wrf_new_line_countour VIEWPORT: "+cn_vpwidth+"x"+cn_vpheight+"+"+cn_vpx+"+"+cn_vpy+" " )

        return(cn)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function wrf_new_vector( wks[1]: graphic, data_u[*][*]:numeric, data_v[*][*]:numeric, opt_args[1]:logical, vpx[1]:float,vpy[1]:float,vpwidth[1]:float,vpheight[1]:float )
;pre-viewport_params function wrf_new_vector(wks[1]: graphic, data_u[*][*]:numeric, data_v[*][*]:numeric, opt_args[1]:logical)
local dims
begin

;;;JACK - print to indicate this routine being used
; print("    wrf_plot.ncl FUNCTION wrf_new_vector ENTERED")

        opts =  opt_args

        
        vf = create "vf" vectorFieldClass defaultapp
                "vfUDataArray" : data_u
                "vfVDataArray" : data_v
        end create
        if(isatt(data_u,"_FillValue")) 
                setvalues vf
                        "vfMissingUValueV" : data_u@_FillValue
                end setvalues
        end if
        if(isatt(data_v,"_FillValue")) 
                setvalues vf
                        "vfMissingVValueV" : data_v@_FillValue
                end setvalues
        end if
        
        dims = new(2,float)
        dims = dimsizes(data_u)

        if((opts).and.(isatt(opts,"AspectRatio")))
                ratio = opts@AspectRatio
    delete(opts@AspectRatio)
        else
;jack - shouldnt be an integer divide here !
    ratio = (dims(0)+0.00) / (dims(1)+0.00)
;original    ratio = dims(0)/dims(1)
;jack - dont constrain ratio
;jack-    if(ratio .gt. 1.2) then
;jack-        ratio = 1.2
;jack-    end if
;jack-    if(ratio .lt. .6667) then
;jack-       ratio = .6667
;jack-    end if
        end if

        getvalues wks
                "wkColorMap" : cmap
        end getvalues
        clen = dimsizes(cmap)-2

        if(ratio .gt. 1) 
                height = vpheight
                width = vpheight * 1.0/ratio
                ;pre-viewport_params                width = .65 * 1.0/ratio
                ;pre-viewport_params                height = .65
                labelbarside = "right"
                lbOrientation = "VERTICAL"
        else
                width = vpwidth
                height = vpwidth * ratio
                ;pre-viewport_params                width = .95 
                ;pre-viewport_params                height = .95 * ratio
                labelbarside = "bottom"
                lbOrientation = "HORIZONTAL"
        end if

        if(isatt(data_u,"units"))
                units = data_u@units
        else
                if(isatt(data_u,"UNITS"))
                        units = data_u@UNITS
                else
                        units = "No units provided"
                end if
        end if  

        if((opts).and.(isatt(opts,"VectLen")))
                vect_len = opts@VectLen
                delete(opts@VectLen)
        else
                vect_len = -1.0
        end if
        ;JACK - now allow vector length to be set absolutely or relatively
        ;JACK       use input vect_len as ndc length if positive, gridpt separation multiplier if negative
        if( vect_len .gt. 0 )
          vect_len_ndc = vect_len
        else
          vect_len_ndc = -1. * vect_len * width / dims(1)
        end if
        if((opts).and.(isatt(opts,"WindBarbsOn")))
                if(opts@WindBarbsOn)
                        gstyle = "WindBarb"
                else
                        gstyle = "LineArrow"
                end if
                delete(opts@WindBarbsOn)
        else
                gstyle = "LineArrow"
        end if
        vct = create "vct" vectorPlotClass wks
                "vcVectorFieldData" : vf
                "vpXF" : vpx
                "vpYF" : vpy
                "vpWidthF" : vpwidth
                "vpHeightF" : vpheight 
                ;pre-viewport_params                "vpXF" : .1
                ;pre-viewport_params                "vpYF" : .87
                ;pre-viewport_params                ;original "vpYF" : .90
                ;pre-viewport_params                "vpWidthF" : width
                ;pre-viewport_params                "vpHeightF" : height 
                ;JACK - set distance between displayed wind barbs and barb shaft length
                "vcMinDistanceF" : vect_len_ndc
                ;JACK - set barb shaft length as fraction of distance between wind barbs - 0.8 too large (get overlap of barbs & shafts)
                "vcRefLengthF" : 0.667 * vect_len_ndc
                ;first "vcRefLengthF" : 0.75 * vect_len_ndc
                ;original "vcMinDistanceF" : width/num_vectors
                ;original "vcRefLengthF" : width/num_vectors
                ;jack - docs say vcMinFracLengthF ignored for "WindBarb"  
                "vcMinFracLengthF" : .2
                "vcGlyphStyle" : gstyle
        end create

        _SetMainTitle(wks,vct,data_u,opts)

        if(opts) 
                atts = getvaratts(opts)
                if(.not.all(ismissing(atts)))
                        attsetvalues(vct,opts)
                end if
        end if
        return(vct)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure wrf_update_contour_data( wks,cn[1]:graphic, data[*][*]:numeric,opt_args[1]:logical, vpx[1]:float,vpy[1]:float,vpwidth[1]:float,vpheight[1]:float )
;pre-viewport_params procedure wrf_update_contour_data(wks,cn[1]:graphic, data[*][*]:numeric,opt_args[1]:logical)
begin

;;;  *** NB ***  IF USE THIS ROUTINE MUST MAKE ADDITIONAL ALTERATIONS TO PARALLEL MY CHANGES TO function wrf_new_fill_contour  !!!!!!

        opts = opt_args
        if(NhlClassName(cn).eq."contourPlotClass")
              dims = new(2,float)
              dims = dimsizes(data)

             if((opts).and.(isatt(opts,"AspectRatio")))
                ratio = opts@AspectRatio
                delete(opts@AspectRatio)
              else
                ;jack - shouldnt be an integer divide here !
                ratio = (dims(0)+0.00) / (dims(1)+0.00)
;original                ratio = dims(0)/dims(1)
;jack - dont constrain ratio
;jack-       if(ratio .gt. 1.2) then
;jack-                  ratio = 1.2
;jack-          end if
;jack-          if(ratio .lt. .6667) then
;jack-                  ratio = .6667
;jack-          end if
                end if

                getvalues wks
                        "wkColorMap" : cmap
                end getvalues
                clen = dimsizes(cmap)-2

                mx = max(data)
                mn = min(data)
                if(mx.ne.mn)
                  if( (opts).and.(isatt(opts,"ContourParameters")).and.(opts@ContourParameters(2).gt.0) )
                  ;old if((opts).and.(isatt(opts,"ContourParameters")))
                    if( opts@ContourParameters(0) .ge. opts@ContourParameters(1) )  ; c_interval specified
                    ;old if( dimsizes(opts@ContourParameters) .eq. 1)  ; c_interval specified
                      nlev = floattointeger( (mx-mn)/opts@ContourParameters(2) )+1
                      levels = nice_mnmxintvl(mn,mx,nlev,True)
                        if(levels(0) .lt. 0.)  ;  set a zero contour
                          nlev = floattointeger( levels(0)/opts@ContourParameters(2) ) - 1
                          levels(0) = nlev*opts@ContourParameters(2)
                        end if
                        nlev = floattointeger( (levels(1)-levels(0))/opts@ContourParameters(2) )+1
                        levels(1) = levels(0) + nlev*opts@ContourParameters(2)
                        levels(2) = opts@ContourParameters(2)
                      else  ; c_min, c_max and c_int are specified
                        levels = opts@ContourParameters(2)
                      end if
                      delete(opts@ContourParameters)
                    else  ; choose nice contour parameters
                      levels = nice_mnmxintvl(mn,mx,28,True)
                    end if
                    nlev = floattointeger(((levels(1)-levels(0))/levels(2)))+1
                    fill_colors = ispan(2,clen(0),clen(0)/nlev)
                    dash_patterns = new(nlev+1,integer)
                    line_thicknesses = new(nlev+1,float)
                    k = levels(0)
                    sp = levels(2)
                    do i = 0, nlev 
                       if((k + i*sp).lt.0.0)
                          dash_patterns(i) = 1
                          line_thicknesses(i) = 1.0
                       else
                         if(k+i*sp.eq.0.0)
                           line_thicknesses(i) = 2.0
                         else
                           line_thicknesses(i) = 1.0
                         end if
                         dash_patterns(i) = 0
                      end if
                    end do
                  else 
                    levels  = (/mx,mx,0.0/)
                    nlev = 1
                    fill_colors = 2
                    dash_patterns = 1
                    line_thicknesses = 1
                  end if

                  if(ratio .gt. 1) 
                        height = vpheight
                        width = vpwidth * 1.0/ratio
                        ;pre-viewport_params                        width = .65 * 1.0/ratio
                        ;pre-viewport_params                        height = .65
                        labelbarside = "right"
                        lbOrientation = "VERTICAL"
                  else
                        width = vpwidth
                        height = vpheight * ratio
                        ;pre-viewport_params                        width = .95 
                        ;pre-viewport_params                        height = .95 * ratio
                        labelbarside = "bottom"
                        lbOrientation = "HORIZONTAL"
                  end if

                  if((.not.opts).or.(.not.isatt(opts,"UnitLabel")))
                    if(isatt(data,"units"))
                      units = data@units
                    else
                      if(isatt(data,"UNITS"))
                         units = data@UNITS
                      else
                         units = "No units provided"
                      end if
                    end if
                  else
                    units = opts@UnitLabel
                    delete(opts@UnitLabel)
                  end if  
                  getvalues cn
                        "cnScalarFieldData" : sf
                  end getvalues
                  setvalues cn
                        "cnLevelSelectionMode" : "AUTOMATICLEVELS"
                  end setvalues
                  setvalues sf
                        "sfDataArray" : data
                  end setvalues
                  if(isatt(data,"_FillValue"))
                        setvalues sf
                                "sfMissingValueV" : data@_FillValue
                        end setvalues
                  end if
  
                  if((opts).and.(isatt(opts,"LineThickness")))
                    line_thicknesses = line_thicknesses*opts@LineThickness
                    delete(opts@LineThickness)
                  end if

                  setvalues cn
                  ;       "vpXF" : .1
                  ;       "vpYF" : .87
                  ;       ;original "vpYF" : .90
                  ;       "vpWidthF" : width
                  ;       "vpHeightF" : height
                          "cnInfoLabelOn" : False
                          "cnFillColors" : fill_colors
                          "cnLineThicknesses" : line_thicknesses
                          "cnLineDashPatterns" : dash_patterns
                          "lbTitleString" : units
                          "lbLabelStride" : 1
                  end setvalues

                  if(mn.ne.mx)
                     setvalues cn
                        "cnLevelSelectionMode" : "MANUALLEVELS"
                        "cnMinLevelValF" : levels(0)
                        "cnMaxLevelValF" : levels(1)
                        "cnLevelSpacingF" : levels(2)
                    end setvalues
                  end if

                  if((opts).and.(isatt(opts,"UnitLabel")))
                     setvalues cn
                         "lbTitleString" : opts@UnitLabel
                     end setvalues
                     delete(opts@UnitLabel)
                  end if
                  getvalues cn
                          "pmLabelBarDisplayMode" : tp
                  end getvalues
                  if(.not.ismissing(tp).and.(tp.eq.1))
                    ok = False
                    lbstride = 1
                    do while(.not.ok)
                          setvalues cn
                                  "lbLabelStride" : lbstride
                          end setvalues
                          getvalues cn
                                  "lbLabelFontHeightF" : lbf
                          end getvalues
                          if(lbf.gt..013)
                                  ok = True
                          else
                                  lbstride = lbstride + 1
                                  setvalues cn
                                          "lbLabelStride" : lbstride
                                  end setvalues
                          end if
                    end do
                  end if
                  _ReSetMainTitle(wks,cn,data,opts)

                  if(opts) 
                    atts = getvaratts(opts)
                    if(.not.all(ismissing(atts)))
                          attsetvalues(cn,opts)
                    end if
                  end if

                else
                  print("wrf_update_contour_data: only works with contour plots")
                end if
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure wrf_update_vector_data(wks,vc[1]:graphic, data_u[*][*]:numeric,data_v[*][*]:numeric,opt_args[1]:logical)
begin
        opts = opt_args

        if(NhlClassName(vc).eq."vectorPlotClass")
                getvalues vc
                        "vcVectorFieldData" : vf
                        "vpWidthF" : width
                end getvalues
                setvalues vf
                        "vfUDataArray" : data_u
                        "vfVDataArray" : data_v
                end setvalues
                if(isatt(data_u,"_FillValue")) 
                        setvalues vf
                                "vfMissingUValueV" : data_u@_FillValue
                        end setvalues
                end if
                if(isatt(data_v,"_FillValue")) 
                        setvalues vf
                                "vfMissingVValueV" : data_v@_FillValue
                        end setvalues
                end if
                _ReSetMainTitle(wks,vc,data_u,opts)
        if((opts).and.(isatt(opts,"NumVectors")))
                        setvalues vc
                                "vcMinDistanceF" : width/opts@NumVectors
                                "vcRefLengthF" : width/opts@NumVectors
                        end setvalues
        delete(opts@NumVectors)
        end if
        if((opts).and.(isatt(opts,"WindBarbsOn")))
                        if(opts@WindBarbsOn)
                                setvalues vc
                                        "vcGlyphStyle" : "WindBarb"
                                end setvalues
                        else 
                                setvalues vc
                                        "vcGlyphStyle" : "LineArrow"
                                end setvalues
                        end if
        delete(opts@WindBarbsOn)
          end if
                if(opts) 
                        atts = getvaratts(opts)
                        if(.not.all(ismissing(atts)))
                                attsetvalues(vc,opts)
                        end if
                end if


        else 
                print("wrf_updata_vector_data: only works with vector input")
        end if
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure wrf_mapoverlay(base[1]:graphic,plot[1]:graphic)
begin
        setvalues plot
                "tfDoNDCOverlay" : True
        end setvalues
        overlay(base,plot)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function wrf_new_map( wks[1]:graphic,in_file[1]:file,opt_args[1]:logical, vpx[1]:float,vpy[1]:float,vpwidth[1]:float,vpheight[1]:float )
;pre-viewport_params function wrf_new_map(wks[1]:graphic,in_file[1]:file,opt_args[1]:logical)
begin

;;;JACK - print to indicate this routine being used
; print("    wrf_plot.ncl FUNCTION wrf_new_map ENTERED")

        opts = opt_args

;JACK - GEOGRAPHIC OUTLINES
us_states = (/\
   "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", \
   "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", \
   "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", \
   "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", \
   "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming" \
/)

        if(isatt(in_file,"MAP_PROJ"))
                if(in_file@MAP_PROJ .eq. 0)
                        print("Error: MAP_PROJ .eq. 0 data does not have a map projection")
                        return(new(1,graphic))
                end if
                if(in_file@MAP_PROJ .eq. 1)
                        lat = in_file->XLAT(0,:,:)
                        lon = in_file->XLONG(0,:,:)
        ;4testptint: print ( "LAT,LON(0,0)= "+lat(0,0)+" "+lon(0,0) )
                        dims = dimsizes(lat)

    if(isatt(in_file,"STAND_LON"))
                        mp = create "mp" mapPlotClass wks
                    "vpXF" : vpx
                    "vpYF" : vpy
                    "vpWidthF" : vpwidth
                    "vpHeightF" : vpheight
                    ;pre-viewport_params                    "vpXF" : .1
                    ;pre-viewport_params                    "vpYF" : .87
                    ;pre-viewport_params                    ;original "vpYF" : .90
                    ;pre-viewport_params                    "vpWidthF" : .80
                    ;pre-viewport_params                    "vpHeightF" : .70
                                "mpProjection" : "LAMBERTCONFORMAL"
                                "mpDataBaseVersion" : "NCARG4_1"

;JACK - GEOGRAPHIC OUTLINES
;;; to get Country+USstate outline had to use "National" and add states to mpOutlineSpecifiers
;;;    since using "AllBoundaries" also plotted UScounty outlines
        "mpOutlineBoundarySets" : "National"
  "mpOutlineSpecifiers" : "Conterminous US . " + us_states
        ;jack-no_country: "mpOutlineBoundarySets" : "USStates"
  ;jack-country+UScounty:       "mpOutlineBoundarySets" : "AllBoundaries"
  ;bad  "mpOutlineSpecifiers" : "United States . " + us_states    ; dont get n. nv line in canv plot (due to lying along lat. line??)

                                "mpPerimOn" : True
                                "mpLambertParallel1F" : in_file@TRUELAT1
                                "mpLambertParallel2F" : in_file@TRUELAT2
                                "mpLambertMeridianF" : in_file@STAND_LON
                                "mpLimitMode" : "CORNERS"
                                "mpLeftCornerLatF" : lat(0,0)
                                "mpLeftCornerLonF" : lon(0,0)
                                "mpRightCornerLatF" : lat(dims(0)-1,dims(1)-1)
                                "mpRightCornerLonF" : lon(dims(0)-1,dims(1)-1)
;jack - empirically, this controls lat/long line spacing for my press level plots if mpGridSpacingF not set
                                "mpGridSpacingF": 10
                        end create
                   else 
                        mp = create "mp" mapPlotClass wks
                    "vpXF" : vpx
                    "vpYF" : vpy
                    "vpWidthF" : vpwidth
                    "vpHeightF" : vpheight
                    ;pre-viewport_params                    "vpXF" : .1
                    ;pre-viewport_params                    "vpYF" : .87
                    ;pre-viewport_params                    ;original "vpYF" : .90
                    ;pre-viewport_params                    "vpWidthF" : .80
                    ;pre-viewport_params                    "vpHeightF" : .70
                                "mpProjection" : "LAMBERTCONFORMAL"
                                "mpDataBaseVersion" : "NCARG4_1"

;JACK - GEOGRAPHIC OUTLINES
;;; to get Country+USstate outline had to use "National" and add states to mpOutlineSpecifiers
;;;    since using "AllBoundaries" also plotted UScounty outlines
        "mpOutlineBoundarySets" : "National"
        "mpOutlineSpecifiers" : "United States . " + us_states
        ;jack-no_country: "mpOutlineBoundarySets" : "USStates"
  ;jack-country+UScounty:       "mpOutlineBoundarySets" : "AllBoundaries"

                                "mpPerimOn" : True
                                "mpLambertParallel1F" : in_file@TRUELAT1
                                "mpLambertParallel2F" : in_file@TRUELAT2
                                "mpLambertMeridianF" : in_file@CEN_LON
                                "mpLimitMode" : "CORNERS"
                                "mpLeftCornerLatF" : lat(0,0)
                                "mpLeftCornerLonF" : lon(0,0)
                                "mpRightCornerLatF" : lat(dims(0)-1,dims(1)-1)
                                "mpRightCornerLonF" : lon(dims(0)-1,dims(1)-1)
                                "mpGridSpacingF": 10
                        end create
    end if

;;; JACK - TO PRINT NAMES OF THE AVAILABLE GEOGRAPHIC OUTLINES IN DATABASE
;;default:  mp@mpDataSetName    = "Earth..2"
;  getvalues mp              
;  "mpAreaNames" : area_names 
;  end getvalues 
;  print(area_names)
;; JACK - EXAMPLE OF SELECTING CANADIAN PROVINCE OUTLINES
;  mp@mpOutlineSpecifiers = area_names(526:616) 

                end if
                if(in_file@MAP_PROJ .eq. 2)
                        lat = in_file->XLAT(0,:,:)
                        lon = in_file->XLONG(0,:,:)
                        dims = dimsizes(lat)
                        
    if(isatt(in_file,"STAND_LON")) 
                        mp = create "mp" mapPlotClass wks
                    "vpXF" : vpx
                    "vpYF" : vpy
                    "vpWidthF" : vpwidth
                    "vpHeightF" : vpheight
                    ;pre-viewport_params                    "vpXF" : .1
                    ;pre-viewport_params                    "vpYF" : .87
                    ;pre-viewport_params                    ;original "vpYF" : .90
                    ;pre-viewport_params                    "vpWidthF" : .80
                    ;pre-viewport_params                    "vpHeightF" : .70
                                "mpProjection" : "STEREOGRAPHIC"
                                "mpDataBaseVersion" : "NCARG4_1"
                                "mpOutlineBoundarySets" : "USStates"
                                ;"mpOutlineBoundarySets" : "AllBoundaries"
                                "mpPerimOn" : True
                                "mpCenterLatF" : in_file@TRUELAT1
                                "mpLambertMeridianF" : in_file@STAND_LON
                                "mpLimitMode" : "CORNERS"
                                "mpLeftCornerLatF" : lat(0,0)
                                "mpLeftCornerLonF" : lon(0,0)
                                "mpRightCornerLatF" : lat(dims(0)-1,dims(1)-1)
                                "mpRightCornerLonF" : lon(dims(0)-1,dims(1)-1)
                                "mpGridSpacingF": 10
                        end create
                   else 
                        mp = create "mp" mapPlotClass wks
                    "vpXF" : vpx
                    "vpYF" : vpy
                    "vpWidthF" : vpwidth
                    "vpHeightF" : vpheight
                    ;pre-viewport_params                    "vpXF" : .1
                    ;pre-viewport_params                    "vpYF" : .87
                    ;pre-viewport_params                    ;original "vpYF" : .90
                    ;pre-viewport_params                    "vpWidthF" : .80
                    ;pre-viewport_params                    "vpHeightF" : .70
                                "mpProjection" : "STEREOGRAPHIC"
                                "mpDataBaseVersion" : "NCARG4_1"
                                "mpOutlineBoundarySets" : "USStates"
                                ;"mpOutlineBoundarySets" : "AllBoundaries"
                                "mpPerimOn" : True
                                "mpCenterLatF" : in_file@TRUELAT1
                                "mpLambertMeridianF" : in_file@CEN_LON
                                "mpLimitMode" : "CORNERS"
                                "mpLeftCornerLatF" : lat(0,0)
                                "mpLeftCornerLonF" : lon(0,0)
                                "mpRightCornerLatF" : lat(dims(0)-1,dims(1)-1)
                                "mpRightCornerLonF" : lon(dims(0)-1,dims(1)-1)
                                "mpGridSpacingF": 10
                        end create
    end if
                end if
                if(in_file@MAP_PROJ .eq. 3)
                        lat = in_file->XLAT(0,:,:)
                        lon = in_file->XLONG(0,:,:)
                        dims = dimsizes(lat)
                        
    if(isatt(in_file,"STAND_LON"))
                        mp = create "mp" mapPlotClass wks
                    "vpXF" : vpx
                    "vpYF" : vpy
                    "vpWidthF" : vpwidth
                    "vpHeightF" : vpheight
                    ;pre-viewport_params                    "vpXF" : .1
                    ;pre-viewport_params                    "vpYF" : .87
                    ;pre-viewport_params                    ;original "vpYF" : .90
                    ;pre-viewport_params                    "vpWidthF" : .80
                    ;pre-viewport_params                    "vpHeightF" : .70
                                "mpProjection" : "MERCATOR"
                                "mpDataBaseVersion" : "NCARG4_1"
                                "mpOutlineBoundarySets" : "USStates"
                                ;"mpOutlineBoundarySets" : "AllBoundaries"
                                "mpPerimOn" : True
                                "mpCenterLatF" : 0.0
                                "mpLambertMeridianF" : in_file@STAND_LON
                                "mpLimitMode" : "CORNERS"
                                "mpLeftCornerLatF" : lat(0,0)
                                "mpLeftCornerLonF" : lon(0,0)
                                "mpRightCornerLatF" : lat(dims(0)-1,dims(1)-1)
                                "mpRightCornerLonF" : lon(dims(0)-1,dims(1)-1)
                                "mpGridSpacingF": 10
                        end create
                   else 
                        mp = create "mp" mapPlotClass wks
                                "vpXF" : vpx
                                "vpYF" : vpy
                                "vpWidthF" : vpwidth
                                "vpHeightF" : vpheight
                                ;pre-viewport_params                    "vpXF" : .1
                                ;pre-viewport_params                    "vpYF" : .87
                                ;pre-viewport_params                    ;original "vpYF" : .90
                                ;pre-viewport_params                    "vpWidthF" : .80
                                ;pre-viewport_params                    "vpHeightF" : .70
                                "mpProjection" : "MERCATOR"
                                "mpDataBaseVersion" : "NCARG4_1"
                                "mpOutlineBoundarySets" : "USStates"
                                ;"mpOutlineBoundarySets" : "AllBoundaries"
                                "mpPerimOn" : True
                                "mpCenterLatF" : 0.0
                                "mpLambertMeridianF" : in_file@CEN_LON
                                "mpLimitMode" : "CORNERS"
                                "mpLeftCornerLatF" : lat(0,0)
                                "mpLeftCornerLonF" : lon(0,0)
                                "mpRightCornerLatF" : lat(dims(0)-1,dims(1)-1)
                                "mpRightCornerLonF" : lon(dims(0)-1,dims(1)-1)
                                "mpGridSpacingF": 10
                        end create
    end if
                end if
        else
                print("Error: no MAP_PROJ attribute in input file")
                return(new(1,graphic))
        end if
        if(opts) 
                atts = getvaratts(opts)
                if(.not.all(ismissing(atts)))
                        attsetvalues(mp,opts)
                end if
        end if

;;; JACK: print final subroutine values
;;; !!! FIND MAP CORNER VIEWPORT LOCATIONS !!!
;;; *NB* these seem to over-ride other (contour,line) viewport values !!! 
  getvalues mp
  "vpXF" : mp_vpx0
  "vpYF" : mp_vpy0
  "vpWidthF" : mp_vpwidth
  "vpHeightF" : mp_vpheight
  end getvalues
  print("    wrf_plot.ncl wrf_new_map VIEWPORT: "+mp_vpwidth+"x"+mp_vpheight+"@"+mp_vpx0+","+mp_vpy0+" " )
;;; empirical results (for williams g2 image) give:
;;; actual image width   = nint( image_size*vpWidth +1 )  pixels
;;; actual image height  = nint( image_size*vpHeight +1 )  pixels
;;; actual NW image x        = nint( image_size*vpX0 -1 )  pixels
;;; actual NW image y  (y increasing toward bottom)   = nint( image_size - image_size*vpY0 -1 )  pixels
;;; actual NW image y  (y increasing toward top)   = nint( image_size*vpY0 +1 )  pixels  (not checked)

        return(mp)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure _GetAnnoInfo(xy[2]:float,tblr[4],side[1]:string,ppos[1]:float,just[1]:string,opos[1]:float)
local t,b,l,r,p0x,p0y,vpw,vph,vpx,vpy
begin
        t = tblr(0)
        b = tblr(1)
        l = tblr(2)
        r = tblr(3)
        p0x = xy(0)
        p0y = xy(1)
        vpw = r-l
        vph = t-b
        vpx = l
        vpy = t
        

        if(fabs(p0x-l).lt.fabs(p0x-r))
;
;       Left side
;       
                if(fabs(p0y-t).lt.fabs(p0y-b))
;
;       Top or Left sides
;
                        if(fabs(p0y-t).lt.fabs(p0x-l))
                                side = "Top"
                                ppos = fabs((p0x - vpx)/vpw)
                                opos =  (p0y - vpy)/vph
                                just = "bottomcenter"
                        else
                                side = "Left"
                                ppos = 1 - fabs((p0y - vpy)/vph)
                                opos = (vpx -p0x)/vpw
                                just = "centerright"
                        end if
                else
;
;       Bottom or Left sides
;
                        if(fabs(p0y-b).lt.fabs(p0x-l))
                                side = "Bottom" 
                                ppos = fabs((p0x - vpx)/vpw)
                                just = "topcenter"
                                opos = ((vpy-vph)-p0y)/vph
                        else
                                side = "Left"
                                ppos = 1 - fabs((p0y - vpy)/vph)
                                opos = (vpx - p0x)/vpw
                                just = "centerright"
                        end if
                end if
        else
;
;       Right side
;
                if(fabs(p0y-t).lt.fabs(p0y-b))
;
;       Top or Right sides
;       
                        if(fabs(p0y-t).lt.fabs(p0x-r))
                                side = "Top"
                                ppos = fabs((p0x - vpx)/vpw)
                                just = "bottomcenter"
                                opos =  (p0y - vpy)/vph
                        else
                                side = "Right"
                                ppos = 1.0 - fabs((p0y - vpy)/vph)
                                just = "centerleft"
                                opos = (p0x - (vpx + vpw ))/vpw
                        end if

                else
;
;       Bottom or Right sides
;
                        if(fabs(p0y-b).lt.fabs(p0x-r))
                                side = "Bottom"
                                ppos = fabs((p0x - vpx)/vpw)
                                just = "topcenter"
                                opos = ((vpy-vph)-p0y)/vph
                        else
                                side = "Right"
                                ppos = 1.0 - fabs((p0y - vpy)/vph)
                                just = "centerleft"
                                opos = (p0x - (vpx + vpw) )/vpw
                        end if
                end if
        end if
end 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure wrf_maplabel(wks[1]:graphic,mp[1]:graphic,options[1]:logical)
local sample_size,vpx,vpy,vpw,vph,gon,gsp,do_lat,latside,latstride,do_lon,lonside,lonstride,lat_lab,lat,lon_lab,lon,pos_lat_x,pos_lon_y,tmp,indexes,anno,txt,dims,wks,plot_type
begin
        if(NhlClassName(mp).eq."mapPlotClass")
                sample_size = 1000
                getvalues mp
                        "vpXF" : vpx
                        "vpYF" : vpy
                        "vpHeightF" : vph
                        "vpWidthF" : vpw
                        "mpGridAndLimbOn" : gon
                        "mpGridSpacingF": gsp
                end getvalues
                b = vpy-vph
                t = vpy
                r = vpx+vpw
                l = vpx
                if(.not.options)
                        do_lon = True
                        do_lat = True
                        latside = "Left"
                        lonside = "Bottom"
                        latstride = 1
                        lonstride = 1
                        fontheight = .013
                        ;original font = "duplex_roman"
                        font = "helvetica"
                else
                        if(isatt(options,"LabelFontHeight"))
                                fontheight = options@LabelFontHeight
                        else
                                fontheight = .013
                        end if
                        if(isatt(options,"LabelFont"))
                                font = options@LabelFont
                        else
                                ;original font = "duplex_roman"
                                font = "helvetica"
                        end if
                        if(isatt(options,"LatSide"))
                                latside = options@LatSide
                        else
                                latside = "Left"
                        end if
                        if(isatt(options,"LonSide"))
                                lonside = options@LonSide
                        else
                                lonside = "Bottom"
                        end if
                        if(isatt(options,"LonLabelsOn"))
                                do_lon = options@LonLabelsOn
                        else
                                do_lon = True
                        end if
                        if(isatt(options,"LatLabelsOn"))
                                do_lat = options@LatLabelsOn
                        else
                                do_lat = True
                        end if
                        if(isatt(options,"LatStride"))
                                latstride = options@LatStride
                        else
                                latstride = 1
                        end if
                        if(isatt(options,"LonStride"))
                                lonstride = options@LonStride
                        else
                                lonstride = 1
                        end if
                end if
                if(gon)
                        lat = fspan(90.0,-90.0,floattoint(180.0/gsp)+1)
                        lon = fspan(0.0,360.0,floattoint(360.0/gsp)+1)
                        lat_lab = new(dimsizes(lat),string)
                        lon_lab = new(dimsizes(lon),string)

                        lat_lab(ind(lat.gt.0.)) = lat(ind(lat.gt.0.)) + "N"
                        lat_lab(ind(lat.lt.0.)) = fabs(lat(ind(lat.lt.0.))) + "S"
                        lat_lab(ind(lat.eq.0.)) = "EQ"

                        lon_lab(ind(lon.eq.180.)) = lon(ind(lon.eq.180.)) + " "
                        lon_lab(ind(lon.gt.180.)) = fabs((lon(ind(lon.gt.180.)) - 360.)) + "W"
                        lon_lab(ind(lon.lt.180.)) = lon(ind(lon.lt.180.)) + "E"
                        lon_lab(ind(lon.eq.0.0.or.lon.eq.360.0)) = "0"
                        if(do_lat) 
                                dims = (/dimsizes(lat),sample_size/)
                                tmp = onedtond(lat,dims(::-1))
                                tmp!0 = "x"
                                tmp!1 = "y"

                                pos_lat_x = onedtond(fspan(0,360.0,sample_size),dims)
                                pos_lat_y = tmp(y|:,x|:)
                                lo = ndtooned(pos_lat_x)
                                la = ndtooned(pos_lat_y)
                                NhlDataToNDC(mp,lo,la,lo,la)
                                
                                pos_lat_x = onedtond(lo,dims)
                                pos_lat_y = onedtond(la,dims)
                                side = new(1,string)
                                ppos = new(1,float)
                                just = new(1,string)
                                opos = new(1,float)

                                do i = 0, dimsizes(lat) -1,latstride
                                        if(any(.not.ismissing(pos_lat_x(i,:))).and..not.all(.not.ismissing(pos_lat_x(i,:))))
                                                indexes = ind(.not.ismissing(pos_lat_x(i,:)))
                                                p0x = (/pos_lat_x(i,indexes(0))/)
                                                p0y = (/pos_lat_y(i,indexes(0))/)
                                                p1x = (/pos_lat_x(i,indexes(dimsizes(indexes)-1))/)
                                                p1y = (/pos_lat_y(i,indexes(dimsizes(indexes)-1))/)
                                                if(indexes(0).ne.0)
                                                        _GetAnnoInfo((/p0x,p0y/),(/t,b,l,r/),side,ppos,just,opos)
                                                        if(any(latside.eq.side))
                                                                txt = create side + "Label" textItemClass wks
                                                                        "txString" : lat_lab(i)
                                                                        "txFont" : font
                                                                        "txFontHeightF" : fontheight
;jack-font - cant see any effect
                        "txFont" : "helvetica"
                                                                end create
                                                                anno = NhlAddAnnotation(mp,txt)
                                                                setvalues anno
                                                                        "amSide" : side
                                                                        "amParallelPosF" : ppos
                                                                        "amJust" : just
                                                                        "amZone" : 2
                                                                        "amOrthogonalPosF" : opos + .02
                                                                end setvalues
                                                        end if
                                                end if
                                                if(indexes(dimsizes(indexes)-1).ne.sample_size-1)
                                                        _GetAnnoInfo((/p1x,p1y/),(/t,b,l,r/),side,ppos,just,opos)
                                                        if(any(latside.eq.side))
                                                                txt = create side + "Label" textItemClass wks
                                                                        "txString" : lat_lab(i)
                                                                        "txFont" : font
                                                                        "txFontHeightF" : fontheight
;jack-font - cant see any effect
                        "txFont" : "helvetica"
                                                                end create
                                                                anno = NhlAddAnnotation(mp,txt)
                                                                setvalues anno
                                                                        "amSide" : side
                                                                        "amParallelPosF" : ppos
                                                                        "amJust" : just
                                                                        "amZone" : 2
                                                                        "amOrthogonalPosF" : opos + .02
                                                                end setvalues
                                                        end if
                                                end if
                                                delete(indexes)
                                        end if
                                end do
                                delete(dims)
                                delete(tmp)
                                delete(pos_lat_x)
                                delete(pos_lat_y)
                                delete(lo)
                                delete(la)
                        end if
                        if(do_lon)
                

                                dims = (/dimsizes(lon),sample_size/)
                                tmp = onedtond(lon,dims(::-1))
                                tmp!0 = "x"
                                tmp!1 = "y"

                                pos_lon_x = tmp(y|:,x|:)
                                pos_lon_y = onedtond(fspan(-90.0,90.0,sample_size),dims)
                                lo = ndtooned(pos_lon_x)
                                la = ndtooned(pos_lon_y)
                                NhlDataToNDC(mp,lo,la,lo,la)
                                
                                pos_lon_x = onedtond(lo,dims)
                                pos_lon_y = onedtond(la,dims)

                                side = new(1,string)
                                ppos = new(1,float)
                                just = new(1,string)
                                opos = new(1,float)

                                do i = 0, dimsizes(lon) -1,lonstride
                                        if(any(.not.ismissing(pos_lon_x(i,:))).and..not.all(.not.ismissing(pos_lon_x(i,:))))
                                                indexes = ind(.not.ismissing(pos_lon_x(i,:)))
                                                p0x = (/pos_lon_x(i,indexes(0))/)
                                                p1x = (/pos_lon_x(i,indexes(dimsizes(indexes)-1))/)
                                                p0y = (/pos_lon_y(i,indexes(0))/)
                                                p1y = (/pos_lon_y(i,indexes(dimsizes(indexes)-1))/)

                                                if(indexes(0).ne.0)
                                                        _GetAnnoInfo((/p0x,p0y/),(/t,b,l,r/),side,ppos,just,opos)
                                                        if(any(lonside.eq.side))
                                                                txt = create side + "Label" textItemClass wks
                                                                        "txString" : lon_lab(i)
                                                                        "txFont" : font
                                                                        "txFontHeightF" : fontheight
;jack-font - cant see any effect
                        "txFont" : "helvetica"
                                                                end create
                                                                anno = NhlAddAnnotation(mp,txt)
                                                                setvalues anno
                                                                        "amSide" : side
                                                                        "amParallelPosF" : ppos
                                                                        "amJust" : just
                                                                        "amZone" : 2
                                                                        "amOrthogonalPosF" : opos + .02
                                                                end setvalues
                                                        end if
                                                end if

                                                if(indexes(dimsizes(indexes)-1).ne.sample_size-1)
                                                        _GetAnnoInfo((/p1x,p1y/),(/t,b,l,r/),side,ppos,just,opos)
                                                        if(any(lonside.eq.side))
                                                                txt = create side + "Label" textItemClass wks
                                                                        "txString" : lon_lab(i)
                                                                        "txFont" : font
                                                                        "txFontHeightF" : fontheight
;jack-font - cant see any effect
                        "txFont" : "helvetica"
                                                                end create
                                                                anno = NhlAddAnnotation(mp,txt)
                                                                setvalues anno
                                                                        "amSide" : side
                                                                        "amParallelPosF" : ppos
                                                                        "amJust" : just
                                                                        "amZone" : 2
                                                                        "amOrthogonalPosF" : opos + .02
                                                                end setvalues
                                                        end if
                                                end if
                                                delete(indexes)
                                        end if
                                end do
                        end if
                end if
        else
                print("wrf_maplabel: Not a map")
        end if
end
