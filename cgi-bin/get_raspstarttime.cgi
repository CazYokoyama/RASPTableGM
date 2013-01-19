#! /usr/bin/perl -w -T

### CALC RASP TRACK AVG TASK TIMES
### Modified from get_raspTrackAvg.cgi
### PAULS: 10/01/2010

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
  # PAULS NOT NEEDED{ $BASEDIR = '/home/rasp' ;  }

  ### SET EXTERNAL SCRIPT WHICH OUTPUTS RESULT IN TEXT FORMAT
  # PAULS $EXTRACTSCRIPT = "${BASEDIR}/RASP/ANAL/TRACK/rasptrackavg.PL";
  $EXTRACTSCRIPT = "/var/www/cgi-bin/raspstarttime.PL";

################################################################################

  use CGI::Carp qw(fatalsToBrowser);

  my $PROGRAM = 'get_rasptrackavg.cgi' ;

  ##Don't need this for start times
  ### SET PLOT SCRIPT INFORMATION
  # $NCARG_ROOT = "${BASEDIR}/UTIL/NCARG" ;
  $NCARG_ROOT = "/home/rasp/UTIL/NCARG" ;
  #old $NCARG_ROOT = '/usr/local/ncarg' ;
  $ENV{'NCARG_ROOT'} = $NCARG_ROOT ;
  # PAULS ${NCLSCRIPT} = "${BASEDIR}/RASP/ANAL/TRACK/rasptrackavg.multiplot.ncl";
  # ${NCLSCRIPT} = "/var/www/cgi-bin/rasptrackavg.multiplot.ncl";

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
    
  ### GET OUTPUT TEXT FROM EXTERNAL SCRIPT
  #PAULS-TEST print "${EXTRACTSCRIPT} $region $grid $day $validtime $polar $wgt $tsink $tmult $latlons $tmpid\n\n";

  $calcout = `${EXTRACTSCRIPT} $region $grid $day $validtime $polar $wgt $tsink $tmult $latlons $tmpid`;

  ### PLOT FROM OUTPUT FILE PRODUCED BY ABOVE
  # if ( $calcout !~ m|error|i )
  #  #PAULS - TEST-> { $plotout = `$NCARG_ROOT/bin/ncl ${NCLSCRIPT}  'wks="ncgm"' 'data_filename="/tmp/rasptrackavg.out.${tmpid}"' 'plot_filename="/tmp/rasptrackavg.multiplot.ncgm.${tmpid}"'`; }
  #  # { $plotout = `/var/www/cgi-bin/ncl ${NCLSCRIPT}  'wks="ncgm"' 'data_filename="/tmp/rasptrackavg.out.${tmpid}"' 'plot_filename="/tmp/rasptrackavg.multiplot.ncgm.${tmpid}"'`; }
  #  { $plotout = `${NCARG_ROOT}/bin/ncl ${NCLSCRIPT}  'wks="ncgm"' 'data_filename="/tmp/rasptrackavg.out.${tmpid}"' 'plot_filename="/tmp/rasptrackavg.multiplot.ncgm.${tmpid}"'`; }
  # else
  # { $plotout = 'CALC ERROR => NO PLOT' ; }

  ### PRINT HTML TEXT = HEADER + SCRIPT OUTPUT + FOOTER
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
    { print "Content-type: text/html\n\n${headerline}<TABLE><TR valign=\"top\"><TD><BR><PRE>${calcout}</PRE></TD></TR></TABLE> ${footerline}\n"; }
  else
    { print "Content-type: text/html\n\n${headerline}<PRE>${calcout}<BR></PRE> ${footerline}\n"; }
  #4test: print "Content-type: text/html\n\n${headerline}<PRE>${calcout}</PRE> <BR> PLOTOUT= $plotout <BR>${footerline}\n";

	#PAULS - CLEAN UP THE DETRITUS
	 { `/bin/rm -f /tmp/rasptrackavg.out.${tmpid}` ; }

