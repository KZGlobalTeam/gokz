#if defined _memutils_included
#endinput
#endif
#define _memutils_included

#include "glib/assertutils"
#include "glib/addressutils"

/* Compile time settings for this include. Should be defined before including this file.
*  #define MEMUTILS_PLUGINENDCALL //This should be defined if main plugin has OnPluginEnd() forward used.
*/

#define MEM_LEN_SAFE_THRESHOLD 2000

//-==PatchHandling methodmap
static StringMap gPatchStack;

methodmap PatchHandler < AddressBase
{
	public PatchHandler(Address addr)
	{
		ASSERT(addr != Address_Null);
		
		if(!gPatchStack)
			gPatchStack = new StringMap();
		
		return view_as<PatchHandler>(addr);
	}
	
	property any Any
	{
		public get() { return view_as<any>(this); }
	}
	
	public void Save(int len)
	{
		ASSERT(gPatchStack);
		ASSERT(len > 0 && len < MEM_LEN_SAFE_THRESHOLD);
		
		len++;
		
		int[] arr = new int[len];
		arr[0] = len;
		
		for(int i = 0; i < len - 1; i++)
			arr[i + 1] = LoadFromAddress(this.Address + i, NumberType_Int8);
		
		char buff[32];
		IntToString(this.Any, buff, sizeof(buff));
		gPatchStack.SetArray(buff, arr, len);
	}
	
	public void PatchNSave(int len, char byte = 0x90)
	{
		ASSERT(gPatchStack);
		ASSERT(len > 0 && len < MEM_LEN_SAFE_THRESHOLD);
		
		len++;
		
		int[] arr = new int[len];
		arr[0] = len;
		
		for(int i = 0; i < len - 1; i++)
		{
			arr[i + 1] = LoadFromAddress(this.Address + i, NumberType_Int8);
			StoreToAddress(this.Address + i, byte, NumberType_Int8);
		}
		
		char buff[32];
		IntToString(this.Any, buff, sizeof(buff));
		gPatchStack.SetArray(buff, arr, len);
	}
	
	public void PatchNSaveSeq(const char[] data, int len)
	{
		ASSERT(gPatchStack);
		ASSERT(len > 0 && len < MEM_LEN_SAFE_THRESHOLD);
		
		len++;
		
		int[] arr = new int[len];
		arr[0] = len;
		
		for(int i = 0; i < len - 1; i++)
		{
			arr[i + 1] = LoadFromAddress(this.Address + i, NumberType_Int8);
			StoreToAddress(this.Address + i, data[i], NumberType_Int8);
		}
		
		char buff[32];
		IntToString(this.Any, buff, sizeof(buff));
		gPatchStack.SetArray(buff, arr, len);
	}
	
	public void Restore()
	{
		if(!gPatchStack)
			return;
		
		char buff[32];
		IntToString(this.Any, buff, sizeof(buff));
		
		int arrSize[1];
		if(!gPatchStack.GetArray(buff, arrSize, sizeof(arrSize)))
			return;
		
		int[] arr = new int[arrSize[0]];
		gPatchStack.GetArray(buff, arr, arrSize[0]);
		gPatchStack.Remove(buff);
		
		for(int i = 0; i < arrSize[0] - 1; i++)
			StoreToAddress(this.Address + i, arr[i + 1], NumberType_Int8);
		
		if(gPatchStack.Size == 0)
			delete gPatchStack;
	}
}

public void OnPluginEnd()
{
	if(gPatchStack)
	{
		StringMapSnapshot sms = gPatchStack.Snapshot();
		char buff[32];
		Address addr;
		
		for(int i = 0; i < sms.Length; i++)
		{
			sms.GetKey(i, buff, sizeof(buff));
			addr = view_as<Address>(StringToInt(buff));
			view_as<PatchHandler>(addr).Restore();
		}
	}
	
#if defined MEMUTILS_PLUGINENDCALL
	OnPluginEnd_MemUtilsRedefined();
#endif
}
#undef OnPluginEnd
#if defined MEMUTILS_PLUGINENDCALL
#define OnPluginEnd OnPluginEnd_MemUtilsRedefined
#else
#define OnPluginEnd OnPluginEnd_Redifined(){}\
void MEMUTILS_INCLUDE_WARNING_OnPluginEnd_REDIFINITION
#endif
//PatchHandling methodmap==-

//-==Other util functions
stock int LoadStringFromAddress(Address addr, char[] buff, int length)
{
	int i;
	for(i = 0; i < length && (buff[i] = LoadFromAddress(addr + i, NumberType_Int8)) != '\0'; i++) { }
	buff[i == length ? i - 1 : i] = '\0';
	return i;
}

stock void DumpOnAddress(Address addr, int len, int columns = 10)
{
	char buff[128], buff2[128];
	
	ASSERT(addr != Address_Null);
	ASSERT(len > 0 && len < MEM_LEN_SAFE_THRESHOLD);
	
	Format(buff, sizeof(buff), "[0x%08X]", addr);
	char chr;
	for(int i = 0; i < len; i++)
	{
		chr = LoadFromAddress(addr + i, NumberType_Int8);
		Format(buff, sizeof(buff), "%s %02X", buff, chr);
		Format(buff2, sizeof(buff2), "%s%c", buff2, (chr > ' ' && chr != 0x7F && chr != 0xFF ? chr : '.'));
		if(i % columns == columns - 1)
		{
			PrintToServer(__SNAME..."%s %s", buff, buff2);
			Format(buff, sizeof(buff), "[0x%08X]", addr + i);
			buff2[0] = '\0';
		}
	}
	
	if((len - 1) % columns != columns - 1)
		PrintToServer(__SNAME..."%s %s", buff, buff2);
}

//NO OVERLAPPING!!
stock void MoveBytes(Address from, Address to, int len, char replace_with = 0x90)
{
	ASSERT(from != Address_Null);
	ASSERT(to != Address_Null);
	ASSERT(len > 0 && len < MEM_LEN_SAFE_THRESHOLD);
	ASSERT(to < from || to > from + len);
	
	if(from == to)
		return;
	
	for(int i = 0; i < len; i++)
	{
		StoreToAddress(to + i, LoadFromAddress(from + i, NumberType_Int8), NumberType_Int8);
		StoreToAddress(from + i, replace_with, NumberType_Int8);
	}
}

stock void CutNCopyBytes(Address from, Address to, int len, char replace_with = 0x90)
{
	ASSERT(from != Address_Null);
	ASSERT(to != Address_Null);
	ASSERT(len > 0 && len < MEM_LEN_SAFE_THRESHOLD);
	
	if(from == to)
		return;
	
	int[] arr = new int[len];
	
	for(int i = 0; i < len; i++)
	{
		arr[i] = LoadFromAddress(from + i, NumberType_Int8);
		StoreToAddress(from + i, replace_with, NumberType_Int8);
	}
	
	for(int i = 0; i < len; i++)
		StoreToAddress(to + i, arr[i], NumberType_Int8);
}

stock void PatchArea(Address addr, int len, char byte = 0x90)
{
	ASSERT(addr != Address_Null);
	ASSERT(len > 0 && len < MEM_LEN_SAFE_THRESHOLD);
	
	for(int i = 0; i < len; i++)
		StoreToAddress(addr + i, byte, NumberType_Int8);
}
//Other util functions==-

#undef MEM_LEN_SAFE_THRESHOLD