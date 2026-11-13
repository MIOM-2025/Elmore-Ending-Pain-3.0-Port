import openfl.text.TextFormat;
import flixel.text.FlxTextBorderStyle;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import flixel.text.FlxText.FlxTextFormat;
import flixel.util.FlxAxes;

var ratingGroup:FlxText;
var numberGroup:FlxText;

function create(){
    add(ratingGroup = new FlxText(0, 110, FlxG.width).setFormat(Paths.font("Adult-Swim-Font.ttf"), 53, -1, 'center', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK));
    ratingGroup.borderSize = 3;

    add(numberGroup = new FlxText(0, ratingGroup.y - 60, FlxG.width).setFormat(Paths.font("Adult-Swim-Font.ttf"), 45, -1, 'center', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK));
    numberGroup.borderSize = 3;
    numberGroup.alpha = 0;

    for (groupers in [ratingGroup, numberGroup]){
    groupers.camera = camHUD;
    comboGroup.kill();
    }

    applyScrollLayout();
}

// 居中滚动（Middlescroll）布局：
// 上滚 = 右上角（右边缘贴屏幕右边、上边缘贴屏幕顶），判定在上、连击数字在下，右边缘对齐
// 下滚 = 左下角，判定在上、连击数字在下
function applyScrollLayout() {
    ratingGroup.antialiasing = true;
    numberGroup.antialiasing = true;

    var mid:Bool = Options.middleScroll;
    if (!mid) {
        ratingGroup.alignment = 'center';
        numberGroup.alignment = 'center';
        ratingGroup.fieldWidth = FlxG.width;
        numberGroup.fieldWidth = FlxG.width;
        ratingGroup.x = 0;
        numberGroup.x = 0;
        ratingGroup.y = 110;
        numberGroup.y = ratingGroup.y - 60;
        return;
    }

    var pad:Float = 20;
    var gap:Float = 10;
    ratingGroup.fieldWidth = FlxG.width - pad * 2;
    numberGroup.fieldWidth = FlxG.width - pad * 2;
    ratingGroup.x = pad;
    numberGroup.x = pad;

    if (!Options.downscroll) {
        // 上滚：右上角
        ratingGroup.alignment = 'right';
        numberGroup.alignment = 'right';
        ratingGroup.y = 4;
        numberGroup.y = ratingGroup.y + ratingGroup.height + gap;
    } else {
        // 下滚：左下角
        ratingGroup.alignment = 'left';
        numberGroup.alignment = 'left';
        var totalH:Float = ratingGroup.height + gap + numberGroup.height;
        ratingGroup.y = FlxG.height - totalH - 14;
        numberGroup.y = ratingGroup.y + ratingGroup.height + gap;
    }
}

function update(elapsed:Float){
    applyScrollLayout();
    numberGroup.scale.set(lerp(numberGroup.scale.x, 1.4, 0.25), lerp(numberGroup.scale.y, 1.4, 0.2));
    ratingGroup.scale.set(lerp(ratingGroup.scale.x, 1.4, 0.25), lerp(ratingGroup.scale.y, 1.4, 0.2));
    numberGroup.text = StringTools.lpad(Std.string(combo), '0', 3);
}

function change(rating:String) {
    ratingGroup.text = rating.toUpperCase();
    ratingGroup.alpha = numberGroup.alpha = 1;
    ratingGroup.scale.set(1.6, 1.6);
    numberGroup.scale.set(1.6, 1.6);
    if (!Options.middleScroll) ratingGroup.screenCenter(FlxAxes.X);
    
    for(ratings in [ratingGroup, numberGroup]) {
        FlxTween.cancelTweensOf(ratings);
        FlxTween.tween(ratings, {alpha: 0}, 1, {startDelay: 1});
    }
}

function onPlayerHit(event) {
    if (!event.note.isSustainNote)
        change(event.rating);
}