package funkin.options;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;
import flixel.util.FlxSignal;
import funkin.backend.system.Controls;
import funkin.backend.TurboControls;
import funkin.options.TreeMenu.ITreeOption;
import funkin.options.TreeMenu.ITreeFloatOption;
import funkin.options.type.OptionType;
import funkin.options.type.Separator;
#if TOUCH_CONTROLS
import mobile.funkin.backend.utils.OptionTouch;
#end

class TreeMenuScreen extends FlxSpriteGroup {
	public var persistentUpdate:Bool = false;
	public var persistentDraw:Bool = false;

	public var onClose:FlxSignal = new FlxSignal();

	public var parent:TreeMenu;
	public var transitioning:Bool = false;
	public var inputEnabled:Bool = false;
	public var curSelected:Int = 0;

	public var name:String;
	public var desc:String;
	public var prevMenuTPadModes:Array<String> = [];
	/**
	 * The prefix to add to the translations ids.
	**/
	public var prefix:String = "";

	private var rawName(default, set):String;
	private var rawDesc(default, set):String;

	function set_rawName(v:String) {
		rawName = v;
		name = TU.exists(v) ? TU.translate(v) : v;
		return v;
	}

	function set_rawDesc(v:String) {
		rawDesc = v;
		desc = TU.exists(v) ? TU.translate(v) : v;
		return v;
	}

	public inline function getNameID(name):String return prefix + name + "-name";
	public inline function getDescID(name):String return prefix + name + "-desc";
	public inline function getID(name):String return prefix + name;
	public function translate(name:String, ?args:Array<Dynamic>):String return TU.translate(getID(name), args);

	public var controls(get, never):Controls;
	inline function get_controls():Controls return PlayerSettings.solo.controls;

	var leftTurboControl:TurboControls = new TurboControls([Control.LEFT], 0.2, 1 / 48);
	var rightTurboControl:TurboControls = new TurboControls([Control.RIGHT], 0.2, 1 / 48);
	var upTurboControl:TurboControls = new TurboControls([Control.UP]);
	var downTurboControl:TurboControls = new TurboControls([Control.DOWN]);
	var turboBasics:Array<TurboBasic>;

	var curOption:ITreeOption;
	var curFloatOption:ITreeFloatOption;
	var __firstFrame:Bool = true;

	public var dragging:Bool = false;
	#if TOUCH_CONTROLS
	var dragStartY:Float = 0;
	var dragStartSelected:Int = 0;
	var dragLastY:Float = 0;
	var dragMoved:Bool = false;
	var dragVel:Array<Float> = [];
	var listInertia:FlxTimer = null;
	var ownsTouchPad:Bool = false;
	#end

	public function new(name:String, desc:String, ?prefix:String, ?objects:Array<FlxSprite>, ?menuTPadModes:Array<String>) {
		super();
		this.prefix = prefix;
		rawName = name;
		rawDesc = desc;

		turboBasics = [leftTurboControl, rightTurboControl, upTurboControl, downTurboControl];

		#if TOUCH_CONTROLS
		OptionTouch.init();
		#end
		
		#if TOUCH_CONTROLS
		if (menuTPadModes != null)
		{
			final state = MusicBeatState.getState();
			// 设置界面本身不再挂 TouchPad，所以这里可能没有 pad 可换
			if (state.touchPad != null)
			{
				this.prevMenuTPadModes = [state.touchPad.curDPadMode, state.touchPad.curActionMode];
				state.removeTouchPad();
			}
			else ownsTouchPad = true;

			state.addTouchPad(menuTPadModes[0], menuTPadModes[1]);
			state.addTouchPadCamera();
		}
		#end

		if (objects != null) for (object in objects) add(object);
	}

