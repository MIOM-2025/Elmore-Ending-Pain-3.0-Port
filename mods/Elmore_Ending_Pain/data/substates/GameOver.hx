import hxvlc.flixel.FlxVideoSprite;
import flixel.text.FlxTextBorderStyle;

var camOver:FlxCamera = new FlxCamera();
var restart:Bool = false;
var started:Bool = false;
var video:FlxVideoSprite = null;

var noiseTop:FlxSprite = null;
var noiseMid:FlxSprite = null;
var noiseBot:FlxSprite = null;
var bandA:FlxSprite = null;
var bandB:FlxSprite = null;
var vignette:FlxSprite = null;

var vcrRec:FlxText = null;
var vcrMsg:FlxText = null;
var vcrTime:FlxText = null;
var playTime:Float = 0;
var tearT:Float = 0;
var clockAcc:Float = 0;
var clockStr:String = "--:--";

var menuShown:Bool = false;
var menuReady:Bool = false;
var menuSelected:Int = 0;
var mouseSelected:Int = -1;
var menuTitle:FlxText = null;
var menuReplay:FlxText = null;
var menuExit:FlxText = null;
var menuPointer:FlxSprite = null;

function create(event) {
    event.cancel();
    FlxG.sound.music = false;
    camOver.bgColor = 0x0;

    // 先保持当前场景不变，0.7s 后突然黑屏 + 雪花淡入
    new FlxTimer().start(0.7, function(tmr:FlxTimer) {
        if (restart) return;
        FlxG.cameras.add(camOver, false);
        startSnow();
    });
}

function startSnow() {
    started = true;

    // ---- VHS / CRT 四角弯曲 ----
    var vhsNew:Bool = (FlxG.save.data != null && FlxG.save.data.vhsNew == true);
    var vhsShader = new CustomShader(vhsNew ? "vhs_new" : "vhs");
    try { camOver.addShader(vhsShader); } catch (e0:Dynamic) {}
    try { vhsShader.setFloat("uInterlace", 1.0); } catch (e1:Dynamic) {}
    try { vhsShader.uCurvature = 4.0; } catch (e2:Dynamic) {}
    try { vhsShader.setFloat("uCurvature", 4.0); } catch (e3:Dynamic) {}

    video = new FlxVideoSprite(0, 0);
    video.load(Assets.getPath(Paths.video('Static-Death')), [':input-repeat=65535']);
    video.play();
    video.alpha = 0;
    try { video.volume = 0.04; } catch (e:Dynamic) {
        try { video.bitmap.volume = 0.04; } catch (e2:Dynamic) {}
    }
    video.bitmap.onFormatSetup.add(() -> {
        video.setGraphicSize(FlxG.width, FlxG.height);
        video.screenCenter();
    });
    video.bitmap.onEndReached.add(function() {
        if (video != null && !restart) video.play();
    });
    video.camera = camOver;
    add(video);

    // ---- 雪花噪点带 ----
    noiseTop = mkBand(FlxG.height * 0.22, 0xFFFFFF, 0);
    noiseMid = mkBand(FlxG.height * 0.18, 0xE8E8E8, 0);
    noiseBot = mkBand(FlxG.height * 0.26, 0xFFFFFF, 0);

    // ---- 追踪条纹 ----
    bandA = mkBand(4, 0xFFFFFF, 0);
    bandB = mkBand(2, 0xFFFFFF, 0);

    // ---- 四边压暗 ----
    vignette = new FlxSprite();
    vignette.makeGraphic(FlxG.width, FlxG.height);
    vignette.color = 0x000000;
    vignette.scrollFactor.set(0, 0);
    vignette.cameras = [camOver];
    vignette.alpha = 0;
    add(vignette);

    // ---- 录像带 OSD（左上角，黄字黑边）----
    clockStr = nowClock();

    vcrRec = new FlxText(40, 28, 0, "● REC", 34);
    vcrRec.scrollFactor.set(0, 0);
    vcrRec.cameras = [camOver];
    vcrRec.alpha = 0;
    add(vcrRec);
    styleVcr(vcrRec, 34);

    vcrMsg = new FlxText(40, 76, 0, "TAPE DAMAGED", 34);
    vcrMsg.scrollFactor.set(0, 0);
    vcrMsg.cameras = [camOver];
    vcrMsg.alpha = 0;
    add(vcrMsg);
    styleVcr(vcrMsg, 34);

    vcrTime = new FlxText(40, 124, 0, clockStr, 30);
    vcrTime.scrollFactor.set(0, 0);
    vcrTime.cameras = [camOver];
    vcrTime.alpha = 0;
    add(vcrTime);
    styleVcr(vcrTime, 30);

    createMenu();

    // 雪花逐渐显现
    FlxTween.tween(video, {alpha: 1}, 1.2);

    // 文字等雪花显示后再淡入
    FlxTween.tween(vcrRec, {alpha: 0.95}, 0.4, {startDelay: 1.6});
    FlxTween.tween(vcrMsg, {alpha: 1}, 0.4, {startDelay: 1.9});
    FlxTween.tween(vcrTime, {alpha: 0.9}, 0.4, {startDelay: 2.2});
    FlxTween.tween(vignette, {alpha: 0.55}, 0.5, {startDelay: 1.8});
    FlxTween.tween(noiseTop, {alpha: 0.30}, 0.4, {startDelay: 1.4});
    FlxTween.tween(noiseMid, {alpha: 0.22}, 0.4, {startDelay: 1.6});
    FlxTween.tween(noiseBot, {alpha: 0.26}, 0.4, {startDelay: 1.8});
}


