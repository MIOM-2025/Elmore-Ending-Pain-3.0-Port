var bords:FlxSprite;
public var vhsShader = new CustomShader("vhs");

function postCreate() {
    bg.loadGraphic(Paths.image("menu/EEP_BG"));
    bg.setGraphicSize(FlxG.width, FlxG.height);
    bg.screenCenter();
    bg.antialiasing = Options.antialiasing;

    var vhsOn:Bool = (FlxG.save.data == null || FlxG.save.data.vhsEnabled != false);
    var vhsCurve:Bool = (FlxG.save.data == null || FlxG.save.data.vhsCurve != false);
    if (vhsOn) {
        var vhsNew:Bool = (FlxG.save.data != null && FlxG.save.data.vhsNew == true);
        vhsShader = new CustomShader(vhsNew ? "vhs_new" : "vhs");
        FlxG.camera.addShader(vhsShader);
        var curveVal:Float = vhsCurve ? 4.0 : 0.0;
        try { vhsShader.uCurvature = curveVal; } catch (e:Dynamic) {}
        try { vhsShader.setFloat("uCurvature", curveVal); } catch (e:Dynamic) {}
    }
}