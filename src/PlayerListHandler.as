class Player {
    string Name;
    string Login;
    bool IsSpectator;
    int Index;
    int Distance;
    bool IsFavorited;
    int Team;

    Player(){}

    Player(string name, string login, bool isSpectator, int index, bool isFavorited, int team) {
        Name = name;
        Login = login;
        IsSpectator = isSpectator;
        Index = index;
        IsFavorited = isFavorited;
        Team = team;
    }
}

class PlayerListHandler {
    array<Player> _players;
    string _searchPattern;
    array<string> _favorites;
    int _currentPb;
    int _currentRank;
    string _targetLogin;

    void Update() {
        CGamePlayground@ playground = GetApp().CurrentPlayground;
        _players.RemoveRange(0, _players.Length);

        for (uint i = 0; i < playground.Players.Length; i++) {
            auto player = cast<CSmPlayer@>(playground.Players[i]);
            // ignore local user
            if (playground.Interface.ManialinkScriptHandler.LocalUser.Login == player.User.Login) {
                continue;
            }

            bool isSpectator = player.User.SpectatorMode == CGameNetPlayerInfo::ESpectatorMode::Watcher 
                            || player.User.SpectatorMode == CGameNetPlayerInfo::ESpectatorMode::LocalWatcher
                            || player.SpawnIndex < 0;

            bool isFavorited = _favorites.Find(player.User.Login) >= 0;
            
            _players.InsertLast(Player(player.User.Name, player.User.Login, isSpectator, i, isFavorited, player.EdClan));
        }

        if (_players.Length > 0) {
            _players.Sort(function(a,b) {
                return a.Name.ToLower() < b.Name.ToLower();
            });

            _players.Sort(function(a, b) {
                return !a.IsSpectator && b.IsSpectator ? true : false;
            });

            if (Setting_EnableFavorites) {
                _players.Sort(function(a, b) {
                    return !a.IsFavorited && b.IsFavorited || a.IsFavorited == b.IsFavorited ? false : true;
                });
            }
        }
    }

    array<Player> GetPlayerList() {
        if (_searchPattern == "") {
            return _players;
        }

        array<Player> effectivePlayers;

        for (uint i = 0; i < _players.Length; i++) {
            _players[i].Distance = _players[i].Name.ToLower().IndexOf(_searchPattern.ToLower());
        }

        for (uint i = 0; i < _players.Length; i++) {
            if (_players[i].Distance >= 0) {
                effectivePlayers.InsertLast(_players[i]);
            }
        }

        if (effectivePlayers.Length > 0) {
            effectivePlayers.Sort(function(a, b) {
                return a.Distance < b.Distance;
            });
        }

        return effectivePlayers;
    }

    int GetCurrentPb() {
        return _currentPb;
    }

    int GetCurrentRank() {
        return _currentRank;
    }

    void SetSearchPattern(string&in newPattern) {
        _searchPattern = newPattern;
    }

    void Spectate(string&in login) {
        CGamePlayground@ playground = GetApp().CurrentPlayground;
        CGamePlaygroundClientScriptAPI@ api = GetApp().CurrentPlayground.Interface.ManialinkScriptHandler.Playground;

        if (!IsKnockoutDaily() && !api.IsSpectator) {
            api.RequestSpectatorClient(true);
        }

        api.SetSpectateTarget(login);
        _targetLogin = login;

        if(shouldShowDeepDipInfo()) {
            startnew(CoroutineFunc(this.getDeepDipInfo));
        }
    }

    void getDeepDipInfo() {
        string Wsid = LoginToWSID(_targetLogin);
        string dipResponse = SendJSONRequest(Net::HttpMethod::Get, "https://dips-plus-plus.xk.io/leaderboard/" + Wsid); //Get Deep Dip info
        //If player is not using DIPS++ it will return null as a string
        if(dipResponse == 'null') {
            _currentPb = 0;
            _currentRank = 0;
            return;
        }

        Json::Value DeepDipResponse = ResponseToJSON(dipResponse, Json::Type::Object);
        _currentPb = DeepDipResponse['height'];
        _currentRank = DeepDipResponse['rank'];
    }

    void ToggleFavorite(string&in login) {
        auto i = _favorites.Find(login);
        if (i >= 0) {
            _favorites.RemoveAt(i);
        } else {
            _favorites.InsertLast(login);
        }
    }
}
