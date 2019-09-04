#if defined _sourcemod_colors_included
	#endinput
#endif
#define _sourcemod_colors_included "1.0"

/*
*   _____                                              _    _____      _
*  / ____|                                            | |  / ____|    | |               
* | (___   ___  _   _ _ __ ___ ___ _ __ ___   ___   __| | | |     ___ | | ___  _ __ ___ 
*  \___ \ / _ \| | | | '__/ __/ _ \ '_ ` _ \ / _ \ / _` | | |    / _ \| |/ _ \| '__/ __|
*  ____) | (_) | |_| | | | (_|  __/ | | | | | (_) | (_| | | |___| (_) | | (_) | |  \__ \
* |_____/ \___/ \__,_|_|  \___\___|_| |_| |_|\___/ \__,_|  \_____\___/|_|\___/|_|  |___/
* 
* 
* - Author: Keith Warren (Drixevel)
* - Original By: Raska aka KissLick (ColorVariables)
* 
* This is meant to be a drop-in replacement for every Source Engine game to add colors to chat and more cheat features.
*/

// ----------------------------------------------------------------------------------------
#define MAX_BUFFER_SIZE 1024

static bool g_bInit;
static StringMap g_hColors;
static char g_sChatPrefix[64];

static bool g_bIgnorePrefix;
static int g_iAuthor;
static bool g_bSkipPlayers[MAXPLAYERS + 1];
// ----------------------------------------------------------------------------------------

/*
*	Sets the prefix for all chat prints to use.
*	
*	prefix		- String to use.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CSetPrefix(const char[] prefix, any ...)
{
	VFormat(g_sChatPrefix, sizeof(g_sChatPrefix), prefix, 2);
}

/*
*	Setup the next print to skip using the prefix.
*	
*	
*	Return		- N/A
*/
stock void CSkipNextPrefix()
{
	g_bIgnorePrefix = true;
}

/*
*	Sets the author for the next print. (Mostly applies colors)
*	
*	client		- Author index.
*	
*	Return		- N/A
*/
stock void CSetNextAuthor(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
		ThrowError("Invalid client index %i", client);
	
	g_iAuthor = client;
}

/*
*	Setup the next chat print to not be sent to this client.
*	
*	client		- Client index.
*	
*	Return		- N/A
*/
stock void CSkipNextClient(int client)
{
	if (client < 1 || client > MaxClients)
		ThrowError("Invalid client index %i", client);
	
	g_bSkipPlayers[client] = true;
}

