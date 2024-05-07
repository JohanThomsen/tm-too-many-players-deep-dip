string TrimStringLeft(string&in str) {
    string trimmed = "";
    bool add = false;
    int addi = 0;

    for (int i = 0; i < str.Length; i++) {
        if (str[i] != 32) {
            add = true;
        }

        if (add) {
            trimmed += " ";
            trimmed[addi++] = str[i];
        }
    }

    return trimmed;
}

string TrimStringRight(string&in str) {
    string trimmed = "";
    bool add = false;

    for (int i = str.Length-1; i >= 0; i--) {
        if (str[i] != 32) {
            add = true;
        }

        if (add) {
            trimmed = " " + trimmed;
            trimmed[0] = str[i];
        }
    }

    return trimmed;
}

string TrimString(string&in str) {
    return TrimStringRight(TrimStringLeft(str));
}

bool IsTeamsMode() {
    return GetApp().Network.ClientManiaAppPlayground.ManiaPlanet.CurrentServerModeName == "TM_Teams_Online";
}

bool IsKnockoutDaily() {
    return GetApp().Network.ClientManiaAppPlayground.ManiaPlanet.CurrentServerModeName == "TM_KnockoutDaily_Online";
}

string LoginToWSID(const string &in login) {
    auto buf = MemoryBuffer();
    buf.WriteFromBase64(login, true);
    auto hex = BufferToHex(buf);
    return hex.SubStr(0, 8)
        + "-" + hex.SubStr(8, 4)
        + "-" + hex.SubStr(12, 4)
        + "-" + hex.SubStr(16, 4)
        + "-" + hex.SubStr(20)
        ;
}

string BufferToHex(MemoryBuffer@ buf) {
    buf.Seek(0);
    auto size = buf.GetSize();
    string ret;
    for (uint i = 0; i < size; i++) {
        ret += Uint8ToHex(buf.ReadUInt8());
    }
    return ret;
}

string Uint8ToHex(uint8 val) {
    return Uint4ToHex(val >> 4) + Uint4ToHex(val & 0xF);
}

string Uint4ToHex(uint8 val) {
    if (val > 0xF) throw('val out of range: ' + val);
    string ret = " ";
    if (val < 10) {
        ret[0] = val + 0x30;
    } else {
        // 0x61 = a
        ret[0] = val - 10 + 0x61;
    }
    return ret;
}

//Adds headers to an HTTP request
string SendJSONRequest(const Net::HttpMethod Method, const string &in URL, string Body = "") {
    dictionary@ Headers = dictionary();
    Headers["Accept"] = "application/json";
    Headers["Content-Type"] = "application/json";
    Headers["User-Agent"] = "Too many players extension for Deep Dip. Made by @JohanClan on discord";
    return SendHTTPRequest(Method, URL, Body, Headers);
}

//Bundles everything together for an HTTP Request
string SendHTTPRequest(const Net::HttpMethod Method, const string &in URL, const string &in Body, dictionary@ Headers) {
    Net::HttpRequest req;
    req.Method = Method;
    req.Url = URL;
    @req.Headers = Headers;
    req.Body = Body;
    req.Start();
    while (!req.Finished()) {
        yield();
    }

    return req.String();
}

//Handles the response
Json::Value ResponseToJSON(const string &in HTTPResponse, Json::Type ExpectedType) {
    Json::Value ReturnedObject;
    try {
        ReturnedObject = Json::Parse(HTTPResponse);
    } catch {
        print("JSON Parsing of string failed!");
    }
    if (ReturnedObject.GetType() != ExpectedType) {
        print("Unexpected JSON Type returned");
        return ReturnedObject;
    }
    return ReturnedObject;
}

bool shouldShowDeepDipInfo() {
    return Setting_EnableDeepDip && getMapUid() == 'DeepDip2__The_Storm_Is_Here';
}

string getMapUid(){
    return GetApp().RootMap.MapInfo.MapUid;
}
