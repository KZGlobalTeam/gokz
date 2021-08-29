// ================== DOUBLE INCLUDE ========================= //

#if defined _GlobalAPI_Responses_included_
#endinput
#endif
#define _GlobalAPI_Responses_included_

// =========================================================== //

#include <json>
#include <GlobalAPI/iterable>

// =========================================================== //

methodmap APIAuth < JSON_Object
{
	public APIAuth(JSON_Object hAuth)
	{
		return view_as<APIAuth>(hAuth);
	}

	public bool GetType(char[] buffer, int maxlength)
	{
		return this.GetString("Type", buffer, maxlength);
	}

	property bool IsValid
	{
		public get() { return this.GetBool("IsValid"); }
	}

	property int Identity
	{
		public get() { return this.GetInt("Identity"); }
	}
}

// =========================================================== //

methodmap APIBan < JSON_Object
{
	public APIBan(JSON_Object hBan)
	{
		return view_as<APIBan>(hBan);
	}

	property int Id
	{
		public get() { return this.GetInt("id"); }
	}

	property int UpdatedById
	{
		public get() { return this.GetInt("updated_by_id"); }
	}

	public void GetStats(char[] buffer, int maxlength)
	{
		this.GetString("stats", buffer, maxlength);
	}

	public void GetBanType(char[] buffer, int maxlength)
	{
		this.GetString("ban_type", buffer, maxlength);
	}

	public void GetExpiresOn(char[] buffer, int maxlength)
	{
		this.GetString("expires_on", buffer, maxlength);
	}

	public void GetSteamId64(char[] buffer, int maxlength)
	{
		this.GetString("steamid64", buffer, maxlength);
	}

	public void GetPlayerName(char[] buffer, int maxlength)
	{
		this.GetString("player_name", buffer, maxlength);
	}

	public void GetNotes(char[] buffer, int maxlength)
	{
		this.GetString("notes", buffer, maxlength);
	}

	public void GetSteamId(char[] buffer, int maxlength)
	{
		this.GetString("steam_id", buffer, maxlength);
	}

	public void GetUpdatedOn(char[] buffer, int maxlength)
	{
		this.GetString("updated_on", buffer, maxlength);
	}

	property int ServerId
	{
		public get() { return this.GetInt("server_id"); }
	}

	public void GetCreatedOn(char[] buffer, int maxlength)
	{
		this.GetString("created_on", buffer, maxlength);
	}
}

// =========================================================== //

methodmap APIJumpstat < JSON_Object
{
	public APIJumpstat(JSON_Object hJump)
	{
		return view_as<APIJumpstat>(hJump);
	}

	property int Id
	{
		public get() { return this.GetInt("id"); }
	}

	property int ServerId
	{
		public get() { return this.GetInt("server_id"); }
	}

	public void GetSteamId64(char[] buffer, int maxlength)
	{
		this.GetString("steamid64", buffer, maxlength);
	}

	public void GetName(char[] buffer, int maxlength)
	{
		this.GetString("player_name", buffer, maxlength);
	}

	public void GetSteamId(char[] buffer, int maxlength)
	{
		this.GetString("steam_id", buffer, maxlength);
	}

	property int JumpType
	{
		public get() { return this.GetInt("jump_type"); }
	}

	property float Distance
	{
		public get() { return this.GetFloat("distance"); }
	}

	property int TickRate
	{
		public get() { return this.GetInt("tickrate"); }
	}

	property int MslCount
	{
		public get() { return this.GetInt("msl_count"); }
	}

	property int StrafeCount
	{
		public get() { return this.GetInt("strafe_count"); }
	}

	property bool IsCrouchBind
	{
		public get() { return this.GetBool("is_crouch_bind"); }
	}

	property bool IsForwardBind
	{
		public get() { return this.GetBool("is_forward_bind"); }
	}

	property bool IsCrouchBoost
	{
		public get() { return this.GetBool("is_crouch_boost"); }
	}

	property int UpdatedById
	{
		public get() { return this.GetInt("updated_by_id"); }
	}

	public void GetCreatedOn(char[] buffer, int maxlength)
	{
		this.GetString("created_on", buffer, maxlength);
	}

	public void GetUpdatedOn(char[] buffer, int maxlength)
	{
		this.GetString("updated_on", buffer, maxlength);
	}
}

