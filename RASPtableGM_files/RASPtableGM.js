/**********************
 *	RASPtableGM.js  *
 **********************/

/* 
 * Global Variables
 */

var oldDayIndex;
var Loaded = [];
var Pics = [];
var theTitles = [];
var theScales = [];
var theSideScales = [];

var ffversion;

var fullSet;

var oldParam;
var oldDay;
var times;

var	map;
var overlay = null;
var markerArray = [];
var infoArray = [];
var taskMarkerArray = [];
var airspaceArray = [];
var ASstring;
var Event;

var paramWindow;
var origTblHt;
var imgHt;
var imgWid;
var	topHeight;

var map;
var resolution;
var opacity = 50;	// default opacity
var centre;
var zoom = 6;		// default zoom
var ctrFlag = false;
var OPACITY_MAX_PIXELS = 57; // Width of opacity control image
var opacity_control = "N";
var opacityCtrlKnob;

var waslong = "N";	// longclick

 /***********************
 * initIt()             *
 *                      *
 * Initialise Variables *
 * Build Menus, etc     *
 ***********************/
function initIt()
{
	document.body.style.overflow = "hidden"; // Disable Scrolling
	window.onresize = function(){setSize();}

	oldDayIndex = document.getElementById("Day").options.selectedIndex;
	oldParam = document.getElementById("Param").options.value;
	oldDay = document.getElementById("Day").value;

	paramWindow = null ;
	wasSounding = false;

	/* There is a bug in FF 1.5 & 2 with DOMMouseScroll - look for ffversion below */
	if (/Firefox[\/\s](\d+\.\d+)/.test(navigator.userAgent)){ //test for Firefox/x.x or Firefox x.x (ignoring remaining digits);
		ffversion=new Number(RegExp.$1) // capture x.x portion and store as a number
	}

	/**********************/
	/* Build the Day Menu */
	/**********************/

	var Now = new Date().getTime();	// Time now - in milliSec(!)
	var mS_Day = 24 * 60 * 60 * 1000;	// mS in a day
	var T = new Date();			// Instantiate a Date object
	var dayName   = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
	var monthName = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

	var day = document.getElementById("Day");	// save typing

	T.setTime(Now);					// Today
	day.options[0] = new Option(dayName[T.getDay()] + ' ' + T.getDate() + ' ' + monthName[T.getMonth()] + " - Today", dayName[T.getDay()]);

	/***********************/
	/* Set Default Options */
	/***********************/

	// Set Short Param List
	fullSet = false;
	for(var i = 0; i < GMparamListLite.length; i++) {
		document.getElementById("Param").options[i] = new Option(GMparamListLite[i][2], GMparamListLite[i][1]);
		document.getElementById("Param").options[i].className = GMparamListLite[i][0];
	}

	// Install Handlers
	document.getElementById("Param").onchange        = doChange;
	document.getElementById("Day").onchange          = doChange;
	document.getElementById("Time").onchange         = doChange;
	document.getElementById("archiveDay").onchange   = doChange;
	document.getElementById("archiveMonth").onchange = doChange;
	document.getElementById("archiveYear").onchange  = doChange;
	document.getElementById("paramSet").onmousedown  = switchParamList;
	document.getElementById("statusButton").onclick  = getStatus;


	/* Install Time options and adjust Table times for DST
		 Assume that Standard Time is in force on Jan 1 2012
		 And Daylight Saving Time in "the summer"
		 May be incorrect in southern hemisphere
		 See also setTimes()
	 */
	dateNow = new Date();
	dateJan = new Date(2012, 0, 1)
	if(dateNow.getTimezoneOffset() == dateJan.getTimezoneOffset())
		times = tzArray["PST"];
	else
		times = tzArray["PDT"];

	for(var i = 0; i < times.length; i++) {
		document.getElementById("Time").options[i] = new Option(times[i], times[i]);
		if(times[i] == "1000")
			document.getElementById("Time").options[i].selected = true;
	}

	document.getElementById("Day").options[0].selected    = true;				// Today
	document.getElementById("Param").options[1].selected  = true;				// wstar
	document.getElementById("popup").info[0].checked      = true;				// "Value" in infoWindow (not "Day" or "SkewT")
	document.getElementById("desc").innerHTML             = GMparamListLite[document.getElementById("Param").selectedIndex][3] ;

	/* Sort out Archive year(s), at least, to handle 6 months */
	T.setTime(Now - 182 * mS_Day);
	document.getElementById("archiveYear").options[1] = new Option(T.getFullYear(), T.getFullYear());
	T.setTime(Now);
	if(T.getFullYear() != document.getElementById("archiveYear").options[1].value){
		document.getElementById("archiveYear").options[2] = new Option(T.getFullYear(), T.getFullYear());
	}

	for(i = 0; i < document.getElementById("Time").options.length; i++){
		Pics[i]          = new Image(); // null;
		theScales[i]     = new Image();
		theSideScales[i] = new Image();
		theTitles[i]     = new Image();
		Loaded[i]        = false;
	}

	whichBrowser();	// Determine punter's Browser

	resolution = getResolution();
	centre = corners.Centre[resolution];

	// Build the basic layout
	titleObj = document.getElementById("theTitle");

	map = newMap();

	new LongClick(map, 3000);	// longclick

	// map.fitBounds(Bnds);	// This seems to zoom out rather too much!

	scaleObj = document.getElementById("theScale");
	sideScaleObj = document.getElementById("theSideScale");
	setSize();

	// Install handlers for the map
	google.maps.event.addListener(map, 'rightclick',   function(event) { newclick(event);             });	// R-Click and longpress
	google.maps.event.addListener(map, 'longpress',    function(event) { newclick(event);             });	// do the same thing
	google.maps.event.addListener(map, 'click',        function(event) { oneclick(event);             });
	google.maps.event.addListener(map, 'dragend',      function(event) { constrainMap(event);         });
	google.maps.event.addListener(map, 'zoom_changed', function(event) { constrainMap(event);         });

	// Install airspaces
	var airspaceOpts = {
			// map:  map,	// Don't specify map yet - done when AS is switched on
			preserveViewport: true
	};

	url = location.href;
	head = url.slice(0, url.lastIndexOf('/'))
	var airspacetype = document.getElementById("airspace");
	for(i = 0; i < airspacetype.length; i++){
		airspacetype[i].checked = false;	// Clear Airspace checkboxes
		ASstring = head + "/class_" + airspacetype[i].value + ".kmz" ;
		airspaceArray[i] = new google.maps.KmlLayer(ASstring, airspaceOpts);
	}

	// Save the original Selector Table Height
	origTblHt = document.getElementById("selectors").offsetHeight;

	/*****************************************
	 * Process URL tail and set menu options *
	 *****************************************/
	if( location.href.split("?")[1]){ // Any args?
		args=location.href.split("?")[1].split("&");

		for(i = 0; i < args.length; i++){
			prams = args[i].split("=");
			if(prams[0] == "param"){
				for(j = 0; j < document.getElementById("Param").options.length; j++){
					if(document.getElementById("Param").options[j].value == prams[1]){
						document.getElementById("Param").options[j].selected = true;
						break;
					}
				}
				if(j == document.getElementById("Param").options.length){
					switchParamList();
					for(j = 0; j < document.getElementById("Param").options.length; j++){
						if(document.getElementById("Param").options[j].value == prams[1]){
							document.getElementById("Param").options[j].selected = true;
							break;
						}
					}
					if(j == document.getElementById("Param").options.length){
						switchParamList();	// Put back if not found
					}
				}
			}
			if(prams[0] == "time"){
				for(j = 0; j < document.getElementById("Time").options.length; j++){
					if(document.getElementById("Time").options[j].value == prams[1])
						document.getElementById("Time").options[j].selected = true;
				}
			}
				
			if(prams[0] == "date"){
				var dateNow = new Date();
				dateNow.setHours(0, 0, 0, 0);
				// Build requested date
				var newDate = new Date(prams[1].substr(0,4), prams[1].substr(4,2) - 1, prams[1].substr(6,2), 0, 0, 0, 0);
				if(newDate >= dateNow){
					// Set forecast date Menu Option
					for(j = 1; j < 7; j++){
						dateNow.setDate(dateNow.getDate() + 1);
						// alert("dateNow = " + dateNow + "\nnewDate = " + newDate);
						if(  newDate.getFullYear() == dateNow.getFullYear()
							&& newDate.getMonth() == dateNow.getMonth()
							&& newDate.getDate() == dateNow.getDate()
						){
							day.options[j+1].selected = true;	// Have to add 1 because of 12Km for Today!!!
						}
					}
					dateNow.setDate(dateNow.getDate());
					if(newDate > dateNow)
						alert("No forecast for " + newDate.toDateString() + " - Too far ahead!");
					archiveMode = 0;
				}
				else{
					// Set Archive Date (inc Today)
					for(j = 0; j < document.getElementById("archiveYear").options.length; j++){
						if(document.getElementById("archiveYear").options[j].value == prams[1].substr(0,4))
							document.getElementById("archiveYear").options[j].selected = true;
					}
					for(j = 0; j < document.getElementById("archiveMonth").options.length; j++){
						if(document.getElementById("archiveMonth").options[j].value == prams[1].substr(4,2))
							document.getElementById("archiveMonth").options[j].selected = true;
					}
					for(j = 0; j < document.getElementById("archiveDay").options.length; j++){
						if(document.getElementById("archiveDay").options[j].value == prams[1].substr(6,2))
							document.getElementById("archiveDay").options[j].selected = true;
					}
					archiveMode = 1;
				}
			}
			if(prams[0] == "zoom"){
				zoom = parseInt(prams[1]);
			}
			if(prams[0] == "centre"){
				latlon = prams[1].split(',');
				lat = latlon[0];
				lon = latlon[1];
				centre = new google.maps.LatLng(lat, lon);
			}
		}
		doChange(null);
	}
}

