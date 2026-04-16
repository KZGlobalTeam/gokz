#include <sourcemod>

#include <sdktools>
#include <clientprefs>

#include <gokz/core>
#include <gokz/jumpbeam>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN

#include <gokz/kzplayer>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Jump Beam", 
	author = "DanZay", 
	description = "Provides option to leave behind a trail when in midair", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

float gF_OldOrigin[MAXPLAYERS + 1][3];
bool gB_OldDucking[MAXPLAYERS + 1];
float gF_BeamOffset[MAXPLAYERS + 1][3];
bool gB_WaitingForOffset[MAXPLAYERS + 1];
Cookie gH_BeamOffsetCookie;
int gI_BeamModel;
TopMenu gTM_Options;
TopMenuObject gTMO_CatGeneral;
TopMenuObject gTMO_ItemsJB[JBOPTION_COUNT];
TopMenuObject gTMO_ItemBeamOffset;



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-jumpbeam");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-jumpbeam.phrases");
	
	gH_BeamOffsetCookie = new Cookie("gokz-jb-offset", "Jump Beam Offset (x y z)", CookieAccess_Private);
	
	RegConsoleCmd("sm_beamoffset", CommandBeamOffset, "[KZ] Set jump beam offset. Usage: !beamoffset <x> <y> <z>");
}

public void OnClientDisconnect(int client)
{
	gB_WaitingForOffset[client] = false;
}

public void OnClientCookiesCached(int client)
{
	char value[64];
	gH_BeamOffsetCookie.Get(client, value, sizeof(value));
	
	if (value[0] == '\0')
	{
		gF_BeamOffset[client] = view_as<float>({0.0, 0.0, 0.0});
	}
	else
	{
		char parts[3][16];
		ExplodeString(value, " ", parts, 3, 16);
		gF_BeamOffset[client][0] = StringToFloat(parts[0]);
		gF_BeamOffset[client][1] = StringToFloat(parts[1]);
		gF_BeamOffset[client][2] = StringToFloat(parts[2]);
	}
}

public void OnAllPluginsLoaded()
{	
	TopMenu topMenu;
	if (LibraryExists("gokz-core") && ((topMenu = GOKZ_GetOptionsTopMenu()) != null))
	{
		GOKZ_OnOptionsMenuReady(topMenu);
	}
}



// =====[ CLIENT EVENTS ]=====

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!IsValidClient(client))
	{
		return;
	}

	OnPlayerRunCmdPost_JumpBeam(client);
	UpdateOldVariables(client);
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	gI_BeamModel = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_Options();
	OnOptionsMenuReady_OptionsMenu(topMenu);
}



// =====[ GENERAL ]=====

void UpdateOldVariables(int client)
{
	if (IsPlayerAlive(client))
	{
		Movement_GetOrigin(client, gF_OldOrigin[client]);
		gB_OldDucking[client] = Movement_GetDucking(client);
	}
}



// =====[ JUMP BEAM ]=====

void OnPlayerRunCmdPost_JumpBeam(int targetClient)
{
	// In this case, spectators are handled from the target 
	// client's OnPlayerRunCmd call, otherwise the jump 
	// beam will be all broken up.
	
	KZPlayer targetPlayer = KZPlayer(targetClient);
	
	if (targetPlayer.Fake || !targetPlayer.Alive || targetPlayer.OnGround || !targetPlayer.ValidJump)
	{
		return;
	}
	
	// Send to self
	SendJumpBeam(targetPlayer, targetPlayer);
	
	// Send to spectators
	for (int client = 1; client <= MaxClients; client++)
	{
		KZPlayer player = KZPlayer(client);
		if (player.InGame && !player.Alive && player.ObserverTarget == targetClient)
		{
			SendJumpBeam(player, targetPlayer);
		}
	}
}

void SendJumpBeam(KZPlayer player, KZPlayer targetPlayer)
{
	if (player.JBType == JBType_Disabled)
	{
		return;
	}
	
	switch (player.JBType)
	{
		case JBType_Feet:SendFeetJumpBeam(player, targetPlayer);
		case JBType_Head:SendHeadJumpBeam(player, targetPlayer);
		case JBType_FeetAndHead:
		{
			SendFeetJumpBeam(player, targetPlayer);
			SendHeadJumpBeam(player, targetPlayer);
		}
		case JBType_Ground:SendGroundJumpBeam(player, targetPlayer);
	}
}

