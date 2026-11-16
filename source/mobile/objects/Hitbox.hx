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
 * 4 个触摸区铺满整个屏幕（含 4:3 画面两边的留黑），
 * 画面里的花哨渐变改成屏幕级的纯白描边（不透明度 0.1，只在按下时出现）。
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

	// 铺满屏幕的图案（画在舞台层，和 FPS 计数器同一层）
	var overlay:Shape = null;
	var overlayButtons:Array<TouchButton> = [];

	/**
	 * Create the zone.
	 */
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
			// 四等分整个屏幕（不是 4:3 画布）：上下贴屏幕上下边缘
			var m = screenMetrics();
			var zx:Float = -m.ox / m.sc;
			var zy:Float = -m.oy / m.sc;
			var zw:Float = m.sw / m.sc / 4;
			var zh:Float = m.sh / m.sc;

			buttonLeft = createHint(zx, zy, Std.int(zw), Std.int(zh), 0xFFFFFFFF, false);
			buttonDown = createHint(zx + zw, zy, Std.int(zw), Std.int(zh), 0xFFFFFFFF, false);
			buttonUp = createHint(zx + zw * 2, zy, Std.int(zw), Std.int(zh), 0xFFFFFFFF, false);
			buttonRight = createHint(zx + zw * 3, zy, Std.int(zw), Std.int(zh), 0xFFFFFFFF, false);

			add(buttonLeft);
			add(buttonDown);
			add(buttonUp);
			add(buttonRight);

			overlayButtons = [buttonLeft, buttonDown, buttonUp, buttonRight];

			overlay = new Shape();
			if (Main.instance != null)
				Main.instance.addChild(overlay);
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

	/** 屏幕像素 ↔ 游戏坐标的换算（和 FPS 计数器一致） */
	function screenMetrics():{sw:Float, sh:Float, sc:Float, ox:Float, oy:Float}
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
			return {sw: sw, sh: sh, sc: 1, ox: 0, oy: 0};
		var sc:Float = Math.min(sw / gw, sh / gh);
		if (sc <= 0) sc = 1;
		return {sw: sw, sh: sh, sc: sc, ox: (sw - gw * sc) / 2, oy: (sh - gh * sc) / 2};
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
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
		var target:Float = FlxMath.bound(Options.hitboxAlpha / 100, 0.1, 1);
		var w:Float = m.sw / 4;

		overlay.graphics.clear();
		for (i in 0...overlayButtons.length)
		{
			var b = overlayButtons[i];
			if (b == null || !(b.pressed || b.justPressed)) continue;
			overlay.graphics.lineStyle(4, 0xFFFFFF, target);
			overlay.graphics.drawRect(w * i + 2, 2, w - 4, m.sh - 4);
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

				var targetAlpha:Float = FlxMath.bound(Options.hitboxAlpha / 100, 0.1, 1);
				hintTween = FlxTween.tween(hint, {alpha: targetAlpha}, targetAlpha / 100, {
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

				hintTween = FlxTween.tween(hint, {alpha: 0.00001}, (Options.hitboxAlpha / 100) / 10, {
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
		hint.alpha = spriteVisual ? 0.00001 : 0;
		hint.canChangeLabelAlpha = true;
		hint.antialiasing = Options.antialiasing;
		hint.color = 0xFFFFFFFF;
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}

	private function createHintGraphic(Width:Int, Height:Int, ?drawBorder:Bool = true):FlxGraphic
	{
		var w:Int = Std.int(Math.max(Width, 1));
		var h:Int = Std.int(Math.max(Height, 1));
		var bitmap:BitmapData = new BitmapData(w, h, true, 0);

		if (drawBorder)
		{
			var shape:Shape = new Shape();
			var border:Float = 4;
			shape.graphics.lineStyle(border, 0xFFFFFF, 1);
			shape.graphics.drawRect(border / 2, border / 2, w - border, h - border);
			bitmap.draw(shape);
		}

		return FlxG.bitmap.add(bitmap);
	}
}
#end
