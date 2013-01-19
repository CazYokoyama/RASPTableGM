#! /usr/bin/perl  -w

#### convert ncgm file to png and send to browser  
### query string args: file= ctransarg= convertarg=
### e.g. www.drjack.info/cgi-bin/display_ncgm.cgi?ctransarg=-res%20800x800&file=/tmp/plot.ncgm

###############################################################################
### FOR VISUAL DEBUGGER:  perl -d:ptkdb example.pl
### FOR DEBUG MODE: run with -d flag  (but not for neptune)
### In debug mode, set package name + local variables so X,V don't show "main" variables, ie:
# package Main; local ($a,$b,...);
### To enable verbose diagnostics (but not for CRAY):
#   use diagnostics;
### To restrict unsafe constructs (vars,refs,subs)
###    vars requires variables to be declared with "my" or fully qualified or imported
###    refs generates error if symbolic references uses instead of hard refs
###    subs requires subroutines to be predeclared
#    use strict;
### To provide aliases for buit-in punctuation variables (p403)
    use English;
### for cgi use taint checking option -T
### for non-buffered ouput:
     $|=1; #(autoflush HANDLE EXPR)
###############################################################################

use CGI::Carp qw(fatalsToBrowser);

 ### PARSE CGI INPUT
use CGI qw(:standard);
$query = new CGI;
$file = $query->param('file');
$ctransarg = $query->param('ctransarg');
$convertarg = $query->param('convertarg');
if( ! defined $ctransarg ) { $ctransarg = ''; }
if( ! defined $convertarg ) { $convertarg = ''; }
# test for file existence
if( ! defined $file || ! -f $file )
  { print "Content-Type: text/plain\n\n File not found"; }

#PAULS $NCARG_ROOT = '/usr/local/ncarg' ;
$NCARG_ROOT = '/home/rasp/UTIL/NCARG' ;
#PAULS $CONVERTEXE = '/usr/local/bin/convert' ;
$CONVERTEXE = '/usr/bin/convert' ;
$ENV{'NCARG_ROOT'} = $NCARG_ROOT ;

$pngout=`$NCARG_ROOT/bin/ctrans $ctransarg -d sun $file | $CONVERTEXE $convertarg - png:-` ;

if( defined $pngout && $pngout ne "" )
{
    print "Content-Type: image/png\n\n";
    print $pngout ;
}
else
  { print "Content-Type: text/plain\n\n Conversion failure"; }

#PAULS
{ `/bin/rm -f $file` }