	public function reloadStrings() {
		rawName = rawName;
		rawDesc = rawDesc;

		for (object in members) if (object != null && object is OptionType) cast(object, OptionType).reloadStrings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (__firstFrame) {
			__firstFrame = false;
			if (members[curSelected] is ITreeOption) {
				(curOption = cast members[curSelected]).selected = true;
				if (curOption is ITreeFloatOption) curFloatOption = cast curOption;
			}
			updateItems(true);
			return;
		}

		if (inputEnabled) {
			for (basic in turboBasics) basic.update(elapsed);

			#if TOUCH_CONTROLS
			// 手指按住列表往上/下拖 = 列表跟着滚（带惯性）
			updateListDrag(elapsed);
			#end

			var change = (upTurboControl.activated ? -1 : 0) + (downTurboControl.activated ? 1 : 0) - FlxG.mouse.wheel, mouseControl = false;
			if (!dragging) changeSelection(change);

			if (length > 0 && curOption != null && !dragging) {
				if (controls.ACCEPT) curOption.select();

				var goLeft:Bool = controls.LEFT, goRight:Bool = controls.RIGHT;
				#if TOUCH_CONTROLS
				// 左右滑 = 改值 / 切换（只影响设置界面）
				goLeft = goLeft || OptionTouch.swipeLeft;
				goRight = goRight || OptionTouch.swipeRight;
				#end
				if (curFloatOption != null) {
					if (goLeft) curFloatOption.changeValue(-(controls.LEFT ? elapsed : 1));
					if (goRight) curFloatOption.changeValue(controls.RIGHT ? elapsed : 1);
				}
				else {
					if (leftTurboControl.activated || goLeft) curOption.changeSelection(-1);
					if (rightTurboControl.activated || goRight) curOption.changeSelection(1);
				}
			}

			if (controls.BACK || (FlxG.mouse.justPressedRight && Main.timeSinceFocus > 0.3)) close();
		}

		updateItems();
	}

	public function updateItems(force = false) {
		var r = force ? 1 : 0.25, initY = FlxG.height * 0.5;
		var i = curSelected, y = initY, object:FlxSprite = null, itemHeight:Float = 0;

		inline function updateItem() {
			object.y = CoolUtil.fpsLerp(object.y, y - itemHeight * 0.5, r);
			object.x = x + 100 - Math.pow(Math.abs((object.y - (FlxG.height - itemHeight) * 0.5) / itemHeight / FlxG.height * FlxG.initialHeight), 1.6) * 15;
		}

		while (i < length) if ((object = members[i++]) != null) {
			itemHeight = object.height;
			updateItem();
			y += itemHeight;
		}

		y = initY;
		i = curSelected;
		while (i-- > 0) if ((object = members[i]) != null) {
			y -= (itemHeight = object.height);
			updateItem();
		}
	}

	#if TOUCH_CONTROLS
	/**
	 * 按住列表上下拖：列表跟着滚；松手带惯性；
	 * 轻点某一项 = 直接跳到选中它；点当前项 = 确认/切换。
	 * 在返回键上按下不会触发拖动。
	 */
	function updateListDrag(elapsed:Float):Void
	{
		if (length == 0) return;

		var backHeld:Bool = parent != null && parent.backButton != null && parent.backButton.exists
			&& OptionTouch.pressingOn(parent.backButton);

		if (!dragging && OptionTouch.justPressedNow && !backHeld)
		{
			dragging = true;
			dragMoved = false;
			dragStartY = OptionTouch.pointerY;
			dragLastY = dragStartY;
			dragStartSelected = curSelected;
			dragVel = [];
			if (listInertia != null)
			{
				listInertia.cancel();
				listInertia = null;
			}
		}

		if (!dragging) return;

		if (OptionTouch.holding)
		{
			var dy:Float = OptionTouch.pointerY - dragStartY;
			if (Math.abs(dy) > 6) dragMoved = true;

			if (dragMoved)
			{
				var itemH:Float = 64;
				if (curSelected >= 0 && curSelected < length && members[curSelected] != null && members[curSelected].height > 8)
					itemH = members[curSelected].height;

				// 往上拖 = 列表往上滚 = 选中项往后走
				// 灵敏度：默认 1 项 ≈ 0.55 个选项高度，滑起来更省力
				var raw:Float = dragStartSelected - dy / (itemH * 0.55);
				var target:Int = Std.int(FlxMath.bound(Math.round(raw), 0, length - 1));
				if (target != curSelected) setSelected(target, false);
			}

			var v:Float = (OptionTouch.pointerY - dragLastY) / Math.max(elapsed, 0.001);
			dragLastY = OptionTouch.pointerY;
			dragVel.push(v);
			if (dragVel.length > 8) dragVel.shift();
		}

		if (OptionTouch.releasedNow)
		{
			dragging = false;

			if (!dragMoved)
			{
				var idx:Int = itemAtScreenY(OptionTouch.pointerY);
				if (idx >= 0)
				{
					if (idx == curSelected)
					{
						if (curOption != null) curOption.select();
					}
					else setSelected(idx, true);
				}
			}
			else
			{
				var avg:Float = 0;
				for (v in dragVel) avg += v;
				if (dragVel.length > 0) avg /= dragVel.length;

				if (Math.abs(avg) > 35) startListInertia(avg < 0 ? 1 : -1, Math.abs(avg));
			}

			dragVel = [];
		}
	}

