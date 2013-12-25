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

// Willamette Valley Oregon 1Km
corners.Bounds[1] = new google.maps.LatLngBounds(
            new google.maps.LatLng(43.4626312, -124.2068787), // SW
            new google.maps.LatLng(46.1070404, -121.8491211)  // NE
          );
corners.Centre[1] = new google.maps.LatLng(44.7848358, -123.0279999);

// predict from 0000Z-1600PST
corners.Bounds[2] = new google.maps.LatLngBounds(
    new google.maps.LatLng(43.4626312, -124.2068787), // SW
    new google.maps.LatLng(46.1070404, -121.8491211)  // NE
);
corners.Centre[2] = new google.maps.LatLng(44.7848358, -123.0279999);
