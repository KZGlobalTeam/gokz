/* 	
	GOKZ Jumpstats Include File
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_jumpstats_included_
#endinput
#endif
#define _gokz_jumpstats_included_



// =========================  ENUMERATIONS  ========================= //

enum
{
	JumpType_Invalid = -1, 
	JumpType_LongJump, 
	JumpType_Bhop, 
	JumpType_MultiBhop, 
	JumpType_WeirdJump, 
	JumpType_LadderJump, 
	JumpType_Fall, 
	JumpType_Other, 
	JUMPTYPE_COUNT
}

enum
{
	StrafeDirection_None, 
	StrafeDirection_Left, 
	StrafeDirection_Right
}

enum
{
	DistanceTier_None = -1, 
	DistanceTier_Meh, 
	DistanceTier_Impressive, 
	DistanceTier_Perfect, 
	DistanceTier_Godlike, 
	DistanceTier_Ownage, 
	DISTANCETIER_COUNT
}



// =========================  PHRASES  ========================= //

stock char gC_JumpTypes[JUMPTYPE_COUNT][] = 
{
	"Long Jump", 
	"Bunnyhop", 
	"Multi Bunnyhop", 
	"Weird Jump", 
	"Ladder Jump", 
	"Fall", 
	"Unknown Jump"
}

stock char gC_JumpTypesShort[JUMPTYPE_COUNT][] = 
{
	"LJ", 
	"BH", 
	"MBH", 
	"WJ", 
	"LAJ", 
	"FL", 
	"??"
}



// =========================  FORWARDS  ========================= //

/**
 * Called when a player begins their jump.
 *
 * @param client		Client index.
 * @param jumpType		Type of jump.
 * @noreturn
 */
forward void GOKZ_JS_OnTakeoff(int client, int jumpType);

/**
 * Called when a player lands their jump.
 *
 * @param client		Client index.
 * @param jumpType		Type of jump they landed.
 * @param distance		Horizontal distance of the jump.
 * @param offset		Vertical distance of the jump.
 * @param height		Max height of the player relative to their takeoff origin.
 * @param preSpeed		Takeoff speed.
 * @param maxSpeed		Max horizontal speed reached.
 * @param strafes		Number of strafes.
 * @param sync			Percentage of time that speed was gained.
 * @param duration		Duration of the jump in seconds.
 * @noreturn
 */
forward void GOKZ_JS_OnLanding(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration);

/**
 * Called when player's current jump has been declared an invalid jumpstat.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void GOKZ_JS_OnJumpInvalidated(int client);



// =========================  NATIVES  ========================= //

/**
 * Declare the player's current jump an invalid jumpstat.
 *
 * @param client    	Client index.
 * @noreturn
 */
native void GOKZ_JS_InvalidateJump(int client);



// =========================  DEPENDENCY  ========================= //

public SharedPlugin __pl_gokz_jumpstats = 
{
	name = "gokz-jumpstats", 
	file = "gokz-jumpstats.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_jumpstats_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_JS_InvalidateJump");
}
#endif