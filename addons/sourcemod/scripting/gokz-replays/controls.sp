/*
	Lets player control the replay bot.

	Each replay bot has at most one controller, who is shown the control menu
	while watching it. Control only changes in the event handlers and
	commands, never while drawing the menu.
*/

#define ITEM_INFO_PAUSE "pause"
#define ITEM_INFO_SKIP "skip"
#define ITEM_INFO_REWIND "rewind"
#define ITEM_INFO_FREECAM "freecam"
#define ITEM_INFO_BACK_TO_BOT "backtobot"

static int controllingUserId[RP_MAX_BOTS];
static int botTeleports[RP_MAX_BOTS];
static bool menuDrawnInFreecam[MAXPLAYERS + 1];



// =====[ EVENTS ]=====

void OnPlayerRunCmdPost_ReplayControls(int client, int cmdnum)
{
	// Let the HUD plugin takes care of this if possible.
	if (cmdnum % 6 == 3 && !gB_GOKZHUD)
	{
		UpdateReplayControlMenu(client);
	}
}

void OnBotJoined_ReplayControls(int requester, int bot)
{
	if (ShowControlsEnabled(requester))
	{
		controllingUserId[bot] = GetClientUserId(requester);
	}
}

void OnBotDisconnect_ReplayControls(int bot)
{
	// A requester with Show Controls off doesn't overwrite the slot when their
	// bot joins, so it would otherwise still name this bot's controller.
	ReleaseReplayBot(bot);
}

void OnOptionChanged_ReplayControls(int client, const char[] option, any newValue)
{
	if (!StrEqual(option, gC_HUDOptionNames[HUDOption_ShowControls]) || newValue != ReplayControls_Disabled)
	{
		return;
	}
	
	// A hidden menu would leave the player holding bots they can't use, locking
	// out everyone else, so turning the option off gives them up.
	for (int bot = 0; bot < RP_MAX_BOTS; bot++)
	{
		if (GetReplayBotController(bot) == client)
		{
			ReleaseReplayBot(bot);
		}
	}
}



// =====[ PUBLIC ]=====

// Returns the client controlling the replay bot, or 0.
int GetReplayBotController(int bot)
{
	return GetClientOfUserId(controllingUserId[bot]);
}

// Whether the bot's controller is currently watching it.
static bool IsReplayBotControlled(int bot)
{
	int controller = GetReplayBotController(bot);
	return controller != 0 && GetWatchedBot(controller) == bot;
}

bool UpdateReplayControlMenu(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client))
	{
		return false;
	}
	
	int bot = GetWatchedBot(client);
	if (bot == -1 || GetReplayBotController(bot) != client)
	{
		return false;
	}
	
	// We have to update this often if bot uses teleports.
	if (GetClientMenu(client) == MenuSource_None || 
		GOKZ_HUD_GetMenuShowing(client) && GetClientAvgLoss(client, NetFlow_Both) > EPSILON || 
		GOKZ_HUD_GetMenuShowing(client) && GOKZ_HUD_GetOption(client, HUDOption_TimerText) == TimerText_TPMenu ||
		GOKZ_HUD_GetMenuShowing(client) && PlaybackGetTeleports(bot) > 0 ||
		// The last item depends on freecam, and nothing else redraws the menu when
		// only that changes, such as entering freecam with the spectator mode key.
		GOKZ_HUD_GetMenuShowing(client) && menuDrawnInFreecam[client] != (GetObserverMode(client) == ObsMode_Roaming))
	{
		botTeleports[bot] = PlaybackGetTeleports(bot);
		ShowReplayControlMenu(client, bot);
	}
	return true;
}