/****************************************
 *      END OF INITIALISATION STUFF     *
 *      Start of functions              *
 ****************************************/

function constrainMap(E)
{
	var VPbounds;

	while(!(VPbounds = map.getBounds()))
		; // Hmmm! Busy wait?
	
	zoom = map.getZoom();	  // Register new zoom & centre values for Page URL
	centre = map.getCenter();

	var URL = document.getElementById("Url").innerHTML;
	URL = URL.replace(/centre=-*\d+\.\d+,-*\d+\.\d+/, "centre=" + centre.toUrlValue() );
	URL = URL.replace(/zoom=\d+/, "zoom=" + zoom);
	document.getElementById("Url").innerHTML = URL;

        if( !VPbounds.intersects(corners.Bounds[getResolution()])){
		if(confirm("Map Outside ViewPort\nReCentre?")){
			map.setCenter(corners.Centre[getResolution()]);
			centre = map.getCenter();
		}
	}

	/*
                alert("Map Outside ViewPort");	// alert() will stop further dragging!
		                                // zoom is limited anyway

	var SW = corners.Bounds[getResolution()].getSouthWest();
	var NE = corners.Bounds[getResolution()].getSouthWest();
	var NW = new google.maps.LatLng(NE.lat(), SW.lng());
	var SE = new google.maps.LatLng(SW.lat(), NE.lng());

	if(    !VPbounds.contains(SW)
	    && !VPbounds.contains(NW)
	    && !VPbounds.contains(NE)
	    && !VPbounds.contains(SE)
	)
	if(corners.Bounds[getResolution()].getSoutWest().lng() > VPbounds.getNorthEast().lng())
		alert("Move map west");
	if(corners.Bounds[getResolution()].getNorthEast().lng() > VPbounds.getSoutWest().lng())
		alert("Move map east");
	if(corners.Bounds[getResolution()].getNorthEast().lat() > VPbounds.getSoutWest().lat())
		alert("Move map north");
	if(corners.Bounds[getResolution()].getSoutWest().lat() > VPbounds.getNorthEast().lat())
		alert("Move map south");
	*/
}


function newMap()
{
	var mapOptions = {
		zoom:               zoom,
		center:             corners.Centre[getResolution()],
		mapTypeId:          google.maps.MapTypeId.ROADMAP,
		scrollwheel:	    false,
		draggableCursor:    "crosshair",
		streetViewControl:  false,
		// overviewMapControl:  true,
		minZoom:            6,
		maxZoom:            12
	};

	return( new google.maps.Map(document.getElementById("zoomBox"), mapOptions));
}
	

var TParray = ['LAS','LIN','SUT', 'TAL', 'LAS']; // Any old default Task!
var taskCoords = [];
var taskList = [];
var taskLine = null;

// Add or change a Task
function addTask()
{
	var path;
		
	// Remove the Task Lines, if present
	if(taskLine){
		path = taskLine.getPath();
		for(i = 0; i < path.length; i++){
			path.removeAt(path.getAt(i));
		}
		taskList.length = 0;
		taskLine.setMap(null);
		taskLine = null;
	
		// Remove the Task Markers
		if(taskMarkerArray){
			for(i = 0; i < taskMarkerArray.length; i++){
				taskMarkerArray[i].setMap(null);
				taskMarkerArray[i] = null;
			}
			taskMarkerArray.length = 0;
		}
	}

	// Install the new Task
	if(TParray.length == 0){	//Nothing to do
		document.getElementById("trkavgpopup").disabled = true;
		return;
	}

	for(var i = 0; i < TParray.length; i++){
		var j = tpn.indexOf(TParray[i])
		if(latlo[j]){
			lat = latlo[j].split(',')[0];
			lon = latlo[j].split(',')[1];
			taskList.push( new google.maps.LatLng(lat, lon));
		}
	}
	drawTask();

	// Enable the TrackAvg button
	document.getElementById("trkavgpopup").disabled = false;
}


function drawTask()
{
	if(taskList && taskList.length > 0 && taskLine){	// Remove the old Task Lines
		taskLine.setMap(null);
		taskLine = null;
	}

	var taskLineOpts = {
	                     map:   map,
	                     path:  taskList,
	                     zindex:       1000000,
	                     strokeWeight:	3,
	                     strokeColor:  "#cc00cc"
	                     };		

	taskLine = new google.maps.Polyline(taskLineOpts);
	taskLine.setMap(map);

	// NOT a good idea! google.maps.event.addListener(taskLine, 'click', function(){ TrackAvg(); });

	var N = -90, S = 90, E = -180, W = 180;

	if(taskList.length > 0){
		for(i = 0; i < taskList.length; i++){
			if( taskList[i].lat() > N ) N = taskList[i].lat();
			if( taskList[i].lat() < S ) S = taskList[i].lat();
			if( taskList[i].lng() > E ) E = taskList[i].lng();
			if( taskList[i].lng() < W ) W = taskList[i].lng();
		}
		var taskBounds = new google.maps.LatLngBounds(new google.maps.LatLng(S, W), new google.maps.LatLng(N, E));

		map.fitBounds(taskBounds);

		addTaskMarkers();
	}
}



