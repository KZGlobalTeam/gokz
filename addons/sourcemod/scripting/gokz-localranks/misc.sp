/*
	Miscellaneous
	
	Miscellaneous functions.
*/



void CompletionMVPStarsUpdate(int client)
{
	DB_GetCompletion(client, GetSteamAccountID(client), GOKZ_GetDefaultMode(), false);
}

void CompletionMVPStarsUpdateAll()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			CompletionMVPStarsUpdate(client);
		}
	}
}



// =========================  ANNOUNCEMENTS  ========================= //

void OnMapStart_Announcements()
{
	if (!LoadSounds())
	{
		SetFailState("Invalid or missing %s", SOUNDS_CFG_PATH);
	}
}

static bool LoadSounds()
{
	KeyValues kv = new KeyValues("sounds");
	if (!kv.ImportFromFile(SOUNDS_CFG_PATH))
	{
		return false;
	}
	
	char downloadPath[256];
	
	kv.GetString("beatrecord", gC_BeatRecordSound, sizeof(gC_BeatRecordSound));
	FormatEx(downloadPath, sizeof(downloadPath), "sound/%s", gC_BeatRecordSound);
	AddFileToDownloadsTable(downloadPath);
	PrecacheSoundAny(gC_BeatRecordSound);
	
	kv.Close();
	return true;
}

static void PlayBeatRecordSound()
{
	EmitSoundToAllAny(gC_BeatRecordSound);
}

void AnnounceNewTime(
	int client, 
	int course, 
	int mode, 
	float runTime, 
	int teleportsUsed, 
	bool firstTime, 
	float pbDiff, 
	int rank, 
	int maxRank, 
	bool firstTimePro, 
	float pbDiffPro, 
	int rankPro, 
	int maxRankPro)
{
	// Main Course
	if (course == 0)
	{
		// Main Course PRO Times
		if (teleportsUsed == 0)
		{
			if (firstTimePro)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Time - First Time (PRO)", 
					client, GOKZ_FormatTime(runTime), rankPro, maxRankPro, gC_ModeNamesShort[mode]);
			}
			else if (pbDiffPro < 0)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Time - Beat PB (PRO)", 
					client, GOKZ_FormatTime(runTime), GOKZ_FormatTime(FloatAbs(pbDiffPro)), rankPro, maxRankPro, gC_ModeNamesShort[mode]);
			}
			else
			{
				GOKZ_PrintToChatAll(true, "%t", "New Time - Miss PB (PRO)", 
					client, GOKZ_FormatTime(runTime), GOKZ_FormatTime(pbDiffPro), rankPro, maxRankPro, gC_ModeNamesShort[mode]);
			}
		}
		// Main Course NUB Times
		else
		{
			if (firstTime)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Time - First Time", 
					client, GOKZ_FormatTime(runTime), rank, maxRank, gC_ModeNamesShort[mode]);
			}
			else if (pbDiff < 0)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Time - Beat PB", 
					client, GOKZ_FormatTime(runTime), GOKZ_FormatTime(FloatAbs(pbDiff)), rank, maxRank, gC_ModeNamesShort[mode]);
			}
			else
			{
				GOKZ_PrintToChatAll(true, "%t", "New Time - Miss PB", 
					client, GOKZ_FormatTime(runTime), GOKZ_FormatTime(pbDiff), rank, maxRank, gC_ModeNamesShort[mode]);
			}
		}
	}
	// Bonus Course
	else
	{
		// Bonus Course PRO Times
		if (teleportsUsed == 0)
		{
			if (firstTimePro)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Time - First Time (PRO)", 
					client, course, GOKZ_FormatTime(runTime), rankPro, maxRankPro, gC_ModeNamesShort[mode]);
			}
			else if (pbDiffPro < 0)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Time - Beat PB (PRO)", 
					client, course, GOKZ_FormatTime(runTime), GOKZ_FormatTime(FloatAbs(pbDiffPro)), rankPro, maxRankPro, gC_ModeNamesShort[mode]);
			}
			else
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Time - Miss PB (PRO)", 
					client, course, GOKZ_FormatTime(runTime), GOKZ_FormatTime(pbDiffPro), rankPro, maxRankPro, gC_ModeNamesShort[mode]);
			}
		}
		// Bonus Course NUB Times
		else
		{
			if (firstTime)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Time - First Time", 
					client, course, GOKZ_FormatTime(runTime), rank, maxRank, gC_ModeNamesShort[mode]);
			}
			else if (pbDiff < 0)
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Time - Beat PB", 
					client, course, GOKZ_FormatTime(runTime), GOKZ_FormatTime(FloatAbs(pbDiff)), rank, maxRank, gC_ModeNamesShort[mode]);
			}
			else
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Time - Miss PB", 
					client, course, GOKZ_FormatTime(runTime), GOKZ_FormatTime(pbDiff), rank, maxRank, gC_ModeNamesShort[mode]);
			}
		}
	}
}

void AnnounceNewRecord(int client, int course, int mode, KZRecordType recordType)
{
	if (course == 0)
	{
		switch (recordType)
		{
			case KZRecordType_Nub:
			{
				GOKZ_PrintToChatAll(true, "%t", "New Record (NUB)", client, gC_ModeNamesShort[mode]);
			}
			case KZRecordType_Pro:
			{
				GOKZ_PrintToChatAll(true, "%t", "New Record (PRO)", client, gC_ModeNamesShort[mode]);
			}
			case KZRecordType_NubAndPro:
			{
				GOKZ_PrintToChatAll(true, "%t", "New Record (NUB and PRO)", client, gC_ModeNamesShort[mode]);
			}
		}
	}
	else
	{
		switch (recordType)
		{
			case KZRecordType_Nub:
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Record (NUB)", client, course, gC_ModeNamesShort[mode]);
			}
			case KZRecordType_Pro:
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Record (PRO)", client, course, gC_ModeNamesShort[mode]);
			}
			case KZRecordType_NubAndPro:
			{
				GOKZ_PrintToChatAll(true, "%t", "New Bonus Record (NUB and PRO)", client, course, course, gC_ModeNamesShort[mode]);
			}
		}
	}
	
	PlayBeatRecordSound(); // Play sound!
} 