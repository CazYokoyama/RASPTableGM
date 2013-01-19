;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;JACK - ADDED FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  BELOW FUNCTIONS HAD BEEN ADDED TO wrf_plot.ncl, NOW MOVED HERE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  START OF GENERAL UTILITY FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;---------------------------------------------------------------------------------
;;; STRING GREP FUNCTION - count existences of "pattern" in "instring" (=> 0=false)
  undef("string_pattern_grep")
  function string_pattern_grep( instring:string,pattern:string )
  local instring,pattern,count, string_chars,instring_length,pattern_length
  begin
    count = 0
    string_chars = stringtochar( instring )
    instring_length = dimsizes(stringtochar(instring))-1
    pattern_length = dimsizes(stringtochar(pattern))-1
    do kk=0,(instring_length-pattern_length)
      ; bombs here with "subscript out of range" if pattern not found 
      if( string_chars(kk:kk-1+pattern_length).eq.pattern ) then
        count = count + 1
      end if 
    end do
    return (count)
  end
;;;---------------------------------------------------------------------------------
;;; STRING REPLACEMENT FUNCTION - create "outstring" by replacing "target" with "replacement" in "instring"
  undef("string_target_replace")
  function string_target_replace( instring:string,target:string,replacement:string )
  ; single replacement only (not global) - case-sensitive - replacement can be null
  local instring,target,replacement,outstring, string_chars,instring_length,target_length
  begin
    string_chars = stringtochar( instring )
    instring_length = dimsizes(stringtochar(instring))-1
    target_length = dimsizes(stringtochar(target))-1
    outstring = instring
    ;4test: print ( "string_chars,instring_length,target_length= "+string_chars+","+instring_length+","+target_length )
    kk = 0
    do while ( kk .le. instring_length-target_length )
    ;old do kk=0,(instring_length-target_length-1)
      ;4test: print ( "kk,string_chars,target= "+kk+","+string_chars(kk:kk-1+target_length)+","+target )
      if( string_chars(kk:kk-1+target_length).eq.target ) then
        if( kk .eq. 0 ) then
          outstring = replacement+chartostring(string_chars(kk+target_length:))
        else
          outstring = chartostring(string_chars(0:kk-1))+replacement+chartostring(string_chars(kk+target_length:))
        end if
        ; for single replacement:
        break
      end if 
      kk = kk +1
    end do
    ;4test: print ( "end do" )
    return (outstring)
  end
;;;---------------------------------------------------------------------------------
;;; STRING REPLACEMENT FUNCTION - create "outstring" by replacing "target" with "replacement" in "instring"
  undef("string_target_replace_global")
  function string_target_replace_global( instring:string,target:string,replacement:string )
  ; UNTESTED - case-sensitive - replacement can be null
  local instring,target,replacement,outstring, string_chars,instring_length,target_length
  begin
    outstring = instring
    string_chars = stringtochar( outstring )
    outstring_length = dimsizes(stringtochar(outstring))-1
    target_length = dimsizes(stringtochar(target))-1
    replacement_length = dimsizes(stringtochar(replacement))-1
    ;4test: print ( "string_chars,outstring_length,target_length,replacement_length= "+string_chars+","+outstring_length+","+target_length+","+replacement_length )
    kk = 0
    do while ( kk .le. outstring_length-target_length )
      ;4test: print ( "kk,string_chars,target= "+kk+","+string_chars(kk:kk-1+target_length)+","+target )
      if( string_chars(kk:kk-1+target_length).eq.target ) then
        if( kk .eq. 0 ) then
          outstring = replacement+chartostring(string_chars(kk+target_length:))
        else
          outstring = chartostring(string_chars(0:kk-1))+replacement+chartostring(string_chars(kk+target_length:))
        end if
        ; for single replacement:         break
        ; for global replacement: 
        delete ( string_chars )
        string_chars = stringtochar( outstring )
        outstring_length = dimsizes(stringtochar(outstring))-1
        kk = kk +replacement_length -1
        ;4test: print ( "outstring="+outstring+"=" )
      end if 
      kk = kk +1
      ;4test: print ( "kk,outstring_length="+kk+","+outstring_length )
    end do
    ;4test: print ( "end do" )
    return (outstring)
  end
;;;---------------------------------------------------------------------------------
;;; EXTRACT STRING FIELD FROM INPUT STRING (null returned if string field non-existent)
;;;    delimiter = delimiterchar (must be single character) OR CR OR EndOfLine  (first field = 1 !)
  undef("extract_string_field")
  function extract_string_field( instring:string,fieldno:integer,delimiterchar:string )
  local instring,fieldno,delimiterchar, string_chars,instring_length, kk,kfield,kfirst,klast,carriagereturnchar
  begin
    string_chars = stringtochar( instring )
    instring_length = dimsizes(stringtochar(instring))-1
    ;4test: print ( "string_chars,instring_length= "+string_chars+","+instring_length )
    carriagereturnchar = systemfunc( "echo ''" )
    kk = 0
    kfirst = 0
    klast = -2
    kfield = 0
    do while ( kk .lt. instring_length )
      ;4test: print ( "kk,kfield,kfirst,klast= "+kk+","+kfield+","+kfirst+","+klast )
      ;;; treat delimiter or CarriageReturn
      if( string_chars(kk:kk) .eq. delimiterchar .or. string_chars(kk:kk) .eq. carriagereturnchar ) then
        kfield = kfield +1
        kfirst = klast +2
        klast = kk -1
        if ( kfield .eq. fieldno ) then
          break
        end if
      end if
      ;;; treat end of line reached
      if( kk .eq. (instring_length -1) ) then
        kfield = kfield +1
        kfirst = klast +2
        klast = instring_length -1
        if ( kfield .eq. fieldno ) then
          break
        end if
      end if
      kk = kk +1
    end do
    ;4test: print ( "END kk,kfield,kfirst,klast= "+kk+","+kfield+","+kfirst+"="+klast+"=" )
    if ( kfield .eq. fieldno ) then
      outstring = chartostring( string_chars(kfirst:klast) )
    else
      outstring = ""
    end if
    return (outstring)
  end