/* Install Soundings Markers */
function addSndMarkers()
{
	// Install the markers - but only if needed
	if(markerArray && markerArray[1]){	// No Sounding0
		return;
	}
	var siz    = 20;
	var anchor = siz / 2; 
	var sndImg = new google.maps.MarkerImage(
	                   "sndmkr.png",                   // url
	                   new google.maps.Size(siz,siz),  // size
	                   new google.maps.Point(0,0),   // origin
	                   new google.maps.Point(anchor,anchor), // anchor
	                   new google.maps.Size(siz,siz)   // scaledSize
	                 );

	for(i = 1; i < soundings.LOC.length; i++ ){	// No Sounding0 !!
		var marker = new google.maps.Marker({
		                   position:  soundings.LOC[i],
		                   title:     soundings.NAM[i],
		                   icon:      sndImg,
		                   optimized: false,
		                   flat:      true,
		                   map:       map,
		                   content:   i
		             });
		addSoundingLink(marker, i);	// For unexplained reasons, this must be a separate function!
		markerArray.push(marker);
	}
}


function addSoundingLink(marker, n)
{
	google.maps.event.addListener(
		marker,
		'click',
		function(){
			ctrFlag = true;
			centre = map.getCenter();
			var sndURL = '<img src="' + Server + getBasedir() + '/';
			if(archiveMode){
				sndURL += document.getElementById("archiveYear").value + '/'
							 + document.getElementById("archiveYear").value
							 + document.getElementById("archiveMonth").value
							 + document.getElementById("archiveDay").value
							 + '/sounding' + n + '.curr.'
							 + document.getElementById("Time").value 
							 + 'lst.d2.png" height=800 width=800>' ;
							 // + 'lst.d2.png" height=400 width=400>' ;
			}
			else {
				sndURL += 'FCST/sounding' + n + '.curr.'
				       + document.getElementById("Time").value 
				       + 'lst.d2.png" height=800 width=800>' ;
				       // + 'lst.d2.png" height=400 width=400>' ;
			}
			var infowindow = new google.maps.InfoWindow( { content: sndURL });
			infoArray.push(infowindow);
			infowindow.open(map, marker);
		}
	);
}

/* Install Task Markers */
function addTaskMarkers()
{
	// If No Task, remove any markers
	for(i = 0; i < taskMarkerArray.length; i++){
		taskMarkerArray[i].setMap(null);
		taskMarkerArray[i] = null;
	}
	taskMarkerArray.length = 0;

	if( ! taskList || taskList.length ==  0){
		return;	// Nothing to do
	}

	// var zoom = map.getZoom();
	var siz    = 20;
	var anchor = siz / 2; 
	var tpImg = new google.maps.MarkerImage(
				"TnPt.png",                           // url
				new google.maps.Size(siz,siz),        // size
				new google.maps.Point(0,0),           // origin
				new google.maps.Point(anchor,anchor), // anchor
				new google.maps.Size(siz,siz)         // scaledSize
			);

	var	dist = 0, arr = [] ;

	for(p = 0; p < TParray.length; p++ ){
		if(p > 0 && p != TParray.length){
			arr = taskList.slice(0, p+1);
		}
		dist = google.maps.geometry.spherical.computeLength( arr ) / 1000 ;	// Convert to Km

		marker = new google.maps.Marker({
				position: taskList[p],
				title:    "TP" + p + " - " + TParray[p] + " - " + dist.toFixed(1) + " km",
				icon:     tpImg,
				flat:     true,
				optimized: false,
				map:      map
			});
		// google.maps.event.addListener(marker, 'click', function(){ TPinfo(); });
		taskMarkerArray.push(marker);
	}
}

function TPinfo()
{
	/*
	 * PlaceHolder for now
	 * Need to find a way to identify which TP was clicked
	 */
	var desc;

	for(p = 0; p < TParray.length; p++){
		for(j = 0; j < tpn.length; j++){
			if(tpn[j] == TParray[p]){
				desc = tpdesc[j];
			}
		}
		infoOpts = {
		             position: taskList[p],
		             map:      map,
								 content:  desc
		};
		var infowindow = new google.maps.InfoWindow( infoOpts );
		infowindow.open(map);
	}
}

// Needed for Status Report!
function popup(mylink, windowname, wid, ht)
{
	if (! window.focus)return true;
	var href;
	if (typeof(mylink) == 'string')
		href=mylink;
	else
		href=mylink.href;
	args = 'width=' + wid + ',height=' + ht + ',scrollbars=yes';
	// window.open(href, windowname, args);
	window.open(href, '', args);	// IE objects to a window name
	return false;
}


// Get the run status from the Modeller, via a cgi-bin script
function getStatus()
{
	url = Server + "cgi-bin/statusChk.cgi";
	popup( url, 'Status Report', 650, 450);
}


/*
 * Need to distinguish Single vs Double Click
 *
 * doclick() is always called: Set timeout
 *
 * If dblclick() fires within timeout, reset timer (default actions follow)
 * Else oneclick() runs
 *
 */
var	timeoutId;

function doclick()
{
	timeoutId = setTimeout(oneclick, 500);
}


function dblclick()
{
	clearTimeout(timeoutId);
}

/********************************/
/* CallBack for onclick (image) */
/********************************/
function oneclick(E)
{
	// Catch a stupid selection
	if (document.getElementById("Param").value === "nope1") {
		return false;
	}

	if(waslong == "Y"){ // longclick
		waslong = "N";
	}
	else {
		var i = document.getElementById("Time").selectedIndex;
		i = (i + 1) % times.length;
		document.getElementById("Time").options[i].selected   = true;
		doChange(E);
	}
}


/******************************************************
 * Check if "Value" or "Day" for param is implemented
 *
 * Returns: "" if not implemented
 *          Parameter name, or
 *          Two Parameter names for Vector Parameters
 ******************************************************/
function checkParam()
{
	var badParams = new Array();
	badParams[0]  = "";
	badParams[1]  = "boxwmax";
	badParams[2]  = "sounding1";
	badParams[3]  = "sounding2";
	badParams[4]  = "sounding3";
	badParams[5]  = "sounding4";
	badParams[6]  = "sounding5";
	badParams[7] = "sounding6";
	badParams[8] = "sounding7";
	badParams[9] = "sounding8";
	badParams[10] = "sounding9";
	badParams[11] = "sounding10";
	badParams[12] = "sounding11";
	badParams[13] = "sounding12";
	badParams[14] = "sounding13";
	badParams[15] = "sounding14";
	badParams[16] = "sounding15";
	badParams[17] = "topo" ;
	badParams[18] = "zblclmask" ;
	badParams[19] = "zsfclclmask" ;
	// badParams[1]  = "press850";
	// badParams[2]  = "press700";
	// badParams[3]  = "press500";
	// badParams[23]  = "press950";
	// badParams[24]  = "press1000";

	for(i = 0; i < badParams.length; i++) 
		if( document.getElementById("Param").value === badParams[i])
			return "" ;

	/* Identify the Vector Params */
	if(document.getElementById("Param").value === "wstar_bsratio")
		return("wstar bsratio");
	if(document.getElementById("Param").value === "sfcwind0")
		return("sfcwind0spd sfcwind0dir");
	if(document.getElementById("Param").value === "sfcwind")
		return("sfcwindspd sfcwinddir");
	if(document.getElementById("Param").value === "blwind")
		return("blwindspd blwinddir");
	if(document.getElementById("Param").value === "bltopwind")
		return("bltopwindspd bltopwinddir");
	if(document.getElementById("Param").value === "press1000")
		return("press1000 press1000wspd press1000wdir");
	if(document.getElementById("Param").value === "press950")
		return("press950 press950wspd press950wdir");
	if(document.getElementById("Param").value === "press850")
		return("press850 press850wspd press850wdir");
	if(document.getElementById("Param").value === "press700")
		return("press700 press700wspd press700wdir");
	if(document.getElementById("Param").value === "press500")
		return("press500 press500wspd press500wdir");

	return document.getElementById("Param").value ;
}

			
var req = false;

