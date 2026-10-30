extends RefCounted
## Prototype combat is deliberately independent of the side-view skill system.
const PROFILES := ["PHUZASHI_CHILL","RED_CAP"]
const HEALTH: float = 200
const BOSS_HEALTH: float = 900
const PLAYER_RADIUS: float = 0.34
const REVIVE_TIME: float = 1.8
const REVIVE_RANGE: float = 1.8
# duration, damage, active start/end, reach in metres, guard pressure.
const NORMALS := {
	"PUNCH":[0.42,8,0.34,0.60,2.0,8], "PUNCH_2":[0.36,10,0.32,0.57,2.05,10],
	"PUNCH_3":[0.50,16,0.30,0.62,2.2,20], "KICK":[0.58,14,0.40,0.65,2.45,12],
	"KICK_2":[0.50,16,0.36,0.62,2.55,14], "KICK_3":[0.64,22,0.34,0.65,2.7,24],
	"AIR_PUNCH":[0.32,9,0.24,0.60,2.0,10], "AIR_KICK":[0.42,15,0.30,0.66,2.5,14]
}
const ATTACK_LABELS := {"SWEEP":"SWEEP / GET BEHIND OR JUMP", "SLAM":"LEAP SLAM / LEAVE THE RING OR JUMP", "CHARGE":"CHARGE / STEP OUT OF THE LANE"}
const WINDUP := {"SWEEP":0.95,"SLAM":1.30,"CHARGE":1.05}
const ACTIVE := {"SWEEP":0.16,"SLAM":0.20,"CHARGE":0.55}
const DAMAGE := {"SWEEP":22,"SLAM":32,"CHARGE":26}
const RADIUS := {"SWEEP":3.4,"SLAM":2.8}
const CHARGE_LENGTH: float = 7.7
const CHARGE_HALF_WIDTH: float = 1.1
const TIMING := {
	"PUNCH":[0.0,0.12,0.26,0.34,0.62,0.74,0.84,0.94],
	"PUNCH_2":[0.0,0.10,0.22,0.32,0.44,0.57,0.76,0.91],
	"PUNCH_3":[0.0,0.08,0.20,0.30,0.46,0.62,0.80,0.93],
	"KICK":[0.0,0.10,0.20,0.28,0.40,0.65,0.82,0.94],
	"KICK_2":[0.0,0.10,0.20,0.30,0.64,0.73,0.83,0.94],
	"KICK_3":[0.0,0.08,0.14,0.20,0.34,0.65,0.83,0.94]
}

static func flat(value: Vector3) -> Vector2:
	return Vector2(value.x,value.z)

static func ground(value: Vector2) -> Vector3:
	return Vector3(value.x,0,value.y)

static func direction(from: Vector3, to: Vector3) -> Vector2:
	var difference := flat(to-from)
	return difference.normalized() if difference.length_squared() > 0.001 else Vector2.RIGHT

static func inside_attack(point: Vector3, kind: String, origin: Vector3, aim: Vector2, center: Vector3, jump_height: float = 0) -> bool:
	var offset := flat(point-origin)
	if kind == "SLAM": return flat(point-center).length() <= RADIUS.SLAM and jump_height < 0.9
	if kind == "SWEEP": return offset.length() <= RADIUS.SWEEP and (offset.length() < 0.01 or offset.normalized().dot(aim) >= 0.0) and jump_height < 0.85
	return false

static func frame_for(clip: String, phase: float) -> int:
	var sequence: Array = TIMING.get(clip,[0.0,0.125,0.25,0.375,0.5,0.625,0.75,0.875])
	var result: int = 0
	for i in range(sequence.size()):
		if phase >= float(sequence[i]): result = i
	return result
