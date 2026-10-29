import flixel.util.FlxAxes;
import flixel.effects.FlxFlicker;
import flixel.util.FlxSpriteUtil;
import funkin.backend.utils.DiscordUtil;
import flixel.math.FlxPoint;
import flixel.text.FlxTextBorderStyle;

var enter:Bool = false;
var transitioning:Bool = false;
var optionsActive:Bool = false;

var mainOptions:Array<Dynamic> = [];
var moreOptions:Array<Dynamic> = [];
var moreOptionsOpen:Bool = false;

var warnTxt:FunkinText;
var adsTxt:FunkinText;
var redTitleTxt:FunkinText;
var enterTxt:FunkinText;
var moreOptionsButtonTxt:FunkinText;
var dontShowOption:Dynamic = null;

var moreOptionsPanelBg:FlxSprite;
var moreOptionsPanelGroup:FlxSpriteGroup;

var vhsShader:CustomShader;
var shaderTime:Float = 0;

var BOX_SIZE:Int = 26;
var BOX_GAP:Int = 14;
var CHECK_OFFSET:Int = 9;
var MOVE_DISTANCE:Float = 30;

var SMALL_BOX_SIZE:Int = 26;
var SMALL_BOX_GAP:Int = 12;
var SMALL_CHECK_OFFSET:Int = 9;
var SMALL_FONT:Int = 24;
var SMALL_ITEM_SPACING:Int = 48;

var DROP_DUR:Float = 0.25;
var CHECK_DUR:Float = 0.15;
var DROP_GAP:Float = 0.1;
var MORE_SLIDE_DUR:Float = 0.3;

