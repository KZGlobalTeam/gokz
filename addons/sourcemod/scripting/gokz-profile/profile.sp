
#define ITEM_INFO_NAME "name"
#define ITEM_INFO_MODE "mode"
#define ITEM_INFO_RANK "rank"
#define ITEM_INFO_POINTS "points"

int profileTargetPlayer[MAXPLAYERS];
int profileMode[MAXPLAYERS];
bool profileWaitingForUpdate[MAXPLAYERS];



// =====[ PUBLIC ]=====

void ShowProfile(int client, int player = 0)
{
	if (player != 0)
	{
		profileTargetPlayer[client] = player;
		profileMode[client] = GOKZ_GetCoreOption(player, Option_Mode);
	}
		
	if (GOKZ_GL_GetRankPoints(profileTargetPlayer[client], profileMode[client]) < 0)
	{
		GOKZ_GL_UpdatePoints(profileTargetPlayer[client], profileMode[client]);
		profileWaitingForUpdate[client] = true;
		return;
	}
	
	profileWaitingForUpdate[client] = false;
	Menu menu = new Menu(MenuHandler_Profile);
	menu.SetTitle("%T", "Profile Menu - Title", client);
	ProfileMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ EVENTS ]=====

void Profile_OnClientConnected(int client)
{
	profileTargetPlayer[client] = 0;
	profileWaitingForUpdate[client] = false;
}

void Profile_OnClientDisconnect(int client)
{
	profileTargetPlayer[client] = 0;
	profileWaitingForUpdate[client] = false;
}

void Profile_OnPointsUpdated(int player, int mode)
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (profileWaitingForUpdate[client]
			&& profileTargetPlayer[client] == player
			&& profileMode[client] == mode)
		{
			ShowProfile(client);
		}
	}
}

public int MenuHandler_Profile(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		
		if (StrEqual(info, ITEM_INFO_MODE, false))
		{
			if (++profileMode[param1] == MODE_COUNT)
			{
				profileMode[param1] = 0;
			}
		}
		else if (StrEqual(info, ITEM_INFO_RANK, false))
		{
			// TODO Show rank info
		}
		
		ShowProfile(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =====[ PRIVATE ]=====

static void ProfileMenuAddItems(int client, Menu menu)
{
	char display[32];
	int player = profileTargetPlayer[client];
	int mode = profileMode[client];
	
	FormatEx(display, sizeof(display), "%T: %N",
			 "Profile Menu - Name", client, player);
	menu.AddItem(ITEM_INFO_NAME, display);
	
	FormatEx(display, sizeof(display), "%T: %s",
			 "Profile Menu - Mode", client, gC_ModeNames[mode]);
	menu.AddItem(ITEM_INFO_MODE, display);
	
	FormatEx(display, sizeof(display), "%T: %s",
			 "Profile Menu - Rank", client, gC_rankName[gI_Rank[player][mode]]);
	menu.AddItem(ITEM_INFO_RANK, display);
	
	FormatEx(display, sizeof(display), "%T: %d",
			 "Profile Menu - Points", client, GOKZ_GL_GetRankPoints(player, mode));
	menu.AddItem(ITEM_INFO_POINTS, display);
}
