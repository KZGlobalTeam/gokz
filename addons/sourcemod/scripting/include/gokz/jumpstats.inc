/* 	
	GOKZ Jumpstats Include File
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_jumpstats_included_
#endinput
#endif
#define _gokz_jumpstats_included_



// =========================  ENUMERATIONS  ========================= //

enum JumpType
{
	JumpType_Invalid = -1, 
	JumpType_LongJump, 
	JumpType_Bhop, 
	JumpType_MultiBhop, 
	JumpType_DropBhop, 
	JumpType_WeirdJump, 
	JumpType_LadderJump, 
	JumpType_Fall, 
	JUMPTYPE_COUNT
}



// =========================  PHRASES  ========================= //

stock char gC_JumpTypes[JUMPTYPE_COUNT][] = 
{
	"Long Jump", 
	"B-Hop", 
	"Multi B-Hop", 
	"Drop B-Hop", 
	"Weird Jump", 
	"Ladder Jump", 
	"Fall"
}



// =========================  FORWARDS  ========================= //





// =========================  NATIVES  ========================= //





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
	
}
#endif