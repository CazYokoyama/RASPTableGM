############################################
##########  SET SITE DIRECTORIES  ##########
############################################
sub site_directories ()
{
	### SET SITE-DEPENDENT BASEDIR FOR APACHE SERVER RUN
	###  (USED AS GLOBAL VARIABLES)
	if ( ! defined $ENV{'HOME'} ) {
		$ENV{'HOME'} = '' ;
	}
	else {
		### UNTAINT ENVIRON VARIABLE
		if ( $ENV{'HOME'} =~ m|^([A-Za-z0-9/][A-Za-z0-9_.:/-]*)$| ) {  # filename chars only
			$ENV{'HOME'} = $1 ;
		}
	}
	$HOME = $ENV{'HOME'}; 
	#PAULS $BASEDIR = "$ENV{'HOME'}/."; 
	$BASEDIR = ""; 
}

#############################################
##########  SET REGION PARAMETERS  ##########
#############################################
sub region_params ()
{
	my ($REGION) = @_;
	my $routinename = 'region_params' ;
	my ( $localtime_id, $localtime_adj ); 

	if($REGION eq 'UK+0' || $REGION eq 'UK12' || $REGION eq 'UK+1' || $REGION eq 'UK+2' || $REGION eq 'UK+3' || $REGION eq 'UK+4' || $REGION eq 'UK+5' || $REGION eq 'UK+6') {
		$localtime_id = 'GMT' ;
		$localtime_adj = 0 ;
	}

	else { die "*** $routinename ERROR EXIT:  unknown region = $REGION"; }

	return ( $localtime_id, $localtime_adj ); 
}

