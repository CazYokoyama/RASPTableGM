#! /usr/bin/perl -wT

### CALC RASP BLIPMAP TRACK AVG, SPATIAL AND OPTIMAL FLIGHT
### ala http://www.drjack.info/cgi-bin/get_rasptrackavg.cgi?region=GREATBRITAIN&grid=d2&day=0&time=1500&polar=LS-3&wgt=1&tsink=1&tmult=1&latons=51.,0.,52.,-1.,52.,1.,51.,0.
#rasp- ### CAN INPUT EITHER LAT,LONS OR IMAGE INFORMATION

################################################################################

  ### MODIFIED FROM get_bliptrackavg.pl

  ### NOTE - if input parameter argument changes may need to change its detainting

  ### TO UNTAINT PATH
  $ENV{'PATH'} = '/bin:/usr/bin:/var/www/cgi-bin';

  ### DEFINE BASEDIR - HARDWIRE FOR APACHE SERVER 
  # PAULS if ( defined $ENV{'HOME'} ) { $BASEDIR = $ENV{'HOME'}/DRJACK ;  }
  # PAULS else                        { $BASEDIR = '/home/admin/DRJACK' ;  }
  # PAULS else                        { $BASEDIR = '/home/rasp' ;  }
  # Not Needed { $BASEDIR = '/home/rasp' ;  }

  ### SET EXTERNAL SCRIPT WHICH OUTPUTS RESULT IN TEXT FORMAT
  # PAULS $EXTRACTSCRIPT = "${BASEDIR}/RASP/ANAL/TRACK/rasptrackavg.PL";
  $EXTRACTSCRIPT = "/var/www/cgi-bin/rasptrackavg.PL";

