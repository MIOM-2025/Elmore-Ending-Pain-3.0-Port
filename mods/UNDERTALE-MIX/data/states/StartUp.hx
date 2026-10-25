import flixel.math.FlxRandom;
import flixel.tweens.FlxTweenType;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import funkin.backend.utils.DiscordUtil;

import UndertaleText;
import Sys;

// ========== 可调整的触控点击宽度（单位：像素） ==========
var touchWidthLetter:Int = 20;
var touchWidthBackspace:Int = 60;
var touchWidthDone:Int = 35;
var touchWidthYes:Int = 20;
var touchWidthNo:Int = 20;

// ========== 原有变量 ==========
var letterLanes:Map<Int, Array<String>> = [];
var letterObjects:Map<Int, Array<UndertaleText>> = [];
var lettersArray:Array<UndertaleText> = [];
var mapLength:Int = 0;
var letters:String = 'ABCDEFG/HIJKLMN/OPQRSTU/VWXYZ/abcdefg/hijklmn/opqrstu/vwxyz/';
var offsetValue:Int = 0.3;

// 特殊名字字典
var specialNames = [
	'frisk' => ['WARNING: This name will\nmake your life hell.\nProceed anyway?'],
	'chara' => ['The true name.'],
	'' => ['You must choose a name.', false],
	'asgore' => ['You cannot.', false],
	'toriel' => ['I think you should\nthink of your own\nname, my child', false],
	'sans' => ['nope.', false],
	'undyne' => ['Get your OWN name!', false],
	'flowey' => ['I already CHOSE\nthat name.', false],
	'alphys' => ['D-don\'t do that.'],
	'alphy' => ['Uh.... OK?'],
	'papyru' => ['I\'LL ALLOW IT!!!!'],
	'napsta' => ['............\n(They\'re powerless to\nstop you.)'],
	'blooky' => ['............\n(They\'re powerless to\nstop you.)'],
	'murder' => ['That\'s a little on-\nthe-nose, isn\'t it...?'],
	'mercy' => ['That\'s a little on-\nthe-nose, isn\'t it...?'],
	'singin' => ['That\'s a little on-\nthe-nose, isn\'t it...?'],
	'funkin' => ['On a friday night.'],
	'clover' => ['You don\'t look the type\nto truly deliver justice.', false],
	'dlover' => ['What kind of name is that?'],
	'dlowey' => ['What kind of name is that?'],
	'lucky' => ['Taken.', false],
	'venus' => ['Thats MY name, idiot!', false],
	'gerson' => ['I\'m old!'],
	'catty' => ['Bratty! Bratty!\nThat\'s MY name!'],
	'bratty' => ['Like, OK I guess.'],
	'MTT' => ['OOOOH!!! ARE YOU\nPROMOTING MY BRAND?'],
	'metta' => ['OOOOH!!! ARE YOU\nPROMOTING MY BRAND?'],
	'mett' => ['OOOOH!!! ARE YOU\nPROMOTING MY BRAND?'],
	'shyren' => ['...?'],
	'aaron' => ['Is this name correct? ; )'],
	'temmie' => ['h0I!'],
	'woshua' => ['Clean name.'],
	'jerry' => ['Jerry.'],
	'bpants' => ['You are really scraping the\nbottom of the barrel.'],
	'asriel' => ['...', false],
	'parchy' => ['UM... I GUESS I\'LL\nALLOW IT?'],
	'toby' => ['(Bark, bark!)'],
	'cakie' => ['Shoo, FROGGIT.', false],
	'dragon' => ['That\'s a cool name.'],
	'drago' => ['That\'s a cool name.'],
	'yeetus' => ['Fuh nah...', false],
	'bug' => [':eyes:'],
	'goku' => ['Hey, it\'s me, Goku!'],
	'frieza' => ['Filthy, MONKEY!', false],
	'pepz' => ['NO!!! >:  (', false],
	'awsome' => ['hey so like that name is already\nin use or something lmao\ngo choose something else', false],
	'julio' => ['empanadas'],
	'MIOM' => ['Uh, you have no idea how hard it is to add touch to this UI.'],
	'Luzew' => ['I\'d love to see you come undone ^p^'],
	'Xenith' => ['Whoa, are you going for the SFC rank too?']
];
var nameAllowed:Bool = true;
var texts:Array<String>;
var prompts:Array<String>;