function doCallback(url, data, Event)
{
	/************************************************/
	/* This stuff needed if running from file://... */
	/* DELETE THE LINE BELOW TO INCLUDE  */
	/*
	try {
		netscape.security.PrivilegeManager.enablePrivilege("UniversalBrowserRead");
	} catch (e) {
		alert("Permission UniversalBrowserRead denied.");
	}
	*/
	/* AND THE LINE ABOVE */
	// End This stuff needed
	/************************************************/
	if (window.XMLHttpRequest) {
		try { req = new XMLHttpRequest(); }
		catch (e) { req = false; }
	}
	else if (window.ActiveXObject) {
		// For Internet Explorer on Windows
		try { req = new ActiveXObject("Msxml2.XMLHTTP"); }
		catch (e) {
			try { req = new ActiveXObject("Microsoft.XMLHTTP"); }
			catch (e) { req = false; }
		}
	}
	if (req) {
		req.onreadystatechange = function(){
			if(req.readyState == 4 && req.status == 200){
				addInfo(Event.latLng, '<pre>' + req.responseText + '</pre>');
			}
		}
		try { req.open('POST', url, true); }
		catch (E){ alert(E); }
		req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
		req.send(data);
	}
	else { alert("Failed to send XML data"); }
}

var text;


/******************/
/* Which Browser? */
/******************/
var ns;
var ko;
var ie;
var op;

function whichBrowser()
{
	// alert("Browser = " + navigator.appName);
	ns = navigator.appName === 'Netscape' ;
	ie = navigator.appName === 'Microsoft Internet Explorer' ;
	ko = navigator.appName === 'Konqueror' ;
	op = navigator.appName === 'Opera' ;
}


// Determine the Map Resolution
function getResolution()
{
	if(archiveMode) {
		return(2);
	}
	else {
		switch( document.getElementById("Day").options.selectedIndex){
		case 0:	return( 2);	break;  // Today    - 2Km
		case 1: return(12);	break;  // Today    - 12Km
		case 2: return( 4);	break;  // Tomorrow - 4Km
		case 3:                     // Rest of week - 12Km
		case 4:
		case 5:
		case 6: 
		case 7: return(12); break;
		default:
			alert("getResolution: Unknown Day Index!");
			return(12);	// What else?
			break;
		}
	}
}

/******************/
/* Set Image Size */
/******************/

var Format;

function setSize()
{
	var titleBox;
	var zoomBox;
	var scaleBox;
	var sideScaleBox;

	if(document.body.clientWidth !== undefined) {	// IE in various versions
		imgHt  = document.body.clientHeight;
		imgWid = document.body.clientWidth;
	}
	else if(document.documentElement && document.documentElement.clientWidth !== undefined) {
		imgHt  = document.documentElement.clientHeight;
		imgWid = document.documentElement.clientWidth;
	}
	else if(window.innerWidth !== undefined){
		imgHt  = window.innerHeight;
		imgWid = window.innerWidth;
	}
	else {	// FF etc
		imgHt  = document.body.scrollHeight;
		imgWid = document.body.scrollWidth;
	}

	imgWid -= document.getElementById("selectors").offsetWidth; // Subtract width of Selectors

	// Determin whether image is Portrait or Landscape
	if( imgHt > imgWid){
		Format = "Portrait";
	}
	else {
		Format = "Landscape";
	}

	topHeight = imgWid * (1 - 0.82) / 3.0 ;		// Value from NCL header.ncl But much too big (so / 3.0)
	if(Format == "Landscape") {
		botHeight = 0  // Turn off Bottom Scale
		sideWidth = Math.ceil(imgHt * 0.09);   // Value from NCL labelbar.ncl
	}
	else {
		botHeight = imgWid * 0.06;	// Value from NCL labelbar.ncl
		sideWidth = 0; // Turn Off Side Scale
	}

	/* 
	 * See http://www.w3schools.com/Css/pr_class_position.asp
	 * for interaction of position = absolute, fixed, relative, static & inherit
	 */
	titleBox = document.getElementById("topTitle");
	titleBox.style.left     = 0  + "px" ;
	titleBox.style.top      = 0  + "px";
	titleBox.style.height   = topHeight + "px";
	titleBox.style.width    = imgWid + "px";
	titleBox.style.overflow = "hidden" ;
	titleBox.style.position = "relative" ;
	titleBox.style.padding  = 0;

	titleObj.style.left     = 0  + "px" ;
	titleObj.style.top      = 0 + "px";
	titleObj.style.height   = topHeight + "px";
	titleObj.style.position = "relative" ;

	zoomBox = document.getElementById("zoomBox");
	zoomBox.style.left     = 0  + "px" ;
	zoomBox.style.top      = 0  + "px";
	// There's some (as yet unindentified) padding, which must be allowed for => 12
	// OLD zoomBox.style.height   = (imgHt - topHeight - botHeight ) + "px";
	// OLD zoomBox.style.width    = (imgWid - sideWidth ) + "px";
	zoomBox.style.height   = (imgHt - topHeight - botHeight - 12) + "px";
	zoomBox.style.width    = (imgWid - sideWidth - 12) + "px";
	zoomBox.style.overflow = "hidden" ;
	zoomBox.style.position = "relative" ;
	zoomBox.style.padding  = 0;

	sideScaleBox = document.getElementById("sideScale");
	sideScaleBox.style.left     = 0  + "px" ;
	sideScaleBox.style.top      = 0  + "px";
	sideScaleBox.style.width    = sideWidth + "px";
	sideScaleBox.style.width    = sideWidth + "px";
	sideScaleBox.style.overflow = "hidden" ;
	sideScaleBox.style.position = "relative" ;
	sideScaleBox.style.padding  = 0;

	sideScaleObj.style.left     = 0  + "px";
	sideScaleObj.style.top      = 0 + "px";
	sideScaleObj.style.width    = sideWidth  + "px";
	sideScaleObj.style.height   = zoomBox.style.height
	sideScaleObj.style.position = "relative" ;

	scaleBox = document.getElementById("botScale");
	scaleBox.style.left     = 0  + "px" ;
	scaleBox.style.top      = 0  + "px";
	scaleBox.style.height   = botHeight + "px";
	scaleBox.style.overflow = "hidden" ;
	scaleBox.style.position = "relative" ;

	scaleObj.style.left     = 0  + "px";
	scaleObj.style.top      = 0 + "px";
	scaleObj.style.height   = botHeight  + "px";
	scaleObj.style.position = "relative" ;
	scaleObj.style.width    = zoomBox.style.width;

	/* Now do the Selectors */

	tblHt = document.getElementById("selectors").offsetHeight;

	// alert("TableHt = " + tblHt + "ImgHt = " + imgHt);
			
	if( tblHt > imgHt ){
		document.getElementById("Param").size = 1;	// Number of visible Parameters
		document.getElementById("Time").size  = 1;	// Number of visible Times
		document.getElementById("Day").size   = 1;	// Number of visible Days
	}

	else { 							// The big Tables will fit
		document.getElementById("Param").size = 13;
		document.getElementById("Time").size  = 8;
		document.getElementById("Day").size   = 8;
	}
	doChange(null);
}


/********************/
/* Check if Archive */
/* 0 => normal      */
/* 1 => archive     */
/********************/
var archiveMode = 0;
var oldArchive = 0;
var oldArchiveDay;
var oldArchiveMonth;
var oldArchiveYear;
var oldDayIndex;

function isArchive()
{
	if((document.getElementById("archiveDay").value === "nope1")
	    || (document.getElementById("archiveMonth").value === "nope1")
	    || (document.getElementById("archiveYear").value === "nope1")){
		archiveMode = 0;
	}
	else
		archiveMode = 1;
}


