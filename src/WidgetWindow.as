class Player {
    string Name;
    string Login;
    bool IsSpectator;
    int Index;
    int Distance;

    Player(){}

    Player(string name, string login, bool isSpectator, int index) {
        Name = name;
        Login = login;
        IsSpectator = isSpectator;
        Index = index;
    }
}

class WidgetWindow {
    bool _autoUpdate = true;
    string searchPattern = "";
    array<Player> players;
    array<Player> effectivePlayers;

    void UpdatePlayers() {
        CGamePlayground@ playground = GetApp().CurrentPlayground;

        players.RemoveRange(0, players.Length);

        for (uint i = 0; i < playground.Players.Length; i++) {
            auto player = playground.Players[i];
            // ignore local user
            if (playground.Interface.ManialinkScriptHandler.LocalUser.Login == player.User.Login) {
                continue;
            }

            bool isSpectator = player.User.SpectatorMode == CGameNetPlayerInfo::ESpectatorMode::Watcher || player.User.SpectatorMode == CGameNetPlayerInfo::ESpectatorMode::LocalWatcher;
            players.InsertLast(Player(player.User.Name, player.User.Login, isSpectator, i));
        }

        if (players.Length > 0) {
            players.Sort(function(a,b) {
                return a.Name.ToLower() < b.Name.ToLower();
            });

            players.Sort(function(a, b) {
                return !a.IsSpectator && b.IsSpectator ? true : false;
            });
        }
    }

    void SpectatePlayer(string&in login) {
        CGamePlayground@ playground = GetApp().CurrentPlayground;
        CGamePlaygroundClientScriptAPI@ api = GetApp().CurrentPlayground.Interface.ManialinkScriptHandler.Playground;

        if (!api.IsSpectator) {
            api.RequestSpectatorClient(true);
        }

        api.SetSpectateTarget(login);
    }

    void SetEffectivePlayerList() {
        string newPattern = UI::InputText("Search", searchPattern);

        if (newPattern != searchPattern) {
            searchPattern = TrimString(newPattern);
        }

        effectivePlayers.RemoveRange(0, effectivePlayers.Length);

        if (searchPattern == "") {
            for (uint i = 0; i < players.Length; i++) {
                effectivePlayers.InsertLast(players[i]);
            }

            return;
        }

        // find best matches
        for (uint i = 0; i < players.Length; i++) {
            players[i].Distance = players[i].Name.ToLower().IndexOf(searchPattern.ToLower());
        }

        for (uint i = 0; i < players.Length; i++) {
            if (players[i].Distance >= 0) {
                effectivePlayers.InsertLast(players[i]);
            }
        }

        if (effectivePlayers.Length > 0) {
            effectivePlayers.Sort(function(a, b) {
                return a.Distance < b.Distance;
            });
        }
    }

    void Render() {
        if (!Setting_Visible) {
            return;
        }

        UI::SetNextWindowSize(200, 285, UI::Cond::FirstUseEver);
        UI::SetNextWindowPos(0, 75, UI::Cond::FirstUseEver);

        auto flags =  UI::WindowFlags::NoFocusOnAppearing 
                    | UI::WindowFlags::NoCollapse
                    | UI::WindowFlags::NoDocking 
                    | UI::WindowFlags::NoTitleBar;

        if (UI::Begin(Icons::Users +" Too Many Players", Setting_Visible, flags)) {
            auto windowPos = UI::GetWindowPos();
            auto windowSize = UI::GetWindowSize();

            Setting_Width = windowSize.x;
            Setting_Height = windowSize.y;
            Setting_PosX = windowPos.x;
            Setting_PosY = windowPos.y;

            UI::Text("Auto Update:");
            if (UI::BeginTable("controls", 2)) {
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed, 0);
                UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 0);

                UI::TableNextRow();

                UI::TableNextColumn();
                _autoUpdate = UI::Checkbox("", _autoUpdate);

                UI::TableNextColumn();

                if (_autoUpdate || UI::IsWindowAppearing()) {
                    UpdatePlayers();
                } else if (UI::Button("Update Now")) {
                    UpdatePlayers();
                }

                UI::EndTable();
            }

            UI::Separator();

            UI::Text("Player List:");

            SetEffectivePlayerList();

            UI::BeginChild("playerlist");

            if (UI::BeginTable("players", 2)) {
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 0);

                for (uint i = 0; i < effectivePlayers.Length; i++) {
                    Player player = effectivePlayers[i];

                    if (player is null) {
                        continue;
                    }

                    UI::TableNextRow();

                    UI::TableNextColumn();
                    UI::Text(player.Name);

                    UI::TableNextColumn();

                    if (!player.IsSpectator && UI::Button(Icons::Eye + "##"+i)) {
                        SpectatePlayer(player.Login);
                    }
                }

                UI::EndTable();
            }

            UI::EndChild();
        }

        UI::End();
    }
}

WidgetWindow widgetWindow;
