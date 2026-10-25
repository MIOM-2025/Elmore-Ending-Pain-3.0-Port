import funkin.editors.charter.Charter;
import UndertaleText;
import TypedBitmapText;
import StringTools;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

var canPress:Bool = false;
var deathDialogue:TypedBitmapText;
var camera = new FlxCamera();
var exclude:String = '';
var soul:FlxSprite = new FlxSprite(PlayState.instance.dad.x + 44, PlayState.instance.dad.y + 50).loadGraphic(Paths.image('soul'), true, 20, 16);

// ---------- 菜单变量 ----------
var menuShown:Bool = false;
var menuReady:Bool = false;
var menuTitle:UndertaleText;
var menuYes:UndertaleText;
var menuNo:UndertaleText;
var lastHighlight:Int = -1;
var highlightColor:String = "FFFF00";
var gameOverText:FlxSprite;

function create(e) {
	e.cancel();
	
	FlxG.cameras.add(camera, false);
	camera.bgColor = FlxColor.TRANSPARENT;
	camera.alpha = 0;
	
	var songDeathTheme:String;
	if (PlayState.SONG.meta.customValues != null) {
		songDeathTheme = PlayState.SONG.meta.customValues.deathTheme;
	}
	if (songDeathTheme != null) {
		deathTheme = FlxG.sound.load(Paths.music('deaththemes/' + songDeathTheme), Options.volumeMusic, true);
	} else {
		deathTheme = FlxG.sound.load(Paths.music('deaththemes/basic'), Options.volumeMusic, true);
	}

	gameOverText = new FlxSprite(0, 60).loadGraphic(Paths.image('gameover/gameover'));
	gameOverText.antialiasing = false;
	gameOverText.cameras = [camera];
	gameOverText.scale.set(1.5, 1.5);
	gameOverText.updateHitbox();
	gameOverText.screenCenter(FlxAxes.X);
	add(gameOverText);
	
	var lines:Array<String> = [
		'You cannot give up/just yet...',
		'It cannot end now!',
		'Don\'t lose hope!',
		'You\'re going to/be alright!'
	];
	var determined:String = '<n>!/Stay determined...';
	var full:String = lines[FlxG.random.int(0, lines.length - 1)] + ':' + StringTools.replace(determined, '<n>', FlxG.save.data.playerName);
	
	var fontGetter:UndertaleText = new UndertaleText(0, 0, '', 'left', 0, 0);
	deathDialogue = new TypedBitmapText(398, 476, full, fontGetter.getFont('undertale-pixel'));
	deathDialogue.parentState = this;
	deathDialogue.cameras = [camera];
	deathDialogue.lineOffset = 1278;
	deathDialogue.lineSpacing = 58;
	deathDialogue.setTextFormat(3, 'FFFFFF', fontGetter.getAlignment('left'), FlxG.width);
	add(deathDialogue);
	
	var colors = [
		'determination' => 'FF0000',
		'patience' => '42FCFF',
		'bravery' => 'FCA600',
		'integrity' => '003CFF',
		'perseverance' => 'D535D9',
		'kindness' => '00C000',
		'justice' => 'FFFF00'
	];
	var color:String = FlxG.save.data.soulColor;
	color ??= 'determination';
	var soulColor:String = colors[color];
	
	soul.animation.add('soul', [0, 1], 0);
	soul.animation.play('soul', true);
	soul.antialiasing = false;
	soul.scale.set(0.4, 0.4);
	soul.color = FlxColor.fromString('#' + soulColor);
	soul.updateHitbox();
	add(soul);
	
	PlayState.instance.camFollow.setPosition(soul.getMidpoint().x, soul.getMidpoint().y);
	FlxG.sound.play(Paths.sound('break'), Options.volumeSFX, false, FlxG.sound.defaultSoundGroup, true, function() {
		soul.visible = false;
		var difference:Array<Dynamic> = [[-5, -5], [-5, 0], [-5, 5], [5, -5], [5, 0], [5, 5]];
		for (diff in difference) {
			soulShard(soul.x + diff[0], soul.y + diff[1]);
		}
		FlxG.sound.play(Paths.sound('shatter'), Options.volumeSFX);
		deathTheme.play();
		canPress = true;
		FlxTween.tween(camera, {alpha: 1}, 0.3, {ease: FlxEase.cubeIn, onComplete: function() {
			deathDialogue.startTyping(0.03, 'text-blip', true);
		}});
	});
	soul.animation.curAnim.curFrame = 1;
}

var dropped:Bool = false;
function update(elapsed:Float) {
	if (deathDialogue != null) {
		deathDialogue.textUpdate(elapsed);
	}

	if (menuShown && menuReady) {
		handleMenuInput();
	}

	if (canPress && !menuShown) {
		if (deathDialogue.active) {
			if (controls.ACCEPT || FlxG.mouse.justPressed) {
				deathDialogue.advanceDialogue();
			}
		} else {
			if (controls.ACCEPT || FlxG.mouse.justPressed) {
				hideDialogueThenShowMenu();
			}
		}
	}
}

