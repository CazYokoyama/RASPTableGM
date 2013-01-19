#! /usr/bin/perl  -w

#ifnot1argument: 
if ( $#ARGV < 0 || $ARGV[0] eq '-?' ) {
#-----------------adescription1------------------------------------
print "Plot wrf output to png file(s) in RUNARG plot directory \n";
print "Usage: plot.wrffile.PL <flags> wrffilename(full|local) <parameter list> \n";
print "Flags: <send=-s> <save=-S> <fixedcolor=-f> <size=-g 512x512> <pngdir=-d directory> <keepncgm=-k> <region=-r REGIONXYZ> \n";
print "  (Modified from rasp.pl, default parameter list set internally) \n";
print "  (tries to extract region from wrffilenmae, -r option needed if fails) \n";
print "  eg: plot.wrffile.PL -d /tmp /home/glendeni/DRJACK/WRF/WRFV2/RASP/PANOCHE/wrfout_d02_2005-04-02_21:00:00 wstar \n";
exit 0; }
###############################################################################
  ### for cgi use taint checking option -T
  ### FOR VISUAL DEBUGGER:  /usr/bin/perl -d:ptkdb example.pl
  ### FOR DEBUG MODE: run with -d flag 
  ###    i debug mode, set package name + local variables so X,V don't show "main" variables, ie:
  # package Main; local ($a,$b,...);
  ### To restrict unsafe constructs (vars,refs,subs)
  ###    vars requires variables to be declared with "my" or fully qualified or imported
  ###    refs generates error if symbolic references uses instead of hard refs
  ###    subs requires subroutines to be predeclared
  #    use strict;
  ### To provide aliases for buit-in punctuation variables (p403)
use English;
  ### for non-buffered STDOUT,STDERR ouput:
select STDERR; $|=1;
select STDOUT; $|=1;   #must be last select
  ### to append new line to each print record:     $\="\n"; #($OUTPUT_RECORD_SEPARATOR)
  ### for error statements with subroutine traceback
use Carp ();
local $SIG{__WARN__} = \&Carp::cluck;
  ### To enable verbose diagnostics:
  #   use diagnostics;
###############################################################################

########  PROGRAMMING NOTES ########

### SCRIPT IS A KLUDGY MESS AS NUMEROUS OPTIONS HAVE BEEN ADDED TO ORIGINAL EXTRACT FROM ASP.PL
### *NB* SCRIPT USED FOR VIEWER SKEWT POPUP (apache run) SO TEST THAT MODE AFTER SIGNIFICANT MODIFICATIONS

###############################################################################

###### SET NCL FILE TO USE - ITS OUTPUT PARAMS MUST MATCH PARAM LIST HERE !!!
  #normal: 
  $RASP_NCLFILE = 'rasp.ncl' ;

###### SET DEFAULT ARGUMENT PARAMETERS
### 2=> save data+images ($LSAVE=2 set by -S argument
  $LSAVE = 0;
### 1=> copy png files to html directory  ($LSEND=2 set by -s argument)
  $LSEND = 0;
### default imagesize 
# PAULS   $imagesize = '800x800';
# Make same as other image sizes
  $imagesize = '1024x1024';

###### SET PLOT PARAMETERS
  ### DEFAULT PARAMETER LIST - can be overridden by optional argument(s)
  # FULL PARAMETER LIST - 30 Sep 2006
  @imagenamelist = ( 'hbl','dbl','hwcrit','dwcrit','wstar','bsratio', 'sfcsunpct','sfcshf', 'blwind','sfcwind', 'zsfclcl','zsfclcldif','zsfclclmask', 'zblcl','zblcldif','zblclmask','blcloudpct','blcwbase', 'boxwmax','press850','press700','press500', 'bltopvariab','bltopwind','wblmaxmin','zwblmaxmin', 'blwindshear', 'sfctemp','sfcdewpt', 'cape', 'wstar_bsratio', 'experimental1','experimental2','hglider' );
  #4test: @imagenamelist = ( 'wrf_LANDMASK' ) ;
  ### FOR SOUNDING PLOTS:  push @imagenamelist, ( 'sounding1','sounding10' );  
  ### FOR SOUNDING PLOTS:  
  # push @imagenamelist, ( 'sounding2','sounding3','sounding7','sounding6' );  
  #unused push @imagenamelist, ( 'sounding1','sounding2','sounding3','sounding4','sounding5','sounding6','sounding7','sounding8','sounding9','sounding10' );  
  #old @imagenamelist = ( "hbl","dbl","hwcrit","dwcrit","wstar","bsratio", "sfcsun","sfcshf", "blwind","sfcwind", "zsfclcl","zsfclcldif","zsfclclmask", "zblcl","zblcldif","zblclmask","rhblmax","cwbase", "boxwmax","press850","press700","press500", "bltopvariab","bltopwind","wblmaxmin","zwblmaxmin", "blwindshear", "sfctemp","sfcdewpt", "cape", "experimental1","experimental2","wstar_bsratio" );
  #4test: @imagenamelist = ( "hbl" );

#########################################################

### treat unknown variables 
  $fileanaltime = 0; 
  $analhr = 0; 
  $localsoarday = 'curr.'; 