// =========================================================== //

methodmap APIMap < JSON_Object
{
	public APIMap(JSON_Object hMap)
	{
		return view_as<APIMap>(hMap);
	}

	property int Id
	{
		public get() { return this.GetInt("id"); }
	}

	public void GetName(char[] buffer, int maxlength)
	{
		this.GetString("name", buffer, maxlength);
	}

	property int Filesize
	{
		public get() { return this.GetInt("filesize"); }
	}

	property bool IsValidated
	{
		public get() { return this.GetBool("validated"); }
	}

	property int Difficulty
	{
		public get() { return this.GetInt("difficulty"); }
	}

	public void GetCreatedOn(char[] buffer, int maxlength)
	{
		this.GetString("created_on", buffer, maxlength);
	}

	public void GetUpdatedOn(char[] buffer, int maxlength)
	{
		this.GetString("updated_on", buffer, maxlength);
	}

	public void GetApprovedBySteamId64(char[] buffer, int maxlength)
	{
		this.GetString("approved_by_steamid64", buffer, maxlength);
	}
}

// =========================================================== //

methodmap APIMode < JSON_Object
{
	public APIMode(JSON_Object hMode)
	{
		return view_as<APIMode>(hMode);
	}

	property int Id
	{
		public get() { return this.GetInt("id"); }
	}

	public void GetName(char[] buffer, int maxlength)
	{
		this.GetString("name", buffer, maxlength);
	}

	public void GetDescription(char[] buffer, int maxlength)
	{
		this.GetString("description", buffer, maxlength);
	}

	property int LatestVersion
	{
		public get() { return this.GetInt("latest_version"); }
	}

	public void GetLatestVersionDesc(char[] buffer, int maxlength)
	{
		this.GetString("latest_version_description", buffer, maxlength);
	}

	public void GetWebsite(char[] buffer, int maxlength)
	{
		this.GetString("website", buffer, maxlength);
	}

	public void GetRepository(char[] buffer, int maxlength)
	{
		this.GetString("repo", buffer, maxlength);
	}

	public void GetContactSteamId64(char[] buffer, int maxlength)
	{
		this.GetString("contact_steamid64", buffer, maxlength);
	}

	// TODO: Add supported_tickrates

	public void GetCreatedOn(char[] buffer, int maxlength)
	{
		this.GetString("created_on", buffer, maxlength);
	}

	public void GetUpdatedOn(char[] buffer, int maxlength)
	{
		this.GetString("updated_on", buffer, maxlength);
	}

	public void GetUpdatedById(char[] buffer, int maxlength)
	{
		this.GetString("updated_by_id", buffer, maxlength);
	}
}

// =========================================================== //

methodmap APIPlayerRank < JSON_Object
{
	public APIPlayerRank(JSON_Object hPlayerRank)
	{
		return view_as<APIPlayerRank>(hPlayerRank);
	}

	property int Points
	{
		public get() { return this.GetInt("points"); }
	}

	property float Average
	{
		public get() { return this.GetFloat("average"); }
	}

	property float Rating
	{
		public get() { return this.GetFloat("rating"); }
	}

	property int Finishes
	{
		public get() { return this.GetInt("finishes"); }
	}

	public void GetSteamId64(char[] buffer, int maxlength)
	{
		this.GetString("steamid64", buffer, maxlength);
	}

	public void GetSteamId(char[] buffer, int maxlength)
	{
		this.GetString("steamid", buffer, maxlength);
	}

	public void GetPlayerName(char[] buffer, int maxlength)
	{
		this.GetString("player_name", buffer, maxlength);
	}
}

// =========================================================== //

