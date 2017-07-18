/*
	Player Top Menu
	
	Lets players view the top record holders
	See also:
		database/open_playertop20.sp
*/



void PlayerTopMenuCreateMenus()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		PlayerTopMenuCreate(client);
		PlayerTopSubMenuCreate(client);
	}
}

void PlayerTopMenuDisplay(int client)
{
	gH_PlayerTopMenu[client].SetTitle("%T", "Player Top Menu - Title", client, gC_ModeNames[g_PlayerTopMode[client]]);
	PlayerTopMenuAddItems(client, gH_PlayerTopMenu[client]);
	gH_PlayerTopMenu[client].Display(client, MENU_TIME_FOREVER);
}



/*===============================  Public Callbacks  ===============================*/

public int MenuHandler_PlayerTop(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		DB_OpenPlayerTop20(param1, param2, g_PlayerTopMode[param1]);
	}
}

public int MenuHandler_PlayerTopSubmenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit) {
		PlayerTopMenuDisplay(param1);
	}
}



/*===============================  Static Functions  ===============================*/

static void PlayerTopMenuCreate(int client)
{
	gH_PlayerTopMenu[client] = new Menu(MenuHandler_PlayerTop);
}

static void PlayerTopSubMenuCreate(int client)
{
	gH_PlayerTopSubMenu[client] = new Menu(MenuHandler_PlayerTopSubmenu);
	gH_PlayerTopSubMenu[client].Pagination = 5;
}

static void PlayerTopMenuAddItems(int client, Menu menu)
{
	char text[32];
	menu.RemoveAllItems();
	for (int timeType = 0; timeType < TIMETYPE_COUNT; timeType++)
	{
		FormatEx(text, sizeof(text), "%T", "Player Top Menu - Top 20", client, gC_TimeTypeNames[timeType]);
		menu.AddItem("", text, ITEMDRAW_DEFAULT);
	}
} 