/*
*	Sends a chat print to the client.
*	
*	client		- Client index.
*	message		- Message string.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CPrintToChat(int client, const char[] message, any ...)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return;
	
	SetGlobalTransTarget(client);

	char buffer[MAX_BUFFER_SIZE];
	VFormat(buffer, sizeof(buffer), message, 3);

	AddPrefixAndDefaultColor(buffer, sizeof(buffer));
	g_bIgnorePrefix = false;

	CProcessVariables(buffer, sizeof(buffer));
	CAddWhiteSpace(buffer, sizeof(buffer));

	SendPlayerMessage(client, buffer, g_iAuthor);
	g_iAuthor = 0;
}

/*
*	Sends a chat print to the client with a specified author.
*	
*	client		- Client index.
*	author		- Author index.
*	message		- Message string.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CPrintToChatEx(int client, int author, const char[] message, any ...)
{
	CSetNextAuthor(author);
	char buffer[MAX_BUFFER_SIZE];
	VFormat(buffer, sizeof(buffer), message, 4);
	CPrintToChat(client, buffer);
}

/*
*	Sends a chat print to all clients.
*	
*	message		- Message string.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CPrintToChatAll(const char[] message, any ...)
{
	char buffer[MAX_BUFFER_SIZE];

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || g_bSkipPlayers[client])
		{
			g_bSkipPlayers[client] = false;
			continue;
		}

		SetGlobalTransTarget(client);
		
		VFormat(buffer, sizeof(buffer), message, 2);

		AddPrefixAndDefaultColor(buffer, sizeof(buffer));
		g_bIgnorePrefix = false;

		CProcessVariables(buffer, sizeof(buffer));
		CAddWhiteSpace(buffer, sizeof(buffer));

		SendPlayerMessage(client, buffer, g_iAuthor);
	}
	
	g_iAuthor = 0;
}

/*
*	Sends a chat print to all clients with a specified author.
*	
*	author		- Author index.
*	message		- Message string.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CPrintToChatAllEx(int author, const char[] message, any ...)
{
	CSetNextAuthor(author);
	char buffer[MAX_BUFFER_SIZE];
	VFormat(buffer, sizeof(buffer), message, 3);
	CPrintToChatAll(buffer);
}

/*
*	Sends a chat print to a specified team.
*	
*	team		- Team index.
*	message		- Message string.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CPrintToChatTeam(int team, const char[] message, any ...)
{
	char buffer[MAX_BUFFER_SIZE];

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || GetClientTeam(client) != team || g_bSkipPlayers[client])
		{
			g_bSkipPlayers[client] = false;
			continue;
		}

		SetGlobalTransTarget(client);
		VFormat(buffer, sizeof(buffer), message, 3);

		AddPrefixAndDefaultColor(buffer, sizeof(buffer));
		g_bIgnorePrefix = false;

		CProcessVariables(buffer, sizeof(buffer));
		CAddWhiteSpace(buffer, sizeof(buffer));

		SendPlayerMessage(client, buffer, g_iAuthor);
	}
	
	g_iAuthor = 0;
}

/*
*	Sends a chat print to a specified team with a specified author.
*	
*	team		- Team index.
*	message		- Message string.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CPrintToChatTeamEx(int team, int author, const char[] message, any ...)
{
	CSetNextAuthor(author);
	char buffer[MAX_BUFFER_SIZE];
	VFormat(buffer, sizeof(buffer), message, 4);
	CPrintToChatTeam(team, buffer);
}

/*
*	Sends a chat print to available admins.
*	Example for bitflags: (ADMFLAG_RESERVATION | ADMFLAG_GENERIC)
*	
*	bitflags	- Bit Flags.
*	message		- Message string.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CPrintToChatAdmins(int bitflags, const char[] message, any ...)
{
	char buffer[MAX_BUFFER_SIZE];
	AdminId iAdminID;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || g_bSkipPlayers[client])
		{
			g_bSkipPlayers[client] = false;
			continue;
		}

		iAdminID = GetUserAdmin(client);
		
		if (iAdminID == INVALID_ADMIN_ID || !(GetAdminFlags(iAdminID, Access_Effective) & bitflags))
			continue;

		SetGlobalTransTarget(client);
		VFormat(buffer, sizeof(buffer), message, 3);

		AddPrefixAndDefaultColor(buffer, sizeof(buffer));
		g_bIgnorePrefix = false;

		CProcessVariables(buffer, sizeof(buffer));
		CAddWhiteSpace(buffer, sizeof(buffer));

		SendPlayerMessage(client, buffer, g_iAuthor);
	}
	
	g_iAuthor = 0;
}

/*
*	Sends a chat print to available admins with a specified author.
*	Example for bitflags: (ADMFLAG_RESERVATION | ADMFLAG_GENERIC)
*	
*	bitflags	- Bit Flags.
*	message		- Message string.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CPrintToChatAdminsEx(int bitflags, int author, const char[] message, any ...)
{
	CSetNextAuthor(author);
	char buffer[MAX_BUFFER_SIZE];
	VFormat(buffer, sizeof(buffer), message, 4);
	CPrintToChatTeam(bitflags, buffer);
}

/*
*	Sends a reply message to the client. (This is useful because it works for console as well)
*	
*	client		- Client index.
*	message		- Message string.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CReplyToCommand(int client, const char[] message, any ...)
{
	if (client < 0 || client > MaxClients)
		ThrowError("Invalid client index %d", client);

	if (client != 0 && !IsClientInGame(client))
		ThrowError("Client %d is not in game", client);

	char buffer[MAX_BUFFER_SIZE];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 3);

	AddPrefixAndDefaultColor(buffer, sizeof(buffer), "engine 1");
	g_bIgnorePrefix = false;

	if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		CRemoveColors(buffer, sizeof(buffer));
		PrintToConsole(client, "%s", buffer);
	}
	else
		CPrintToChat(client, "%s", buffer);
}

/*
*	Displays usage of an admin command to users depending on the setting of the sm_show_activity cvar. 
*	This version does not display a message to the originating client if used from chat triggers or menus.
*	If manual replies are used for these cases, then this function will suffice.
*	Otherwise, ShowActivity2() is slightly more useful.
*	
*	client		- Client index.
*	message		- Message string.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CShowActivity(int client, const char[] message, any ...)
{
	if (client < 0 || client > MaxClients)
		ThrowError("Invalid client index %d", client);
	
	if (client != 0 && !IsClientInGame(client))
		ThrowError("Client %d is not in game", client);

	char buffer[MAX_BUFFER_SIZE];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 3);
	Format(buffer, sizeof(buffer), "{engine 1}%s", buffer);
	CProcessVariables(buffer, sizeof(buffer));
	CAddWhiteSpace(buffer, sizeof(buffer));

	ShowActivity(client, "%s", buffer);
}

/*
*	Displays usage of an admin command to users depending on the setting of the sm_show_activity cvar.
*	All users receive a message in their chat text, except for the originating client, who receives the message based on the current ReplySource.
*	
*	client		- Client index.
*	tag			- Tag to show.
*	message		- Message string.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CShowActivityEx(int client, const char[] tag, const char[] message, any ...)
{
	if (client < 0 || client > MaxClients)
		ThrowError("Invalid client index %d", client);

	if (client != 0 && !IsClientInGame(client))
		ThrowError("Client %d is not in game", client);

	char buffer[MAX_BUFFER_SIZE]; char sBufferTag[MAX_BUFFER_SIZE];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 4);
	Format(buffer, sizeof(buffer), "{engine 1}%s", buffer);
	CProcessVariables(buffer, sizeof(buffer));
	Format(sBufferTag, sizeof(sBufferTag), "{prefix}%s", tag);
	CProcessVariables(sBufferTag, sizeof(sBufferTag));
	CAddWhiteSpace(buffer, sizeof(buffer));
	CAddWhiteSpace(sBufferTag, sizeof(sBufferTag));

	ShowActivityEx(client, sBufferTag, " %s", buffer);
}

/*
*	Same as ShowActivity(), except the tag parameter is used instead of "[SM] " (note that you must supply any spacing).
*	
*	client		- Client index.
*	tag			- Tag to show.
*	message		- Message string.
*	any			- Extra Parameters
*	
*	Return		- N/A
*/
stock void CShowActivity2(int client, const char[] tag, const char[] message, any ...)
{
	if (client < 0 || client > MaxClients)
		ThrowError("Invalid client index %d", client);

	if (client != 0 && !IsClientInGame(client))
		ThrowError("Client %d is not in game", client);

	char buffer[MAX_BUFFER_SIZE]; char sBufferTag[MAX_BUFFER_SIZE];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 4);
	Format(buffer, sizeof(buffer), "{engine 2}%s", buffer);
	CProcessVariables(buffer, sizeof(buffer));
	Format(sBufferTag, sizeof(sBufferTag), "{prefix}%s", tag);
	CProcessVariables(sBufferTag, sizeof(sBufferTag));
	CAddWhiteSpace(buffer, sizeof(buffer));
	CAddWhiteSpace(sBufferTag, sizeof(sBufferTag));

	ShowActivityEx(client, sBufferTag, " %s", buffer);
}