;;;---------------------------------------------------------------------------------
;*** ROUTINE TO DETERMINE IF SUBSTRING EXISTS IN A STRING (from Dennis Shea)
undef("isStrSubset")
function isStrSubset(S[1]:string, s[1]:string)
; return True or False is "s" is a subset of "S" 
local SC, sc, nsc, nSC, n, sTF
begin
   SC  = stringtochar(S)     ; main
   sc  = stringtochar(s)     ; subset
   nSC = dimsizes( SC ) - 2  ; extra 'end of char' at end
   nsc = dimsizes( sc ) - 2
   sTF = False
   if (nsc.le.nSC) then      ; nsc must be <= nSC
       do n=0,nSC-nsc
          if (all(SC(n:n+nsc).eq.sc(0:nsc)) ) then
              sTF = True
              return (sTF)
          end if
       end do
   end if
   return (sTF)
end
;;;---------------------------------------------------------------------------------
;*** ROUTINE TO RETURN INDICES OF SUBSTRING IN A STRING (from Dennis Shea)
undef("indStrSubset")
function indStrSubset(S[1]:string, s[1]:string)
; return the indices of the characters
; of "S" of which "s" is a subset. 
local SC, sc, nsc, nSC, n, ii
begin
   SC  = stringtochar(S)     ; main
   sc  = stringtochar(s)     ; subset
   nSC = dimsizes( SC ) - 2  ; extra 'end of char' at end
   nsc = dimsizes( sc ) - 2
   if (nsc.le.nSC) then      ; nsc must be <= nSC
       do n=0,nSC-nsc
          if (all(SC(n:n+nsc).eq.sc(0:nsc)) ) then
              ii  = ispan(n,n+nsc,1)
              return( ii )
          end if
       end do
   end if
   ii = new ( 1, "integer", -999)
   return (ii)
end
;;;---------------------------------------------------------------------------------
;;; BLIP ADDITION - added function
;;; ROUTINE TO SPLIT STRING INTO ARRAY BASED ON INPUT DELIMITER CHARACTER (single character only)
  undef("split_string_into_array")
  function split_string_into_array( inputstring:string, delimiter:string )
  local string_chars, temp_strings, string_array, string_max, nstrings, ichar,ichar1,ichar2
  begin
        ;;; convert delimiter-delimited environmental string into parameter array (what a mess!)
        ;4testprint: print ( "INPUTSTRING= "+inputstring )
        string_chars = stringtochar( inputstring )
        string_max  = dimsizes(string_chars)-2
        ;;; temporary array determines maximum parameter names
        temp_strings = new( (/300/), string)
        ichar1=0
        nstrings=-1
        do ichar=1,string_max
          ; allow for either delimiter or no-delimiter at end of string
          if( string_chars(ichar).eq.delimiter .or. ichar.eq.string_max) then
            nstrings = nstrings +1
            if( ichar.eq.string_max) then
              ichar2 = string_max
            else
              ichar2 = ichar-1
            end if
            temp_strings(nstrings) = chartostring( string_chars(ichar1:ichar2) ) 
            ;4testprint: print ( "NAME= "+nstrings+" : "+ichar1+"-"+ichar2+" => "+temp_strings(nstrings) )
            ichar1= ichar+1
          end if
        end do    
        string_array = new( (nstrings+1), string)
        do iname=0,nstrings  
          string_array(iname) = temp_strings(iname)
        end do    
    return(string_array)
  end
;;;---------------------------------------------------------------------------------
;;; BREAK STRING INTO TWO PIECES BASED ON _LAST_ OCCURENCE OF SPECIFIED DELIMITER (single char only)
;;; used to break full filepathname into path and filename (delimiter NOT included in basestring or tailstring)
;;; (if delimiter not found tailstring equals entire input string)
  undef("split_string_in2")
  procedure split_string_in2( instring:string,delimitstring:string, basestring:string,tailstring:string )
  local string_chars, string_max, ichar,icharend
  begin
        ;4testprint: print ( "INSTRING= "+instring )
        string_chars = stringtochar( instring )
        string_max  = dimsizes(string_chars)-2
        icharend=0
        do ichar=1,string_max
          if( string_chars(ichar).eq.delimitstring) then
            icharend = ichar
          end if
        end do
        basestring = chartostring( string_chars(0:icharend-1) )
        tailstring = chartostring( string_chars(icharend+1:) )
        ;4testprint: print ( "BASE,TAIL= "+basestring+" & "+tailstring )
  end
;;;---------------------------------------------------------------------------------
;;; ROUTINE TO TRIM STRING, ELIMINATING TRAILING BLANK CHARACTERS
  undef("trim_string")
  function trim_string( inputstring:string )
  local string_chars, string_max, ichar,icharend
  begin
        ;4testprint: print ( "INPUTSTRING= "+inputstring )
        string_chars = stringtochar( inputstring )
        string_max  = dimsizes(string_chars)-2
        icharend=0
        do ichar=1,string_max
          if( string_chars(ichar).ne." ") then
            icharend = ichar
          end if
        end do    
    outstring = chartostring( string_chars(0:icharend) )
    return(outstring)
  end
;;;---------------------------------------------------------------------------------
;;;  FIND NEAREST INTEGER VALUE
  undef("nint")
  function nint( a:float )
  local i
  begin
    if ( a .lt. 0.5 ) then
      i = floattointeger( a-0.5)
    else
      i = floattointeger( a+0.5)
    end if
    return(i)
  end
