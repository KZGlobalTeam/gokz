/*
	gokz-pistol Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_pistol_included_
#endinput
#endif
#define _gokz_pistol_included_



// =====[ ENUMS ]=====

enum
{
	Pistol_USP = 0, 
	Pistol_Glock, 
	Pistol_P250, 
	Pistol_Dualies, 
	Pistol_Deagle, 
	Pistol_CZ75A, 
	Pistol_FiveSeveN, 
	Pistol_Tec9, 
	Pistol_R8Revolver, 
	Pistol_Disabled, 
	PISTOL_COUNT
};



// =====[ CONSTANTS ]=====

#define PISTOL_OPTION_NAME "pistol"
#define PISTOL_OPTION_DESCRIPTION "Pistol"



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_pistol = 
{
	name = "gokz-pistol", 
	file = "gokz-pistol.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
}; 