/*
*	Strips all colors from the specified string.
*	
*	msg			- String buffer.
*	size		- Size of the string.
*	
*	Return		- N/A
*/
stock void CRemoveColors(char[] msg, int size)
{
	CProcessVariables(msg, size, true);
}

/*
*	Processes colors in a string by replacing found tags with color/hex codes.
*	
*	msg			- String buffer.
*	size		- Size of the string.
*	removecolors	- Whether to remove colors or keep them. (same as CRemoveColors)
*	
*	Return		- N/A
*/
stock void CProcessVariables(char[] msg, int size, bool removecolors = false)
{
	Init();

	char[] sOut = new char[size]; char[] sCode = new char[size]; char[] color = new char[size];
	int iOutPos = 0; int iCodePos = -1;
	int iMsgLen = strlen(msg);

	for (int i = 0; i < iMsgLen; i++)
	{
		if (msg[i] == '{')
			iCodePos = 0;

		if (iCodePos > -1)
		{
			sCode[iCodePos] = msg[i];
			sCode[iCodePos + 1] = '\0';

			if (msg[i] == '}' || i == iMsgLen - 1)
			{
				strcopy(sCode, strlen(sCode) - 1, sCode[1]);
				StringToLower(sCode);

				if (CGetColor(sCode, color, size))
				{
					if (!removecolors)
					{
						StrCat(sOut, size, color);
						iOutPos += strlen(color);
					}
				}
				else
				{
					Format(sOut, size, "%s{%s}", sOut, sCode);
					iOutPos += strlen(sCode) + 2;
				}

				iCodePos = -1;
				strcopy(sCode, size, "");
				strcopy(color, size, "");
			}
			else
				iCodePos++;

			continue;
		}

		sOut[iOutPos] = msg[i];
		iOutPos++;
		sOut[iOutPos] = '\0';
	}

	strcopy(msg, size, sOut);
}

