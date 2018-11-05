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

stock char gC_PistolNames[PISTOL_COUNT][] = 
{
	"P2000 / USP-S", 
	"Glock-18", 
	"P250", 
	"Dual Berettas", 
	"Desert Eagle", 
	"CZ75-Auto", 
	"Five-SeveN", 
	"Tec-9", 
	"R8 Revolver", 
	"" // Disabled
};

stock char gC_PistolClassNames[PISTOL_COUNT][] = 
{
	"weapon_hkp2000", 
	"weapon_glock", 
	"weapon_p250", 
	"weapon_elite", 
	"weapon_deagle", 
	"weapon_cz75a", 
	"weapon_fiveseven", 
	"weapon_tec9", 
	"weapon_revolver", 
	"" // Disabled
};

stock int gI_PistolTeams[PISTOL_COUNT] = 
{
	CS_TEAM_CT, 
	CS_TEAM_T, 
	CS_TEAM_NONE, 
	CS_TEAM_NONE, 
	CS_TEAM_NONE, 
	CS_TEAM_NONE, 
	CS_TEAM_CT, 
	CS_TEAM_T, 
	CS_TEAM_NONE, 
	CS_TEAM_NONE // Disabled
};



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