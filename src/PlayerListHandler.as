class PlayerListHandler {
    array<Player> _players;
    string _searchPattern;

    void Update() {
        CGamePlayground@ playground = GetApp().CurrentPlayground;

        _players.RemoveRange(0, _players.Length);

        for (uint i = 0; i < playground.Players.Length; i++) {
            auto player = playground.Players[i];
            // ignore local user
            if (playground.Interface.ManialinkScriptHandler.LocalUser.Login == player.User.Login) {
                continue;
            }

            bool isSpectator = player.User.SpectatorMode == CGameNetPlayerInfo::ESpectatorMode::Watcher || player.User.SpectatorMode == CGameNetPlayerInfo::ESpectatorMode::LocalWatcher;
            _players.InsertLast(Player(player.User.Name, player.User.Login, isSpectator, i));
        }

        if (_players.Length > 0) {
            _players.Sort(function(a,b) {
                return a.Name.ToLower() < b.Name.ToLower();
            });

            _players.Sort(function(a, b) {
                return !a.IsSpectator && b.IsSpectator ? true : false;
            });
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

    void SetSearchPattern(string&in newPattern) {
        _searchPattern = newPattern;
    }

    void Spectate(string&in login) {
        CGamePlayground@ playground = GetApp().CurrentPlayground;
        CGamePlaygroundClientScriptAPI@ api = GetApp().CurrentPlayground.Interface.ManialinkScriptHandler.Playground;

        if (!api.IsSpectator) {
            api.RequestSpectatorClient(true);
        }

        api.SetSpectateTarget(login);
    }
}
