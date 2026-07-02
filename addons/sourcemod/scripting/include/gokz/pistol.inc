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
	Pistol_Disabled = 0, 
	Pistol_USPS, 
	Pistol_P2000, 
	Pistol_Glock18, 
	Pistol_DualBerettas, 
	Pistol_P250, 
	Pistol_FiveSeveN, 
	Pistol_Tec9, 
	Pistol_CZ75Auto, 
	Pistol_DesertEagle, 
	Pistol_R8Revolver, 
	PISTOL_COUNT
};



// =====[ CONSTANTS ]=====

#define PISTOL_OPTION_NAME "GOKZ - Pistol"
#define PISTOL_OPTION_DESCRIPTION "Pistol - 0 = Disabled, 1 = USP-S, 2 = P2000, 3 = Glock-18, 4 = Dual Berettas, 5 = P250, 6 = Five-SeveN, 7 = Tec-9, 8 = CZ75-Auto, 9 = Desert Eagle, 10 = R8 Revolver"

stock char gC_PistolNames[PISTOL_COUNT][] = 
{
	"",  // Disabled
	"USP-S",
	"P2000",
	"Glock-18", 
	"Dual Berettas", 
	"P250", 
	"Five-SeveN", 
	"Tec-9", 
	"CZ75-Auto", 
	"Desert Eagle", 
	"R8 Revolver"
};

stock char gC_PistolClassNames[PISTOL_COUNT][] = 
{
	"",  // Disabled
	"weapon_usp_silencer",
	"weapon_hkp2000", 
	"weapon_glock", 
	"weapon_elite", 
	"weapon_p250", 
	"weapon_fiveseven", 
	"weapon_tec9", 
	"weapon_cz75a", 
	"weapon_deagle", 
	"weapon_revolver"
};

stock int gI_PistolTeams[PISTOL_COUNT] = 
{
	CS_TEAM_NONE,  // Disabled
	CS_TEAM_CT, 
	CS_TEAM_CT,
	CS_TEAM_T, 
	CS_TEAM_NONE, 
	CS_TEAM_NONE, 
	CS_TEAM_CT, 
	CS_TEAM_T, 
	CS_TEAM_NONE, 
	CS_TEAM_NONE, 
	CS_TEAM_NONE
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