### PARSE ARGUMENT(S) 
  local ( $opt_s, $opt_S, $opt_f, $opt_k, $opt_H, $opt_d ) ;
  use Getopt::Std ;
  getopts('sSfkg:d:r:H');
  ### treat optional "html" argument
  if( $opt_H ) { $LHTML = 1; }
  ### treat optional "send" argument
  if( $opt_s ) { $LSEND = 2; }
  ### treat optional "save" argument
  if( $opt_S ) { $LSAVE = 2; }
  ### treat optional "geometry" argument
  if( $opt_g ) { $imagesize = $opt_g; }
  ### treat optional "image directory" argument
  if( $opt_d )
  { 
    $imagedir = $opt_d;
    ### '.' means use $PWD 
    if( $imagedir eq '.' ) { $imagedir = $ENV{'PWD'} ;}
  }
  ### treat optional "regionname" argument
  if( $opt_r ) { $regionname = $opt_r; }
  ### treat optional "fixed color" argument
  if( $opt_f )
  { $ENV{'ENV_NCL_CONTOURING'} = "fixed"; }
  ### set wrf filename - if local file create full filename
  if( $ARGV[0] =~ m|/| )
    {  $wrffilename = $ARGV[0]; }
  else
    {  $wrffilename = "$ENV{'PWD'}/${ARGV[0]}"; }
  shift;
  ### treat optional parameters argument(s)
  if( $#ARGV > -1 )
  { 
    @imagenamelist = ( );
    $limagenameinput = 1;
  }
  else
  {
    $limagenameinput = 0;
  }
  while( $#ARGV > -1 )
  { 
    push @imagenamelist, $ARGV[0]; 
    shift;
  }

### FOR HTML CASE PRINT TO STDER INSTEAD
  if( ! defined $LHTML )
  {
    $LPRINT = 2;
    $PRINTFH = 'STDOUT';
  }
  else
  {
    $LPRINT = 0 ;
    #4testprints:     $LPRINT = 2 ;
    $PRINTFH = 'STDERR';
  }
$LPRINT = 2 ;

### INITIALIZATION
  ### set program name
  $program = $0;
### TEST FOR EXISTENCE OF DATA FILE
  if( ! -f  $wrffilename ) { die "$program ERROR STOP: non-existent input file $wrffilename"; }

###JACK - extract RUNARG,moad,regionname from filename - assumes file in normal wrf output directory
  if ( defined $regionname )
  {
    $moad = $regionname ;
  }
  else
  {
    ( $moad = $wrffilename ) =~ s|^.*/RASP/([^/]*)/.*|$1|i ;
    ### JACK - if moad not found, see if is in a SAVE subdirectory
    if( $moad =~ m|/| )
    {
      ( $moad = $wrffilename ) =~ s|^.*/SAVE/([^/]*)/.*|$1|i ;
    } 
  }
  if( ! $moad || $moad =~ m|/| )
  { 
    die "*** ERROR - $moad region NOT PARSED FROM INPUT FILENAME (re-run using -r option ? UNTESTED!)" ; 
  }

  ### set upper-case region name based on moad
  ( $regionname = $moad ) =~ tr/a-z/A-Z/;
  $regionkey =  $regionname ;
  ( $RUNARG = $moad ) =~ s|-window||i ;  $RUNARG =~ tr/a-z/A-Z/;
  ### set IWINDOW based on $moad
  if( $moad !~ m|-window| ) 
    { $IWINDOW = 0; }
  else
    { $IWINDOW = 1; }
  ### extract day&time from filename
  ( $filename = $wrffilename ) =~ s|.*/([^/]*)|$1| ;
  ( $head,$filemm,$tail ) = split /-/, $1 ;
  ( $fileyyyy = $head ) =~ s|.*_([0-9][0-9][0-9][0-9]).*|$1| ;
  ( $filedd = $tail ) =~ s|([0-9][0-9])_.*|$1| ;
   $jyr4 = $fileyyyy ; 
   $jmo2 = $filemm ;
   $jda2 = $filedd ;
   ( $fcsthr = $tail ) =~ s|.*_([0-9][0-9]):.*|$1| ;
   ( my $fcstmin = $tail ) =~ s|.*_[0-9][0-9]:([0-9][0-9]):.*|$1| ;

### PRINT INFO
  if ( $LPRINT>0 )
  {
    print $PRINTFH "$RUNARG plot for region $moad => IWINDOW=$IWINDOW  LSEND,LSAVE= $LSEND $LSAVE\n";
    print $PRINTFH "  for  WRFfile= $wrffilename \n";
    print $PRINTFH "  uses NCLfile= $RASP_NCLFILE \n";
    #4test:  print "  MOAD= $moad REGIONNAME= $regionname RUNARG= $RUNARG FILENAME= $filename\n";
  } 

#####################################################################################
####################  START OF SETUP INFO EXTRACTED FROM ASP.PL  ####################
#####################################################################################

### treat unused extracted variables 
  $GRIBDIR =  '';
  $MODELTYPE = '';
######################################################################
### FOR -WINDOW DIRECTORY, $LDOWINDOW=2 USES w2 IN FILE NAME FOR $LSEND/$LSAVE>0 _ONLY (NOT for other plots)
### (default value set further below)
  $LDOWINDOW{'NONE'} = 0;
  $LDOWINDOW{'NONE-WINDOW'} = 1;   # should always be 1, to give window-only run
  $LDOWINDOW{'PANOCHE'} = 0;
  $LDOWINDOW{'PANOCHE-WINDOW'} = 1;   # should always be 1, to give window-only run
  $LDOWINDOW{'WILLIAMS'} = 0;
  $LDOWINDOW{'WILLIAMS-WINDOW'} = 1;   # should always be 1, to give window-only run
  $LDOWINDOW{'GREATBRITAIN'} = 0;
  $LDOWINDOW{'GREATBRITAIN-WINDOW'} = 1;   # should always be 1, to give window-only run
  $LDOWINDOW{'GB-ORIG'} = 0;
  $LDOWINDOW{'GB-NOAH'} = 0;
  $LDOWINDOW{'GB-RUC'} = 0;
  $LDOWINDOW{'SW_SOUTHAFRICA'} = 0;
  $LDOWINDOW{'SW_SOUTHAFRICA-WINDOW'} = 1;   # should always be 1, to give window-only run
  $LDOWINDOW{'MINDEN'} = 0;
  $LDOWINDOW{'CANV'} = 0;  
  $LDOWINDOW{'SW_SOUTHAFRICA'} = 0;  
  $LDOWINDOW{'S_NEWZEALAND'} = 0;  
  $LDOWINDOW{'GOVCUP'} = 0;
  $LDOWINDOW{'GOVCUP-WINDOW'} = 1;   # should always be 1, to give window-only run
  $LDOWINDOW{'BLACKFOREST_CO'} = 0;  
  $LDOWINDOW{'BLACKFOREST_EXPAND'} = 0;  
  $LDOWINDOW{'UK+0'} = 0;  
  $LDOWINDOW{'UK12'} = 0;  
  $LDOWINDOW{'UK+1'} = 0;  
  $LDOWINDOW{'UK+2'} = 0;  
  $LDOWINDOW{'UK+3'} = 0;  
  $LDOWINDOW{'UK+4'} = 0;  
  $LDOWINDOW{'UK+5'} = 0;  
  $LDOWINDOW{'UK+6'} = 0;  
######################################################################

  ###### SET DIRECTORIES
  ### DETERMINE SCRIPT DIRECTORY - this should be automatic but can over-ride here if necessary
  ### require latlon<->ij conversion scripts to be in current directory
  if( $0 =~ m|^/| ) { ( $SCRIPTDIR = "${0}" ) =~ s|/[^/]*$|| ; }
  else              { ( $SCRIPTDIR = "$ENV{'PWD'}/${0}" ) =~ s|[\./]*/[^/]*$|| ; }
  #unused ( $BASEDIR = $SCRIPTDIR ) =~ s|/[R]*ASP/UTIL[/]*||i ;
  ### SET SITE DEPENDENT VARIABLES (use separate file to avoid tar update overwrite)
  require "$SCRIPTDIR/sub.rasp_site_parameters.PL" ;
  ### SET SITE DEPENDENT DIRECTORIES
  ### apache popup skewt run on SM => $ENV{PWD}=blank $0=/home/admin/DRJACK/RASP/UTIL/plot.wrfoutfile.PL
  ### apache popup skewt run on SM => before &site_directories, $ENV{HOME}=/home/admin  $BASEDIR=(undefined)        $SCRIPTDIR=/home/admin/DRJACK/RASP/UTIL
  ### apache popup skewt run on SM => after  &site_directories, $ENV{HOME}=/home/admin  $BASEDIR=/home/admin/DRJACK $SCRIPTDIR=/home/admin/DRJACK/RASP/UTIL
  #4testprint: `echo "PWD= $ENV{'PWD'} & 0= $0 << " >> /var/www/cgi-bin/LOG/plot.wrfoutfile.test_prints`;
  &site_directories ;
  #pre-&site_directories  ### make HOME machine specific, so that other-"admin" users can run on SM
  #pre-&site_directories  ###      and pass that to child scripts
  #pre-&site_directories  $hostname = `hostname`; chomp( $hostname );
  #pre-&site_directories  if ( $hostname =~ 'drjack' )
  #pre-&site_directories    { $ENV{'HOME'} = '/home/admin';  }
  #pre-&site_directories  elsif ( $hostname eq 'localhost.localdomain' || $hostname eq 'aeolus' )
  #pre-&site_directories    { $ENV{'HOME'} = '/home/glendeni';  }
  #pre-&site_directories  else
  #pre-&site_directories    { die "$program EXIT ERROR: unknown hostname = $hostname"; }
  #pre-&site_directories  $HOME = $ENV{'HOME'};
  #pre-&site_directories  ### BASE directory
  #pre-&site_directories  $BASEDIR = "$HOME/DRJACK";
  ### ASP base directory
	### PAULS
	$HOME = "/var/www/cgi-bin";
  ## PAULS: Add . to LD_LIBRARY_PATH
  $ENV{'LD_LIBRARY_PATH'} = $HOME ;

  # $DIR = "$BASEDIR/RASP";
	$DIR  = "/home/rasp";

  ### WRF base directory (WRFV2+WRFSI are subdirectories)
  $WRFBASEDIR="$HOME/WRF";
  ### run subdirectory - PRESENTLY HARDWIRED TO STATIC VALUE, NOT TO $RUNARG
  $RUNDIR = "${DIR}/RUN";
  #notimplemented $RUNDIR = "${DIR}/$RUNARG";
  ### directory for grib file - *** MUST AGREE WITH VALUE IN WRFSI/extdata/static/grib_prep.nl
  $MODELDIR = "${RUNDIR}/$MODELTYPE";
  $GRIBDIR = "$MODELDIR/GRIB";
  ### directory for plotting files (overlays, executeables)
  #unused $PLOTDIR = "${DIR}/PLOT";
  ### directory for saved files (uses separate subdirectorys for each region
  ###   (don't use RUNDIR, since can then have separate RUNARG jobs writing to same directory)
  $SAVEDIR = "${DIR}/SAVE";
  ### asp utilities directory - including copy,plot programs & overlay,gif files
  # PaulS No longer needed $UTILDIR = "${RUNDIR}/UTIL";
  ### directory for temporary plot, ftp/cp files
  $OUTDIR = "${RUNDIR}/OUT";
  ###### SET EXTERNAL PROGRAM INFO
  ### gnu zip program
  #UNUSED: $GZIP = "$UTILDIR/gzip";
  ### regular zip program
  #unused $ZIP = "$UTILDIR/zip";
  #xi $CONVERT = '/usr/bin/X11/convert';
  #LINUX(RedHat):
  ### ImageMagick convert program (should include LZW compressions if loop created)
  $CONVERT = "convert";
  ### USE SEPARATE CALL TO NCARG CTRANS so can mix versions if need be
  $CTRANS = "/home/rasp/UTIL/ctrans";
  ##### ENVIRONMENTAL PARAMS NEEDED FOR NCAR GRAPHICS (CTRANS)
  ### *NB* ON SM THIS IS NCL-ONLY 

	#PAULS
  # $NCARG_ROOT = "$BASEDIR/NCARG";
  $NCARG_ROOT = "/home/rasp/UTIL/NCARG";

  ### WRF NCL DIRECTORY contains ncl plotting stuff
  $NCLDIR = "$WRFBASEDIR/NCL";
  ####### HTML BASE DIRECTORY - where plot images sent to
  ### use link on sm so can use same directory as on xi
  $HTMLBASEDIR = "$HOME/rasp/RASP/HTML";

#####################################################################################
####################   END OF SETUP INFO EXTRACTED FROM ASP.PL   ####################
#####################################################################################

    ### FROM sub setup_region_info
    ### (default value set further below)
    #####################  START OF NONE REGION SETUP  ####################
      $regiontimeid{'NONE'} = 'PST';
      $regiontimeadj{'NONE'} = -8; 
      #unused $regiontimebase{'NONE'} = 21;
    #####################  START OF NONE-WINDOW REGION SETUP  ####################
      $regiontimeid{'NONE-WINDOW'} = 'PST';
      $regiontimeadj{'NONE-WINDOW'} = -8;
      #unused $regiontimebase{'NONE-WINDOW'} = 21;
    #####################  START OF PANOCHE REGION SETUP  ####################
      $regiontimeid{'PANOCHE'} = 'PST';
      $regiontimeadj{'PANOCHE'} = -8; 
      #unused $regiontimebase{'PANOCHE'} = 21;
    #####################  START OF PANOCHE-WINDOW REGION SETUP  ####################
      $regiontimeid{'PANOCHE-WINDOW'} = 'PST';
      $regiontimeadj{'PANOCHE-WINDOW'} = -8;
      #unused $regiontimebase{'PANOCHE-WINDOW'} = 21;
    #####################  START OF WILLIAMS REGION SETUP  ####################
      $regiontimeid{'WILLIAMS'} = 'PST';
      $regiontimeadj{'WILLIAMS'} = -8; 
      #unused $regiontimebase{'WILLIAMS'} = 21;
    #####################  START OF WILLIAMS-WINDOW REGION SETUP  ####################
      $regiontimeid{'WILLIAMS-WINDOW'} = 'PST';
      $regiontimeadj{'WILLIAMS-WINDOW'} = -8;
      #unused $regiontimebase{'WILLIAMS'} = 21;
    #####################  START OF MINDEN REGION SETUP  ####################
      $regiontimeid{'MINDEN'} = 'PST';
      $regiontimeadj{'MINDEN'} = -8; 
      #unused $regiontimebase{'MINDEN'} = 21;
    #####################  START OF CANV REGION SETUP  ####################
      $regiontimeid{'CANV'} = 'PST';
      $regiontimeadj{'CANV'} = -8; 
      #unused $regiontimebase{'CANV'} = 21;
    #####################  START OF SW_SOUTHAFRICA REGION SETUP  ####################
      $regiontimeid{'SW_SOUTHAFRICA'} = 'LST';
      $regiontimeadj{'SW_SOUTHAFRICA'} = +2; 
    #####################  START OF SW_SOUTHAFRICA-WINDOW REGION SETUP  ####################
      $regiontimeid{'SW_SOUTHAFRICA-WINDOW'} = 'LST';
      $regiontimeadj{'SW_SOUTHAFRICA-WINDOW'} = +2; 
    #####################  START OF GREATBRITAIN REGION SETUP  ####################
      $regiontimeid{'GREATBRITAIN'} = 'GMT';
      $regiontimeadj{'GREATBRITAIN'} = +0; 
    #####################  START OF GREATBRITAIN-WINDOW REGION SETUP  ####################
      $regiontimeid{'GREATBRITAIN-WINDOW'} = 'GMT';
      $regiontimeadj{'GREATBRITAIN-WINDOW'} = +0; 
    #####################  START OF GB-ORIG REGION SETUP  ####################
      $regiontimeid{'GB-ORIG'} = 'GMT';
      $regiontimeadj{'GB-ORIG'} = +0; 
    #####################  START OF GB-NOAH REGION SETUP  ####################
      $regiontimeid{'GB-NOAH'} = 'GMT';
      $regiontimeadj{'GB-NOAH'} = +0; 
    #####################  START OF GB-RUC REGION SETUP  ####################
      $regiontimeid{'GB-RUC'} = 'GMT';
      $regiontimeadj{'GB-RUC'} = +0; 
    #####################  START OF S_NEWZEALAND REGION SETUP  ####################
      $regiontimeid{'S_NEWZEALAND'} = 'LST';
      $regiontimeadj{'S_NEWZEALAND'} = +11; 
    #####################  START OF GOVCUP REGION SETUP  ####################
      $regiontimeid{'GOVCUP'} = 'EST';
      $regiontimeadj{'GOVCUP'} = -5; 
    #####################  START OF GOVCUP-WINDOW REGION SETUP  ####################
      $regiontimeid{'GOVCUP-WINDOW'} = 'EST';
      $regiontimeadj{'GOVCUP-WINDOW'} = -5; 
    #####################  START OF BLACKFOREST_CO REGION SETUP  ####################
      $regiontimeid{'BLACKFOREST_CO'} = 'MST';
      $regiontimeadj{'BLACKFOREST_CO'} = -7 ; 
    #####################  START OF BLACKFOREST_EXPAND REGION SETUP  ####################
      $regiontimeid{'BLACKFOREST_EXPAND'} = 'MST';
      $regiontimeadj{'BLACKFOREST_EXPAND'} = -7 ; 
    #####################  START OF YOURREGION REGION SETUP  ####################
    ### THESE PARAMETER NOT USED AT PRESENT TIME, BUT KEPT FOR LATER USE ####
      $regiontimeid{'UK+0'} = 'GMT';
      $regiontimeid{'UK12'} = 'GMT';
      $regiontimeid{'UK+1'} = 'GMT';
      $regiontimeid{'UK+2'} = 'GMT';
      $regiontimeid{'UK+3'} = 'GMT';
      $regiontimeid{'UK+4'} = 'GMT';
      $regiontimeid{'UK+5'} = 'GMT';
      $regiontimeid{'UK+6'} = 'GMT';
      $regiontimeadj{'UK+0'} = +0; 
      $regiontimeadj{'UK12'} = +0; 
      $regiontimeadj{'UK+1'} = +0; 
      $regiontimeadj{'UK+2'} = +0; 
      $regiontimeadj{'UK+3'} = +0; 
      $regiontimeadj{'UK+4'} = +0; 
      $regiontimeadj{'UK+5'} = +0; 
      $regiontimeadj{'UK+6'} = +0; 
      #unused $regiontimebase{'YOURREGION'} = 21;

#####################################################################################
###### SET REGION DEFAULT VALUES
if( ! defined $LDOWINDOW{$regionname} )
{ 
  if( $regionname !~ m|-window|i )
    { $LDOWINDOW{$regionname} = 0 ; }
  else
    { $LDOWINDOW{$regionname} = 0 ; }
  print $PRINTFH "*WARNING - $regionname region \$LDOWINDOW not set internally so using default = $LDOWINDOW{$regionname} \n" ; 
}
if( ! defined $regiontimeadj{$regionname} )
{
   $regiontimeid{$regionname} = 'GMT' ; 
   $regiontimeadj{$regionname} = 0 ; 
   #old $regiontimeid{$regionname} = 'PST' ; 
   #old $regiontimeadj{$regionname} = -8 ; 
   print $PRINTFH "*WARNING - $regionname region \$regiontimeadj not set internally so using default = $regiontimeid{$regionname} $regiontimeadj{$regionname} \n" ;
}
#####################################################################################

#####################################################################################
  my %mon = ( '01','Jan', '02','Feb', '03','Mar', '04','Apr', '05','May', '06','Jun',
            '07','Jul', '08','Aug', '09','Sep', '10','Oct', '11','Nov', '12','Dec' );
  @dow = ( "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT" );
########################################################
  $savehistoryhhmm = '2100' ;
  ########### START OF MODEL RUN PARAMETERS FOR NORMAL/WINDOW RUN DOMAINS ###########
  ### SET HISTORY HOUR FOR IMAGES SAVED WHEN LSAVE=1
  $savehistoryhhmm = '2100' ;
  ### FOR NORMAL-RUN ITERATION
  $modelforecastperiodhr[0] = 12;       # used only by initialization programs
  $boundaryupdateperiodhr[0] = 3;       # used only by initialization programs
  ### $ndownboundaryupdateperiodhr must agree with history output interval (but its in minutes)
  $ndownboundaryupdateperiodhr[0] = 0 ;  
  #for3boundaryfiles: $boundaryupdateperiodhr[0] = 6;       # used only by initialization programs
  $domain1_starthh[0] = '12';             # must have grib file available for this time
  $domain2_start_deltamins[0] = 0;     # if non-zero, must set namelist.template INPUT_FROM_FILE=false
  $domain3_start_deltamins[0] = 420;     # if non-zero, must set namelist.template INPUT_FROM_FILE=false
  $domain1_endhh[0] = '00';              # 
  $domain2_end_deltamins[0] = 0;     # relative to domain1
  $domain3_end_deltamins[0] = -120;     # relative to domain1
  # for non-threaded output times to plot (depends upon history output length and increment)
  @{$historyhhmmlist[0]} =  ( '1200', '1500', '1800', '2100', '2200', '0000' );
  #4test: $modelforecastperiodhr[0] = 6;       # used only by initialization programs
  #4test: $domain1_endhh[0] = '18';              # 
  #4test: @{$historyhhmmlist[0]} =  ( '1200', '1500', '1800' );
  ### FOR WINDOWED-RUN ITERATION
  $modelforecastperiodhr[1] = 3;       
  $boundaryupdateperiodhr[1] = 1;     
  ### $ndownboundaryupdateperiodhr must agree with history output interval (but its in minutes)
  $ndownboundaryupdateperiodhr[1] = 1 ;  
  #for3boundaryfiles: $boundaryupdateperiodhr[1] = 6;

  $domain1_starthh[1] = '19';          # must have grib file available at or prior to this time
  $domain2_start_deltamins[1] = 0;     # if non-zero, must set namelist.template INPUT_FROM_FILE=false
  $domain3_start_deltamins[1] = 0;     # if non-zero, must set namelist.template INPUT_FROM_FILE=false
  $domain1_endhh[1] = '22';          
  $domain2_end_deltamins[1] = 0;     # relative to domain1
  $domain3_end_deltamins[1] = 0;     # relative to domain1
  @{$historyhhmmlist[1]} = (  '2100', '2130', '2200' ); 
  #4test: $domain1_starthh[1] = '15';         
  #4test: $domain1_endhh[1] = '18';          
  #4test: @{$historyhhmmlist[1]} = ( '1500', '1600', '1700', '1800' ); 

  ### SW_SOUTHAFRICA
  if ( $RUNARG eq 'SW_SOUTHAFRICA' )
  { 
  $domain1_starthh[0] = '03';           # must have grib file available for this time
  $domain3_start_deltamins[0] = 360;    # if non-zero, must set namelist.template INPUT_FROM_FILE=false
  $domain1_endhh[0] = '15';              
  $domain3_end_deltamins[0] = -180 ;     # relative to domain1
  @{$historyhhmmlist[0]} =  ( '0300', '0600', '0900', '1200', '1500' );
  ### SET HISTORY HOUR FOR IMAGES SAVED WHEN LSAVE=1
  $savehistoryhhmm = '1200' ;
  #window $modelforecastperiodhr[1] = 3;       
  #window $domain1_endhh[1] = '12';          
  #window $domain1_starthh[1] = '09';         
  #window @{$historyhhmmlist[1]} = ( '1200' ); 
  }
  ### S_NEWZEALAND
  if ( $RUNARG eq 'S_NEWZEALAND' )
  { 
  $domain1_starthh[0] = '18';           # must have grib file available for this time
  $domain3_start_deltamins[0] = 360;    # if non-zero, must set namelist.template INPUT_FROM_FILE=false
  $domain1_endhh[0] = '06';              
  $domain3_end_deltamins[0] = -180 ;     # relative to domain1
  @{$historyhhmmlist[0]} =  (  '1800', '2100','0000', '0300','0600' );
  ### SET HISTORY HOUR FOR IMAGES SAVED WHEN LSAVE=1
  $savehistoryhhmm = '0300' ;
  #window $modelforecastperiodhr[1] = 3;       
  #window $domain1_starthh[1] = '00';         
  #window $domain1_endhh[1] = '03';          
  #window @{$historyhhmmlist[1]} = ( '0300' ); 
  }
  ########### END OF MODEL RUN PARAMETERS FOR NORMAL/WINDOW RUN DOMAINS ###########
##########################################################
###### TEST FOR MISSING DATA
if( ! defined $LDOWINDOW{$regionname} ) { die "ERROR STOP - missing LDOWINDOW for region $regionname" ; }
if( ! defined $regiontimeadj{$regionname} ) { die "ERROR STOP - missing regiontimeadj for region $regionname" ; }
###########################################################
    ### don't know actual analhr or fcstperiod but really need fcsthr so use known fcsthr with analhr=0
    ( $localyyyy,$localmm,$localdd,$localhh, $localmin ) = &GMT_plus_mins( $jyr4, $jmo2, $jda2, $analhr, 0, (60*($fcsthr+$regiontimeadj{$regionname})) );
    #reference ( $localyyyy,$localmm,$localdd,$localhh, $localmin ) = &GMT_plus_mins( $jyr4, $jmo2, $jda2, $analhr, 0, (60*($fcstperiod+$regiontimeadj{$regionname})) );
    $savesubdir{$regionname} = sprintf "%s/%s/%4d%02d%02d",$SAVEDIR,$regionname,$localyyyy,$localmm,$localdd;
    #4test: print "savedir: $jyr4 & $jmo2 & $jda2 & $analhr => $localyyyy & $localmm & $localdd & $localhh \n";
#############################################################
##########  OVERRIDE NORMAL CHOMP  ##########
### must be set here to avoid compile warning "jchomp() called too early to check prototype"
### but then edpsub macro cuts off lines above from narrowed region
sub jchomp(@)
### DELETES ENDING NEWLINE ALA REGULAR CHOMP
{
  if ( $_[0] =~ m/(^.*)\n$/ ) { $_[0] = $1; }
  return  ;
}
############################################

  &output_model_results ( $wrffilename ) ; 


########################################################################################
########################################################################################
sub output_model_results (@)
### CREATE WRF PLOTS, DO FTPING + SAVE FOR SINGLE OUTPUT TIME
### *NB* DEPENDS ON EXTERNAL $IWINDOW,$regionname,$regionname_lc,$regionkey
{
  my $wrffilename = $_[0];
  my ( $moad, $kdomain, $domainid, $historyhhmm );

  $moad = $regionname ;
  #JACK- ### EXTRACT $moad FROM FILENAME
  #JACK- ( $moad = $wrffilename ) =~ s|$WRFBASEDIR/WRFV2/RASP/([^/]+)/.*|$1|;
  #old ( $moad = $wrffilename ) =~ s|$WRFBASEDIR/WRFV2/real/([^/]+)/.*|$1|;

  ### AT PRESENT, PLOT 2 DOMAINS
  ### EXTRACT $kdomain FROM FILENAME
  ### allow inclusion of "previous" in filename so can use routine with those filenames
  ( $kdomain = $wrffilename ) =~ s|.*wrfout_d0([1-3]).*|$1|;


  ### SET DOMAIN NAME 3 FOR WINDOWED CASE
  ### AT PRESENT, PLOT 2 DOMAINS
  ### $domainid d/w is posted&saved id used in $regionname directory (vice $moad) for normal/windowed domain
  if( $moad =~ m|-window|i && $LDOWINDOW{$regionkey} == 2 )
    { $domainid = 'w' ; }
  else
    { $domainid = 'd' ; }
    
  ( $historyhhmm = $wrffilename ) =~ s/.*wrfout_d.*_([0-9][0-9]:[0-9][0-9]):.*/$1/;
  $historyhhmm =~ s|:||;

  ### set date variables for display
  my ( $historyhhmmplus, $fcstperiod ); 

### DAY/HR SELECTION - used to set historyhhmmplus
if ( $historyhhmm >= $historyhhmmlist[$IWINDOW][0] )
  { $historyhhmmplus = $historyhhmm ; }
  else 
  { $historyhhmmplus = $historyhhmm + 2400 ; }
  ### allow forecast period string to be decimal hours but strip off any .0 
  $fcstperiod = substr ( ${historyhhmmplus}, 0, 2 ) +0.01667*substr ( ${historyhhmmplus}, 2, 2 ) -$fileanaltime ;
  if( $fcstperiod < 0 ) { $fcstperiod += 24; }
  $fcstperiod = sprintf "%.1f", $fcstperiod ;
  $fcstperiod =~ s|.0$|| ;
  
  ### CREATE WEB IMAGES FROM WRF OUTPUT FILE
  ##########################################################################################
  ### **********  LIST OF PARAMETERS MUST MATCH OUTPUT NUMBER AND ORDER IN asp.ncl **********
  ### **********  but name itself can differ - this is name used for png filename **********
  ### FULL PARAMETER LIST - 12 Sep 2005
#JACK - NOW SET @imagenamelist AT TOP  @imagenamelist = ( "hbl","dbl","hwcrit","dwcrit","wstar","bsratio", "sfcsun","sfcshf", "blwind","sfcwind", "zsfclcl","zsfclcldif","zsfclclmask", "zblcl","zblcldif","zblclmask","rhblmax","cwbase", "boxwmax","press850","press700","press500", "bltopvariab","bltopwind","wblmaxmin","zwblmaxmin", "blwindshear", "sfctemp","sfcdewpt", "cape", "experimental1","experimental2","wstar_bsratio" );
  #old @imagenamelist = ( "sfcsun","sfcshf","dbl","hbl","hwcrit","wstar","wblmaxmin","zwblmaxmin","blwind","sfcwind","bltopwind","rhblmax","cwbase","zsfclcl","zsfclcldif","zsfclclmask", "bsratio", "sfctemp","sfcdewpt", "zblcl","zblcldif","zblclmask", "bltopvariab", "blwindshear", "cape", "boxwmax","press850","press700","press500"  );
  #old @imagenamelist = ( "sfcsun","sfcshf","dbl","hbl","hwcrit","wstar","wblmaxmin","zwblmaxmin","blwind","sfcwind","bltopwind","rhblmax","cwbase","zsfclcl","zsfclcldif","zsfclclmask", "bsratio", "sfctemp","sfcdewpt", "zblcl","zblcldif","zblclmask", "bltopvariab", "blwinddif", "cape","p850","p700","p500","boxwmax"  );
  ### ADD NUMBER OF SOUNDINGS DEPENDING ON REGION, AS SET IN asp.ncl
  if ( $limagenameinput == 0 && $regionname eq 'PANOCHE' )
    { push @imagenamelist, ( 'sounding1','sounding2' );  }
  if (  $limagenameinput == 0 && $regionname eq 'YOURREGIONSOUNDING'  ) 
    { push @imagenamelist, ( 'sounding1' );  }
  #4test-1plot (but asp.ncl controls number plotted): @imagenamelist = ( 'blwind' );
  ### PARTIAL PARAMETER LIST OVER-RIDES ABOVE : @imagenamelist = ( "boxwmax","press850" );
  ### PARTIAL PARAMETER LIST OVER-RIDES ABOVE : @imagenamelist = ( "wfpm" );
  ##########################################################################################

  #JACK ADDITION - allow image output directory to be command-line arg
  ### directory for temporary plot, ftp/cp files
  if( ! defined $imagedir )
  { 
    $imagedir = "$OUTDIR/$regionname" ;
    $moad = $regionname ;
  }

  ### ncl-environment variables
  $ENV{'ENV_NCL_REGIONNAME'} = $regionname ;
  $ENV{'ENV_NCL_FILENAME'} = $wrffilename ;
  #JACK ADDITION - allow image output directory to be command-line arg
  $ENV{'ENV_NCL_OUTDIR'} = $imagedir ;
  #JACK- $ENV{'ENV_NCL_OUTDIR'} = "$OUTDIR/$moad" ;
   ### use local time for plot print
  ( $filename = $wrffilename ) =~ s|.*/([^/]*)|$1| ;
  ( $head,$filemm,$tail ) = split /-/, $filename ;
  ( $fileyyyy = $head ) =~ s|.*_([0-9][0-9][0-9][0-9]).*|$1| ;
  ( $filedd = $tail ) =~ s|([0-9][0-9])_.*|$1| ;
  ( $filehh = $tail ) =~ s|.*_([0-9][0-9]):.*|$1| ;
  ( $filemin = $tail ) =~ s|.*_[0-9][0-9]:([0-9][0-9]).*|$1| ;
  ( $localyyyy,$localmm,$localdd,$localhh, $localmin ) = &GMT_plus_mins( $fileyyyy, $filemm, $filedd, $filehh, $filemin, (60*$regiontimeadj{$regionname}) );
  ( $localday = $localdd ) =~ s|^0|| ;
  $localmon = $mon{$localmm} ;
  $localdow = $dow[ &dayofweek( $localdd, $localmm, $localyyyy ) ];     # uses Date::DayOfWeek
  # shouldnt matter which $ifile used here since only need "curr day" and should be same for all in this group
    ### set parameter list
#NEW-NCL  
    $ENV{'ENV_NCL_PARAMS'} = sprintf "%s", ( join ':',@imagenamelist )  ;

### REMOVE PRINT OF FCST PERIOD SINCE UNKNOWN (only fcst hr known from filename)
  $ENV{'ENV_NCL_ID'} = sprintf "Valid %02d%02d %s %s %s %s %d", $localhh,$localmin, $regiontimeid{$regionname}, $localdow, $localday, $localmon, $localyyyy ;
  #original $ENV{'ENV_NCL_ID'} = sprintf "%s hrFcst - Valid %02d%02d %s %s %s %s %d", $fcstperiod, $localhh,$localmin, $regiontimeid{$regionname}, $localdow, $localday, $localmon, $localyyyy ;
  #old $ENV{'ENV_NCL_ID'} = sprintf "%s hrFcst - Valid %s %d %dZ", $fcstperiod, $validmon{'curr.'}, $jda2, $historyhhmmplus ;
  #older $ENV{'ENV_NCL_ID'} = sprintf "%dZ Init - Valid %4d-%02d-%02d %dZ", $fileanaltime, $jyr4,$jmo2,$jda2, $historyhhmmplus ;

  ### run ncl for this file to create individual ncgm files
#NEW-NCL
  ### ensure removal of old ncgm files
  `rm -f $ENV{'ENV_NCL_OUTDIR'}/*.ncgm 2>/dev/null`;
  if( ! defined $LHTML )
  {
    my $nclout = `NCARG_ROOT=$NCARG_ROOT; export NCARG_ROOT ; cd $NCLDIR ; $NCARG_ROOT/bin/ncl $RASP_NCLFILE >| rasp.ncl.out.$moad.$kdomain 2>&1`;
  }
  else
  {
   ### for apache run do not have permission to write to usual files so write to /tmp 
    # PAULS my $nclout = `NCARG_ROOT=$NCARG_ROOT; export NCARG_ROOT ; cd $NCLDIR ; $NCARG_ROOT/bin/ncl $RASP_NCLFILE >| /tmp/rasp.ncl.out.$moad.$kdomain 2>&1 ; chmod ugo+rw /tmp/rasp.ncl.out.$moad.$kdomain`;
    my $nclout = `NCARG_ROOT=$NCARG_ROOT; export NCARG_ROOT ; $NCARG_ROOT/bin/ncl $RASP_NCLFILE >| /tmp/rasp.ncl.out.$moad.$kdomain 2>&1 ; chmod ugo+rw /tmp/rasp.ncl.out.$moad.$kdomain`;
  }

  ### LOOP OVER ALL NCGM FILES CREATED 
  for ($iimage=0; $iimage<=$#imagenamelist; $iimage++ )
  {
    my $iimageid = $iimage +1;
    $imagename = $imagenamelist[$iimage] ;
#NEW-NCL
    $ncgmname = sprintf "%s.ncgm", $imagename ;
    #4test: print "TEST: $ENV{'ENV_NCL_OUTDIR'} ncgmname= $ncgmname \n";

    ### skip if non-existent or stub ncgm file (needed for domains with no soundings)
    if( -f "$ENV{'ENV_NCL_OUTDIR'}/$ncgmname" && -s "$ENV{'ENV_NCL_OUTDIR'}/$ncgmname" > 4000 )
    {

      ### AT PRESENT, PLOT 2 DOMAINS
      ### "d" indicates "domain" for plots in run directory, but "w" for "windowed region" when posted/stored 
      ###     since window domains combined with non-window domains when posted/stored
      $pngname = sprintf "%s.%s%02d%02dlst.d${kdomain}.png", $imagename,$localsoarday,$localhh,$localmin ;
      $pngpostname = sprintf "%s.%s%02d%02dlst.${domainid}${kdomain}.png", $imagename,$localsoarday,$localhh,$localmin ;

      ### ensure removal of old sun and png file to prevent inadvertent use
      `rm -f $imagedir/tmp.rasp.sun $imagedir/$pngname`;

      ### convert individual ncgm files into png images
      ### NCAR CTRANS CONVERTS METAFILE TO SQUARE BITMAP
      # defaultsize=512x512 - alter using "-resolution widthxheight"
			#PAULS
      # die("$CTRANS -res $imagesize -d sun -outfile $imagedir/tmp.rasp.sun $ENV{'ENV_NCL_OUTDIR'}/$ncgmname 2>&1" );
      jchomp( my $ctransout = `NCARG_ROOT=$NCARG_ROOT; export NCARG_ROOT ; $CTRANS -res $imagesize -d sun -outfile $imagedir/tmp.rasp.sun $ENV{'ENV_NCL_OUTDIR'}/$ncgmname 2>&1` );

      ### convert converts square bitmap to (sometimes) non-square png
      jchomp( my $convertout = `$CONVERT $imagedir/tmp.rasp.sun $imagedir/$pngname ; chmod ugo+rw $imagedir/$pngname` );
   
      ### SEND IMAGE TO WEBSITE
      if( $LSEND > 0 )
      {
        ### allow for tests using filename pre-pended with "test."
        if( $LSEND == 1 )
        { $postedpngname = "test.${pngpostname}"; }
        else
        { $postedpngname = $pngpostname; }
        ### AT PRESENT, PLOT 2 DOMAINS
          ### write to html location, saving previous image file
          `mv -f $HTMLBASEDIR/$regionname/FCST/${postedpngname}  $HTMLBASEDIR/$regionname/FCST/previous.${postedpngname} 2>/dev/null`;
          `cp -pf $imagedir/${pngname} $HTMLBASEDIR/$regionname/FCST/${postedpngname}`;
          ### SPECIAL CASE - WEBSITE ONLY - WINDOWED CASE ONLY - CREATE IMAGE LOOP
          ###  FOR 1km RESOLUTION ONLY => PANOCHE ONLY -  HARDWIRE IF AND CONVERT FILELIST FOR 2200 
          if( ( $LDOWINDOW{$regionkey} == 0 && $kdomain == 3 && $historyhhmm eq '2200' ) || ( $LDOWINDOW{$regionkey} > 0 && $moad =~ m|-window|i && $kdomain == 2 && $historyhhmm eq '2200' ) ) 
          {
            `mv -f $HTMLBASEDIR/$regionname/FCST/$imagename.${localsoarday}loop.w2.gif  $HTMLBASEDIR/$regionname/FCST/previous.$imagename.${localsoarday}loop.w2.gif 2>/dev/null`;
            my $loopcreateout = `$CONVERT -loop 30 -delay 100 $imagedir/$imagename.${localsoarday}1[34]*lst.d${kdomain}.png $HTMLBASEDIR/$regionname/FCST/$imagename.${localsoarday}loop.${domainid}${kdomain}.gif`;
            #old `mv -f $HTMLBASEDIR/$regionname/FCST/$imagename.loop.w2.gif  $HTMLBASEDIR/$regionname/FCST/previous.$imagename.loop.w2.gif 2>/dev/null`;
            #old my $loopcreateout = `$CONVERT -loop 30 -delay 100 $OUTDIR/$moad/$imagename.1[34]*lst.d${kdomain}.png $HTMLBASEDIR/$regionname/FCST/$imagename.loop.${domainid}${kdomain}.gif`;
            #4testprint: print $PRINTFH "IMAGE LOOP: $imagename => $loopcreateout \n";
          }
      }

      ### SEND SINGLE IMAGE TO BROWSER (STDOUT with html header)
      if( defined $LHTML ) {
        if( $iimage == 0 ) {
          use CGI::Carp;
          open (HTML, "<$imagedir/$pngname")|| die 'plot.wrfoutfile.PL: HTML plot failed';
          print "Content-Type: image/png\n\n";
          while (<HTML>)
           { print $_; }
          #4testprint: print "INLINE OUTPUT OF IMAGE FILE $imagedir/$pngname \n";
          ### cleanup
          `rm -f $imagedir/$pngname ` ;
        }
        else {
          if ($LPRINT>1) {
            print $PRINTFH "  *WARNING: SKIPPING MULTIPLE PLOTS FOR HTML FLAG - iimage= $iimage \n";
          }
        }      
      }

      if ($LPRINT>1) {
        print $PRINTFH "> PLOTTED $imagename for $moad ${domainid}${kdomain} at ${historyhhmmplus}Z = $localsoarday ${localhh}${localmin} $regiontimeid{$regionname} $localday $localmon $localyyyy to ${imagedir}/${pngname}\n";
      }
    }
    else {  
      open (HTML, "<$imagedir/$pngname")|| die 'plot.wrfoutfile.PL: HTML plot failed';
      print "Content-Type: text/html\n\n";
      print "<br><br><br><br><h2 align='center'>Bad or No Data</h2>";

      if ($LPRINT>1) {  print $PRINTFH "  *WARNING: SKIPPING NON-EXISTENT OR BAD (too small)  NCGM FILE $ENV{'ENV_NCL_OUTDIR'}/$ncgmname \n"; } 
      if ($LPRINT>1) {  print $PRINTFH "  *         OCCURS WHEN ATTEMPTING TO PLOT NON-EXISTENT VARIABLE \n"; }
      # if ($LPRINT>1) {  print $PRINTFH "  *         HAS OCCURRED WHEN TRYING TO PLOT TO RUN DIRECTORY, BUT OTHER TIMES THAT HAS WORKED !? \n"; }
    }
  }

  $time = `date +%H:%M:%S`;
  ### SEND MESSAGES
  if( $LSEND > 0 ) { if ($LPRINT>1) { print $PRINTFH "  SENT $moad ${domainid}${kdomain} plots for ${historyhhmmplus}Z = ${localhh}:${localmin} $regiontimeid{$regionname} $localday $localmon $localyyyy at $time" ; } }

  ### SAVE DESIRED IMAGE FILES - at present for only one time
  ### save directory based on region-specific julian date intended to represent soaring day
  if( $LSAVE > 0 && $historyhhmm == $savehistoryhhmm )
  {
    ### CREATE SUBDIR
    `mkdir -p $savesubdir{$regionname} 2>/dev/null`;
    ### SAVE IMAGE FILES 
    for ($iimage=0; $iimage<=$#imagenamelist; $iimage++ )
    {
      ### skip if non-existent ncgm file (should happen only for soundings)
      if( -f "$imagedir/${pngname}" )
      {
        ### AT PRESENT, PLOT 2 DOMAINS BUT SAVE ONLY DOMAIN 2
        ### these lines should match those in image creation loop above
        ### "d" indicates "domain" for plots in run directory, but "w" for "windowed region" when posted/stored 
        ###     since window domains combined with non-window domains when posted/stored
        $imagename = $imagenamelist[$iimage] ;
        $pngname = sprintf "%s.%02d%02dlst.d${kdomain}.png", $imagename,$localhh,$localmin ;
        $pngstorename = sprintf "%s.%02d%02dlst.${domainid}${kdomain}.png", $imagename,$localhh,$localmin ;
        #old $pngname = sprintf "%s.%04dz.d${kdomain}.png", $imagename,$historyhhmmplus ;
        #old $pngstorename = sprintf "%s.%04dz.${domainid}${kdomain}.png", $imagename,$historyhhmmplus ;
        `cp -pf $imagedir/${pngname} ${savesubdir{$regionname}}/${pngstorename}`;
      }
    }
    ### make SAVE files read-only to prevent accidental over-write
   `chmod -f 444 $savesubdir{$regionname}/*`;
    $time = `date +%H:%M:%S`;
    if ($LPRINT>1) { print $PRINTFH "  SAVED $moad ${domainid}${kdomain} plot images for ${historyhhmmplus}Z = ${localhh}:${localmin} $regiontimeid{$regionname} $localday $localmon $localyyyy to $savesubdir{$regionname} at $time"; } 
  }

  ### CLEANUP of sun and ncgm file
  `rm -f $imagedir/tmp.rasp.sun $imagedir/*.tmp.ncgm 2>/dev/null`;
  if( ! defined $opt_k )
  {
    `rm -f $ENV{'ENV_NCL_OUTDIR'}/$ncgmname 2>/dev/null`;
  }

}
#############################################################################################
#############################################################################################
sub GMT_plus_mins ()
{
### CALC DAY/TIME AFTER ADDING $DELmins MINUTES TO INPUT DAY/TIME VALUES
### INPUT/OUTPUT YEAR=4digit MONTH=01-12 DAY=01-31
### MUST ALLOW FOR PERL ZERO INDEXING AND YEAR-1900
  use Time::Local;
  my ( $year1,$month1,$day1,$hr1,$min1, $DELmins ) = @_;
  my ( $csec, $year2,$month2,$day2,$hr2,$min2,$sec2, $wday,$jday,$isdst );
  $csec = timegm( 0,$min1,$hr1,$day1,($month1-1),($year1-1900) );
  $csec += 60*$DELmins ;
  ( $sec2,$min2,$hr2,$day2,$month2,$year2, $wday,$jday,$isdst ) = gmtime( $csec );;
  $min2 = sprintf "%02d", $min2 ;
  $hr2 = sprintf "%02d", $hr2 ;
  $day2 = sprintf "%02d", $day2 ;
  $month2 = sprintf "%02d", ($month2+1) ;
  $year2 += 1900 ;
  return $year2,$month2,$day2,$hr2,$min2;
}
###########################################################################################
###########################################################################################
sub dayofweek
### Returns the NUMERICAL (0-6, 0=sunday) Day of the Week for any date between 1500 and 2699.
### >>> Month should be in the range 1..12 <<<  Year=yyyy (2 digit gives same result except for century)
#      $dow = dayofweek( 25, 10, 1971 );
### (extracted from Date::DayofWeek)
{
    my ($day, $month, $year) = @_;
  ###JACK - STRIP ANY LEADING ZEROS
  $day = &strip_leading_zero( $day );
  $month = &strip_leading_zero( $month );
    # When is doomsday this year?
    my $doomsday = &Doomsday( $year );
    # And when is doomsday this month?
    my @base = ( 0, 0, 7, 4, 9, 6, 11, 8, 5, 10, 7, 12 );
    @base[0,1] = leapyear($year) ? (32,29) : (31,28);
    # And how far after that are we?
    my $on = $day - $base[$month - 1];
    $on = $on % 7;
    # So, the day of the week should be doomsday, plus however far on we are
    return ($doomsday + $on) % 7;
}
sub Doomsday
### Doomsday is a concept invented by John Horton Conway to make it easier to
### figure out what day of the week particular events occur in a given year.
### Returns the day of the week (in the range 0..6) of doomsday in the particular
### year given. If no year is specified, the current year is assumed.
### (extracted from Date::Doomsday)
#    $doomsday = doomsday( 1945 );
{
    my $year = shift;
    $year = ( localtime(time) )[5] unless $year;
#jack: turn off warning so can use 2 digit date (but incorrect for centry)
#jack-    if ($year < 1583) {
#jack-        warn "The Gregorian calendar did not come into use until 1583. Your date predates the usefulness of this algorithm."
#jack-    }
    my $century = $year - ( $year % 100 );
    my $base = ( 3, 2, 0, 5 )[ ( ($century - 1500)/100 )%4 ];
    my $twelves = int ( ( $year - $century )/12);
    my $rem = ( $year - $century ) % 12;
    my $fours = int ($rem/4);
    my $doomsday = $base + ($twelves + $rem + $fours)%7;
    return $doomsday % 7;
}
sub leapyear
###  returns 1 or 0 if a year is leap or not  (4digit year - 2 digit gives same result except for century)
### (extracted from Date::Leapyear)
#    $true = leapyear( 2004 );
{
    my $year = $_[0];
    #bad? my ($year) = @_;
    return 1 if (( $year % 400 ) == 0 ); # 400's are leap
    return 0 if (( $year % 100 ) == 0 ); # Other centuries are not
    return 1 if (( $year % 4 ) == 0 ); # All other 4's are leap
    return 0; # Everything else is not
}
#########################################################################
#########################################################################
sub strip_leading_zero ()
### subroutine strip_leading_zero
{
  my $string = shift @_;
  my $value;
  if ( substr( $string, 0,1 ) == 0 )
    { $value = substr( $string, 1); }
  else
    { $value = $string; }
  return $value;
}
# end of strip_leading_zero
#########################################################################
#########################################################################
###########################################################################################
###########################################################################################
