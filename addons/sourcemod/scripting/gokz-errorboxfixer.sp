#include <sourcemod>
#include <sdktools>

#include <gokz>

#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "GOKZ KZErrorBoxFixer",
	author = "1NutWunDeR",
	description = "Adds missing models for KZ maps",
	version = GOKZ_VERSION,
	url = GOKZ_SOURCE_URL
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-errorboxfixer.txt"

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
}

public void OnMapStart()
{
	AddFileToDownloadsTable("models/kzmod/buttons/stand_button.vtf");
	AddFileToDownloadsTable("models/kzmod/buttons/stand_button.vmt");
	AddFileToDownloadsTable("models/kzmod/buttons/stand_button_normal.vtf");
	AddFileToDownloadsTable("models/kzmod/buttons/standing_button.mdl");
	AddFileToDownloadsTable("models/kzmod/buttons/standing_button.dx90.vtx");
	AddFileToDownloadsTable("models/kzmod/buttons/standing_button.phy");
	AddFileToDownloadsTable("models/kzmod/buttons/standing_button.vvd");
	AddFileToDownloadsTable("models/kzmod/buttons/stone_button.mdl");
	AddFileToDownloadsTable("models/kzmod/buttons/stone_button.dx90.vtx");
	AddFileToDownloadsTable("models/kzmod/buttons/stone_button.phy");
	AddFileToDownloadsTable("models/kzmod/buttons/stone_button.vvd");
	AddFileToDownloadsTable("models/props_wasteland/pipecluster002a.mdl");
	AddFileToDownloadsTable("models/props_wasteland/pipecluster002a.dx90.vtx");
	AddFileToDownloadsTable("models/props_wasteland/pipecluster002a.phy");
	AddFileToDownloadsTable("models/props_wasteland/pipecluster002a.vvd");
	AddFileToDownloadsTable("materials/kzmod/starttimersign.vmt");
	AddFileToDownloadsTable("materials/kzmod/starttimersign.vtf");
	AddFileToDownloadsTable("materials/kzmod/stoptimersign.vmt");
	AddFileToDownloadsTable("materials/kzmod/stoptimersign.vtf");
	PrecacheModel("models/kzmod/buttons/stand_button.vmt", true);
	PrecacheModel("models/props_wasteland/pipecluster002a.mdl", true);
	PrecacheModel("models/kzmod/buttons/standing_button.mdl", true);
	PrecacheModel("models/kzmod/buttons/stone_button.mdl", true);
	PrecacheModel("materials/kzmod/starttimersign.vmt", true);
	PrecacheModel("materials/kzmod/stoptimersign.vmt", true);
}