###########################################
##########  SET GRID PARAMETERS  ##########
###########################################
sub grid_params ()
{
	my ($REGION,$GRID) = @_;
	my $routinename = 'grid_params' ;
	my ( $grid_imin,$grid_imax, $grid_jmin,$grid_jmax ) ;

	$grid_imin = 1 ;
	$grid_jmin = 1 ; 

	### "$grid_imax" VALUES OBTAINED BY SUBTRACTING 1 FROM "e_we" VALUES IN $BASEDIR/WRF/WRFV2/RASP/REGIONXYZ/namelist.template
	### "$grid_jmax" VALUES OBTAINED BY SUBTRACTING 1 FROM "e_sn" VALUES IN $BASEDIR/WRF/WRFV2/RASP/REGIONXYZ/namelist.template

	### *** N*B *** DATAFILE GRID INDEX MAX IS ONE LESS THAN THAT OF WRF INIT FILE !!!

	if( $REGION eq 'UK+0' || $REGION eq 'UK12' || $REGION eq 'UK+1' || $REGION eq 'UK+2' || $REGION eq 'UK+3' || $REGION eq 'UK+4' || $REGION eq 'UK+5' || $REGION eq 'UK+6' )  {
		if( $GRID eq 'd1' || $GRID eq '1' ) {
			### SET GRID SIZE
			$grid_imax = 27 ;
			$grid_jmax = 38 ;
		}
		elsif( $GRID eq 'd2' || $GRID eq 'w1' || $GRID eq '2' ) {
			### SET GRID SIZE
			# UK4  $grid_imax = 153 ;
			# UK4  $grid_jmax = 252 ;
			# UK5  $grid_imax = 119 ;
			# UK5  $grid_jmax = 196 ;
			# UK12 $grid_imax = 57 ;
			# UK12 $grid_jmax = 90 ;
			$mapdatafilename = "/var/www/html/$REGION/mapdata.txt"; 
			if ($mapdatafilename =~ /^([ &:#-\@\w.]+)$/) {
				$mapdatafilename = $1; #data is now untainted
			}
			else {
				print "bad data\n";
			}
			open(MAPPARAMS, "<$mapdatafilename") or die ("**** ERROR EXIT - open failed for $mapdatafilename");
			@datalines = <MAPPARAMS>;
			for($iiline = 0; $iiline <= $#datalines; $iiline++) {
				 # if ( $datalines[$iiline] =~ m|^ *MAPWIDTH * = * [\"\'] *([^\"\']*)[\"\' ]|i )     { $MAPWIDTH = $1 ; }
				 # if ( $datalines[$iiline] =~ m|^ *MAPHEIGHT * = * [\"\'] *([^\"\']*)[\"\' ]|i )    { $MAPHEIGHT = $1 ; }
				 # if ( $datalines[$iiline] =~ m|^ *MAPORIGINX * = * [\"\'] *([^\"\']*)[\"\' ]|i )   { $MAPORIGINX = $1 ; }
				 # if ( $datalines[$iiline] =~ m|^ *MAPORIGINY * = * [\"\'] *([^\"\']*)[\"\' ]|i )   { $MAPORIGINY = $1 ; }
				 if ( $datalines[$iiline] =~ m|^ *GRIDIMAX * = * (.*) *$|i )     { $GRIDIMAX = $1 ; }
				 if ( $datalines[$iiline] =~ m|^ *GRIDJMAX * = * (.*) *$|i )     { $GRIDJMAX = $1 ; }
			}
			$grid_imax = $GRIDIMAX ;
			$grid_jmax = $GRIDJMAX ;
			`echo "$grid_imax $grid_jmax " >> /var/www/cgi-bin/LOG/get_params.txt` ;
		}
		elsif( $GRID eq 'w2' || $GRID eq '3' ) {
			### SET GRID SIZE
			$grid_imax = $GRIDIMAX ;
			$grid_jmax = $GRIDJMAX ;
		}
		else { die "*** $routinename ERROR EXIT:  $REGION unknown grid = $GRID"; }
	}

	else { die "*** $routinename ERROR EXIT:  unknown region = $REGION"; }

	return ( $grid_imin,$grid_imax, $grid_jmin,$grid_jmax ) ;

}

############################################
##########  SET IMAGE PARAMETERS  ##########
############################################
sub image_params ()
{
	my ($REGION,$GRID) = @_;
	my $routinename = 'image_params' ;
	my ( $image_mapwidth,$image_mapheight, $image_maporiginx, $image_maporiginy );

	### GRID 2 VALUES OBTAINED BY FINDING LINES ala "VIEWPORT: 0.602933x0.82@0.198534,0.89" in $BASEDIR/WRF/NCL/rasp.ncl.out.REGIONXYZ.02
	### GRID 3 VALUES OBTAINED BY FINDING LINES ala "VIEWPORT: 0.602933x0.82@0.198534,0.89" in $BASEDIR/WRF/NCL/rasp.ncl.out.REGIONXYZ-WINDOW.02
	###    where the VIEWPORT values represent:  $image_mapwidth x $image_mapheight @ $image_maporiginx , $image_maporiginy

	if( $REGION eq 'UK+0' || $REGION eq 'UK12' || $REGION eq 'UK+1' || $REGION eq 'UK+2' || $REGION eq 'UK+3' || $REGION eq 'UK+4' || $REGION eq 'UK+5' || $REGION eq 'UK+6' )  {
		if( $GRID eq 'd1' || $GRID eq '1' ) {
			die "$routinename - no data for $REGION  $GRID ";
		}
		elsif( $GRID eq 'd2' || $GRID eq 'w1' || $GRID eq '2' ) {
			### SET IMAGE VIEWPORT SIZE, ORIGIN
			### here "map" is same as "viewport", with values between 0.0 and 1.0
			# UK4  $image_mapwidth = 0.496574 ;
			# UK5  $image_mapwidth = 0.496206 ;
			# UK12 $image_mapwidth = 0.515955 ;
			# $image_mapheight = 0.82 ;
			# UK4  $image_maporiginx = 0.251713 ;
			# UK5  $image_maporiginx = 0.251897 ;
			# UK12 $image_maporiginx = 0.242022 ;
			# $image_maporiginy = 0.89 ;
			#### NOW FROM FILE
			$mapdatafilename = "/var/www/html/$REGION/mapdata.txt"; 
			if ($mapdatafilename =~ /^([ &:#-\@\w.]+)$/) {
				   $mapdatafilename = $1; #data is now untainted
			}
			else {
				print "bad data\n";
			}
			open(MAPPARAMS, "<$mapdatafilename") or die ("**** ERROR EXIT - open failed for $mapdatafilename");
			@datalines = <MAPPARAMS>;
			for($iiline = 0; $iiline <= $#datalines; $iiline++) {
				if ( $datalines[$iiline] =~ m|^ *MAPWIDTH * = * (.*) *$|i )     { $MAPWIDTH = $1 ; }
				if ( $datalines[$iiline] =~ m|^ *MAPHEIGHT * = * (.*) *$|i )    { $MAPHEIGHT = $1 ; }
				if ( $datalines[$iiline] =~ m|^ *MAPORIGINX * = * (.*) *$|i )   { $MAPORIGINX = $1 ; }
				if ( $datalines[$iiline] =~ m|^ *MAPORIGINY * = * (.*) *$|i )   { $MAPORIGINY = $1 ; }
				# if ( $datalines[$iiline] =~ m|^ *GRIDIMAX * = * (.*) *$|i )     { $GRIDIMAX = $1 ; }
				# if ( $datalines[$iiline] =~ m|^ *GRIDJMAX * = * (.*) *$|i )     { $GRIDJMAX = $1 ; }
			}
			$image_mapwidth = $MAPWIDTH ;
			$image_mapheight = $MAPHEIGHT ;
			$image_maporiginx = $MAPORIGINX ;
			$image_maporiginy = $MAPORIGINY ;
			###TEST `echo "$image_mapwidth $image_mapheight $image_maporiginx $image_maporiginy" >> /var/www/cgi-bin/LOG/get_params.txt` ;
			##PAULS
			close MAPPARAMS ;
		}
		elsif( $GRID eq 'w2' || $GRID eq '3' ) {
			die "$routinename - no data for $REGION  $GRID ";
		}
		else { die "*** $routinename ERROR EXIT:  $REGION unknown grid = $GRID"; }
	}

	else { die "*** $routinename ERROR EXIT:  unknown region = $REGION"; }

	return ( $image_mapwidth,$image_mapheight, $image_maporiginx, $image_maporiginy );

}

### FILE MUST END WITH FOLLOWING LINE:
1;