void SendFeetJumpBeam(KZPlayer player, KZPlayer targetPlayer)
{
	float origin[3], beamStart[3], beamEnd[3];
	int beamColour[4];
	targetPlayer.GetOrigin(origin);
	
	beamStart = gF_OldOrigin[targetPlayer.ID];
	beamEnd = origin;
	ApplyBeamOffset(beamStart, gF_BeamOffset[player.ID]);
	ApplyBeamOffset(beamEnd, gF_BeamOffset[player.ID]);
	GetJumpBeamColour(targetPlayer, beamColour);
	
	TE_SetupBeamPoints(beamStart, beamEnd, gI_BeamModel, 0, 0, 0, JB_BEAM_LIFETIME, 0.25, 0.25, 10, 0.0, beamColour, 0);
	TE_SendToClient(player.ID);
}

void SendHeadJumpBeam(KZPlayer player, KZPlayer targetPlayer)
{
	float origin[3], beamStart[3], beamEnd[3];
	int beamColour[4];
	targetPlayer.GetOrigin(origin);
	
	beamStart = gF_OldOrigin[targetPlayer.ID];
	beamEnd = origin;
	ApplyBeamOffset(beamStart, gF_BeamOffset[player.ID]);
	ApplyBeamOffset(beamEnd, gF_BeamOffset[player.ID]);
	if (gB_OldDucking[targetPlayer.ID])
	{
		beamStart[2] = beamStart[2] + 54.0;
	}
	else
	{
		beamStart[2] = beamStart[2] + 72.0;
	}
	if (targetPlayer.Ducking)
	{
		beamEnd[2] = beamEnd[2] + 54.0;
	}
	else
	{
		beamEnd[2] = beamEnd[2] + 72.0;
	}
	GetJumpBeamColour(targetPlayer, beamColour);
	
	TE_SetupBeamPoints(beamStart, beamEnd, gI_BeamModel, 0, 0, 0, JB_BEAM_LIFETIME, 0.25, 0.25, 10, 0.0, beamColour, 0);
	TE_SendToClient(player.ID);
}

void SendGroundJumpBeam(KZPlayer player, KZPlayer targetPlayer)
{
	float origin[3], takeoffOrigin[3], beamStart[3], beamEnd[3];
	int beamColour[4];
	targetPlayer.GetOrigin(origin);
	targetPlayer.GetTakeoffOrigin(takeoffOrigin);
	
	beamStart = gF_OldOrigin[targetPlayer.ID];
	beamEnd = origin;
	ApplyBeamOffset(beamStart, gF_BeamOffset[player.ID]);
	ApplyBeamOffset(beamEnd, gF_BeamOffset[player.ID]);
	beamStart[2] = takeoffOrigin[2] + 0.1;
	beamEnd[2] = takeoffOrigin[2] + 0.1;
	GetJumpBeamColour(targetPlayer, beamColour);
	
	TE_SetupBeamPoints(beamStart, beamEnd, gI_BeamModel, 0, 0, 0, JB_BEAM_LIFETIME, 0.25, 0.25, 10, 0.0, beamColour, 0);
	TE_SendToClient(player.ID);
}

void GetJumpBeamColour(KZPlayer targetPlayer, int colour[4])
{
	if (targetPlayer.Ducking)
	{
		colour =  { 255, 0, 0, 110 }; // Red
	}
	else
	{
		colour =  { 0, 255, 0, 110 }; // Green
	}
}

void ApplyBeamOffset(float pos[3], const float offset[3])
{
	pos[0] += offset[0];
	pos[1] += offset[1];
	pos[2] += offset[2];
}

float ClampFloat(float value, float min, float max)
{
	if (value < min)
	{
		return min;
	}
	if (value > max)
	{
		return max;
	}
	return value;
}



public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (!gB_WaitingForOffset[client])
	{
		return Plugin_Continue;
	}
	
	gB_WaitingForOffset[client] = false;
	
	char trimmed[64];
	strcopy(trimmed, sizeof(trimmed), sArgs);
	TrimString(trimmed);
	
	char parts[3][16];
	int count = ExplodeString(trimmed, " ", parts, 3, 16);
	
	if (count < 3 || !IsNumericString(parts[0]) || !IsNumericString(parts[1]) || !IsNumericString(parts[2]))
	{
		GOKZ_PrintToChat(client, true, "%t", "Beam Offset Invalid");
		return Plugin_Stop;
	}
	
	float x = ClampFloat(StringToFloat(parts[0]), -JB_OFFSET_MAX, JB_OFFSET_MAX);
	float y = ClampFloat(StringToFloat(parts[1]), -JB_OFFSET_MAX, JB_OFFSET_MAX);
	float z = ClampFloat(StringToFloat(parts[2]), -JB_OFFSET_MAX, JB_OFFSET_MAX);
	
	SetBeamOffset(client, x, y, z);
	return Plugin_Stop;
}