;;;---------------------------------------------------------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  END OF GENERAL UTILITY FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;---------------------------------------------------------------------------------
;*** ROUTINE TO WRITE CONTOUR SPACING INFO ON PLOT
  undef("anno_ter_contour" )
  procedure anno_ter_contour(wks[1]:graphic,contour_ter[1]:graphic,units:string)
  local lev_title
  begin
       getvalues contour_ter
        "cnLevelSpacingF" : cnLevelSpacing
       end getvalues
       ;4testprint:  print("    TER LEVEL SPACING= cnLevelSpacing= "+cnLevelSpacing+" " )
            	lev_title = "Terrain contours: " + cnLevelSpacing + " " + units
     	tertxt = create "lev_title" textItemClass wks
     		"txFuncCode" : "~"
     		"txString" : lev_title
     		"txFontHeightF" : .012
     		"txFont" : "helvetica"
        ;; blank out existing plotting in text area
     		"txPerimOn" : True
     		"txBackgroundFillColor" : "white"
     		"txPerimSpaceF" : 0.35    ; default=0.5 - if too large will blank part of plot or colorbar
     		"txPerimThicknessF" : 0.0    ; default=1.0
     	end create
     	anno = NhlAddAnnotation(contour_ter,tertxt)
     	setvalues anno
     		"amResizeNotify" : True
     		"amZone" : 1  ; plot perimeter
     		"amSide" : "Bottom"
                "amJust" : "CenterRight" ; move inside plot edge so less change of overlapping fixed flag
                ;old "amJust" : "CenterCenter"
     		"amParallelPosF" : 1.0  ; right-edge
                ;older "amJust" : "CenterLeft"
                ;older "amParallelPosF" : 0.5  ; centered
     		"amOrthogonalPosF" : -0.015  ; moved down from perimeter
     		;old "amOrthogonalPosF" : -0.04  ; moved down from perimeter
     	end setvalues
  end
;;;---------------------------------------------------------------------------------
;*** ROUTINE TO WRITE PATTERN/STIPPLE INFO ON PLOT
  undef("anno_pattern" )
  procedure anno_pattern(wks[1]:graphic,plot[1]:graphic,title:string)
  begin
     	titletxt = create "pattern_title" textItemClass wks
     		"txFuncCode" : "~"
     		"txString" : title
     		"txFontHeightF" : .010
     		"txFont" : "helvetica"
     	end create
     	anno = NhlAddAnnotation(plot,titletxt)
     	setvalues anno
     		"amResizeNotify" : True
     		"amZone" : 1  ; plot perimeter
     		"amSide" : "Bottom"
                "amJust" : "CenterCenter"
                ;old "amJust" : "CenterRight"
     		"amParallelPosF" : 0.0  ; left-edge
     		;old "amParallelPosF" : 0.5  ; centered
     		"amOrthogonalPosF" : -0.04  ; moved down from perimeter
     	end setvalues
  end
;;;---------------------------------------------------------------------------------
;*** ROUTINE TO WRITE EXTRA LABELBAR INFO
;;; writes units and (if appropriate) fixed to side of label bar (assumes units not written to label bar itself)
  undef("add_labelbar_text" )
  procedure add_labelbar_text( wks[1]:graphic, plot[1]:graphic, title:string, lfixedcolor:numeric )
  local vpXF,vpYF,vpWidthF,vpHeightF,pmLabelBarWidthF,pmLabelBarHeightF,pmLabelBarParallelPosF,pmLabelBarOrthogonalPosF, libtxtres,xNDCleft,xNDCright,yNDCmid,xNDC,yNDC
  begin
        ;;; SET BASIC TEXT RESOURCES
        lbtxtres = True
        lbtxtres@txFuncCode    = "~"  
        ;;; DETERMINE LABEL BAR SIZE AND POSITION
        getvalues plot
         "vpXF" : vpXF
         "vpYF" : vpYF
         "vpWidthF" : vpWidthF
         "vpHeightF" : vpHeightF
         "pmLabelBarWidthF" : pmLabelBarWidthF
         "pmLabelBarHeightF" : pmLabelBarHeightF
         "pmLabelBarParallelPosF" : pmLabelBarParallelPosF
         "pmLabelBarOrthogonalPosF" : pmLabelBarOrthogonalPosF
        end getvalues
        ;left-edge
        xNDCleft = 0.5*( 1.0 - pmLabelBarWidthF )
        ;right-edge
        xNDCright = 1.0 - 0.5*( 1.0 - pmLabelBarWidthF )
        ;mid-side
        yNDCmid = vpYF - vpHeightF - pmLabelBarOrthogonalPosF - 0.5*pmLabelBarHeightF
        ;4test  print(" xNCDright,left= "+xNDCright+","+xNDCleft+" " )
        ;4test  print(" yNDCmid= "+yNDCmid+" " )

        ;;; ADD UNITS TEXT
        lbtxtres@txFontHeightF = 0.015                  
        lbtxtres@txFont = "helvetica"
        ;;; add left side units text
        lbtxtres@txJust = "CenterRight"          ; Default is "CenterCenter".
        ;reversed xNDC = xNDCleft
        ;reversed yNDC = yNDCmid + lbtxtres@txFontHeightF
        xNDC = xNDCleft - lbtxtres@txFontHeightF       
        yNDC = yNDCmid
        ;old yNDC = yNDCmid - 0.5*lbtxtres@txFontHeightF
        gsn_text_ndc ( wks, title, xNDC,yNDC, lbtxtres )   
        ;;; add right side units text
        lbtxtres@txJust = "CenterLeft"          ; Default is "CenterCenter".
        ;reversed xNDC = xNDCright
        xNDC = xNDCright + lbtxtres@txFontHeightF
        gsn_text_ndc ( wks, title, xNDC,yNDC, lbtxtres )   

        ;;; ADD  FIXED TEXT
        if( lfixedcolor .eq. 1 ) then
          lbtxtres@txFontHeightF = 0.015                  
          lbtxtres@txFont = "helvetica-bold"
          ;;; add left side fixed text
          lbtxtres@txJust = "CenterRight"          ; Default is "CenterCenter".
          ;reversed xNDC = xNDCleft 
          ;reversed yNDC = yNDCmid - lbtxtres@txFontHeightF
          xNDC = xNDCleft - lbtxtres@txFontHeightF
          yNDC = yNDCmid 
          ;old=fixed_only yNDC = yNDCmid + 1.5*lbtxtres@txFontHeightF
          gsn_text_ndc ( wks, "~I~ FIXED~C~~C~COLOR", xNDC,yNDC, lbtxtres )   
          ;alt gsn_text_ndc ( wks, "~I~FIXED~C~~C~ TINT", xNDC,yNDC, lbtxtres )   
          ;old=fixed_only gsn_text_ndc ( wks, "FIXED", xNDC,yNDC, lbtxtres )   
          ;;; add right side fixed text
          lbtxtres@txJust = "CenterLeft"          ; Default is "CenterCenter".
          ;reversed xNDC = xNDCright
           xNDC = xNDCright + lbtxtres@txFontHeightF
          gsn_text_ndc ( wks, "~I~ FIXED~C~~C~COLOR", xNDC,yNDC, lbtxtres )   
          ;old=fixed_only gsn_text_ndc ( wks, "FIXED", xNDC,yNDC, lbtxtres )   
       end if

  end
