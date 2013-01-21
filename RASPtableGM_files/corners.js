/****************************************
 *    corners.js                        *
 *                                      *
 *    Corner info for Google Maps       *
 ****************************************/ 

var corners = new Array();
var tmp;

corners["Bounds"]
corners["Centre"]

corners.Bounds = new Array();
corners.Centre = new Array();

// UK 2km (Today)
corners.Bounds[2] = new google.maps.LatLngBounds(
    new google.maps.LatLng(43.4626312, -124.2068787), // SW
    new google.maps.LatLng(46.1070404, -121.8491211)  // NE
);
corners.Centre[2] = new google.maps.LatLng(44.7848358, -123.0279999);

// UK 4km (Tomorrow)
corners.Bounds[4] = new google.maps.LatLngBounds(
            new google.maps.LatLng( 49.3967667 ,  -10.9656889 ), // SW
            new google.maps.LatLng( 59.6024306 ,  2.7377500 )  // NE
          );
corners.Centre[4] = new google.maps.LatLng( 54.4995986 ,  -4.1139694 );


// UK 5km (Not currently used)
corners.Bounds[5] = new google.maps.LatLngBounds(
            new google.maps.LatLng( 49.4039417 ,  -10.9529528 ), // SW
            new google.maps.LatLng( 59.5960889 ,  2.7322389 )  // NE
          );
corners.Centre[5] = new google.maps.LatLng( 54.5000153 ,  -4.1103569 );


// UK 12km (Rest of week)
corners.Bounds[12] = new google.maps.LatLngBounds(
            new google.maps.LatLng( 49.0379750 ,  -11.6808000 ), // SW
            new google.maps.LatLng( 59.9565806 ,  3.2745306 )  // NE
          );
corners.Centre[12] = new google.maps.LatLng( 54.4972778 ,  -4.2031347 );
