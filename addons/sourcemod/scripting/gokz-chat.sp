#include <sourcemod>

#include <colorvariables>
#include <cstrike>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <basecomm>
#include <updater>



public Plugin myinfo = 
{
	name = "GOKZ Chat", 
	author = "DanZay", 
	description = "Handles client-triggered chat messages", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-chat.txt"

bool gB_BaseComm;

ConVar gCV_gokz_chat_processing;
ConVar gCV_gokz_connection_messages;



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-chat");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-chat.phrases");
	
	CreateConVars();
	HookEvents();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	gB_BaseComm = LibraryExists("basecomm");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	gB_BaseComm = gB_BaseComm || StrEqual(name, "basecomm");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_BaseComm = gB_BaseComm && !StrEqual(name, "basecomm");
}



// =====[ CLIENT EVENTS ]=====

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client != 0 && gCV_gokz_chat_processing.BoolValue)
	{
		OnClientSayCommand_ChatProcessing(client, command, sArgs);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	PrintConnectMessage(client);
}

public Action OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) // player_disconnect pre hook
{
	event.BroadcastDisabled = true; // Block disconnection messages
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		PrintDisconnectMessage(client, event);
	}
	return Plugin_Continue;
}

public Action OnPlayerJoinTeam(Event event, const char[] name, bool dontBroadcast) // player_team pre hook
{
	event.BroadcastDisabled = true; // Block join team messages
	return Plugin_Continue;
}



// =====[ GENERAL ]=====

void CreateConVars()
{
	gCV_gokz_chat_processing = CreateConVar("gokz_chat_processing", "1", "Whether GOKZ processes player chat messages.", _, true, 0.0, true, 1.0);
	gCV_gokz_connection_messages = CreateConVar("gokz_connection_messages", "1", "Whether GOKZ handles connection and disconnection messages.", _, true, 0.0, true, 1.0);
}

void HookEvents()
{
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_team", OnPlayerJoinTeam, EventHookMode_Pre);
}



// =====[ CHAT PROCESSING ]=====

void OnClientSayCommand_ChatProcessing(int client, const char[] command, const char[] message)
{
	if (gB_BaseComm && BaseComm_IsClientGagged(client)
		 || UsedBaseChat(client, command, message)
		 || IsChatTrigger())
	{
		return;
	}
	
	// Resend messages that may have been a command with capital letters
	if ((message[0] == '!' || message[0] == '/') && IsCharUpper(message[1]))
	{
		char loweredMessage[128];
		String_ToLower(message, loweredMessage, sizeof(loweredMessage));
		FakeClientCommand(client, "say %s", loweredMessage);
		return;
	}
	
	char sanitisedMessage[128];
	strcopy(sanitisedMessage, sizeof(sanitisedMessage), message);
	SanitiseChatInput(sanitisedMessage, sizeof(sanitisedMessage));
	
	char sanitisedName[MAX_NAME_LENGTH];
	GetClientName(client, sanitisedName, sizeof(sanitisedName));
	SanitiseChatInput(sanitisedName, sizeof(sanitisedName));
	
	if (TrimString(sanitisedMessage) == 0)
	{
		return;
	}
	
	if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
	{
		GOKZ_PrintToChatAll(false, "{grey}*S* {lime}%s {default}: %s", sanitisedName, sanitisedMessage);
	}
	else
	{
		GOKZ_PrintToChatAll(false, "{lime}%s {default}: %s", sanitisedName, sanitisedMessage);
	}
}

bool UsedBaseChat(int client, const char[] command, const char[] message)
{
	// Assuming base chat is in use, check if message will get processed by basechat
	if (message[0] != '@')
	{
		return false;
	}
	
	if (strcmp(command, "say_team", false) == 0)
	{
		return true;
	}
	else if (strcmp(command, "say", false) == 0 && CheckCommandAccess(client, "sm_say", ADMFLAG_CHAT))
	{
		return true;
	}
	
	return false;
}

void SanitiseChatInput(char[] message, int maxlength)
{
	Color_StripFromChatText(message, message, maxlength);
	CRemoveColors(message, maxlength);
	// Chat gets double formatted, so replace '%' with '%%%%' to end up with '%'
	ReplaceString(message, maxlength, "%", "%%%%");
}



// =====[ CONNECTION MESSAGES ]=====

void PrintConnectMessage(int client)
{
	if (!gCV_gokz_connection_messages.BoolValue || IsFakeClient(client))
	{
		return;
	}
	
	GOKZ_PrintToChatAll(false, "%t", "Client Connection Message", client);
}

void PrintDisconnectMessage(int client, Event event) // Hooked to player_disconnect event
{
	if (!gCV_gokz_connection_messages.BoolValue || IsFakeClient(client))
	{
		return;
	}
	
	char reason[128];
	event.GetString("reason", reason, sizeof(reason));
	GOKZ_PrintToChatAll(false, "%t", "Client Disconnection Message", client, reason);
} 