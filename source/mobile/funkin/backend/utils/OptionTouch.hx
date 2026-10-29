package mobile.funkin.backend.utils;

#if TOUCH_CONTROLS
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;

/**
 * 设置界面（TreeMenu / TreeMenuScreen）专用的触摸手势：
 * 轻点 = 选中当前项，左右滑 = 改值/切换，上下滑 = 上下移动光标。
 * 不影响 TouchPad：这里只读取手势，不拦截输入。
 */
class OptionTouch
{
	public static var tapDistance:Float = 26;
	public static var swipeDistance:Float = 60;

	static var initialized:Bool = false;
	static var frame:Int = 0;
	static var lastFrame:Int = -1;

	static var tracking:Bool = false;
	static var startX:Float = 0;
	static var startY:Float = 0;
	static var endX:Float = 0;
	static var endY:Float = 0;

	static var _tapped:Bool = false;
	static var _released:Bool = false;
	static var _swipeX:Int = 0;
	static var _swipeY:Int = 0;

	public static function init():Void
	{
		if (initialized) return;
		initialized = true;
		FlxG.signals.preUpdate.add(onPreUpdate);
		FlxG.signals.postUpdate.add(refresh);
		FlxG.signals.preStateSwitch.add(reset);
	}

	public static function reset():Void
	{
		tracking = false;
		_tapped = false;
		_released = false;
		_swipeX = 0;
		_swipeY = 0;
		lastFrame = frame;
	}

	static function onPreUpdate():Void
		frame++;

	static function begin(x:Float, y:Float):Void
	{
		tracking = true;
		startX = x;
		startY = y;
	}

	static function finish(x:Float, y:Float):Void
	{
		tracking = false;
		_released = true;
		endX = x;
		endY = y;

		var dx:Float = x - startX;
		var dy:Float = y - startY;
		var absX:Float = Math.abs(dx);
		var absY:Float = Math.abs(dy);

		if (absX <= tapDistance && absY <= tapDistance)
			_tapped = true;
		else if (absX > absY && absX >= swipeDistance)
			_swipeX = dx > 0 ? 1 : -1;
		else if (absY >= absX && absY >= swipeDistance)
			_swipeY = dy > 0 ? 1 : -1;
	}

	static function refresh():Void
	{
		if (lastFrame == frame) return;
		lastFrame = frame;

		_tapped = false;
		_released = false;
		_swipeX = 0;
		_swipeY = 0;

		for (touch in FlxG.touches.list)
		{
			if (touch == null) continue;
			if (touch.justPressed) begin(touch.screenX, touch.screenY);
			else if (touch.justReleased && tracking) finish(touch.screenX, touch.screenY);
		}

		// 桌面 / 没有触摸事件时用鼠标兜底
		if (FlxG.mouse.justPressed) begin(FlxG.mouse.screenX, FlxG.mouse.screenY);
		else if (FlxG.mouse.justReleased && tracking) finish(FlxG.mouse.screenX, FlxG.mouse.screenY);
	}

	// ===== 查询 =====
	public static var tapped(get, never):Bool;
	static function get_tapped():Bool { refresh(); return _tapped; }

	public static var swipeLeft(get, never):Bool;
	static function get_swipeLeft():Bool { refresh(); return _swipeX < 0; }

	public static var swipeRight(get, never):Bool;
	static function get_swipeRight():Bool { refresh(); return _swipeX > 0; }

	public static var swipeUp(get, never):Bool;
	static function get_swipeUp():Bool { refresh(); return _swipeY < 0; }

	public static var swipeDown(get, never):Bool;
	static function get_swipeDown():Bool { refresh(); return _swipeY > 0; }

	public static var anyPressed(get, never):Bool;
	static function get_anyPressed():Bool
	{
		for (touch in FlxG.touches.list) if (touch != null && touch.pressed) return true;
		return FlxG.mouse.pressed;
	}

	/** 轻点是否落在某个 sprite 上 */
	public static function tappedOn(sprite:FlxSprite, ?camera:FlxCamera):Bool
	{
		if (!_tapped || sprite == null) return false;
		return hit(sprite, startX, startY, camera);
	}

	/** 抬手是否落在某个 sprite 上（返回键用） */
	public static function releasedOn(sprite:FlxSprite, ?camera:FlxCamera):Bool
	{
		if (!_released || sprite == null) return false;
		return hit(sprite, endX, endY, camera);
	}

	/** 按下点是否落在某个 sprite 上（返回键按下态） */
	public static function pressingOn(sprite:FlxSprite, ?camera:FlxCamera):Bool
	{
		if (sprite == null || !tracking) return false;
		return hit(sprite, startX, startY, camera);
	}

	static function hit(sprite:FlxSprite, x:Float, y:Float, ?camera:FlxCamera):Bool
	{
		var cam = camera != null ? camera : sprite.getDefaultCamera();
		var pos = sprite.getScreenPosition(null, cam);
		var ok = x >= pos.x && x <= pos.x + sprite.width && y >= pos.y && y <= pos.y + sprite.height;
		pos.put();
		return ok;
	}
}
#end
