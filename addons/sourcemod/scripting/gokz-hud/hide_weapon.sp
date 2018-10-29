/*
	Hide Weapon
	
	Hides weapon view model.
*/



// =========================  PUBLIC  ========================= //

void UpdateHideWeapon(int client)
{
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 
		GOKZ_HUD_GetOption(client, HUDOption_ShowWeapon) == ShowWeapon_Enabled);
}



// =========================  LISTENERS  ========================= //

void OnOptionChanged_HideWeapon(int client, HUDOption option)
{
	if (option == HUDOption_ShowWeapon)
	{
		UpdateHideWeapon(client);
	}
} 