/*
	gokz-momsurffix Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_momsurffix_included_
#endinput
#endif
#define _gokz_momsurffix_included_

// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_momsurffix = 
{
	name = "gokz-momsurffix", 
	file = "gokz-momsurffix.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};