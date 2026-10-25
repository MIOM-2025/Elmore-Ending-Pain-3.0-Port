import funkin.backend.utils.WindowUtils;
import funkin.backend.system.framerate.Framerate;
import openfl.text.TextFormat;
import openfl.text.TextField;
import funkin.backend.MusicBeatTransition;
import funkin.backend.utils.DiscordUtil;
import funkin.game.GameOverSubstate;
import openfl.Lib;
import openfl.display.Sprite;
import Sys;
import funkin.backend.MusicBeatState;
import openfl.Lib;
import funkin.backend.utils.NativeAPI;
import flixel.util.FlxColor;
import flixel.group.FlxTypedSpriteGroup;

function new() {
    boxSolidSprite = new Sprite();
    boxSolidSprite.graphics.beginFill(0x00000000);
	boxSolidSprite.graphics.drawRect(0, 0, 100, 100);
	boxSolidSprite.graphics.endFill();
	boxSolidSprite.alpha = 0.5;
	boxSolidSprite.visible = !FlxG.save.data.EEPvfpsCounter;
	Main.instance.addChild(boxSolidSprite);

    fpsText = new TextField();
	fpsText.defaultTextFormat = new TextFormat(Paths.getFontName(Paths.font('fpsCounter.ttf')), 24, 0xffffff);
	fpsText.height = 40;
	fpsText.selectable = false;
	fpsText.visible = !FlxG.save.data.EEPvfpsCounter;
	Main.instance.addChild(fpsText);

	updatePosition();
}

function updatePosition() {
	var stage = Lib.current.stage;
	if (stage == null) return;

	// 计算游戏视口在窗口中的偏移（黑边尺寸）
	var stageW:Float = stage.stageWidth;
	var stageH:Float = stage.stageHeight;
	var gameW:Float = FlxG.width;
	var gameH:Float = FlxG.height;

	var scale:Float = Math.min(stageW / gameW, stageH / gameH);
	var offsetX:Float = (stageW - gameW * scale) / 2;
	var offsetY:Float = (stageH - gameH * scale) / 2;

	boxSolidSprite.x = offsetX;
	boxSolidSprite.y = offsetY;
	fpsText.x = offsetX + 3;
	fpsText.y = offsetY + 4;
}

function preStateSwitch() {
    Framerate.instance.visible = false;
}

function update(elapsed) {
	updatePosition();

    fpsText.text = "FPS: " + Framerate.fpsCounter.fpsNum.text + " ~ " + "MEM: " + Framerate.memoryCounter.memoryText.text + Framerate.memoryCounter.memoryPeakText.text;
    fpsText.setTextFormat(fpsText.defaultTextFormat);
	fpsText.width = fpsText.textWidth + 15;
    setScaleSize(fpsText.width - 4, fpsText.height - 10);
}

function setScaleSize(width, height) {
	boxSolidSprite.graphics.clear();
	boxSolidSprite.graphics.beginFill(0x242424);
	boxSolidSprite.graphics.drawRect(0, 0, width, height);
	boxSolidSprite.graphics.endFill();
}

function destroy() {
	Framerate.instance.visible = true;

	Main.instance.removeChild(boxSolidSprite);
	Main.instance.removeChild(fpsText);
}