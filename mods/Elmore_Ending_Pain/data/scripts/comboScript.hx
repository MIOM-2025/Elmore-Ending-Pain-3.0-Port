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
}

function update(elapsed:Float){
    numberGroup.scale.set(lerp(numberGroup.scale.x, 1.4, 0.25), lerp(numberGroup.scale.y, 1.4, 0.2));
    ratingGroup.scale.set(lerp(ratingGroup.scale.x, 1.4, 0.25), lerp(ratingGroup.scale.y, 1.4, 0.2));
    numberGroup.text = StringTools.lpad(Std.string(combo), '0', 3);
}

function change(rating:String) {
    ratingGroup.text = rating.toUpperCase();
    ratingGroup.alpha = numberGroup.alpha = 1;
    ratingGroup.scale.set(1.6, 1.6);
    numberGroup.scale.set(1.6, 1.6);
    ratingGroup.screenCenter(FlxAxes.X);
    
    for(ratings in [ratingGroup, numberGroup]) {
        FlxTween.cancelTweensOf(ratings);
        FlxTween.tween(ratings, {alpha: 0}, 1, {startDelay: 1});
    }
}

function onPlayerHit(event) {
    if (!event.note.isSustainNote)
        change(event.rating);
}