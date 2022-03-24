/*
	gokz-profile Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_profile_included_
#endinput
#endif
#define _gokz_profile_included_


// =====[ RANKS ]=====

#define RANK_COUNT 23

stock int gI_rankThreshold[MODE_COUNT][RANK_COUNT] = {
	{
		0,
		1,
		500,
		1000,
		
		2000,
		5000,
		10000,
		
		20000,
		30000,
		40000,
		
		60000,
		70000,
		80000,
		
		100000,
		120000,
		140000,
		
		160000,
		180000,
		200000,
		
		250000,
		300000,
		400000,
		600000
	},
	{
		0,
		1,
		500,
		1000,
		
		2000,
		5000,
		10000,
		
		20000,
		30000,
		40000,
		
		60000,
		70000,
		80000,
		
		100000,
		120000,
		150000,
		
		200000,
		230000,
		250000,
		
		300000,
		400000,
		500000,
		800000
	},
	{
		0,
		1,
		500,
		1000,

		2000,
		5000,
		10000,

		20000,
		30000,
		40000,

		60000,
		70000,
		80000,

		100000,
		120000,
		150000,

		200000,
		230000,
		250000,

		400000,
		600000,
		800000,
		1000000
	},
};

stock char gC_rankName[RANK_COUNT][] = {
	"New",
	"Beginner-",
	"Beginner",
	"Beginner+",
	"Amateur-",
	"Amateur",
	"Amateur+",
	"Casual-",
	"Casual",
	"Casual+",
	"Regular-",
	"Regular",
	"Regular+",
	"Skilled-",
	"Skilled",
	"Skilled+",
	"Expert-",
	"Expert",
	"Expert+",
	"Semipro",
	"Pro",
	"Master",
	"Legend"
};

stock char gC_rankColor[RANK_COUNT][] = {
	"{grey}",
	"{default}",
	"{default}",
	"{default}",
	"{blue}",
	"{blue}",
	"{blue}",
	"{lightgreen}",
	"{lightgreen}",
	"{lightgreen}",
	"{green}",
	"{green}",
	"{green}",
	"{purple}",
	"{purple}",
	"{purple}",
	"{orchid}",
	"{orchid}",
	"{orchid}",
	"{lightred}",
	"{lightred}",
	"{red}",
	"{gold}"
};


// =====[ ENUMS ]=====

enum ProfileOption:
{
	PROFILEOPTION_INVALID = -1, 
	ProfileOption_ShowRankChat,
	ProfileOption_ShowRankClanTag,
	ProfileOption_TagType,
	PROFILEOPTION_COUNT
};

enum
{
	ProfileOptionBool_Disabled = 0,
	ProfileOptionBool_Enabled,
	PROFILEOPTIONBOOL_COUNT
};

enum
{
	ProfileTagType_Rank = 0,
	ProfileTagType_Admin,
	ProfileTagType_VIP,
	PROFILETAGTYPE_COUNT
};



// =====[ CONSTANTS ]=====

stock char gC_ProfileOptionNames[PROFILEOPTION_COUNT][] = 
{
	"GOKZ Profile - Show Rank Chat",
	"GOKZ Profile - Show Rank Clan",
	"GOKZ Profile - Tag Type"
};

stock char gC_ProfileOptionDescriptions[PROFILEOPTION_COUNT][] = 
{
	"Show Rank Tag in Chat - 0 = Disabled, 1 = Enabled",
	"Show Rank in Clan - 0 = Disabled, 1 = Enabled",
	"Type of Tag to Show - 0 = Rank, 1 = Admin, 2 = VIP"
};

stock char gC_ProfileOptionPhrases[PROFILEOPTION_COUNT][] = 
{
	"Options Menu - Show Rank Chat",
	"Options Menu - Show Rank Clan",
	"Options Menu - Tag Type",
};

stock char gC_ProfileBoolPhrases[PROFILEOPTIONBOOL_COUNT][] = 
{
	"Options Menu - Disabled",
	"Options Menu - Enabled"
};

stock char gC_ProfileTagTypePhrases[PROFILETAGTYPE_COUNT][] = 
{
	"Options Menu - Tag Rank",
	"Options Menu - Tag Admin",
	"Options Menu - Tag VIP"
};

stock int gI_ProfileOptionCounts[PROFILEOPTION_COUNT] = 
{
	PROFILEOPTIONBOOL_COUNT,
	PROFILEOPTIONBOOL_COUNT,
	PROFILETAGTYPE_COUNT
};

stock int gI_ProfileOptionDefaults[PROFILEOPTION_COUNT] = 
{
	ProfileOptionBool_Enabled,
	ProfileOptionBool_Enabled,
	ProfileTagType_Rank
};

#define PROFILE_OPTION_CATEGORY "Profile"
#define TAG_COLOR_ADMIN "{red}"
#define TAG_COLOR_VIP   "{purple}"


// =====[ FORWARDS ]=====


/**
 * Called when the rank of a player is updated.
 *
 * @param client		Client index.
 * @param mode	    	Game mode.
 * @param rank			The new rank.
 */
forward void GOKZ_PF_OnRankUpdated(int client, int mode, int rank);

// =====[ NATIVES ]=====

/**
 * Gets whether a mode is loaded.
 *
 * @param client		Client.
 * @param tag			Mode.
 * @returns				Integer representing the player rank.
 */
native int GOKZ_PF_GetRank(int client, int mode);


// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_profile = 
{
	name = "gokz-profile", 
	file = "gokz-profile.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_profile_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_PF_GetRank");
}
#endif