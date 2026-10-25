import funkin.backend.utils.WindowUtils;
import flixel.math.FlxBasePoint;
import openfl.Lib;

public var camMoveOffset:Float = 18;
public var camFollowChars:Bool = true;
public var angleMoveSpeed = 0.015; 
public var angleVar = 1; 

public var charCamMoveMovement = new FlxBasePoint();
function onCameraMove(camMoveEvent) {
    if (camFollowChars) {
        camMoveEvent.cancelled = false;
        if (!camFollowChars) return;
       
        for(char in strumLines.members[curCameraTarget].characters)
            switch (char.getAnimName()) {
                    case "singLEFT": charCamMoveMovement.set(-camMoveOffset, 0);
                    FlxG.camera.angle = (lerp(FlxG.camera.angle, -angleVar, angleMoveSpeed));
                    case "singDOWN": charCamMoveMovement.set(0, camMoveOffset);
                    FlxG.camera.angle = (lerp(FlxG.camera.angle, 0, angleMoveSpeed));
                    case "singUP": charCamMoveMovement.set(0, -camMoveOffset);
                    FlxG.camera.angle = (lerp(FlxG.camera.angle, 0, angleMoveSpeed));
                    case "singRIGHT": charCamMoveMovement.set(camMoveOffset, 0);
                    FlxG.camera.angle = (lerp(FlxG.camera.angle, angleVar, angleMoveSpeed));
                    default: charCamMoveMovement.set(0,0);
                    FlxG.camera.angle = (lerp(FlxG.camera.angle, 0, 0.01));
            };
		 
		camMoveEvent.position.x += charCamMoveMovement.x;
		camMoveEvent.position.y += charCamMoveMovement.y;
        
    }
}