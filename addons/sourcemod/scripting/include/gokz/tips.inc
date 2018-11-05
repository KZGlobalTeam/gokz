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

#define TIPS_OPTION_NAME "tips"
#define TIPS_OPTION_DESCRIPTION "Tips"
#define TIPS_CORE "gokz-tips-core.phrases.txt"
#define TIPS_LOCALRANKS "gokz-tips-localranks.phrases.txt"
#define TIPS_REPLAYS "gokz-tips-replays.phrases.txt"
#define TIPS_JUMPSTATS "gokz-tips-jumpstats.phrases.txt"



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