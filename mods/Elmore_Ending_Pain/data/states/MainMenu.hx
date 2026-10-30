import flixel.util.FlxAxes;
import flixel.text.FlxTextBorderStyle;
import funkin.backend.utils.CoolSfx;
import funkin.menus.credits.CreditsMain;
import funkin.options.OptionsMenu;
import funkin.menus.ModSwitchMenu;
import funkin.editors.EditorPicker;
import lime.system.System;
import funkin.backend.utils.CoolUtil;
import funkin.backend.utils.DiscordUtil;

var camMenu:FlxCamera = new FlxCamera();
var camOptions:FlxCamera = new FlxCamera();
var grpGroupOptions:FlxSpriteGroup;
var bg:FlxSprite;
var bg_3:FlxSprite;
var bg_4:FlxSprite;
var logo:FlxSprite;
var tadTxt:FunkinText;
var creditsTxt:FunkinText;
var hxandCNE:FlxSprite;
public var vhsShader = new CustomShader("vhs");
public var optionsArray:Array<String> = [
    "Play",
    "Options",
    "Credits",
    "Exit"
];

var canAccessDebugMenus:Bool = true;
static var isStarted:Bool = false;
static var curSelected:Int = -1;
var beats:Bool = true;
var canInteract:Bool = false;
var logoBop:Bool = false;

var introPhase:Int = 0;
var canSkip:Bool = false;
var logoAccelerated:Bool = false;
var optionsRevealed:Bool = false;

var mousePressedOption:Int = -1;
var inCredits:Bool = false;

var camAngle:Float = 0;
var camRadiusX:Float = 25;
var camRadiusY:Float = 30;

