import flixel.util.FlxAxes;
import flixel.util.FlxSpriteUtil;
import openfl.utils.Assets;

public var finesHP:FlxSpriteGroup;
public var grpHudUIAssets:FlxSpriteGroup;
var heart:FlxSprite;
var bords:FlxSprite;
var usingLife2:Bool = false;

// ===== 血量块尺寸 =====
var hpCanvasW:Int = 36;
var hpCanvasH:Int = 300;
var hpBarW:Int = 34;
var hpBarH:Int = 100;
var hpSpacing:Float = 34;
var hpBaseX:Float = 275;
var hpYOffset:Float = 50;

var hpBaseScale:Float = 0.55;
var life2Scale:Float = 0.50;
var life2YOffset:Float = 16;
var hpPeakAmplitude:Float = 0.6;
var hpDecayPerIndex:Float = 0.82;
var hpWaveDelay:Float = 0.04;   // 恢复原来的传递速度

function create()
    isSustainNote = false;

function postCreate() {
    for (items in [iconP1, iconP2, scoreTxt, missesTxt, accuracyTxt, healthBar, healthBarBG])
        items.kill();

    grpHudUIAssets = new FlxSpriteGroup();
    add(grpHudUIAssets);

    bords = new FlxSprite(-130, 740 + (Options.downscroll) ? -130 : 720).loadGraphic(Paths.image("hud/health_bar_thing"));
    bords.scale.set(0.55, 0.55);
    bords.camera = camHUD;
    grpHudUIAssets.add(bords);

    var censorHealth:Bool = (FlxG.save.data != null && FlxG.save.data.censorHealth == true);
    var heartAsset:String = censorHealth ? "hud/life2" : "hud/heart";
    if (censorHealth && !Assets.exists(Paths.image(heartAsset))) heartAsset = "hud/heart";
    usingLife2 = (heartAsset == "hud/life2");
    heart = new FlxSprite(88, 600 + (Options.downscroll) ? 75 : 630).loadGraphic(Paths.image(heartAsset));
    if (usingLife2) {
        // life2 is shorter than the original heart: nudge it down and slightly smaller.
        heart.y += life2YOffset;
        heart.scale.set(life2Scale, life2Scale);
    } else {
        heart.scale.set(0.55, 0.55);
    }
    grpHudUIAssets.add(heart);
    grpHudUIAssets.camera = camHUD;

    finesHP = new FlxSpriteGroup();
    add(finesHP);

    for (i in 0...8) {
        var hpThing = new FlxSprite(0, 0);
        hpThing.makeGraphic(hpCanvasW, hpCanvasH, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawRect(
            hpThing,
            Std.int((hpCanvasW - hpBarW) / 2),
            Std.int((hpCanvasH - hpBarH) / 2),
            hpBarW, hpBarH,
            FlxColor.WHITE
        );

        hpThing.updateHitbox();
        hpThing.offset.set(0, 0);
        hpThing.origin.set(hpCanvasW / 2, hpCanvasH / 2);
        hpThing.scale.set(hpBaseScale, hpBaseScale);

        hpThing.ID = i;
        finesHP.add(hpThing);
        finesHP.camera = camHUD;
    }

    syncHpPositions();

    for (hud in [grpHudUIAssets, finesHP]) {
        hud.alpha = 0;
    }
}

function syncHpPositions() {
    if (bords == null || finesHP == null) return;
    var bordsVisualCenterY:Float = bords.y + (bords.height * bords.scale.y) * 0.5;
    var spriteY:Float = bordsVisualCenterY - hpCanvasH / 2 + hpYOffset;

    for (i in 0...finesHP.length) {
        var hpThing:FlxSprite = cast finesHP.members[i];
        if (hpThing == null) continue;
        hpThing.x = hpBaseX + i * hpSpacing;
        hpThing.y = spriteY;
    }
}

function beatHit() {
    if (curBeat % 2 == 0) {
        var baseScale:Float = usingLife2 ? life2Scale : 0.55;
        heart.scale.set(baseScale * 1.15, baseScale * 1.15);
        triggerPulseWave();
    }
}

function triggerPulseWave() {
    for (i in 0...finesHP.length) {
        var hpThing:FlxSprite = cast finesHP.members[i];
        if (hpThing == null) continue;

        var delay = i * hpWaveDelay;
        var amplitude = hpPeakAmplitude * Math.pow(hpDecayPerIndex, i);
        var peakScale = hpBaseScale * (1 + amplitude);

        FlxTween.cancelTweensOf(hpThing.scale);
        hpThing.scale.set(hpBaseScale, hpBaseScale);

        var driver = {v: hpBaseScale};

        FlxTween.tween(driver, {v: peakScale}, 0.08, {
            startDelay: delay,
            ease: FlxEase.quadOut,
            onUpdate: function(_) {
                hpThing.scale.y = driver.v;
            },
            onComplete: function(_) {
                FlxTween.tween(driver, {v: hpBaseScale}, 0.25, {
                    ease: FlxEase.quadOut,
                    onUpdate: function(__) {
                        hpThing.scale.y = driver.v;
                    }
                });
            }
        });
    }
}

var lifes:Float = 8;
function onPlayerMiss(event) {
    if (event.note.isSustainNote) return;
    lifes--;
}

function postUpdate() {
    var baseScale:Float = usingLife2 ? life2Scale : 0.55;
    heart.scale.set(lerp(heart.scale.x, baseScale, 0.2), lerp(heart.scale.y, baseScale, 0.2));

    syncHpPositions();

    finesHP.forEachAlive(function(item:FlxSprite) {
        item.visible = item.ID < lifes;
    }, false);
    if (lifes == 0) health = 0;
}

function stepHit() {
    switch(curStep) {
        case 256:
            for (hud in [grpHudUIAssets, finesHP]) {
                FlxTween.tween(hud, {alpha: 1}, 1);
            }
        case 946:
            for (hud in [grpHudUIAssets, finesHP]) {
                hud.visible = false;
            }
    }
}