// ================== DOUBLE INCLUDE ========================= //

#if defined _GlobalAPI_Request_included_
#endinput
#endif
#define _GlobalAPI_Request_included_

// =========================================================== //

static char gC_acceptTypePhrases[][] =
{
	"application/json",
	"application/octet-stream"
};

static char gC_contentTypePhrases[][] =
{
	"application/json",
	"application/octet-stream"
};

// =========================================================== //

methodmap GlobalAPIRequest < Handle
{
   /**
 	* Creates a new GlobalAPIRequest
 	*
 	* @param url				URL of the request
 	* @param method				SteamWorks k_ETTPMethod of the request
 	* @return					A new GlobalAPIRequest handle
 	*/
	public GlobalAPIRequest(char[] url, EHTTPMethod method)
	{
		Handle request = SteamWorks_CreateHTTPRequest(method, url);
		return view_as<GlobalAPIRequest>(request);
	}

   /**
 	* Sets request timeout
 	*
 	* @param seconds			Timeout in seconds
 	* @return					Whether the operation was successful
 	*/
	public bool SetTimeout(int seconds)
	{
		return SteamWorks_SetHTTPRequestAbsoluteTimeoutMS(this, seconds * 1000);
	}
	
   /**
 	* Sets request body
 	*
 	* @param hData				GlobalAPIRequestData containing contentType
 	* @param body				Request body to set
 	* @param maxlength			Maxlength of the body
 	* @return					Whether the operation was successful
 	*/
	public bool SetBody(GlobalAPIRequestData hData, char[] body, int maxlength)
	{
		return SteamWorks_SetHTTPRequestRawPostBody(this, gC_contentTypePhrases[hData.ContentType], body, maxlength);
	}

   /**
	* Sets request body from a file
	*
	* @param hData				GlobalAPIRequestData containing contentType
	* @return					Whether the operation was successful
	*/
	public bool SetBodyFromFile(GlobalAPIRequestData hData, char[] file)
	{
		return SteamWorks_SetHTTPRequestRawPostBodyFromFile(this, gC_contentTypePhrases[hData.ContentType], file);
	}

   /**
 	* Sets a request context value
 	*
 	* @param data				Any data to pass
 	* @return					Whether the operation was successful
 	*/
	public bool SetData(any data1, any data2 = 0)
	{
		return SteamWorks_SetHTTPRequestContextValue(this, data1, data2);
	}

   /**
 	* Sets predefined HTTP callbacks
 	*
 	* @note						Predefined values respectively: 
	* @note 					Global_HTTP_Completed, Global_HTTP_Headers and Global_HTTP_DataReceived
 	* @noreturn
 	*/
	public void SetCallbacks()
	{
		SteamWorks_SetHTTPCallbacks(this, Global_HTTP_Completed, Global_HTTP_Headers, Global_HTTP_DataReceived);
	}
	
   /**
 	* Sets "Accept" header
 	*
 	* @param hData				GlobalAPIRequestData containing acceptType
 	* @return					Whether the operation was successful
 	*/
	public bool SetAcceptHeaders(GlobalAPIRequestData hData)
	{
		return SteamWorks_SetHTTPRequestHeaderValue(this, "Accept", gC_acceptTypePhrases[hData.AcceptType]);
	}
	
   /**
 	* Sets "powered by" header
 	*
 	* @return					Whether the operation was successful
 	*/
	public bool SetPoweredByHeader()
	{
		return SteamWorks_SetHTTPRequestHeaderValue(this, "X-Powered-By", GlobalAPI_Plugin_NameVersion);
	}

   /**
 	* Sets authentication header
 	*
 	* @return					Whether the operation was successful
 	*/
	public bool SetAuthenticationHeader(char[] apiKey)
	{
		return SteamWorks_SetHTTPRequestHeaderValue(this, "X-ApiKey", apiKey);
	}

   /**
 	* Sets envinroment headers (MetaMod & SourceMod)
 	*
  	* @param mmVersion			MetaMod version string
 	* @param smVersion			SourceMod version string
 	* @return					Whether the operation was successful
 	*/
	public bool SetEnvironmentHeaders(char[] mmVersion, char[] smVersion)
	{
		return SteamWorks_SetHTTPRequestHeaderValue(this, "X-MetaMod-Version", mmVersion)
		&& SteamWorks_SetHTTPRequestHeaderValue(this, "X-SourceMod-Version", smVersion);
	}

   /**
 	* Sets content type header
 	*
 	* @param hData				GlobalAPIRequestData containing contentType
 	* @return					Whether the operation was successful
 	*/
	public bool SetContentTypeHeader(GlobalAPIRequestData hData)
	{
		return SteamWorks_SetHTTPRequestHeaderValue(this, "Content-Type", gC_contentTypePhrases[hData.ContentType]);
	}
	
   /**
 	* Sets request origin header
 	*
 	* @param hData				GlobalAPIRequestData containing pluginName
 	* @return					Whether the operation was successful
 	*/
	public bool SetRequestOriginHeader(GlobalAPIRequestData hData)
	{
		char pluginName[GlobalAPI_Max_PluginName_Length];
		hData.GetString("pluginName", pluginName, sizeof(pluginName));
		
		char pluginVersion[GlobalAPI_Max_PluginVersion_Length + 2];
		hData.GetString("pluginVersion", pluginVersion, sizeof(pluginVersion));
		
		char fullPluginDisplay[sizeof(pluginName) + sizeof(pluginVersion) + 6];
		Format(fullPluginDisplay, sizeof(fullPluginDisplay), "%s (V.%s)", pluginName, pluginVersion); 
		
		return SteamWorks_SetHTTPRequestHeaderValue(this, "X-Request-Origin", fullPluginDisplay);
	}

   /**
 	* Sends our request with all available data
 	*
 	* @param hData				GlobalAPIRequestData handle with all required keys
 	* @return					Whether the operation was successful
 	*/
	public bool Send(GlobalAPIRequestData hData)
	{
		Call_Private_OnHTTPStart(this, hData);
		return SteamWorks_SendHTTPRequest(this);
	}
}

// =========================================================== //