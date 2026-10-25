var zoomStar:Float = 1;
var daZoom:Float = 0.0;
var setZoomStar:Bool = false;
function postCreate() {
    zoomStar = defaultCamZoom; 
}
function onEvent(event) {
    if (event.event.name == "camZoom") {
      
       setZoomStar = event.event.params[0];
       if (!setZoomStar){
        zoomStar = event.event.params[1];
        defaultCamZoom = zoomStar;
       }else{
        daZoom = initialZoom;
        defaultCamZoom = zoomStar;
       }
       
    }
}