function create()
{
    DiscordUtil.call("onMenuLoaded", ["Main Menu"]);

    FlxG.mouse.visible = true;
    CoolUtil.playMenuSong(true);

    camMenu.bgColor = 0x0;
    FlxG.cameras.add(camMenu, false);

    camOptions.bgColor = 0x0;
    FlxG.cameras.add(camOptions, false);

    var vhsOn:Bool = (FlxG.save.data == null || FlxG.save.data.vhsEnabled != false);
    var vhsCurve:Bool = (FlxG.save.data == null || FlxG.save.data.vhsCurve != false);
    if (vhsOn) {
        var vhsNew:Bool = (FlxG.save.data != null && FlxG.save.data.vhsNew == true);
        vhsShader = new CustomShader(vhsNew ? "vhs_new" : "vhs");
        camMenu.addShader(vhsShader);
        camOptions.addShader(vhsShader);
        var curveVal:Float = vhsCurve ? 4.0 : 0.0;
        try { vhsShader.uCurvature = curveVal; } catch (e:Dynamic) {}
        try { vhsShader.setFloat("uCurvature", curveVal); } catch (e:Dynamic) {}
    }

    bg = new FlxSprite(-70, 0).loadGraphic(Paths.image("menu/menu_concept_4"));
    bg.camera = camMenu;
    bg.scale.set(1, 1);
    bg.scrollFactor.set(1, 1);
    add(bg);

    bg_3 = new FlxSprite(-70, 0).loadGraphic(Paths.image("menu/menu_concept_2"));
    bg_3.camera = camMenu;
    bg_3.scale.set(1, 1);
    bg_3.scrollFactor.set(0.7, 0.7);
    add(bg_3);

    bg_4 = new FlxSprite(-70, 0).loadGraphic(Paths.image("menu/menu_concept_1"));
    bg_4.camera = camMenu;
    bg_4.scale.set(1, 1);
    bg_4.scrollFactor.set(1, 1);
    add(bg_4);

    logo = new FlxSprite(0, -370).loadGraphic(Paths.image("menu/LogoMOD"));
    logo.scale.set(0.35, 0.35);
    logo.camera = camOptions;
    logo.screenCenter(FlxAxes.X);
    add(logo);

    tadTxt = new FunkinText(0, 200, 0, "Made with:", 40);
    tadTxt.setFormat(Paths.font("Adult-Swim-Font.ttf"), 40, FlxColor.WHITE);
    tadTxt.screenCenter(FlxAxes.X);
    tadTxt.alpha = 0;
    tadTxt.antialiasing = Options.antialiasing;
    add(tadTxt);

    creditsTxt = new FunkinText(
        500, 50, 0,
        "girl director:\n" +
        "Lily - art, animation, conceptual art\n\n" +
        "Composer:\n" +
        "Cinder - Guilt composer\n\n" +
        "Artists:\n" +
        "ElbenjaG - art, 3D modeling, animation\n" +
        "Saint_Damien - art, conceptual art and help\n" +
        "Jesús Viloria - logo\n" +
        "Unkooldude - small help\n" +
        "THE COFFE ARTS - cover art\n" +
        "Solaria - art\n\n" +
        "Programming:\n" +
        "Zoulin! - code\n" +
        "bennydoodles.fla - Guilt chart\n" +
        "MIOM - mobile port\n\n" +
        "Special thanks:\n" +
        "tjghostly - menu theme\n" +
        "Strawberrycode - small coding help\n" +
        "'The grieving' belongs to GlobaLuna/xxZeroZonexx",
        32
    );
    creditsTxt.setFormat(Paths.font("Adult-Swim-Font.ttf"), 32, FlxColor.WHITE);
    creditsTxt.alignment = "center";
    creditsTxt.camera = camOptions;
    creditsTxt.alpha = 0;
    creditsTxt.antialiasing = Options.antialiasing;
    add(creditsTxt);

    hxandCNE = new FlxSprite(0, -370).loadGraphic(Paths.image("menu/CNE AND HX"));
    hxandCNE.scale.set(0.5, 0.5);
    hxandCNE.camera = camOptions;
    hxandCNE.alpha = 0;
    hxandCNE.screenCenter(FlxAxes.XY);
    add(hxandCNE);

    grpGroupOptions = new FlxSpriteGroup();
    grpGroupOptions.camera = camOptions;
    add(grpGroupOptions);

    for (i in 0...optionsArray.length)
    {
        var option = new FunkinText(150, 350 + (i * 90), 0, optionsArray[i], 80);
        option.setFormat(Paths.font("Adult-Swim-Font.ttf"), 80, FlxColor.WHITE, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
        option.borderSize = 3.5;
        option.antialiasing = Options.antialiasing;
        option.ID = i;
        grpGroupOptions.add(option);
    }

    updateSelectionPositions();

    if (isStarted)
    {
        bg.alpha = bg_3.alpha = bg_4.alpha = 1;
        logo.alpha = 1;
        grpGroupOptions.alpha = 1;
        tadTxt.visible = false;
        hxandCNE.visible = false;
        canInteract = true;
        logoBop = true;
        introPhase = 2;
        optionsRevealed = true;
    }
    else
    {
        introEEP();
    }
}

function introEEP()
{
    if (isStarted) return;

    introPhase = 0;
    canSkip = true;
    logoAccelerated = false;
    optionsRevealed = false;

    for (asset in [grpGroupOptions, bg, bg_3, bg_4, logo])
        asset.alpha = 0;

    FlxTween.tween(tadTxt,{alpha: 1},0.1,{startDelay: 1});
    FlxTween.tween(hxandCNE,{alpha: 1},1,{startDelay: 2});
    FlxTween.tween(hxandCNE,{"scale.x": 0.6,"scale.y": 0.6},4,{startDelay: 2});
    new FlxTimer().start(4, function(tmr:FlxTimer) {
        tadTxt.visible = false;
        hxandCNE.visible = false;
    });

    logo.y = -100;
    logo.scale.set(0.55, 0.55);
    logo.alpha = 0;

    new FlxTimer().start(5, function(tmr:FlxTimer) {
        if (introPhase != 0) return;
        introPhase = 1;
        canSkip = false;
        playLogoPhase();
    });
}

function skipToLogoPhase()
{
    if (introPhase != 0) return;
    introPhase = 1;
    canSkip = false;

    FlxTween.cancelTweensOf(tadTxt);
    FlxTween.cancelTweensOf(hxandCNE);

    tadTxt.visible = false;
    tadTxt.alpha = 0;
    hxandCNE.visible = false;
    hxandCNE.alpha = 0;

    logo.y = -100;
    logo.scale.set(0.55, 0.55);
    logo.alpha = 0;

    playLogoPhase();
}

function playLogoPhase()
{
    FlxTween.tween(logo,{"scale.x": 0.6,"scale.y": 0.6},1,{ease: FlxEase.quadInOut});
    FlxTween.tween(logo,{alpha: 1},1,{ease: FlxEase.quadInOut,onComplete: _ -> {
        for (asset in [bg, logo, bg_3, bg_4]) FlxTween.tween(asset,{alpha: 1},1.5,{startDelay: 0.5});
        FlxTween.tween(logo,{"scale.x": 0.35,"scale.y": 0.35},2,{ease: FlxEase.quadInOut,startDelay: 0.5});
        FlxTween.tween(logo,{y: -370},2,{
            ease: FlxEase.quadInOut,
            startDelay: 0.5,
            onComplete: _ -> {
                FlxTween.tween(grpGroupOptions,{alpha: 1},1,{startDelay: 1});
                beats = false;
                logoBop = true;
                canInteract = true;
                isStarted = true;
                introPhase = 2;
                optionsRevealed = true;
            }
        });
    }});
}

// ============ 加速 logo 阶段（先快后慢 expoOut） ============
function accelerateLogoPhase()
{
    if (logoAccelerated || introPhase != 1) return;
    logoAccelerated = true;

    FlxTween.cancelTweensOf(logo);
    FlxTween.cancelTweensOf(bg);
    FlxTween.cancelTweensOf(bg_3);
    FlxTween.cancelTweensOf(bg_4);

    // expoOut：起步极快，越接近终点越慢
    FlxTween.tween(logo, {alpha: 1, y: -370, "scale.x": 0.35, "scale.y": 0.35}, 0.9, {ease: FlxEase.expoOut});
    FlxTween.tween(bg,   {alpha: 1}, 0.9, {ease: FlxEase.expoOut});
    FlxTween.tween(bg_3, {alpha: 1}, 0.9, {ease: FlxEase.expoOut});
    FlxTween.tween(bg_4, {alpha: 1}, 0.9, {ease: FlxEase.expoOut});

    if (!optionsRevealed) {
        optionsRevealed = true;
        // 选项一露出来就能选/能点，不等淡入结束
        canInteract = true;
        FlxTween.cancelTweensOf(grpGroupOptions);
        FlxTween.tween(grpGroupOptions, {alpha: 1}, 1.0, {ease: FlxEase.expoOut});
    }

    new FlxTimer().start(1.0, function(_) {
        beats = false;
        logoBop = true;
        canInteract = true;
        isStarted = true;
        introPhase = 2;
    });
}

function showCreditsEEP()
{
    inCredits = true;
    FlxTween.cancelTweensOf(logo);
    FlxTween.cancelTweensOf(creditsTxt);
    FlxTween.tween(logo, {alpha: 0}, 1);
    FlxTween.tween(creditsTxt, {alpha: 1}, 1);
}

function fadeCreditsEEP()
{
    inCredits = false;
    FlxTween.cancelTweensOf(logo);
    FlxTween.cancelTweensOf(creditsTxt);
    FlxTween.tween(logo,{alpha: 1},1);
    FlxTween.tween(creditsTxt,{alpha: 0},1);
}

function beatHit()
{
    if (curBeat % 2 == 0 && logoBop)
    {
        logo.scale.set(0.38, 0.38);
    }
}

function update(elapsed:Float)
{
    if (!isStarted && canSkip && FlxG.mouse.justPressed)
    {
        skipToLogoPhase();
    }
    else if (!isStarted && introPhase == 1 && !logoAccelerated && FlxG.mouse.justPressed)
    {
        accelerateLogoPhase();
    }

    if (logoBop) logo.scale.set(lerp(logo.scale.x, 0.35, 0.2), lerp(logo.scale.y, 0.35, 0.2));
    updateMenuControls();
    updateCamera(elapsed);

    if (!canAccessDebugMenus)
        return;
}

function updateMenuControls()
{
    if (!canInteract) return;

    if (inCredits)
    {
        if (FlxG.mouse.justPressed)
        {
            fadeCreditsEEP();
        }
        return;
    }

    // ===== 悬停检测 =====
    var hoveredOption:Int = -1;
    for (item in grpGroupOptions.members)
    {
        if (FlxG.mouse.overlaps(item))
        {
            hoveredOption = item.ID;
            break;
        }
    }

    // ===== 更新选中状态（悬停即选中，离开即取消） =====
    if (hoveredOption == -1)
    {
        if (curSelected != -1)
        {
            curSelected = -1;
            updateSelectionPositions();
        }
    }
    else
    {
        if (curSelected != hoveredOption)
        {
            curSelected = hoveredOption;
            updateSelectionPositions();
        }
    }

    // ===== 鼠标按下：只有在"已选中该选项"的状态下按下，才记录 =====
    if (FlxG.mouse.justPressed)
    {
        if (curSelected != -1 && hoveredOption == curSelected)
        {
            mousePressedOption = hoveredOption;
        }
        else
        {
            mousePressedOption = -1;
        }
    }

    // ===== 鼠标松开：按下 + 松开在同一选项，且该选项仍是选中状态 =====
    if (FlxG.mouse.justReleased)
    {
        if (mousePressedOption != -1 &&
            hoveredOption == mousePressedOption &&
            curSelected == mousePressedOption)
        {
            optionSelected();
        }
        mousePressedOption = -1;
    }

    // ===== 键盘操作 =====
    if (controls.ACCEPT && curSelected != -1)
    {
        optionSelected();
        return;
    }

    if (controls.UP_P)
    {
        if (curSelected == -1) curSelected = 0;
        else curSelected = FlxMath.wrap(curSelected - 1, 0, optionsArray.length - 1);
        updateSelectionPositions();
    }
    else if (controls.DOWN_P)
    {
        if (curSelected == -1) curSelected = 0;
        else curSelected = FlxMath.wrap(curSelected + 1, 0, optionsArray.length - 1);
        updateSelectionPositions();
    }

    if (controls.BACK)
    {
        fadeCreditsEEP();
    }
}

function updateSelectionPositions()
{
    for (item in grpGroupOptions.members)
    {
        FlxTween.cancelTweensOf(item);
        FlxTween.tween(item, {x: item.ID == curSelected ? 180 : 160}, 0.2, {ease: FlxEase.cubeOut});
    }
}

// ============ 摄像机自动环绕 ============
function updateCamera(elapsed:Float)
{
    var baseSpeed:Float = 0.12;
    var speedMultiplier:Float = 1.0 + 0.4 * Math.abs(Math.sin(camAngle));
    camAngle += elapsed * baseSpeed * speedMultiplier;

    var targetX:Float = Math.cos(camAngle) * camRadiusX;
    var targetY:Float = Math.sin(camAngle) * camRadiusY;

    var smooth:Float = FlxMath.bound(elapsed * 2.0, 0.0, 1.0);
    camMenu.scroll.x = FlxMath.lerp(camMenu.scroll.x, targetX, smooth);
    camMenu.scroll.y = FlxMath.lerp(camMenu.scroll.y, targetY, smooth);
}

function changeSelection(change:Int = 0)
{
    curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);
    updateSelectionPositions();
}

function optionSelected()
{
    switch (optionsArray[curSelected])
    {
        case "Play":
            PlayState.loadSong("Guilt","hard");
            FlxG.switchState(new PlayState());
        case "Options":
            FlxG.switchState(new OptionsMenu());
        case "Credits":
            showCreditsEEP();
        case "Exit":
            System.exit(0);
    }
}