#include <sourcemod>

#include <gokz/core>
#include <gokz/paint>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



// Credit to SlidyBat for a large part of the painting code (https://forums.alliedmods.net/showthread.php?p=2541664)
// Credit to Cabbage McGravel of the MomentumMod team for making the textures

public Plugin myinfo = 
{
	name = "GOKZ Paint", 
	author = "zealain", 
	description = "Provides client sided paint for visibility", 
	version = GOKZ_VERSION, 
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-paint.txt"

char gC_PaintColors[][32] =
{
	"paint_red",
	"paint_white",
	"paint_black",
	"paint_blue",
	"paint_brown",
	"paint_green",
	"paint_yellow",
	"paint_purple"
};

char gC_PaintSizePostfix[][8] =
{
	"_small",
	"_med",
	"_large"
};

int gI_Decals[sizeof(gC_PaintColors)][sizeof(gC_PaintSizePostfix)];
float gF_LastPaintPos[MAXPLAYERS + 1][3];
bool gB_IsPainting[MAXPLAYERS + 1];

TopMenu gTM_Options;
TopMenuObject gTMO_CatPaint;
TopMenuObject gTMO_ItemsPaint[PAINTOPTION_COUNT];


// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-paint");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-paint.phrases");
	
	RegisterCommands();
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



// =====[ EVENTS ]=====

public void GOKZ_OnOptionsMenuCreated(TopMenu topMenu)
{
	OnOptionsMenuCreated_OptionsMenu(topMenu);
}

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_Options();
	OnOptionsMenuReady_OptionsMenu(topMenu);
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	
	AddFileToDownloadsTable("materials/gokz/paint/paint_decal.vtf");
	for (int color = 0; color < sizeof(gC_PaintColors); color++)
	{
		for (int size = 0; size < sizeof(gC_PaintSizePostfix); size++)
		{
			Format(buffer, sizeof(buffer), "gokz/paint/%s%s.vmt", gC_PaintColors[color], gC_PaintSizePostfix[size]);
			gI_Decals[color][size] = PrecachePaint(buffer);
		}
	}
	
	CreateTimer(0.1, Timer_Paint, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}



// =====[ PAINT ]=====

void Paint(int client)
{
	if (!IsValidClient(client) ||		
		IsFakeClient(client))
	{
		return;
	}
	
	float position[3];
	bool hit = GetPlayerEyeViewPoint(client, position);
	
	if (!hit || GetVectorDistance(position, gF_LastPaintPos[client], true) < MIN_PAINT_SPACING)
	{
		return;
	}
	
	int paint = GOKZ_GetOption(client, gC_PaintOptionNames[PaintOption_Color]);
	int size = GOKZ_GetOption(client, gC_PaintOptionNames[PaintOption_Size]);
	
	TE_SetupWorldDecal(position, gI_Decals[paint][size]);
	TE_SendToClient(client);
	 
	gF_LastPaintPos[client] = position;
}

public Action Timer_Paint(Handle timer)
{
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		if (gB_IsPainting[client])
		{
			Paint(client);
		}
	}
	return Plugin_Continue;
}

void TE_SetupWorldDecal(const float origin[3], int index)
{	
	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin", origin);
	TE_WriteNum("m_nIndex", index);
}

int PrecachePaint(char[] filename)
{
	char path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "materials/%s", filename);
	AddFileToDownloadsTable(path);
	
	return PrecacheDecal(filename, true);
}

bool GetPlayerEyeViewPoint(int client, float position[3])
{
	float angles[3];
	GetClientEyeAngles(client, angles);

	float origin[3];
	GetClientEyePosition(client, origin);

	Handle trace = TR_TraceRayFilterEx(origin, angles, MASK_PLAYERSOLID, RayType_Infinite, TraceEntityFilterPlayers);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(position, trace);
		delete trace;
		return true;
	}
	delete trace;
	return false;
}



// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOptions();
}

void RegisterOptions()
{
	for (PaintOption option; option < PAINTOPTION_COUNT; option++)
	{
		GOKZ_RegisterOption(gC_PaintOptionNames[option], gC_PaintOptionDescriptions[option], 
			OptionType_Int, gI_PaintOptionDefaults[option], 0, gI_PaintOptionCounts[option] - 1);
	}
}



// =====[ OPTIONS MENU ]=====

