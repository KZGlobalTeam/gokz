void RegisterCommands()
{
	RegConsoleCmd("sm_menu", CommandMenu, "[KZ] Toggle the simple teleport menu.");
	RegConsoleCmd("sm_cpmenu", CommandMenu, "[KZ] Toggle the simple teleport menu.");
	RegConsoleCmd("sm_adv", CommandToggleAdvancedMenu, "[KZ] Toggle the advanced teleport menu.");
	RegConsoleCmd("sm_panel", CommandToggleInfoPanel, "[KZ] Toggle visibility of the centre information panel.");
	RegConsoleCmd("sm_timerstyle", CommandToggleTimerStyle, "[KZ] Toggle the style of the timer text.");
	RegConsoleCmd("sm_timertype", CommandToggleTimerType, "[KZ] Toggle visibility of your time type.");
	RegConsoleCmd("sm_speed", CommandToggleSpeed, "[KZ] Toggle visibility of your speed and jump pre-speed.");
	RegConsoleCmd("sm_hideweapon", CommandToggleShowWeapon, "[KZ] Toggle visibility of your weapon.");
}

public Action CommandMenu(int client, int args)
{
	if (GOKZ_HUD_GetOption(client, HUDOption_TPMenu) != TPMenu_Disabled)
	{
		GOKZ_HUD_SetOption(client, HUDOption_TPMenu, TPMenu_Disabled);
	}
	else
	{
		GOKZ_HUD_SetOption(client, HUDOption_TPMenu, TPMenu_Simple);
	}
	return Plugin_Handled;
}

public Action CommandToggleAdvancedMenu(int client, int args)
{
	if (GOKZ_HUD_GetOption(client, HUDOption_TPMenu) != TPMenu_Advanced)
	{
		GOKZ_HUD_SetOption(client, HUDOption_TPMenu, TPMenu_Advanced);
	}
	else
	{
		GOKZ_HUD_SetOption(client, HUDOption_TPMenu, TPMenu_Simple);
	}
	return Plugin_Handled;
}

public Action CommandToggleInfoPanel(int client, int args)
{
	if (GOKZ_HUD_GetOption(client, HUDOption_InfoPanel) == InfoPanel_Disabled)
	{
		GOKZ_HUD_SetOption(client, HUDOption_InfoPanel, InfoPanel_Enabled);
	}
	else
	{
		GOKZ_HUD_SetOption(client, HUDOption_InfoPanel, InfoPanel_Disabled);
	}
	return Plugin_Handled;
}

public Action CommandToggleTimerStyle(int client, int args)
{
	if (GOKZ_HUD_GetOption(client, HUDOption_TimerStyle) == TimerStyle_Standard)
	{
		GOKZ_HUD_SetOption(client, HUDOption_TimerStyle, TimerStyle_Precise);
	}
	else
	{
		GOKZ_HUD_SetOption(client, HUDOption_TimerStyle, TimerStyle_Standard);
	}
	return Plugin_Handled;
}

public Action CommandToggleTimerType(int client, int args)
{
	if (GOKZ_HUD_GetOption(client, HUDOption_TimerType) == TimerType_Disabled)
	{
		GOKZ_HUD_SetOption(client, HUDOption_TimerType, TimerType_Enabled);
	}
	else
	{
		GOKZ_HUD_SetOption(client, HUDOption_TimerType, TimerType_Disabled);
	}
	return Plugin_Handled;
}

public Action CommandToggleSpeed(int client, int args)
{
	int speedText = GOKZ_HUD_GetOption(client, HUDOption_SpeedText);
	int infoPanel = GOKZ_HUD_GetOption(client, HUDOption_InfoPanel);
	
	if (speedText == SpeedText_Disabled)
	{
		if (infoPanel == InfoPanel_Enabled)
		{
			GOKZ_HUD_SetOption(client, HUDOption_SpeedText, SpeedText_InfoPanel);
		}
		else
		{
			GOKZ_HUD_SetOption(client, HUDOption_SpeedText, SpeedText_Bottom);
		}
	}
	else if (infoPanel == InfoPanel_Disabled && speedText == SpeedText_InfoPanel)
	{
		GOKZ_HUD_SetOption(client, HUDOption_SpeedText, SpeedText_Bottom);
	}
	else
	{
		GOKZ_HUD_SetOption(client, HUDOption_SpeedText, SpeedText_Disabled);
	}
	return Plugin_Handled;
}

public Action CommandToggleShowWeapon(int client, int args)
{
	if (GOKZ_HUD_GetOption(client, HUDOption_ShowWeapon) == ShowWeapon_Disabled)
	{
		GOKZ_HUD_SetOption(client, HUDOption_ShowWeapon, ShowWeapon_Enabled);
	}
	else
	{
		GOKZ_HUD_SetOption(client, HUDOption_ShowWeapon, ShowWeapon_Disabled);
	}
	return Plugin_Handled;
} 