var curSelected:Int = 0;
var laneSelected:Int = 0;

var name:UndertaleText;
var topText:UndertaleText;
var flavorText:UndertaleText;

var camera:FlxCamera = new FlxCamera();
var camZoom:Float = 3.0;
var r:FlxRandom = new FlxRandom();

// ========== 模式管理 ==========
var inputMode:String = "keyboard";
var hoveredObject:UndertaleText = null;
var yesNoSelected:UndertaleText = null;
var readyOption:String = null;
var confirmHoverLocked:Bool = false;

// 记录触摸按下时的悬停对象
var pressStartHover:UndertaleText = null;
// ★ 新增：标记本次按下过程中是否发生过悬停切换
var hasSwitched:Bool = false;

// ========== Yes 过渡动画 ==========
var transitioning:Bool = false;
var blackOverlay:FlxSprite;

function create() {
	DiscordUtil.changePresenceAdvanced({
		details: 'Picking a name',
	});
	
	FlxG.cameras.add(camera, false);
	camera.bgColor = FlxColor.TRANSPARENT;
	camera.antialiasing = false;
	camera.zoom = camZoom;
	this.cameras = [camera];
	
	// 解析字母矩阵
	var splits:Array<String> = letters.split('');
	var index:Int = 0;
	var row:Int = 0;
	var letterRow:Array<String> = [];
	for (letter in splits) {
		if (letter == '/') {
			letterLanes.set(row, letterRow);
			letterRow = [];
			row++;
			index = 0;
		}
		if (letter != '/') { letterRow.push(letter); }
		index++;
	}
	
	// 创建字母对象
	var mapIndex:Int = 0;
	for (key in letterLanes) {
		var letterIndex:Int = 0;
		var letters:Array<UndertaleText> = [];
		for (l in letterLanes.get(mapIndex)) {
			var letter:UndertaleText = new UndertaleText(550 + (27 * letterIndex), 310 + (14 * mapIndex), l, 'left', FlxG.width, 1, 'FFFFFF', 'undertale-pixel');
			letter.ID = letterIndex;
			letter.fieldWidth = touchWidthLetter;
			add(letter);
			lettersArray.push(letter);
			letters.push(letter);
			letterIndex++;
		}
		letterObjects.set(mapIndex, letters);
		mapIndex++;
	}
	mapLength = mapIndex;
	
	// 名字显示
	name = new UndertaleText(610, 290, (FlxG.save.data.playerName == null ? '' : FlxG.save.data.playerName), 'left', FlxG.width, 1, 'FFFFFF', 'undertale-pixel');
	add(name);
	
	// 顶部随机提示
	texts = CoolUtil.coolTextFile(Paths.txt('nameflavortext'));
	topText = new UndertaleText(2, 264, texts[r.int(0, texts.length - 1)], 'center', FlxG.width, 1, 'FFFFFF', 'undertale-pixel');
	add(topText);
	
	// 功能按钮
	var backspace:UndertaleText = new UndertaleText(556, 428, 'Backspace', 'left', FlxG.width, 1, 'FFFFFF', 'undertale-pixel');
	backspace.ID = 0;
	backspace.fieldWidth = touchWidthBackspace;
	add(backspace);
	
	var done:UndertaleText = new UndertaleText(658, 428, 'Done', 'left', FlxG.width, 1, 'FFFFFF', 'undertale-pixel');
	done.ID = 1;
	done.fieldWidth = touchWidthDone;
	add(done);
	letterObjects.set(8, [backspace, done]);
	mapLength += 1;
	
	prompts = letterObjects.get(8);
	
	// 全屏黑色覆盖层（用于 Yes 过渡）
	blackOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
	blackOverlay.cameras = [camera];
	blackOverlay.alpha = 0;
	blackOverlay.scrollFactor.set(0, 0);
	blackOverlay.visible = false;
	add(blackOverlay);
	
	#if mobile
		inputMode = "touch";
	#else
		inputMode = "keyboard";
	#end
	initializeMode();
	
	FlxTween.tween(done, {x: done.x}, 0.03, {type: FlxTweenType.PINGPONG, onComplete: function() {
		for (letter in lettersArray) {
			letter.offset.set(r.float(offsetValue, -offsetValue), r.float(offsetValue, -offsetValue));
		}
	}});
}

