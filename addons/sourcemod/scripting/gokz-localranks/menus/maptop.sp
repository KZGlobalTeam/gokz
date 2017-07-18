/*
	Map Top Menu
	
	Lets players view the top times on a map.
	See also:
		database/open_maptop.sp
		database/open_maptop20.sp
*/



void MapTopMenuCreateMenus()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		MapTopMenuCreate(client);
		MapTopSubMenuCreate(client);
	}
}

void MapTopMenuDisplay(int client)
{
	if (gI_MapTopCourse[client] == 0)
	{
		gH_MapTopMenu[client].SetTitle("%T", "Map Top Menu - Title", client, 
			gC_MapTopMapName[client], gC_ModeNames[g_MapTopMode[client]]);
	}
	else
	{
		gH_MapTopMenu[client].SetTitle("%T", "Map Top Menu - Title (Bonus)", client, 
			gC_MapTopMapName[client], gC_ModeNames[g_MapTopMode[client]]);
	}
	MapTopMenuAddItems(client, gH_MapTopMenu[client]);
	gH_MapTopMenu[client].Display(client, MENU_TIME_FOREVER);
}



/*===============================  Public Callbacks  ===============================*/

public int MenuHandler_MapTop(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		DB_OpenMapTop20(param1, gI_MapTopMapID[param1], gI_MapTopCourse[param1], g_MapTopMode[param1], param2);
	}
}

public int MenuHandler_MapTopSubmenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		MapTopMenuDisplay(param1);
	}
}



/*===============================  Static Functions  ===============================*/

static void MapTopMenuCreate(int client)
{
	gH_MapTopMenu[client] = new Menu(MenuHandler_MapTop);
}

static void MapTopSubMenuCreate(int client)
{
	gH_MapTopSubMenu[client] = new Menu(MenuHandler_MapTopSubmenu);
	gH_MapTopSubMenu[client].Pagination = 5;
}

static void MapTopMenuAddItems(int client, Menu menu)
{
	char text[32];
	menu.RemoveAllItems();
	for (int timeType = 0; timeType < TIMETYPE_COUNT; timeType++)
	{
		FormatEx(text, sizeof(text), "%T", "Map Top Menu - Top 20", client, gC_TimeTypeNames[timeType]);
		menu.AddItem("", text, ITEMDRAW_DEFAULT);
	}
} 