;;;---------------------------------------------------------------------------------
;*** ROUTINE TO TEST ANNOTATION WRITING
;;; demonstrates that annotation scaled by viewport of plot it is attached to
  undef("anno_test" )
  procedure anno_test( wks[1]:graphic, plot[1]:graphic, title:string )
  begin
     	titletxt = create "pattern_title" textItemClass wks
     		"txFuncCode" : "~"
     		"txString" : title
     		"txFontHeightF" : .010
     		"txFont" : "helvetica"
     	end create
     	anno = NhlAddAnnotation(plot,titletxt)
     	setvalues anno
     		"amResizeNotify" : True
;OK-SEcorner    		"amZone" : 1  ; plot perimeter
;sameas_amZone=1:   "amZone" : 6  ;
;sameas_amZone=1:
   "amZone" : 6  ;
     		"amSide" : "Bottom"
                "amJust" : "CenterCenter"
     		"amParallelPosF" : 0.0  
     		"amOrthogonalPosF" : 0.0 
     	end setvalues
  end
;;;---------------------------------------------------------------------------------
;;; ROUTINE TO PRINT OBJECT VALUES
  undef("query_object" )
  procedure query_object( wks[1]:graphic, plot[1]:graphic, parameter:string )
  begin
       getvalues plot
;OK        "cnLevelSpacingF" : cnLevelSpacing
        parameter : parameter_value
       end getvalues
       print(" query_object "+parameter+" = "+parameter_value+" " )
  end
;;;---------------------------------------------------------------------------------
undef ("PrintWallClockElapseTime")
procedure PrintWallClockElapseTime(wcStrt, title:string)
;;; modified from $NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl
;original procedure wallClockElapseTime(wcStrt:string, title:string)
; compute *Wall Clock* elapsed time in seconds
; does NOT handle change of year or Feb-March of leap year
; Usage:     wcStrt = systemfunc("date")
;                   :    ; one or more statements [usually a block of code]
;            PrintWallClockElapseTime(wcStrt, "short_info")
local wcNow, wcStrt_c, tSTRT, wcNow_c, tNOW, sec, NLINE, dayspermonth
begin
  wcNow     = systemfunc("date")   ; current ("now") time
  wcStrt_c  = stringtochar(wcStrt)
  tSTRT     = stringtointeger((/wcStrt_c( 8: 9)/))*86400 \
            + stringtointeger((/wcStrt_c(11:12)/))*3600  \
            + stringtointeger((/wcStrt_c(14:15)/))*60    \
            + stringtointeger((/wcStrt_c(17:18)/))
  wcNow_c   = stringtochar(wcNow)
  tNOW      = stringtointeger((/wcNow_c( 8: 9)/))*86400  \
            + stringtointeger((/wcNow_c(11:12)/))*3600   \
            + stringtointeger((/wcNow_c(14:15)/))*60     \
            + stringtointeger((/wcNow_c(17:18)/))
  secElapseTime = tNOW-tSTRT
;jack - add month dependence
  if ( secElapseTime .le. 0 ) then
    dayspermonth = (/31,28,31,30,31,30,31,31,30,31,30,31/)
    secElapseTime = secElapseTime + stringtointeger((/wcStrt_c( 8: 9)/))*86400  
  end if
  NLINE     = inttochar(10)   ; new line character
  print ("--- "+title+" "+wcNow+" WallClockElapseTime= "+secElapseTime+" sec")
  ;original print (NLINE+ \
  ;original        "=====> Wall Clock Elapsed Time: "+title+": "+   \
  ;original       secElapseTime+" seconds <====="+NLINE)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;JACK - STREAMLINE PLOTTING FUNCTION
;jack - (based on function wrf_new_vector)
undef("wrf_new_streamline")
function wrf_new_streamline( wks[1]: graphic, data_u[*][*]:numeric, data_v[*][*]:numeric, opt_args[1]:logical, vpx[1]:float,vpy[1]:float,vpwidth[1]:float,vpheight[1]:float )
;pre-viewport_params function wrf_new_streamline(wks[1]: graphic, data_u[*][*]:numeric, data_v[*][*]:numeric, opt_args[1]:logical)
local dims
begin