function resetArchive()
{
	document.getElementById("archiveDay").options[0].selected = true;
	document.getElementById("archiveMonth").options[0].selected = true;
	document.getElementById("archiveYear").options[0].selected = true;
	doChange(null);
}

/* 
 * Set the times in the table for PST or PDT
 *
 */
function setTimes()
{
	var dateJan = new Date(2012, 0, 1);
	var dateNow = new Date();

	if(archiveMode){
		dateNow = new Date( document.getElementById("archiveYear").value,
		                    document.getElementById("archiveMonth").value - 1,	// Allow for months 1 - 12
		                    document.getElementById("archiveDay").value,
		                    12); // midday
	}
	else{
		var mS_Day = 24 * 60 * 60 * 1000;	// mS in a day

		switch( document.getElementById("Day").selectedIndex ){
		case 0:                                                     break;     // Today   - 2km
		case 1:                                                     break;     // Today   - 12km
		case 2: dateNow = new Date(dateNow.valueOf() +     mS_Day); break;     // Today+1 - 4km
		case 3: dateNow = new Date(dateNow.valueOf() + 2 * mS_Day); break;     // Today+2 - 4km
		case 4: dateNow = new Date(dateNow.valueOf() + 3 * mS_Day); break;     // Today+3 - 4km
		case 5: dateNow = new Date(dateNow.valueOf() + 4 * mS_Day); break;     // Today+4 - 4km
		case 6: dateNow = new Date(dateNow.valueOf() + 5 * mS_Day); break;     // Today+5 - 4km
		case 7: dateNow = new Date(dateNow.valueOf() + 6 * mS_Day); break;     // Today+6 - 4km
		}
	}
	if(dateNow.getTimezoneOffset() == dateJan.getTimezoneOffset())
		times = tzArray["PST"];
	else
		times = tzArray["PDT"];

        // alert("dateNow = " + dateNow);

        // Keep the same time selected
	Tindex = document.getElementById("Time").selectedIndex;

	for(var i = 0; i < times.length; i++) {
		document.getElementById("Time").options[i] = new Option(times[i], times[i]);
		if(Tindex == i)
			document.getElementById("Time").options[i].selected = true;
	}
}

/*******************************/
/* CallBack from the selectors */
/*******************************/
function doChange(E)
{
	if(document.getElementById("Param").value === "nope1" ) {
		return 0;		// Catch a stupid selection
	}

	/*  Descriptions */
	if(fullSet){
		(document.getElementById("desc")).innerHTML = GMparamListFull[document.getElementById("Param").selectedIndex][3] ;
	}
	else {
		(document.getElementById("desc")).innerHTML = GMparamListLite[document.getElementById("Param").selectedIndex][3] ;
	}

	isArchive();

	if( oldArchive == 0 && archiveMode == 1){	// Change to Archive mode
		oldDayIndex =  document.getElementById("Day").options.selectedIndex;
		document.getElementById("Day").options[document.getElementById("Day").options.selectedIndex].selected = false;
		document.getElementById("Day").disabled = true;
	}
	else if (oldArchive == 1 && archiveMode == 0){ // Change to Normal mode
		document.getElementById("Day").disabled = false;
		document.getElementById("Day").options[oldDayIndex].selected = true;
	}

	/* Clear saved images
	 * if changing to / from archiveMode,
	 * or Param or Day changes
	 */
	if(  (    oldParam !== document.getElementById("Param").value)
	      || (oldDay !== document.getElementById("Day").value)
	      || (oldArchive !== archiveMode)
	      || (archiveMode &&
		( oldArchiveDay     != document.getElementById("archiveDay").value
	          || oldArchiveMonth != document.getElementById("archiveMonth").value
	          || oldArchiveYear  != document.getElementById("archiveYear").value
		)
	     )
	  ){
		for(i = 0; i < document.getElementById("Time").options.length; i++){
			Loaded[i] = false;
		}
		setTimes();
	}

	// Change the resolution if Day changes	
	if(oldDay !== document.getElementById("Day").value){
		resolution = getResolution();
	}

	/* Save current values, so can detect change */
	oldParam = document.getElementById("Param").value;
	oldDay = document.getElementById("Day").value;
	oldArchive = archiveMode;
	oldArchiveDay = document.getElementById("archiveDay").value;
	oldArchiveMonth = document.getElementById("archiveMonth").value;
	oldArchiveYear  = document.getElementById("archiveYear").value;

	loadImage(1); // forwards
}

function getBasedir()
{
	var basedir;

	if(archiveMode)
		return("ARCHIVE/UK+0");

	switch(document.getElementById("Day").selectedIndex){
		case 0: basedir = "northplains"; break;
		default: alert("getBasedir: Bad day selector: " + document.getElementById("Day").selectedIndex); break;
	}
	return(basedir);
}

/************************************/
/* Load the Image, and the next one */
/************************************/

