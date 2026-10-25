importScript("data/scripts/fpsCounter");
importScript("data/scripts/HandlerPreloadVideos");
function new() {
	if(!FlxG.save.data.EEPvfpsCounter == null) FlxG.save.data.EEPvfpsCounter = true;
}
function preStateSwitch() {
    FlxG.camera.bgColor = FlxColor.BLACK;

    @:privateAccess
	if (_nextResolution != null && (FlxG.initialWidth != _nextResolution.width || FlxG.initialHeight != _nextResolution.height)) {
		Main.scaleMode.updateGameSize(FlxG.initialWidth = _nextResolution.width, FlxG.initialHeight = _nextResolution.height);
		_nextResolution = {width: 1280, height: 960};
	}
}

var _nextResolution = {width: 1280, height: 960};
public static function resizeGame(width:Int, height:Int) {
	_nextResolution = {width: width, height: height}
}