extends Node2D
## Stage artwork and HUD are drawn with code; no unlicensed game sprites.

@onready var phuzashi: PhuzashiCharacter = $PHUZASHI

const VIEW_W: float = 960.0
const VIEW_H: float = 540.0
const FLOOR_Y: float = 450.0

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    _draw_stage()
    _draw_hud()

func _draw_stage() -> void:
    draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color("#6bc7f1"))
    for index in range(32):
        var y: float = float(index * 9)
        draw_rect(Rect2(0, y, VIEW_W, 9), Color("#78c9ed").lerp(Color("#c0eced"), float(index) / 35.0))
    # Pixelated layered mountains and clouds.
    _mountain(565, 230, 300, Color("#5ca5ad"))
    _mountain(780, 270, 310, Color("#3f7f9a"))
    _mountain(265, 245, 285, Color("#82b0b5"))
    _mountain(60, 288, 335, Color("#538c90"))
    for i in range(9):
        var x: float = float((i * 171 + 36) % 980)
        var y: float = float(54 + (i * 37) % 94)
        _cloud(x, y)
    draw_rect(Rect2(0, 302, VIEW_W, 148), Color("#3c9555"))
    draw_colored_polygon(PackedVector2Array([Vector2(0, 355), Vector2(120, 325), Vector2(320, 345), Vector2(500, 314), Vector2(740, 342), Vector2(960, 305), Vector2(960, 450), Vector2(0, 450)]), Color("#69b16a"))
    draw_rect(Rect2(0, 398, VIEW_W, 52), Color("#94b674"))
    for i in range(31):
        var tx: float = float(i * 33 + (i % 3) * 5)
        var ty: float = float(306 + (i * 13) % 51)
        _pine(tx, ty, (i % 3) + 1)
    for i in range(64):
        var gx: float = float((i * 97 + 33) % 960)
        var gy: float = float(370 + (i * 31) % 72)
        draw_line(Vector2(gx, gy), Vector2(gx + 3, gy - 8), Color("#2a8249"), 2.0)
    # Simple tiled stone training platform.
    draw_rect(Rect2(0, FLOOR_Y, VIEW_W, 90), Color("#d9bd8d"))
    draw_rect(Rect2(0, FLOOR_Y, VIEW_W, 5), Color("#fff0be"))
    draw_rect(Rect2(0, FLOOR_Y + 5, VIEW_W, 4), Color("#a77d52"))
    for j in range(4):
        var py: float = FLOOR_Y + 12.0 + float(j) * 32.0
        draw_line(Vector2(0, py), Vector2(VIEW_W, py), Color("#ad8d62"), 2.0)
        for i in range(12):
            var xx: float = float(i) * 92.0 + (46.0 if j % 2 == 1 else 0.0)
            draw_line(Vector2(xx, py), Vector2(xx - 5.0, py + 32.0), Color("#b39366"), 2.0)
    # Foreground decorations.
    for i in range(13):
        var x: float = float(i * 81 + (i % 3) * 17)
        draw_rect(Rect2(x, 436 + (i % 2) * 2, 5, 3), Color("#5a9156"))

func _mountain(peak_x: float, peak_y: float, width: float, tint: Color) -> void:
    draw_colored_polygon(PackedVector2Array([Vector2(peak_x - width, 320), Vector2(peak_x - width * 0.2, peak_y + 62), Vector2(peak_x, peak_y), Vector2(peak_x + width * 0.33, peak_y + 80), Vector2(peak_x + width, 320)]), tint)
    draw_colored_polygon(PackedVector2Array([Vector2(peak_x, peak_y), Vector2(peak_x - 43, peak_y + 48), Vector2(peak_x - 20, peak_y + 40), Vector2(peak_x + 8, peak_y + 72), Vector2(peak_x + 26, peak_y + 28), Vector2(peak_x + 50, peak_y + 54)]), Color("#d6edf2"))

func _cloud(x: float, y: float) -> void:
    draw_rect(Rect2(x, y + 12, 80, 14), Color("#d6f3f7"))
    draw_rect(Rect2(x + 13, y + 5, 27, 20), Color("#ffffff"))
    draw_rect(Rect2(x + 36, y, 26, 22), Color("#ffffff"))
    draw_rect(Rect2(x + 60, y + 12, 24, 12), Color("#e8f6ff"))

func _pine(x: float, y: float, kind: int) -> void:
    var h: float = 18.0 + float(kind * 6)
    draw_rect(Rect2(x - 2, y + h * 0.4, 4, 13), Color("#4b5036"))
    draw_colored_polygon(PackedVector2Array([Vector2(x, y - h), Vector2(x - h * 0.4, y + h * 0.3), Vector2(x + h * 0.4, y + h * 0.3)]), Color("#20694a"))
    draw_colored_polygon(PackedVector2Array([Vector2(x, y - h + 6), Vector2(x - h * 0.47, y + h * 0.6), Vector2(x + h * 0.47, y + h * 0.6)]), Color("#1f7f52"))

func _draw_hud() -> void:
    draw_rect(Rect2(18, 12, 344, 87), Color(0.014, 0.037, 0.084, 0.94))
    draw_rect(Rect2(18, 12, 344, 2), Color("#8c42f0"))
    _label(Vector2(32, 37), "PHUZASHI  /  DARK PULSE", 18, Color("#f6efff"))
    _label(Vector2(32, 58), "HP", 13, Color("#cbcfdf"))
    draw_rect(Rect2(66, 47, 250, 12), Color("#111a30"))
    draw_rect(Rect2(68, 49, 246.0 * phuzashi.health / 100.0, 8), Color("#eb6176"))
    _label(Vector2(32, 79), "MP", 13, Color("#cbcfdf"))
    draw_rect(Rect2(66, 67, 250, 12), Color("#111a30"))
    draw_rect(Rect2(68, 69, 246.0 * phuzashi.energy / 100.0, 8), Color("#9147ff"))

    draw_rect(Rect2(650, 12, 292, 73), Color(0.014, 0.037, 0.084, 0.91))
    draw_rect(Rect2(650, 12, 292, 2), Color("#39d5ef"))
    _label(Vector2(666, 38), "TRAINING GROUND / STAGE 01", 16, Color("#e9f6ff"))
    _label(Vector2(666, 62), "STATE: " + phuzashi.state_name, 16, Color("#c8a5ff"))

    draw_rect(Rect2(185, 494, 590, 33), Color(0.018, 0.035, 0.075, 0.90))
    _label(Vector2(201, 515), "A/D MOVE   SHIFT RUN   SPACE JUMP   S CROUCH   L GUARD", 14, Color("#ebf1ff"))
    _label(Vector2(244, 534), "J PUNCH   K KICK   U SKILL   I ULT   R RESET", 12, Color("#b895ff"))

func _label(pos: Vector2, s: String, size: int, tint: Color) -> void:
    draw_string(ThemeDB.fallback_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)