################################################################################

  use CGI::Carp qw(fatalsToBrowser);

  my $PROGRAM = 'get_rasptrackavg.cgi' ;

  ### SET PLOT SCRIPT INFORMATION
  # $NCARG_ROOT = "${BASEDIR}/UTIL/NCARG" ;
  $NCARG_ROOT = "/home/rasp/UTIL/NCARG" ;
  #old $NCARG_ROOT = '/usr/local/ncarg' ;
  $ENV{'NCARG_ROOT'} = $NCARG_ROOT ;
  # PAULS ${NCLSCRIPT} = "${BASEDIR}/RASP/ANAL/TRACK/rasptrackavg.multiplot.ncl";
  ${NCLSCRIPT} = "/var/www/cgi-bin/rasptrackavg.multiplot.ncl";

  ### ALLOW XI TESTS
  $LTEST = 0;
  #4XItest: $LTEST = 1;
  ### SET INPUT PARAMETERS
  if ( $LTEST == 0 )
  {
    ### PARSE CGI INPUT
    use CGI qw(:standard);
    $query = new CGI;
    $region = $query->param('region');
    $grid = $query->param('grid');
    $day = $query->param('day');
    $validtime = $query->param('time');
    $polar = $query->param('polar');
    $wgt = $query->param('wgt');
    $tsink = $query->param('tsink');
    $tmult = $query->param('tmult');
    $latlons = $query->param('latlons');
    $xylist = $query->param('xylist');
    $imagewidth = $query->param('width');
    $imageheight = $query->param('height');
    ### UNTAINT INPUT PARAMS - do not allow leading "-" except with numeric value
    #tainttest: use Scalar::Util qw(tainted);
    #tainttest: print "avar " . (tainted($avar)?"IS ":"is not ") . "tainted\n" ;
    #4test=insecure:    if ( defined $region && $region =~ m|^(.*)$| ) { $region = $1 ; }
    #bad    if ( defined $region && $region =~ m|^(\w{1}[\w\-\.]*)$| ) { $region = $1 ; }
    if ( defined $region && $region =~ m|^([A-Za-z0-9][A-Za-z0-9_.+-]*)$| ) { $region = $1 ; }
    if ( defined $grid && $grid =~ m|^([dw][0-9])$| ) { $grid = $1 ; }
    if ( defined $day && $day =~ m|^([0-9-]*)$| ) { $day = $1 ; }
    #PAULS if ( defined $validtime && $validtime =~ m|^([0-9a-zA-Z]*)$| ) { $validtime = $1 ; }
    if ( defined $validtime && $validtime =~ m|^([0-9a-zA-Z+]*)$| ) { $validtime = $1 ; }
    if ( defined $polar && $polar =~ m|^([A-Za-z0-9+-][A-Za-z0-9,_+.-]*)$| ) { $polar = $1 ; }
    if ( defined $wgt && $wgt =~ m|^([0-9.-]*)$| ) { $wgt = $1 ; }
    if ( defined $tsink && $tsink =~ m|^([0-9.mkts]*)$| ) { $tsink = $1 ; }
    if ( defined $tmult && $tmult =~ m|^([0-9.]*)$| ) { $tmult = $1 ; }
    ### once seemed to get error using following but then not !?
    if ( defined $latlons && $latlons =~ m|^([0-9,.-]*)$| ) { $latlons = $1 ; }
    if ( defined $xylist && $xylist   =~ m|^([0-9,.-]*)$| ) { $xylist = $1 ; }
    if ( defined $imagewidth && $imagewidth =~ m|^([0-9]*)$| ) { $imagewidth = $1 ; }
    if ( defined $imageheight && $imageheight =~ m|^([0-9]*)$| ) { $imageheight = $1 ; }
  }
  else
  {
    ###### INITIALIZATION FOR XI TESTS
    #4test: $EXTRACTSCRIPT = "${BASEDIR}/RASP/ANAL/TRACK/test.rasptrackavg.PL";
    ###### CASE
      $region = 'GREATBRITAIN';
      ### SET DAY=-1 TO USE PREVIOUS DAY DATA
      $day = 0;
      $grid = 'd2' ;
      $validtime = 1500 ;
      ### ARTIFICIAL INPUT
      #alternate: $latlons = "51.,0.,52.,-1.,52.,1.,51.,0.," ;
      $xylist = "500,600,550,650," ;
      $imagewidth = $imageheight = 1000 ;
      $polar = '-1.3419e-4,2.077e-2,-1.37' ;
      $wgt = 1 ;
      $tsink = 0.8 ;
      $tmult = 1.0 ;
  }

  #### ALLOW DEFAULTS FOR CERTAIN PARAMETERS
  if ( ! defined $day || $day eq '' ) { $day = 0 ; } 
  if ( ! defined $wgt || $wgt eq '' ) { $wgt = '1' ; }
  if ( ! defined $tsink || $tsink eq '' ) { $tsink = '1.0' ; }
  if ( ! defined $tmult || $tmult eq '' ) { $tmult = '1' ; }

  #### TEST FOR MISSING ARGUMENTS
  if ( ! defined $region || $region eq '' ) { die "${PROGRAM} ERROR EXIT: missing region argument"; }
  if ( ! defined $grid || $grid eq '' ) { die "${PROGRAM} ERROR EXIT: missing grid argument"; }
  if ( ! defined $day || $day eq '' ) { die "${PROGRAM} ERROR EXIT: missing day argument"; }
  if ( ! defined $validtime || $validtime eq '' ) { die "${PROGRAM} ERROR EXIT: missing time argument"; }
  if ( ! defined $polar || $polar eq '' ) { die "${PROGRAM} ERROR EXIT: missing polar argument"; }
  ### TEST FOR EITHER LATLONS or XYLIST INPUT ALTERNATIVE
  if ( ! defined $xylist || $xylist eq '' )
  { if ( ! defined $latlons || $latlons eq '' ) { die "${PROGRAM} ERROR EXIT: missing latlons or xylist argument"; } }
  else
  {
    if ( ! defined $imagewidth || $imagewidth eq '' ) { die "${PROGRAM} ERROR EXIT: missing width argument"; }
    if ( ! defined $imageheight || $imageheight eq '' ) { die "${PROGRAM} ERROR EXIT: missing height argument"; }
  }

  ### INITIALIZATION
  #unused ### ensure region is capital
  #unused $region =~ tr/a-z/A-Z/;
  #bad ### ensure time has no leading zero
  #bad $validtime =~ s/0([0-9])/$1/;
  ### SET TMP FILE IDENTIFIER
  $tmpid = int( rand 999998 ) +1;
    