/*
*	Retrieves the color/hex code for a specified color name.
*	
*	name		- Color to search for.
*	color		- String buffer.
*	size		- Size of the string.
*	
*	Return		- True if found, false otherwise.
*/
stock bool CGetColor(const char[] name, char[] color, int size)
{
	if (name[0] == '\0')
		return false;

	if (name[0] == '@')
	{
		int iSpace;
		char sData[64]; char m_sName[64];
		strcopy(m_sName, sizeof(m_sName), name[1]);

		if ((iSpace = FindCharInString(m_sName, ' ')) != -1 && (iSpace + 1 < strlen(m_sName)))
		{
			strcopy(m_sName, iSpace + 1, m_sName);
			strcopy(sData, sizeof(sData), m_sName[iSpace + 1]);
		}

		if (color[0] != '\0')
			return true;
	}
	else if (name[0] == '#')
	{
		if (strlen(name) == 7)
		{
			Format(color, size, "\x07%s", name[1]);
			return true;
		}
		
		if (strlen(name) == 9)
		{
			Format(color, size, "\x08%s", name[1]);
			return true;
		}
	}
	else if (StrContains(name, "player ", false) == 0 && strlen(name) > 7)
	{
		int client = StringToInt(name[7]);

		if (client < 1 || client > MaxClients || !IsClientInGame(client))
		{
			strcopy(color, size, "\x01");
			LogError("Invalid client index %d", client);
			return false;
		}

		strcopy(color, size, "\x01");
		
		switch (GetClientTeam(client))
		{
			case 1: g_hColors.GetString("engine 8", color, size);
			case 2: g_hColors.GetString("engine 9", color, size);
			case 3: g_hColors.GetString("engine 11", color, size);
		}
		
		return true;
	}
	else
		return g_hColors.GetString(name, color, size);

	return false;
}

/*
*	Checks if the specified color exists.
*	
*	name		- Color to search for.
*	
*	Return		- True if found, false otherwise.
*/
stock bool CExistColor(const char[] name)
{
	if (name[0] == '\0' || name[0] == '@' || name[0] == '#')
		return false;

	char color[64];
	return g_hColors.GetString(name, color, sizeof(color));
}

