/*
	Pistol Menu
	
	Lets players pick their pistol.
*/



static char pistolNames[PISTOL_COUNT][] = 
{
	"P2000 / USP-S", 
	"Glock-18", 
	"P250", 
	"Dual Berettas", 
	"Deagle", 
	"CZ75-Auto", 
	"Five-SeveN", 
	"Tec-9"
};



// =========================  PUBLIC  ========================= //

void DisplayPistolMenu(int client, int atItem = 0)
{
	Menu menu = new Menu(MenuHandler_Pistol);
	menu.SetTitle("%T", "Pistol Menu - Title", client);
	PistolMenuAddItems(client, menu);
	menu.DisplayAt(client, atItem, MENU_TIME_FOREVER);
}



// =========================  HANDLER  ========================= //

public int MenuHandler_Pistol(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		SetOption(param1, Option_Pistol, param2);
		UpdatePistol(param1);
		DisplayPistolMenu(param1, param2 / 6 * 6); // Re-display menu at same spot
	}
	else if (action == MenuAction_Cancel && GetCameFromOptionsMenu(param1))
	{
		DisplayOptionsMenu(param1, 6);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}



// =========================  PRIVATE  ========================= //

static void PistolMenuAddItems(int client, Menu menu)
{
	int selectedPistol = GOKZ_GetOption(client, Option_Pistol);
	char display[32];
	
	for (int pistol = 0; pistol < PISTOL_COUNT; pistol++)
	{
		FormatEx(display, sizeof(display), "%s", pistolNames[pistol]);
		// Add asterisk to selected pistol
		if (pistol == selectedPistol)
		{
			Format(display, sizeof(display), "%s*", display);
		}
		
		menu.AddItem("", display, ITEMDRAW_DEFAULT);
	}
} 