/*
	gokz-tips Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_tips_included_
#endinput
#endif
#define _gokz_tips_included_



// =====[ ENUMS ]=====

enum
{
	Tips_Disabled = 0, 
	Tips_Enabled, 
	TIPS_COUNT
};



// =====[ CONSTANTS ]=====

#define TIPS_PLUGINS_COUNT 9
#define TIPS_CORE "gokz-tips-core.phrases.txt"
#define TIPS_TIPS "gokz-tips-tips.phrases.txt"
#define TIPS_OPTION_NAME "GOKZ - Tips"
#define TIPS_OPTION_DESCRIPTION "Random Tips Periodically in Chat - 0 = Disabled, 1 = Enabled"

stock char gC_PluginsWithTips[TIPS_PLUGINS_COUNT][] = 
{
	"goto", 
	"hud", 
	"jumpstats", 
	"localranks", 
	"measure", 
	"pistol", 
	"quiet", 
	"replays", 
	"spec"
}



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_tips = 
{
	name = "gokz-tips", 
	file = "gokz-tips.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
}; 