function loadImage(dirn)
{
	// dirn: -1 => backwards; 0 => neither; 1 => forwards

	var tIdx = document.getElementById("Time").selectedIndex;
	var tValue;
	var imgURL;

	var T = new Date();			// Instantiate a Date object; initialised to "Now"
	var str;

	tValue = document.getElementById("Time").options[tIdx].value;

	// set up URL Button
	if(archiveMode){
		str = location.href.split("?")[0]
		      + "?" + "date="
		      + document.getElementById("archiveYear").value
		      + document.getElementById("archiveMonth").value
		      + document.getElementById("archiveDay").value
		      + "&param=" + document.getElementById("Param").value
		      + "&time=" + tValue 
		      + "&zoom="   + zoom
		      + "&centre=" + centre.toUrlValue(); 
	}
	else {
		offset = document.getElementById("Day").selectedIndex;
		if(offset > 1){
			T.setDate(T.getDate() + offset - 1);	// DayOfMonth - Deal with "Today-12Km"
		}
		month = T.getMonth() + 1;	// month now 1 to 12
		if(month < 10)
			month = "0" + month;
		date = T.getDate();
		if(date < 10)
			date = "0" + date;
		year = T.getFullYear();
		str = location.href.split("?")[0]
		      + "?"
		      + "date="    + year + month + date
		      + "&param="  + document.getElementById("Param").value
		      + "&time="   + tValue
		      + "&zoom="   + zoom
		      + "&centre=" + centre.toUrlValue(); 
	}
	
	document.getElementById("Url").innerHTML = '<a href="' + str +'">Page URL</a>';

	/* Can't copy the URL from an alert() box in Widnows!
	str = "onclick=alert('" + str + "');";
	document.getElementById("Url").innerHTML = "<button onClick=\"" + str +"\">Page URL</button>";
	*/
	// URL Button done

	//Build the img url
	if(archiveMode == 1){
		imgURL = Server + getBasedir() + "/"
		                + document.getElementById("archiveYear").value + "/"
		                + document.getElementById("archiveYear").value
		                + document.getElementById("archiveMonth").value
		                + document.getElementById("archiveDay").value
		                + "/"
		;
	}
	else {
			imgURL =  Server + "RASP/GM/" + getBasedir() + "/" ;
	}
	// alert( "imgURL = " + imgURL);
	
	/***************************************************
	 * First shot at interrogating the Valid Time info *
	 ***************************************************/
	// stuff = doCallback( imgURL + "valid.curr." + tValue + "lst.d2.txt", "", 0);
	// popup(imgURL + "valid.curr." + tValue + "lst.d2.txt", "Date Done", 200, 40);
	// document.getElementById("validTime").src = imgURL + "valid.curr." + tValue + "lst.d2.txt";
	// alert( document.getElementById("validTime").innerHTML )

	if(document.getElementById("Param").value == "topo"){
		Pics[tIdx]              = "topo" + getResolution() + ".body.png";	// topo files are in this dir
		theTitles[tIdx].src     = "topo" + getResolution() + ".head.png";
		theSideScales[tIdx].src = "topo" + getResolution() + ".side.png";
		theScales[tIdx].src     = "topo" + getResolution() + ".foot.png";
		Loaded[tIdx]            = true;
	}
	else{

		for(x = tIdx, i = 0; i < 2; i++){
			if (Loaded[x]) {
				x = (x + dirn) % times.length;
				if (x < 0)
					x = times.length - 1;
				continue;
			}
			t = tzArray["UTC"][x];
			if(document.getElementById("Param").value.match("sounding")){
				isSounding = true;
				ximgURL = imgURL + document.getElementById("Param").value + ".curr." + t + "lst.d2.png" ;
				if( !Loaded[x]){
					Pics[x]              = ximgURL;
					Loaded[x]            = true;
				}
			}
			else{
				isSounding = false;
				ximgURL = imgURL + document.getElementById("Param").value + ".curr." + t + "lst.d2.body.png" ;
				if( !Loaded[x]){
					Pics[x]              = ximgURL;
					theTitles[x].src     = ximgURL.replace(/body/, "head");
					theSideScales[x].src = ximgURL.replace(/body/, "side");
					theScales[x].src     = ximgURL.replace(/body/, "foot");
					Loaded[x]            = true;
				}
			}
		}
	}

	// If already have an overlay, remove it
	if(overlay){
		google.maps.event.removeListener( overlay.MymouseWheelListener2_);
		google.maps.event.removeListener( overlay.MymouseWheelListener_);
		overlay.setMap(null);
	}

	deleteInfo();		// Remove the InfoWindows
	if(paramWindow){	// and BLIPspot / skewT popup window
		paramWindow.close();
	}

	// Install the new Overlay or Sounding
	var imgData = document.getElementById("imgdata");
	if(isSounding){
		if(wasSounding == false){
			if(!imgFragment)
				imgFragment = document.createDocumentFragment();
			imgFragment.appendChild( document.getElementById("imgDiv")); // "appending" imgData removes it from old tree
			wasSounding = true;
		}
		if(Format == "Landscape")
			imgData.innerHTML = "<img src='" + Pics[tIdx] + "'" + " height=" + imgHt + ">" ;
		else
			imgData.innerHTML = "<img src='" + Pics[tIdx] + "'" + " width=" + imgWid + ">" ;
		imgData.firstChild.addEventListener('click', function(event) {oneclick(event);});
	}
	else {	// Map
		if(wasSounding){
			if(!imgFragment)
				alert("Error! - No saved image fragment");
			imgData.removeChild(imgData.firstChild);
			imgData.appendChild(imgFragment);
			wasSounding = false;
		}

		document.getElementById("theTitle").src     = theTitles[tIdx].src;
		document.getElementById("theScale").src     = theScales[tIdx].src;
		document.getElementById("theSideScale").src = theSideScales[tIdx].src;
		overlay = new RASPoverlay(corners.Bounds[resolution], Pics[tIdx], map);
		overlay.setMap(map);
		overlay.draw(map);
		addSndMarkers();
		if ( opacity_control == "N" ) {	
		    createOpacityControl(map, opacity); 
			opacity_control = "Y";
		}

		// Handle Centre & Zoom - e.g. if specified in URL
		map.setCenter(centre),
		google.maps.event.addListenerOnce(map, "tilesloaded", function () { map.setZoom(zoom)});

	}
}

var imgFragment = null;

var wasSounding ;
var mapStuff          ;
var soundingStuff = null;

function doAirspace()
{
	var airspacetype = document.getElementById("airspace");

	for(i = 0; i < airspacetype.length; i++){
		if(airspacetype[i].checked){
			airspaceArray[i].setMap(map);
		}
		else{
			airspaceArray[i].setMap(null);
		}
	}
}


function newclick(E)
{
	var content;
	var tail;
	var parameter;
	var str;
	var lat;
	var lon;

	clearTimeout(timeoutId);

	str = E.latLng.toUrlValue();
	lat = str.split(',')[0];
	lon = str.split(',')[1];

	parameter = checkParam();
	if(parameter === "") {
		addInfo(E.latLng, "<br>Values for " +document.getElementById("Param").value + " are not available", 30, 80);
		return;
	}
	else { // Good parameter
		blipSpotUrl = Server + "cgi-bin/get_rasp_blipspot.cgi";
		str = archiveMode ? "UK%2b0" : getBasedir().replace("\+", "%2b"); // %2b == '+'

		tail = "region=" + str
		     + "&grid="   + "d2"
		     + "&day="
		     + (archiveMode ? ( document.getElementById("archiveYear").value
		                      + document.getElementById("archiveMonth").value
		                      + document.getElementById("archiveDay").value)
			           : "0")
		     + "&linfo=1"
		     + "&lat="        + lat
		     + "&lon="        + lon
		     ;

		// Get type of Popup from Radio Button Selector
		var el = document.getElementById("popup").info;

		for(i = 0; i < el.length; i++){
			if(el[i].checked)
				infoPopup = el[i].value;
		}

		if(infoPopup == "SkewT") {
			if(archiveMode){
				addInfo(E.latLng, "<pre>Not available for Archive dates</pre>", 0, 0);
				return;
			}
			
			wrffile = getRegion();
			blipSpotUrl = Server + "cgi-bin/get_rasp_skewt.cgi";
			tail = "region=" + wrffile
			                 + "&grid="   + "d2"
			                 + "&day="    + "0"
			                 + "&lat="    + lat
			                 + "&lon="    + lon
			                 + "&time="   +  document.getElementById("Time").value
			;
			// var txt = '<img src="' + blipSpotUrl + '?' + tail +'" height=600 width=600>';
			// addInfo(E.latLng, txt, 650, 650);
			addInfo(E.latLng, "<pre>See PopUp Window</pre>", 0, 0);
			paramWindow = window.open(blipSpotUrl + "?" + tail, 'SkewT', 'height=850,width=850');
			return;
		}
		if(infoPopup == "Value") {
			tail = tail + "&time=" + document.getElementById("Time").value + "lst" + "&param=" + parameter ;
		}
		if(infoPopup == "Day") {
			tail = tail + "&param=" + parameter ;
		}

		// alert("URL = " + blipSpotUrl + "\n\ntail = " + tail);
		doCallback(blipSpotUrl, tail, E);
	}
}


function getRegion()
{
	if(archiveMode){
		return( "UK%2b0" );
	}
	switch(document.getElementById("Day").selectedIndex){
		case 0: regn = "UK%2b0"; break;
		case 1: regn = "UK12";   break;
		case 2: regn = "UK%2b1"; break; // Both +1 runs go into the same directory 
		case 3: regn = "UK%2b2"; break;
		case 4: regn = "UK%2b3"; break;
		case 5: regn = "UK%2b4"; break;
		case 6: regn = "UK%2b5"; break;
		case 7: regn = "UK%2b6"; break;
		default: alert("Bad day selector: " + document.getElementById("Day").selectedIndex); break;
	}
	return(regn);
}



function addInfo(location, txt, xsiz, ysiz)
{
	var infoOpts;

	// if((imgWid < 480) || (imgHeight < 480))	// Remove other infoWindows on small screens
	//	deleteInfo();
	
	var el = document.getElementById("popup").info;

	for(i = 0; i < el.length; i++){
		if(el[i].checked)
			infoPopup = el[i].value;
	}

	var nlines = 0;
	for(var start = 0; (start = txt.indexOf("\n", start)) > -1; start++, nlines++)
		;
	nlines = nlines ? nlines : 1;
	txt1 = '<div style="height: ' + nlines + 'em;" >' + txt + '</div>';

	infoOpts = {
	           position: location,
	           map:      map,
	           content:  txt1,
		   maxHeight: 50
	};
	var infowindow = new google.maps.InfoWindow( infoOpts );
	infowindow.open(map);
	infoArray.push(infowindow);

	// This is a bit kludgy - Adjust *every* infowindow each time - but it seems to work!
	google.maps.event.addDomListenerOnce(infowindow, 'domready', function(event) {
			var arr = document.getElementsByTagName("pre");
			for(var e = 0; e < arr.length; e++){
				arr[e].parentNode.parentNode.style.overflow = 'visible';
			}
		}, true
	);
}

