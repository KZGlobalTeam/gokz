static GlobalForward H_OnNewTopTime;



// =====[ FORWARDS ]=====

void CreateGlobalForwards()
{
	H_OnNewTopTime = new GlobalForward("GOKZ_GL_OnNewTopTime", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Float);
}

void Call_OnNewTopTime(int client, int course, int mode, int timeType, int rank, int rankOverall, float time)
{
	Call_StartForward(H_OnNewTopTime);
	Call_PushCell(client);
	Call_PushCell(course);
	Call_PushCell(mode);
	Call_PushCell(timeType);
	Call_PushCell(rank);
	Call_PushCell(rankOverall);
	Call_PushFloat(time);
	Call_Finish();
}



// =====[ NATIVES ]=====

void CreateNatives()
{
	CreateNative("GOKZ_GL_PrintRecords", Native_PrintRecords);
	CreateNative("GOKZ_GL_DisplayMapTopMenu", Native_DisplayMapTopMenu);
}

public int Native_PrintRecords(Handle plugin, int numParams)
{
	char map[33];
	GetNativeString(2, map, sizeof(map));
	
	if (StrEqual(map, ""))
	{
		PrintRecords(GetNativeCell(1), gC_CurrentMap, GetNativeCell(3), GetNativeCell(4));
	}
	else
	{
		PrintRecords(GetNativeCell(1), map, GetNativeCell(3), GetNativeCell(4));
	}
}

public int Native_DisplayMapTopMenu(Handle plugin, int numParams)
{
	char pluginName[32];
	GetPluginFilename(plugin, pluginName, sizeof(pluginName));
	bool localRanksCall = StrEqual(pluginName, "gokz-localranks.smx", false);
	
	char map[33];
	GetNativeString(2, map, sizeof(map));
	
	if (StrEqual(map, ""))
	{
		DisplayMapTopSubmenu(GetNativeCell(1), gC_CurrentMap, GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), localRanksCall);
	}
	else
	{
		DisplayMapTopSubmenu(GetNativeCell(1), map, GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), localRanksCall);
	}
} 