function create() {
    DiscordUtil.call("onMenuLoaded", ["Warning"]);

    try {
        applyVhsSettings();
        if (vhsShader != null) {
            try { vhsShader.setInt("uFrame", 0); } catch (e:Dynamic) {}
        }
    } catch (e:Dynamic) {
        vhsShader = null;
    }

    add(warnTxt = new FunkinText(0, 0, 0, "Warning", 70));
    warnTxt.setFormat(Paths.font("fpsCounter.ttf"), 70, FlxColor.WHITE);
    warnTxt.screenCenter(FlxAxes.X);
    warnTxt.alpha = 0;
    warnTxt.antialiasing = Options.antialiasing;

    add(adsTxt = new FunkinText(0, 0, 0,
        "The mod contains gore, flashing lights,\n" +
        "and other elements that may be disturbing to some players.\n" +
        "If you are sensitive to these\n" +
        "it is recommended that you stop playing immediately.",
        50
    ));
    adsTxt.alignment = "center";
    adsTxt.setFormat(Paths.font("Adult-Swim-Font.ttf"), 40, FlxColor.WHITE);
    adsTxt.screenCenter(FlxAxes.X);
    adsTxt.alpha = 0;
    adsTxt.antialiasing = Options.antialiasing;

    add(redTitleTxt = new FunkinText(0, 0, 0, "Disturbing Content", 45));
    redTitleTxt.setFormat(Paths.font("fpsCounter.ttf"), 45, 0xFFFF2222);
    redTitleTxt.screenCenter(FlxAxes.X);
    redTitleTxt.alpha = 0;
    redTitleTxt.antialiasing = Options.antialiasing;

    add(enterTxt = new FunkinText(0, 0, 0, "> Continue <", 46));
    enterTxt.setFormat(Paths.font("fpsCounter.ttf"), 46, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    enterTxt.borderSize = 3;
    enterTxt.alpha = 0;
    enterTxt.antialiasing = Options.antialiasing;

    warnTxt.y = 0;
    adsTxt.y = warnTxt.y + warnTxt.height + 22;
    redTitleTxt.y = adsTxt.y + adsTxt.height + 30;

    createTwoMainOptions();

    var lastOpt = mainOptions[mainOptions.length - 1];
    enterTxt.y = lastOpt.box.y + BOX_SIZE + 50;
    enterTxt.screenCenter(FlxAxes.X);

    centerContent();

    createDontShowOption();
    createMoreOptionsButton();
    createMoreOptionsMenu();

    playIntro();
}

function applyVhsSettings() {
    var vhsOn:Bool = (FlxG.save.data == null || FlxG.save.data.vhsEnabled != false);
    var vhsCurve:Bool = (FlxG.save.data == null || FlxG.save.data.vhsCurve != false);
    var vhsNew:Bool = (FlxG.save.data != null && FlxG.save.data.vhsNew == true);
    var shaderName:String = vhsNew ? "vhs_new" : "vhs";

    if (vhsShader != null) {
        try { FlxG.camera.removeShader(vhsShader); } catch (e:Dynamic) {}
        vhsShader = null;
    }

    if (!vhsOn) return;

    try {
        vhsShader = new CustomShader(shaderName);
        FlxG.camera.addShader(vhsShader);
        try { vhsShader.setFloat("uInterlace", 1.0); } catch (e:Dynamic) {}
        var curveVal:Float = vhsCurve ? 4.0 : 0.0;
        try { vhsShader.uCurvature = curveVal; } catch (e:Dynamic) {}
        try { vhsShader.setFloat("uCurvature", curveVal); } catch (e:Dynamic) {}
    } catch (e:Dynamic) {
        vhsShader = null;
    }
}

function centerContent() {
    var topY:Float = warnTxt.y;
    var bottomY:Float = enterTxt.y + enterTxt.height;
    var totalHeight:Float = bottomY - topY;
    var targetTop:Float = (FlxG.height - totalHeight) / 2;
    var offset:Float = targetTop - topY;

    warnTxt.y += offset;
    adsTxt.y += offset;
    redTitleTxt.y += offset;
    enterTxt.y += offset;

    for (opt in mainOptions) {
        opt.box.y += offset;
        opt.check.y += offset;
        opt.label.y += offset;
    }
}

function createTwoMainOptions() {
    var opt1Y = redTitleTxt.y + redTitleTxt.height + 25;
    var spacing = 50;

    var labels = ["Censor Video", "Censor Death Animation"];
    var keys   = ["censorVideo", "censorDeath"];

    for (i in 0...labels.length) {
        var txt = new FunkinText(0, 0, 0, labels[i], 26);
        txt.setFormat(Paths.font("fpsCounter.ttf"), 26, 0xDDDDDD);
        txt.antialiasing = Options.antialiasing;

        var totalW = BOX_SIZE + BOX_GAP + txt.width;
        var startX = (FlxG.width - totalW) / 2;
        var optY = opt1Y + i * spacing;

        var box = makeCheckbox(Std.int(startX), Std.int(optY), BOX_SIZE, 2);
        box.alpha = 0;

        var check = makeCheckmarkWithSize(Std.int(startX), Std.int(optY), BOX_SIZE, CHECK_OFFSET);
        check.alpha = 0;
        check.origin.set(check.width / 2, check.height / 2);

        var saveData = FlxG.save.data;
        var savedVal = saveData != null ? Reflect.field(saveData, keys[i]) : null;
        var isChecked = (savedVal == null) ? true : (savedVal == true);
        check.visible = isChecked;
        if (isChecked) check.scale.set(1, 1); else check.scale.set(0.01, 0.01);

        txt.x = startX + BOX_SIZE + BOX_GAP;
        txt.y = optY + (BOX_SIZE - txt.height) / 2;
        txt.alpha = 0;

        var opt = {
            box: box, check: check, label: txt,
            key: keys[i], checked: isChecked,
            checkOffset: CHECK_OFFSET
        };
        mainOptions.push(opt);

        add(box);
        add(check);
        add(txt);
    }
}

function createDontShowOption() {
    var optY = enterTxt.y + enterTxt.height + 28;

    var txt = new FunkinText(0, 0, 0, "Don't show this warning again", 24);
    txt.setFormat(Paths.font("fpsCounter.ttf"), 24, 0x777777);
    txt.antialiasing = Options.antialiasing;

    var totalW = BOX_SIZE + BOX_GAP + txt.width;
    var startX = (FlxG.width - totalW) / 2;

    var box = makeCheckbox(Std.int(startX), Std.int(optY), BOX_SIZE, 2);
    box.alpha = 0;

    var check = makeCheckmarkWithSize(Std.int(startX), Std.int(optY), BOX_SIZE, CHECK_OFFSET);
    check.alpha = 0;
    check.origin.set(check.width / 2, check.height / 2);

    var saveData = FlxG.save.data;
    var savedVal = saveData != null ? Reflect.field(saveData, "hideWarning") : null;
    var isChecked = (savedVal == true);
    check.visible = isChecked;
    if (isChecked) check.scale.set(1, 1); else check.scale.set(0.01, 0.01);

    txt.x = startX + BOX_SIZE + BOX_GAP;
    txt.y = optY + (BOX_SIZE - txt.height) / 2;
    txt.alpha = 0;

    dontShowOption = {
        box: box, check: check, label: txt,
        key: "hideWarning", checked: isChecked,
        checkOffset: CHECK_OFFSET
    };

    add(box);
    add(check);
    add(txt);
}

function createMoreOptionsButton() {
    var btnX = 20;
    var btnY = FlxG.height - 80;

    moreOptionsButtonTxt = new FunkinText(btnX, btnY, 0, "More Options", 32);
    moreOptionsButtonTxt.setFormat(Paths.font("fpsCounter.ttf"), 32, 0xCCCCCC);
    moreOptionsButtonTxt.alpha = 0;
    moreOptionsButtonTxt.antialiasing = Options.antialiasing;
    add(moreOptionsButtonTxt);
}

function createMoreOptionsMenu() {
    var labels = ["Censor Health Icons", "VHS Shader", "CRT Curvature", "New VHS Filter"];
    var keys   = ["censorHealth", "vhsEnabled", "vhsCurve", "vhsNew"];

    moreOptionsPanelGroup = new FlxSpriteGroup();
    add(moreOptionsPanelGroup);

    var panelPaddingX = 14;
    var panelPaddingY = 12;

    var maxItemWidth:Float = 0;
    for (i in 0...labels.length) {
        var tempTxt = new FunkinText(0, 0, 0, labels[i], SMALL_FONT);
        tempTxt.setFormat(Paths.font("fpsCounter.ttf"), SMALL_FONT, FlxColor.WHITE);
        tempTxt.updateHitbox();
        var w = SMALL_BOX_SIZE + SMALL_BOX_GAP + tempTxt.width;
        if (w > maxItemWidth) maxItemWidth = w;
    }

    var panelW:Float = maxItemWidth + panelPaddingX * 2;
    var panelH:Float = labels.length * SMALL_ITEM_SPACING + panelPaddingY * 2 - (SMALL_ITEM_SPACING - SMALL_BOX_SIZE - 4);

    var panelX:Float = 15;
    var panelY:Float = FlxG.height - 90 - panelH - 5;

    moreOptionsPanelBg = new FlxSprite(panelX, panelY);
    moreOptionsPanelBg.makeGraphic(Std.int(panelW), Std.int(panelH), 0xFF000000);
    moreOptionsPanelBg.alpha = 0.75;
    moreOptionsPanelBg.visible = false;
    moreOptionsPanelGroup.add(moreOptionsPanelBg);

    for (i in 0...labels.length) {
        var y = panelY + panelPaddingY + i * SMALL_ITEM_SPACING;
        var itemX = panelX + panelPaddingX;

        var txt = new FunkinText(0, 0, 0, labels[i], SMALL_FONT);
        txt.setFormat(Paths.font("fpsCounter.ttf"), SMALL_FONT, FlxColor.WHITE);
        txt.antialiasing = Options.antialiasing;

        var box = makeCheckbox(Std.int(itemX), Std.int(y), SMALL_BOX_SIZE, 2);
        box.visible = false;
        box.alpha = 0;

        var check = makeCheckmarkWithSize(Std.int(itemX), Std.int(y), SMALL_BOX_SIZE, SMALL_CHECK_OFFSET);
        check.visible = false;
        check.alpha = 0;
        check.origin.set(check.width / 2, check.height / 2);

        var saveData = FlxG.save.data;
        var savedVal = saveData != null ? Reflect.field(saveData, keys[i]) : null;
        var defChecked:Bool = (keys[i] == "vhsEnabled" || keys[i] == "vhsCurve");
        var isChecked:Bool = (savedVal == null) ? defChecked : (savedVal == true);
        if (isChecked) check.scale.set(1, 1); else check.scale.set(0.01, 0.01);

        txt.x = itemX + SMALL_BOX_SIZE + SMALL_BOX_GAP;
        txt.y = y + (SMALL_BOX_SIZE - txt.height) / 2;
        txt.alpha = 0;
        txt.visible = false;

        var opt = {
            box: box, check: check, label: txt,
            key: keys[i], checked: isChecked, visible: false,
            checkOffset: SMALL_CHECK_OFFSET
        };
        moreOptions.push(opt);

        moreOptionsPanelGroup.add(box);
        moreOptionsPanelGroup.add(check);
        moreOptionsPanelGroup.add(txt);
    }
}

function toggleMoreOptionsMenu() {
    moreOptionsOpen = !moreOptionsOpen;

    if (moreOptionsOpen) {
        moreOptionsPanelGroup.visible = true;
        moreOptionsPanelGroup.y = 30;
        moreOptionsPanelGroup.alpha = 0;

        moreOptionsPanelBg.visible = true;
        for (opt in moreOptions) {
            opt.visible = true;
            opt.box.visible = true;
            opt.label.visible = true;
            if (opt.checked) opt.check.visible = true;
        }

        FlxTween.cancelTweensOf(moreOptionsPanelGroup);
        FlxTween.tween(moreOptionsPanelGroup, {y: 0, alpha: 1}, MORE_SLIDE_DUR, {ease: FlxEase.expoOut});

        for (opt in moreOptions) {
            FlxTween.cancelTweensOf(opt.box);
            FlxTween.tween(opt.box, {alpha: 1}, MORE_SLIDE_DUR, {ease: FlxEase.expoOut});
            FlxTween.cancelTweensOf(opt.label);
            FlxTween.tween(opt.label, {alpha: 1}, MORE_SLIDE_DUR, {ease: FlxEase.expoOut});
            if (opt.checked) {
                FlxTween.cancelTweensOf(opt.check);
                FlxTween.tween(opt.check, {alpha: 1}, MORE_SLIDE_DUR, {ease: FlxEase.expoOut});
            }
        }
    } else {
        FlxTween.cancelTweensOf(moreOptionsPanelGroup);
        FlxTween.tween(moreOptionsPanelGroup, {y: 30, alpha: 0}, MORE_SLIDE_DUR, {
            ease: FlxEase.expoIn,
            onComplete: function(_) {
                moreOptionsPanelGroup.visible = false;
                moreOptionsPanelBg.visible = false;
                for (opt in moreOptions) {
                    opt.visible = false;
                    opt.box.visible = false;
                    opt.label.visible = false;
                    opt.check.visible = false;
                    opt.box.alpha = 0;
                    opt.label.alpha = 0;
                    opt.check.alpha = 0;
                }
            }
        });
    }
}

function playIntro() {
    var step:Float = 0;
    var gap:Float = DROP_GAP;

    warnTxt.y -= MOVE_DISTANCE;
    adsTxt.y -= MOVE_DISTANCE;
    redTitleTxt.y -= MOVE_DISTANCE;
    enterTxt.y -= MOVE_DISTANCE;
    dontShowOption.box.y -= MOVE_DISTANCE;
    dontShowOption.label.y -= MOVE_DISTANCE;
    dontShowOption.check.y -= MOVE_DISTANCE;
    moreOptionsButtonTxt.y -= MOVE_DISTANCE;

    for (opt in mainOptions) {
        opt.box.y -= MOVE_DISTANCE;
        opt.label.y -= MOVE_DISTANCE;
        opt.check.y -= MOVE_DISTANCE;
    }

    FlxTween.tween(warnTxt, {alpha: 1, y: warnTxt.y + MOVE_DISTANCE}, DROP_DUR, {startDelay: step, ease: FlxEase.expoOut});
    step += gap;

    FlxTween.tween(adsTxt, {alpha: 1, y: adsTxt.y + MOVE_DISTANCE}, DROP_DUR, {startDelay: step, ease: FlxEase.expoOut});
    step += gap;

    FlxTween.tween(redTitleTxt, {alpha: 1, y: redTitleTxt.y + MOVE_DISTANCE}, DROP_DUR, {startDelay: step, ease: FlxEase.expoOut});
    step += gap;

    for (opt in mainOptions) {
        FlxTween.tween(opt.box, {alpha: 1, y: opt.box.y + MOVE_DISTANCE}, DROP_DUR, {startDelay: step, ease: FlxEase.expoOut});
        FlxTween.tween(opt.label, {alpha: 1, y: opt.label.y + MOVE_DISTANCE}, DROP_DUR, {startDelay: step, ease: FlxEase.expoOut});
        if (opt.checked) {
            FlxTween.tween(opt.check, {alpha: 1, y: opt.check.y + MOVE_DISTANCE}, DROP_DUR, {startDelay: step, ease: FlxEase.expoOut});
        } else {
            opt.check.y += MOVE_DISTANCE;
        }
    }
    step += gap;

    FlxTween.tween(enterTxt, {alpha: 1, y: enterTxt.y + MOVE_DISTANCE}, DROP_DUR, {startDelay: step, ease: FlxEase.expoOut});
    step += gap;

    FlxTween.tween(dontShowOption.box, {alpha: 1, y: dontShowOption.box.y + MOVE_DISTANCE}, DROP_DUR, {startDelay: step, ease: FlxEase.expoOut});
    FlxTween.tween(dontShowOption.label, {alpha: 1, y: dontShowOption.label.y + MOVE_DISTANCE}, DROP_DUR, {startDelay: step, ease: FlxEase.expoOut});
    if (dontShowOption.checked) {
        FlxTween.tween(dontShowOption.check, {alpha: 1, y: dontShowOption.check.y + MOVE_DISTANCE}, DROP_DUR, {startDelay: step, ease: FlxEase.expoOut});
    } else {
        dontShowOption.check.y += MOVE_DISTANCE;
    }
    step += gap;

    FlxTween.tween(moreOptionsButtonTxt, {alpha: 1, y: moreOptionsButtonTxt.y + MOVE_DISTANCE}, DROP_DUR, {startDelay: step, ease: FlxEase.expoOut});
    step += DROP_DUR;

    new FlxTimer().start(step, function(_) {
        optionsActive = true;
        enter = true;
    });
}

function makeCheckbox(x:Int, y:Int, size:Int = 30, thickness:Int = 3):FlxSprite {
    var spr = new FlxSprite(x, y);
    spr.makeGraphic(size, size, FlxColor.TRANSPARENT);
    var w = FlxColor.WHITE;

    for (i in 0...thickness) {
        for (px in i...(size - i)) {
            spr.pixels.setPixel32(px, i, w);
            spr.pixels.setPixel32(px, size - 1 - i, w);
        }
        for (py in i...(size - i)) {
            spr.pixels.setPixel32(i, py, w);
            spr.pixels.setPixel32(size - 1 - i, py, w);
        }
    }
    return spr;
}

function makeCheckmarkWithSize(boxX:Int, boxY:Int, boxSize:Int, off:Int):FlxSprite {
    var totalSize = boxSize + off * 2;
    var spr = new FlxSprite(boxX - off, boxY - off);
    spr.makeGraphic(totalSize, totalSize, FlxColor.TRANSPARENT);

    var gold = 0xFFFFD700;
    var thickness = Math.max(3, Std.int(5 * boxSize / 30));
    var scale:Float = boxSize / 30.0;

    var p1x = off + 4 * scale;
    var p1y = off + 16 * scale;
    var p2x = off + 12 * scale;
    var p2y = off + 25 * scale;
    var p3x = off + 32 * scale;
    var p3y = off + 2 * scale;

    FlxSpriteUtil.drawLine(spr, p1x, p1y, p2x, p2y,
        {color: gold, thickness: thickness, alpha: 1});
    FlxSpriteUtil.drawLine(spr, p2x, p2y, p3x, p3y,
        {color: gold, thickness: thickness, alpha: 1});

    return spr;
}

function isMouseOver(target:Dynamic):Bool {
    if (target == null || !target.visible) return false;
    if (target.alpha <= 0.01) return false;

    var mp:FlxPoint = FlxG.mouse.getWorldPosition(FlxG.camera);
    return mp.x >= target.x && mp.x <= target.x + target.width &&
           mp.y >= target.y && mp.y <= target.y + target.height;
}

function toggleOption(opt) {
    opt.checked = !opt.checked;

    if (FlxG.save.data != null) {
        Reflect.setField(FlxG.save.data, opt.key, opt.checked);
        FlxG.save.flush();
    }

    FlxTween.cancelTweensOf(opt.check);

    var off = (opt.checkOffset != null) ? opt.checkOffset : CHECK_OFFSET;
    opt.check.y = opt.box.y - off;

    if (opt.checked) {
        opt.check.visible = true;
        opt.check.alpha = 1;
        opt.check.scale.set(0.01, 0.01);
        FlxTween.tween(opt.check.scale, {x: 1, y: 1}, CHECK_DUR, {ease: FlxEase.backOut});
    } else {
        if (opt.check.visible) {
            FlxTween.tween(opt.check.scale, {x: 0.01, y: 0.01}, CHECK_DUR, {
                ease: FlxEase.quadIn,
                onComplete: function(_) {
                    opt.check.visible = false;
                }
            });
        }
    }

    if (opt.key == "vhsEnabled" || opt.key == "vhsCurve" || opt.key == "vhsNew") applyVhsSettings();
}

function update(elapsed:Float) {
    if (vhsShader != null) {
        shaderTime += elapsed;
        var frameVal:Int = Std.int(shaderTime * 30) % 2;
        try { vhsShader.setInt("uFrame", frameVal); } catch (e:Dynamic) {}
    }

    if (transitioning) return;

    if (optionsActive) {
        for (opt in mainOptions) {
            var hover = isMouseOver(opt.box) || isMouseOver(opt.label);
            if (hover && FlxG.mouse.justPressed) toggleOption(opt);
        }

        if (dontShowOption != null) {
            var hover = isMouseOver(dontShowOption.box) || isMouseOver(dontShowOption.label);
            if (hover && FlxG.mouse.justPressed) toggleOption(dontShowOption);
        }

        if (moreOptionsButtonTxt != null && moreOptionsButtonTxt.alpha > 0.5) {
            if (isMouseOver(moreOptionsButtonTxt) && FlxG.mouse.justPressed) {
                toggleMoreOptionsMenu();
            }
        }

        if (moreOptionsOpen && moreOptionsPanelGroup != null && moreOptionsPanelGroup.alpha > 0.5) {
            for (opt in moreOptions) {
                if (!opt.visible || !opt.box.visible) continue;
                var hover = isMouseOver(opt.box) || isMouseOver(opt.label);
                if (hover && FlxG.mouse.justPressed) toggleOption(opt);
            }
        }
    }

    if (enter) {
        var hovering = isMouseOver(enterTxt);
        enterTxt.color = hovering ? 0xFFFFDD : FlxColor.WHITE;
        if (hovering && FlxG.mouse.justPressed) onEnterClicked();
    }
}

function onEnterClicked() {
    if (transitioning || !enter) return;

    transitioning = true;
    enter = false;
    enterTxt.color = FlxColor.WHITE;

    for (opt in mainOptions) {
        if (FlxG.save.data != null)
            Reflect.setField(FlxG.save.data, opt.key, opt.checked);
    }
    if (dontShowOption != null && FlxG.save.data != null)
        Reflect.setField(FlxG.save.data, dontShowOption.key, dontShowOption.checked);
    for (opt in moreOptions) {
        if (FlxG.save.data != null)
            Reflect.setField(FlxG.save.data, opt.key, opt.checked);
    }
    if (FlxG.save.data != null) FlxG.save.flush();

    FlxFlicker.flicker(enterTxt, 1, 0.06, false, false,
        function(flick:FlxFlicker) { enterTxt.alpha = 0; }
    );

    new FlxTimer().start(1.0, function(_) {
        var blackOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        blackOverlay.scrollFactor.set(0, 0);
        blackOverlay.alpha = 0;
        add(blackOverlay);

        FlxTween.tween(blackOverlay, {alpha: 1}, 0.5, {
            onComplete: function(_) {
                if (vhsShader != null) {
                    try { FlxG.camera.removeShader(vhsShader); } catch (e:Dynamic) {}
                    vhsShader = null;
                }
                FlxG.switchState(new ModState("MainMenu"));
            }
        });
    });
}