#rasp-   ### TREAT CASE WHERE LAT,LONS INPUT VIA CLICKING ON BLIPMAP IN JAVASCRIPT VIEWER
#rasp-   if ( ! defined $latlons || $latlons eq '' )
#rasp-   {
#rasp-   
#rasp-     ### FOR RASP NEED PARAMETER SETTING STUFF HERE IF IMAGE SELECTION+INPUT LATER ENABLED
#rasp-     ###   (use parameters read from REGIONXYZ/static/wrfsi.nl and lat/lon calc routine ala rasptrackavg.PL)  
#rasp-     ###   (plus need image corner locations)
#rasp-     ##########  USE EXTERNAL FILES TO SET GLOBAL PARAMETERS ##########
#rasp-     $MODEL_PARAMETERID = $region ;
#rasp-     ### REQUIRE NON-MODEL-SPECIFIC FILE SUBROUTINES ###
#rasp-     require "$HOME/DRJACK/BLIP/SUB/sub.import_image_variables.pl" ;
#rasp-     ### REQUIRE MODEL-SPECIFIC FILE SUBROUTINES ###
#rasp-     require "$HOME/DRJACK/BLIP/SUB/sub.import_model_region_parameters.${MODEL_PARAMETERID}.pl" ;
#rasp-     require "$HOME/DRJACK/BLIP/SUB/sub.import_model_grid_parameters.${MODEL_PARAMETERID}.pl" ;
#rasp-     require "$HOME/DRJACK/BLIP/SUB/sub.import_model_plot_parameters.${MODEL_PARAMETERID}.pl" ;
#rasp-     ### CALL TO SET GRID REGIONS (grid corners)
#rasp-     ### BELOW REQUIRES REGION SPECIFIC FILE SUBROUTINE
#rasp-     &import_model_region_parameters ;
#rasp-     ### SET MODEL GRID PARAMETERS
#rasp-     ### BELOW REQUIRES REGION SPECIFIC FILE SUBROUTINE
#rasp-     ### *** RELIES ON GLOBAL PARAMETERS BEING SET, PASSED, AND USED ***
#rasp-     &import_model_grid_parameters;
#rasp-     ### CALL TO SET PLOT PARAMS
#rasp-     ### BELOW REQUIRES REGION SPECIFIC FILE SUBROUTINE
#rasp-     $plot_mappixelperpt = '' ;
#rasp-     &import_model_plot_parameters( $grid ) ;
#rasp-     ### CALL TO SET IMAGE SIZE
#rasp-     ### BELOW REQUIRES NON-REGION SPECIFIC FILE SUBROUTINE
#rasp-     $image_mapwidth = $image_mapheight = '' ;
#rasp-     &import_image_variables( $grid, $plot_mappixelperpt, $plot_imin,$plot_imax,$plot_jmin,$plot_jmax ) ;
#rasp- 
#rasp-     ### TREAT CASE WHERE IMAGE INFO INPUT
#rasp-     ### CONVERT IMAGE x,y LIST INTO LAT,LONS
#rasp-     $xyargtail = $xylist ;
#rasp-     $npts = 0;
#rasp-     while ( defined $xyargtail && $xyargtail ne "" )
#rasp-     {
#rasp-       ( $ximage[$npts],$yimage[$npts], $xyargtail ) = split /,/, $xyargtail, 3 ;
#rasp-       $npts = $npts + 1 ;
#rasp-     }
#rasp-     ### ADJUST FOR RE-SIZED MAP - convert re-sized image coord to original size coord
#rasp-     if ( defined $imagewidth ) 
#rasp-     { 
#rasp-       for ( $ipt=0; $ipt<=($npts-1); $ipt++ ) 
#rasp-       {
#rasp-         $ximage[$ipt] = $ximage[$ipt] * ($image_xsize/$imagewidth)
#rasp-       }
#rasp-     }
#rasp-     if ( defined $imageheight ) 
#rasp-     {
#rasp-       for ( $ipt=0; $ipt<=($npts-1); $ipt++ ) 
#rasp-       {
#rasp-         $yimage[$ipt] = $yimage[$ipt] * ($image_ysize/$imageheight)
#rasp-       }
#rasp-     }
#rasp-     ### convert into i,j (nonstaggered)
#rasp-    for ( $ipt=0; $ipt<=($npts-1); $ipt++ ) 
#rasp-    {
#rasp-       $aigrid[$ipt] = $plot_imin + ($plot_imax-$plot_imin)*(($ximage[$ipt]-$image_maporiginx)/$image_mapwidth) ;
#rasp-       $ajgrid[$ipt] = $plot_jmin + ($plot_jmax-$plot_jmin)*( 1 - (($yimage[$ipt]-$image_maporiginy)/$image_mapheight) ) ;
#rasp-     }
#rasp-     #unused ### get nearest integer values
#rasp-     #unused $igrid = nint( $aigrid );
#rasp-     #unused $jgrid = nint( $ajgrid );
#rasp-     ### for test prints
#rasp-     if ( $LTEST == 1 )
#rasp-     {
#rasp-       #4test:   print "x,yIMAGE= @ximage & @yimage x,ySIZE= $image_xsize $image_ysize x,yORIGIN= $image_maporiginx $image_maporiginy i,jGRID= @aigrid & @ajgrid \n";
#rasp-     }
#rasp-     ### convert into lat/lon
#rasp-     if ( $region eq 'RUC' || $region eq 'FSL' )
#rasp-     {
#rasp-       for ( $ipt=0; $ipt<=($npts-1); $ipt++ ) 
#rasp-       {
#rasp-         ( $alat[$ipt],$alon[$ipt] ) = &ruc_ij2latlon( $aigrid[$ipt],$ajgrid[$ipt] );
#rasp-       }
#rasp-     }
#rasp-      else
#rasp-     { die "${PROGRAM} ERROR EXIT: unknown REGION for image processing"; }
#rasp-     ### END OF CASE WHERE LAT,LONS INPUT VIA CLICKING ON BLIPMAP IN JAVASCRIPT VIEWER
#rasp-     ### PUT LAT,LONS INTO SINGLE STRING NEEDED FOR EXTERNAL SCRIPT ARGUMENT
#rasp-     $latlons='';
#rasp-     for ( $ipt=0; $ipt<=($npts-1); $ipt++ ) 
#rasp-     {
#rasp-       $latlons = sprintf "%s%.3f,%.3f,", $latlons, $alat[$ipt],$alon[$ipt] ;
#rasp-     }
#rasp-     #4test: print "$latlons \n";
#rasp-   }    

  ### GET OUTPUT TEXT FROM EXTERNAL SCRIPT
  #PAULS-TEST print "${EXTRACTSCRIPT} $region $grid $day $validtime $polar $wgt $tsink $tmult $latlons $tmpid\n\n";

  $calcout = `${EXTRACTSCRIPT} $region $grid $day $validtime $polar $wgt $tsink $tmult $latlons $tmpid`;

  ### PLOT FROM OUTPUT FILE PRODUCED BY ABOVE
  if ( $calcout !~ m|error|i )
   #PAULS - TEST-> { $plotout = `$NCARG_ROOT/bin/ncl ${NCLSCRIPT}  'wks="ncgm"' 'data_filename="/tmp/rasptrackavg.out.${tmpid}"' 'plot_filename="/tmp/rasptrackavg.multiplot.ncgm.${tmpid}"'`; }
   # { $plotout = `/var/www/cgi-bin/ncl ${NCLSCRIPT}  'wks="ncgm"' 'data_filename="/tmp/rasptrackavg.out.${tmpid}"' 'plot_filename="/tmp/rasptrackavg.multiplot.ncgm.${tmpid}"'`; }
   { $plotout = `${NCARG_ROOT}/bin/ncl ${NCLSCRIPT}  'wks="ncgm"' 'data_filename="/tmp/rasptrackavg.out.${tmpid}"' 'plot_filename="/tmp/rasptrackavg.multiplot.ncgm.${tmpid}"'`; }
  else
  { $plotout = 'CALC ERROR => NO PLOT' ; }

  ### PRINT HTML TEXT = HEADER + SCRIPT OUTPUT
  $headerline = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
 <HTML>
 <HEAD>
  <TITLE>RASP Track Avg</TITLE>
  <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1">
  <meta name="author" content="Dr. John W. (Jack) Glendening">
 </HEAD>
  <BODY text="black" bgcolor="white">' ;
  $footerline = ' </BODY></HTML>' ;
  if ( $calcout !~ m|error|i )
  #PAULS { print "Content-type: text/html\n\n${headerline}<PRE>${calcout}</PRE> <IMG SRC=\"/cgi-bin/display_ncgm.cgi?file=/tmp/rasptrackavg.multiplot.ncgm.${tmpid}&ctransarg=-window%200.15:0.0:0.85:1.0%20-res%20420x600\"> ${footerline}\n"; }
  { print "Content-type: text/html\n\n${headerline}<TABLE><TR valign=\"top\"><TD><BR><PRE>${calcout}</PRE></TD><TD><IMG SRC=\"/cgi-bin/display_ncgm.cgi?file=/tmp/rasptrackavg.multiplot.ncgm.${tmpid}&ctransarg=-window%200.15:0.0:0.85:1.0%20-res%20420x600\"></TD></TR></TABLE> ${footerline}\n"; }
  else
  { print "Content-type: text/html\n\n${headerline}<PRE>${calcout}<BR>${plotout}</PRE> ${footerline}\n"; }
  #4test: print "Content-type: text/html\n\n${headerline}<PRE>${calcout}</PRE> <BR> PLOTOUT= $plotout <BR>${footerline}\n";
  #old print "Content-type: text/plain\n\n${calcout}\n";

	#PAULS - CLEAN UP THE DETRITUS
	 # { `/bin/rm -f /tmp/rasptrackavg.out.${tmpid} /tmp/rasptrackavg.multiplot.ncgm.${tmpid}` ; }
	 { `/bin/rm -f /tmp/rasptrackavg.out.${tmpid}` ; }