function soulShard(s_x, s_y) {
	var shard:FlxSprite = new FlxSprite(s_x, s_y).loadGraphic(Paths.image('shard'), true, 7, 8);
	shard.antialiasing = false;
	shard.color = soul.color;
	shard.animation.add('anim', [0, 1, 2, 3], 8);
	shard.animation.play('anim', true);
	shard.scale.set(soul.scale.x, soul.scale.y);
	shard.velocity.set(FlxG.random.int(200, -250, exclude), FlxG.random.int(200, -250, exclude));
	shard.acceleration.y = 600;
	add(shard);
}

function hideDialogueThenShowMenu() {
	if (menuShown) return;
	canPress = false;

	if (deathDialogue != null) {
		FlxTween.tween(deathDialogue, {alpha: 0}, 0.4, {
			ease: FlxEase.cubeIn,
			onComplete: function(_) {
				deathDialogue.visible = false;
				if (deathDialogue.lines != null) {
					for (line in deathDialogue.lines) {
						line.visible = false;
					}
				}
				showMenu();
			}
		});
	} else {
		showMenu();
	}
}

function showMenu() {
	menuShown = true;

	var titleScale:Float = 4.0;
	var optionScale:Float = 3.6;
	var fontName:String = "undertale-pixel";
	var textColor:String = "FFFFFF";

	menuTitle = new UndertaleText(0, Math.round(FlxG.height * 0.6), "Return?", "center", FlxG.width, titleScale, textColor, fontName);
	menuTitle.cameras = [camera];
	add(menuTitle);

	new FlxTimer().start(0.5, function(_) {
		var centerX = menuTitle.x + menuTitle.width / 2;
		var yPos = menuTitle.y + 160;
		var spacing = 150;
		// 修改：宽度改为125，高度强制设为75
		menuYes = new UndertaleText(0, Math.round(yPos), "Yes", "center", 125, optionScale, textColor, fontName);
		menuYes.height = 75;                       // 强制高度75
		menuYes.x = centerX - spacing - 125 / 2;   // 用新宽度重新计算水平位置
		menuYes.cameras = [camera];
		add(menuYes);
	});

	new FlxTimer().start(1.0, function(_) {
		var centerX = menuTitle.x + menuTitle.width / 2;
		var yPos = menuTitle.y + 160;
		var spacing = 150;
		// 修改：宽度改为125，高度强制设为75
		menuNo = new UndertaleText(0, Math.round(yPos), "No", "center", 125, optionScale, textColor, fontName);
		menuNo.height = 75;                        // 强制高度75
		menuNo.x = centerX + spacing - 125 / 2;    // 用新宽度重新计算水平位置
		menuNo.cameras = [camera];
		add(menuNo);
		menuReady = true;
		canPress = true;
		lastHighlight = -1;
	});
}

function handleMenuInput() {
	if (!menuReady) return;
	var items:Array<UndertaleText> = [menuYes, menuNo];
	var mousePoint:FlxPoint = FlxG.mouse.getWorldPosition(camera);
	var highlightedIndex:Int = -1;

	for (i in 0...items.length) {
		var item = items[i];
		if (item == null) continue;
		if (item.visible && item.overlapsPoint(mousePoint, true, camera)) {
			highlightedIndex = i;
			break;
		}
	}

	if (highlightedIndex != lastHighlight) {
		if (highlightedIndex != -1) {
			FlxG.sound.play(Paths.sound('squeak'), Options.volumeSFX);
		}
		if (lastHighlight != -1 && items[lastHighlight] != null) {
			items[lastHighlight].color = FlxColor.WHITE;
		}
		if (highlightedIndex != -1 && items[highlightedIndex] != null) {
			items[highlightedIndex].color = FlxColor.fromString('#' + highlightColor);
		}
		lastHighlight = highlightedIndex;
	}

	if (FlxG.mouse.justReleased && highlightedIndex != -1) {
		FlxG.sound.play(Paths.sound('select'), Options.volumeSFX);
		if (highlightedIndex == 0) {
			endScreen(false);
		} else {
			endScreen(true);
		}
	}
}

function endScreen(exiting:Bool) {
	canPress = false;
	deathTheme.fadeOut(0.5, 0);
	camera.fade(FlxColor.BLACK, 1, false, function() {
		if (!exiting) {
			FlxG.switchState(new PlayState());
		} else {
			if (PlayState.chartingMode && Charter.undos.unsaved) {
				game.saveWarn(false);
			} else {
				if (Charter.instance != null) Charter.instance.__clearStatics();
				if (FlxG.sound.music != null) FlxG.sound.music.stop();
				FlxG.sound.music = null;
				FlxG.switchState(PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());
			}
		}
	});
}