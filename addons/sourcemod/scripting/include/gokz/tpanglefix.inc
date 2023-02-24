/*
	gokz-tpanglefix Plugin Include
	
	Website: https://github.com/KZGlobalTeam/gokz
*/

#if defined _gokz_tpanglefix_included_
#endinput
#endif
#define _gokz_tpanglefix_included_


// =====[ ENUMS ]=====

enum
{
	TPAngleFix_Disabled = 0, 
	TPAngleFix_Enabled, 
	TPANGLEFIX_COUNT
};


// =====[ CONSTANTS ]=====

#define TPANGLEFIX_OPTION_NAME "GOKZ - TPAngleFix"
#define TPANGLEFIX_OPTION_DESCRIPTION "TPAngleFix - 0 = Disabled, 1 = Enabled"


// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_tpanglefix = 
{
	name = "gokz-tpanglefix", 
	file = "gokz-tpanglefix.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
}; 