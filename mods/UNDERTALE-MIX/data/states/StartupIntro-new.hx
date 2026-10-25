import UndertaleText;
import TypedBitmapText;
import funkin.backend.utils.DiscordUtil;

var camera:FlxCamera = new FlxCamera();

var inputMode:String = "keyboard";
var modeSwitchedThisFrame:Bool = false;
var tapText:FlxText;

var canProceed:Bool = false;
var hasToPick:Bool = false;
var currentIndex:Int = true;
var textIndex:Int = 0;
var yesOrNo:Bool = false;
var waitForInput:Bool = false;

// 两步确认：选中的选项 (null 未选, true Yes, false No)
var selectedOption:Null<Bool> = null;

var yesHitArea:FlxSprite;
var noHitArea:FlxSprite;
var yes:UndertaleText;
var no:UndertaleText;
var infoText:UndertaleText;
var typedText:TypedBitmapText;

// 延迟显示选项
var optionsState:Int = 0; // 0=等待显示Yes, 1=已显示Yes等待No, 2=已显示No可交互
var optionsTimer:Float = 0;
var optionsDelay:Float = 0.5; // 每个步骤间隔0.5秒
var optionsReady:Bool = false; // 是否允许交互（由hasToPick控制）

function create() {
	DiscordUtil.changePresenceAdvanced({
		details: 'Getting started...',
	});

	FlxG.cameras.add(camera, false);
	camera.bgColor = FlxColor.TRANSPARENT;
	camera.antialiasing = false;
	camera.zoom = 3.0;
	camera.pixelPerfectRender = true;
	this.cameras = [camera];

	FlxG.sound.playMusic(Paths.music('menuthemes/startup'), 0.5, true);

	infoText = new UndertaleText(450, 280, '--Information--', 'left', FlxG.width, 1, 'FFFFFF', 'undertale-pixel');
	infoText.alpha = 0.5;
	add(infoText);

	var fullDialogue = '\n \n \n*Hi, thanks for playing Undertale Mix!\n\nñBefore you start to actually play\nñthe mod we have to ask a few quick\nñquestions.:\n \n \n*This mod uses heavy flashing lights\nñin some songs which could trigger a seizure\nñor affect anyone with photosensitivity.\n \n*Do you want to keep flashing lights on?:\n \n \n*Like any Friday Night Funkin\' mod ever this\nñmod uses shaders.\n \n*Do you want to keep shaders on?:\n \n \n*Some songs have particle effects that\nñdepending on the device could\nñcause performance issues.\n \n*Do you want to keep particles on?:\n \n \n*With that out of the way we,\nñthe Undertale Mix team hope\nñyou enjoy the mod!';

	typedText = new TypedBitmapText(450, 280, fullDialogue, infoText.getFont('undertale-pixel'));
	typedText.setTextFormat(1, 'FFFFFF', FlxTextAlign.LEFT, FlxG.width);
	typedText.alpha = infoText.alpha;
	add(typedText);
	typedText.startTyping(0.03, null, false);

	yes = new UndertaleText(0, 300, 'Yes', 'left', FlxG.width, 1, 'FFFFFF', 'undertale-pixel');
	yes.autoSize = true;
	yes.updateHitbox();
	add(yes);
	yes.alpha = 1;

	no = new UndertaleText(yes.x + 50, yes.y, 'No', 'left', FlxG.width, 1, 'FFFFFF', 'undertale-pixel');
	no.autoSize = true;
	no.updateHitbox();
	add(no);
	no.alpha = yes.alpha;

	var total:Int = yes.width + 100 + no.width;
	yes.setPosition((FlxG.width - total) / 2, 444);
	no.setPosition(yes.x + 100, yes.y);
	yes.visible = no.visible = false;

	yesHitArea = new FlxSprite(yes.x, yes.y);
	yesHitArea.makeGraphic(Std.int(yes.width), Std.int(yes.height), FlxColor.TRANSPARENT);
	yesHitArea.cameras = [camera];
	yesHitArea.alpha = 0;
	yesHitArea.visible = false;
	add(yesHitArea);

	noHitArea = new FlxSprite(no.x, no.y);
	noHitArea.makeGraphic(Std.int(no.width), Std.int(no.height), FlxColor.TRANSPARENT);
	noHitArea.cameras = [camera];
	noHitArea.alpha = 0;
	noHitArea.visible = false;
	add(noHitArea);

	tapText = new FlxText(0, 0, 0, "Tap to continue", 20);
	tapText.setFormat(Paths.font("undertale-pixel"), 20, 0xFFFFFF, "right");
	tapText.antialiasing = true;
	tapText.cameras = [camera];
	tapText.alpha = 0.8;
	tapText.visible = false;
	add(tapText);
	updateTapTextPosition();

	#if mobile
		inputMode = "touch";
	#else
		inputMode = "keyboard";
	#end
}

