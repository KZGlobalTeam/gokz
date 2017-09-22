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





/*===============================  Static Functions  ===============================*/

static void PlayerTopMenuCreate(int client)
{
	
}

static void PlayerTopSubMenuCreate(int client)
{

}

