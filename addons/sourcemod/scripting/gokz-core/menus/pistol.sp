/*
	Pistol Menu
	
	Lets players pick their pistol.
*/



static Menu pistolMenu[MAXPLAYERS + 1];

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

void CreateMenusPistol()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		pistolMenu[client] = new Menu(MenuHandler_Pistol);
	}
}

void DisplayPistolMenu(int client, int atItem = 0)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	PistolMenuUpdate(client, pistolMenu[client]);
	pistolMenu[client].DisplayAt(client, atItem, MENU_TIME_FOREVER);
}



// =========================  HANDLER  ========================= //

public int MenuHandler_Pistol(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		SetOption(param1, Option_Pistol, param2);
		UpdatePistol(param1);
		DisplayPistolMenu(param1, param2 / 6 * 6);
	}
	else if (action == MenuAction_Cancel && GetCameFromOptionsMenu(param1))
	{
		DisplayOptionsMenu(param1, 6);
	}
}



// =========================  PRIVATE  ========================= //

static void PistolMenuUpdate(int client, Menu menu)
{
	menu.SetTitle("%T", "Pistol Menu - Title", client);
	menu.RemoveAllItems();
	for (int pistol = 0; pistol < PISTOL_COUNT; pistol++)
	{
		menu.AddItem("", pistolNames[pistol]);
	}
} 