function updateTapTextPosition() {
	if (tapText != null) {
		tapText.updateHitbox();
		tapText.x = FlxG.width - tapText.width - 2;
		tapText.y = FlxG.height - 2;
	}
}

function update(elapsed:Float) {
	updateTapTextPosition();

	// ===== 跳过打字（播放 squeak） =====
	if (typedText != null && typedText.typing && FlxG.mouse.justPressed) {
		if (typedText.skipTyping != null) {
			typedText.skipTyping();
		} else {
			typedText.typingSpeed = 0.001;
			if (typedText.visibleChars != null) {
				typedText.visibleChars = typedText.text.length;
			}
			typedText.typing = false;
		}
		FlxG.sound.play(Paths.sound('squeak'));
		return;
	}

	if (typedText != null) {
		typedText.textUpdate(elapsed);
	}

	// ===== 打字完成，进入选项准备 =====
	if (!typedText.typing && !waitForInput) {
		if (textIndex == 1 || textIndex == 2 || textIndex == 3) {
			// 开始延迟显示选项
			waitForInput = true;
			optionsState = 0;
			optionsTimer = 0;
			yes.visible = no.visible = false;
			yesHitArea.visible = noHitArea.visible = false;
			tapText.visible = true; // 显示 "Tap to continue" 作为提示（但暂时不可点击）
			// 清除之前的选中状态
			selectedOption = null;
			yes.color = FlxColor.WHITE;
			no.color = FlxColor.WHITE;
			yesOrNo = false;
			hasToPick = false;
			optionsReady = false;
		} else {
			// 非选项段，直接可推进
			canProceed = true;
			waitForInput = true;
		}
	}

	// ===== 处理选项延迟显示 =====
	if (waitForInput && !hasToPick && (textIndex == 1 || textIndex == 2 || textIndex == 3)) {
		optionsTimer += elapsed;
		switch(optionsState) {
			case 0: // 等待显示 Yes
				if (optionsTimer >= optionsDelay) {
					yes.visible = true;
					yesHitArea.visible = true;
					optionsState = 1;
					optionsTimer = 0;
					// 可选播放音效？不需要
				}
			case 1: // 等待显示 No
				if (optionsTimer >= optionsDelay) {
					no.visible = true;
					noHitArea.visible = true;
					optionsState = 2;
					optionsTimer = 0;
					// 现在允许交互
					hasToPick = true;
					optionsReady = true;
					// 如果是键盘模式，默认选中 Yes
					if (inputMode == "keyboard") {
						yesOrNo = true;
						yes.color = FlxColor.YELLOW;
						no.color = FlxColor.WHITE;
						selectedOption = true;
					} else {
						// 触摸模式无默认选中
						yes.color = FlxColor.WHITE;
						no.color = FlxColor.WHITE;
						selectedOption = null;
						yesOrNo = false;
					}
				}
		}
		// 延迟期间不允许其他操作
		return;
	}

	// ===== 模式切换 =====
	modeSwitchedThisFrame = false;
	if (inputMode == "keyboard") {
		if (FlxG.mouse.justPressed) {
			inputMode = "touch";
			modeSwitchedThisFrame = true;
			if (hasToPick) {
				// 切换到触摸，清除选中
				selectedOption = null;
				yes.color = FlxColor.WHITE;
				no.color = FlxColor.WHITE;
				yesOrNo = false;
			}
		}
	} else if (inputMode == "touch") {
		if (controls.LEFT || controls.RIGHT) {
			inputMode = "keyboard";
			modeSwitchedThisFrame = true;
			if (hasToPick) {
				yesOrNo = true;
				yes.color = FlxColor.YELLOW;
				no.color = FlxColor.WHITE;
				selectedOption = true;
			}
		}
	}
	if (modeSwitchedThisFrame) return;

	// ===== 无选项时：点击任意处或按确认推进 =====
	if (canProceed) {
		if (FlxG.mouse.justPressed) {
			FlxG.sound.play(Paths.sound('select'));
			advanceDialogue();
		}
		if (controls.ACCEPT || FlxG.keys.justPressed.Z) {
			FlxG.sound.play(Paths.sound('select'));
			advanceDialogue();
		}
	}

	// ===== 有选项时 =====
	if (hasToPick) {
		var mousePoint = FlxG.mouse.getScreenPosition(camera);
		var overYes = yesHitArea.visible && yesHitArea.overlapsPoint(mousePoint, true, camera);
		var overNo  = noHitArea.visible  && noHitArea.overlapsPoint(mousePoint, true, camera);

		if (inputMode == "keyboard") {
			// 键盘模式：左右切换选中
			if (controls.LEFT) {
				if (selectedOption != true) {
					yes.color = FlxColor.YELLOW;
					no.color = FlxColor.WHITE;
					selectedOption = true;
					yesOrNo = true;
					FlxG.sound.play(Paths.sound('squeak'));
				}
			} else if (controls.RIGHT) {
				if (selectedOption != false) {
					yes.color = FlxColor.WHITE;
					no.color = FlxColor.YELLOW;
					selectedOption = false;
					yesOrNo = false;
					FlxG.sound.play(Paths.sound('squeak'));
				}
			}
			// 键盘确认
			if (controls.ACCEPT || FlxG.keys.justPressed.Z) {
				FlxG.sound.play(Paths.sound('select'));
				acceptChoice();
			}
		} else { // 触摸模式：悬停即选中，点击确认
			// 检测鼠标移动，更新悬停对象（粘性高亮）
			if (FlxG.mouse.moved) {
				if (overYes) {
					if (selectedOption != true) {
						// 切换到 Yes
						yes.color = FlxColor.YELLOW;
						no.color = FlxColor.WHITE;
						selectedOption = true;
						yesOrNo = true;
						FlxG.sound.play(Paths.sound('squeak'));
					}
				} else if (overNo) {
					if (selectedOption != false) {
						// 切换到 No
						yes.color = FlxColor.WHITE;
						no.color = FlxColor.YELLOW;
						selectedOption = false;
						yesOrNo = false;
						FlxG.sound.play(Paths.sound('squeak'));
					}
				} else {
					// 鼠标离开任何选项，保持现有选中（不取消），除非点击空白
					// 这里不做取消
				}
			}

			// 点击处理
			if (FlxG.mouse.justPressed) {
				// 检查是否点击在选项区域内
				if (overYes) {
					if (selectedOption == true) {
						// 已选中 Yes，点击确认
						FlxG.sound.play(Paths.sound('select'));
						acceptChoice();
						return;
					} else {
						// 不应发生，因为移动已经更新了选中，但以防万一
						selectedOption = true;
						yesOrNo = true;
						yes.color = FlxColor.YELLOW;
						no.color = FlxColor.WHITE;
						FlxG.sound.play(Paths.sound('squeak'));
					}
				} else if (overNo) {
					if (selectedOption == false) {
						// 已选中 No，点击确认
						FlxG.sound.play(Paths.sound('select'));
						acceptChoice();
						return;
					} else {
						selectedOption = false;
						yesOrNo = false;
						yes.color = FlxColor.WHITE;
						no.color = FlxColor.YELLOW;
						FlxG.sound.play(Paths.sound('squeak'));
					}
				} else {
					// 点击空白区域：取消选中
					if (selectedOption != null) {
						selectedOption = null;
						yesOrNo = false;
						yes.color = FlxColor.WHITE;
						no.color = FlxColor.WHITE;
						// 可选播放音效？不播放
					}
				}
			}

			// 触摸模式下按回车/Z：直接确认当前选中项（若无选中则默认 Yes）
			if (controls.ACCEPT || FlxG.keys.justPressed.Z) {
				if (selectedOption == null) {
					selectedOption = true;
					yesOrNo = true;
					yes.color = FlxColor.YELLOW;
					no.color = FlxColor.WHITE;
				} else {
					yesOrNo = selectedOption;
				}
				FlxG.sound.play(Paths.sound('select'));
				acceptChoice();
			}
		}
	}
}

function advanceDialogue() {
	textIndex++;
	typedText.advanceDialogue();
	canProceed = false;
	waitForInput = false;
	hasToPick = false;
	optionsReady = false;
	selectedOption = null;
	yes.visible = no.visible = false;
	yesHitArea.visible = noHitArea.visible = false;
	tapText.visible = false;
	yes.color = FlxColor.WHITE;
	no.color = FlxColor.WHITE;
	if (textIndex == 5) {
		FlxTween.tween(infoText, {x: infoText.x - 500, alpha: 0}, 0.5, {ease: FlxEase.cubeInOut, onComplete: function() {
			FlxG.switchState(new ModState('StartUp', 'startup'));
		}});
	}
	trace(textIndex);
}

function acceptChoice() {
	FlxG.sound.play(Paths.sound('select'));

	switch(textIndex) {
		case 1:
			FlxG.save.data.flashingLights = yesOrNo;
			FlxG.save.flush();
		case 2:
			Options.gameplayShaders = yesOrNo;
			FlxG.save.flush();
		case 3:
			FlxG.save.data.particlesEnabled = yesOrNo;
			FlxG.save.flush();
	}
	advanceDialogue();
	trace('ACCEPTED OR NA: ' + yesOrNo);
}