void OnOptionsMenuCreated_OptionsMenu(TopMenu topMenu)
{
	if (gTM_Options == topMenu && gTMO_CatPaint != INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	gTMO_CatPaint = topMenu.AddCategory(PAINT_OPTION_CATEGORY, TopMenuHandler_Categories);
}

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	// Make sure category exists
	if (gTMO_CatPaint == INVALID_TOPMENUOBJECT)
	{
		GOKZ_OnOptionsMenuCreated(topMenu);
	}
	
	if (gTM_Options == topMenu)
	{
		return;
	}
	
	gTM_Options = topMenu;
	
	// Add gokz-paint option items	
	for (int option = 0; option < view_as<int>(PAINTOPTION_COUNT); option++)
	{
		gTMO_ItemsPaint[option] = gTM_Options.AddItem(gC_PaintOptionNames[option], TopMenuHandler_Paint, gTMO_CatPaint);
	}
}

void DisplayPaintOptionsMenu(int client)
{
	gTM_Options.DisplayCategory(gTMO_CatPaint, client);
}

public void TopMenuHandler_Categories(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption || action == TopMenuAction_DisplayTitle)
	{
		if (topobj_id == gTMO_CatPaint)
		{
			Format(buffer, maxlength, "%T", "Options Menu - Paint", param);
		}
	}
}

public void TopMenuHandler_Paint(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	PaintOption option = PAINTOPTION_INVALID;
	for (int i = 0; i < view_as<int>(PAINTOPTION_COUNT); i++)
	{
		if (topobj_id == gTMO_ItemsPaint[i])
		{
			option = view_as<PaintOption>(i);
			break;
		}
	}
	
	if (option == PAINTOPTION_INVALID)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		switch (option)
		{
			case PaintOption_Color:
			{
				FormatEx(buffer, maxlength, "%T - %T",
					gC_PaintOptionPhrases[option], param,
					gC_PaintColorPhrases[GOKZ_GetOption(param, gC_PaintOptionNames[option])], param);
			}
			case PaintOption_Size:
			{
				FormatEx(buffer, maxlength, "%T - %T",
					gC_PaintOptionPhrases[option], param,
					gC_PaintSizePhrases[GOKZ_GetOption(param, gC_PaintOptionNames[option])], param);
			}
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (option == PaintOption_Color)
		{
			DisplayColorMenu(param);
		}
		else
		{
			GOKZ_CycleOption(param, gC_PaintOptionNames[option]);
			gTM_Options.Display(param, TopMenuPosition_LastCategory);
		}
	}
}

void DisplayColorMenu(int client)
{
	char buffer[32];
	
	Menu menu = new Menu(MenuHandler_PaintColor);
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.SetTitle("%T", "Paint Color Menu - Title", client);
	
	for (int i = 0; i < PAINTCOLOR_COUNT; i++)
	{
		FormatEx(buffer, sizeof(buffer), "%T", gC_PaintColorPhrases[i], client);
		menu.AddItem(gC_PaintColors[i], buffer);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_PaintColor(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			
			for (int i = 0; i < PAINTCOLOR_COUNT; i++)
			{
				if (StrEqual(gC_PaintColors[i], item))
				{
					GOKZ_SetOption(param1, gC_PaintOptionNames[PaintOption_Color], i);
					DisplayPaintOptionsMenu(param1);
					return 0;
				}
			}
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayPaintOptionsMenu(param1);
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}



// =====[ COMMANDS ]=====

void RegisterCommands()
{
	RegConsoleCmd("+paint", CommandPaintStart, "[KZ] Start painting.");
	RegConsoleCmd("-paint", CommandPaintEnd, "[KZ] Stop painting.");
	RegConsoleCmd("sm_paint", CommandPaint, "[KZ] Place a paint.");
	RegConsoleCmd("sm_paintoptions", CommandPaintOptions, "[KZ] Open the paint options.");
}

public Action CommandPaintStart(int client, int args)
{
	gB_IsPainting[client] = true;
	return Plugin_Handled;
}

public Action CommandPaintEnd(int client, int args)
{
	gB_IsPainting[client] = false;
	return Plugin_Handled;
}

public Action CommandPaint(int client, int args)
{
	Paint(client);
	return Plugin_Handled;
}

public Action CommandPaintOptions(int client, int args)
{
	DisplayPaintOptionsMenu(client);
	return Plugin_Handled;
}
