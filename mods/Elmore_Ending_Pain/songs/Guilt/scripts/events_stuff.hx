importScript("data/scripts/heart_hud");

import hxvlc.flixel.FlxVideoSprite;

var barCam:FlxCamera = new FlxCamera();

public var characterWhite = new CustomShader("effectorsomethingbysawako");
public var saturation = new CustomShader("saturation");

function create() 
    introLength = 0;

function postCreate() {

    if (FlxG.save.data == null || FlxG.save.data.vhsEnabled != false) camVideos.addShader(vhsShader);
    camGame.addShader(characterWhite);
    camGame.addShader(saturation);

    saturation.sat = 1;
    characterWhite.intensity = 0;

    blackend = new FlxSprite().makeGraphic(1280,720, FlxColor.BLACK);
    blackend.y = 700;
    blackend.alpha = 0;
    blackend.scale.set(5,5);
    insert(members.indexOf(gf), blackend);


    for (strum in cpuStrums.notes) strum.alpha = 0;
    for (note in [0,1,2,3]) {
        var opponentStrum = strumLines.members[0].members[note];
        opponentStrum.alpha = 0;
        var playerStrum = strumLines.members[1].members[note];
        playerStrum.alpha = 0;
    }

    camGame.fade(FlxColor.BLACK, 0.001, false);
    gf.alpha = 0;
}

function waveFlash() {
    for (shadergrup in [saturation, characterWhite]) 
        FlxTween.cancelTweensOf(shadergrup);

    characterWhite.intensity = 0.6;
    FlxTween.tween(characterWhite, {intensity:0}, 1.5);
    saturation.sat = 1.75;
    FlxTween.tween(saturation, {sat:1}, 1.5);
}

function colorFlash() {
    saturation.sat = 1.75;
    FlxTween.tween(saturation, {sat:1}, 1.5);
}

function stepHit() {
    switch(curStep) {
        case 1:
            blackend.alpha = 0.6;
        case 70:
            camGame.fade(FlxColor.BLACK, 0.001, true);
        case 132:
            for (strum in cpuStrums.notes) FlxTween.tween(strum, {alpha: 1}, 1);
            
            for (note in [0,1,2,3]) {
                var opponentStrum = strumLines.members[0].members[note];
                FlxTween.tween(opponentStrum, {alpha: 1}, 1);
            }
        case 190:
            for (note in [0,1,2,3]) {
                var playerStrum = strumLines.members[1].members[note];
                FlxTween.tween(playerStrum, {alpha: 1}, 1);
            }
        case 256:
            blackend.alpha = 0;
        case 766:
            FlxTween.tween(saturation, {sat : 0.3}, 0.5);
        case 776:
            saturation.sat = 1;
        case 876:
            camGame.fade(FlxColor.BLACK, 1, false);
        case 878, 1156:
            FlxTween.tween(camHUD, {alpha : 0}, 1);
        case 946:
            for (strum in cpuStrums.notes) strum.visible = false;
            
            for (note in [0,1,2,3]) {
                var opponentStrum = strumLines.members[0].members[note];
                opponentStrum.visible = false;
            }
        case 948:
            FlxTween.tween(camHUD, {alpha : 1}, 1);
    }
}