;;;JACK - print to indicate this routine being used
; print("    wrf_plot.ncl FUNCTION wrf_new_streamline ENTERED")

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

        if((opts).and.(isatt(opts,"NumStreamlines")))
                num_streamlines = opts@NumStreamlines
                delete(opts@NumStreamlines)
        else
                num_streamlines = 25.0
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

        stream = create "stream" streamlinePlotClass wks
                "stVectorFieldData" : vf
                "vpXF" : vpx
                "vpYF" : vpy
                "vpWidthF" : vpwidth
                "vpHeightF" : vpheight 
                ;pre-viewport_params                "vpXF" : .1
                ;pre-viewport_params                "vpYF" : .87
                ;pre-viewport_params                ;original "vpYF" : .90
                ;pre-viewport_params                "vpWidthF" : width
                ;pre-viewport_params                "vpHeightF" : height 
        end create

        _SetMainTitle(wks,stream,data_u,opts)

        if(opts) 
                atts = getvaratts(opts)
                if(.not.all(ismissing(atts)))
                        attsetvalues(stream,opts)
                end if
        end if

    ;;4TESTPRINT of streamline values used
    ; getvalues stream
    ;   "stMinLineSpacingF" : stMinLineSpacingF
    ;   "stStepSizeF" : stStepSizeF
    ;  "stLineStartStride" : stLineStartStride
    ;  "stCrossoverCheckCount" : stCrossoverCheckCount
    ;  "stArrowStride" : stArrowStride 
    ;   end getvalues
    ;   print( "--STREAMLINE stMinLineSpacingF="+stMinLineSpacingF+" stStepSizeF="+stStepSizeF+" stLineStartStride="+stLineStartStride+" stCrossoverCheckCount="+stCrossoverCheckCount+" stArrowStride="+stArrowStride )

        return(stream)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;jack - add dotted frame of width kframe points to indicate boundary region
;jack - now superceded for operational rasp.ncl by use of "add_frame"
;jack - but keep since for some reason needed by topo.ncl so may have hidden capabilities
undef("wrf_add_frame")
procedure wrf_add_frame( wks:graphic,  map:graphic, data[*][*]:numeric, opt_args[1]:logical, kframe[*]:numeric, vpwidth[1]:float,vpheight[1]:float )
;pre-viewport_params procedure wrf_add_frame( wks:graphic,  map:graphic, data[*][*]:numeric, opt_args[1]:logical, kframe[*]:numeric )
local opts,dims,ratio,width,height,xx,yy
begin

        opts =  opt_args
        dims = dimsizes(data)
        if((opts).and.(isatt(opts,"AspectRatio")))
                ratio = opts@AspectRatio
    delete(opts@AspectRatio)
        else
;jack - shouldnt be an integer divide here !
    ratio = (dims(0)+0.00) / (dims(1)+0.00)
;original       ratio = dims(0)/dims(1)
;jack - dont constrain ratio
;jack-    if(ratio .gt. 1.2) then
;jack-        ratio = 1.2
;jack-    end if
;jack-    if(ratio .lt. .6667) then
;jack-       ratio = .6667
;jack-    end if
        end if
        if(ratio .gt. 1) 
                height = vpheight
                width = vpwidth * 1.0/ratio
                ;pre-viewport_params                width = .65 * 1.0/ratio
                ;pre-viewport_params                height = .65
        else
                width = vpwidth
                height = vpheight * ratio
                ;pre-viewport_params                width = .85 
                ;pre-viewport_params                height = .85 * ratio
        end if
  ;;; get viewport info
        getvalues map
                "vpXF" : vpx
                "vpYF" : vpy
                "vpHeightF" : vph
                "vpWidthF" : vpw
        end getvalues