function styleVcr(t:FlxText, size:Int) {
    try { t.setFormat(Paths.font('vcr.ttf'), size, 0xFFFFD23F, 'left', FlxTextBorderStyle.OUTLINE, 0xFF000000); } catch (e:Dynamic) {}
    t.color = 0xFFFFD23F;
    t.borderStyle = FlxTextBorderStyle.OUTLINE;
    t.borderColor = 0xFF000000;
    t.borderSize = 2;
}

function createMenu() {
    menuTitle = new FlxText(0, FlxG.height * 0.565, 0, "SELECT?", 46);
    menuTitle.scrollFactor.set(0, 0);
    menuTitle.cameras = [camOver];
    menuTitle.alpha = 0;
    add(menuTitle);
    styleVcr(menuTitle, 46);
    menuTitle.borderSize = 3;
    menuTitle.updateHitbox();
    // 左对齐：等下面选项量好宽度后再统一设置

    menuReplay = new FlxText(0, menuTitle.y + 56, 0, "REPLAY TAPE", 36);
    menuReplay.scrollFactor.set(0, 0);
    menuReplay.cameras = [camOver];
    menuReplay.alpha = 0;
    add(menuReplay);
    styleVcr(menuReplay, 36);
    menuReplay.borderSize = 3;
    menuReplay.updateHitbox();
    menuReplay.x = (FlxG.width - menuReplay.width) * 0.5;

    menuExit = new FlxText(0, menuReplay.y + 46, 0, "EXIT", 36);
    menuExit.scrollFactor.set(0, 0);
    menuExit.cameras = [camOver];
    menuExit.alpha = 0;
    add(menuExit);
    styleVcr(menuExit, 36);
    menuExit.borderSize = 3;
    menuExit.updateHitbox();
    menuTitle.x = menuReplay.x;
    menuExit.x = menuReplay.x;

    menuPointer = makePointer();
    menuSelected = 0;
    refreshPointer();
}

function makePointer():FlxSprite {
    var p = new FlxSprite();
    p.makeGraphic(14, 18, 0x00000000);
    for (y in 0...18) {
        var len:Int = Std.int(7.0 * (1.0 - Math.abs(y - 8.5) / 8.5));
        for (x in 0...len) {
            p.pixels.setPixel32(x, y, 0xFFFFD23F);
        }
    }
    p.dirty = true;
    p.scrollFactor.set(0, 0);
    p.cameras = [camOver];
    p.alpha = 0;
    add(p);
    return p;
}

