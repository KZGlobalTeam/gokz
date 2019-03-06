void RegisterCommands()
{
	RegConsoleCmd("sm_measure", CommandMeasureMenu, "[KZ] Open the measurement menu.");
}

public Action CommandMeasureMenu(int client, int args)
{
	DisplayMeasureMenu(client);
	return Plugin_Handled;
} 