function initializeMode() {
	for (row in letterObjects) {
		for (obj in row) {
			obj.color = FlxColor.WHITE;
		}
	}
	curSelected = 0;
	laneSelected = 0;
	readyOption = null;
	confirmHoverLocked = false;
	yesNoSelected = null;
	transitioning = false;
	pressStartHover = null;
	hasSwitched = false;
	if (inputMode == "keyboard") {
		updateSelection(0, 0);
	} else {
		hoveredObject = null;
	}
}

function switchToTouch() {
	if (inputMode == "touch" || transitioning) return;
	inputMode = "touch";
	for (row in letterObjects) {
		for (obj in row) {
			obj.color = FlxColor.WHITE;
		}
	}
	curSelected = 0;
	laneSelected = 0;
	hoveredObject = null;
	readyOption = null;
	confirmHoverLocked = false;
	yesNoSelected = null;
	pressStartHover = null;
	hasSwitched = false;
}

function switchToKeyboard() {
	if (inputMode == "keyboard" || transitioning) return;
	inputMode = "keyboard";
	for (row in letterObjects) {
		for (obj in row) {
			obj.color = FlxColor.WHITE;
		}
	}
	curSelected = 0;
	laneSelected = 0;
	hoveredObject = null;
	readyOption = null;
	confirmHoverLocked = false;
	yesNoSelected = null;
	pressStartHover = null;
	hasSwitched = false;
	updateSelection(0, 0);
}

var namingMenu:Bool = false;

