#! /usr/bin/perl  -w 

##### PAULS - 2008-08-02 Warnings turned off at lines 900 1025 1039 & 1062 to avoid cluttering logs with errors from sqrt(-ve num) #####
##### PAULS - 2008-08-03 Can't have -T flag to perl. Opening a file for writing is not allowed - see "man perlsec"
#expect at least 9 arguments:
if ( $#ARGV <  8 ) {
#4test:  if ( $#ARGV != -1 ) {
#-----------------adescription1------------------------------------
print "Calc+Output optimal time along path based on \"speed to fly\" eqns for \$1=Region \$2=Grid \$3=valid.Day \$4=valid.Time \$5=PolarInfo \$6=WgtInfo \$7=ThermallingSinkrate(m/s) \$8=ThermalMultiplier \$9=Turnpt.Lat,Lon.pairs <\$10=tmpfileid> \n";
print " Input: Day=-1/0/1/2/yyyy-mm-dd  Valid.Time=hhmm[+]  ThermalingSink=m/sec  Lat/Lon=degrees(Wlon=-) \n";
print "        ValidTime \"hhmm\" => single datafile time (lst)  \"hhmm+\" => flite start time (lst) \n";
print " Output: std out \n";
print " eg: rasptrackavg.PL GREATBRITAIN d2 0 1500 LS-3 1 1 1 51.,0.,52.,-1.,52.,0.,51.,0. \n";
print "     rasptrackavg.PL PANOCHE d2 2007-03-24 1300 LS-3 1 1 1 36,-121,37,-121,36,-120.5,36,-121 \n";
print "*NB* requires american unit data file input = do not use for metric data files \n";
exit 0; }
############ PROGRAM NOTICE AND LICENSE #################################
#
#            PROGRAM NOTICE AND LICENSE
#
### rasptrackavg.PL COMPUTER PROGRAM - April 12, 2008
### Original Author: Dr. John W. (Jack) Glendening, Meteorologist (drjack@drjack.net)
### Copyright (C) 2007-2008 by John W. Glendening
# 
# This program is free software and is provided by the copyright
# holder under the following license.  By obtaining, using and/or
# copying this work, you (the licensee) agree that you have read,
# understood, and will comply with the following terms and conditions.
# 
# Permission to use, copy, modify, and distribute this program and its
# documentation, with or without modification, for any purpose and
# without fee or royalty is hereby granted, provided that the following
# terms and conditions are complied with:
# 
# 1. The full text of this NOTICE AND LICENSE is provided in a location
# viewable to users of the redistributed or derivative work.
# 
# 2. Pre-existing intellectual property notices and conditions,
# including the above statement of original authorship, the names of
# subsequent modification authors, the original copyright notice, and
# this list of conditions is to be included on all copies of the
# program and documentation or portions thereof, including all
# modifications.
#
# 3. The terms of version 2 of the GNU General Public License are
# complied with.  The GNU General Public License can be viewed
# at on-line http://www.drjack.net/INFO/gnu_gpl_license_2.txt 
# or obtained from the Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# This program is distributed in the hope that it will be useful.
# The program and documentation is provided "as is," and copyright
# holders make no representations or warranties, express or implied,
# including but not limited to, warranties of merchantability or fitness
# for any particular purpose or that the use of the program or
# documentation will not infringe any third party patents, copyrights,
# trademarks or other rights.
#
#########################################################################
  ### for cgi use taint checking option -T
  ### FOR VISUAL DEBUGGER:  perl -d:ptkdb example.pl
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
  #old  use FileHandle; STDOUT->autoflush(1);  # or autoflush HANDLE EXPR (needs "use FileHandle;")
  ### to append new line to each print record:     $\="\n"; #($OUTPUT_RECORD_SEPARATOR)
  ### for error statements with subroutine traceback
use Carp ();
local $SIG{__WARN__} = \&Carp::cluck;
  ### To enable verbose diagnostics:
  #   use diagnostics;
###############################################################################

###############################################################################
############################  PROGRAMMING NOTES  ##############################
###############################################################################
### MODIFIED FOR RASP FROM bliptrackavg.PL
### *NB* datafile units must be "american" - might later allow for metric !
### if alter input argument format may need to change detainting in cgi program
### April 2008 - corrected wind adjustment
###############################################################################

### need asin function
use Math::Trig ;

### ***NB*** ASSUMES ARCHIVED DATAFILE PROJECTION INFO SAME AS IN CURRENT $BASEDIR/WRF/wrfsi/domains/${REGION}/static/wrfsi.nl 
###          (projection info included in files on/after 10 Feb 2007 - might use it instead at some later time)

### ALLOW USE OF LARGEST W VALUE IN SURROUNDING AREA
### $LWSURROUND cells surrounding flight grid cell for which largest w will be used (instead of w at flight grid cell)
### start $LWSURROUND=1 28mar2007
  $LWSURROUND = 1 ;

### CONVERSIONS
  $mps2fpm =  196.850 ;
  $mps2kt =  1.943849 ;
  $kmphr2mps = 0.277778 ;
  #unused $kmphr2kt = 0.539956  ;

#4test: for( $iarg=0; $iarg<=$#ARGV; $iarg++ )
#4test: { print "$iarg ARGV = $ARGV[$iarg] \n"; }

###### PARSE ARGUMENTS
  #unused ### TEST FOR FLAG
  #unused if ( $ARGV[0] eq '-H' )
  #unused   { $FLAG_ARG = $ARGV[0]; shift; }
  #unused else
  #unused   { $FLAG_ARG = ''; }
  #unused ### generate html output header if requested soonest so can display "die" output
  #unused if ( $FLAG_ARG eq '-H' )
  #unused { 
  #unused   use CGI::Carp;
  #unused   print "Content-Type: text/html\n\n";
  #unused }
  ### ensure that certain args are capitals
  ### RASP MOD
  ( $REGION =  $ARGV[0] ) =~ tr/a-z/A-Z/ ;
  ### ensure that certain args are lower case
  ### RASP MOD
  ( $GRID = $ARGV[1] ) =~ tr/A-Z/a-z/ ;
  ( $VALIDDAY =  $ARGV[2] ) =~ tr/A-Z/a-z/ ;
  ( $VALIDTIME =  $ARGV[3] ) =~ tr/A-Z/a-z/ ;
  ### fixup to allow input time with/without trailing lst
  if ( $VALIDTIME =~ m|lst$| ) 
    { $VALIDTIME =~ s|lst||g ; } 
  ### SET $LVALIDTIME: 0=starttime 1=constant
  if( $VALIDTIME =~ m|\+$| || $VALIDTIME =~ m|\-$| )
  {
    $LVALIDTIME = 0 ;
    chop( $VALIDTIME );
  }
  else
  { $LVALIDTIME = 1 ; }
  #4test=starttime: $LVALIDTIME = 0 ;
  #4test=1datafile: $LVALIDTIME = 1 ;

  ### RASP MOD - set KGRID
  if   ( $GRID eq 'd1' ) { $KGRID=1; } 
  elsif( $GRID eq 'd2' ) { $KGRID=2; } 
  elsif( $GRID eq 'w1' ) { $KGRID=2; } 
  elsif( $GRID eq 'w2' ) { $KGRID=3; } 
  $polarinfoarg = $ARGV[4];
  $wgtinfoarg = $ARGV[5];
  ### default ThermallingSinkrate input units = m/s - allow kt/kts append to change units
  if ( $ARGV[6] =~ m|^([0-9.])*kt[s]*$|i )
  { $thermallingsinkrate = ${1}/${mps2kt}  ; }
  else
  { $thermallingsinkrate = $ARGV[6]; }
  $thermalmultiplier = $ARGV[7];
  ### SET  TRACK TURNPOINTS IN LAT,LON (FORTRAN INDEXING)
  $latlonarg = $ARGV[8];
  $tmpfileid = $ARGV[9];
  $nturnpts = 0 ;
  $latlonargtail = $latlonarg ;

  while ( defined $latlonargtail && $latlonargtail ne "" )
  {
    ( $alatpts[$nturnpts],$alonpts[$nturnpts], $latlonargtail ) = split /,/, $latlonargtail, 3 ;
    $nturnpts = $nturnpts + 1 ;
  }
  $nleg = $nturnpts - 1 ;
  #4test: print "NLEG= $nleg \n";
  #4test: for( $ileg=0; $ileg<=$nleg; $ileg++ )
  #4test: { print "$ileg = $alatpts[$ileg] & $alonpts[$ileg] = \n"; }
  ### check for lat,lon pairs

  if ( ! defined $alonpts[$nleg] || $alonpts[$nleg] eq "" ) { die "*** ERROR EXIT - number of latitude and longitude points does not match" }

###### FOR TESTS, HARD-WIRE TEST VARIABLES
#4test: $MODEL = 'RUC';
#nam $MODEL = 'NAM';
#4test: $REGION = 'OKTX';
#4test: $VALIDDAY ='0;
#4test: $VALIDTIME ='18';
### DG-400 POLAR FOR 17m & 7.4lb/ft^2: QuadFit FOR POSITIVE SINK RATE :  1.365734,-2.07661e-2,1.34190e-4  ERRsd=0.0183 (V=km/hr,W=m/s) from ARCHIVE/GLENDENI/SOAR/FLITE/polar_dg400-17light.txt
### dg-400 polar: NEGATIVE W(m/s)= -1.365734 +2.07661e-2*V -1.34190e-4*V**2 where V=km/hr
#4test: $apolar = -1.3419e-4 ; $bpolar = 2.077e-2 ; $cpolar = -1.37 ; $thermallingsinkrate =  1.02 ; # sink=m/s(200fpm)
#use_kts: ### TO USE KT EVERYWHERE
#use_kts: ### NEGATIVE W(kt)= -2.652940 +7.474663E-02*K -8.950191E-04*K**2 where K=kt
#use_kts+ $apolar = -8.950191E-04 ; $bpolar = +7.474663E-02 ; $cpolar = -2.652940 ; $thermallingsinkrate =  1.975 ; # KTS
#4test  $alatpts[0] = 30.0 ; $alonpts[0] = -100.0 ;
#4test  $alatpts[1] = 34.0 ; $alonpts[1] = -98.0 ;
#4test  $alatpts[2] = 34.0 ; $alonpts[2] = -102.0 ;
#4test  $alatpts[3] = 30.0 ; $alonpts[3] = -100.0 ;
#4test  #return2start:  $alatpts[2] = 30.0 ; $alonpts[2] = -100.0 ;
#4test  $nleg = $#alatpts ;

   my $program = 'raspstarttime' ; 

   ### SET NAME OF OUTPUT DATA FILE (blank=none)
   $OUTDATAFILE = '' ;
   if( defined $tmpfileid && $tmpfileid ne "" )
     { $OUTDATAFILE = "/tmp/${program}.out.${tmpfileid}" ; }
   else
     { $OUTDATAFILE = "$program.out" ; }

###### SET MACHINE-DEPENDENT PARAMS
    ### directory containing current forecasts
    $DATADIR = "/var/www/html/${REGION}/FCST"; #OK, but no archives
    ### directory header for archived data (with trailing slash - used by read_archived_plotfile)
    $SAVEDIR =  "/var/www/html/ARCHIVE" ;
