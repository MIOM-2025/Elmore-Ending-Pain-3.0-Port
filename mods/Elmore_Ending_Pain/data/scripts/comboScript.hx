import flixel.text.FlxTextBorderStyle;

var ratingGroup:FlxText;
var numberGroup:FlxText;
var fadeTimer:Float = 0;

// 判定/连击文字：不用 alignment，全部靠算 x 定位，宽度随文本自适应。
function create() {
	ratingGroup = new FlxText(0, 0, 0, "", 53);
	ratingGroup.setFormat(Paths.font("Adult-Swim-Font.ttf"), 53, -1, "left", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	ratingGroup.borderSize = 3;
	ratingGroup.antialiasing = true;
	ratingGroup.visible = false;
	add(ratingGroup);

	numberGroup = new FlxText(0, 0, 0, "", 45);
	numberGroup.setFormat(Paths.font("Adult-Swim-Font.ttf"), 45, -1, "left", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	numberGroup.borderSize = 3;
	numberGroup.antialiasing = true;
	numberGroup.visible = false;
	add(numberGroup);

	ratingGroup.camera = camHUD;
	numberGroup.camera = camHUD;

	if (comboGroup != null) comboGroup.kill();

	// 居中模式下开局先亮 2 秒，用来确认位置/字号（同时验证脚本是否真的在跑）
	if (Options.middleScroll) {
		ratingGroup.text = "PERFECT";
		numberGroup.text = "000";
		ratingGroup.visible = true;
		numberGroup.visible = true;
		ratingGroup.alpha = numberGroup.alpha = 1;
		fadeTimer = 3.0;
	}
	layout();
}

// 上滚 + 居中：判定贴右上角，连击数字在判定下方并对齐右边缘
// 下滚 + 居中：判定贴左下角，连击数字在判定下方
// 非居中：保持原来的屏幕中上方居中
function layout() {
	var pad:Float = 20;
	var gap:Float = 6;

	var rw:Float = sizeW(ratingGroup);
	var rh:Float = sizeH(ratingGroup);
	var nw:Float = sizeW(numberGroup);
	var nh:Float = sizeH(numberGroup);

	if (!Options.middleScroll) {
		ratingGroup.x = Math.round((FlxG.width - rw) * 0.5);
		ratingGroup.y = 110;
		numberGroup.x = Math.round((FlxG.width - nw) * 0.5);
		numberGroup.y = ratingGroup.y - nh - gap;
	} else if (!Options.downscroll) {
		ratingGroup.x = FlxG.width - rw - pad;
		ratingGroup.y = 4;
		numberGroup.x = FlxG.width - nw - pad;
		numberGroup.y = ratingGroup.y + rh + gap;
	} else {
		var totalH:Float = rh + gap + nh;
		ratingGroup.x = pad;
		ratingGroup.y = FlxG.height - totalH - 14;
		numberGroup.x = pad;
		numberGroup.y = ratingGroup.y + rh + gap;
	}
}

// 文本实际显示尺寸（含缩放），不依赖 updateHitbox
function sizeW(t:FlxText):Float {
	var w:Float = t.width;
	if (w <= 1) w = 10;
	return w;
}

function sizeH(t:FlxText):Float {
	var h:Float = t.height;
	if (h <= 1) h = 10;
	return h;
}

function update(elapsed:Float) {
	if (fadeTimer > 0) {
		fadeTimer -= elapsed;
		if (fadeTimer <= 0) {
			ratingGroup.visible = numberGroup.visible = false;
		} else if (fadeTimer < 1) {
			ratingGroup.alpha = numberGroup.alpha = fadeTimer;
		} else {
			ratingGroup.alpha = numberGroup.alpha = 1;
		}
	}

	ratingGroup.scale.set(FlxMath.lerp(ratingGroup.scale.x, 1.4, 0.2), FlxMath.lerp(ratingGroup.scale.y, 1.4, 0.2));
	numberGroup.scale.set(FlxMath.lerp(numberGroup.scale.x, 1.4, 0.2), FlxMath.lerp(numberGroup.scale.y, 1.4, 0.2));

	numberGroup.text = StringTools.lpad(Std.string(combo), '0', 3);

	layout();
}

function change(rating:String) {
	ratingGroup.text = rating.toUpperCase();
	ratingGroup.visible = numberGroup.visible = true;
	ratingGroup.alpha = numberGroup.alpha = 1;
	ratingGroup.scale.set(1.6, 1.6);
	numberGroup.scale.set(1.6, 1.6);
	fadeTimer = 2.0;
	layout();
}

function onPlayerHit(event) {
	if (!event.note.isSustainNote)
		change(event.rating);
}