	/** 松手后按速度再滚 1~3 格，到头就停（不循环） */
	function startListInertia(dir:Int, speed:Float):Void
	{
		var steps:Int = Std.int(FlxMath.bound(Math.floor(speed / 200), 1, 4));
		if (listInertia != null) listInertia.cancel();
		listInertia = new FlxTimer().start(0.06, function(t:FlxTimer) {
			var next:Int = curSelected + dir;
			if (next < 0 || next >= length)
			{
				t.cancel();
				listInertia = null;
				return;
			}
			setSelected(next, false);
			if (--steps <= 0)
			{
				t.cancel();
				listInertia = null;
			}
		}, 0);
	}

	function itemAtScreenY(y:Float):Int
	{
		for (i in 0...length)
		{
			var m:FlxSprite = members[i];
			if (m == null || !m.exists) continue;
			var pos = m.getScreenPosition(null, FlxG.camera);
			var hit:Bool = y >= pos.y && y <= pos.y + m.height;
			pos.put();
			if (hit) return i;
		}
		return -1;
	}
	#end

	public function close() {
		onClose.dispatch();

		if (curOption != null) curOption.selected = false;

		if (parent == null) return destroy();
		else parent.removeMenu(this);

		CoolUtil.playMenuSFX(CANCEL).persist = true;
		
		#if TOUCH_CONTROLS
		if (prevMenuTPadModes.length > 0)
		{
			final state = MusicBeatState.getState();
			state.removeTouchPad();

			state.addTouchPad(prevMenuTPadModes[0], prevMenuTPadModes[1]);
			state.addTouchPadCamera();
		}
		else if (ownsTouchPad)
		{
			ownsTouchPad = false;
			MusicBeatState.getState().removeTouchPad();
		}
		#end
	}

	/**
	 * 直接选中某一项（拖动/点击用）。到边界就停，不循环；
	 * 选到分隔符会就近挪到旁边可选项。
	 */
	public function setSelected(index:Int, playSFX:Bool = true):Void {
		if (length == 0) return;

		index = Std.int(FlxMath.bound(index, 0, length - 1));

		if (members[index] is Separator) {
			var found:Int = -1;
			for (d in 1...length) {
				var a:Int = index - d, b:Int = index + d;
				if (a >= 0 && !(members[a] is Separator)) { found = a; break; }
				if (b < length && !(members[b] is Separator)) { found = b; break; }
			}
			if (found < 0) return;
			index = found;
		}

		if (index == curSelected) return;
		curSelected = index;

		if (curOption != null) curOption.selected = false;
		if (members[curSelected] is ITreeOption) {
			(curOption = cast members[curSelected]).selected = true;
			if (curOption is ITreeFloatOption) curFloatOption = cast curOption;
			else curFloatOption = null;
		}
		else {
			curOption = null;
			curFloatOption = null;
		}
		updateMenuDesc();

		if (playSFX) CoolUtil.playMenuSFX(SCROLL);
	}

	public function changeSelection(change:Int, force:Bool = false) {
		if (length == 0 || (change == 0 && !force)) return;

		var prevSelect = curSelected = FlxMath.wrap(curSelected + change, 0, members.length - 1);
		while (members[curSelected] is Separator)
			if ((curSelected = FlxMath.wrap(curSelected + (change > 0 ? 1 : -1), 0, members.length - 1)) == prevSelect) break;

		if (curOption != null) curOption.selected = false;
		if (members[curSelected] is ITreeOption) {
			(curOption = cast members[curSelected]).selected = true;
			if (curOption is ITreeFloatOption) curFloatOption = cast curOption;
			else curFloatOption = null;
		}
		else {
			curOption = null;
			curFloatOption = null;
		}
		updateMenuDesc();

		CoolUtil.playMenuSFX(SCROLL);
	}

	public function updateMenuDesc(?customTxt:String) {
		if (parent != null) parent.updateDesc(customTxt);
	}

	function mouseOverlaps(sprite:FlxSprite):Bool
		return sprite.overlapsPoint(FlxG.mouse.getPosition(@:privateAccess flixel.input.FlxPointer._cachedPoint), true);

	override function destroy() {
		super.destroy();
		for (basic in turboBasics) basic.destroy();
	}
}