#rasp- #####################################################################################################
#rasp- ##########  SUBROUTINES FOLLOW  #####################################################################
#rasp- #####################################################################################################
#rasp- sub ruc_ij2latlon ()
#rasp- {
#rasp-   ### using ncep routine w3fb12
#rasp-   ### PARSE ARGUMENT
#rasp-   my ($aigrid,$ajgrid) = @_;
#rasp-       ### FOLLOWING FROM mapscon.f - for 20km RUC
#rasp-       my ( $GRID_DX_P, $GRID_LAT_LL_P, $GRID_LONG_LL_P, $GRID_LON_XX_P, $GRID_LAT_TAN_P  );
#rasp-       $dx = $GRID_DX_P       =  20317.63     ;
#rasp-       $alat1 = $GRID_LAT_LL_P   =  16.2810      ; 
#rasp-       $elon1 = $GRID_LONG_LL_P   = -126.1378     ; 
#rasp-       $elonv = $GRID_LON_XX_P   = -95.0         ;
#rasp-       #**  GRID_LAT_TAN_P         R  LATITUDE AT LAMBERT CONFORMAL PROJECTION IS TRUE (DEG)
#rasp-       $alatan = $GRID_LAT_TAN_P  =  25.0       ;
#rasp-       #unused**  GRID_LAT_TRUE_P        R  LATITUDE AT WHICH X-Y SCALE IS TRUE (DEG)
#rasp-       #unused      $GRID_LAT_TRUE_P =  35.0  ;
#rasp-   my ($alat,$alon,$ierr) = &w3fb12( $aigrid, $ajgrid );
#rasp-   #4test: print "RUC_20km lat,lon= $alat $alon \n";
#rasp-   return $alat,$alon ;
#rasp- }
#rasp- sub w3fb12()
#rasp- {
#rasp- 
#rasp-   my ($xi,$xj) = @_;
#rasp-   my ( $alat,$elon,$ierr );
#rasp- 
#rasp- ### fortran subroutine w3fb12( xi,xj, alat1,elon1,dx,elonv,alatan, alat,elon,ierr )
#rasp- #$$$   subprogram  documentation  block
#rasp- #
#rasp- # subprogram:  w3fb12        lambert(i,j) to lat/lon for grib
#rasp- #   prgmmr: stackpole        org: nmc42       date:88-11-28
#rasp- #
#rasp- # abstract: converts the coordinates of a location on earth given in a
#rasp- #   grid coordinate system overlaid on a lambert conformal tangent
#rasp- #   cone projection true at a given n or s latitude to the
#rasp- #   natural coordinate system of latitude/longitude
#rasp- #   w3fb12 is the reverse of w3fb11.
#rasp- #   uses grib specification of the location of the grid
#rasp- #
#rasp- # program history log:
#rasp- #   88-11-25  original author:  stackpole, w/nmc42
#rasp- #
#rasp- # usage:  call w3fb12(xi,xj,alat1,elon1,dx,elonv,alatan,alat,elon,ierr)
#rasp- #   input argument list:
#rasp- #     xi       - i coordinate of the point  real*4
#rasp- #     xj       - j coordinate of the point  real*4
#rasp- #     alat1    - latitude  of lower left point of grid (point 1,1)
#rasp- #                latitude <0 for southern hemisphere; real*4
#rasp- #     elon1    - longitude of lower left point of grid (point 1,1)
#rasp- #                  east longitude used throughout; real*4
#rasp- #     dx       - mesh length of grid in meters at tangent latitude
#rasp- #     elonv    - the orientation of the grid.  i.e.,
#rasp- #                the east longitude value of the vertical meridian
#rasp- #                which is parallel to the y-axis (or columns of
#rasp- #                the grid) along which latitude increases as
#rasp- #                the y-coordinate increases.  real*4
#rasp- #                this is also the meridian (on the other side of the
#rasp- #                tangent cone) along which the cut is made to lay
#rasp- #                the cone flat.
#rasp- #     alatan   - the latitude at which the lambert cone is tangent to
#rasp- #                (touches or osculates) the spherical earth.
#rasp- #                 set negative to indicate a
#rasp- #                 southern hemisphere projection; real*4
#rasp- #
#rasp- #   output argument list:
#rasp- #     alat     - latitude in degrees (negative in southern hemi.)
#rasp- #     elon     - east longitude in degrees, real*4
#rasp- #     ierr     - .eq. 0   if no problem
#rasp- #                .ge. 1   if the requested xi,xj point is in the
#rasp- #                         forbidden zone, i.e. off the lambert map
#rasp- #                         in the open space where the cone is cut.
#rasp- #                  if ierr.ge.1 then alat=999. and elon=999.
#rasp- #
#rasp- #   remarks: formulae and notation loosely based on hoke, hayes,
#rasp- #     and renninger's "map projections and grid systems...", march 1981
#rasp- #     afgwc/tn-79/003
#rasp- #
#rasp- # attributes:
#rasp- #   language: ibm vs fortran
#rasp- #   machine:  nas
#rasp- #
#rasp- #$$$
#rasp- #
#rasp- # data
#rasp-          my $rerth = 6.3712e+6;
#rasp-          my $pi = 3.1415926;
#rasp-          my $oldrml = 99999.;
#rasp- #
#rasp- #        preliminary variables and redifinitions
#rasp- #
#rasp- #        h = 1 for northern hemisphere; = -1 for southern
#rasp- 
#rasp-          my $beta  = 1.;
#rasp-          $ierr = 0;
#rasp- 
#rasp-          my ( $h, $newmap, $aninv2, $polei, $polej );
#rasp-          if ( $alatan > 0)
#rasp-            { $h = 1.; }
#rasp-          else
#rasp-            { $h = -1.; }
#rasp- #
#rasp-          my $piby2 = $pi/2.;
#rasp-          my $radpd = $pi/180.0;
#rasp-          my $degprd = 1./$radpd;
#rasp-          my $rebydx = $rerth/$dx;
#rasp-          my $alatn1 = $alatan * $radpd;
#rasp-          my $an = $h * sin($alatn1);
#rasp-          my $cosltn = cos($alatn1);
#rasp- #
#rasp- #        make sure that input longitude does not pass through
#rasp- #        the cut zone (forbidden territory) of the flat map
#rasp- #        as measured from the vertical (reference) longitude
#rasp- #
#rasp-          my $elon1l = $elon1;
#rasp-          if ( ($elon1-$elonv) > 180.) 
#rasp-            { $elon1l = $elon1 - 360.; }
#rasp-          if ( ($elon1-$elonv) < (-180.) )
#rasp-            {  $elon1l = $elon1 + 360.; }
#rasp- #
#rasp-          my $elonvr = $elonv * $radpd;
#rasp- #
#rasp- #        radius to lower left hand (ll) corner
#rasp- #
#rasp-          my $ala1 =  $alat1 * $radpd;
#rasp-          my $rmll = $rebydx * (($cosltn**(1.-$an))*(1.+$an)**$an) *
#rasp-                 (((cos($ala1))/(1.+$h*sin($ala1)))**$an)/$an;
#rasp- #
#rasp- #        use rmll to test if map and grid unchanged from previous
#rasp- #        call to this code.  thus avoid unneeded recomputations.
#rasp- #
#rasp-          if ( $rmll == $oldrml )
#rasp-            {  $newmap = 'false'; }
#rasp-          else
#rasp-          {
#rasp-            $newmap = 'true'; 
#rasp-            $oldrml = $rmll ;
#rasp- #
#rasp- #          use ll point info to locate pole point
#rasp- #
#rasp-            my $elo1 = $elon1l * $radpd ;
#rasp-            my $arg = $an * ($elo1-$elonvr) ;
#rasp-            $polei = 1. - $h * $rmll * sin($arg) ;
#rasp-            $polej = 1. + $rmll * cos($arg) ;
#rasp-          }
#rasp- #
#rasp- #        radius to the i,j point (in grid units)
#rasp- #              yy reversed so positive is down
#rasp- #
#rasp-          my $xx = $xi - $polei ;
#rasp-          my $yy = $polej - $xj ;
#rasp-          my $r2 = $xx**2 + $yy**2 ;
#rasp- #
#rasp- #        check that the requested i,j is not in the forbidden zone
#rasp- #           yy must be positive up for this test
#rasp- #
#rasp-          my $theta = $pi*(1.-$an) ;
#rasp-          $beta = abs(atan2($xx,-$yy)) ;
#rasp-          $ierr = 0 ;
#rasp-          if ( $beta <= $theta )
#rasp-          {
#rasp-            $ierr = 1 ;
#rasp-            $alat = 999. ;
#rasp-            $elon = 999. ;
#rasp-            if ( $newmap eq 'false' ) { return $alat,$elon,$ierr }
#rasp-          }
#rasp- #
#rasp- #        now the magic formulae
#rasp- #
#rasp-          if ( $r2 == 0 )
#rasp-          {
#rasp-            $alat = $h * 90. ;
#rasp-            $elon = $elonv ;
#rasp-          }
#rasp- #
#rasp- #          first the longitude
#rasp- #
#rasp-          else
#rasp-          {
#rasp-            $elon = $elonv + $degprd * atan2($h*$xx,$yy)/$an ;
#rasp- #fortran           elon = amod(elon+360., 360.) 
#rasp- #bad-uses_integer_mod:           $elon = ($elon+360.) % 360. ;
#rasp-            $elon = ($elon+360.) ;
#rasp- 
#rasp- #
#rasp- #          now the latitude
#rasp- #          recalculate the thing only if map is new since last time
#rasp- #
#rasp-            if ( $newmap eq 'true' )
#rasp-            {
#rasp-              my $aninv = 1./$an ;
#rasp-                 $aninv2 = $aninv/2. ;
#rasp-              $thing = (($an/$rebydx) ** $aninv)/
#rasp-                (($cosltn**((1.-$an)*$aninv))*(1.+ $an)) ;
#rasp-            }
#rasp-            $alat = $h*($piby2 - 2.*atan($thing*($r2**$aninv2)))*$degprd ;
#rasp-          }
#rasp- #
#rasp- #        following to assure error values if first time thru
#rasp- #         is off the map
#rasp- #
#rasp- ###JACK: OUTPUT W LONG. INSTEAD OF E.
#rasp-          $wlon  = $elon - 360.;
#rasp-          if ( $ierr != 0 )
#rasp-          {
#rasp-            $alat = 999. ;
#rasp-            $elon = 999. ;
#rasp-            $wlon = 999. ;
#rasp-            $ierr = 2 ;
#rasp-          }
#rasp-          return $alat, $wlon, $ierr;
#rasp- }
#rasp- sub atan ()
#rasp- {
#rasp-  my $atan = +atan2( $_[0], 1. );
#rasp-   return $atan;
#rasp- }
#rasp- ###########################################################################################
#rasp- ### FIND NEAREST INTEGER
#rasp- sub nint { int($_[0] + ($_[0] >=0 ? 0.5 : -0.5)); }
#rasp- ###########################################################################################