function update(elapsed:Float) {
	// 过渡动画期间禁用一切输入
	if (transitioning) return;
	
	// 模式切换
	if (inputMode == "keyboard") {
		if (FlxG.mouse.justPressed) {
			switchToTouch();
			return;
		}
	} else {
		if (controls.LEFT_P || controls.RIGHT_P || controls.UP_P || controls.DOWN_P || controls.ACCEPT) {
			switchToKeyboard();
		}
	}
	
	// ========== 键盘模式 ==========
	if (inputMode == "keyboard") {
		if (controls.ACCEPT) {
			var letter:UndertaleText = letterObjects.get(laneSelected)[curSelected];
			if (!namingMenu) {
				FlxG.sound.play(Paths.sound('squeak'));
				switch(letter.text) {
					case 'Backspace':
						name.text = name.text.substring(0, name.text.length - 1);
					case 'Done':
						nameAccept();
					default:
						if (name.text.length < 6) {
							name.text = name.text + letter.text;
							if (name.text.toLowerCase() == 'gaster') {
								Sys.exit();
							}
						}
				}
			} else {
				FlxG.sound.play(Paths.sound('select'));
				switch(letter.text) {
					case 'Yes':
						FlxG.save.data.playerName = name.text;
						FlxG.save.flush();
						if (data != null) {
							FlxG.switchState(new ModState('ModMainMenu', data));
						} else {
							FlxG.switchState(new MainMenuState());
						}
					case 'No':
						returnName();
				}
			}
		}
		
		if (controls.LEFT_P) {
			updateSelection(-1);
		} else if (controls.RIGHT_P) {
			updateSelection(1);
		} else if (controls.UP_P) {
			updateSelection(null, -1);
		} else if (controls.DOWN_P) {
			updateSelection(null, 1);
		}
	}
	
	// ========== 触控模式 ==========
	if (inputMode == "touch") {
		var mousePoint = FlxG.mouse.getScreenPosition(camera);
		
		// 确认界面悬停锁
		if (namingMenu && confirmHoverLocked) {
			if (FlxG.mouse.moved || FlxG.mouse.justPressed) {
				confirmHoverLocked = false;
				readyOption = null;
				yesNoSelected = null;
			}
		}
		
		var newHover:UndertaleText = null;
		for (row in letterObjects) {
			for (obj in row) {
				if (obj.visible && obj.overlapsPoint(mousePoint, false, camera)) {
					newHover = obj;
					break;
				}
			}
			if (newHover != null) break;
		}
		
		// ★ 按下时重置切换标记，并记录起始悬停
		if (FlxG.mouse.justPressed) {
			if (!namingMenu) {
				pressStartHover = newHover;
				hasSwitched = false;
			}
		}
		
		if (!confirmHoverLocked) {
			if (namingMenu) {
				// Yes/No 粘性高亮
				if (newHover != null && (newHover.text == 'Yes' || newHover.text == 'No')) {
					if (yesNoSelected != newHover) {
						if (yesNoSelected != null) yesNoSelected.color = FlxColor.WHITE;
						yesNoSelected = newHover;
						yesNoSelected.color = FlxColor.YELLOW;
						FlxG.sound.play(Paths.sound('squeak'));
						readyOption = null;
					}
				}
				hoveredObject = newHover;
			} else {
				// ★ 悬停切换处理：高亮更新，音效播放条件
				if (newHover != hoveredObject) {
					if (hoveredObject != null) hoveredObject.color = FlxColor.WHITE;
					if (newHover != null) {
						newHover.color = FlxColor.YELLOW;
						// 只在非按下瞬间播放音效（按下瞬间不播，避免重复）
						if (!FlxG.mouse.justPressed) {
							FlxG.sound.play(Paths.sound('squeak'));
							hasSwitched = true; // 标记发生过切换
						}
					}
					hoveredObject = newHover;
				}
			}
		}
		
		// ★ 松开处理：执行功能，并根据 hasSwitched 决定是否播放音效
		if (FlxG.mouse.justReleased) {
			if (confirmHoverLocked) return;
			
			if (!namingMenu) {
				if (newHover != null) {
					switch(newHover.text) {
						case 'Backspace':
							name.text = name.text.substring(0, name.text.length - 1);
							if (!hasSwitched) FlxG.sound.play(Paths.sound('squeak'));
						case 'Done':
							nameAccept();
							if (!hasSwitched) FlxG.sound.play(Paths.sound('squeak'));
						default:
							if (name.text.length < 6) {
								name.text = name.text + newHover.text;
								if (name.text.toLowerCase() == 'gaster') {
									Sys.exit();
								}
							}
							if (!hasSwitched) FlxG.sound.play(Paths.sound('squeak'));
					}
				}
				// 清空记录
				pressStartHover = null;
				hasSwitched = false;
			} else {
				// Yes/No 界面逻辑不变
				var actualClicked:UndertaleText = newHover;
				if (actualClicked != null && (actualClicked.text == 'Yes' || actualClicked.text == 'No')) {
					if (readyOption == null) {
						readyOption = actualClicked.text;
					} else if (readyOption == actualClicked.text) {
						FlxG.sound.play(Paths.sound('select'));
						if (actualClicked.text == 'Yes') {
							startYesTransition();
						} else {
							readyOption = null;
							returnName();
						}
					} else {
						readyOption = actualClicked.text;
					}
				}
			}
		}
	}
}

function startYesTransition() {
	transitioning = true;
	blackOverlay.visible = true;
	blackOverlay.alpha = 0;
	FlxTween.tween(blackOverlay, {alpha: 1}, 0.3, {
		ease: FlxEase.quadIn,
		onComplete: function(_) {
			FlxG.save.data.playerName = name.text;
			FlxG.save.flush();
			if (data != null) {
				FlxG.switchState(new ModState('ModMainMenu', data));
			} else {
				FlxG.switchState(new MainMenuState());
			}
		}
	});
}

function postUpdate(elapsed:Float) {
	if (!namingMenu) {
		// 保留飘动效果
	} else if (!transitioning) {
		name.angle = r.float(offsetValue, -offsetValue);
	}
}