function refreshPointer() {
    if (menuPointer == null) return;
    var t:FlxText = (menuSelected == 0) ? menuReplay : menuExit;
    menuPointer.x = t.x - 30;
    menuPointer.y = t.y + (t.height - menuPointer.height) * 0.5;
}

function showMenu() {
    if (menuShown) return;
    menuShown = true;
    mouseSelected = -1;
    FlxTween.tween(menuTitle, {alpha: 0.95}, 0.45);
    FlxTween.tween(menuReplay, {alpha: 0.95}, 0.45, {startDelay: 0.12});
    FlxTween.tween(menuExit, {alpha: 0.95}, 0.45, {startDelay: 0.22});
    FlxTween.tween(menuPointer, {alpha: 1.0}, 0.45, {startDelay: 0.12});
    new FlxTimer().start(0.60, function(t:FlxTimer) { menuReady = true; });
}

function overPoint(px:Float, py:Float, t:FlxText):Bool {
    if (t == null) return false;
    return px >= t.x - 18 && px <= t.x + t.width + 18 && py >= t.y - 10 && py <= t.y + t.height + 10;
}

function overViewPoint(px:Float, py:Float, t:FlxText):Bool {
    if (t == null) return false;
    // 文字挂在这个摄像机下、scrollFactor=0，所以用摄像机的 view 坐标做命中
    var left:Float = t.x - camOver.scroll.x * t.scrollFactor.x - camOver.viewMarginX;
    var top:Float = t.y - camOver.scroll.y * t.scrollFactor.y - camOver.viewMarginY;
    return px >= left - 18 && px <= left + t.width + 18 && py >= top - 10 && py <= top + t.height + 10;
}

function overText(t:FlxText):Bool {
    if (t == null) return false;
    // camOver 和主摄像机不同，优先用 camOver 自己的 view 坐标映射
    try {
        var vp = FlxG.mouse.getViewPosition(camOver);
        if (vp != null && overViewPoint(vp.x, vp.y, t)) return true;
    } catch (e:Dynamic) {}
    // 兼容旧版：world 坐标减去 scroll（因为 scrollFactor=0）
    try {
        var wp = FlxG.mouse.getWorldPosition(camOver);
        if (wp != null) {
            wp.x -= camOver.scroll.x;
            wp.y -= camOver.scroll.y;
            if (overPoint(wp.x, wp.y, t)) return true;
        }
    } catch (e:Dynamic) {}
    return false;
}

function overTouch(touch:Dynamic, t:FlxText):Bool {
    if (touch == null || t == null) return false;
    try {
        var vp = touch.getViewPosition(camOver);
        if (vp != null && overViewPoint(vp.x, vp.y, t)) return true;
    } catch (e:Dynamic) {}
    try {
        var wp = touch.getWorldPosition(camOver);
        if (wp != null) {
            wp.x -= camOver.scroll.x;
            wp.y -= camOver.scroll.y;
            if (overPoint(wp.x, wp.y, t)) return true;
        }
    } catch (e:Dynamic) {}
    return false;
}

function clickOption(index:Int) {
    if (menuSelected != index) {
        menuSelected = index;
        mouseSelected = index;
        refreshPointer();
        return;
    }
    if (mouseSelected == index) {
        chooseMenu();
    } else {
        mouseSelected = index;
        refreshPointer();
    }
}

function chooseMenu() {
    if (restart) return;
    restart = true;
    if (FlxG.sound.music != null && FlxG.sound.music != false) {
        try { FlxG.sound.music.stop(); } catch (e:Dynamic) {}
    }
    FlxG.sound.music = null;
    if (video != null) {
        try { video.stop(); } catch (e:Dynamic) {}
    }
    if (menuSelected == 0) {
        FlxG.switchState(new PlayState());
    } else {
        FlxG.switchState(new ModState("MainMenu"));
    }
}

function nowClock():String {
    var d:Date = Date.now();
    var hh:Int = d.getHours();
    var mm:Int = d.getMinutes();
    var hs:String = Std.string(hh);
    var ms:String = Std.string(mm);
    if (hh < 10) hs = "0" + hs;
    if (mm < 10) ms = "0" + ms;
    return hs + ":" + ms;
}

