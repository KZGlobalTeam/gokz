/*
	Particle Auto-Precacher
	
	Precaches particle systems referenced in the per-map manifest file
	(maps/<mapname>_particles.txt), as the engine no longer does this automatically in CS:GO.
	
	Based on CSGO-Particle-AutoPrecacher by Copypaste Slim and zer0.k.
	https://bitbucket.org/zer0k_z/csgo-particle-auto-precacher
*/

#define PARTICLE_MANIFEST_FOLDER     "maps/"
#define PARTICLE_MANIFEST_EXTENSION  "_particles.txt"



// =====[ EVENTS ]=====

void OnMapStart_PrecacheParticles()
{
	char map[PLATFORM_MAX_PATH];
	char mapDisplayName[PLATFORM_MAX_PATH];
	char manifestFullPath[PLATFORM_MAX_PATH];
	
	GetCurrentMap(map, sizeof(map));
	// Strip workshop path (e.g. "workshop/123/kz_foo" -> "kz_foo")
	GetMapDisplayName(map, mapDisplayName, sizeof(mapDisplayName));
	
	FormatEx(manifestFullPath, sizeof(manifestFullPath), "%s%s%s",
		PARTICLE_MANIFEST_FOLDER, mapDisplayName, PARTICLE_MANIFEST_EXTENSION);
	
	if (!FileExists(manifestFullPath, true, NULL_STRING))
	{
		return;
	}
	
	ProcessParticleManifest(manifestFullPath);
}



// =====[ PRIVATE ]=====

static void ProcessParticleManifest(const char[] path)
{
	KeyValues kv = new KeyValues("particles_manifest");
	if (!kv.ImportFromFile(path))
	{
		delete kv;
		return;
	}
	
	if (!kv.JumpToKey("file", false))
	{
		delete kv;
		return;
	}
	
	char buffer[PLATFORM_MAX_PATH];
	do
	{
		kv.GetString(NULL_STRING, buffer, sizeof(buffer), NULL_STRING);
		// Skip leading '!' which marks the file as preload-only in the manifest
		int offset = (buffer[0] == '!') ? 1 : 0;
		if (buffer[offset] != '\0')
		{
			PrecacheGeneric(buffer[offset], true);
		}
	} while (kv.GotoNextKey(false));
	
	delete kv;
}
