// ================== DOUBLE INCLUDE ========================= //

#if defined _GlobalAPI_Stocks_included_
#endinput
#endif
#define _GlobalAPI_Stocks_included_

// =========================================================== //

/**
 * Gets plugin's display name from its handle
 *
 * @param plugin				Plugin handle to retrieve name from
 * @return						String representation of the plugin name
 */
stock void GetPluginDisplayName(Handle plugin, char[] pluginName, int maxlength)
{
	if (!GetPluginInfo(plugin, PlInfo_Name, pluginName, maxlength))
	{
		strcopy(pluginName, maxlength, "Unknown");
	}
}

/**
 * Gets plugin's version from its handle
 *
 * @param plugin				Plugin handle to retrieve version from
 * @return						String representation of the plugin version
 */
stock void GetPluginVersion(Handle plugin, char[] pluginVersion, int maxlength)
{
	if (!GetPluginInfo(plugin, PlInfo_Version, pluginVersion, maxlength))
	{
		strcopy(pluginVersion, maxlength, "Unknown");
	}
}

/**
 * Gets current map's "display name"
 *
 * @param buffer				Buffer to store the result in
 * @param maxlength				Max length of the buffer
 * @noreturn
 */
stock void GetMapDisplay(char[] buffer, int maxlength)
{
	char map[PLATFORM_MAX_PATH];
	GetCurrentMap(map, sizeof(map));
	GetMapDisplayName(map, map, sizeof(map));
	
	FormatEx(buffer, maxlength, map);
}

/**
 * Gets current map's full (game dir) path
 *
 * @param buffer				Buffer to store result in
 * @param maxlength				Max length of the buffer
 * @noreturn
 */
stock void GetMapFullPath(char[] buffer, int maxlength)
{
	char mapPath[PLATFORM_MAX_PATH];
	GetCurrentMap(mapPath, sizeof(mapPath));
	
	Format(buffer, maxlength, "maps/%s.bsp", mapPath);
}
