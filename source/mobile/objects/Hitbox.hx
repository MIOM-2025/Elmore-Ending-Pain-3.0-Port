package mobile.objects;

#if TOUCH_CONTROLS
import openfl.display.BitmapData;
import openfl.display.Shape;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.math.FlxMath;
import funkin.backend.system.Main;

/**
 * A zone with 4 hint's (A hitbox).
 * 4 个触摸区：尺寸可选 全屏 / 16:9 / 窗口，样式可选 纯白描边 / 原版彩色。
 */
class Hitbox extends MobileInputManager implements IMobileControls
{
	final offsetFir:Int = (Options.hitboxPos ? Std.int(FlxG.height / 4) * 3 : 0);
	final offsetSec:Int = (Options.hitboxPos ? 0 : Std.int(FlxG.height / 4));

	public var buttonLeft:TouchButton = new TouchButton(0, 0, [MobileInputID.HITBOX_LEFT, MobileInputID.NOTE_LEFT]);
	public var buttonDown:TouchButton = new TouchButton(0, 0, [MobileInputID.HITBOX_DOWN, MobileInputID.NOTE_DOWN]);
	public var buttonUp:TouchButton = new TouchButton(0, 0, [MobileInputID.HITBOX_UP, MobileInputID.NOTE_UP]);
	public var buttonRight:TouchButton = new TouchButton(0, 0, [MobileInputID.HITBOX_RIGHT, MobileInputID.NOTE_RIGHT]);
	public var buttonExtra:TouchButton = new TouchButton(0, 0, [MobileInputID.EXTRA_1]);
	public var buttonExtra2:TouchButton = new TouchButton(0, 0, [MobileInputID.EXTRA_2]);

	public var instance:MobileInputManager;
	public var onButtonDown:FlxTypedSignal<TouchButton->Void> = new FlxTypedSignal<TouchButton->Void>();
	public var onButtonUp:FlxTypedSignal<TouchButton->Void> = new FlxTypedSignal<TouchButton->Void>();

	var storedButtonsIDs:Map<String, Array<MobileInputID>> = new Map<String, Array<MobileInputID>>();

	// 纯白描边时，画在舞台层（和 FPS 计数器同一层），能画到 4:3 画布外的黑边上
	var overlay:Shape = null;
	var overlayButtons:Array<TouchButton> = [];