bool IsNumericString(const char[] str)
{
	int i = 0;
	if (str[0] == '-' || str[0] == '+')
	{
		i = 1;
	}
	
	bool hasDigit = false;
	bool hasDot = false;
	
	while (str[i] != '\0')
	{
		if (str[i] == '.')
		{
			if (hasDot)
			{
				return false;
			}
			hasDot = true;
		}
		else if (str[i] < '0' || str[i] > '9')
		{
			return false;
		}
		else
		{
			hasDigit = true;
		}
		i++;
	}
	
	return hasDigit;
}



// =====[ COMMANDS ]=====

public Action CommandBeamOffset(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if (args < 3)
	{
		GOKZ_PrintToChat(client, true, "%t", "Beam Offset Usage");
		GOKZ_PrintToChat(client, true, "%t", "Current Beam Offset", 
			gF_BeamOffset[client][0], gF_BeamOffset[client][1], gF_BeamOffset[client][2]);
		return Plugin_Handled;
	}
	
	char arg[16];
	
	GetCmdArg(1, arg, sizeof(arg));
	float x = ClampFloat(StringToFloat(arg), -JB_OFFSET_MAX, JB_OFFSET_MAX);
	
	GetCmdArg(2, arg, sizeof(arg));
	float y = ClampFloat(StringToFloat(arg), -JB_OFFSET_MAX, JB_OFFSET_MAX);
	
	GetCmdArg(3, arg, sizeof(arg));
	float z = ClampFloat(StringToFloat(arg), -JB_OFFSET_MAX, JB_OFFSET_MAX);
	
	SetBeamOffset(client, x, y, z);
	return Plugin_Handled;
}

void SetBeamOffset(int client, float x, float y, float z)
{
	gF_BeamOffset[client][0] = x;
	gF_BeamOffset[client][1] = y;
	gF_BeamOffset[client][2] = z;
	
	char value[64];
	FormatEx(value, sizeof(value), "%.1f %.1f %.1f", x, y, z);
	gH_BeamOffsetCookie.Set(client, value);
	
	GOKZ_PrintToChat(client, true, "%t", "Current Beam Offset", x, y, z);
}



// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOptions();
}

void RegisterOptions()
{
	for (JBOption option; option < JBOPTION_COUNT; option++)
	{
		GOKZ_RegisterOption(gC_JBOptionNames[option], gC_JBOptionDescriptions[option], 
			OptionType_Int, gI_JBOptionDefaultValues[option], 0, gI_JBOptionCounts[option] - 1);
	}
}



// =====[ OPTIONS MENU ]=====

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	if (gTM_Options == topMenu)
	{
		return;
	}
	
	gTM_Options = topMenu;
	gTMO_CatGeneral = gTM_Options.FindCategory(GENERAL_OPTION_CATEGORY);
	
	for (int option = 0; option < view_as<int>(JBOPTION_COUNT); option++)
	{
		gTMO_ItemsJB[option] = gTM_Options.AddItem(gC_JBOptionNames[option], TopMenuHandler_General, gTMO_CatGeneral);
	}
	
	gTMO_ItemBeamOffset = gTM_Options.AddItem("GOKZ JB - Beam Offset", TopMenuHandler_BeamOffset, gTMO_CatGeneral);
}

public void TopMenuHandler_General(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	JBOption option = JBOPTION_INVALID;
	for (int i = 0; i < view_as<int>(JBOPTION_COUNT); i++)
	{
		if (topobj_id == gTMO_ItemsJB[i])
		{
			option = view_as<JBOption>(i);
			break;
		}
	}
	
	if (option == JBOPTION_INVALID)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		switch (option)
		{
			case JBOption_Type:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					gC_JBOptionPhrases[option], param, 
					gC_JBTypePhrases[GOKZ_JB_GetOption(param, option)], param);
			}
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		switch (option)
		{
			default:
			{
				GOKZ_JB_CycleOption(param, option);
				gTM_Options.Display(param, TopMenuPosition_LastCategory);
			}
		}
	}
} 

public void TopMenuHandler_BeamOffset(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T - %.1f %.1f %.1f", 
			"Options Menu - Beam Offset", param, 
			gF_BeamOffset[param][0], gF_BeamOffset[param][1], gF_BeamOffset[param][2]);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		gB_WaitingForOffset[param] = true;
		CreateTimer(15.0, Timer_BeamOffsetTimeout, GetClientUserId(param), TIMER_FLAG_NO_MAPCHANGE);
		GOKZ_PrintToChat(param, true, "%t", "Beam Offset Prompt");
	}
}

public Action Timer_BeamOffsetTimeout(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client != 0 && gB_WaitingForOffset[client])
	{
		gB_WaitingForOffset[client] = false;
	}
	return Plugin_Stop;
} 