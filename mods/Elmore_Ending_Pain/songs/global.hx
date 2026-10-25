importScript("data/scripts/note_skins");
importScript("data/scripts/comboScript");

import flixel.math.FlxBasePoint;

public var vhsShader = new CustomShader("vhs");
public var curveShader = new CustomShader("curvature");
public var camChain:FlxCamera = new FlxCamera();
public var opponentStrum:Array<FlxBasePoint> = [];
public var playerStrum:Array<FlxBasePoint> = [];
public var camVideos:FlxCamera;
function create(){
    noteSkin = "EEPNOTE_assets";
    remove(splashHandler);

    camVideos = new FlxCamera();
    camVideos.bgColor = 0x0;
}

function postCreate() {

    camChain.bgColor = 0x0;

    FlxG.cameras.remove(camHUD, false);
    FlxG.cameras.add(camVideos, false);
    FlxG.cameras.add(camHUD, false);
    FlxG.cameras.add(camChain, false);

    var vhsOn:Bool = (FlxG.save.data == null || FlxG.save.data.vhsEnabled != false);
    var vhsCurve:Bool = (FlxG.save.data == null || FlxG.save.data.vhsCurve != false);
    if (vhsOn) {
        var vhsNew:Bool = (FlxG.save.data != null && FlxG.save.data.vhsNew == true);
        vhsShader = new CustomShader(vhsNew ? "vhs_new" : "vhs");
        camGame.addShader(vhsShader);
        camHUD.addShader(vhsShader);
        var curveVal:Float = vhsCurve ? 4.0 : 0.0;
        try { vhsShader.uCurvature = curveVal; } catch (e:Dynamic) {}
        try { vhsShader.setFloat("uCurvature", curveVal); } catch (e:Dynamic) {}
        if (vhsCurve) {
            camChain.addShader(curveShader);
            try { curveShader.uCurvature = curveVal; } catch (e:Dynamic) {}
            try { curveShader.setFloat("uCurvature", curveVal); } catch (e:Dynamic) {}
        }
    }

    add(asLogo = new FlxSprite(900, 850 + (Options.downscroll) ? 900 : 850).loadGraphic(Paths.image("as")));
    asLogo.scale.set(0.7, 0.7);
    asLogo.camera = camChain;
    asLogo.alpha = .6;

    for (i in [0,1,2,3]) {
        var strum = strumLines.members[0].members[i];
        opponentStrum.push(new FlxBasePoint().set(strum.x,strum.y));

        var strum = strumLines.members[1].members[i];
        playerStrum.push(new FlxBasePoint().set(strum.x,strum.y));
    }
}
function onPostGameOver() 
    new FlxTimer().start(2, function(tmr:FlxTimer) {
		camChain.visible = false;
	});

//function onGamePause(e) e.cancel();