/*
*	Sends a raw SayText2 usermsg to the specified client with settings.
*	
*	client		- Client index.
*	message		- Message string.
*	author		- Author index.
*	chat		- "0 - raw text, 1 - sets CHAT_FILTER_PUBLICCHAT "
*	
*	Return		- N/A
*/
stock void CSayText2(int client, const char[] message, int author, bool chat = true)
{
	if (client < 1 || client > MaxClients)
		return;
	
	Handle hMsg = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(hMsg, "ent_idx", author);
		PbSetBool(hMsg, "chat", chat);
		PbSetString(hMsg, "msg_name", message);
		PbAddString(hMsg, "params", "");
		PbAddString(hMsg, "params", "");
		PbAddString(hMsg, "params", "");
		PbAddString(hMsg, "params", "");
	}
	else
	{
		BfWriteByte(hMsg, author);
		BfWriteByte(hMsg, true);
		BfWriteString(hMsg, message);
	}
	
	EndMessage();
}

/*
*	Adds a space to the start a string buffer.
*	
*	buffer		- String buffer.
*	size		- Size of the string.
*	
*	Return		- N/A
*/
stock void CAddWhiteSpace(char[] buffer, int size)
{
	if (!IsSource2009())
		Format(buffer, size, " %s", buffer);
}

// ----------------------------------------------------------------------------------------
// Private stuff
// ----------------------------------------------------------------------------------------

stock bool Init()
{
	if (g_bInit)
	{
		LoadColors();
		return true;
	}

	for (int i = 1; i <= MaxClients; i++)
		g_bSkipPlayers[i] = false;
	
	LoadColors();
	g_bInit = true;
	
	return true;
}

