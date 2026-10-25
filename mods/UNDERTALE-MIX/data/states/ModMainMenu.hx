import funkin.backend.system.Flags;
import funkin.backend.utils.DiscordUtil;
import funkin.options.OptionsMenu;
import funkin.backend.system.Controls.Control;
import funkin.options.Options;
import haxe.Date;

import flixel.util.FlxStringUtil;
import flixel.input.mouse.FlxMouseEvent;
import flixel.input.mouse.FlxMouseEventManager;
import funkin.menus.ModSwitchMenu;

import funkin.editors.ui.UIState;

import UndertaleText;
import Sys;

var name:UndertaleText;
var accuracy:UndertaleText;
var time:UndertaleText;

var camera:FlxCamera = new FlxCamera();
var c_e:FlxCamera = new FlxCamera();

var menuObjects:Array<Dynamic> = [];
var menuOptions:Array<String> = [
	'Story Mode',
	'Freeplay',
	'Credits',
	'Options',
];
var menuChar:FlxSprite;
var bg:FlxSprite;
var storyModeButton:UndertaleText;
var buttonScale:Int = 3;
var curSelected:Int = 0;
var objectDistance:Int = 16;
var nameSelected:Bool = false;
var optionSelected:Bool = false;
var weirdName:Bool = false;

// ========== 模式管理 ==========
var inputMode:String = "keyboard";
var hoveredObject:UndertaleText = null;
var canInteract:Bool = false;

var originalX:Array<Float> = [];