methodmap APIPlayer < JSON_Object
{
	public APIPlayer(JSON_Object hPlayer)
	{
		return view_as<APIPlayer>(hPlayer);
	}

	public void GetSteamId64(char[] buffer, int maxlength)
	{
		this.GetString("steamid64", buffer, maxlength);
	}

	public void GetSteamId(char[] buffer, int maxlength)
	{
		this.GetString("steam_id", buffer, maxlength);
	}

	property bool IsBanned
	{
		public get() { return this.GetBool("is_banned"); }
	}

	property int TotalRecords
	{
		public get() { return this.GetInt("total_records"); }
	}

	public void GetName(char[] buffer, int maxlength)
	{
		this.GetString("name", buffer, maxlength);
	}
}

// =========================================================== //

methodmap APIRecord < JSON_Object
{
	public APIRecord(JSON_Object hRecord)
	{
		return view_as<APIRecord>(hRecord);
	}

	property int Id
	{
		public get() { return this.GetInt("id"); }
	}

	public void GetSteamId64(char[] buffer, int maxlength)
	{
		this.GetString("steamid64", buffer, maxlength);
	}

	public void GetPlayerName(char[] buffer, int maxlength)
	{
		this.GetString("player_name", buffer, maxlength);
	}

	public void GetSteamId(char[] buffer, int maxlength)
	{
		this.GetString("steam_id", buffer, maxlength);
	}

	property int ServerId
	{
		public get() { return this.GetInt("server_id"); }
	}

	property int MapId
	{
		public get() { return this.GetInt("map_id"); }
	}

	property int Stage
	{
		public get() { return this.GetInt("stage"); }
	}

	public void GetMode(char[] buffer, int maxlength)
	{
		this.GetString("mode", buffer, maxlength);
	}

	property int TickRate
	{
		public get() { return this.GetInt("tickrate"); }
	}

	property float Time
	{
		public get() { return this.GetFloat("time"); }
	}

	property int Teleports
	{
		public get() { return this.GetInt("teleports"); }
	}

	public void GetCreatedOn(char[] buffer, int maxlength)
	{
		this.GetString("created_on", buffer, maxlength);
	}

	public void GetUpdatedOn(char[] buffer, int maxlength)
	{
		this.GetString("updated_on", buffer, maxlength);
	}

	property int UpdatedBy
	{
		public get() { return this.GetInt("updated_by"); }
	}

	public void GetServerName(char[] buffer, int maxlength)
	{
		this.GetString("server_name", buffer, maxlength);
	}

	public void GetMapName(char[] buffer, int maxlength)
	{
		this.GetString("map_name", buffer, maxlength);
	}
}

// =========================================================== //

methodmap APIServer < JSON_Object
{
	public APIServer(JSON_Object hServer)
	{
		return view_as<APIServer>(hServer);
	}

	property int Port
	{
		public get() { return this.GetInt("port"); }
	}

	public void GetIPAddress(char[] buffer, int maxlength)
	{
		this.GetString("ip", buffer, maxlength);
	}

	public void GetName(char[] buffer, int maxlength)
	{
		this.GetString("name", buffer, maxlength);
	}

	public void GetOwnerSteamId64(char[] buffer, int maxlength)
	{
		this.GetString("owner_steamid64", buffer, maxlength);
	}
}

// =========================================================== //

methodmap APIRecordFilter < JSON_Object
{
	public APIRecordFilter(JSON_Object hRecordFilter)
	{
		return view_as<APIRecordFilter>(hRecordFilter);
	}

	property int Id
	{
		public get() { return this.GetInt("id"); }
	}

	property int MapId
	{
		public get() { return this.GetInt("map_id"); }
	}

	property int Stage
	{
		public get() { return this.GetInt("stage"); }
	}

	property int ModeId
	{
		public get() { return this.GetInt("mode_id"); }
	}

	property int TickRate
	{
		public get() { return this.GetInt("tickrate"); }
	}

	property bool HasTeleports
	{
		public get() { return this.GetBool("has_teleports"); }
	}

	public void GetCreatedOn(char[] buffer, int maxlength)
	{
		this.GetString("created_on", buffer, maxlength);
	}

	public void GetUpdatedOn(char[] buffer, int maxlength)
	{
		this.GetString("updated_on", buffer, maxlength);
	}

	public void GetUpdatedById(char[] buffer, int maxlength)
	{
		this.GetString("updated_by_id", buffer, maxlength);
	}
}

// =========================================================== //
