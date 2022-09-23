#define ITEM_INFO_POINT_A "a"
#define ITEM_INFO_POINT_B "b"
#define ITEM_INFO_GET_DISTANCE "get"
#define ITEM_INFO_GET_BLOCK_DISTANCE "block"

// =====[ PUBLIC ]=====

void DisplayMeasureMenu(int client, bool reset = true)
{
	if (reset)
	{
		MeasureResetPos(client);
	}
	
	Menu menu = new Menu(MenuHandler_Measure);
	menu.SetTitle("%T", "Measure Menu - Title", client);
	MeasureMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ EVENTS ]=====

public int MenuHandler_Measure(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));
		
		if (StrEqual(info, ITEM_INFO_POINT_A, false))
		{
			MeasureGetPos(param1, 0);
		}
		else if (StrEqual(info, ITEM_INFO_POINT_B, false))
		{
			MeasureGetPos(param1, 1);
		}
		else if (StrEqual(info, ITEM_INFO_GET_DISTANCE, false))
		{
			MeasureDistance(param1);
		}
		else if (StrEqual(info, ITEM_INFO_GET_BLOCK_DISTANCE, false))
		{
			if (!MeasureBlock(param1))
			{
				DisplayMeasureMenu(param1, false);
			}
		}
		
		DisplayMeasureMenu(param1, false);
	}
	else if (action == MenuAction_Cancel)
	{
		MeasureResetPos(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}



// =====[ PRIVATE ]=====

static void MeasureMenuAddItems(int client, Menu menu)
{
	char display[32];
	
	FormatEx(display, sizeof(display), "%T", "Measure Menu - Point A", client);
	menu.AddItem(ITEM_INFO_POINT_A, display);
	FormatEx(display, sizeof(display), "%T", "Measure Menu - Point B", client);
	menu.AddItem(ITEM_INFO_POINT_B, display);
	FormatEx(display, sizeof(display), "%T\n ", "Measure Menu - Get Distance", client);
	menu.AddItem(ITEM_INFO_GET_DISTANCE, display);
	FormatEx(display, sizeof(display), "%T", "Measure Menu - Get Block Distance", client);
	menu.AddItem(ITEM_INFO_GET_BLOCK_DISTANCE, display);
}