	public function new()
	{
		super();

		for (button in Reflect.fields(this))
		{
			var field = Reflect.field(this, button);
			if (Std.isOfType(field, TouchButton))
				storedButtonsIDs.set(button, Reflect.getProperty(field, 'IDs'));
		}

		if (!funkin.game.PlayState.qqqeb)
		{
			var visual:Bool = (Options.hitboxType != 'white');
			var r = blockGameRect();
			var rx:Float = r[0], ry:Float = r[1];
			var zw:Float = r[2] / 4;
			var zh:Float = r[3];

			buttonLeft = createHint(rx, ry, Std.int(zw), Std.int(zh), 0xFFC24B99, visual);
			buttonDown = createHint(rx + zw, ry, Std.int(zw), Std.int(zh), 0xFF00FFFF, visual);
			buttonUp = createHint(rx + zw * 2, ry, Std.int(zw), Std.int(zh), 0xFF12FA05, visual);
			buttonRight = createHint(rx + zw * 3, ry, Std.int(zw), Std.int(zh), 0xFFF9393F, visual);

			add(buttonLeft);
			add(buttonDown);
			add(buttonUp);
			add(buttonRight);

			if (!visual)
			{
				overlayButtons = [buttonLeft, buttonDown, buttonUp, buttonRight];
				overlay = new Shape();
				if (Main.instance != null)
					Main.instance.addChild(overlay);
			}
		}
		else
		{
			add(buttonLeft = createHint(0, offsetSec, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4) * 3, 0xFFC24B99, true));
			add(buttonDown = createHint(FlxG.width / 4, offsetSec, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4) * 3, 0xFF00FFFF, true));
			add(buttonUp = createHint(FlxG.width / 2, offsetSec, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4) * 3, 0xFF12FA05, true));
			add(buttonRight = createHint((FlxG.width / 2) + (FlxG.width / 4), offsetSec, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4) * 3,
				0xFFF9393F, true));
			add(buttonExtra = createHint(0, offsetFir, FlxG.width, Std.int(FlxG.height / 4), 0xFF0066FF, true));
		}

		for (button in Reflect.fields(this))
		{
			if (Std.isOfType(Reflect.field(this, button), TouchButton))
				Reflect.setProperty(Reflect.getProperty(this, button), 'IDs', storedButtonsIDs.get(button));
		}

		storedButtonsIDs.clear();
		scrollFactor.set();
		updateTrackedButtons();

		instance = this;
	}

	/**
	 * 屏幕像素 ↔ 游戏坐标的换算（和 FPS 计数器一致）
	 */
	/** [sw, sh, sc, ox, oy] */
	function screenMetrics():Array<Float>
	{
		var sw:Float = 0, sh:Float = 0;
		if (FlxG.stage != null)
		{
			sw = FlxG.stage.stageWidth;
			sh = FlxG.stage.stageHeight;
		}
		if (sw <= 0 || sh <= 0)
		{
			sw = FlxG.width;
			sh = FlxG.height;
		}
		var gw:Float = FlxG.width, gh:Float = FlxG.height;
		if (gw <= 0 || gh <= 0)
			return [sw, sh, 1.0, 0.0, 0.0];
		var sc:Float = Math.min(sw / gw, sh / gh);
		if (sc <= 0) sc = 1.0;
		return [sw, sh, sc, (sw - gw * sc) / 2, (sh - gh * sc) / 2];
	}

	/** 四个区合起来的范围（游戏坐标） */
	function blockGameRect():Array<Float>
	{
		var m = screenMetrics();
		var sw:Float = m[0], sh:Float = m[1], sc:Float = m[2], ox:Float = m[3], oy:Float = m[4];
		switch (Options.hitboxSize)
		{
			case 'window':
				return [0.0, 0.0, FlxG.width * 1.0, FlxG.height * 1.0];
			case 'ratio16x9':
				var h:Float = FlxG.height * 1.0;
				var w:Float = h * 16 / 9;
				return [(FlxG.width * 1.0 - w) / 2, 0.0, w, h];
			default: // fullscreen：铺满整个屏幕（含黑边）
				return [-ox / sc, -oy / sc, sw / sc, sh / sc];
		}
	}

	/** 四个区合起来的范围（舞台像素，给 overlay 用） */
	function blockPxRect(m:Array<Float>):Array<Float>
	{
		var sw:Float = m[0], sh:Float = m[1], sc:Float = m[2], ox:Float = m[3], oy:Float = m[4];
		switch (Options.hitboxSize)
		{
			case 'window':
				return [ox, oy, FlxG.width * sc, FlxG.height * sc];
			case 'ratio16x9':
				var w:Float = sh * 16 / 9;
				return [(sw - w) / 2, 0.0, w, sh];
			default:
				return [0.0, 0.0, sw, sh];
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// 死亡界面时整个触控判定隐藏（图案 + 触摸区域）
		var dead:Bool = (FlxG.state != null && FlxG.state.subState is funkin.game.GameOverSubstate);
		if (dead)
		{
			if (overlay != null) overlay.graphics.clear();
			if (visible) visible = false;
			return;
		}
		if (!visible) visible = true;

		drawOverlay();
	}

	function drawOverlay():Void
	{
		if (overlay == null || overlayButtons.length == 0) return;

		if (Options.hitboxType == 'hidden')
		{
			overlay.graphics.clear();
			return;
		}

		var m = screenMetrics();
		var idleA:Float = FlxMath.bound(Options.hitboxAlphaIdle / 100, 0, 1);
		var pressA:Float = FlxMath.bound(Options.hitboxAlphaPressed / 100, 0, 1);
		var r = blockPxRect(m);
		var rx:Float = r[0], ry:Float = r[1];
		var w:Float = r[2] / 4;

		overlay.graphics.clear();

		// 没按下时只画一个整体区域；按下时只画被按的那一格
		var pressedIndex:Int = -1;
		for (i in 0...overlayButtons.length)
		{
			var b = overlayButtons[i];
			if (b != null && (b.pressed || b.justPressed))
			{
				pressedIndex = i;
				break;
			}
		}

		if (pressedIndex >= 0)
		{
			if (pressA > 0.002)
			{
				overlay.graphics.lineStyle(4, 0xFFFFFF, pressA);
				overlay.graphics.drawRect(rx + w * pressedIndex + 2, ry + 2, w - 4, r[3] - 4);
			}
		}
		else if (idleA > 0.002)
		{
			overlay.graphics.lineStyle(4, 0xFFFFFF, idleA);
			overlay.graphics.drawRect(rx + 2, ry + 2, r[2] - 4, r[3] - 4);
		}
	}

	/**
	 * Clean up memory.
	 */
	override function destroy()
	{
		if (overlay != null)
		{
			if (overlay.parent != null) overlay.parent.removeChild(overlay);
			overlay = null;
		}
		overlayButtons = [];

		super.destroy();
		onButtonUp.destroy();
		onButtonDown.destroy();

		for (fieldName in Reflect.fields(this))
		{
			var field = Reflect.field(this, fieldName);
			if (Std.isOfType(field, TouchButton))
				Reflect.setField(this, fieldName, FlxDestroyUtil.destroy(field));
		}
	}

	public function createHint(X:Float, Y:Float, Width:Int, Height:Int, Color:Int = 0xFFFFFF, ?spriteVisual:Bool = true):TouchButton
	{
		var hint = new TouchButton(X, Y);
		hint.statusAlphas = [];
		hint.statusIndicatorType = NONE;
		hint.loadGraphic(createHintGraphic(Width, Height, spriteVisual));

		if (Options.hitboxType != 'hidden')
		{
			var hintTween:FlxTween = null;

			hint.onDown.callback = function()
			{
				onButtonDown.dispatch(hint);

				if (!spriteVisual)
					return;

				if (hintTween != null)
					hintTween.cancel();

				var targetAlpha:Float = FlxMath.bound(Options.hitboxAlphaPressed / 100, 0, 1);
				hintTween = FlxTween.tween(hint, {alpha: targetAlpha}, 0.08, {
					ease: FlxEase.circInOut,
					onComplete: (twn:FlxTween) -> hintTween = null
				});
			}

			hint.onOut.callback = hint.onUp.callback = function()
			{
				onButtonUp.dispatch(hint);

				if (!spriteVisual)
					return;

				if (hintTween != null)
					hintTween.cancel();

				var idleAlpha:Float = FlxMath.bound(Options.hitboxAlphaIdle / 100, 0, 1);
				hintTween = FlxTween.tween(hint, {alpha: idleAlpha}, 0.08, {
					ease: FlxEase.circInOut,
					onComplete: (twn:FlxTween) -> hintTween = null
				});
			}
		}
		else
		{
			hint.onDown.callback = () -> onButtonDown.dispatch(hint);
			hint.onOut.callback = hint.onUp.callback = () -> onButtonUp.dispatch(hint);
		}

		hint.immovable = hint.multiTouch = true;
		hint.solid = hint.moves = false;
		hint.alpha = spriteVisual ? FlxMath.bound(Options.hitboxAlphaIdle / 100, 0, 1) : 0;
		hint.canChangeLabelAlpha = true;
		hint.antialiasing = Options.antialiasing;
		hint.color = spriteVisual ? Color : 0xFFFFFFFF;
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}

	private function createHintGraphic(Width:Int, Height:Int, ?drawDesign:Bool = true):FlxGraphic
	{
		var w:Int = Std.int(Math.max(Width, 1));
		var h:Int = Std.int(Math.max(Height, 1));
		var bitmap:BitmapData = new BitmapData(w, h, true, 0);

		if (drawDesign)
		{
			// 按 Hit Design 的设定画，再用 color 染成四色
			var shape:Shape = new Shape();
			if (Options.hitboxType == 'noGradient')
			{
				shape.graphics.lineStyle(12, 0xFFFFFF, 1);
				shape.graphics.drawRect(6, 6, w - 12, h - 12);
				shape.graphics.endFill();
			}
			else if (Options.hitboxType == 'noGradientOld')
			{
				shape.graphics.lineStyle(10, 0xFFFFFF, 1);
				shape.graphics.drawRect(5, 5, w - 10, h - 10);
				shape.graphics.endFill();
			}
			else // gradient
			{
				shape.graphics.lineStyle(3, 0xFFFFFF, 1);
				shape.graphics.drawRect(0, 0, w, h);
				shape.graphics.lineStyle(0, 0, 0);
				shape.graphics.drawRect(3, 3, w - 6, h - 6);
				shape.graphics.endFill();
				shape.graphics.beginFill(0xFFFFFF, 0.35);
				shape.graphics.drawRect(3, 3, w - 6, h - 6);
				shape.graphics.endFill();
			}
			bitmap.draw(shape);
		}

		return FlxG.bitmap.add(bitmap);
	}
}
#end