;       if((opts).and.(isatt(opts,"LineThickness")))
;               line_thicknesses = line_thicknesses*opts@LineThickness
;    delete(opts@LineThickness)
;       end if
   ;;; compute corner points 
   xx = new ( 5, float )
   yy = new ( 5, float )
   ;;; kframe is single value for constant frame, 4 values for variable frame
   kframedims = dimsizes(kframe)
   if( kframedims(0) .eq. 1 ) then
   xx(0) =  vpx + vpw* kframe(0) / ( dims(1)-1 ) 
   yy(0) =  vpy - vph +vph* kframe(0) / ( dims(0)-1 ) 
   xx(1) =  vpx + vpw* (  dims(1)-1-kframe(0) ) / ( dims(1)-1 ) 
   yy(1) =  vpy - vph +vph* kframe(0) / ( dims(0)-1 ) 
   xx(2) =  vpx + vpw* ( dims(1)-1-kframe(0) ) / ( dims(1)-1 ) 
   yy(2) =  vpy - vph +vph* ( dims(0)-1-kframe(0) ) / ( dims(0)-1 ) 
   xx(3) =  vpx + vpw* kframe(0) / ( dims(1)-1 ) 
   yy(3) =  vpy - vph +vph* ( dims(0)-1-kframe(0) ) / ( dims(0)-1 ) 
   xx(4) =  vpx + vpw* kframe(0) / ( dims(1)-1 )  
   yy(4) =  vpy - vph +vph* kframe(0) / ( dims(0)-1 ) 
   end if
   if( kframedims(0) .eq. 4 ) then
  ;;; kframe = xl,yb, xr,yt - USES NAMELIST FORTRAN INDEXS ! AND ALLOWS FOR MASS GRID OFFSET !
  ;;; *NB* this assumes that fine:coarse grid spacing is 3:1  
       xx(0) =  vpx + vpw* ( kframe(0) -1.333) / ( dims(1)-1 ) 
       yy(0) =  vpy - vph +vph* ( kframe(1) -1.333) / ( dims(0)-1 ) 
       xx(1) =  vpx + vpw* ( kframe(2) -1.667) / ( dims(1)-1 ) 
       yy(1) =  vpy - vph +vph* ( kframe(1) -1.333) / ( dims(0)-1 ) 
       xx(2) =  vpx + vpw* ( kframe(2) -1.667) / ( dims(1)-1 ) 
       yy(2) =  vpy - vph +vph* ( kframe(3) -1.667) / ( dims(0)-1 ) 
       xx(3) =  vpx + vpw* ( kframe(0) -1.333) / ( dims(1)-1 ) 
       yy(3) =  vpy - vph +vph* ( kframe(3) -1.667) / ( dims(0)-1 ) 
       xx(4) =  vpx + vpw* ( kframe(0) -1.333) / ( dims(1)-1 )  
       yy(4) =  vpy - vph +vph* ( kframe(1) -1.333) / ( dims(0)-1 ) 
    ;bad    ;;; my reasoning first gave following (and this is centered and gives width of 1 when xl-xr=2)
    ;bad    ;;;    but then CA coastline on grid 1 at panoche grid2 line does not match grid2 edge (for X grid1 1-39 with subgrid 12-28)
    ;bad    ;;; finally realized that mass pt on coarse grid is one fine grid spacing inward from perimeter fine grid pt
    ;bad  xx(0) =  vpx + vpw* ( kframe(0) -1.) / ( dims(1)-1 ) 
    ;bad  yy(0) =  vpy - vph +vph* ( kframe(1) -1.) / ( dims(0)-1 ) 
    ;bad  xx(1) =  vpx + vpw* ( kframe(2) -2.) / ( dims(1)-1 ) 
    ;bad  yy(1) =  vpy - vph +vph* ( kframe(1) -1.) / ( dims(0)-1 ) 
    ;bad  xx(2) =  vpx + vpw* ( kframe(2) -2.) / ( dims(1)-1 ) 
    ;bad  yy(2) =  vpy - vph +vph* ( kframe(3) -2.) / ( dims(0)-1 ) 
    ;bad  xx(3) =  vpx + vpw* ( kframe(0) -1.) / ( dims(1)-1 ) 
    ;bad  yy(3) =  vpy - vph +vph* ( kframe(3) -2.) / ( dims(0)-1 ) 
    ;bad  xx(4) =  vpx + vpw* ( kframe(0) -1.) / ( dims(1)-1 )  
    ;bad  yy(4) =  vpy - vph +vph* ( kframe(1) -1.) / ( dims(0)-1 ) 
    end if
   ;4testprint print ( "dims="+dims(1)+" "+dims(0) )
   ;4testprint print ( "ratio,width,height="+ratio+" "+width+" "+height )
   ;4testprint print ( "vpx vpy vpw vph="+vpx+" "+vpy+" "+vpw+" "+vph )
   ;4testprint print ( "xx="+xx(0)+" "+xx(1)+" "+xx(2)+" "+xx(3)+" "+xx(4) )
   ;4testprint print ( "yy="+yy(0)+" "+yy(1)+" "+yy(2)+" "+yy(3)+" "+yy(4) )
  ;;; draw line
   gsn_polyline_ndc ( wks, xx,yy, opts ) 
   ;unused ; Trying to use NhlNDCPolyline gives only 3 sides !?
   ;unused ; Create a blank plot object to place the primitives on.
   ;unused    cid = create "canvas" logLinPlotClass wks
   ;unused    end create
   ;unused      mapframe = create "mapframe" graphicStyleClass wks
   ;unused   "gsLineColor" : "white"
   ;unused   "gsLineThicknessF" : 3
   ;unused      end create
   ;unused ;only3side!?  NhlNDCPolyline( cid, mapframe, xx, yy )
  ;;; cleanup
   delete ( xx )
   delete ( yy )
end
;---------------------------------------------------------------------------------
;;; BLIP ADDITION - added function
undef("blip_new_map")
function blip_new_map( wks[1]:graphic,alat[*][*]:float,alon[*][*]:float,isize:integer,jsize:integer,plat1,plat2,plon, opt_args[1]:logical, vpx[1]:float,vpy[1]:float,vpwidth[1]:float,vpheight[1]:float )
;;; modified from wrf_new_map in wrf_plot.ncl (eliminating non-lambert-conformal projections)
;;; ASSUMES RUC/regriddedETA LAMBERT CONFORMAL PROJECTION PARAMETERS
local opts
begin
  ;;;JACK - print to indicate this routine being used
  ;4test print("    blip_plot.ncl FUNCTION blip_new_map ENTERED")
   opts = opt_args
;JACK - GEOGRAPHIC OUTLINES
us_states = (/\
   "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", \
   "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", \
   "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", \
   "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", \
   "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming" \
/)
                        mp = create "mp" mapPlotClass wks
                    "vpXF" : vpx
                    "vpYF" : vpy
                    ;original "vpYF" : .90
                    "vpWidthF" : vpwidth
                    "vpHeightF" : vpheight
                                "mpProjection" : "LAMBERTCONFORMAL"
            ;;; set geophysical coastline used
                                "mpDataBaseVersion" : "NCARG4_1"      ; standard
            ;HiResCoastline:                    "mpDataBaseVersion" : "RANGS"         ; high-resolution (requires datafiles in $NCARG_ROOT/lib/ncarg/database/rangs)
;JACK - GEOGRAPHIC OUTLINES
;;; to get Country+USstate outline had to use "National" and add states to mpOutlineSpecifiers
;;;    since using "AllBoundaries" also plotted UScounty outlines
        "mpOutlineBoundarySets" : "National"
  "mpOutlineSpecifiers" : "Conterminous US . " + us_states
        ;4test: "mpDataResolution" : "FinestResolution"
        ;jack-no_country: "mpOutlineBoundarySets" : "USStates"
  ;jack-country+UScounty:       "mpOutlineBoundarySets" : "AllBoundaries"
  ;bad  "mpOutlineSpecifiers" : "United States . " + us_states    ; dont get n. nv line in canv plot (due to lying along lat. line??)

                                "mpPerimOn" : True
;;; BLIP CHANGE - USE INTERNALLY SET PROJECTION PARAMETERS
                                "mpLambertParallel1F" : plat1
                                "mpLambertParallel2F" : plat2
                                "mpLambertMeridianF"  : plon

                                "mpLimitMode" : "CORNERS"
                                "mpLeftCornerLatF" : alat(0,0)
                                "mpLeftCornerLonF" : alon(0,0)
                                "mpRightCornerLatF" : alat(jsize-1,isize-1)
                                "mpRightCornerLonF" : alon(jsize-1,isize-1)
