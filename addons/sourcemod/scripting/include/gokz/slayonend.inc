/*
	gokz-slayonend Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_slayonend_included_
#endinput
#endif
#define _gokz_slayonend_included_



// =====[ ENUMS ]=====

enum
{
	SlayOnEnd_Disabled = 0, 
	SlayOnEnd_Enabled, 
	SLAYONEND_COUNT
};



// =====[ CONSTANTS ]=====

#define SLAYONEND_OPTION_NAME "GOKZ - Slay On End"
#define SLAYONEND_OPTION_DESCRIPTION "Automatic Slaying Upon Ending Timer - 0 = Disabled, 1 = Enabled"



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_slayonend = 
{
	name = "gokz-slayonend", 
	file = "gokz-slayonend.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
}; 