var eep_gf:FlxSprite;

function create() {
    GameOverSubstate.script = "data/substates/GameOver";
}

function postCreate() {
    	eep_gf = new FlxSprite(400, 107);
		eep_gf.frames = Paths.getSparrowAtlas('characters/RITA');
		eep_gf.animation.addByPrefix("idle", 'RITA idle', 24, false);
		eep_gf.antialiasing = true;
		eep_gf.scale.set(0.75, 0.75);
		insert(members.indexOf(gf), eep_gf);
}

function beatHit() {
    if(curBeat % 1 == 0) {
        eep_gf.animation.play('idle');
    }
}

function fadeStage() {
	for(bgAssets in [bg, sillas, eep_gf])
		bgAssets.visible = false;
}

function showStage() {
	for(bgAssets in [bg, sillas, eep_gf])
		bgAssets.visible = true;
}

function onPostGameOver() {
    new FlxTimer().start(2, function(tmr:FlxTimer) {
		camGame.visible = false;
	});
    camHUD.visible = false;
    persistentDraw = true;
}