void ShowReplayControlMenu(int client, int bot)
{
	char text[256];
	
	Menu menu = new Menu(MenuHandler_ReplayControls);
	menu.OptionFlags = MENUFLAG_NO_SOUND;
	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = true;
	if (gB_GOKZHUD)
	{
		if (GOKZ_HUD_GetOption(client, HUDOption_ShowSpectators) != ShowSpecs_Disabled &&
			GOKZ_HUD_GetOption(client, HUDOption_SpecListPosition) == SpecListPosition_TPMenu)
		{
			HUDInfo info;
			GetPlaybackState(GetClientFromBot(bot), info);
			GOKZ_HUD_GetMenuSpectatorText(client, info, text, sizeof(text));
		}
		if (GOKZ_HUD_GetOption(client, HUDOption_TimerText) == TimerText_TPMenu)
		{
			Format(text, sizeof(text), "%s\n%T - %s", text, "Replay Controls - Title", client,
				GOKZ_FormatTime(GetPlaybackTime(bot), GOKZ_HUD_GetOption(client, HUDOption_TimerStyle) == TimerStyle_Precise));
		}
		else
		{
			Format(text, sizeof(text), "%s%T", text, "Replay Controls - Title", client);
		}
	}
	else
	{
		Format(text, sizeof(text), "%s%T", text, "Replay Controls - Title", client);
	}


	if (botTeleports[bot] > 0)
	{
		Format(text, sizeof(text), "%s\n%T", text, "Replay Controls - Teleports", client, botTeleports[bot]);
	}

	menu.SetTitle(text);
	
	if (PlaybackPaused(bot))
	{
		FormatEx(text, sizeof(text), "%T", "Replay Controls - Resume", client);
		menu.AddItem(ITEM_INFO_PAUSE, text);
	}
	else
	{
		FormatEx(text, sizeof(text), "%T", "Replay Controls - Pause", client);
		menu.AddItem(ITEM_INFO_PAUSE, text);
	}
	
	FormatEx(text, sizeof(text), "%T", "Replay Controls - Skip", client);
	menu.AddItem(ITEM_INFO_SKIP, text);
	
	FormatEx(text, sizeof(text), "%T\n ", "Replay Controls - Rewind", client);
	menu.AddItem(ITEM_INFO_REWIND, text);
	
	// Leaving freecam with the spectator mode key doesn't necessarily land on the
	// bot, so freecam offers a way straight back instead.
	menuDrawnInFreecam[client] = GetObserverMode(client) == ObsMode_Roaming;
	if (menuDrawnInFreecam[client])
	{
		FormatEx(text, sizeof(text), "%T", "Replay Controls - Back To Bot", client);
		menu.AddItem(ITEM_INFO_BACK_TO_BOT, text);
	}
	else
	{
		FormatEx(text, sizeof(text), "%T", "Replay Controls - Freecam", client);
		menu.AddItem(ITEM_INFO_FREECAM, text);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);

	if (gB_GOKZHUD)
	{
		GOKZ_HUD_SetMenuShowing(client, true);
	}
}

void ToggleReplayControls(int client)
{
	int bot = GetWatchedBot(client);
	if (bot == -1)
	{
		GOKZ_PrintToChat(client, true, "%t", "Replay Controls - Not Spectating Bot");
		GOKZ_PlayErrorSound(client);
		return;
	}
	
	if (GetReplayBotController(bot) == client)
	{
		ReleaseReplayBot(bot);
		return;
	}
	
	// A controller who looked away shouldn't lock everyone out, so only one who's
	// watching blocks taking the bot.
	if (IsReplayBotControlled(bot))
	{
		GOKZ_PrintToChat(client, true, "%t", "Replay Controls - Bot Controlled");
		GOKZ_PlayErrorSound(client);
		return;
	}
	
	// Asking for controls means wanting them, so this turns the option back on
	// like other gokz toggle commands do, rather than overriding it.
	if (!ShowControlsEnabled(client))
	{
		GOKZ_HUD_SetOption(client, HUDOption_ShowControls, ReplayControls_Enabled);
	}
	
	controllingUserId[bot] = GetClientUserId(client);
	botTeleports[bot] = PlaybackGetTeleports(bot);
	ShowReplayControlMenu(client, bot);
}

int MenuHandler_ReplayControls(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!IsValidClient(param1))
			{
				return 0;
			}

			int bot = GetWatchedBot(param1);
			if (bot == -1 || GetReplayBotController(bot) != param1)
			{
				return 0;
			}
			
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, ITEM_INFO_PAUSE, false))
			{
				PlaybackTogglePause(bot);
			}
			else if (StrEqual(info, ITEM_INFO_SKIP, false))
			{
				PlaybackSkipForward(bot);
			}
			else if (StrEqual(info, ITEM_INFO_REWIND, false))
			{
				PlaybackSkipBack(bot);
			}
			else if (StrEqual(info, ITEM_INFO_FREECAM, false))
			{
				SetEntProp(param1, Prop_Send, "m_iObserverMode", 6);
			}
			else if (StrEqual(info, ITEM_INFO_BACK_TO_BOT, false))
			{
				SpectateBot(param1, bot);
			}
			GOKZ_HUD_SetMenuShowing(param1, false);
		}
		case MenuAction_Cancel:
		{
			GOKZ_HUD_SetMenuShowing(param1, false);
			if (param2 == MenuCancel_Exit)
			{
				// The menu is already closing, so release without closing it again.
				int bot = GetWatchedBot(param1);
				if (bot != -1 && GetReplayBotController(bot) == param1)
				{
					controllingUserId[bot] = 0;
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}



// =====[ PRIVATE ]=====

static void ReleaseReplayBot(int bot)
{
	int controller = GetReplayBotController(bot);
	controllingUserId[bot] = 0;
	if (controller != 0 && GetWatchedBot(controller) == bot)
	{
		ClearReplayControlMenu(controller);
	}
}

// Cancelling a menu only forgets it on the server, and the client keeps showing
// it until something replaces it, so it's replaced with an empty panel instead.
static void ClearReplayControlMenu(int client)
{
	Panel panel = new Panel();
	panel.Send(client, PanelHandler_Empty, 1);
	delete panel;
}

static int PanelHandler_Empty(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

// Without the HUD plugin the option doesn't exist, so controls are always allowed.
static bool ShowControlsEnabled(int client)
{
	return !gB_GOKZHUD || GOKZ_HUD_GetOption(client, HUDOption_ShowControls) != ReplayControls_Disabled;
}