function deleteInfo()
{
	if (infoArray) {
		for(i  = 0; i < infoArray.length; i++) {
			infoArray[i].setMap(null);
		}
		infoArray.length = 0;
		if(ctrFlag){
			map.panTo(centre); // Centre the map if Sounding has scrolled it
			ctrFlag = false;
		}
	}
}


/*
function writePopup(text)
{
	var txt;

	if(text.lastIndexOf('\n') - text.indexOf('\n') > 1){
		// txt = document.getElementById("Param").value + "<br>" + text.replace(/\n/, (document.getElementById("Param").value === "wstar_bsratio" ? "<br>BS: ": "<br>Dirn: "));
		txt = text.replace(/\n/, (document.getElementById("Param").value === "wstar_bsratio" ? "<br>BS: ": "<br>Dirn: ")) ;
	}
	else {
		// txt = document.getElementById("Param").value + "<br>" + text;
		txt = text +"<br>";
	}
	// alert('Text = "' + text + '"\nPosn = ' + Event.latLng)
	addInfo(Event.latLng, txt, 80, 120);
}
*/


function switchParamList(E)
{
	if(fullSet){
		changeParamset(GMparamListLite);
		document.getElementById("paramSet").innerHTML = "Press for Full Parameter set";
	}
	else{
		changeParamset(GMparamListFull);
		document.getElementById("paramSet").innerHTML = "Press for Reduced Parameter set";
	}
}
		

function changeParamset(newParams)
{
	for(var i = 0; i < newParams.length; i++) {
		document.getElementById("Param").options[i] = new Option(newParams[i][2], newParams[i][1]);
		document.getElementById("Param").options[i].className = newParams[i][0];
	}
	if(document.getElementById("Param").options.length > newParams.length){
		for(i = newParams.length; i < document.getElementById("Param").length; i++){
			document.getElementById("Param").options[i] = null;
		}
	}
	document.getElementById("Param").options.length = newParams.length;
	fullSet = ((fullSet == true) ? false : true);

	// The parameter punter had selected is available as oldParam !!
	for(var i = 0; i < document.getElementById("Param").options.length; i++){
		if(document.getElementById("Param").options[i].value == oldParam)
			break;
	}
	if(i == document.getElementById("Param").options.length){
		document.getElementById("Param").options[1].selected = true;	// Not available
	}
	else{
		document.getElementById("Param").options[i].selected =true;
	}
}

// longclick
function LongClick(map, length) {
    this.length_ = length;
    var me = this;
    me.map_ = map;
    google.maps.event.addListener(map, 'mousedown', function(e) { me.onMouseDown_(e) });
    google.maps.event.addListener(map, 'mouseup', function(e) { me.onMouseUp_(e) });
}

LongClick.prototype.onMouseUp_ = function(e) {
    var now = +new Date;
    if (now - this.down_ > this.length_) {
      google.maps.event.trigger(this.map_, 'longpress', e);
      waslong = "Y";
    }
}

LongClick.prototype.onMouseDown_ = function() {
    this.down_ = +new Date;
}

/**** Subclass Google Maps OverlayView() to add Opacity ****/

function cancelEvent(e)
{
	e = e ? e : window.event;
	if(e.stopPropagation) e.stopPropagation();
	if(e.preventDefault)  e.preventDefault();
	e.cancelBubble = true;
	e.cancel = true;
	e.returnValue = false;
	return false;
}

/**
* Get the position of the mouse relative to the document.
* @param {Object} e  Mouse event
* @return {Object} left & top position
*/
function getMousePosition(e)
{
	var posX = 0, posY = 0;
	e = e || window.event;
	if (typeof e.pageX !== "undefined") {
		posX = e.pageX;
		posY = e.pageY;
	}
	else if (typeof e.clientX !== "undefined") {
		posX = e.clientX + (typeof document.documentElement.scrollLeft !== "undefined" ? document.documentElement.scrollLeft : document.body.scrollLeft);
		posY = e.clientY + (typeof document.documentElement.scrollTop  !== "undefined" ? document.documentElement.scrollTop  : document.body.scrollTop);
	}
	return {
		left: posX,
		top: posY
	};
};


/**
 * Get the position of an HTML element relative to the document.
 * @param {Object} h  HTML element
 * @return {Object} left & top position
 */
function getElementPosition(h)
{
	var posX = h.offsetLeft;
	var posY = h.offsetTop;
	var parent = h.offsetParent;
	// Add offsets for all ancestors in the hierarchy
	while (parent !== null) {
		// Adjust for scrolling elements which may affect the map position.
		//
		// See http://www.howtocreate.co.uk/tutorials/javascript/browserspecific
		//
		// "...make sure that every element [on a Web page] with an overflow
		// of anything other than visible also has a position style set to
		// something other than the default static..."
		if (parent !== document.body && parent !== document.documentElement) {
			posX -= parent.scrollLeft;
			posY -= parent.scrollTop;
		}
		posX += parent.offsetLeft;
		posY += parent.offsetTop;
		parent = parent.offsetParent;
	}
	return {
		left: posX,
		top: posY
	};
};



function getMousePoint(e)
{
	var mousePosn = mousePos_;
	if (!mousePosn) {
		return null;
	}
	var mapPosn = getElementPosition(map.getDiv());
	return new google.maps.Point(mousePosn.left - mapPosn.left, mousePosn.top - mapPosn.top);
};


var mousePos_ = null;
function myMouseMove_(e) {
	mousePos_ = getMousePosition(e);
};


RASPoverlay.prototype = new google.maps.OverlayView();

var p = null;

function myMouseWheel_(e)
{
	e = e || window.event;
	if (e.wheelDelta) { // IE/Opera/Chrome. 
		delta = e.wheelDelta/120;
		if (window.opera)
			delta = -delta; // In Opera 9, delta differs in sign as compared to IE
	}
	else if (e.detail) { // Mozilla & friends
		delta = -e.detail / 3.0; // Sgn(delta) opposite
	}
	if(e.shiftKey){	// Adjust Opacity
		opacity += 10 * delta; // "opacity" ensures all overlays have this opacity
		opacity = (opacity > 100) ? 100 : opacity;
		opacity = (opacity < 0)   ?   0 : opacity;
		overlay.setOpacity(opacity);
		// Set slider too
		var newsliderValue = OPACITY_MAX_PIXELS * (opacity/ 100);
		opacityCtrlKnob.setValueX(newsliderValue);
	}
	else{ // Adjust Zoom
		p = getMousePoint(e);	// mouse posn on map in pixel coords - top left is (0,0)
		if (!p) {
			return;
		}
		var div = map.getDiv();
		var cX = div.offsetWidth  / 2;	// centre of map (pixel coords)
		var cY = div.offsetHeight / 2;
		var z = map.getZoom();

		if(delta > 0) {
			if(z < 12){
				z++;
				map.panBy((p.x-cX)/2, (p.y-cY)/2);
			}
		}
		else {
			if(z > 6){	// Do nothing if zoom == 6 (minZoom)
				z--;
				map.panBy(cX-p.x, cY-p.y);
			}
		}
		map.setZoom(z);
		zoom = z;
	}

	return(cancelEvent(e));
}

