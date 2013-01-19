############################################################
### SITE DEPENDENT VARIABLES USED BY extract.blipspot.PL ###
###   (use separate file to avoid tar update overwrite)  ###
############################################################

### SET SITE DEPENDENT DEFAULT PARAMETERS
if( $#paramdolist == -1 ) { 
  @paramdolist = ( 'wstar','experimental1','hwcrit','hbl','dbl','dwcrit','hglider','sfcsunpct','sfctemp','sfcdewpt','sfcwind0dir','sfcwind0spd','sfcwinddir','sfcwindspd','blwindspd','blwinddir','mslpress','wblmaxmin','zsfclcldif','rain1') ;
}

### SET SITE DEPENDENT REGION DEFAULT TIMES
if( $#timedolist == -1 ) { 
  if ( $REGION eq "UK+0" || $REGION eq 'UK12' || $REGION eq 'UK+1' || $REGION eq 'UK+2' || $REGION eq 'UK+3' || $REGION eq 'UK+4' || $REGION eq 'UK+5' || $REGION eq 'UK+6' ) {
    if( $LARCHIVE == 0 ) {
      # GMT
      @timedolistSTD = ('0600lst','0630lst','0700lst','0730lst','0800lst','0830lst','0900lst','0930lst','1000lst','1030lst','1100lst','1130lst','1200lst','1230lst','1300lst','1330lst','1400lst','1430lst','1500lst','1530lst','1600lst','1630lst','1700lst','1730lst','1800lst');
      # BST
      @timedolistDST = ('0700lst','0730lst','0800lst','0830lst','0900lst','0930lst','1000lst','1030lst','1100lst','1130lst','1200lst','1230lst','1300lst','1330lst','1400lst','1430lst','1500lst','1530lst','1600lst','1630lst','1700lst','1730lst','1800lst','1830lst','1900lst');
    }
    else {
      # GMT
      @timedolistSTD = ('0600lst','0630lst','0700lst','0730lst','0800lst','0830lst','0900lst','0930lst','1000lst','1030lst','1100lst','1130lst','1200lst','1230lst','1300lst','1330lst','1400lst','1430lst','1500lst','1530lst','1600lst','1630lst','1700lst','1730lst','1800lst');
      # BST
      @timedolistDST = ('0700lst','0730lst','0800lst','0830lst','0900lst','0930lst','1000lst','1030lst','1100lst','1130lst','1200lst','1230lst','1300lst','1330lst','1400lst','1430lst','1500lst','1530lst','1600lst','1630lst','1700lst','1730lst','1800lst','1830lst','1900lst');
    }
  }
  else { die "$programname EXIT ERROR: no default times for REGION = $REGION"; }
}

###### SET SITE DEPENDENT DATA DIRECTORIES
### set data directory
$hostname = `hostname`; chomp( $hostname );
if ( $hostname eq 'rasp' && $LARCHIVE==0) {
  $DATADIR = "/var/www/html/${REGION}/FCST";
}
elsif ( $hostname eq 'rasp' && $LARCHIVE==1) {
  $DATADIR = "/var/www/html/ARCHIVE/${REGION}/";
}
elsif ( $hostname eq 'rasp.inn.leedsmet.ac.uk' && $LARCHIVE==0) {
  $DATADIR = "/var/www/html/${REGION}/FCST";
}
elsif ( $hostname eq 'rasp.inn.leedsmet.ac.uk' && $LARCHIVE==1) {
  $DATADIR = "/var/www/html/ARCHIVE/${REGION}/";
}
else { die "$programname EXIT ERROR: unknown hostname = $hostname"; }