// ========== 系统时间辅助函数 ==========
function getSystemTimeString():String {
	var now:Date = Date.now();
	var h:Int = now.getHours();
	var m:Int = now.getMinutes();
	var s:Int = now.getSeconds();
	return (h < 10 ? '0' : '') + h + ':' + (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s;
}

function create() {
	DiscordUtil.changePresenceAdvanced({
		details: 'In the Main Menu',
	});
	
	if (FlxG.sound.music == null || (data != null && data == 'startup')) {
		FlxG.sound.playMusic(Paths.music('menuthemes/mainmenu'), Options.volumeMusic, true);
		Conductor.bpm = 128.0;
	}
	
	if (FlxG.save.data.playerName != null) {
		weirdName = FlxG.save.data.playerName.length > 6;
	}
	
	if (FlxG.save.data.pong_unlock != null || FlxG.save.data.run_unlock != null) {
		menuOptions.push('Minigames');
	}

	FlxG.cameras.add(camera, false);
	camera.bgColor = FlxColor.TRANSPARENT;
	camera.zoom = 3;
	camera.antialiasing = false;
	this.cameras = [camera];
	
	FlxG.cameras.add(c_e, false);
	c_e.bgColor = FlxColor.TRANSPARENT;
	c_e.antialiasing = false;
	
	bg = new FlxSprite().loadGraphic(Paths.image('title/ruinsbg'));
	bg.screenCenter();
	bg.setPosition(bg.x + 70, bg.y - 30);
	add(bg);
	
	menuChar = new FlxSprite(bg.x + 60, bg.y + 190);
	menuChar.frames = Paths.getAsepriteAtlas('title/mainmenucharacters/bf-mainmenu');
	menuChar.animation.addByPrefix('s', 'selecting', 8, true);
	menuChar.animation.addByPrefix('d', 'selected', 8, false);
	menuChar.animation.play('s', true);
	add(menuChar);
	
	name = new UndertaleText(bg.x + 28, bg.y + 101, (FlxG.save.data.playerName != null ? FlxG.save.data.playerName : 'Unknown'), 'left', FlxG.width, 1, 'FFFFFF', 'undertale-pixel');
	name.text = name.text + (weirdName ? '\nNot that easy to change?' : '');
	add(name);
	
	// ========== 时间文本：显示当前系统时间 ==========
	var initTimeString:String = getSystemTimeString();
	time = new UndertaleText(name.x + 71, name.y + (weirdName ? 34 : 0), initTimeString, 'left', FlxG.width, 1, 'FFFFFF', 'undertale-pixel');
	add(time);
	
	var mapLength:Int = 0;
	var foundAcc = FlxG.save.data.savedAcc;
	accuracy = new UndertaleText(name.x, name.y + 34, 'Avg. Acc\n%0.0', 'left', FlxG.width, 1, 'FFFFFF', 'undertale-pixel');
	if (foundAcc != null) {
		var sum:Float = 0;
		for (key in foundAcc) {
			sum += key;
			mapLength++;
		}
		var acc:Float = floorDecimal((sum / mapLength) * 100, 2);
		if (acc > 0) {
			accuracy.text = 'Avg. Acc\n%' + acc;
		}
	}
	add(accuracy);

	// ---------- 创建菜单选项 ----------
	var total = menuOptions.length;
	var baseY = FlxG.height / 2 - 20;
	var baseX:Float = 480;
	
	for (i in 0...total) {
		var menu = menuOptions[i];
		var option:UndertaleText = new UndertaleText(baseX, 0, menu.toLowerCase(), 'left', FlxG.width, 1, 'FFFFFF', 'wonder');
		var initialY = baseY + (i - (total - 1) / 2) * objectDistance;
		option.y = initialY;
		option.ID = i;
		if (menu.toLowerCase() == 'story mode') {
			option.fieldWidth = 160;
		} else {
			option.fieldWidth = 120;
		}
		option.updateHitbox();
		add(option);
		originalX.push(baseX);
		menuObjects.push([option, initialY, i, baseX]);
		if (menu.toLowerCase() == 'story mode') {
			storyModeButton = option;
		}
	}
	
	// ---------- 初始模式设置 ----------
	#if mobile
		inputMode = "touch";
	#else
		inputMode = "keyboard";
	#end
	initializeMode();
	
	switch(data) {
		case 'freeplay':
			camera.x = -500;
			camera.alpha = 0;
			FlxTween.tween(camera, {x: 0}, transitionTime, {ease: FlxEase.cubeInOut});
			FlxTween.tween(camera, {alpha: 1}, transitionTime, {ease: FlxEase.cubeInOut, onComplete: function(twn) {
				canInteract = true;
			}});
		case 'options':
			camera.y = -500;
			camera.alpha = 0;
			FlxTween.tween(camera, {y: 0}, transitionTime, {ease: FlxEase.cubeInOut});
			FlxTween.tween(camera, {alpha: 1}, transitionTime, {ease: FlxEase.cubeInOut, onComplete: function(twn) {
				canInteract = true;
			}});
		case 'credits':
			camera.x = 500;
			camera.alpha = 0;
			FlxTween.tween(camera, {x: 0}, transitionTime, {ease: FlxEase.cubeInOut});
			FlxTween.tween(camera, {alpha: 1}, transitionTime, {ease: FlxEase.cubeInOut, onComplete: function(twn) {
				canInteract = true;
			}});
		case 'minigames':
			camera.zoom *= 6;
			camera.alpha = 0;
			FlxTween.tween(camera, {zoom: 3}, transitionTime, {ease: FlxEase.cubeInOut});
			FlxTween.tween(camera, {alpha: 1}, transitionTime, {ease: FlxEase.cubeInOut, onComplete: function(twn) {
				canInteract = true;
			}});
		default:
			canInteract = true;
	}
	
	if (FlxG.save.data.lastMainMenuSelected != null) {
		curSelected = FlxG.save.data.lastMainMenuSelected;
	}
	
	updateSelection();
}

function postCreate() {
	var modVersion:String = '\nundertale mix v1.0';
	var extraString:String = modVersion;
	var firstKey = controls.getKeyName(Control.SWITCHMOD, 0);
	var keys = (firstKey != null ? firstKey : 'any');
	var keyText:String = 'press ' + keys.toLowerCase() + ' to open mods menu.';
	var appInfo:UndertaleText = new UndertaleText(bg.x - 200, bg.y + 256, Flags.VERSION_MESSAGE.toLowerCase() + extraString + '\n' + keyText, 'left', FlxG.width, 1, 'FFFFFF', 'crypt');
	appInfo.alpha = 0.5;
	add(appInfo);
}

// ========== 模式初始化 ==========
function initializeMode() {
	for (object in menuObjects) {
		object[0].color = FlxColor.WHITE;
	}
	hoveredObject = null;
	if (inputMode == "keyboard") {
		resetKeyboardSelection();
	} else {
		curSelected = getFirstVisibleIndex();
	}
}

// ========== 辅助函数 ==========
function getFirstVisibleIndex():Int {
	for (i in 0...menuObjects.length) {
		if (menuObjects[i][0].visible) {
			return i;
		}
	}
	return 0;
}

function resetKeyboardSelection() {
	curSelected = getFirstVisibleIndex();
	updateSelection(0);
}

// ========== 模式切换 ==========
function switchToTouch() {
	if (inputMode == "touch") return;
	inputMode = "touch";
	for (object in menuObjects) {
		object[0].color = FlxColor.WHITE;
	}
	hoveredObject = null;
	curSelected = getFirstVisibleIndex();
}

function switchToKeyboard() {
	if (inputMode == "keyboard") return;
	inputMode = "keyboard";
	if (hoveredObject != null) {
		hoveredObject.color = FlxColor.WHITE;
		hoveredObject = null;
	}
	resetKeyboardSelection();
}

var lerp:Float = 0;
var lastTimeString:String = "";
var transitionTime:Float = 0.25;

// ========== 执行当前选中选项 ==========
function acceptCurrentOption() {
	var selected:String = menuOptions[curSelected].toLowerCase();
	
	FlxG.sound.play(Paths.sound('select'));
	if (selected != 'story mode') {
		optionSelected = true;
		menuChar.animation.play('d', true);
	}
	updateSelection();
	if (nameSelected) {
		FlxG.switchState(new ModState('StartUp'));
	} else {
		switch(selected) {
			case 'story mode':
				if (storyModeButton.visible) {
					explode();
					storyModeButton.visible = false;
					menuObjects.shift();
					menuOptions.shift();
					originalX.shift();
					for (object in menuObjects) {
						object[2] = object[2] - 1;
						object[0].ID = object[0].ID -= 1;
					}
					for (object in menuObjects) {
						object[1] -= objectDistance;
					}
					optionSelected = false;
					resetKeyboardSelection();
				}
			case 'freeplay':
				FlxG.sound.music.fadeOut(1, 0);
				FlxTween.tween(camera, {x: -500}, transitionTime, {ease: FlxEase.cubeInOut, onComplete: function() {
					FlxG.switchState(new ModState('MixedFreeplayState'));
				}});
				FlxTween.tween(camera, {alpha: 0}, transitionTime, {ease: FlxEase.cubeInOut});
			case 'options':
				FlxTween.tween(camera, {y: -500}, transitionTime, {ease: FlxEase.cubeInOut, onComplete: function() {
					FlxG.switchState(new ModState('MixedOptions'));
				}});
				FlxTween.tween(camera, {alpha: 0}, transitionTime, {ease: FlxEase.cubeInOut});
			case 'credits':
				FlxTween.tween(camera, {x: 500}, transitionTime, {ease: FlxEase.cubeInOut, onComplete: function() {
					FlxG.switchState(new ModState('ModCreditsState'));
				}});
				FlxTween.tween(camera, {alpha: 0}, transitionTime, {ease: FlxEase.cubeInOut});
			case 'mod option test':
				FlxG.switchState(new ModState('ModOptions'));
			case 'minigames':
				FlxG.sound.music.fadeIn(transitionTime, Options.volumeMusic, 0);
				FlxTween.tween(camera, {zoom: 3 * 6}, transitionTime, {ease: FlxEase.cubeInOut, onComplete: function() {
					FlxG.switchState(new ModState('MiniGamesMenuState', 'mainmenu'));
				}});
				FlxTween.tween(camera, {alpha: 0}, transitionTime, {ease: FlxEase.cubeInOut});
			default:
				trace('what');
		}
	}
}

function update(elapsed:Float) {
	// ========== 系统时间刷新（每帧检查，秒变化才更新） ==========
	var currentTimeString:String = getSystemTimeString();
	if (time.text != currentTimeString) {
		time.text = currentTimeString;
		time.updateHitbox();
		lastTimeString = currentTimeString;
	}

	// 选项动画插值
	lerp = Math.exp(-elapsed * 24.6);
	var selectedID:Int = (inputMode == "touch" && hoveredObject != null) ? hoveredObject.ID : (inputMode == "keyboard" ? curSelected : -1);
	for (i in 0...menuObjects.length) {
		var object = menuObjects[i];
		var text:UndertaleText = object[0];
		var isSelected = (selectedID != -1 && object[2] == selectedID && !nameSelected && !optionSelected);
		
		var offsetX = (isSelected ? 6 : 0);
		var targetX = originalX[i] + offsetX;
		var targetScale = (isSelected ? 1.2 : 1.0);
		var targetY = object[1];
		
		text.x = FlxMath.lerp(targetX, text.x, lerp);
		text.y = FlxMath.lerp(targetY, text.y, lerp);
		text.scale.set(
			FlxMath.lerp(targetScale, text.scale.x, lerp / 2),
			FlxMath.lerp(targetScale, text.scale.y, lerp / 2)
		);
		text.updateHitbox();
		if (isSelected) {
			text.offset.y += 1;
		} else {
			text.offset.y = 0;
		}
	}
	
	if (!storyModeButton.visible) {
		storyModeButton.setPosition(menuObjects[0][0].x, menuObjects[0][0].y - 20);
	}
	explosion.setPosition(storyModeButton.x + 40, storyModeButton.y - 44);

	if (!canInteract) return;
	if (optionSelected) return;

	// ========== 模式切换检测 ==========
	if (inputMode == "keyboard") {
		if (FlxG.mouse.justPressed) {
			switchToTouch();
		}
	} else {
		if (controls.LEFT_P || controls.RIGHT_P || controls.UP_P || controls.DOWN_P || controls.ACCEPT) {
			switchToKeyboard();
		}
	}
	
	// ==========================================
	// 键盘模式
	// ==========================================
	if (inputMode == "keyboard") {
		if (controls.SWITCHMOD) {
			openSubState(new ModSwitchMenu());
			persistentUpdate = false;
			persistentDraw = true;
		}
		
		if (controls.ACCEPT) {
			acceptCurrentOption();
		} else if (controls.UP_P && !nameSelected) {
			updateSelection(-1);
		} else if (controls.DOWN_P && !nameSelected) {
			updateSelection(1);
		} else if (controls.LEFT_P) {
			if (nameSelected) {
				FlxG.sound.play(Paths.sound('squeak'));
				nameSelected = false;
				name.color = FlxColor.WHITE;
				updateSelection();
			}
		} else if (controls.RIGHT_P) {
			if (!nameSelected) {
				FlxG.sound.play(Paths.sound('squeak'));
				nameSelected = true;
				name.color = FlxColor.YELLOW;
				updateSelection();
			}
		} else if (controls.BACK && !optionSelected) {
			FlxG.switchState(new TitleState());
		}
		if (FlxG.mouse.wheel != 0) {
			updateSelection(-FlxG.mouse.wheel);
		}
	}
	
	// ==========================================
	// 触摸模式
	// ==========================================
	if (inputMode == "touch") {
		var mousePoint = FlxG.mouse.getScreenPosition(camera);
		var newHover:UndertaleText = null;
		
		for (object in menuObjects) {
			var opt:UndertaleText = object[0];
			if (!opt.visible) continue;
			var left = opt.x - 120;
			var right = opt.x + opt.fieldWidth;
			var top = opt.y;
			var bottom = opt.y + opt.textHeight;
			if (mousePoint.x >= left && mousePoint.x <= right &&
			    mousePoint.y >= top && mousePoint.y <= bottom) {
				newHover = opt;
				break;
			}
		}
		
		if (newHover != hoveredObject) {
			if (hoveredObject != null) {
				hoveredObject.color = FlxColor.WHITE;
			}
			if (newHover != null) {
				newHover.color = FlxColor.YELLOW;
				curSelected = newHover.ID;
				FlxG.sound.play(Paths.sound('squeak'), Options.volumeSFX);
			} else {
				curSelected = getFirstVisibleIndex();
			}
			hoveredObject = newHover;
		}
		
		if (FlxG.mouse.justReleased) {
			if (hoveredObject != null) {
				curSelected = hoveredObject.ID;
				acceptCurrentOption();
			}
		}
		
		if (controls.BACK && !optionSelected) {
			FlxG.switchState(new TitleState());
		}
	}
}

// ========== 更新键盘高亮 ==========
function updateSelection(?v:Int) {
	if (optionSelected) return;
	if (inputMode != "keyboard") return;
	
	if (v != null) {
		FlxG.sound.play(Paths.sound('squeak'));
		curSelected += v;
		if (curSelected > menuObjects.length - 1) {
			curSelected = 0;
		} else if (curSelected < 0) {
			curSelected = menuObjects.length - 1;
		}
	}
	for (object in menuObjects) {
		object[0].color = (object[0].ID == curSelected && !nameSelected && !optionSelected ? FlxColor.YELLOW : FlxColor.WHITE);
	}
}

var explosion:FlxSprite = new FlxSprite();
function explode() {
	FlxG.sound.play(Paths.sound('explosion'), 1);
	explosion.frames = Paths.getAsepriteAtlas('explosion');
	explosion.animation.addByPrefix('a', 'a', 8, false);
	explosion.animation.play('a', true);
	explosion.scale.set(4, 0.5);
	add(explosion);
}

function floorDecimal(value:Float, decimals:Int) {
	if (decimals < 1)
		return Math.floor(value);
		
	return Math.floor(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
}

function destroy() {
	FlxG.save.data.lastMainMenuSelected = curSelected;
}