function RASPoverlay(bounds, image, map)
{
	this.url_           = image;
	this.bounds_        = bounds;
	this.map_           = map;
	this.id             = image;
	this.percentOpacity = opacity;
	this.setMap(map);

	// Is this IE, if so we need to use AlphaImageLoader
	var agent = navigator.userAgent.toLowerCase();
	if ((agent.indexOf("msie") > -1) && (agent.indexOf("opera") < 1)) {
		this.ie = true ;
	}
	else {
	 this.ie = false ;
	}
}


RASPoverlay.prototype.onAdd = function()
{
	var div = document.createElement("div") ;

	div.style.position = "absolute" ;
	div.style.borderStyle = "none";
	div.setAttribute('id',this.id) ;

	this.MymouseWheelListener_  = google.maps.event.addDomListener(this.map_.getDiv(), 'mousewheel',     function (e) { myMouseWheel_(e); }, true);
	this.MymouseWheelListener2_ = google.maps.event.addDomListener(this.map_.getDiv(), 'DOMMouseScroll', function (e) { myMouseWheel_(e); }, true);
	this.mouseMoveListener_     = google.maps.event.addDomListener(this.map_.getDiv(), 'mousemove',      function (e) { myMouseMove_(e); },  true);

	this.div_ = div ;
	var panes = this.getPanes();
 	panes.overlayLayer.appendChild(div);

	if( this.percentOpacity ) {
		this.setOpacity(opacity) ;
	}
}

// Remove the main DIV from the map pane
RASPoverlay.prototype.onRemove = function()
{
	this.div_.parentNode.removeChild(this.div_);
	this.div_ = null;
}


RASPoverlay.prototype.draw = function()
{
	var overlayProjection = this.getProjection();

	if(overlayProjection == undefined)
		return;

	var sw = overlayProjection.fromLatLngToDivPixel(this.bounds_.getSouthWest());
	var ne = overlayProjection.fromLatLngToDivPixel(this.bounds_.getNorthEast());

	// Position our DIV using our bounds
	if(this.div_ == null)
		return;
	this.div_.style.left   = Math.min(sw.x,  ne.x) + "px";
	this.div_.style.top    = Math.min(ne.y,  sw.y) + "px";
	this.div_.style.width  = Math.abs(sw.x - ne.x) + "px";
	this.div_.style.height = Math.abs(ne.y - sw.y) + "px";

	this.div_.innerHTML = '<img src="' + this.url_ + '" width=' + this.div_.style.width + ' height=' + this.div_.style.height + ' >';

	if( this.percentOpacity ) {
		this.setOpacity(opacity) ;
	}
}

/* 
 * Opacity utility functions
 */
RASPoverlay.prototype.setOpacity=function(opacity)
{
	var c = opacity/100 ;
	var d = document.getElementById( this.id ) ;

	if (d) {
		if (typeof(d.style.filter) =='string')         { d.style.filter = 'alpha(opacity=' + opacity + ')'; } //IE
		if (typeof(d.style.KHTMLOpacity) == 'string' ) { d.style.KHTMLOpacity = c ; }
		if (typeof(d.style.MozOpacity) == 'string')    { d.style.MozOpacity = c ; }
		if (typeof(d.style.opacity) == 'string')       { d.style.opacity = c ; }
	}
}

RASPoverlay.prototype.getOpacity=function()
{
	var d = document.getElementById(this.id);
	if(d){
		d = d.parentNode;
		if (typeof(d.style.filter) =='string')        { d.style.filter = 'alpha(opacity=' + opacity + ');'; } //IE
		if (typeof(d.style.KHTMLOpacity) == 'string') { return(100 * d.style.KHTMLOpacity); }
		if (typeof(d.style.MozOpacity)   == 'string') { return(100 * d.style.MozOpacity);   }
		if (typeof(d.style.opacity)      == 'string') { return(100 * d.style.opacity);      }
	}
}

// add indexOf function - For the dreaded m$ Widnows Exploder
if (!Array.prototype.indexOf){
	Array.prototype.indexOf = function(val, fromIndex) {
		if (typeof(fromIndex) != 'number')
			fromIndex = 0;
		for(var index = fromIndex,len = this.length; index < len; index++)
			if (this[index] == val)
				return index;
			return -1;
	}
}

function createOpacityControl(map, opacity) {
	var sliderImageUrl = "slider.png";

	// Create main div to hold the control.
	var opacityDiv = document.createElement('DIV');
	opacityDiv.setAttribute("style", "margin:5px;overflow-x:hidden;overflow-y:hidden;background:url(slider.png) no-repeat;width:71px;height:21px;cursor:pointer;");

	// Create knob
	var opacityKnobDiv = document.createElement('DIV');
	opacityKnobDiv.setAttribute("style", "padding:0;margin:0;overflow-x:hidden;overflow-y:hidden;background:url(slider.png) no-repeat -71px 0;width:14px;height:21px;");
	opacityDiv.appendChild(opacityKnobDiv);

	opacityCtrlKnob = new ExtDraggableObject(opacityKnobDiv, {
		restrictY: true,
		container: opacityDiv
	});

	google.maps.event.addListener(opacityCtrlKnob, "dragend", function () {
		setOpacity(opacityCtrlKnob.valueX());
	});

	google.maps.event.addDomListener(opacityDiv, "click", function (e) {
		var left = findPosLeft(this);
		opacity = e.pageX - left - 5; // - 5 as we're using a margin of 5px on the div
		opacityCtrlKnob.setValueX(opacity);
		setOpacity(opacity);
	});

	map.controls[google.maps.ControlPosition.TOP_RIGHT].push(opacityDiv);

	// Set initial value
	var initialValue = OPACITY_MAX_PIXELS * (opacity/ 100);
	opacityCtrlKnob.setValueX(initialValue);
	setOpacity(initialValue);

}

function setOpacity(pixelX) {
	// Range = 0 to OPACITY_MAX_PIXELS
	opacity = (100 / OPACITY_MAX_PIXELS) * pixelX;
	if (opacity < 0) opacity = 0;
	if (opacity == 0) {
		if (overlay.visible == true) {
			overlay.hide();
		}
	}
	else {
		overlay.setOpacity(opacity);
		if (overlay.visible == false) {
			overlay.show();
		}
	}
}

function findPosLeft(obj) {
	var curleft = 0;
	if (obj.offsetParent) {
		do {
			curleft += obj.offsetLeft;
		} while (obj = obj.offsetParent);
		return curleft;
	}
	return undefined;
}

function getTask()
{
	window.open("task.html", 'Specify_Task', "width=600,height=300");
}

// Default Values for getGlider()
var glider  = "DiscusA";
var ballast = "1";
var tsink   = "1.0";
var tmult   = "1.0";

function selGlider()
{
	return popup("glider.html", 'Select_Glider', 480, 300);
}


function TrackAvg()
{
	var str;
	
	str = Server + "/cgi-bin/get_rasptrackavg.cgi?region=" + getRegion() + "&grid=d2&day=" ;

	if(archiveMode){
		str = str + document.getElementById("archiveYear").value + "-"
                          + document.getElementById("archiveMonth").value + "-"
                          + document.getElementById("archiveDay").value;
	}
	else{
		str = str + "0";
	}

	str = str + "&time=" + document.getElementById("Time").value + "%2b&polar=" + glider + "&wgt=" + ballast + "&tsink=" + tsink + "&tmult=" + tmult + "&latlons=";
	for(i  = 0; i < taskList.length; i++){
		str = str + taskList[i].toUrlValue() + ",";
	}
	str = str.replace(/,$/ , '');	// Zap last ','

	// alert(str);
	window.open(str, "Track_Average", "width=975,height=700,resizable=yes,scrollbars=yes");
}
