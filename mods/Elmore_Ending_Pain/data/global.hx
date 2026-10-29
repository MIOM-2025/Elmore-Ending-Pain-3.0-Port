importScript("data/scripts/fpsCounter");
importScript("data/scripts/HandlerPreloadVideos");
function new() {
	// 默认值：两个和谐开、生命图标不和谐、VHS 两个效果开、新版滤镜关、显示警告、不显示 FPS
	if (FlxG.save.data != null) {
		var defVal = function(k:String, v:Dynamic) {
			if (Reflect.field(FlxG.save.data, k) == null) Reflect.setField(FlxG.save.data, k, v);
		}
		defVal("censorVideo", true);
		defVal("censorDeath", true);
		defVal("censorHealth", false);
		defVal("vhsEnabled", true);
		defVal("vhsCurve", true);
		defVal("vhsNew", false);
		defVal("hideWarning", false);
		defVal("EEPvfpsCounter", false);
		FlxG.save.flush();
	}
	// One-time default for the optional alternate VHS filter: old shader stays default.
	// Bump the version whenever the shader set changes so existing saves are reset once.
	if (FlxG.save.data != null && Reflect.field(FlxG.save.data, "vhsNewVersion") != 2) {
		Reflect.setField(FlxG.save.data, "vhsNew", false);
		Reflect.setField(FlxG.save.data, "vhsNewVersion", 2);
		FlxG.save.flush();
	}
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