function mkBand(h:Float, col:Int, a:Float):FlxSprite {
    var s = new FlxSprite();
    s.makeGraphic(FlxG.width, h);
    s.color = col;
    s.scrollFactor.set(0, 0);
    s.cameras = [camOver];
    s.alpha = a;
    s.screenCenter();
    add(s);
    return s;
}

function update(elpased:Float) {
    if (!started) return;
    if (!restart) {
        playTime += elpased;

        // REC 闪烁（最上面那行）
        if (vcrRec != null) {
            if (Math.sin(playTime * 6.0) > 0) {
                vcrRec.alpha = 0.95;
            } else {
                vcrRec.alpha = 0.15;
            }
        }

        // 现实时间（每 0.5s 刷新）
        clockAcc += elpased;
        if (clockAcc >= 0.5) {
            clockAcc = 0;
            var c:String = nowClock();
            if (vcrTime != null && c != clockStr) {
                clockStr = c;
                vcrTime.text = c;
            }
        }

        // 3s 后进入断开状态：画面持续跳动
        if (playTime > 2.6) {
            tearT -= elpased;
            if (tearT <= 0) {
                tearT = 0.05 + Math.random() * 0.09;
                if (video != null) {
                    video.x = FlxG.width * 0.5 - video.width * 0.5 + (Math.random() - 0.5) * 26;
                    video.y = FlxG.height * 0.5 - video.height * 0.5 + (Math.random() - 0.5) * 10;
                }
                if (bandA != null) {
                    bandA.y = Math.random() * FlxG.height;
                    bandA.alpha = 0.25 + Math.random() * 0.35;
                }
                if (bandB != null) {
                    bandB.y = Math.random() * FlxG.height;
                    bandB.alpha = 0.15 + Math.random() * 0.25;
                }
            }
        }

        // 噪点带缓慢移动
        if (noiseTop != null) noiseTop.y += elpased * 34;
        if (noiseMid != null) noiseMid.y -= elpased * 51;
        if (noiseBot != null) noiseBot.y += elpased * 21;

        // 死亡画面稳定后出现选择菜单
        if (!menuShown && playTime > 3.0) showMenu();

        if (menuShown && menuPointer != null) {
            var target:FlxText = (menuSelected == 0) ? menuReplay : menuExit;
            var baseY:Float = target.y + (target.height - menuPointer.height) * 0.5;
            menuPointer.y = baseY + Math.sin(playTime * 7.0) * 3.0;
        }
    }

    if (restart) return;

    if (!menuShown) {
        if (controls.BACK) {
            restart = true;
            if (video != null) {
                try { video.stop(); } catch (e:Dynamic) {}
            }
            FlxG.switchState(new ModState("MainMenu"));
        }
        return;
    }

    if (!menuReady) return;

    if (controls.UP_P || controls.DOWN_P) {
        menuSelected = (menuSelected == 0) ? 1 : 0;
        mouseSelected = -1;
        refreshPointer();
    }

    // 鼠标/触屏优先：第一次点只选择，第二次点同一个选项才进入
    var pointerMiss:Bool = false;
    if (FlxG.mouse.justPressed) {
        if (overText(menuReplay)) {
            clickOption(0);
            return;
        }
        if (overText(menuExit)) {
            clickOption(1);
            return;
        }
        mouseSelected = -1;
        pointerMiss = true;
    }

    // 触屏映射：有些设备不会把触摸转成 FlxG.mouse，必须单独读 FlxG.touches
    if (FlxG.touches.list != null) {
        for (touch in FlxG.touches.list) {
            if (touch.justPressed) {
                if (overTouch(touch, menuReplay)) {
                    clickOption(0);
                    return;
                }
                if (overTouch(touch, menuExit)) {
                    clickOption(1);
                    return;
                }
                mouseSelected = -1;
                return;
            }
        }
    }

    if (pointerMiss) return;

    if (controls.ACCEPT) {
        chooseMenu();
        return;
    }

    if (controls.BACK) {
        menuSelected = 1;
        chooseMenu();
    }
}
