/*
	gokz-chat Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_chat_included_
#endinput
#endif
#define _gokz_chat_included_



// =====[ NATIVES ]=====

/**
 * Gets whether a mode is loaded.
 *
 * @param client		Client.
 * @param tag			Tag to prepend to the player name in chat.
 * @param color			Color to use for the tag.
 */
native void GOKZ_CH_SetChatTag(int client, const char[] tag, const char[] color);



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_chat = 
{
	name = "gokz-chat", 
	file = "gokz-chat.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_chat_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_CH_SetChatTag");
}
#endif