/*
	Miscellaneous
	
	Miscellaneous functions a features.
*/



bool GlobalsEnabled(int mode)
{
	return gB_APIKeyCheck && gCV_gokz_settings_enforcer.BoolValue && MapCheck() && gB_ModeCheck[mode];
}

bool MapCheck()
{
	return GlobalAPI_GetMapGlobalStatus()
	 && GlobalAPI_GetMapID() > 0
	 && GlobalAPI_GetMapFilesize() == FileSize(gC_CurrentMapPath);
}

void PrintGlobalCheck(int client)
{
	GOKZ_PrintToChat(client, true, "%t", "Global Check Header");
	GOKZ_PrintToChat(client, false, "  %t", "Global Check", 
		gB_APIKeyCheck ? "{green}✓" : "{darkred}X", 
		gCV_gokz_settings_enforcer.BoolValue ? "{green}✓" : "{darkred}X", 
		MapCheck() ? "{green}✓" : "{darkred}X");
	
	char modeCheck[256];
	FormatEx(modeCheck, sizeof(modeCheck), "{purple}%s %s", gC_ModeNames[0], gB_ModeCheck[0] ? "{green}✓" : "{darkred}X");
	for (int i = 1; i < MODE_COUNT; i++)
	{
		FormatEx(modeCheck, sizeof(modeCheck), "%s {grey}| {purple}%s %s", modeCheck, gC_ModeNames[i], gB_ModeCheck[i] ? "{green}✓" : "{darkred}X");
	}
	GOKZ_PrintToChat(client, false, "  %s", modeCheck);
}

void InvalidateRun(int client)
{
	gB_InValidRun[client] = false;
}

void AnnounceNewTopTime(int client, int course, int mode, int timeType, int rank, int rankOverall)
{
	bool newRecord = false;
	
	if (timeType == TimeType_Nub && rankOverall != 0)
	{
		if (rankOverall == 1)
		{
			if (course == 0)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Global Record (NUB)", client, gC_ModeNamesShort[mode]);
			}
			else
			{
				GOKZ_PrintToChatAll(true, "%t", "New Global Bonus Record (NUB)", client, course, gC_ModeNamesShort[mode]);
			}
			newRecord = true;
		}
		else
		{
			if (course == 0)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Global Top Time (NUB)", client, rankOverall, gC_ModeNamesShort[mode]);
			}
			else
			{
				GOKZ_PrintToChatAll(true, "%t", "New Global Top Bonus Time (NUB)", client, rankOverall, course, gC_ModeNamesShort[mode]);
			}
		}
	}
	else if (timeType == TimeType_Pro)
	{
		if (rankOverall != 0)
		{
			if (rankOverall == 1)
			{
				if (course == 0)
				{
					GOKZ_PrintToChatAll(true, "%t", "New Global Record (NUB)", client, gC_ModeNamesShort[mode]);
				}
				else
				{
					GOKZ_PrintToChatAll(true, "%t", "New Global Bonus Record (NUB)", client, course, gC_ModeNamesShort[mode]);
				}
				newRecord = true;
			}
			else
			{
				if (course == 0)
				{
					GOKZ_PrintToChatAll(true, "%t", "New Global Top Time (NUB)", client, rankOverall, gC_ModeNamesShort[mode]);
				}
				else
				{
					GOKZ_PrintToChatAll(true, "%t", "New Global Top Bonus Time (NUB)", client, rankOverall, course, gC_ModeNamesShort[mode]);
				}
			}
		}
		
		if (rank == 1)
		{
			if (course == 0)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Global Record (PRO)", client, gC_ModeNamesShort[mode]);
			}
			else
			{
				GOKZ_PrintToChatAll(true, "%t", "New Global Bonus Record (PRO)", client, course, gC_ModeNamesShort[mode]);
			}
			newRecord = true;
		}
		else
		{
			if (course == 0)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Global Top Time (PRO)", client, rank, gC_ModeNamesShort[mode]);
			}
			else
			{
				GOKZ_PrintToChatAll(true, "%t", "New Global Top Bonus Time (PRO)", client, rank, course, gC_ModeNamesShort[mode]);
			}
		}
	}
	
	if (newRecord)
	{
		PlayBeatRecordSound();
	}
}

void PlayBeatRecordSound()
{
	EmitSoundToAllAny(RECORD_SOUND_PATH);
} 