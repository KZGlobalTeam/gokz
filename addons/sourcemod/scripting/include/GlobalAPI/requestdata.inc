// ================== DOUBLE INCLUDE ========================= //

#if defined _GlobalAPI_RequestData_included_
#endinput
#endif
#define _GlobalAPI_RequestData_included_

// =========================================================== //

#include <json>

// =========================================================== //

/*
	Helper methodmap for wrapping data related to requests
*/
methodmap GlobalAPIRequestData < JSON_Object
{
   /**
 	* Creates a new GlobalAPIRequestData
 	*
 	* @note 					You can pass a plugin handle or name and/or version
 	* @note						Plugin handle is always preferred
 	* @param plugin				Handle to calling plugin
 	* @param pluginName			Name of the calling plugin
 	* @param pluginVersion		Version of the calling plugin
 	* @return					A new GlobalAPIRequestData handle
 	*/
	public GlobalAPIRequestData(Handle plugin = null, char[] pluginName = "Unknown", char[] pluginVersion = "Unknown")
	{
		JSON_Object requestData = new JSON_Object();

		if (plugin == null)
		{
			requestData.SetString("pluginName", pluginName);
			requestData.SetString("pluginVersion", pluginVersion);
		}
		else
		{
			char name[GlobalAPI_Max_PluginName_Length];
			char version[GlobalAPI_Max_PluginVersion_Length];
			GetPluginDisplayName(plugin, name, sizeof(name));
			GetPluginVersion(plugin, version, sizeof(version));
			requestData.SetString("pluginName", name);
			requestData.SetString("pluginVersion", version);
		}

		requestData.SetHidden("pluginName", true);
		requestData.SetHidden("pluginVersion", true);

		requestData.SetInt("acceptType", 0);
		requestData.SetHidden("acceptType", true);

		requestData.SetInt("contentType", 0);
		requestData.SetHidden("contentType", true);

		return view_as<GlobalAPIRequestData>(requestData);
	}

   /**
 	* Sets a key as default
 	*
 	* @note						This sets them as "Handle" type
 	* @note						- See GlobalAPI.inc for default values
 	* @param key				Key to set as default
 	* @noreturn
 	*/
	public void SetDefault(char[] key)
	{
		this.SetInt(key, 0);
		this.SetHidden(key, true);
	}
	
   /**
 	* Sets url to the request data
 	*
 	* @param url				Url to set
 	* @noreturn
 	*/
	public void AddUrl(char[] url)
	{
		this.SetString("url", url);
		this.SetHidden("url", true);
	}
	
   /**
 	* Sets endpoint to the request data
 	*
 	* @param endpoint			Endpoint to set
 	* @noreturn
 	*/
	public void AddEndpoint(char[] endpoint)
	{
		this.SetString("endpoint", endpoint);
		this.SetHidden("endpoint", true);
	}
	
   /**
	* Sets body file path to the request data
	*
	* @note						Path to file with data to be posted
	* @param path				Body file (path) to set
	* @noreturn
	*/
	public void AddBodyFile(char[] path)
	{
		this.SetString("bodyFile", path);
		this.SetHidden("bodyFile", true);
	}

   /**
	* Sets data file path to the request data
	*
	* @note						Path for downloaded files
	* @param path				Data path to set
	* @noreturn
	*/
	public void AddDataPath(char[] path)
	{
		this.SetString("dataFilePath", path);
		this.SetHidden("dataFilePath", true);
	}

    /*
 		Get or set the request's "acceptType"
 	*/
	property int AcceptType
	{
		public get()
		{
			return this.GetInt("acceptType");
		}
		public set(int type)
		{
			this.SetInt("acceptType", type);
		}
	}

    /*
 		Get or set the request's "contentType"
 	*/
	property int ContentType
	{
		public get()
		{
			return this.GetInt("contentType");
		}
		public set(int type)
		{
			this.SetInt("contentType", type);
		}
	}
	
    /*
 		Get or set the request's "keyRequired"
 	*/
	property bool KeyRequired
	{
		public get()
		{
			return this.GetBool("keyRequired");
		}
		public set(bool required)
		{
			this.SetBool("keyRequired", required);
			this.SetHidden("keyRequired", true);
		}
	}
	
	/*
		Get or set the request's "isRetried"
 	*/
	property bool IsRetried
	{
		public get()
		{
			return this.GetBool("isRetried");
		}
		public set(bool retried)
		{
			this.SetBool("isRetried", retried);
			this.SetHidden("isRetried", true);
		}
	}
	
	/*
		Get or set the request's "bodyLength"
 	*/
	property int BodyLength
	{
		public get()
		{
			return this.GetInt("bodyLength");
		}
		public set(int length)
		{
			this.SetInt("bodyLength", length);
			this.SetHidden("bodyLength", true);
		}
	}

    /*
 		Get or set the request's "status"
 	*/
	property int Status
	{
		public get()
		{
			return this.GetInt("status");
		}
		public set(int status)
		{
			this.SetInt("status", status);
			this.SetHidden("status", true);
		}
	}

    /*
 		Get or set the request's "responseTime"
 	*/
	property int ResponseTime
	{
		public get()
		{
			return this.GetInt("responseTime");
		}
		public set(int responseTime)
		{
			this.SetInt("responseTime", responseTime);
			this.SetHidden("responseTime", true);
		}
	}

    /*
 		Get or set the request's "requestType"
 	*/
	property int RequestType
	{
		public get()
		{
			return this.GetInt("requestType");
		}
		public set(int type)
		{
			this.SetInt("requestType", type);
			this.SetHidden("requestType", true);
		}
	}

    /*
 		Get or set the request's "failure"
 	*/
	property bool Failure
	{
		public get()
		{
			return this.GetBool("failure");
		}
		public set(bool failure)
		{
			this.SetBool("failure", failure);
			this.SetHidden("failure", true);
		}
	}

    /*
 		Get or set the request's "callback"
 	*/
	property Handle Callback
	{
		public get()
		{
			return view_as<Handle>(this.GetInt("callback"));
		}
		public set(Handle hFwd)
		{
			this.SetInt("callback", view_as<int>(hFwd));
			this.SetHidden("callback", true);
		}
	}
	
	/*
		Get or set the request's "data"
 	*/
	property any Data
	{
		public get()
		{
			return this.GetInt("data");
		}
		public set(any data)
		{
			this.SetInt("data", data);
			this.SetHidden("data", true);
		}
	}

   /**
 	* Adds a number to the request data
 	*
 	* @note						Default values are added as "defaults"
 	* @note						See GlobalAPI.inc for the default values
 	* @param key				Key name to set
 	* @param value				Value of the key
 	* @noreturn
 	*/
	public void AddNum(char[] key, int value)
	{
		if (value == -1)
		{
			this.SetDefault(key);
		}
		else
		{
			this.SetInt(key, value);
		}
	}

   /**
 	* Adds a float to the request data
 	*
 	* @note						Default values are added as "defaults"
 	* @note						See GlobalAPI.inc for the default values
 	* @param key				Key name to set
 	* @param value				Value of the key
 	* @noreturn
 	*/
	public void AddFloat(char[] key, float value)
	{
		if (value == -1.000000)
		{
			this.SetDefault(key);
		}
		else
		{
			this.SetFloat(key, value);
		}
	}

   /**
 	* Adds a string to the request data
 	*
 	* @note						Default values are added as "defaults"
 	* @note						See GlobalAPI.inc for the default values
 	* @param key				Key name to set
 	* @param value				Value of the key
 	* @noreturn
 	*/
	public void AddString(char[] key, char[] value)
	{
		if (StrEqual(value, ""))
		{
			this.SetDefault(key);
		}
		else
		{
			this.SetString(key, value);
		}
	}

   /**
 	* Adds a boolean to the request data
 	*
 	* @note						Default values are added as "defaults"
 	* @note						See GlobalAPI.inc for the default values
 	* @param key				Key name to set
 	* @param value				Value of the key
 	* @noreturn
 	*/
	public void AddBool(char[] key, bool value)
	{
		if (value != true && value != false)
		{
			this.SetDefault(key);
		}
		else
		{
			this.SetBool(key, value);
		}
	}
	
   /**
 	* Adds integer array to the request data
 	*
 	* @note						Max length <= 0 are added as defaults
 	* @param key				Key name to set
 	* @param value				Values (array) of the key
 	* @param maxlength			Max length of the values array
 	* @noreturn
 	*/
	public void AddIntArray(char[] key, int[] value, int maxlength)
	{
		if (maxlength <= 0)
		{
			this.SetDefault(key);
		}
		else
		{
			JSON_Array hArray = new JSON_Array();

			for (int i = 0; i < maxlength; i++)
			{
				hArray.PushInt(value[i]);
			}

			this.SetObject(key, hArray);
		}
	}

   /**
 	* Adds string array to the request data
 	*
 	* @note						Item count <= 0 are added as defaults
 	* @param key				Key name to set
 	* @param itemCount			Amount of strings in the array
 	* @noreturn
 	*/
	public void AddStringArray(char[] key, char[][] value, int itemCount)
	{
		if (itemCount <= 0)
		{
			this.SetDefault(key);
		}
		else
		{
			JSON_Array hArray = new JSON_Array();

			for (int i = 0; i < itemCount; i++)
			{
				hArray.PushString(value[i]);
			}

			this.SetObject(key, hArray);
		}
	}

   /**
 	* Converts all of the request data into a query string representation
 	*
 	* @note						This ignores "hidden" keys
 	* @param queryString		Buffer to store the result in
 	* @param maxlength			Max length of the buffer
 	* @noreturn
 	*/
	public void ToString(char[] queryString, int maxlength)
	{
		int jsonSize = this.Length;

		char key[64];
		char value[1024];

		int paramCount = 0;

		for (int i = 0; i < jsonSize; i++)
		{
			int keySize = this.GetKeySize(i);
			if (keySize > sizeof(key)) keySize = sizeof(key);
			this.GetKey(i, key, keySize);

			if (this.GetHidden(key))
			{
				continue;
			}

			switch(this.GetType(key))
			{
				case JSON_Type_String:
				{
					this.GetString(key, value, sizeof(value));
					AppendToQueryString(paramCount, queryString, maxlength, key, value);
				}
				case JSON_Type_Float:
				{
					float temp = this.GetFloat(key);
					FloatToString(temp, value, sizeof(value));
					AppendToQueryString(paramCount, queryString, maxlength, key, value);
				}
				case JSON_Type_Int:
				{
					int temp = this.GetInt(key);
					IntToString(temp, value, sizeof(value));
					AppendToQueryString(paramCount, queryString, maxlength, key, value);
				}
				case JSON_Type_Bool:
				{
					bool temp = this.GetBool(key);
					BoolToString(temp, value, sizeof(value));
					AppendToQueryString(paramCount, queryString, maxlength, key, value);
				}
				case JSON_Type_Object:
				{
					JSON_Object hObject = this.GetObject(key);
					
					if (!hObject.IsArray) continue;

					JSON_Array hArray = view_as<JSON_Array>(hObject);

					for (int x = 0; x < hArray.Length; x++)
					{
						switch (hArray.GetType(x))
						{
							case JSON_Type_Int:
							{
								int temp = hArray.GetInt(x);
								IntToString(temp, value, sizeof(value));
								AppendToQueryString(paramCount, queryString, maxlength, key, value);
							}
							case JSON_Type_String:
							{
								hArray.GetString(x, value, sizeof(value));
								AppendToQueryString(paramCount, queryString, maxlength, key, value);
							}
						}
					}
				}
			}
		}
	}
}

// =====[ PRIVATE ]=====

static void BoolToString(bool value, char[] buffer, int maxlength)
{
	FormatEx(buffer, maxlength, "%s", value ? "true" : "false");
}

static void AppendToQueryString(int &index, char[] buffer, int maxlength, char[] key, char[] value)
{
	if (index == 0)
	{
		index++;
		Format(buffer, maxlength, "?%s=%s", key, value);
	}
	else
	{
		index++;
		Format(buffer, maxlength, "%s&%s=%s", buffer, key, value);
	}
}
