extends RefCounted
## Measured pixel geometry from officer_reach_up_right_v03.png (unchanged RGBA).
## These exact values are shared by sprite sampling and contact motion.
const OFFICER_REGION:=Rect2(294,160,797,1016)
const OFFICER_PIVOT:=Vector2(321,480)
const OFFICER_PALMS:=Vector2(689,95)
const OFFICER_SCALE: float=70.0/1016.0
const OFFICER_HAND_OFFSET: Vector2=(OFFICER_PALMS-OFFICER_PIVOT)*OFFICER_SCALE
const RING_CONTACT_OFFSET:=Vector2(-27,2)
const OFFICER_FOOT_MIN_X: float=-21.5
const OFFICER_FOOT_MAX_X: float=19.0
