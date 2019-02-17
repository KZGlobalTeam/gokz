/*
	Hides weapon view model.
*/



// =====[ EVENTS ]=====

void OnPlayerSpawn_HideWeapon(int client)
{
	UpdateHideWeapon(client);
}

void OnOptionChanged_HideWeapon(int client, HUDOption option)
{
	if (option == HUDOption_ShowWeapon)
	{
		UpdateHideWeapon(client);
	}
}



// =====[ PRIVATE ]=====

static void UpdateHideWeapon(int client)
{
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 
		GOKZ_HUD_GetOption(client, HUDOption_ShowWeapon) == ShowWeapon_Enabled);
} 