;jack - empirically, this controls lat/long line spacing for my press level plots if mpGridSpacingF not set
                                "mpGridSpacingF": 10
                        end create
;;; JACK - TO PRINT NAMES OF THE AVAILABLE GEOGRAPHIC OUTLINES IN DATABASE
;;default:  mp@mpDataSetName    = "Earth..2"
;  getvalues mp              
;  "mpAreaNames" : area_names 
;  end getvalues 
;  print(area_names)
;; JACK - EXAMPLE OF SELECTING CANADIAN PROVINCE OUTLINES
;  mp@mpOutlineSpecifiers = area_names(526:616) 
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
  print("    blipmap_jack.ncl blip_new_map VIEWPORT: "+mp_vpwidth+"x"+mp_vpheight+"@"+mp_vpx0+","+mp_vpy0+" " )
;;; empirical results (for williams g2 image) give:
;;; actual image width   = nint( image_size*vpWidth +1 )  pixels
;;; actual image height  = nint( image_size*vpHeight +1 )  pixels
;;; actual NW image x        = nint( image_size*vpX0 -1 )  pixels
;;; actual NW image y  (y increasing toward bottom)   = nint( image_size - image_size*vpY0 -1 )  pixels
;;; actual NW image y  (y increasing toward top)   = nint( image_size*vpY0 +1 )  pixels  (not checked)
        return(mp)