################################################################################

   ### INITIALIZATION
   %monthname = ( '1','Jan','2','Feb','3','Mar','4','Apr','5','May','6','Jun','7','Jul','8','Aug','9','Sep','10','Oct','11','Nov','12','Dec',  '01','Jan','02','Feb','03','Mar','04','Apr','05','May','06','Jun','07','Jul','08','Aug','09','Sep' );
   ### avoid warning message
   $titleline1 = '';
   if( $OUTDATAFILE ne '' )
   { open (OUTDATAFILE,">$OUTDATAFILE") }
   else
   { die "***ERROR EXIT - output file -- $OUTDATAFILE -- could not be opened" }
   ### initialization params
   $PI = 4.*atan2(1,1) ;
   $TWOPI = 2.*$PI ;
   $HALFPI = 0.5*$PI ;

   $DEG2RAD = $PI / 180. ;
   $warningfooter = '';

    ### GET POLAR,WGT DATA FROM SUBROUTINE
    &set_glider_data();
 
   ### SET REGION DEPENDENT PARAMS
   ### RASP MOD - *NB* domain param arrays are _0_ index based
   &read_region_params( "/var/www/html/${REGION}/wrfsi.nl" );

   ### RASP MOD - set local variables ala blip (could cleanup later)
   ### params derived from regional grid params
   # note param arrays use _perl_ indexing
   if ( $MOAD_DELTA_X != $MOAD_DELTA_Y ) { die "*** $program ERROR EXIT - DX != DY"; } 
   $RATIO_TO_MOAD = 1 ;
   for ( $igrid=2 ; $igrid<=$KGRID; $igrid++ )
   {
     $RATIO_TO_MOAD = $RATIO_TO_MOAD * $RATIO_TO_PARENT[$KGRID] ;
   }
   $DX = $MOAD_DELTA_X / $RATIO_TO_MOAD ;

   ### must allow for change from domain grid to mass point grid
   $GRID_IMIN = 1 ;
   $GRID_IMAX = ($DOMAIN_ORIGIN_URI[$KGRID]-$DOMAIN_ORIGIN_LLI[$KGRID])*$RATIO_TO_PARENT[$KGRID] ;

   $GRID_JMIN = 1 ;
   $GRID_JMAX = ($DOMAIN_ORIGIN_URJ[$KGRID]-$DOMAIN_ORIGIN_LLJ[$KGRID])*$RATIO_TO_PARENT[$KGRID] ;

   ### params needed for latlon->ij conversion
   $DX_P             = $MOAD_DELTA_X ;
   $LAT_MOAD_CENTER  = $MOAD_KNOWN_LAT ;
   $LON_MOAD_CENTER  = $MOAD_KNOWN_LON ;
   $LON_XX_P         = $MOAD_STAND_LONS ;
   $LAT_TAN_P        = $MOAD_STAND_LAT ;
   $NXmassMOAD       = $DOMAIN_ORIGIN_URI[1] -1 ;
   $NYmassMOAD       = $DOMAIN_ORIGIN_URJ[1] -1 ;

   ### param needed for uv2wd conversion
   $GRID_CONE = cos( $DEG2RAD*( 90. - $LAT_TAN_P ) );

   ### GET SUBGRIDij TO MOADij LINEAR CONVERSION SLOPE,INTERCEPT (speeds lat,lon calc since invariant for grid)
   ($se_subgridi2moadcenteri,$se_subgridj2moadcenterj) = &subgridij2moadcenterij( $KGRID, $GRID_IMIN,$GRID_JMIN );
   ($nw_subgridi2moadcenteri,$nw_subgridj2moadcenterj) = &subgridij2moadcenterij( $KGRID, $GRID_IMAX,$GRID_JMAX );
   $b_subgridi2moadcenteri = $se_subgridi2moadcenteri ;
   $b_subgridj2moadcenterj = $se_subgridj2moadcenterj ;
   $m_subgridi2moadcenteri = ( $nw_subgridi2moadcenteri - $se_subgridi2moadcenteri ) / ($GRID_IMAX - $GRID_IMIN );
   $m_subgridj2moadcenterj = ( $nw_subgridj2moadcenterj - $se_subgridj2moadcenterj ) / ($GRID_JMAX - $GRID_JMIN );

  ### SET VALIDDAY DATA


  ### FOR NON-ARCHIVE DATA, SET FILENAME PARAMS
  if(  $VALIDDAY !~ m|[0-9]-|  )
  { 
    ### FOR NON-ARCHIVE DATA DAY
    ### RASP MOD
    ### set model dependent filename
    if( $VALIDDAY == 0 || $VALIDDAY == -1 )
    { 
      $filesoarday = "curr" ;
      $validdayprt = "CurrentDay" ;
    }
    elsif(  $VALIDDAY == 1  )
    { 
      #PAULS $filesoarday = "curr+1" ;
      $filesoarday = "curr" ;
      $validdayprt = "CurrentDay+1" ;
    }
    elsif(  $VALIDDAY == 2  )
    { 
      #PAULS $filesoarday = "curr+2" ;
      $filesoarday = "curr" ;
      $validdayprt = "CurrentDay+2" ;
    }
    elsif(  $VALIDDAY == 3  )
    { 
      #PAULS $filesoarday = "curr+3" ;
      $filesoarday = "curr" ;
      $validdayprt = "CurrentDay+3" ;
    }
    elsif(  $VALIDDAY == 4  )
    { 
      #PAULS $filesoarday = "curr+4" ;
      $filesoarday = "curr" ;
      $validdayprt = "CurrentDay+4" ;
    }
    elsif(  $VALIDDAY == 5  )
    { 
      #PAULS $filesoarday = "curr+5" ;
      $filesoarday = "curr" ;
      $validdayprt = "CurrentDay+5" ;
    }
    elsif(  $VALIDDAY == 6  )
    { 
      #PAULS $filesoarday = "curr+6" ;
      $filesoarday = "curr" ;
      $validdayprt = "CurrentDay+6" ;
    }
    else
      { die "*** ERROR EXIT - bad $REGION valid day = $VALIDDAY "; }
    ### treat previous day case
    if ( $VALIDDAY == -1 ) 
    { 
      $previousdayhead = "previous." ;
      $validdayprt = "PreviousDay" ;
    }
    else {
      $previousdayhead = "" ;
    }
    ### FOR SINGLE-TIME CASE, READ NON-ARCHIVE DATA
    if( $LVALIDTIME == 1 ) {
      ### TEST FOR AVAILABLE DATA
      $filetest = `grep '^ *---' "${DATADIR}/${previousdayhead}wstar.$filesoarday.${VALIDTIME}lst.${GRID}.data" 2>&1`;
      if ( $filetest !~ m|---|  ) {
        die " DATA NOT AVAILABLE FOR:  $REGION  $validdayprt  ${VALIDTIME}lst in ${DATADIR}" ;
      }
      ### TRY TO REPLACE GENERIC DATE WITH DATE EXTRACTED FROM DATA FILE
      $dateline = `grep 'Day=' "${DATADIR}/${previousdayhead}wstar.$filesoarday.${VALIDTIME}lst.${GRID}.data" 2>&1`;
      if ( $dateline =~ m|Day= ([^= ]+)  *([^= ]+)  *([^= ]+)  *([^= ]+) | ) {
         $validdayprt = "$4 $3 $monthname{$2} $1" ;
      }
      ### READ W* DATA
      $inputdatafile = "${DATADIR}/${previousdayhead}wstar.$filesoarday.${VALIDTIME}lst.${GRID}.data";
      @wstardata = &zmapxyplotread($inputdatafile);
      ### READ WIND DATA
      $inputdatafile = "${DATADIR}/${previousdayhead}blwindspd.$filesoarday.${VALIDTIME}lst.${GRID}.data";
      @blwindspddata = &zmapxyplotread($inputdatafile);
      $inputdatafile = "${DATADIR}/${previousdayhead}blwinddir.$filesoarday.${VALIDTIME}lst.${GRID}.data";
      @blwinddirdata = &zmapxyplotread($inputdatafile);
    }
    ### FOR MULTI-TIME CASE, READ NON-ARCHIVE DATA
    else {
      ### READ DATAFILE NAMES
      #PAULS Remove '"' around ${DATADIR} ... .data in 3 lines below
      @{$lslist{'wstar'}}     = sort `ls ${DATADIR}/${previousdayhead}wstar.$filesoarday.*lst.${GRID}.data` ;
      @{$lslist{'blwindspd'}} = sort `ls ${DATADIR}/${previousdayhead}blwindspd.$filesoarday.*lst.${GRID}.data`;
      @{$lslist{'blwinddir'}} = sort `ls ${DATADIR}/${previousdayhead}blwinddir.$filesoarday.*lst.${GRID}.data`;
      if( $#{$lslist{'wstar'}} == -1 ||  $#{$lslist{'blwindspd'}} == -1 || $#{$lslist{'blwinddir'}} == -1 ) {
        die " DATA NOT AVAILABLE FOR:  $REGION  $validdayprt " ;
      }

      ### SET TIME LIST
      # Need to ensure ALL files relate to correct date: DST change can leave old files around
      # Assume that 1200lst contains correct date: all others must have this date
      $dateline = `grep 'Day=' "${DATADIR}/${previousdayhead}wstar.$filesoarday.1200lst.${GRID}.data" 2>&1`;
      if ( $dateline =~ m|Day= ([^= ]+)  *([^= ]+)  *([^= ]+)  *([^= ]+) | ) {
        $validdayprt = "$4 $3 $monthname{$2} $1" ;
        $gooddate = "Day= $1 $2 $3";
      }

      foreach $param ( 'wstar', 'blwindspd', 'blwinddir' ) { 
        for( $ii=0; $ii<=$#{$lslist{$param}}; $ii++ ) {
          chomp( $lslist{$param}[$ii] );
          $founddate = `grep -c '$gooddate' $lslist{$param}[$ii] 2>&1`;
          chomp( $founddate );
          if( $lslist{$param}[$ii] =~ m|^.*\.([0-9][0-9][0-9][0-9])lst| ) {
            if( $founddate > 0 ){
              $filetimelist{$param}[$ii] = $1 ;
              # print "*WARNING: using ${param} $filetimelist{$param}[$ii] \n";
            }
            # else{ print "*WARNING: NOT using ${param} for $1 \n"; }
          }
        }
      }
      ### READ ONE DATA FILE TO SET NNX,NNY
      @wstardata = &zmapxyplotread( ${lslist{'wstar'}[0]} );
    }
  }
  else
  {
  ### FOR ARCHIVE DATA DAY
    $filesoarday = "curr" ;
    if(  $VALIDDAY =~ m|^20([0-9][0-9])-([0-1][0-9])-([0-3][0-9])$|  ) { 
      ### to get data from archive
      $yyyy = '20' . $1 ;        
      $mm = $2 ;        
      $dd = $3 ;        
      $validdayprt = "${yyyy} ${monthname{$mm}} ${dd}" ;
      ### TEST FOR AVAILABLE DATA
      $archivedirname = "${SAVEDIR}/${REGION}/${yyyy}/${yyyy}${mm}${dd}";
      if ( ! -d $archivedirname ) {
        die " ARCHIVE DATA NOT AVAILABLE FOR: $REGION $validdayprt => $archivedirname" ;
      }
      ### FOR SINGLE-TIME CASE, READ ARCHIVE DATA
      if( $LVALIDTIME == 1 )
      {
        ### READ W* DATA
        ### *NB* requires american unit data file input
        @wstardata = &read_archived_plotfile( $archivedirname,$GRID,$VALIDTIME,"wstar" );
        if( $titleline3 !~ m| Unit= ft/min | && $titleline3 !~m| Unit= \[ft/min\] | ) {
          die 'ERROR STOP - requires american units but here wstar not ft/min' ;
        }
        ### READ WIND DATA FOR ARCHIVE DATA
        ### *NB* requires american unit data file input
        @blwindspddata = &read_archived_plotfile( $archivedirname,$GRID,$VALIDTIME,"blwindspd" );
        if( $titleline3 !~ m| Unit= kt | && $titleline3 !~m| Unit= \[kt\] | ) {
          die 'ERROR STOP - requires american units but here blwindspd not kt' ;
        }
        @blwinddirdata = &read_archived_plotfile( $archivedirname,$GRID,$VALIDTIME,"blwinddir" );
      }
      ### FOR MULTI-TIME CASE, READ ARCHIVE DATA
      else
      {
        ### READ DATAFILE NAMES
        @{$lslist{'wstar'}} = sort `ls ${archivedirname}/wstar.${filesoarday}.*lst.${GRID}.data*`;
        @{$lslist{'blwindspd'}} = sort `ls ${archivedirname}/blwindspd.${filesoarday}.*lst.${GRID}.data*`;
        @{$lslist{'blwinddir'}} = sort `ls ${archivedirname}/blwinddir.${filesoarday}.*lst.${GRID}.data*`;
        if( $#{$lslist{'wstar'}} == -1 ||  $#{$lslist{'blwindspd'}} == -1 || $#{$lslist{'blwinddir'}} == -1 )
        { die " ARCHIVE DATA NOT AVAILABLE FOR: $REGION $validdayprt => $archivedirname" ; }
        ### SET TIME LIST
        foreach $param ( 'wstar', 'blwindspd', 'blwinddir' ) { 
          for( $ii=0; $ii<=$#{$lslist{$param}}; $ii++ ) {
            chomp( $lslist{$param}[$ii] );
            if( $lslist{$param}[$ii] =~ m|^.*\.([0-9][0-9][0-9][0-9])lst| ) {
              $filetimelist{$param}[$ii] = $1 ;
            }
            #PAULS - Test to show files used
            # print "*WARNING: using ${param} $filetimelist{$param}[$ii] \n";
          }
        }
        ### READ ONE DATA FILE TO SET NNX,NNY
        @wstardata = &read_archived_plotfile( $archivedirname,$GRID,${filetimelist{'wstar'}[0]},"wstar" );
      }
    }
    else {
      die "*** ERROR EXIT - bad archive date = $VALIDDAY ";
    }
  }

################################################
#### PAULS Loop over all available start times #
################################################
	$DoneHeader = 0;	# Print Header only once
	for ( $idx = 0; $idx<=$#{$filetimelist{'wstar'}}; $idx++ ){
 		# Print the available times
		# print " ${filetimelist{'wstar'}[$idx]} " ;


	$VALIDTIME = $filetimelist{'wstar'}[$idx] ;


  ### SET 2D ARRAY DIMENSIONS FROM DATAFILE READ
  $NNX =  $GRID_IMAX -$GRID_IMIN +1 ;
  $NNY =  $GRID_JMAX -$GRID_JMIN +1 ;
  ### SANITY CHECK OF DATA FILE EXTENT
  if( $imap1in != $GRID_IMIN ) { die "*** ERROR EXIT - data file imap1 does not match expected value : $imap1in != $GRID_IMIN "; }
  if( $imap2in != $GRID_IMAX ) { die "*** ERROR EXIT - data file imap2 does not match expected value : $imap2in != $GRID_IMAX "; }
  if( $jmap1in != $GRID_JMIN ) { die "*** ERROR EXIT - data file jmap1 does not match expected value : $jmap1in != $GRID_JMIN "; }
  if( $jmap2in != $GRID_JMAX ) { die "*** ERROR EXIT - data file jmap2 does not match expected value : $jmap2in != $GRID_JMAX "; }

  ### FOR MULTI-TIME CASE, SET UP INITIAL PRE,POST_TIME DATA ARRAYS
  if( $LVALIDTIME == 0 )
  {
    ### INITIALIZE
    $clocksec = 3600.* substr( $VALIDTIME, 0,2 ) + 60.* substr( $VALIDTIME, 2,2 ) ;
    ### FIND INDEX OF TIME IMMEDIATELY _AFTER_ INPUT $VALIDTIME
    foreach $param ( 'wstar', 'blwindspd', 'blwinddir' ) { 
      for( $ii=0; $ii<=$#{$filetimelist{$param}}; $ii++ ) {
        if( $filetimelist{$param}[$ii] > $VALIDTIME ) {
          $posttimeindex{$param} = $ii ; last;
        }
      }
      ### IF NONE, write warning & set $posttimeindex to last time and set pre,post arrays to that time  
      if( ! defined $posttimeindex{$param} ) {
        $posttimeindex{$param} = $#{$lslist{$param}} ; 
        ### get new data
        if(  $VALIDDAY !~ m|[0-9]-|  ) { 
          ### FOR NON-ARCHIVE DATA
          $inputdatafile = "${DATADIR}/${previousdayhead}${param}.$filesoarday.${filetimelist{$param}[$posttimeindex{$param}]}lst.${GRID}.data";
          @{$posttimedata{$param}} = &zmapxyplotread($inputdatafile);
        }
        else {
          ### FOR ARCHIVE DATA
          @{$posttimedata{$param}} = &read_archived_plotfile( $archivedirname,$GRID,$filetimelist{$param}[$posttimeindex{$param}],$param );
          ### *NB* requires american unit data file input
          if( $param eq 'wstar' && $titleline3 !~ m| Unit= ft/min | && $titleline3 !~m| Unit= \[ft/min\] | ) { die 'ERROR STOP - requires american units but here wstar not ft/min' ; }
          if( $param eq 'blwindspd' && $titleline3 !~ m| Unit= kt | && $titleline3 !~ m| Unit= \[kt\] | ) { die 'ERROR STOP - requires american units but here blwindspd not kt' ; }
        }
        ### set posttimesec large so will never again try to update data 
        $posthhmm{$param} = 9999 ;
        $prehhmm{$param}  = $posthhmm{$param} ;
        push @paramwarning0, $param ;
      }
      ### IF FIRST, write warning
      elsif( $posttimeindex{$param} == 0 ) {
        if(  $VALIDDAY !~ m|[0-9]-|  ) { 
          ### FOR NON-ARCHIVE DATA
          @{$posttimedata{$param}} = &zmapxyplotread( "${DATADIR}/${previousdayhead}${param}.$filesoarday.${filetimelist{$param}[0]}lst.${GRID}.data" );
        }
        else {
          ### FOR ARCHIVE DATA
          @{$posttimedata{$param}} = &read_archived_plotfile( $archivedirname,$GRID,$filetimelist{$param}[0],$param );
          ### *NB* requires american unit data file input
          if( $param eq 'wstar' && $titleline3 !~ m| Unit= ft/min | && $titleline3 !~m| Unit= \[ft/min\] | ) { die 'ERROR STOP - requires american units but here wstar not ft/min' ; }
          if( $param eq 'blwindspd' && $titleline3 !~ m| Unit= kt | && $titleline3 !~ m| Unit= \[kt\] | ) { die 'ERROR STOP - requires american units but here blwindspd not kt' ; }
        }
        $posthhmm{$param} = $filetimelist{$param}[$posttimeindex{$param}] ;
        $prehhmm{$param}  = $posthhmm{$param} ;
        push @paramwarning1, $param ;
      }
      ### ELSE set pre/post arrays to time before/after $VALIDTIME
      else {
        if(  $VALIDDAY !~ m|[0-9]-|  ) { 
          ### FOR NON-ARCHIVE DATA
          @{$posttimedata{$param}} = &zmapxyplotread( "${DATADIR}/${previousdayhead}${param}.$filesoarday.${filetimelist{$param}[$posttimeindex{$param}]}lst.${GRID}.data" );
          @{$pretimedata{$param}} = &zmapxyplotread( "${DATADIR}/${previousdayhead}${param}.$filesoarday.${filetimelist{$param}[$posttimeindex{$param}-1]}lst.${GRID}.data" );
        }
        else {
          ### FOR ARCHIVE DATA
          @{$posttimedata{$param}} = &read_archived_plotfile( $archivedirname,$GRID,$filetimelist{$param}[$posttimeindex{$param}],$param );
          @{$pretimedata{$param}} = &read_archived_plotfile( $archivedirname,$GRID,$filetimelist{$param}[$posttimeindex{$param}-1],$param );
          ### *NB* requires american unit data file input
          if( $param eq 'wstar' && $titleline3 !~ m| Unit= ft/min | && $titleline3 !~m| Unit= \[ft/min\] | ) { die 'ERROR STOP - requires american units but here wstar not ft/min' ; }
          if( $param eq 'blwindspd' && $titleline3 !~ m| Unit= kt | && $titleline3 !~ m| Unit= \[kt\] | ) { die 'ERROR STOP - requires american units but here blwindspd not kt' ; }
        }
        $posthhmm{$param} = $filetimelist{$param}[$posttimeindex{$param}] ;
        $prehhmm{$param}  = $filetimelist{$param}[$posttimeindex{$param}-1] ;
      }
      ### set pre,post_time clock time
      $pretimesec{$param} = 3600.* substr( $prehhmm{$param}, 0,2 ) + 60.* substr( $prehhmm{$param}, 2,2 ) ;
      $posttimesec{$param} = 3600.* substr( $posthhmm{$param}, 0,2 ) + 60.* substr( $posthhmm{$param}, 2,2 ) ;
    }
    ### note: arrays @paramwarning0,1 give parameters missing, but currently not printed
    if( $#paramwarning0 > -1 )
    {  $warningfooter .= sprintf " data unavailable after %s so assumed constant then\n", $VALIDTIME ;}
    #old print "*WARNING: @paramwarning0 data not available aftere $VALIDTIME so using only time $filetimelist{$paramwarning0[0]}[$posttimeindex{$paramwarning0[0]}] \n";
    if( defined $paramwarning1[0] ) { 
      $warningfooter .= sprintf " data unavailable before %s so assumed constant then\n", $filetimelist{$paramwarning1[0]}[$posttimeindex{$paramwarning1[0]}] ; 
    }
  }

  ### PARSE POLAR INFO - can be a,b,c or name
  ### if name, get its polar data
  if ( defined $polar_data{$polarinfoarg} ) {
    $polarinfo = $polar_data{$polarinfoarg} ; }
  else {
    $polarinfo = $polarinfoarg ;
  }
  ### extract polar a,b,c from polardata string
  if( $polarinfo =~ m|[0-9\+\-\.Ee]+,[0-9\+\-\.Ee]+,[0-9\+\-\.]+| )
    { ( $apolar,$bpolar,$cpolar ) = split( /,/, $polarinfo ) ; }
  else
    { die 'ERROR EXIT - Glider Polar Info Not Available' ; }

  ### convert input lat,lon to gridpts
  ### can use same gridpt->i,j routine for nam awip218 and ruc since both lambert conformal
  ### RASP MOD
    ### convert turnpt lat,lon into gridpt locations (can be non-integer - fortran indexing) 
    for ( $iturnpt=0; $iturnpt<=$nleg; $iturnpt++ )
    {
      $alat = $alatpts[$iturnpt] ;
      ### check that this is a West longitude
      $alon = $alonpts[$iturnpt] ;
      ### convert negative W longitude
      if( $alon < 0 ) { $alon = $alon + 360.; }
      ### CALC MOAD I,J (non-integer) RELATIVE TO CENTER OF MOAD GRID
      ### *NB* W3FB11 USES LAT/LON ASSOCIATED WITH (1,1) *NOT* (0,0) SO HAVE TO SHIFT ACCORDINGLY !
      ( $airelative, $ajrelative ) = &W3FB11( $alat,$alon, $LAT_MOAD_CENTER,$LON_MOAD_CENTER,$DX_P,$LON_XX_P,$LAT_TAN_P );
      #4test:  printf "CENTER aI,aJ=%8.2f%8.2f \n", $airelative,$ajrelative ;
      ### CALC MOAD LAMBERT I,J (non-integer) SHIFTED TO MOAD *MASS* GRID
      $aimoad = $airelative + 0.5*( $NXmassMOAD -1 ) ;
      $ajmoad = $ajrelative + 0.5*( $NYmassMOAD -1 ) ;
      #alt $aimoad = ( $airelative -1.0) + 0.5*( $NXmassMOAD +1 ) ;
      #alt $ajmoad = ( $ajrelative -1.0) + 0.5*( $NYmassMOAD +1 ) ;
      ### COMPUTE MOAD I,J FOR SELECTED GRID
      $ai = $aimoad ;
      $aj = $ajmoad ;
      ### CONVERT MOAD *MASS* INDEX TO NON-MOAD SUBGRID *MASS* INDEX
      ### note param arrays use _perl_ indexing
      for ( $igrid=2 ; $igrid<=$KGRID; $igrid++ )
      {
        if( ! defined $RATIO_TO_PARENT[${igrid}] || ! defined  $DOMAIN_ORIGIN_LLI[${igrid}] || ! defined  $DOMAIN_ORIGIN_LLJ[${igrid}] )
        {
          die "ERROR EXIT: BAD GRID NUMBER = $KGRID ";
        }
        $ai = 0.5 + $RATIO_TO_PARENT[${igrid}] * ( $ai - ( $DOMAIN_ORIGIN_LLI[${igrid}] -0.5 ) ) ;
        $aj = 0.5 + $RATIO_TO_PARENT[${igrid}] * ( $aj - ( $DOMAIN_ORIGIN_LLJ[${igrid}] -0.5 ) ) ;
      }
      $xturnpts[$iturnpt] = $ai ;
      $yturnpts[$iturnpt] = $aj ;
      #4test:  print "TURNPT $iturnpt LAT,LON $alat $alon => GRIDPT $gridi $gridj => ARRAY PT $xturnpts[$iturnpt] $yturnpts[$iturnpt] \n"; 
    }
  #old { die "*** $program ERROR - unknown REGION= $REGION "; }
  ### set  track turnpoints in grid pt locations (fortran indexing) - need not be integer
  #4test $xturnpts[0] = 4.0 ; $yturnpts[0] = 4.0 ;
  #4test $xturnpts[1] = 10.0 ; $yturnpts[1] = 10.0 ;
  #4test $xturnpts[2] = 4.0 ; $yturnpts[2] = 4.0 ;

### INITIALIZATION
  #unused  $deg2rad = 0.01745329252 ;  ### convert degrees into radians
  #unused $TMPID = "$MODEL.$REGION.$VALIDDAY.${VALIDTIME}lst.$apolar.$bpolar.$cpolar.$thermallingsinkrate";
  #4test: $TMPID = "$MODEL.$REGION.$VALIDDAY.${VALIDTIME}lst";
  my( $dummy );


### COMPUTE WEIGHT RATIO ADJUSTMENT SO CAN TEST FOR MISSING DATA PRIOR TO PRINT
    ### ADJUST FOR WEIGHT
    ### for -1 use internal ballast info, else sqrt
    if( $wgtinfoarg <= 0 )
    {
      if ( defined $weight_data{$polarinfoarg} && defined $ballast_data{$polarinfoarg} )
        ### 1 liter of water weighs 1 kg
        { $polarfactor = sqrt ( 1. + ( $ballast_data{$polarinfoarg} / $weight_data{$polarinfoarg} ) ) ;  }
      else
       { die 'ERROR STOP - Glider Weight Unavailable' ; }
    }
    else
      { $polarfactor = sqrt ( $wgtinfoarg ) ; }

### PRINT HEADER
    ### ADD EXTRA COLUMN FOR MULTI-TIME TIME
    if( $LVALIDTIME == 0 )
    { 
      $clockprt = '          ' ;
      $clockpr2 = '    ' ;
      $clockstr = ' ClockTime' ;
      $clockdash = '---------' ;
     }
    else
    { $clockprt = $clockpr2 = $clockstr = $clockdash = '' ; }
if( $DoneHeader == 0) {
    print "${clockpr2}            FLIGHT TRACK AVERAGES             \n" ;
    #old print "         SPATIAL and \"OPTIMAL FLIGHT\"         \n" ;
    #old print "          for OPTIMAL TIME & SPEED            \n" ;
    print " ${clockdash}-------------------------------------------- \n" ;
    print "${clockpr2} (\"optimal\" uses wind-adjusted speed-to-fly)\n" ;
    if( $LVALIDTIME == 0 )
    { print "${clockpr2} Valid: $validdayprt  StartTime: ${VALIDTIME}lst\n" ;  }
    else
    { print "${clockpr2} Valid: $validdayprt  ${VALIDTIME}lst\n" ; }
    print "${clockpr2} Grid:  $REGION $GRID = ${DX}m\n" ;
    #old print " Valid:  $REGION $GRID  $validdayprt ${VALIDTIME}lst\n" ;
    ### CALC NO-WIND L/D FOR PRINTOUT
    $vloverd = sqrt($cpolar/$apolar) ;  # in km/hr
    $wloverd = $apolar*$vloverd*$vloverd + $bpolar*$vloverd + $cpolar ; # negative, in m/s
    $LoverD = ( -0.2777777777 * $vloverd )/$wloverd ; # convert v to m/s and allow for negative w
    printf "%s PolarInfo: %s (L/D=%.0f)\n", $clockpr2,$polarinfoarg,$LoverD ; 
    #old print "${clockpr2} PolarInfo: $polarinfoarg\n" ; 
    if ($wgtinfoarg == -1 ) 
      {  printf "${clockpr2} Ballast: %.0f kg   DryWeight: %.0f kg\n", $ballast_data{$polarinfoarg}, $weight_data{$polarinfoarg} ; }
    else
      {  printf "${clockpr2} WeightRatio: %s   DryWeight: %.0f kg\n",  $wgtinfoarg, $weight_data{$polarinfoarg} ; }
    printf "${clockpr2} ThermallingSinkrate: %s m/s\n", $thermallingsinkrate ;
    if ($thermalmultiplier != 1 ) 
      {  printf "${clockpr2} ThermalStrengthMuliplier: %.1f \n", $thermalmultiplier ; }
    ### split lat,lon into pairs for printing
    $latlonargtail = $latlonarg ;
    ( $alat,$alon, $latlonargtail ) = split /,/, $latlonargtail, 3 ;
         printf "${clockpr2} Lat,Lons:  %7.3f %8.3f\n", $alat,$alon ;
    #old printf "     Lat,Lons:  %.2f %.2f  (%s)\n", $alat,$alon, $REGION ;
    #old printf "     Lat,Lons:  %.2f %.2f\n", $alat,$alon ;
    #unused ( $alat,$alon, $latlonargtail ) = split /,/, $latlonargtail, 3 ;
    #unused printf "     %4s       %.2f %.2f\n", $REGION,$alat,$alon ;
    while ( defined $latlonargtail && $latlonargtail ne "" )
    {
      ( $alat,$alon, $latlonargtail ) = split /,/, $latlonargtail, 3 ;
      printf "${clockpr2}            %7.3f %8.3f\n", $alat,$alon ;
    }
    ### PRINT COLUMN HEADERS    
    print " ${clockdash}------------------------------------------------ \n" ;
    print "${clockprt}  -Spatial-Avg- ------Optimal-Flight-Avg------- \n" ;
    print "${clockstr}      Tail Clmb Tail Clmb      Gnd  Gnd Air Thm \n" ;
    print "${clockprt} Dist Wind Rate Wind Rate Time Spd  Spd Spd Pct \n" ;
    print "${clockprt}   km   kt  kt    kt   kt  min  kt km/h  kt   % \n" ;
    $DoneHeader = 1;
} # ENDIF ($DoneHeader)

### START OF LOOP OVER ALL TURNPOINTS
  $totallength = 0 ;
  $totalspatialavgclimbratesum = 0 ;
  $totalspatialavgtailwindsum = 0 ;
  $totalsec = 0 ;
  $totalclimbratesum = 0 ;
  $totalthermaltime = 0 ;
  $totaloptairspeedsum = 0 ;
  $totaltailwindsum = 0 ;
  $ltotalsolution = 1;
  ### compute % of no solution "blocked" boxes
  $totalblocked = 0 ;
  $totallegboxs = 0 ;
  $flitedist = 0 ;
  $flitetime = 0 ;
  $clockhhmm = $VALIDTIME ;
  $itotpt = -1;
  LEG: for ( $ileg=1; $ileg<=$#xturnpts; $ileg++ )
  {
    ### set start,end pts for this leg
    $xstart = $xturnpts[$ileg-1] ;
    $ystart = $yturnpts[$ileg-1] ;
    $xend = $xturnpts[$ileg] ;
    $yend = $yturnpts[$ileg] ;
    ### SET  START,END GRID PT LOCATIONS (FORTRAN INDEXING) - need not be integer
    #4test: #45deg: $xstart = 4.0 ; $ystart = 4.0 ; $xend = 10.0 ; $yend = 10.0 ;
    #4test: #225deg: $xstart = 10.0 ;$ystart = 10.0 ;$xend = 4.0 ;$yend = 4.0 ;

    ### DO TURNPOINT VALIDITY TESTS
    if ( $xturnpts[$ileg] < 1 ) { die "*** ERROR EXIT - turnpoint $iturnpt x extent too small : $xturnpts[$ileg] < 1 ";  }
    if ( $xturnpts[$ileg] > $NNX ) { die "*** ERROR EXIT - turnpoint $iturnpt x extent too large : $xturnpts[$ileg] > $NNX "; }
    if ( $yturnpts[$ileg] < 1 ) { die "*** ERROR EXIT - turnpoint $iturnpt y extent too small : $yturnpts[$ileg] < 1 "; }
    if ( $yturnpts[$ileg] > $NNY ) { die "*** ERROR EXIT - turnpoint $iturnpt y extent too large : $yturnpts[$ileg] > $NNY "; }
    if( $ileg == 1 )
    {
    ### DO TURNPOINT VALIDITY TESTS
    if ( $xturnpts[0] < 1 ) { die "*** ERROR EXIT - turnpoint 0 x extent too small : $xturnpts[0] < 1 "; }
    if ( $xturnpts[0] > $NNX ) { die "*** ERROR EXIT - turnpoint 0 x extent too large : $xturnpts[0] > $NNX "; }
    if ( $yturnpts[0] < 1 ) { die "*** ERROR EXIT - turnpoint 0 y extent too small : $yturnpts[0] < 1 "; }
    if ( $yturnpts[0] > $NNY ) { die "*** ERROR EXIT - turnpoint 0 y extent too large : $yturnpts[0] > $NNY "; }
    }

    ### CALC OPTIMAL SPEED

    ### DO POLAR WEIGHT RATIO WEIGHT ADJUSTMENT 
    $anorm = $apolar / $polarfactor ;
    $bnorm = $bpolar ;
    $cnorm = $cpolar * $polarfactor ;

    ### CONVERT POLAR COEFS TO USE VELOCITY IN m/s
    ### *NB* following calcs assume apolar,bpolar,cpolar give NEGATIVE W=m/s for V=km/hr => a,b=negative c=positive ala Reichmann
    ### so must convert to coeffs which will give all velocities in m/s
    $anorm = $anorm / ( $kmphr2mps * $kmphr2mps ) ;
    $bnorm = $bnorm / $kmphr2mps ;
    $cnorm = $cnorm ;
    #use_kts: ### TO USE KTS EVERYWHERE
    #use_kts+  $anorm = $apolar ;
    #use_kts+  $bnorm = $bpolar ;
    #use_kts+  $cnorm = $cpolar ;

  ### DETERMINE CELL BOXES ALONG START->END PATH
    ( $nlegpts, @xsort ) = &cell_path_intersections ( $xstart,$ystart, $xend,$yend );
    ### must split return into 2 arrays
    @ysort = splice @xsort, $nlegpts,$nlegpts ;
    
  ### DETERMINE INTEGER GRID BOX CONTAINING LINE BETWEEN THIS AND NEXT POINT
  ###    AND LENGTH OF PATH BETWEEN THOSE POINTS
  ### *UNITS* WITHIN THIS LOOP CURRENTLY:  w=m/s(convert from datafile)  speed/wind=m/s(convert from datafile) length=m(ala grid)
    $igridptafter[$nlegpts-1] = 0;
    $jgridptafter[$nlegpts-1] = 0;
    $length[$nlegpts-1] = 0;
    $seconds[$nlegpts-1] = 0;
    $optgroundspeed[$nlegpts-1] = 0;
    $lsolution[$ileg] = 0;
    ### compute % of no solution "blocked" boxes
    $nblocked[$ileg] = 0;
    $nlegboxs[$ileg] = $nlegpts-1 ;
    ### START OF LOOP OVER POINTS ALONG LEG
    for ( $i=0; $i<=($nlegpts-2); $i++ )
    {
      ### set overal totals
      $itotpt += 1 ;
      ### determine grid box for line between this and next point
      $igridptafter[$i] = nint( 0.5*( $xsort[$i] + $xsort[$i+1] ) );
      $jgridptafter[$i] = nint( 0.5*( $ysort[$i] + $ysort[$i+1] ) ) ;
      ### determine length between this and next point
      $length[$i] = $DX * sqrt( ($xsort[$i+1]-$xsort[$i])**2 + ($ysort[$i+1]-$ysort[$i])**2 ) ;
      ### determine optimal time from optimal speed
      $kgridptafter = ($jgridptafter[$i]-1)*$NNX + $igridptafter[$i] -1 ;
      ### START OF OPTGROUNDSPEED CALC FOR THIS GRIDPT
      ### following assumes W* in ft/min
      ### following assumes POSITIVE thermallingsinkrate=m/s
      ### following gives thermallingclimbrate in m/s
      ### multiply thermal climb rate by fudge factor
      ### USE W* VALUE
      ### ALLOW USE OF LARGEST W VALUE IN SURROUNDING AREA
      if ( $LWSURROUND <= 0 )
      {
        ### this is code prior to adding $LWSURROUND - kept outside loop so have for reference (& slightly more efficient)
        if( $LVALIDTIME == 1 )
        {
          $thermalstrength[$i] = $wstardata[$kgridptafter] / $mps2fpm ;
        }
        elsif( $prehhmm{'wstar'} == $posthhmm{'wstar'} )
        {
          $thermalstrength[$i] =  $posttimedata{'wstar'}[$kgridptafter] / $mps2fpm ;
        }
        else
        {
          $thermalstrength[$i] = ( $pretimedata{'wstar'}[$kgridptafter] + (( $clocksec - $pretimesec{'wstar'} ) /( $posttimesec{'wstar'} - $pretimesec{'wstar'} )) * ( $posttimedata{'wstar'}[$kgridptafter] - $pretimedata{'wstar'}[$kgridptafter] ) ) / $mps2fpm ;
        }
        $thermallingclimbrate[$i] = ( $thermalmultiplier * $wstardata[$kgridptafter] / $mps2fpm ) - $thermallingsinkrate ;
        #4testptint: print " $i 4SURROUND=0 : $igridptafter[$i] $jgridptafter[$i] => $kgridptafter : $wstardata[$kgridptafter] \n";

      } 
      else
      {
        ### INTERATE OVER BOX MIN,MAX INDICES 
        $kdist = $LWSURROUND ;
        $igrid = $igridptafter[$i] ;
        $jgrid = $jgridptafter[$i] ;
        $iixmin = &max( ( (1),   ($igrid-$kdist) ) );
        $iixmax = &min( ( ($NNX),($igrid+$kdist) ) );
        $iiymin = &max( ( (1),   ($jgrid-$kdist) ) );
        $iiymax = &min( ( ($NNY),($jgrid+$kdist) ) );
        $wstarmax = -99999. ;
        for( $iiy=$iiymin; $iiy<=$iiymax; $iiy++ )
        {
          ### slightly more efficient to only iter by 1 inside x loop
          $kk = ($iiy -1)*$NNX +$iixmin -1 -1 ;
          for( $iix=$iixmin; $iix<=$iixmax; $iix++ )
          {
            $kk++;
            #old $kk =  ($iiy -1)*$NNX +$iix -1  ;
            #4testprint: print " $kdist : $iix $iiy => $kk \n" ;
            if( $LVALIDTIME == 1 )
            {
              $wstardata = $wstardata[$kk] ;
              #original $thermalstrength[$i] = $wstardata[$kgridptafter] / $mps2fpm ;
            }
            elsif( $prehhmm{'wstar'} == $posthhmm{'wstar'} )
            {
              $wstardata =  $posttimedata{'wstar'}[$kk] ;
              #original $thermalstrength[$i] =  $posttimedata{'wstar'}[$kgridptafter] / $mps2fpm ;
            }
            else
            {
              $wstardata = $pretimedata{'wstar'}[$kk] + (( $clocksec - $pretimesec{'wstar'} ) /( $posttimesec{'wstar'} - $pretimesec{'wstar'} )) * ( $posttimedata{'wstar'}[$kk] - $pretimedata{'wstar'}[$kk] ) ;
              #original $thermalstrength[$i] = ( $pretimedata{'wstar'}[$kgridptafter] + (( $clocksec - $pretimesec{'wstar'} ) /( $posttimesec{'wstar'} - $pretimesec{'wstar'} )) * ( $posttimedata{'wstar'}[$kgridptafter] - $pretimedata{'wstar'}[$kgridptafter] ) ) / $mps2fpm ;
            }
            if ( $wstarmax < $wstardata )  {  $wstarmax = $wstardata ; }
            #4testprint:  print " $i = $iix $iiy => $kk : $wstarmax $wstardata \n";
          }
        }
        $thermalstrength[$i]  = $wstarmax / $mps2fpm ;
        $thermallingclimbrate[$i] = ( $thermalmultiplier * $wstarmax / $mps2fpm ) - $thermallingsinkrate ;
        #4testprint: print "DataTime $i  $clocksec  $pretimesec{'wstar'} $posttimesec{'wstar'}  $prehhmm{'wstar'} $posthhmm{'wstar'} \n";
        #original $thermallingclimbrate[$i] = ( $thermalmultiplier * $wstardata[$kgridptafter] / $mps2fpm ) - $thermallingsinkrate ;
      }
      #use_kts: ### TO USE KTS EVERYWHERE
      #use_kts+  $thermallingclimbrate = $mps2kt * ( ( $wstardata[$kgridptafter] / $mps2fpm ) ) - $thermallingsinkrate ;
      ### use eqn VI from Reichmann Appendix * REQUIRE ALL VELOCITIES TO BE M/S BUT THEN CONVERT RESULT TO KT*

      ### ADJUST GLIDE TO ALLOW FOR WIND
      ### must use kpt of entire grid - output wind speed units same as that input
      ### decided to convert grid track to true direction and use cosine of angle difference to get wind components
      #unused ( $ugrid, $vgrid ) = &ruc_wd2uv ( $kptentiregrid, $windkt[$kgridptafter], $winddeg[$kgridptafter] );
      ### only ratio of $utrack,$vtrack is important, not magnitude so dont convert to actual speed
      $dxtrack = $xsort[$i+1]-$xsort[$i] ;
      $dytrack = $ysort[$i+1]-$ysort[$i] ;
      ### allow previously computed gridpoint lat/lon to be used 
      if ( ! defined $alat[$kgridptafter] || ! defined $alon[$kgridptafter] )
      {  
        ### subgridij to moadij linear conversion speeds lat,lon calc to do here, since invariant for grid
        $aimoadcenter = ( $igridptafter[$i] -1 ) * $m_subgridi2moadcenteri + $b_subgridi2moadcenteri ;
        $ajmoadcenter = ( $jgridptafter[$i] -1 ) * $m_subgridj2moadcenterj + $b_subgridj2moadcenterj ;
        #old ($aimoadcenter,$ajmoadcenter) = &subgridij2moadcenterij( $KGRID, $igridptafter[$i],$jgridptafter[$i] );
        ($alat[$kgridptafter],$alon[$kgridptafter]) = &W3FB12( $aimoadcenter,$ajmoadcenter, $LAT_MOAD_CENTER,$LON_MOAD_CENTER,$DX_P,$LON_XX_P,$LAT_TAN_P );
        ### convert to negative W longitude
        if( $alon[$kgridptafter] > 180. ) { $alon[$kgridptafter] = $alon[$kgridptafter] - 360.; }
        #unused ($alat[$kgridptafter],$alon[$kgridptafter]) = &ij2latlon( $KGRID, $igridptafter[$i],$jgridptafter[$i] );
      }
      ### *NB* $revtrackdegtrue defined in "meteorological" sense, i.e. in direction _opposite_ to vector, so can be compared to tailwind
      ($dummy,$revtrackdegtrue) = &uv2wswd_4latlon ( $dxtrack, $dytrack, $alat[$kgridptafter],$alon[$kgridptafter] );
      #4testprint:  print " --- $kgridptafter $dxtrack $dytrack => $alat[$kgridptafter],$alon[$kgridptafter] => $revtrackdegtrue \n";
      #old $kptentiregrid = ( $GRID_JMIN + $jgridptafter[$i] -2 )*$GRID_IMAX + ( $GRID_IMIN + $igridptafter[$i] -2 );
      #old $revtrackdegtrue = &uv2wd ( $kptentiregrid, $dxtrack, $dytrack );
      ### due to using meteorological convention for direction, use positive cosine to get tailwind
      ### USE WIND VALUE
      if( $LVALIDTIME == 1 )
      {
        $blwindspdmps =  $blwindspddata[$kgridptafter] / $mps2kt ;
        $blwinddirtrue = $blwinddirdata[$kgridptafter] ;
      }
      elsif( $prehhmm{'wstar'} == $posthhmm{'wstar'} )
      {
        $blwindspdmps = $posttimedata{'blwindspd'}[$kgridptafter] / $mps2kt ;
        $blwinddirtrue = $posttimedata{'blwinddir'}[$kgridptafter] ;
      }
      else
      { 
        $blwindspdmps = ( $pretimedata{'blwindspd'}[$kgridptafter] + (( $clocksec - $pretimesec{'blwindspd'} ) /( $posttimesec{'blwindspd'} - $pretimesec{'blwindspd'} )) * ( $posttimedata{'blwindspd'}[$kgridptafter] - $pretimedata{'blwindspd'}[$kgridptafter] ) ) ;

				#### PAULS - BUG in Wind Speed if MultiTime - not converted to Metres per Sec??
				$blwindspdmps = $blwindspdmps / $mps2kt;


        $blwinddirtrue = ( $pretimedata{'blwinddir'}[$kgridptafter] + (( $clocksec - $pretimesec{'blwinddir'} ) /( $posttimesec{'blwinddir'} - $pretimesec{'blwinddir'} )) * ( $posttimedata{'blwinddir'}[$kgridptafter] - $pretimedata{'blwinddir'}[$kgridptafter] ) ) ;
      }
      ### *NB* $revtrackdegtrue defined in "meteorological" sense, i.e. in direction _opposite_ to vector, so can be compared to tailwind
      $windanglerad = $DEG2RAD*( $blwinddirtrue - $revtrackdegtrue ) ;
      $tailwindmps[$i] = $blwindspdmps * cos ( $windanglerad );
      #4testprint: print "$ileg $i TRACK,WINDrad= $revtrackdegtrue $blwinddirtrue => $tailwindmps[$i] \n" ;
      #old $crosswindmps[$i] = $blwindspdmps * sin ( $windanglerad );
      #4test: print "TAIL/CROSSWIND(m/s) = $ileg $i $tailwindmps[$i] $crosswindmps[$i] m/s <= $blwindspddata[$kgridptafter] kt @ $blwinddirdata[$kgridptafter] vs $dxtrack $dytrack $revtrackdegtrue \n" ;

      ### CALC OPTIMAL SOLN (optimal between-thermal airspeed does _not_ depend upon wind, but track ground speed does)
      ### use speed to fly eqn based on thermalling climb rate   
      if ( $thermallingclimbrate[$i] > 0 )
      #old-bad (gives negative values of optgroundspeed) if ( $sqrtfact > 0 )
      {
        $sqrtarg =  ( $cnorm - $thermallingclimbrate[$i] ) / $anorm  ;
        $optairspeed_inglide[$i] = sqrt( $sqrtarg ) ;
        #old $optairspeed_inglide[$i] = sqrt( ( $cnorm - $thermallingclimbrate[$i] ) / $anorm ) ;
        $denom =  2.*${thermallingclimbrate[$i]} - 2.*${cnorm} -${bnorm}*${optairspeed_inglide[$i]} ;
        if ( $denom > 0 )
        {
           $optavgairspeed = ( ( ${thermallingclimbrate[$i]} * $optairspeed_inglide[$i] ) / $denom ) ;
           #use_kts: ### TO USE KTS EVERYWHERE
           #use_kts+ $optavgairspeed = ( ( ${thermallingclimbrate[$i]} * $optairspeed_inglide[$i] ) / $denom ) ;
           $thermalpct[$i] =  100. * ( 1. - ( $optavgairspeed / $optairspeed_inglide[$i] ) ) ;
           ### DO WIND TRIANGLE CALC to get track ground speed - for triangle with two known sides (speeds) and known non-enclosed angle
           ### START OF TESTED WIND TRIANGLE CALC 
           ### ensure angle alpha=$wind2track_anglerad has range 0 to PI
           ### *NB* $revtrackdegtrue defined in "meteorological" sense, i.e. in direction _opposite_ to vector, so can be compared to tailwind
           $awind2track_anglerad = abs( $DEG2RAD*( $blwinddirtrue - $revtrackdegtrue ) );
           if( $awind2track_anglerad > $PI ) { $awind2track_anglerad =  $TWOPI - $awind2track_anglerad ; }
           #4test: print "AWIND2TRACK_ANGLERAD= $awind2track_anglerad \n" ; 
           $asinarg = $blwindspdmps * sin( $awind2track_anglerad ) / $optavgairspeed ;
           ### always use smaller angle solution (between track and airspeed bearing) (=gamma1)
           $gammarad = asin( $asinarg ) ;
           ### tests to ensure that my thinking/logic is correct
           if( $asinarg < 0.0 ) { die "ERROR STOP - asingarg = $asinarg < 0 " ; }
           if( $gammarad < 0.0 ) { die "ERROR STOP - gammarad = $gammarad < 0 " ; }
           if( $gammarad > $HALFPI ) { die "ERROR STOP - gammarad = $gammarad > PI/2 " ; }
           if( $asinarg > 1.0 )
           {
             ### BLOCKED - Wind triangle error => BL wind too strong
             $nblocked[$ileg]++ ;
             $lsolution[$ileg] = -4 ;
             $optgroundspeed[$i] = 0.0 ;
             $thermalpct[$i] = 100. ;
             $seconds[$i] = 0.0 ;
             #4test: print "Wind triangle error => BL wind too strong - $ileg $i $asinarg $gammarad $awind2track_anglerad $blwindspdmps $optavgairspeed \n";
             #old=replace_imaginary_value_for_printing $gammarad = -1. ;
           }
           else
           {
             $betarad = $PI - ( $awind2track_anglerad + $gammarad ) ;
             $denom = sin($awind2track_anglerad) ;
             ### round-off error fixups needed
             if( $denom >= 0.0000001 )
             #old=subject_to_roundoff_error if( $denom != 0.0 )
               { $optgroundspeed[$i] = $optavgairspeed * sin($betarad) / $denom ; }
             elsif( abs(sin($betarad)) <= 0.0000001 )
               {
                 if( abs($betarad) <= 0.0000001 )
                   { $optgroundspeed[$i] = $optavgairspeed - $blwindspdmps ; }
                 elsif( (abs($betarad)-$PI) <= 0.0000001 )
                   { $optgroundspeed[$i] = $optavgairspeed + $blwindspdmps ; }
                 else
                   { die "ERROR STOP - failure of fixup for sine=0 : awind2track_anglerad,gammarad,betarad= $awind2track_anglerad,$gammarad,$betarad " ; }
               }
             else
               { die "ERROR STOP - division by sine=0 : awind2track_anglerad,gammarad,betarad= $awind2track_anglerad,$gammarad,$betarad " ; }
             #old $optgroundspeed[$i] = $optavgairspeed * sin($betarad) / sin($awind2track_anglerad) ;
             if( $optgroundspeed[$i] <= 0.0 )
             {
               ### BLOCKED - Backward movement => BL wind too strong
               $nblocked[$ileg]++ ;
               $lsolution[$ileg] = -3 ;
               $optgroundspeed[$i] = 0.0 ;
               $thermalpct[$i] = 100. ;
               $seconds[$i] = 0 ;
               #4test: print "Backward movement => BL wind too strong - $ileg $i $asinarg $gammarad $awind2track_anglerad $blwindspdmps $optavgairspeed \n";
             }
             else
             {
               ### determine time along this segment of track
               $seconds[$i] =  $length[$i] / $optgroundspeed[$i] ;
               #4test: print "OptTrackspeed - $ileg $i $thermallingclimbrate[$i] $revtrackdegtrue $blwinddirtrue $blwindspdmps $optairspeed_inglide[$i] $optavgairspeed $optgroundspeed[$i] $seconds[$i] \n";
               #4test: print "                     $awind2track_anglerad $gammarad $betarad \n";
             }
             ### END OF TESTED WIND TRIANGLE CALC
           }
        }
        else {
          ### BLOCKED - no optimal airspeed solution => thermal climb rate too small
          $nblocked[$ileg]++ ;
          $lsolution[$ileg] = -2 ;
          $optgroundspeed[$i] = $seconds[$i] = 0.0 ;
          $thermalpct[$i] = 100. ;
          $seconds[$i] = 0 ;
          #4test: print "Optgroundspeed=0 DENOM<0 - $ileg $i $denom $thermallingclimbrate[$i] \n";
        }
      }
      else 
      {
        ### BLOCKED - thermalling climb rate <= 0
        $nblocked[$ileg]++ ;
        $lsolution[$ileg] = -1;
        $optgroundspeed[$i] = $seconds[$i] = 0.0 ;
        $thermalpct[$i] = 100. ;
        #4test: print "Optgroundspeed=0 CLIMBRATE<0 - $ileg $i $thermallingclimbrate[$i] \n";
      }

      ### END OF OPTGROUNDSPEED CALC
      ### WRITE INDIVIDUAL PT VALUES TO FILE - NB if modify, must also modify print for last point !
      if( $OUTDATAFILE ne '' ){
        { printf OUTDATAFILE "%2d %3d %6.1f %6.1f %6.0f %5.0f %8.0f %5.2f %5.2f %5.1f %6.1f %5.1f %5.0f \n",$ileg,$i,$xsort[$i],$ysort[$i], $flitedist,$flitetime, $length[$i],$thermallingclimbrate[$i],$thermalstrength[$i],$tailwindmps[$i], $optgroundspeed[$i], $thermalpct[$i], $seconds[$i] ; }
        #### { no warnings; printf OUTDATAFILE "%2d %3d %6.1f %6.1f %6.0f %5.0f %8.0f %5.2f %5.2f %5.1f %6.1f %5.1f %5.0f \n",$ileg,$i,$xsort[$i],$ysort[$i], $flitedist,$flitetime, $length[$i],$thermallingclimbrate[$i],$thermalstrength[$i],$tailwindmps[$i], $optgroundspeed[$i], $thermalpct[$i], $seconds[$i] ; }
      #4test: printf "%2d %3d %3d %6.1f %6.1f %5d %6d %8.0f %5.2f %5.2f %5.1f %6.1f %5.1f %5.0f \n",$ileg,$i,$kgridptafter,$xsort[$i],$ysort[$i], $flitetime, $flitedist, $length[$i],$thermallingclimbrate[$i],$thermalstrength[$i],$tailwindmps[$i], $optgroundspeed[$i], $thermalpct[$i], g$seconds[$i] ;
      ### add to total time here so used for next file write
			}
      $flitedist += $length[$i] ;
      $flitetime += $seconds[$i] ;
      ###- UPDATE CLOCK SECS & GET NEW DATA IF NEED BE
      if( $LVALIDTIME == 0 )
      {
        $clocksec += $seconds[$i] ;
        $#paramwarning = -1 ;
        foreach $param ( 'wstar', 'blwindspd', 'blwinddir' )
        { 
          if( $clocksec > $posttimesec{$param} )
          {
            ### age current data
            @{$pretimedata{$param}} = @{$posttimedata{$param}} ;
            $prehhmm{$param} = $posthhmm{$param} ;
            $pretimesec{$param} = $posttimesec{$param} ;
            ### IF LAST, set to constant value by not updating posttimedata & write warning
            if( $posttimeindex{$param} == $#{$lslist{$param}} )
            {
              ### set posttimesec large so will never again try to update data 
              $posthhmm{$param} = 99999 ;
              $posttimesec{$param} = 99999. ;
              push @paramwarning, $param ;
            }
            else
            {
              ### get new data
              $posttimeindex{$param}++ ;
              if(  $VALIDDAY !~ m|[0-9]-|  )
              { 
              ### FOR NON-ARCHIVE DATA
                $inputdatafile = "${DATADIR}/${previousdayhead}${param}.$filesoarday.${filetimelist{$param}[$posttimeindex{$param}]}lst.${GRID}.data";
                @{$posttimedata{$param}} = &zmapxyplotread($inputdatafile);
              }
              else
              {
                ### FOR ARCHIVE DATA
                @{$posttimedata{$param}} = &read_archived_plotfile( $archivedirname,$GRID,$filetimelist{$param}[$posttimeindex{$param}],$param );
                ### *NB* requires american unit data file input
                if( $param eq 'wstar' && $titleline3 !~ m| Unit= ft/min | && $titleline3 !~m| Unit= \[ft/min\] | ) { die 'ERROR STOP - requires american units but here wstar not ft/min' ; }
                if( $param eq 'blwindspd' && $titleline3 !~ m| Unit= kt | && $titleline3 !~ m| Unit= \[kt\] | ) { die 'ERROR STOP - requires american units but here blwindspd not kt' ; }
              }
              $posthhmm{$param} = $filetimelist{$param}[$posttimeindex{$param}] ;
              $posttimesec{$param} = 3600.* substr( $posthhmm{$param}, 0,2 ) + 60.* substr( $posthhmm{$param}, 2,2 ) ;
            }
          }
        }
        ### note: array @paramwarning gives parameters missing, but currently not printed
        if( $#paramwarning > -1 )
        {  $warningfooter .= sprintf " data unavailable after %s so assumed constant then\n", $filetimelist{$paramwarning[0]}[$posttimeindex{$paramwarning[0]}],  $filetimelist{$paramwarning[0]}[$posttimeindex{$paramwarning[0]}] ;}
         #old print "*WARNING: @paramwarning data not available after $filetimelist{$paramwarning[0]}[$posttimeindex{$paramwarning[0]}] so now using only time $filetimelist{$paramwarning[0]}[$posttimeindex{$paramwarning[0]}] \n"; 
      }
        
    ### END OF LOOP OVER POINTS ALONG LEG
    }

###### PRINT LEG RESULTS
    ### CALC LEG SPATIAL AVG
    $leglength = 0;
    $legspatialavgclimbratesum = 0.0 ;
    $legspatialavgtailwindsum = 0.0 ;
    for ( $i=0; $i<=($nlegpts-2); $i++ )
    {
      #4test: if ( ! defined $airspeed[$i] ) { print "UNDEFINED AIRSPEED - $i $length[$i] $seconds[$i] $vor[$i] \n" ; }
      ### sum leg time
      $leglength += $length[$i] ;
      $legspatialavgclimbratesum += $length[$i] * $thermallingclimbrate[$i] ;
      $legspatialavgtailwindsum += $length[$i] * $tailwindmps[$i] ;
    }
    ### TEST FOR ZERO LEG LENGTH - IF SO SKIP REST OF PROCESSING FOR THIS LEG
    if( $leglength == 0 ) 
    {
      print "** WARNING - ignored a leg with zero length (duplicate turnpoint?)\n"; 
      next LEG ;
    }
    $totallength += $leglength ;
    $totalspatialavgclimbratesum += $legspatialavgclimbratesum ;
    $totalspatialavgtailwindsum += $legspatialavgtailwindsum ;
    # $legkm = 0.001 * $leglength ;
    # $legspatialavgclimbrate =  $legspatialavgclimbratesum / $leglength  ;
    # $legspatialavgclimbratekt =  $legspatialavgclimbrate * $mps2kt ;
    #PAULS NOT NEEDED $legspatialavgtailwindkt = $mps2kt * $legspatialavgtailwindsum / $leglength  ;
    #old printf " LEG %d %4.1f %4.0f %4.0f  Spatial Average\n", $ileg, $legspatialavgclimbrate, $legspatialavgtailwindkt, $legkm ;
    ### compute % of no solution "blocked" boxes
    $totalblocked += $nblocked[$ileg] ;
    $totallegboxs += $nlegboxs[$ileg] ;
    ###### CALC + PRINT LEG OPTIMAL SOLUTION RESULTS
    if( $lsolution[$ileg] == 0 )
    {
      $legsec = 0 ;
      $legclimbratesum = 0 ;
      $legtailwindsum = 0 ;
      $legthermaltimesum = 0 ;
      $legoptairspeedsum = 0;
      for ( $i=0; $i<=($nlegpts-2); $i++ )
      {
        #4test: if ( ! defined $airspeed[$i] ) { print "UNDEFINED AIRSPEED - $i $length[$i] $seconds[$i] $vor[$i] \n" ; }
        ### sum leg time
        $legsec += $seconds[$i] ;
        $legclimbratesum += $seconds[$i] * $thermallingclimbrate[$i] ;
        $legtailwindsum += $seconds[$i] * $tailwindmps[$i] ;
        $legoptairspeedsum +=  $seconds[$i] * $optairspeed_inglide[$i]  ;
        $legthermaltimesum += $seconds[$i] * $thermalpct[$i] ;
        #boxprint: printf "%3d %6.1f %6.1f %3d %3d %8.0f %6.1f %5.0f \n",$i,$xsort[$i],$ysort[$i], $igridptafter[$i],$jgridptafter[$i], $length[$i], $optgroundspeed[$i],$seconds[$i]  ;
      }
      $totalsec += $legsec ;
      $totalclimbratesum += $legclimbratesum ;
      $totalthermaltime += $legthermaltimesum ;
      $totaloptairspeedsum += $legoptairspeedsum ;
      $totaltailwindsum += $legtailwindsum ;
      # $legmin = 0.01666667 * $legsec ;
      # $legavggroundspeedkt = $mps2kt * ( $leglength / $legsec )   ;
      # $legavggroundspeedkph = 3.6 * ( $leglength / $legsec )   ;
      # $legoptairspeedavgkt = $mps2kt * $legoptairspeedsum / $legsec  ;
      # $legtailwindavgkt = $mps2kt * $legtailwindsum / $legsec  ;
      # $legclimbrateavg =  $legclimbratesum / $legsec  ;
      # $legclimbrateavgkt =  $legclimbrateavg * $mps2kt ;
      # $legthermalpct = $legthermaltimesum / $legsec ;
      ### MULTI-TIME LEG PRINTOUT INCLUDES TURNPOINT TIME
      if( $LVALIDTIME == 0 )
      { 
        $oldclockhhmm = $clockhhmm;
        $clockhhmm = 100*int($clocksec/3600.) + int( ( $clocksec - 3600.*(int($clocksec/3600.)) ) /60. ) ;
        $clockprt = sprintf "%04d-%04d", $oldclockhhmm,$clockhhmm ;
      }
      else
				{ $clockprt = '' ; }
			#### { no warnings };
			# { 
      # printf "%2d %s %4.0f %4.0f %4.1f %4.0f %4.1f %4.0f %3.0f  %3.0f %3.0f %3.0f \n", $ileg, $clockprt, $legkm, $legspatialavgtailwindkt, $legspatialavgclimbratekt, $legtailwindavgkt, $legclimbrateavgkt, $legmin, $legavggroundspeedkt, $legavggroundspeedkph, $legoptairspeedavgkt, $legthermalpct  ;
			# }
    }
    else
    {
      ###### PRINT LEG RESULTS WHEN NO OPTIMAL SOLUTION
      $ltotalsolution = 0 ;
      ### compute % of no solution "blocked" boxes
      $pctblocked = nint( 100.*( $nblocked[$ileg] / $nlegboxs[$ileg] ) );
      # printf "%2d  %4.0f %4.0f %4.1f   NO SOLN    %sblocked=%2d \n", $ileg, $legkm, $legspatialavgtailwindkt, $legspatialavgclimbratekt, '%',$pctblocked ;
    }

### END OF LOOP OVER ALL TURNPOINTS
  }

  ### WRITE FINAL PT VALUES TO FILE
  if( $OUTDATAFILE ne '' )
		#### { no warnings;
		{
		printf OUTDATAFILE "%2d %3d %6.1f %6.1f %6.0f %5.0f %8.0f %5.2f %5.2f %5.1f %6.1f %5.1f %5.0f \n",$nturnpts,0,$xsort[$nlegpts-1],$ysort[$nlegpts-1], $flitedist,$flitetime, 0,0,0,0,0,0,0 ; }
  #4test: printf "%2d %3d %6.1f %6.1f %5d %6d %8.0f %5.2f %5.2f %5.1f %6.1f %5.0f \n",$nturnpts,0,$xsort[$nlegpts-1],$ysort[$nlegpts-1], $flitetime, $flitedist, 0,0,0,0,0,0 ;
  
  ### CALC SPATIAL AVG TOTALS
  $totalkm = 0.001 * $totallength ;
  $totalspatialavgtailwindkt = $mps2kt * $totalspatialavgtailwindsum / $totallength  ;
  $totalspatialavgclimbrate =  $totalspatialavgclimbratesum / $totallength  ;
  $totalspatialavgclimbratekt =  $totalspatialavgclimbrate * $mps2kt ;	# Now Knots
  ### CALC + PRINT OVERALL TOTAL RESULTS
  if( $ltotalsolution == 1 )
  {
    $totalmin = 0.01666667 * $totalsec ;
    $totalavggroundspeedkt = $mps2kt * ( $totallength / $totalsec )   ;
    $totalavggroundspeedkph = 3.6 * ( $totallength / $totalsec )   ;
    $totaloptairspeedavgkt = $mps2kt * $totaloptairspeedsum / $totalsec  ;
    $totaltailwindavgkt = $mps2kt * $totaltailwindsum / $totalsec  ;
    $totalclimbrateavg =  $totalclimbratesum / $totalsec  ;
    $totalclimbrateavgkt =  $totalclimbrateavg * $mps2kt ;
    $totalthermalpct = $totalthermaltime / $totalsec ;
    ### ADD EXTRA COLUMN FOR MULIT-TIME TIME
    if( $LVALIDTIME == 0 )
			{ $clockprt = sprintf "%04d-%04d", $VALIDTIME, $clockhhmm ; }
    else
			{  $clockprt = ''; }
		#PAULS
		#### {no warnings;}
#		{
#		for( $i = 0; $i <= $#{$filetimes}; $i++){
#			printf "%s ", $filetimes[$i] ;
#		}
#		printf("\n");
    printf " %s %4.0f %4.0f %4.1f %4.0f %4.1f %4.0f %3.0f  %3.0f %3.0f %3.0f", $clockprt, $totalkm, $totalspatialavgtailwindkt, $totalspatialavgclimbratekt, $totaltailwindavgkt, $totalclimbrateavgkt, $totalmin, $totalavggroundspeedkt, $totalavggroundspeedkph, $totaloptairspeedavgkt, $totalthermalpct  ;
  }
  else
  {
    ###### PRINT OVERALL TOTAL RESULTS WHEN NO OPTIMAL SOLUTION
    ### compute % of no solution "blocked" boxes
    $pctblocked = nint( 100.*( $totalblocked / $totallegboxs ) );
    printf " %04d      %4.0f %4.0f %4.1f   NO SOLN    %sblocked=%-3d", $VALIDTIME, $totalkm, $totalspatialavgtailwindkt, $totalspatialavgclimbratekt, '%',$pctblocked ;
  }
  ### PRINT WARNING FOOTER, if any
  if(  $warningfooter ne '' )
  { print " WARNING: ${warningfooter}" ; }
  printf "\n" ;

  #4test: print "titleline1=${titleline1}= \n";
  } # END OF LOOP OVER ALL TIMES

  if( $OUTDATAFILE ne '' )
    { close (OUTDATAFILE) ; }


#########################################################################
##########################  SUBROUTINES  ################################
#########################################################################
### FIND NEAREST INTEGER
sub nint { int($_[0] + ($_[0] >=0 ? 0.5 : -0.5)); }
##################################################################################################
### SET POLAR DATA - COEFFS AND WGTS
sub set_glider_data()
{
  ### SET POLAR COEFFS - W=a*V^2+b*V+c where a,b,c for V in km/hr and _negative_ W in m/s ala Reichmann,Herold,etc
  ###   to use V in m/s, W=a'*V^2+b'*V+c where a`=a/kmphr2mps^2 & b'=b/kmphr2mps & kmphr2mps=0.277778 
  ### SET WEIGHT INFO =  dry weight on which polar data based (kg)
  ### SET BALLAST INFO = liters of ballast can carry (1 liter = 1 kg!)
  ### START OF MY POLAR DATA 
     $polar_data{'dg400-jack'} = '-1.3419e-4,2.077e-2,-1.37' ; $weight_data{'dg400-jack'} = '444.' ; $ballast_data{'dg400-jack'} = '90.' ; 
  ### START OF HEROLD DATA at http://www.winpilot.com/polar.asp  - his three (V,W) pairs were converted to corresponding a,b,c
     $polar_data{'1-26A'} = '-0.000356204,0.040847,-2.002' ; $weight_data{'1-26A'} = '261.' ; $ballast_data{'1-26A'} = '0.' ; 
     $polar_data{'1-26E'} = '-0.000325155,0.041163,-2.221' ; $weight_data{'1-26E'} = '315.' ; $ballast_data{'1-26E'} = '0.' ; 
     $polar_data{'1-34'} = '-0.000268213,0.038494,-2.097' ; $weight_data{'1-34'} = '354.' ; $ballast_data{'1-34'} = '0.' ; 
     $polar_data{'1-35A'} = '-0.000203714,0.031158,-1.831' ; $weight_data{'1-35A'} = '381.' ; $ballast_data{'1-35A'} = '179.' ; 
     $polar_data{'1-36_Sprite'} = '-0.000329902,0.045799,-2.252' ; $weight_data{'1-36_Sprite'} = '322.' ; $ballast_data{'1-36_Sprite'} = '0.' ; 
     $polar_data{'604'} = '0.000097318,-.082437,8.794' ; $weight_data{'604'} = '570.' ; $ballast_data{'604'} = '100.' ; 
     $polar_data{'ASW-12'} = '-0.000179391,0.026422,-1.461' ; $weight_data{'ASW-12'} = '948.' ; $ballast_data{'ASW-12'} = '189.' ; 
     $polar_data{'ASW-15'} = '-0.000193631,0.029738,-1.823' ; $weight_data{'ASW-15'} = '349.' ; $ballast_data{'ASW-15'} = '91.' ; 
     $polar_data{'ASW-17'} = '-0.000154923,0.025872,-1.626' ; $weight_data{'ASW-17'} = '522.' ; $ballast_data{'ASW-17'} = '151.' ; 
     $polar_data{'ASW-19'} = '-0.000225199,0.041617,-2.655' ; $weight_data{'ASW-19'} = '363.' ; $ballast_data{'ASW-19'} = '125.' ; 
     $polar_data{'ASW-20'} = '-0.000174026,0.031346,-2.063' ; $weight_data{'ASW-20'} = '377.' ; $ballast_data{'ASW-20'} = '159.' ; 
     $polar_data{'ASW-24'} = '-0.000127520,0.017509,-1.123' ; $weight_data{'ASW-24'} = '350.' ; $ballast_data{'ASW-24'} = '159.' ; 
     $polar_data{'ASW-27_Wnglts'} = '-0.000130178,0.023032,-1.600' ; $weight_data{'ASW-27_Wnglts'} = '357.' ; $ballast_data{'ASW-27_Wnglts'} = '165.' ; 
     $polar_data{'DG-400_15m'} = '-0.000131050,0.026027,-2.020' ; $weight_data{'DG-400_15m'} = '440.' ; $ballast_data{'DG-400_15m'} = '90.' ; 
     $polar_data{'DG-400_17m'} = '-0.000109520,0.020602,-1.588' ; $weight_data{'DG-400_17m'} = '444.' ; $ballast_data{'DG-400_17m'} = '90.' ; 
     $polar_data{'DG-800_15m'} = '-0.000088161,0.013142,-1.058' ; $weight_data{'DG-800_15m'} = '468.' ; $ballast_data{'DG-800_15m'} = '120.' ; 
     $polar_data{'DG-800_18m'} = '-0.000069468,0.006428,-0.521' ; $weight_data{'DG-800_18m'} = '472.' ; $ballast_data{'DG-800_18m'} = '120.' ; 
     $polar_data{'DiscusA'} = '-0.000342455,0.072918,-4.599' ; $weight_data{'DiscusA'} = '350.' ; $ballast_data{'DiscusA'} = '182.' ; 
     $polar_data{'GenesisII'} = '-0.000163640,0.026349,-1.639' ; $weight_data{'GenesisII'} = '374.' ; $ballast_data{'GenesisII'} = '151.' ; 
     $polar_data{'H-201_StdLibelle'} = '-0.000176419,0.023744,-1.433' ; $weight_data{'H-201_StdLibelle'} = '304.' ; $ballast_data{'H-201_StdLibelle'} = '50.' ; 
     $polar_data{'H-301_Libelle'} = '-0.000329333,0.054431,-2.887' ; $weight_data{'H-301_Libelle'} = '300.' ; $ballast_data{'H-301_Libelle'} = '50.' ; 
     $polar_data{'IS-29D2_Lark'} = '-0.000178364,0.021373,-1.169' ; $weight_data{'IS-29D2_Lark'} = '360.' ; $ballast_data{'IS-29D2_Lark'} = '0.' ; 
     $polar_data{'Jantar2_SZD-42A'} = '-0.000156189,0.024749,-1.497' ; $weight_data{'Jantar2_SZD-42A'} = '482.' ; $ballast_data{'Jantar2_SZD-42A'} = '191.' ; 
     $polar_data{'Ka-6CR'} = '-0.000263061,0.037955,-2.120' ; $weight_data{'Ka-6CR'} = '310.' ; $ballast_data{'Ka-6CR'} = '0.' ; 
     $polar_data{'L-33_Solo'} = '-0.000275409,0.042173,-2.380' ; $weight_data{'L-33_Solo'} = '330.' ; $ballast_data{'L-33_Solo'} = '0.' ; 
     $polar_data{'LS-1C'} = '-0.000221766,0.038698,-2.524' ; $weight_data{'LS-1C'} = '350.' ; $ballast_data{'LS-1C'} = '91.' ; 
     $polar_data{'LS-3'} = '-0.000285925,0.067384,-4.828' ; $weight_data{'LS-3'} = '383.' ; $ballast_data{'LS-3'} = '121.' ; 
     $polar_data{'LS-4a'} = '-0.000301194,0.059905,-3.706' ; $weight_data{'LS-4a'} = '361.' ; $ballast_data{'LS-4a'} = '121.' ; 
     $polar_data{'Nimbus2_20m'} = '-0.000175297,0.029284,-1.742' ; $weight_data{'Nimbus2_20m'} = '493.' ; $ballast_data{'Nimbus2_20m'} = '159.' ; 
     $polar_data{'Nimbus3_25m'} = '-0.000129521,0.017982,-1.006' ; $weight_data{'Nimbus3_25m'} = '527.' ; $ballast_data{'Nimbus3_25m'} = '159.' ; 
     $polar_data{'Nimbus3T'} = '-0.000122928,0.017572,-1.007' ; $weight_data{'Nimbus3T'} = '577.' ; $ballast_data{'Nimbus3T'} = '310.' ; 
     $polar_data{'Nimbus4_26m'} = '-0.000136821,0.021365,-1.239' ; $weight_data{'Nimbus4_26m'} = '597.' ; $ballast_data{'Nimbus4_26m'} = '303.' ; 
     $polar_data{'PIK-20B'} = '-0.000154165,0.023746,-1.499' ; $weight_data{'PIK-20B'} = '354.' ; $ballast_data{'PIK-20B'} = '144.' ; 
     $polar_data{'PIK-20D'} = '-0.000188824,0.029145,-1.717' ; $weight_data{'PIK-20D'} = '348.' ; $ballast_data{'PIK-20D'} = '144.' ; 
     $polar_data{'PIK-20E'} = '-0.000120307,0.012809,-0.789' ; $weight_data{'PIK-20E'} = '437.' ; $ballast_data{'PIK-20E'} = '80.' ; 
     $polar_data{'PIK-30M'} = '-0.000126214,0.022729,-1.657' ; $weight_data{'PIK-30M'} = '460.' ; $ballast_data{'PIK-30M'} = '0.' ; 
     $polar_data{'PW-5_Smyk'} = '-0.000257089,0.034076,-1.796' ; $weight_data{'PW-5_Smyk'} = '300.' ; $ballast_data{'PW-5_Smyk'} = '0.' ; 
     $polar_data{'RussiaAC-4_13m'} = '-0.000188581,0.023464,-1.388' ; $weight_data{'RussiaAC-4_13m'} = '250.' ; $ballast_data{'RussiaAC-4_13m'} = '0.' ; 
     $polar_data{'StdCirrus'} = '-0.000238804,0.040618,-2.453' ; $weight_data{'StdCirrus'} = '337.' ; $ballast_data{'StdCirrus'} = '80.' ; 
     $polar_data{'SZD-30'} = '-0.001935,0.14859,-4.2319' ; $weight_data{'SZD-30'} = '340.' ; $ballast_data{'SZD-30'} = '0.' ; 
     $polar_data{'SZD-55-1'} = '-0.000268330,0.053389,-3.320' ; $weight_data{'SZD-55-1'} = '336.' ; $ballast_data{'SZD-55-1'} = '201.' ; 
     $polar_data{'VentusA-B_17m'} = '-0.000153371,0.025876,-1.691' ; $weight_data{'VentusA-B_17m'} = '358.' ; $ballast_data{'VentusA-B_17m'} = '151.' ; 
     $polar_data{'VentusB_15m'} = '-0.000126558,0.018870,-1.316' ; $weight_data{'VentusB_15m'} = '341.' ; $ballast_data{'VentusB_15m'} = '151.' ; 
     $polar_data{'ZuniII'} = '-0.000164235,0.022160,-1.330' ; $weight_data{'ZuniII'} = '358.' ; $ballast_data{'ZuniII'} = '182.' ; 
     $polar_data{'ASH-25_25m_Pil'} = '-0.000094505,0.009998,-0.587' ; $weight_data{'ASH-25_25m_Pil'} = '602.' ; $ballast_data{'ASH-25_25m_Pil'} = '120.' ; 
     $polar_data{'ASH-25_25m_Pas'} = '-0.000088170,0.010025,-0.632' ; $weight_data{'ASH-25_25m_Pas'} = '693.' ; $ballast_data{'ASH-25_25m_Pas'} = '120.' ; 
     $polar_data{'ASH-25M_Pil'} = '-0.000090103,0.009939,-0.609' ; $weight_data{'ASH-25M_Pil'} = '660.' ; $ballast_data{'ASH-25M_Pil'} = '121.' ; 
     $polar_data{'ASH-25M_Pas'} = '-0.000083285,0.009464,-0.603' ; $weight_data{'ASH-25M_Pas'} = '750.' ; $ballast_data{'ASH-25M_Pas'} = '121.' ; 
     $polar_data{'DG-500_Pil'} = '-0.000159462,0.024101,-1.412' ; $weight_data{'DG-500_Pil'} = '570.' ; $ballast_data{'DG-500_Pil'} = '160.' ; 
     $polar_data{'DG-500_Pas'} = '-0.000149216,0.024473,-1.551' ; $weight_data{'DG-500_Pas'} = '660.' ; $ballast_data{'DG-500_Pas'} = '160.' ; 
     $polar_data{'DG-500M_Pil'} = '-0.000148151,0.024048,-1.513' ; $weight_data{'DG-500M_Pil'} = '659.' ; $ballast_data{'DG-500M_Pil'} = '100.' ; 
     $polar_data{'DG-500M_Pas'} = '-0.000139278,0.024190,-1.627' ; $weight_data{'DG-500M_Pas'} = '750.' ; $ballast_data{'DG-500M_Pas'} = '100.' ; 
     $polar_data{'DuoDiscus_Pil'} = '-0.000297310,0.062668,-3.984' ; $weight_data{'DuoDiscus_Pil'} = '537.' ; $ballast_data{'DuoDiscus_Pil'} = '201.' ; 
     $polar_data{'DuoDiscus_Pas'} = '-0.000315738,0.074531,-5.150' ; $weight_data{'DuoDiscus_Pas'} = '628.' ; $ballast_data{'DuoDiscus_Pas'} = '201.' ; 
     $polar_data{'Grob103_TwinII_Pil'} = '-0.000187562,0.032256,-2.118' ; $weight_data{'Grob103_TwinII_Pil'} = '494.' ; $ballast_data{'Grob103_TwinII_Pil'} = '0.' ; 
     $polar_data{'Grob103_TwinII_Pas'} = '-0.000173275,0.032363,-2.306' ; $weight_data{'Grob103_TwinII_Pas'} = '580.' ; $ballast_data{'Grob103_TwinII_Pas'} = '0.' ; 
     $polar_data{'JanusB_18m_Pil'} = '-0.000346616,0.069703,-4.190' ; $weight_data{'JanusB_18m_Pil'} = '508.' ; $ballast_data{'JanusB_18m_Pil'} = '170.' ; 
     $polar_data{'JanusB_18m_Pas'} = '-0.000317857,0.069626,-4.559' ; $weight_data{'JanusB_18m_Pas'} = '603.' ; $ballast_data{'JanusB_18m_Pas'} = '170.' ; 
     $polar_data{'Nimbus3D_25m_Pil'} = '-0.000088882,0.009929,-0.621' ; $weight_data{'Nimbus3D_25m_Pil'} = '621.' ; $ballast_data{'Nimbus3D_25m_Pil'} = '168.' ; 
     $polar_data{'Nimbus3D_25m_Pas'} = '-0.000082691,0.009825,-0.658' ; $weight_data{'Nimbus3D_25m_Pas'} = '712.' ; $ballast_data{'Nimbus3D_25m_Pas'} = '168.' ; 
     $polar_data{'Nimbus3DM_25m_Pil'} = '-0.000110902,0.019118,-1.299' ; $weight_data{'Nimbus3DM_25m_Pil'} = '748.' ; $ballast_data{'Nimbus3DM_25m_Pil'} = '168.' ; 
     $polar_data{'Nimbus3DM_25m_Pas'} = '-0.000102798,0.018201,-1.299' ; $weight_data{'Nimbus3DM_25m_Pas'} = '820.' ; $ballast_data{'Nimbus3DM_25m_Pas'} = '168.' ; 
     $polar_data{'Nimbus4DM_26m_Pil'} = '-0.000123583,0.021293,-1.364' ; $weight_data{'Nimbus4DM_26m_Pil'} = '729.' ; $ballast_data{'Nimbus4DM_26m_Pil'} = '168.' ; 
     $polar_data{'Nimbus4DM_26m_Pas'} = '-0.000115756,0.021041,-1.427' ; $weight_data{'Nimbus4DM_26m_Pas'} = '820.' ; $ballast_data{'Nimbus4DM_26m_Pas'} = '168.' ; 
     $polar_data{'Nimbus4D_Pil'} = '-0.000130179,0.021111,-1.274' ; $weight_data{'Nimbus4D_Pil'} = '652.' ; $ballast_data{'Nimbus4D_Pil'} = '303.' ; 
     $polar_data{'Nimbus4D_Pas'} = '-0.000120390,0.020620,-1.322' ; $weight_data{'Nimbus4D_Pas'} = '743.' ; $ballast_data{'Nimbus4D_Pas'} = '303.' ; 
     $polar_data{'StemmeS10_Pil'} = '-0.000121906,0.019098,-1.293' ; $weight_data{'StemmeS10_Pil'} = '759.' ; $ballast_data{'StemmeS10_Pil'} = '0.' ; 
     $polar_data{'StemmeS10_Pas'} = '-0.000099050,0.012916,-0.785' ; $weight_data{'StemmeS10_Pas'} = '850.' ; $ballast_data{'StemmeS10_Pas'} = '0.' ; 
  ### END OF HEROLD DATA
  return;
}
#########################################################################
### READ (possibly zipped) DATA FILE
sub zmapxyplotread()
{
  ### modified from sub mapxyplotread to read either text or zipped-text files
  ### required changing from "open" to creating a text-filled variable 
  my $inputfile = $_[0] ; 
  my @FILE ; 
  ### read data
  ### READ INPUT FILE DATA - EITHER TEXT OR ZIPPED-TEXT FILE
  ### read header info
  if ( -f "$inputfile" )
    { @FILE = `cat $inputfile` ; }
  elsif ( -f "${inputfile}.zip" )
    { @FILE = `unzip -p "${inputfile}.zip"` ; }
  else
    { print "*** $program ERROR EXIT: data file $inputfile NOT FOUND"; }
  #old open ( FILE, "<${inputfile}" ) or die "*** $program ERROR: data file $inputfile NOT FOUND" ;
  # search for marker line
  my $line = ''; 
  while ( defined $line && $line !~ /^---/ )
  { 
   # once got mysterious "UIV in pattern match" here (which could not replicate in later manual run) so put in test
    if( ! defined $line ) {die "*** $program ERROR EXIT: undefined line : $inputfile" ; }
    #old $line = <FILE>;
    $line = shift @FILE ;
  }
  if ( ! defined $line || $line !~ /^---/ ) { print "*** $program ERROR EXIT: data file $inputfile MISSING DATA"; }
  ### READ HEADER LINES
  ### MODIFIED - make non-local to pass titleline1 between routines
  chomp( $titleline1 = shift @FILE );
  #old chomp( my $titleline1 = shift @FILE );
  chomp( my $titleline2 = shift @FILE );
  chomp( my $titleline3 = shift @FILE );
  #old chomp( my $titleline1 = <FILE> );
  #old chomp( my $titleline2 = <FILE> );
  #old chomp( my $titleline3 = <FILE> );
  #4test: print "FILE= $inputfile  TITLE= $titleline1 \n";
  ### MODIFIED - make non-local to pass array dims between routines
  my ($head,$filegridname,$equal, $tail);
  #ORIGINAL my ($head,$filegridname,$equal,$imap1in,$imap2in,$jmap1in,$jmap2in,$tail);
  ### allow for old and new grid array index delimiter
  if( $titleline2 =~ m|Indexs=| )
    { ($head,$tail) = split( /  *Indexs=  */, $titleline2 ); }
  else
    { ($head,$tail) = split( /  *=  */, $titleline2 ); }
  ($imap1in,$imap2in,$jmap1in,$jmap2in,$tail) = split( /  */, $tail );
  #PAULS print "FILE= $inputfile  imap1in = $imap1in imap2in = $imap2in jmap1in = $jmap1in jmap2in = $jmap2in \n";
  #old ($head,$filegridname,$equal,$imap1in,$imap2in,$jmap1in,$jmap2in,$tail) = split( /  */, $titleline2 );
  ### READ DATA INTO 1D FILE
  my @a = ();
  my @data = ();
  my ($iicol,$jjrow,$icol,$jrow);
  $jjrow = -1;
  for ( $ii=0; $ii<=$#FILE; $ii++ )
  #old while ( <FILE> )
  {
    chomp( $line = $FILE[$ii] );
    @data =split /  */, $line ;
    #old @data = split;
    push @a, @data ;
  }
  return @a;
}
##################################################################################################
sub read_archived_plotfile ()
{
  ### MODIFIED TO ALLOW PASSING $imap1in,$imap2in,$jmap1in,$jmap2in TO MAIN ROUTINE

  ### ONLY CONSIDER "curr" DAY
  my ($archivefiledir,$grid,$validtime,$param) = @_;
  ### find archived file
  my $archivefilename = "${archivefiledir}/${param}.curr.${validtime}lst.${grid}.data.zip";
  ### $TMPFILE used to unzip data to
  my $tmpid = int( rand 999998 ) +1;
  my $tmpfile = "/tmp/rasptrackavg.read_archived_plotfile.${tmpid}.tmp";
  ### test for file existence
  if ( ! -f $archivefilename ) {  die "*** ERROR EXIT - $archivefilename NON_EXISTENT" ; }
  #old if ( ! -f $archivefilename ) { return -1 ; }
  ### now unzip to tmp file (expect $unzipout to be blank)
  ### MAKE WORLD READ-WRITE SO DONT GET PERMISSION DENIED IF RUN FROM SM/APACHE 
  my $unzipout = `umask 000 ; unzip -p $archivefilename  2>&1 >| $tmpfile`;
  #old my $unzipout = `unzip -p $archivefilename  2>&1 >| $tmpfile ; chmod -f ugo+rw $tmpfile`;
  #older my $unzipout = `unzip -p $archivefilename  2>&1 >| $tmpfile`;
  if( $unzipout ne '' ) { die "*** ERROR EXIT - BAD UNZIP OF $archivefilename TO $tmpfile GIVES MESSAGE $unzipout" ; }
  #old if( $unzipout ne '' ) { return -3 ; };
  ### READ INPUT FILE DATA
  ### read header info
  open ( FILE, "<${tmpfile}" ) or die "*** ERROR EXIT - UNZIPPED FILE $tmpfile NON_EXISTENT" ;
  #old open ( FILE, "<${archivefilename}" ) or return -4 ;
  # search for marker line
  my $line = ' '; 
  while ( $line !~ /^---/ )
  { 
   # once got mysterious "UIV in pattern match" here (which could not replicate in later manual run) so put in test
    if( ! defined $line ) { die "*** ERROR EXIT: undefined line in read_archived_plotfile : $archivefilename"; }
    $line = <FILE>;
  }
  ### READ HEADER LINES
  chomp( my $titleline1 = <FILE> );
  chomp( my $titleline2 = <FILE> );
#JACK - rasptrackavg MODIFIED TO ALLOW UNITS TEST
  chomp( $titleline3 = <FILE> );
  #TEST print "FILE= $archivefilename  TITLE_1= $titleline1 \n";
  #TEST print "FILE= $archivefilename  TITLE_2= $titleline2 \n";
  #TEST print "FILE= $archivefilename  TITLE_3= $titleline3 \n";
### MODIFIED TO ALLOW PASSING $imap1in,$imap2in,$jmap1in,$jmap2in TO MAIN ROUTINE
my ($head,$filegridname,$equal,$tail);
#original my ($head,$filegridname,$equal,$imap1in,$imap2in,$jmap1in,$jmap2in,$tail);
  ### allow for old and new grid array index delimiter
  if( $titleline2 =~ m|Indexs=| )
    { ($head,$tail) = split( /  *Indexs=  */, $titleline2 ); }
  else
    { ($head,$tail) = split( /  *=  */, $titleline2 ); }
  ($imap1in,$imap2in,$jmap1in,$jmap2in,$tail) = split( /  */, $tail );
  #old ($head,$filegridname,$equal,$imap1in,$imap2in,$jmap1in,$jmap2in,$tail) = split( /  */, $titleline2 );
  ### READ DATA INTO 1D FILE
  my @a = ();
  my @data = ();
  my ($iicol,$jjrow,$icol,$jrow);
  $jjrow = -1;
  while ( <FILE> )
  {
    @data = split;
    push @a, @data ;
  }
  close ( FILE );
	{ `/bin/rm -f $tmpfile` ; }
  return @a;
}
#########################################################################
sub cell_path_intersections ()
{
### Calc cell intersections over path (i.e. where line intersects cell perimeter around integer x, y values
### PRESENTLY *HALF* LINE INTERSECTION ENABLED - i.e. determines location of line intersection with grid perimeter around each integer value
###                                              FULL LINE determines location of line intersection with integer axis value lines
### METHOD USES FACT THAT INTERSECTIONS MUST OCCUR ALONG HALF/FULL LINE SO JUST FIND THOSE (so do not need to trace line in detail)
### *NB* not tested for negative values !
### currently allows 0 path lengths (occurs when path passes through cell corner)
### ALL DONE IN INTEGER GRID SPACE
### POINT ORDERING IS FROM PT1 to PT2 - can treat const x or y cases
### RETURN: $npts,@x,@y - include start,end pts in output
### ARGS: xstart,ystart, xend,yend 

### SET START, END POINT
   my ($x1,$y1,$x2,$y2) = @_ ;
   my ( $m, $intercept, $x, $y, $xstart,$xend, $ystart,$yend, $i, $npts );
   my ( @xint,@yint, @xsort,@ysort );

  #45deg: $x1 =  1.1 ; $y1 =  1.2 ; $x2 = 4.4 ; $y2 =  4.5 ;
  #backwardX: $x1 =  5.2 ; $y1 =  1.8 ; $x2 = 3.8 ; $y2 =  4.8 ;
  #constX: $x1 =  5.2 ; $y1 =  1.8 ; $x2 = 5.2 ; $y2 =  4.8 ;
  #constY: $x1 =  5.2 ; $y1 =  1.8 ; $x2 = 3.8 ; $y2 =  1.8 ;

  #full2halfline-kludge: ### KLUDGE GIVES HALF-LINE RESULTS BY SHIFTING BY 1/2 IN EACH DIRECTION, GETTING FULL-LINE RESULTS, THEN UN-SHIFTING 
  #full2halfline-kludge: ### *NB* TO USE THIS MUST ENABLE "FULL-LINE" STATEMENTS, NOT "HALF-LINE" STATEMENTS  
  #full2halfline-kludge  ### SET LHALFLINES=1 TO INSTEAD FIND INTERSECTION WITH LINES MID-WAY BETWEEN INTEGER VALUES
  #full2halfline-kludge  ### (for ease of treatment, simple add 0.5 to initial x,y values then subtract from answer
  #full2halfline-kludge  # $LHALFLINES = 0 ;  # find intersection with integer value x,y lines
  #full2halfline-kludge  # $LHALFLINES = 1 ;  # find intersection with lines mid-way between integer value x,y lines

  #full2halfline-kludge  ### TREAT HALF-LINE INTERSECTION CASE AS FULL-LINE SHIFT
  #full2halfline-kludge  # if ( $LHALFLINES == 1 )
  #full2halfline-kludge  # {
  #full2halfline-kludge  #  $x1 = $x1 + 0.5 ;
  #full2halfline-kludge  #  $y1 = $y1 + 0.5 ;
  #full2halfline-kludge  #  $x2 = $x2 + 0.5 ;
  #full2halfline-kludge  #  $y2 = $y2 + 0.5 ;
  #full2halfline-kludge  # }

### FIND INTEGER X AND Y INTERSECTIONS
   ### to include start,end values in list
  if ( $x1 != $x2 )
    { push @xint, ($x1, $x2) ; }
  else
    { push @yint, ($y1, $y2) ; }
### calc line eqn coeffs y=mx+b
  ### allow for const x case
  if ( $x1 != $x2 )
  { 
    $m = ( $y2 - $y1 ) / ( $x2 - $x1 ) ;
    $intercept = $y1 - $m*$x1 ;
  }
### FIND INTEGER X INTERSECTIONS
  if ( $x1 < $x2 )
    #halfline+
    { $xstart = int($x1+1.5); $xend   = int($x2+0.5) ; }
    #fullline+    { $xstart = int($x1+1); $xend   = int($x2) ; }
  else
    #halfline+
    { $xend = int($x1+0.5) ; $xstart = int($x2+1.5) ; }
    #fullline+    { $xend = int($x1) ; $xstart = int($x2+1) ; }
  for ( $x=$xstart ; $x<=$xend ; $x++ )
  {
    #halfline+
    push @xint, $x -0.5 ;
    #fullline+    push @xint, $x ;
  }
### FIND INTEGER Y INTERSECTIONS
  if ( $y1 < $y2 )
    #halfline+
    { $ystart = int($y1+1.5); $yend   = int($y2+0.5) ; }
    #fullline+    { $ystart = int($y1+1); $yend   = int($y2) ; }
  else
    #halfline+
    { $yend = int($y1+0.5) ; $ystart = int($y2+1.5) ; }
    #fullline+    { $yend = int($y1) ; $ystart = int($y2+1) ; }
  ### allow for const x case
  if ( $x1 != $x2 )
  { 
    for ( $y=$ystart ; $y<=$yend ; $y++ )
    {
      #halfline+
      $x =  ( $y -0.5 - $intercept ) / $m ;
      #fullline+      $x = ( $y - $intercept ) / $m ;
      push @xint, $x ;
    }
  }
  else
  {
  ### below is for const x case
    for ( $y=$ystart ; $y<=$yend ; $y++ )
    {
      push @yint, $y -0.5 ;
    }
  }
### SORT ORDER DEPENDS ON DIRECTION
  ### allow for const x case
  if ( $x1 != $x2 )
  {
    if ( $x1 < $x2 )
    {
      @xsort = sort { $a <=> $b; }  @xint ;
    }
    else
    {
      @xsort = sort { $b <=> $a; }  @xint ;
    }
    ### CALC CORRESPONDING Y
    for ( $i=0; $i<=$#xsort; $i++ )
    {
      $ysort[$i] = $m * $xsort[$i] + $intercept ;
    }
    $npts = $#xsort +1 ;
  }
  else
  {
  ### below is for const x case
    if ( $y1 < $y2 )
    {
      @ysort = sort { $a <=> $b; }  @yint ;
    }
    else
    {
      @ysort = sort { $b <=> $a; }  @yint ;
    }
    ### CALC CORRESPONDING X
    for ( $i=0; $i<=$#ysort; $i++ )
    {
      $xsort[$i] = $x1 ;
    }
    $npts = $#xsort +1 ;
  }

  #full2halfline-kludge  ### TREAT HALF-LINE INTERSECTION CASE AS FULL-LINE SHIFT
  #full2halfline-kludge  if ( $LHALFLINES == 1 )
  #full2halfline-kludge  { 
  #full2halfline-kludge    for ( $i=0; $i<=$#xsort; $i++ )
  #full2halfline-kludge    {
  #full2halfline-kludge      $xsort[$i] = $xsort[$i] - 0.5 ;
  #full2halfline-kludge      $ysort[$i] = $ysort[$i] - 0.5 ;
  #full2halfline-kludge    }
  #full2halfline-kludge  }

  #4testprint: print "cell_path_intersections : xsort= @xsort \n"; print "cell_path_intersections : ysort= @ysort \n"; 

  ### ELIMINATE DUPLICATE POINTS (can occur when intersection occurs at corner)
  $newmaxi = 0 ;
  for ( $i=1; $i<=$#xsort; $i++ )
  {
    if( $xsort[$i] != $xsort[$newmaxi] || $ysort[$i] != $ysort[$newmaxi] )
    {
      $newmaxi = $newmaxi +1 ;
      $xsort[$newmaxi] = $xsort[$i] ;
      $ysort[$newmaxi] = $ysort[$i] ;
    }
  }
  ### eliminate extra points
  if( $newmaxi < $#xsort ) { splice @xsort, ($newmaxi+1),$#xsort ; splice @ysort, ($newmaxi+1),$#ysort ; }
  #4testprint: print "cell_path_intersections : npts OLD=$npts NEW=$newmaxi+1 \n"; 
  $npts = $newmaxi +1 ;

  return ( $npts, @xsort, @ysort );
}
#########################################################################
sub W3FB11()
### CALC LAMBERT I,J (decimal) FROM LONG,LAT FOR GIVEN LAMBERT PARAMETERS
###  Args: $ALAT,$ELON, $ALAT1,$ELON1,$DX,$ELONV,$ALATAN
{
#
# SUBPROGRAM:  W3FB11        LAT/LON TO LAMBERT(I,J) FOR GRIB
#   PRGMMR: STACKPOLE        ORG: NMC42       DATE:88-11-28
#
# ABSTRACT: CONVERTS THE COORDINATES OF A LOCATION ON EARTH GIVEN IN
#   THE NATURAL COORDINATE SYSTEM OF LATITUDE/LONGITUDE TO A GRID
#   COORDINATE SYSTEM OVERLAID ON A LAMBERT CONFORMAL TANGENT CONE
#   PROJECTION TRUE AT A GIVEN N OR S LATITUDE. W3FB11 IS THE REVERSE
#   OF W3FB12. USES GRIB SPECIFICATION OF THE LOCATION OF THE GRID
#
# PROGRAM HISTORY LOG:
#   88-11-25  ORIGINAL AUTHOR:  STACKPOLE, W/NMC42
#
# USAGE:  CALL W3FB11 (ALAT,ELON,ALAT1,ELON1,DX,ELONV,ALATAN,XI,XJ)
#   INPUT ARGUMENT LIST:
#     ALAT     - LATITUDE IN DEGREES (NEGATIVE IN SOUTHERN HEMIS)
#     ELON     - EAST LONGITUDE IN DEGREES, REAL*4
#     ALAT1    - LATITUDE  OF LOWER LEFT POINT OF GRID (POINT (1,1))
#     ELON1    - LONGITUDE OF LOWER LEFT POINT OF GRID (POINT (1,1))
#                ALL REAL*4
#     DX       - MESH LENGTH OF GRID IN METERS AT TANGENT LATITUDE
#     ELONV    - THE ORIENTATION OF THE GRID.  I.E.,
#                THE EAST LONGITUDE VALUE OF THE VERTICAL MERIDIAN
#                WHICH IS PARALLEL TO THE Y-AXIS (OR COLUMNS OF
#                OF THE GRID) ALONG WHICH LATITUDE INCREASES AS
#                THE Y-COORDINATE INCREASES.  REAL*4
#                THIS IS ALSO THE MERIDIAN (ON THE BACK SIDE OF THE
#                TANGENT CONE) ALONG WHICH THE CUT IS MADE TO LAY
#                THE CONE FLAT.
#     ALATAN   - THE LATITUDE AT WHICH THE LAMBERT CONE IS TANGENT TO
#                (TOUCHING) THE SPHERICAL EARTH.
#                 SET NEGATIVE TO INDICATE A
#                 SOUTHERN HEMISPHERE PROJECTION.
#
#   OUTPUT ARGUMENT LIST:
#     XI       - I COORDINATE OF THE POINT SPECIFIED BY ALAT, ELON
#     XJ       - J COORDINATE OF THE POINT; BOTH REAL*4
#
#   REMARKS: FORMULAE AND NOTATION LOOSELY BASED ON HOKE, HAYES,
#     AND RENNINGER'S "MAP PROJECTIONS AND GRID SYSTEMS...", MARCH 1981
#     AFGWC/TN-79/003
#
# ATTRIBUTES:
#   LANGUAGE: IBM VS FORTRAN
#   MACHINE:  NAS
#

  my ( $ALAT, $ELON, $ALAT1, $ELON1, $DX, $ELONV, $ALATAN ) = @_;

  my ( $H );
  my     $RERTH = 6.3712E+6;
  my     $PI = 3.14159 ;
#
#        PRELIMINARY VARIABLES AND REDIFINITIONS
#
#        H = 1 FOR NORTHERN HEMISPHERE; = -1 FOR SOUTHERN
#
         if( $ALATAN>0)
           { $H = 1.; }
         else
           { $H = -1.; }
#
  my     $RADPD = $PI/180.0;
  my     $REBYDX = $RERTH/$DX;
  my     $ALATN1 = $ALATAN * $RADPD;
  my     $AN = $H * sin($ALATN1);
  my     $COSLTN = cos($ALATN1);
#
#        MAKE SURE THAT INPUT LONGITUDES DO NOT PASS THROUGH
#        THE CUT ZONE (FORBIDDEN TERRITORY) OF THE FLAT MAP
#        AS MEASURED FROM THE VERTICAL (REFERENCE) LONGITUDE.
#
  my     $ELON1L = $ELON1;
         if( ($ELON1 - $ELONV) > 180.)
         { $ELON1L = $ELON1 - 360. ;}
         if( ($ELON1 - $ELONV) < -180. )
         { $ELON1L = $ELON1 + 360.; }
#
  my     $ELONL = $ELON;
         if( ($ELON - $ELONV) > 180. )
         { $ELONL = $ELON - 360.; }
         if( ($ELON - $ELONV) < -180. )
         { $ELONL = $ELON + 360.; }
#
  my     $ELONVR = $ELONV *$RADPD;
#
#        RADIUS TO LOWER LEFT HAND (LL) CORNER
#
  my     $ALA1 =  $ALAT1 * $RADPD;
  my     $RMLL = $REBYDX * ((($COSLTN)**(1.-$AN))*(1.+$AN)**$AN) * (((cos($ALA1))/(1.+$H*sin($ALA1)))**$AN)/$AN;
#
#        USE LL POINT INFO TO LOCATE POLE POINT
#
  my     $ELO1 = $ELON1L * $RADPD;
  my     $ARG = $AN * ($ELO1-$ELONVR);
  my     $POLEI = 1. - $H * $RMLL * sin($ARG);
  my     $POLEJ = 1. + $RMLL * cos($ARG);
#
#        RADIUS TO DESIRED POINT AND THE I J TOO
#
  my     $ALA = $ALAT * $RADPD;
  my     $RM = $REBYDX * (($COSLTN**(1.-$AN))*(1.+$AN)**$AN) * (((cos($ALA))/(1.+$H*sin($ALA)))**$AN)/$AN;
#
  my     $ELO = $ELONL * $RADPD;
         $ARG = $AN*($ELO-$ELONVR);
  my     $XI = $POLEI + $H * $RM * sin($ARG);
  my     $XJ = $POLEJ - $RM * cos($ARG);
#
#        IF COORDINATE LESS THAN 1
#        COMPENSATE FOR ORIGIN AT (1,1)
#
#jack - following gives round-off error problems so eliminate
#jack-        IF(XI.LT.1.)  XI = XI - 1.;
#jack         IF(XJ.LT.1.)  XJ = XJ - 1.;
#
      return ($XI,$XJ);
}
#############################################################################
#RASP MOD - added subroutines follow
#############################################################################
### read region parameters from wrfsi.nl file
sub read_region_params ()
{
  my $datafilename = $_[0];
  ### READ RASP GRID DATA FROM NAMELIST FILE
  ### *NB* for grid params use 1-base indexs
  open ( DATAFILE, "<$datafilename" );
  @datalines = <DATAFILE>;
  for ( $iiline=0 ; $iiline<=$#datalines ; $iiline++ )
  {
    ### do not allow blank in simulation name (so number of blank-delimited fields in output line always known)
    #unused if ( $datalines[$iiline] =~ m|^ *SIMULATION_NAME * = * [\"\'] *([^\"\' ]*)[\"\' ]|i )   { $SIMULATION_NAME = $1 ; }
    if ( $datalines[$iiline] =~ m|^ *RATIO_TO_PARENT * = * (.*) *$|i )   { @RATIO_TO_PARENT = split ( / *,/, $1 ) ; unshift @RATIO_TO_PARENT, ''; }
    if ( $datalines[$iiline] =~ m|^ *DOMAIN_ORIGIN_LLI * = * (.*) *$|i ) { @DOMAIN_ORIGIN_LLI = split ( / *,/, $1 ) ; unshift @DOMAIN_ORIGIN_LLI, ''; }
    if ( $datalines[$iiline] =~ m|^ *DOMAIN_ORIGIN_LLJ * = * (.*) *$|i ) { @DOMAIN_ORIGIN_LLJ = split ( / *,/, $1 ) ; unshift @DOMAIN_ORIGIN_LLJ, ''; }
    if ( $datalines[$iiline] =~ m|^ *DOMAIN_ORIGIN_URI * = * (.*) *$|i ) { @DOMAIN_ORIGIN_URI = split ( / *,/, $1 ) ; unshift @DOMAIN_ORIGIN_URI, ''; }
    if ( $datalines[$iiline] =~ m|^ *DOMAIN_ORIGIN_URJ * = * (.*) *$|i ) { @DOMAIN_ORIGIN_URJ = split ( / *,/, $1 ) ; unshift @DOMAIN_ORIGIN_URJ, ''; }
    if ( $datalines[$iiline] =~ m|^ *MOAD_KNOWN_LAT * = * ([^, ]*).*$|i )   { $MOAD_KNOWN_LAT = $1 ; }
    if ( $datalines[$iiline] =~ m|^ *MOAD_KNOWN_LON * = * ([^, ]*).*$|i )   { $MOAD_KNOWN_LON = $1 ; }
    if ( $datalines[$iiline] =~ m|^ *MOAD_STAND_LATS * = * (.*) *$|i )   { @MOAD_STAND_LATS = split ( / *,/, $1 ) ; }
    if ( $datalines[$iiline] =~ m|^ *MOAD_STAND_LONS * = * ([^, ]*).*$|i )   { $MOAD_STAND_LONS = $1 ; }
    if ( $datalines[$iiline] =~ m|^ *MOAD_DELTA_X * = * ([^, ]*).*$|i )   { $MOAD_DELTA_X = $1 ; }
    if ( $datalines[$iiline] =~ m|^ *MOAD_DELTA_Y * = * ([^, ]*).*$|i )   { $MOAD_DELTA_Y = $1 ; }
    if ( $datalines[$iiline] =~ m|^ *MAP_PROJ_NAME * = * ([^, ]*).*$|i )   { $MAP_PROJ_NAME = $1 ; }
  }
  ### do sanity checks
  if( ! defined $MOAD_KNOWN_LAT || ! defined $MOAD_KNOWN_LON || 
      ! defined @MOAD_STAND_LATS || ! defined $MOAD_STAND_LONS || 
      ! defined  $MAP_PROJ_NAME )
    { die "*** ERROR EXIT: MISSING DATA in DATAFILE $datafilename " }
  if( ! defined $RATIO_TO_PARENT[${KGRID}] ||
      ! defined  $DOMAIN_ORIGIN_LLI[${KGRID}] || ! defined  $DOMAIN_ORIGIN_LLJ[${KGRID}] ||
      ! defined  $DOMAIN_ORIGIN_URI[${KGRID}] || ! defined  $DOMAIN_ORIGIN_URJ[${KGRID}] )
    { die "ERROR EXIT: MISSING DATA FOR GRID $KGRID in DATAFILE $datafilename "; }
  ### this program only valid for tangent lambert projection
  if( $MOAD_STAND_LATS[0] == $MOAD_STAND_LATS[1] && $MAP_PROJ_NAME =~ m|lambert|i )
    { $MOAD_STAND_LAT = $MOAD_STAND_LATS[0] ; }
  else
    { die "ERROR EXIT: PROGRAM ONLY VALID FOR CASE OF TANGENT LAMBERT PROJECTION "; }
  return;
}
#############################################################################################
sub subgridij2moadcenterij()
### converts subgrid i,j into moad i,j relative to moad center (used for lat,lon determination)
{
  my ($kgrid,$ai,$aj) = @_ ;
  my( $iigrid );
  ### COMPUTE LAMBERT I,J FOR MOAD
  my $aimoad = $ai ;
  my $ajmoad = $aj ;
  ### CONVERT NON-MOAD *MASS* SUBGRID INDEX TO MOAD *MASS* INDEX
  ### note iigrid uses kgrid indexing (i.e. param arrays use 1-based indexing)
  for ( $iigrid=$kgrid;  $iigrid>=2 ; $iigrid-- )
  {
    if( ! defined $RATIO_TO_PARENT[$iigrid] || ! defined  $DOMAIN_ORIGIN_LLI[$iigrid] || ! defined  $DOMAIN_ORIGIN_LLJ[$iigrid] )
    {
      die "*** ERROR EXIT: BAD GRID NUMBER = $kgrid ";
    }
     $aimoad = $DOMAIN_ORIGIN_LLI[$iigrid] -0.5 + ( $aimoad - 0.5 ) / $RATIO_TO_PARENT[$iigrid]  ;
     $ajmoad = $DOMAIN_ORIGIN_LLJ[$iigrid] -0.5 + ( $ajmoad - 0.5 ) / $RATIO_TO_PARENT[$iigrid]  ;
     #old=3:1only $aimoad = $DOMAIN_ORIGIN_LLI[$iigrid] + ( $aimoad - 2.0 ) / $RATIO_TO_PARENT[$iigrid]  ;
     #old=3:1only $ajmoad = $DOMAIN_ORIGIN_LLJ[$iigrid] + ( $ajmoad - 2.0 ) / $RATIO_TO_PARENT[$iigrid]  ;
     #4testprint: print "GRID $iigrid =>  RATIO_TO_PARENT= $RATIO_TO_PARENT[$iigrid] \n";
  }
  ### CALC MOAD I,J (non-integer) SHIFTED RELATIVE TO CENTER OF MOAD GRID
  my $airelative = $aimoad - 0.5*( $NXmassMOAD -1 ) ;
  my $ajrelative = $ajmoad - 0.5*( $NYmassMOAD -1 ) ;
  return  $airelative,$ajrelative ;
}
#############################################################################
sub uv2wswd_4latlon ()
{
  ### $DEG2RAD is global constant
  ### i do not understand why need test for sign of alat
  ### multiplication by CONE means that longitudes must be in range -180 to +180
  my ($u, $v, $alat,$alon) = @_ ;
  my ( $longca, $longcb, $coslong,$sinlong, $umet,$vmet, $ws, $wd );
    # below method ala wrf_user_fortran_util_0 :: compute_uvmet( u,v, uvmet, diff, alpha, longitude,latitude, cen_
    ### requires longitude -180 to 180 !
    if( $alon > 180. ) { $alon = $alon - 360.; }
    $longca = $alon - $MOAD_STAND_LONS ;
    if( $alat < 0 )
      { $longcb = - $longca * $GRID_CONE * $DEG2RAD ; }
    else
      { $longcb = $longca * $GRID_CONE * $DEG2RAD ; }
    $coslong = cos( $longcb ) ;
    $sinlong = sin( $longcb ) ;
    $umet = $v * $sinlong + $u * $coslong ;
    $vmet = $v * $coslong - $u * $sinlong ;
    $ws = sqrt ( $umet**2 + $vmet**2 ) ;
    $wd = atan2( $umet, $vmet )/$DEG2RAD + 180.0 ;
  return $ws, $wd ;
}
#############################################################################################
sub W3FB12()
### CALC LONG,LAT FOR GIVEN LAMBERT I,J (decimal)
###  Args: $XI,$XJ, $ALAT1,$ELON1,$DX,$ELONV,$ALATAN
{
# SUBPROGRAM:  W3FB12        LAMBERT(I,J) TO LAT/LON FOR GRIB
#   PRGMMR: STACKPOLE        ORG: NMC42       DATE:88-11-28
#
# ABSTRACT: CONVERTS THE COORDINATES OF A LOCATION ON EARTH GIVEN IN 
#   GRID COORDINATE SYSTEM OVERLAID ON A LAMBERT CONFORMAL TANGENT
#   CONE PROJECTION TRUE AT A GIVEN N OR S LATITUDE TO THE
#   NATURAL COORDINATE SYSTEM OF LATITUDE/LONGITUDE
#   W3FB12 IS THE REVERSE OF W3FB11.
#   USES GRIB SPECIFICATION OF THE LOCATION OF THE GRID
#
# PROGRAM HISTORY LOG
#   88-11-25  ORIGINAL AUTHOR:  STACKPOLE, W/NMC42
#
# USAGE:  CALL W3FB12(XI,XJ,ALAT1,ELON1,DX,ELONV,ALATAN,ALAT,ELON,IERR,
#                                   IERR)
#   INPUT ARGUMENT LIST:
#     XI       - I COORDINATE OF THE POINT  REAL*4
#     XJ       - J COORDINATE OF THE POINT  REAL*4
#     ALAT1    - LATITUDE  OF LOWER LEFT POINT OF GRID (POINT 1,1)
#                LATITUDE <0 FOR SOUTHERN HEMISPHERE; REAL*4
#     ELON1    - LONGITUDE OF LOWER LEFT POINT OF GRID (POINT 1,1)
#                  EAST LONGITUDE USED THROUGHOUT; REAL*4
#     DX       - MESH LENGTH OF GRID IN METERS AT TANGENT LATITUDE
#     ELONV    - THE ORIENTATION OF THE GRID.  I.E.,
#                THE EAST LONGITUDE VALUE OF THE VERTICAL MERIDIAN
#                WHICH IS PARALLEL TO THE Y-AXIS (OR COLUMNS OF
#                THE GRID) ALONG WHICH LATITUDE INCREASES AS
#                THE Y-COORDINATE INCREASES.  REAL*4
#                THIS IS ALSO THE MERIDIAN (ON THE OTHER SIDE OF THE
#                TANGENT CONE) ALONG WHICH THE CUT IS MADE TO LAY
#                THE CONE FLAT.
#     ALATAN   - THE LATITUDE AT WHICH THE LAMBERT CONE IS TANGENT TO
#                (TOUCHES OR OSCULATES) THE SPHERICAL EARTH.
#                 SET NEGATIVE TO INDICATE A
#                 SOUTHERN HEMISPHERE PROJECTION; REAL*4
#
#   OUTPUT ARGUMENT LIST
#     ALAT     - LATITUDE IN DEGREES (NEGATIVE IN SOUTHERN HEMI.)
#     ELON     - EAST LONGITUDE IN DEGREES, REAL*4
#     IERR     - .EQ. 0   IF NO PROBLEM
#                .GE. 1   IF THE REQUESTED XI,XJ POINT IS IN THE
#                         FORBIDDEN ZONE, I.E. OFF THE LAMBERT MAP
#                         IN THE OPEN SPACE WHERE THE CONE IS CUT.
#                  IF IERR.GE.1 THEN ALAT=999. AND ELON=999.
#
#   REMARKS: FORMULAE AND NOTATION LOOSELY BASED ON HOKE, HAYES,
#     AND RENNINGER'S "MAP PROJECTIONS AND GRID SYSTEMS...", MARCH 1981
#     AFGWC/TN-79/003
#
# ATTRIBUTES:
#   LANGUAGE: IBM VS FORTRAN
#   MACHINE:  NAS
#
#$$$

  my ( $XI, $XJ, $ALAT1, $ELON1, $DX, $ELONV, $ALATAN ) = @_;

#alaWRF
  my     $RERTH = 6.370E+6;
#ORIGINAL-NCEP         $RERTH = 6.3712E+6;
  my     $PI = 3.1415926 ;
#ORIGINAL-NCEP         $PI = 3.14159 ;
#        DATA  OLDRML/99999./
#
#        PRELIMINARY VARIABLES AND REDIFINITIONS
#
#        H = 1 FOR NORTHERN HEMISPHERE; = -1 FOR SOUTHERN
#
#        SAVE

  my ( $H, $ALAT, $ELON );
  my     $BETA  = 1.;
  my     $IERR = 0;

         if( $ALATAN>0 )
           { $H = 1.; }
         else
           { $H = -1.; }
#
  my     $PIBY2 = $PI / 2. ;
  my     $RADPD = $PI / 180.0 ;
  my     $DEGPRD = 1. / $RADPD ;
  my     $REBYDX = $RERTH / $DX ;
  my     $ALATN1 = $ALATAN * $RADPD ;
  my     $AN = $H * sin($ALATN1) ;
  my     $COSLTN = cos($ALATN1) ;
#
#        MAKE SURE THAT INPUT LONGITUDE DOES NOT PASS THROUGH
#        THE CUT ZONE (FORBIDDEN TERRITORY) OF THE FLAT MAP
#        AS MEASURED FROM THE VERTICAL (REFERENCE) LONGITUDE
#
  my     $ELON1L = $ELON1 ;
         if( ($ELON1-$ELONV) > +180. )
          { $ELON1L = $ELON1 - 360.; }
         if( ($ELON1-$ELONV) < (-180.) )
          {  $ELON1L = ELON1 + 360.; }
#
  my     $ELONVR = $ELONV * $RADPD;
#
#        RADIUS TO LOWER LEFT HAND (LL) CORNER
#
  my     $ALA1 =  $ALAT1 * $RADPD;
  my     $RMLL = $REBYDX * (($COSLTN**(1.-$AN))*(1.+$AN)**$AN)*(((cos($ALA1))/(1.+$H*sin($ALA1)))**$AN)/$AN;
#
#        USE RMLL TO TEST IF MAP AND GRID UNCHANGED FROM PREVIOUS
#        CALL TO THIS CODE.  THUS AVOID UNNEEDED RECOMPUTATIONS.
#
#         IF(RMLL.EQ.OLDRML) THEN
#           NEWMAP = .FALSE.
#         ELSE
#           NEWMAP = .TRUE.
#           OLDRML = RMLL
#
#          USE LL POINT INFO TO LOCATE POLE POINT
#
  my       $ELO1 = $ELON1L * $RADPD;
  my       $ARG = $AN * ($ELO1-$ELONVR);
  my       $POLEI = 1. - $H * $RMLL * sin($ARG);
  my       $POLEJ = 1. + $RMLL * cos($ARG);
#         ENDIF
#
#        RADIUS TO THE I,J POINT (IN GRID UNITS)
#              YY REVERSED SO POSITIVE IS DOWN
#
  my     $XX = $XI - $POLEI;
  my     $YY = $POLEJ - $XJ;
  my     $R2 = $XX**2 + $YY**2;
#
#        CHECK THAT THE REQUESTED I,J IS NOT IN THE FORBIDDEN ZONE
#           YY MUST BE POSITIVE UP FOR THIS TEST
#
 my      $THETA = $PI*(1.-$AN);
         $BETA = abs( atan2( $XX, -($YY) ) );
         $IERR = 0;
         if( $BETA <= $THETA ) 
           {
           $IERR = 1;
           $ALAT = 999.;
           $ELON = 999.;
#           IF(.NOT.NEWMAP)  RETURN
           }
#
#        NOW THE MAGIC FORMULAE
#
         if( $R2==0 ) 
         {
           $ALAT = $H * 90.;
           $ELON = $ELONV;
         }
         else
         {
#
#          FIRST THE LONGITUDE
#
           $ELON = $ELONV + $DEGPRD * atan2( $H*$XX, $YY )/$AN;
### needed to replace amod
           $ELON = $ELON+360. -360.*int(($ELON+360.)/360.);
#original           ELON = AMOD(ELON+360., 360.)
#
#          NOW THE LATITUDE
#          RECALCULATE THE THING ONLY IF MAP IS NEW SINCE LAST TIME
#
#           IF(NEWMAP) THEN
 my          $ANINV = 1./$AN;
 my          $ANINV2 = $ANINV/2.;
 my          $THING = (($AN/$REBYDX) ** $ANINV)/(($COSLTN**((1.-$AN)*$ANINV))*(1.+ $AN));
#           ENDIF
### needed to replace atan
           $ALAT = $H*( $PIBY2 - 2.*atan2( $THING*($R2**$ANINV2), 1. ) )*$DEGPRD;
#glendeni-systax_error!           $ALAT = -$H*($PIBY2 - 2.*atan2(($THING*($R2**$ANINV2))),1.)*$DEGPRD;
#old-error??           $ALAT = -$H*($PIBY2 - 2.*atan2(1.,($THING*($R2**$ANINV2))))*$DEGPRD;
#original           ALAT = H*( PIBY2 - 2.*ATAN( THING*(R2**ANINV2) ) )*DEGPRD
         }
#
#        FOLLOWING TO ASSURE ERROR VALUES IF FIRST TIME THRU
#         IS OFF THE MAP
#
         if( $IERR!=0 )
         {
           $ALAT = 999.;
           $ELON = 999.;
           $IERR = 2;
         }
      return ($ALAT,$ELON);
}
##################################################################################################
### GET MAX VALUE OF INPUT ARRAY/LIST
sub max {
    my($max) = shift(@_);

    foreach $temp (@_) {
        $max = $temp if $temp > $max;
    }
    return($max);
}
### GET MIN VALUE OF INPUT ARRAY/LIST
sub min {
    my($min) = shift(@_);

    foreach $temp (@_) {
        $min = $temp if $temp < $min;
    }
    return($min);
}
#############################################################################