stock void LoadColors()
{
	if (g_hColors == null)
		g_hColors = new StringMap();
	else
		g_hColors.Clear();
		
	g_hColors.SetString("default", "\x01");
	g_hColors.SetString("teamcolor", "\x03");
	
	if (IsSource2009())
	{
		g_hColors.SetString("aliceblue", "\x07F0F8FF");
		g_hColors.SetString("allies", "\x074D7942");
		g_hColors.SetString("ancient", "\x07EB4B4B");
		g_hColors.SetString("antiquewhite", "\x07FAEBD7");
		g_hColors.SetString("aqua", "\x0700FFFF");
		g_hColors.SetString("aquamarine", "\x077FFFD4");
		g_hColors.SetString("arcana", "\x07ADE55C");
		g_hColors.SetString("axis", "\x07FF4040");
		g_hColors.SetString("azure", "\x07007FFF");
		g_hColors.SetString("beige", "\x07F5F5DC");
		g_hColors.SetString("bisque", "\x07FFE4C4");
		g_hColors.SetString("black", "\x07000000");
		g_hColors.SetString("blanchedalmond", "\x07FFEBCD");
		g_hColors.SetString("blue", "\x0799CCFF");
		g_hColors.SetString("blueviolet", "\x078A2BE2");
		g_hColors.SetString("brown", "\x07A52A2A");
		g_hColors.SetString("burlywood", "\x07DEB887");
		g_hColors.SetString("cadetblue", "\x075F9EA0");
		g_hColors.SetString("chartreuse", "\x077FFF00");
		g_hColors.SetString("chocolate", "\x07D2691E");
		g_hColors.SetString("collectors", "\x07AA0000");
		g_hColors.SetString("common", "\x07B0C3D9");
		g_hColors.SetString("community", "\x0770B04A");
		g_hColors.SetString("coral", "\x07FF7F50");
		g_hColors.SetString("cornflowerblue", "\x076495ED");
		g_hColors.SetString("cornsilk", "\x07FFF8DC");
		g_hColors.SetString("corrupted", "\x07A32C2E");
		g_hColors.SetString("crimson", "\x07DC143C");
		g_hColors.SetString("cyan", "\x0700FFFF");
		g_hColors.SetString("darkblue", "\x0700008B");
		g_hColors.SetString("darkcyan", "\x07008B8B");
		g_hColors.SetString("darkgoldenrod", "\x07B8860B");
		g_hColors.SetString("darkgray", "\x07A9A9A9");
		g_hColors.SetString("darkgrey", "\x07A9A9A9");
		g_hColors.SetString("darkgreen", "\x07006400");
		g_hColors.SetString("darkkhaki", "\x07BDB76B");
		g_hColors.SetString("darkmagenta", "\x078B008B");
		g_hColors.SetString("darkolivegreen", "\x07556B2F");
		g_hColors.SetString("darkorange", "\x07FF8C00");
		g_hColors.SetString("darkorchid", "\x079932CC");
		g_hColors.SetString("darkred", "\x078B0000");
		g_hColors.SetString("darksalmon", "\x07E9967A");
		g_hColors.SetString("darkseagreen", "\x078FBC8F");
		g_hColors.SetString("darkslateblue", "\x07483D8B");
		g_hColors.SetString("darkslategray", "\x072F4F4F");
		g_hColors.SetString("darkslategrey", "\x072F4F4F");
		g_hColors.SetString("darkturquoise", "\x0700CED1");
		g_hColors.SetString("darkviolet", "\x079400D3");
		g_hColors.SetString("deeppink", "\x07FF1493");
		g_hColors.SetString("deepskyblue", "\x0700BFFF");
		g_hColors.SetString("dimgray", "\x07696969");
		g_hColors.SetString("dimgrey", "\x07696969");
		g_hColors.SetString("dodgerblue", "\x071E90FF");
		g_hColors.SetString("exalted", "\x07CCCCCD");
		g_hColors.SetString("firebrick", "\x07B22222");
		g_hColors.SetString("floralwhite", "\x07FFFAF0");
		g_hColors.SetString("forestgreen", "\x07228B22");
		g_hColors.SetString("frozen", "\x074983B3");
		g_hColors.SetString("fuchsia", "\x07FF00FF");
		g_hColors.SetString("fullblue", "\x070000FF");
		g_hColors.SetString("fullred", "\x07FF0000");
		g_hColors.SetString("gainsboro", "\x07DCDCDC");
		g_hColors.SetString("genuine", "\x074D7455");
		g_hColors.SetString("ghostwhite", "\x07F8F8FF");
		g_hColors.SetString("gold", "\x07FFD700");
		g_hColors.SetString("goldenrod", "\x07DAA520");
		g_hColors.SetString("gray", "\x07CCCCCC");
		g_hColors.SetString("grey", "\x07CCCCCC");
		g_hColors.SetString("green", "\x073EFF3E");
		g_hColors.SetString("greenyellow", "\x07ADFF2F");
		g_hColors.SetString("haunted", "\x0738F3AB");
		g_hColors.SetString("honeydew", "\x07F0FFF0");
		g_hColors.SetString("hotpink", "\x07FF69B4");
		g_hColors.SetString("immortal", "\x07E4AE33");
		g_hColors.SetString("indianred", "\x07CD5C5C");
		g_hColors.SetString("indigo", "\x074B0082");
		g_hColors.SetString("ivory", "\x07FFFFF0");
		g_hColors.SetString("khaki", "\x07F0E68C");
		g_hColors.SetString("lavender", "\x07E6E6FA");
		g_hColors.SetString("lavenderblush", "\x07FFF0F5");
		g_hColors.SetString("lawngreen", "\x077CFC00");
		g_hColors.SetString("legendary", "\x07D32CE6");
		g_hColors.SetString("lemonchiffon", "\x07FFFACD");
		g_hColors.SetString("lightblue", "\x07ADD8E6");
		g_hColors.SetString("lightcoral", "\x07F08080");
		g_hColors.SetString("lightcyan", "\x07E0FFFF");
		g_hColors.SetString("lightgoldenrodyellow", "\x07FAFAD2");
		g_hColors.SetString("lightgray", "\x07D3D3D3");
		g_hColors.SetString("lightgrey", "\x07D3D3D3");
		g_hColors.SetString("lightgreen", "\x0799FF99");
		g_hColors.SetString("lightpink", "\x07FFB6C1");
		g_hColors.SetString("lightsalmon", "\x07FFA07A");
		g_hColors.SetString("lightseagreen", "\x0720B2AA");
		g_hColors.SetString("lightskyblue", "\x0787CEFA");
		g_hColors.SetString("lightslategray", "\x07778899");
		g_hColors.SetString("lightslategrey", "\x07778899");
		g_hColors.SetString("lightsteelblue", "\x07B0C4DE");
		g_hColors.SetString("lightyellow", "\x07FFFFE0");
		g_hColors.SetString("lime", "\x0700FF00");
		g_hColors.SetString("limegreen", "\x0732CD32");
		g_hColors.SetString("linen", "\x07FAF0E6");
		g_hColors.SetString("magenta", "\x07FF00FF");
		g_hColors.SetString("maroon", "\x07800000");
		g_hColors.SetString("mediumaquamarine", "\x0766CDAA");
		g_hColors.SetString("mediumblue", "\x070000CD");
		g_hColors.SetString("mediumorchid", "\x07BA55D3");
		g_hColors.SetString("mediumpurple", "\x079370D8");
		g_hColors.SetString("mediumseagreen", "\x073CB371");
		g_hColors.SetString("mediumslateblue", "\x077B68EE");
		g_hColors.SetString("mediumspringgreen", "\x0700FA9A");
		g_hColors.SetString("mediumturquoise", "\x0748D1CC");
		g_hColors.SetString("mediumvioletred", "\x07C71585");
		g_hColors.SetString("midnightblue", "\x07191970");
		g_hColors.SetString("mintcream", "\x07F5FFFA");
		g_hColors.SetString("mistyrose", "\x07FFE4E1");
		g_hColors.SetString("moccasin", "\x07FFE4B5");
		g_hColors.SetString("mythical", "\x078847FF");
		g_hColors.SetString("navajowhite", "\x07FFDEAD");
		g_hColors.SetString("navy", "\x07000080");
		g_hColors.SetString("normal", "\x07B2B2B2");
		g_hColors.SetString("oldlace", "\x07FDF5E6");
		g_hColors.SetString("olive", "\x079EC34F");
		g_hColors.SetString("olivedrab", "\x076B8E23");
		g_hColors.SetString("orange", "\x07FFA500");
		g_hColors.SetString("orangered", "\x07FF4500");
		g_hColors.SetString("orchid", "\x07DA70D6");
		g_hColors.SetString("palegoldenrod", "\x07EEE8AA");
		g_hColors.SetString("palegreen", "\x0798FB98");
		g_hColors.SetString("paleturquoise", "\x07AFEEEE");
		g_hColors.SetString("palevioletred", "\x07D87093");
		g_hColors.SetString("papayawhip", "\x07FFEFD5");
		g_hColors.SetString("peachpuff", "\x07FFDAB9");
		g_hColors.SetString("peru", "\x07CD853F");
		g_hColors.SetString("pink", "\x07FFC0CB");
		g_hColors.SetString("plum", "\x07DDA0DD");
		g_hColors.SetString("powderblue", "\x07B0E0E6");
		g_hColors.SetString("purple", "\x07800080");
		g_hColors.SetString("rare", "\x074B69FF");
		g_hColors.SetString("red", "\x07FF4040");
		g_hColors.SetString("rosybrown", "\x07BC8F8F");
		g_hColors.SetString("royalblue", "\x074169E1");
		g_hColors.SetString("saddlebrown", "\x078B4513");
		g_hColors.SetString("salmon", "\x07FA8072");
		g_hColors.SetString("sandybrown", "\x07F4A460");
		g_hColors.SetString("seagreen", "\x072E8B57");
		g_hColors.SetString("seashell", "\x07FFF5EE");
		g_hColors.SetString("selfmade", "\x0770B04A");
		g_hColors.SetString("sienna", "\x07A0522D");
		g_hColors.SetString("silver", "\x07C0C0C0");
		g_hColors.SetString("skyblue", "\x0787CEEB");
		g_hColors.SetString("slateblue", "\x076A5ACD");
		g_hColors.SetString("slategray", "\x07708090");
		g_hColors.SetString("slategrey", "\x07708090");
		g_hColors.SetString("snow", "\x07FFFAFA");
		g_hColors.SetString("springgreen", "\x0700FF7F");
		g_hColors.SetString("steelblue", "\x074682B4");
		g_hColors.SetString("strange", "\x07CF6A32");
		g_hColors.SetString("tan", "\x07D2B48C");
		g_hColors.SetString("teal", "\x07008080");
		g_hColors.SetString("thistle", "\x07D8BFD8");
		g_hColors.SetString("tomato", "\x07FF6347");
		g_hColors.SetString("turquoise", "\x0740E0D0");
		g_hColors.SetString("uncommon", "\x07B0C3D9");
		g_hColors.SetString("unique", "\x07FFD700");
		g_hColors.SetString("unusual", "\x078650AC");
		g_hColors.SetString("valve", "\x07A50F79");
		g_hColors.SetString("vintage", "\x07476291");
		g_hColors.SetString("violet", "\x07EE82EE");
		g_hColors.SetString("wheat", "\x07F5DEB3");
		g_hColors.SetString("white", "\x07FFFFFF");
		g_hColors.SetString("whitesmoke", "\x07F5F5F5");
		g_hColors.SetString("yellow", "\x07FFFF00");
		g_hColors.SetString("yellowgreen", "\x079ACD32");
	}
	else
	{
		g_hColors.SetString("red", "\x07");
		g_hColors.SetString("lightred", "\x0F");
		g_hColors.SetString("darkred", "\x02");
		g_hColors.SetString("bluegrey", "\x0A");
		g_hColors.SetString("blue", "\x0B");
		g_hColors.SetString("darkblue", "\x0C");
		g_hColors.SetString("purple", "\x03");
		g_hColors.SetString("orchid", "\x0E");
		g_hColors.SetString("yellow", "\x09");
		g_hColors.SetString("gold", "\x10");
		g_hColors.SetString("lightgreen", "\x05");
		g_hColors.SetString("green", "\x04");
		g_hColors.SetString("lime", "\x06");
		g_hColors.SetString("grey", "\x08");
		g_hColors.SetString("grey2", "\x0D");
	}

	g_hColors.SetString("engine 1", "\x01");
	g_hColors.SetString("engine 2", "\x02");
	g_hColors.SetString("engine 3", "\x03");
	g_hColors.SetString("engine 4", "\x04");
	g_hColors.SetString("engine 5", "\x05");
	g_hColors.SetString("engine 6", "\x06");
	g_hColors.SetString("engine 7", "\x07");
	g_hColors.SetString("engine 8", "\x08");
	g_hColors.SetString("engine 9", "\x09");
	g_hColors.SetString("engine 10", "\x0A");
	g_hColors.SetString("engine 11", "\x0B");
	g_hColors.SetString("engine 12", "\x0C");
	g_hColors.SetString("engine 13", "\x0D");
	g_hColors.SetString("engine 14", "\x0E");
	g_hColors.SetString("engine 15", "\x0F");
	g_hColors.SetString("engine 16", "\x10");
}