end
;---------------------------------------------------------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  BELOW FUNCTIONS HAD BEEN IN rasp.ncl, NOW MOVED HERE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;---------------------------------------------------------------------------------
;onceonly_background: altered function
undef("add_frame")
function add_frame( wks:graphic, plot:graphic, opt_args[1]:logical, ldoframe[1]:numeric, framearray[*]:numeric )
local framearraydims,isize,jsize,ileft,iright,jbot,jtop
begin
;jack - add dotted frame of width framearray points to indicate boundary region
   ;;; framearray inputs needed corner values
   framearraydims = dimsizes(framearray)
   ;;; draw line
   if( ldoframe .gt. 0 ) then
       ;;; *** NO OFFSET USED HERE ***
       isize = framearray(0)
       jsize = framearray(1)
       ;4testprint: print("  isize,jsize="+isize+","+jsize )
       ;;; below assumes  isize,jsize is array dimension
       ileft = 0 + ldoframe
       iright = isize -1 - ldoframe
       jbot = 0 + ldoframe
       jtop = jsize -1 - ldoframe
   else
     if( framearraydims(0) .eq. 4 ) then
       ;;; framearray = xl,yb, xr,yt - USES NAMELIST FORTRAN INDEXS ! AND ALLOWS FOR MASS GRID OFFSET !
       ;;; *NB* this assumes that fine:coarse grid spacing is 3:1  
       ;;; *NOT* CHECKED AFTER ALTERING FROM OLD VIEWPORT WIDTH/HEIGHT TO GRID VALUE METHOD !!!
         ileft  = framearray(0) -1.333
         jbot   = framearray(1) -1.333
         iright = framearray(2) -1.667
         jtop   = framearray(3) -1.667
         ;old xx(0) =  vpx + vpw* ( framearray(0) -1.333) / ( dims(1)-1 ) 
         ;old yy(0) =  vpy - vph +vph* ( framearray(1) -1.333) / ( dims(0)-1 ) 
         ;old xx(1) =  vpx + vpw* ( framearray(2) -1.667) / ( dims(1)-1 ) 
         ;old yy(1) =  vpy - vph +vph* ( framearray(1) -1.333) / ( dims(0)-1 ) 
         ;old xx(2) =  vpx + vpw* ( framearray(2) -1.667) / ( dims(1)-1 ) 
         ;old yy(2) =  vpy - vph +vph* ( framearray(3) -1.667) / ( dims(0)-1 ) 
         ;old xx(3) =  vpx + vpw* ( framearray(0) -1.333) / ( dims(1)-1 ) 
         ;old yy(3) =  vpy - vph +vph* ( framearray(3) -1.667) / ( dims(0)-1 ) 
         ;old xx(4) =  vpx + vpw* ( framearray(0) -1.333) / ( dims(1)-1 )  
         ;old yy(4) =  vpy - vph +vph* ( framearray(1) -1.333) / ( dims(0)-1 ) 
         ;bad    ;;; my reasoning first gave following (and this is centered and gives width of 1 when xl-xr=2)
         ;bad    ;;;    but then CA coastline on grid 1 at panoche grid2 line does not match grid2 edge (for X grid1 1-39 with subgrid 12-28)
         ;bad    ;;; finally realized that mass pt on coarse grid is one fine grid spacing inward from perimeter fine grid pt
         ;bad  xx(0) =  vpx + vpw* ( framearray(0) -1.) / ( dims(1)-1 ) 
         ;bad  yy(0) =  vpy - vph +vph* ( framearray(1) -1.) / ( dims(0)-1 ) 
         ;bad  xx(1) =  vpx + vpw* ( framearray(2) -2.) / ( dims(1)-1 ) 
         ;bad  yy(1) =  vpy - vph +vph* ( framearray(1) -1.) / ( dims(0)-1 ) 
         ;bad  xx(2) =  vpx + vpw* ( framearray(2) -2.) / ( dims(1)-1 ) 
         ;bad  yy(2) =  vpy - vph +vph* ( framearray(3) -2.) / ( dims(0)-1 ) 
         ;bad  xx(3) =  vpx + vpw* ( framearray(0) -1.) / ( dims(1)-1 ) 
         ;bad  yy(3) =  vpy - vph +vph* ( framearray(3) -2.) / ( dims(0)-1 ) 
         ;bad  xx(4) =  vpx + vpw* ( framearray(0) -1.) / ( dims(1)-1 )  
         ;bad  yy(4) =  vpy - vph +vph* ( framearray(1) -1.) / ( dims(0)-1 ) 
      else
       print("  ***ERROR STOP - framearray array not implemented for this dimension" )
       exit
     end if
   end if
  ;;; *NB* must prevent destruction of primitivethingey (else get error messages ala warning:prXArray isn't a resource in this object + Segmentation fault)
   primitivethingey = gsn_add_polyline( wks, plot, (/ileft,iright,iright,ileft,ileft/),(/jbot,jbot,jtop,jtop,jbot/), opt_args )
  ;alternative dummy = gsn_add_primitive( wks, plot, xx,yy, False,"polyline", opt_args )
  ;;; must return   primitivethingey to prevent its destruction
  return ( primitivethingey )
end
;;;---------------------------------------------------------------------------------
;sounding_loc_plot
;jack - plot numerical sounding id at sounding location
; must use array argument "thingeys" to keep graphic primitives created by gsn_add_test from being destroyed !!!
undef("add_sounding_locations")
procedure add_sounding_locations( wks:graphic,  map:graphic, wrfout_file:file, data[*][*]:numeric, ids[*]:string,lats[*]:numeric,lons[*]:numeric, opt_args[1]:logical, thingeys[*]:graphic )
local iddims,dims,maxsounding,isounding,locr,loc,fortranI,fortranJ,loc_str
begin
   ;;; needed to avoid 
   loc_str  = new( 1, string )
   ;;; initialization
      iddims = dimsizes(ids)
      maxsounding = iddims(0)
   ;;; dims gives number of 2d x,y points
      dims = dimsizes(data)
   ;;; loop over all ids
      do isounding=0,(maxsounding-1)
         ;;; sounding integers do not have to be consecutive, so skip any unset ones
            if( ismissing( ids(isounding) ) ) then
               continue
            end if
         ;jack - use array to set sounding id,lat,long - function returns (lat=J,lon=I) pair as nearest integer value
            locr = wrf_user_find_ij_lat_long( wrfout_file, lats(isounding), lons(isounding) )
            loc = floattointeger(locr)
            fortranI = loc(1)+1
            fortranJ = loc(0)+1
         ;;; treat case of lat/lon outside domain - skip plot
         ; use eq since seems to return border value in error cases (and border not too valid anyway)
            ;4testprint print( "*** SOUNDING LOCATION MARKER - "+ids(isounding)+" lon,lat "+lons(isounding)+","+lats(isounding)+" => mathI,J="+fortranI+","+fortranJ+" for dims= "+dims(1)+","+dims(0) )
            if( fortranI.lt. 1 .or. fortranI.gt.dims(1) .or. fortranJ.lt.1 .or. fortranJ.gt.dims(0) ) then
            ;old if( loc(1).le. 0 .or. loc(1).ge.(dims(1)-1) .or. loc(0).le.0 .or. loc(0).ge.(dims(0)-1) ) then
            ;old    print( "   * SKIPPING SOUNDING LOCATION MARKER - "+ids(isounding)+" lon/lat "+lons(isounding)+"/"+lats(isounding)+"outside domain => loc="+loc(1)+" "+loc(0)+" for dims= "+(dims(1)-1)+" "+(dims(0)-1) )
               print( "   * SKIPPING SOUNDING LOCATION MARKER - "+ids(isounding)+" lon,lat "+lons(isounding)+","+lats(isounding)+" outside domain => mathI,J="+fortranI+","+fortranJ+" for dims= "+dims(1)+","+dims(0) )
               continue          
            else
               if( .not. isatt(opt_args,"txFuncCode") ) then
                  ;;; default plots sounding number on map (warning- must be coerced to string at argument call)
                  loc_str = isounding
                  ;bad  loc_str = floattocharacter(isounding)
               else
                  ;;; alternative to plot sounding name on map
                  loc_str = ids(isounding)
               end if
            end if
            ;4testprint print ( "isounding,loc_str="+isounding+","+loc_str )
            ;4testprint print ( "isounding="+isounding+" lat,lon="+lats(isounding)+" "+lons(isounding) )
            ;4testprint print ( "dims="+dims(1)+" "+dims(0)+" I,J="+fortranI+" "+fortranJ )
          ;;; draw text
          thingeys(isounding) = gsn_add_text ( wks, map, loc_str, (/fortranI-1/),(/fortranJ-1/), opt_args ) 
      end do
end
;;;---------------------------------------------------------------------------------
;;; ROUTINE TO WRITE 2D DATA FILE
;        needed params: 
;          ENV_NCL_ID (contains ID & forecast valid time, etc) =    $ENV{'ENV_NCL_ID'} = sprintf "Valid %02d%02d %s [%02d%02dZ] %s %s %s %d %shrFcst@%sz", $localhh,$localmin, $LOCALTIME_ID{$regionkey}, $filehh,$filemin, $localdow, $localday, $localmon, $localyyyy, $fcstperiodprt,$ztime ;
;          isize,jsize (output array size) eg: paramdims=dimsizes(ter) jsize=paramdims(0) isize=paramdims(1)
;          kdomain (domain number)
;          qdatafile = "terrain.data"
;          qgridinfo = "RASP_grid: WRF "+REGION+" d"+kdomain+" ="+" 1 "+sprinti("%i",isize)+" 1 "+sprinti("%i",jsize)
;          qparaminfo = "Param=  Unit=  Mult= "
;          ;ruc qparaminfo = "Anal: "+sprinti("%0.2i",isize)+" Fcst: "+"Valid: "+" Param= "+" Unit= "+Mult= "
;        NCL_JACK_FORTRAN ::  output_mapdatafile( qdatafile, ENV_NCL_ID,qgridinfo,qparaminfo, ter, isize,jsize, lprecision ) lprecision=0=>integer
;;;---------------------------------------------------------------------------------

