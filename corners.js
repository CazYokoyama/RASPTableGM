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
            new google.maps.LatLng(44.8668213, -121.7677765), // SW
            new google.maps.LatLng(49.3583221, -116.2947845)  // NE
          );
corners.Centre[1] = new google.maps.LatLng(47.1125717, -119.0312805);

// predict from 0000Z-1600PST
corners.Bounds[2] = new google.maps.LatLngBounds(
    new google.maps.LatLng(44.8668213, -121.7677765), // SW
    new google.maps.LatLng(49.3583221, -116.2947845)  // NE
);
corners.Centre[2] = new google.maps.LatLng(47.1125717, -119.0312805);