stock bool HasBrackets(const char[] sSource)
{
	return (sSource[0] == '{' && sSource[strlen(sSource) - 1] == '}');
}

stock void StringToLower(char[] sSource)
{
	for (int i = 0; i < strlen(sSource); i++)
	{
		if (sSource[i] == '\0')
			break;

		sSource[i] = CharToLower(sSource[i]);
	}
}

stock bool IsSource2009()
{
	EngineVersion iEngineVersion = GetEngineVersion();
	return (iEngineVersion == Engine_CSS || iEngineVersion == Engine_TF2 || iEngineVersion == Engine_HL2DM || iEngineVersion == Engine_DODS);
}

stock void AddPrefixAndDefaultColor(char[] message, int size, char[] sDefaultColor = "engine 1", char[] sPrefixColor = "engine 2")
{
	if (g_sChatPrefix[0] != '\0' && !g_bIgnorePrefix)
		Format(message, size, "{%s}[%s]{%s} %s", sPrefixColor, g_sChatPrefix, sDefaultColor, message);
	else
		Format(message, size, "{%s}%s", sDefaultColor, message);
}

stock void SendPlayerMessage(int client, char[] message, int author  = 0)
{
	if (author > 0 && author <= MaxClients && IsClientInGame(author))
		CSayText2(client, message, author);
	else
		PrintToChat(client, message);
}