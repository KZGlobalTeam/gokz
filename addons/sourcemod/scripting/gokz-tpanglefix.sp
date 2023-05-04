#include <sourcemod>

#include <dhooks>

#include <gokz/core>
#include <gokz/tpanglefix>

#include <autoexecconfig>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Teleport Angle Fix",
	author = "zer0.k",
	description = "Fix teleporting not modifying player's view angles due to packet loss",
	version = GOKZ_VERSION,
	url = "https://github.com/KZGlobalTeam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-tpanglefix.txt"

TopMenu gTM_Options;
TopMenuObject gTMO_CatGeneral;
TopMenuObject gTMO_ItemTPAngleFix;
Address gA_ViewAnglePatchAddress;
bool gB_EnableFix[MAXPLAYERS + 1];
DynamicDetour gH_WriteViewAngleUpdate;
int gI_ClientOffset;

// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-tpanglefix");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("gokz-tpanglefix.phrases");

	SetupPatch();
	HookEvents();
	RegisterCommands();
}

void SetupPatch()
{
	GameData gamedataConf = LoadGameConfigFile("gokz-tpanglefix.games");
	if (gamedataConf == null)
	{
		SetFailState("Failed to load gokz-tpanglefix gamedata");
	}	
	// Get the patching address
	Address addr = GameConfGetAddress(gamedataConf, "WriteViewAngleUpdate");
	if(addr == Address_Null)
	{
		SetFailState("Can't find WriteViewAngleUpdate address.");	
	}
	
	// Get the offset from the start of the signature to the start of our patch area.
	int offset = GameConfGetOffset(gamedataConf, "WriteViewAngleUpdateReliableOffset");
	if(offset == -1)
	{
		SetFailState("Can't find WriteViewAngleUpdateReliableOffset in gamedata.");
	}
	gA_ViewAnglePatchAddress = view_as<Address>(addr + view_as<Address>(offset));
}

void HookEvents()
{
	GameData gamedataConf = LoadGameConfigFile("gokz-tpanglefix.games");
	if (gamedataConf == null)
	{
		SetFailState("Failed to load gokz-tpanglefix gamedata");
	}
	gH_WriteViewAngleUpdate = DynamicDetour.FromConf(gamedataConf, "CGameClient::WriteViewAngleUpdate");
		
	if (gH_WriteViewAngleUpdate == INVALID_HANDLE)
	{
		SetFailState("Failed to find CGameClient::WriteViewAngleUpdate function signature");
	}
	
	if (!gH_WriteViewAngleUpdate.Enable(Hook_Pre, DHooks_OnWriteViewAngleUpdate_Pre))
	{
		SetFailState("Failed to enable detour on CGameClient::WriteViewAngleUpdate");
	}
	// Prevent the server from crashing.
	FindConVar("sv_parallel_sendsnapshot").SetBool(false);
	FindConVar("sv_parallel_sendsnapshot").AddChangeHook(OnParallelSendSnapshotCvarChanged);

	gI_ClientOffset = gamedataConf.GetOffset("ClientIndexOffset");
	if (gI_ClientOffset == -1)
	{
		SetFailState("Failed to get ClientIndexOffset offset.");
	}
}

void OnParallelSendSnapshotCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar.BoolValue)
	{
		convar.BoolValue = false;
	}
}

public MRESReturn DHooks_OnWriteViewAngleUpdate_Pre(Address pThis)
{
	int client = LoadFromAddress(pThis + view_as<Address>(gI_ClientOffset), NumberType_Int32);
	if (gB_EnableFix[client])
	{
		PatchAngleFix();
	}
	else
	{
		RestoreAngleFix();
	}
	return MRES_Ignored;
}

void PatchAngleFix()
{
	if (LoadFromAddress(gA_ViewAnglePatchAddress, NumberType_Int8) == 0)
	{
		StoreToAddress(gA_ViewAnglePatchAddress, 1, NumberType_Int8);
	}
}

void RestoreAngleFix()
{
	if (LoadFromAddress(gA_ViewAnglePatchAddress, NumberType_Int8) == 1)
	{
		StoreToAddress(gA_ViewAnglePatchAddress, 0, NumberType_Int8);
	}
}

bool ToggleAngleFix(int client)
{
	gB_EnableFix[client] = !gB_EnableFix[client];
	return gB_EnableFix[client];
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}

	TopMenu topMenu;
	if (LibraryExists("gokz-core") && ((topMenu = GOKZ_GetOptionsTopMenu()) != null))
	{
		GOKZ_OnOptionsMenuReady(topMenu);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}

}

// =====[ CLIENT EVENTS ]=====

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	OnOptionChanged_Options(client, option, newValue);
}

// =====[ OTHER EVENTS ]=====

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_Options();
	OnOptionsMenuReady_OptionsMenu(topMenu);
}


// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOption();
}

void RegisterOption()
{
	GOKZ_RegisterOption(TPANGLEFIX_OPTION_NAME, TPANGLEFIX_OPTION_DESCRIPTION, 
		OptionType_Int, TPAngleFix_Disabled, 0, TPANGLEFIX_COUNT - 1);
}

void OnOptionChanged_Options(int client, const char[] option, any newValue)
{
	if (StrEqual(option, TPANGLEFIX_OPTION_NAME))
	{
		gB_EnableFix[client] = newValue;
		switch (newValue)
		{
			case TPAngleFix_Disabled:
			{
				GOKZ_PrintToChat(client, true, "%t", "Option - TP Angle Fix - Disable");
			}
			case TPAngleFix_Enabled:
			{
				GOKZ_PrintToChat(client, true, "%t", "Option - TP Angle Fix - Enable");
			}
		}
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
	gTMO_ItemTPAngleFix = gTM_Options.AddItem(TPANGLEFIX_OPTION_NAME, TopMenuHandler_TPAngleFix, gTMO_CatGeneral);
}

public void TopMenuHandler_TPAngleFix(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (topobj_id != gTMO_ItemTPAngleFix)
	{
		return;
	}

	if (action == TopMenuAction_DisplayOption)
	{
		if (GOKZ_GetOption(param, TPANGLEFIX_OPTION_NAME) == TPAngleFix_Disabled)
		{
			FormatEx(buffer, maxlength, "%T - %T", 
				"Options Menu - TP Angle Fix", param, 
				"Options Menu - Disabled", param);
		}
		else
		{
			FormatEx(buffer, maxlength, "%T - %T", 
				"Options Menu - TP Angle Fix", param, 
				"Options Menu - Enabled", param);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		GOKZ_CycleOption(param, TPANGLEFIX_OPTION_NAME);
		gTM_Options.Display(param, TopMenuPosition_LastCategory);
	}
}

// =====[ COMMANDS ]=====

void RegisterCommands()
{
	RegConsoleCmd("sm_tpafix", CommandTPAFix, "[KZ] Toggle teleport angle fix.");
}

public Action CommandTPAFix(int client, int args)
{
	GOKZ_SetOption(client, TPANGLEFIX_OPTION_NAME, ToggleAngleFix(client));
	return Plugin_Handled;
}