var lane:Array<UndertaleText>;
function updateSelection(?v:Int, ?l:Int) {
	if (inputMode != "keyboard") return;
	
	var oldLane = letterObjects.get(laneSelected);
	if (oldLane != null && oldLane[curSelected] != null) {
		oldLane[curSelected].color = FlxColor.WHITE;
	}
	
	if (l != null && !namingMenu) {
		laneSelected += l;
		if (laneSelected < 0) {
			laneSelected = 0;
		} else if (laneSelected > mapLength - 1) {
			laneSelected = mapLength - 1;
		}
		lane = letterObjects.get(laneSelected);
		if (curSelected > lane.length - 1) {
			curSelected = lane.length - 1;
		}
	}
	if (v != null && nameAllowed) {
		curSelected += v;
		if (curSelected > lane.length - 1) {
			curSelected = lane.length - 1;
		} else if (curSelected < 0) {
			curSelected = 0;
		}
	}
	var finalLane = letterObjects.get(laneSelected);
	if (finalLane != null && finalLane[curSelected] != null) {
		finalLane[curSelected].color = FlxColor.YELLOW;
	}
}

var nameTween:FlxTween;
var namePosition:FlxTween;
function nameAccept() {
	var inputRaw = name.text;
	var inputLower = inputRaw.toLowerCase();
	
	var special:Array<Dynamic> = null;
	for (key in specialNames.keys()) {
		if (key.toLowerCase() == inputLower) {
			special = specialNames.get(key);
			break;
		}
	}
	
	if (special != null) {
		nameAllowed = (special[1] == null || special[1] != false ? true : false);
	}
	
	topText.text = (special != null ? special[0] : (unoriginalName(inputRaw) ? 'Not very creative...?' : 'Is this name correct?'));
	topText.alignment = 'center';
	topText.x = 2;
	
	var tw:Float = name.textWidth;
	var th:Float = name.textHeight;
	var targetScale:Float = 2.8;
	var targetX:Float = (FlxG.width - tw * targetScale) / 2;
	var targetY:Float = (FlxG.height - th * targetScale) / 2;
	
	name.origin.set(0, 0);
	nameTween = FlxTween.tween(name.scale, {x: targetScale, y: targetScale}, 4);
	namePosition = FlxTween.tween(name, {x: targetX, y: targetY}, 4);
	
	var btnNo:UndertaleText = prompts[0];
	var btnYes:UndertaleText = prompts[1];
	btnNo.text = 'No';
	btnNo.fieldWidth = touchWidthNo;
	btnYes.text = 'Yes';
	btnYes.fieldWidth = touchWidthYes;
	btnYes.visible = nameAllowed;
	
	btnNo.color = FlxColor.WHITE;
	btnYes.color = FlxColor.WHITE;
	confirmHoverLocked = true;
	readyOption = null;
	yesNoSelected = null;
	hoveredObject = null;
	
	if (!nameAllowed) {
		curSelected = 0;
		updateSelection(0, 0);
	}
	
	for (letter in lettersArray) {
		letter.visible = false;
	}
	
	namingMenu = true;
}

function returnName() {
	topText.text = texts[r.int(0, texts.length - 1)];
	topText.alignment = 'center';
	topText.x = 2;
	
	DiscordUtil.changePresence('Naming themselves.', topText.text);
	
	prompts[0].text = 'Backspace';
	prompts[0].fieldWidth = touchWidthBackspace;
	prompts[1].text = 'Done';
	prompts[1].fieldWidth = touchWidthDone;
	prompts[1].visible = true;
	
	nameAllowed = true;
	
	for (letter in lettersArray) {
		letter.visible = true;
	}
	
	nameTween.cancel();
	namePosition.cancel();
	name.scale.set(1, 1);
	name.setPosition(610, 290);
	name.angle = 0;
	
	namingMenu = false;
	confirmHoverLocked = false;
	readyOption = null;
	yesNoSelected = null;
	pressStartHover = null;
	hasSwitched = false;
	
	if (inputMode == "keyboard") {
		var lane = letterObjects.get(laneSelected);
		if (lane != null && lane[curSelected] != null) {
			lane[curSelected].color = FlxColor.YELLOW;
		}
	}
}

function unoriginalName(name:String) {
	var firstLetter:String = name.charAt(0);
	var repeats:Int = 0;
	for (i in 1...name.length) {
		if (name.charAt(i) == firstLetter) {
			repeats++;
		}
	}
	return (repeats + 1) == name.length;
}