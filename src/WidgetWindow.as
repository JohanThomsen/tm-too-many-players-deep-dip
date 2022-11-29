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
    float _effectiveHeight = Setting_Height;
    bool _firstHover = true;
    uint64 _lastHover = 0;

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

    bool IsHoveringWindow() {
        vec2 winPos = UI::GetWindowPos();
        vec2 winSize = UI::GetWindowSize();
        vec2 mousePos = UI::GetMousePos();

        bool hovering = mousePos.x >= winPos.x 
            && mousePos.x <= winPos.x+winSize.x-1
            && mousePos.y >= winPos.y 
            && mousePos.y <= winPos.y+winSize.y-1;

        if (hovering == false && _lastHover + 500 > Time::get_Now()) {
            hovering = true;
        } else if (hovering == true) {
            _lastHover = Time::get_Now();
        }

        return hovering;
    }

    void SetWindowSizes(bool mouseIsHovering) {
        auto windowPos = UI::GetWindowPos();
        auto windowSize = UI::GetWindowSize();

        Setting_Width = windowSize.x;
        Setting_PosX = windowPos.x;
        Setting_PosY = windowPos.y;

        if (Setting_MinimizeWhenNotHovering) {
            if (mouseIsHovering) {
                _effectiveHeight = Setting_Height;

                if (!_firstHover) {
                    Setting_Height = windowSize.y;
                }

                _firstHover = false;
            } else {
                _effectiveHeight = 0;
                _firstHover = true;
            }
        } else {
            Setting_Height = windowSize.y;
        }
    }

    void Render() {
        if (!Setting_Visible) {
            return;
        }

        if (!Setting_MinimizeWhenNotHovering) {
            _effectiveHeight = Setting_Height;
        }

        UI::SetNextWindowSize(Setting_Width, _effectiveHeight, UI::Cond::Always);
        UI::SetNextWindowPos(0, 75, UI::Cond::FirstUseEver);
        auto windowFlags =  UI::WindowFlags::NoCollapse 
                          | UI::WindowFlags::NoDocking
                          | UI::WindowFlags::NoTitleBar;

        if (UI::Begin(Icons::Users + " Too Many Players", Setting_Visible, windowFlags)) {
            bool isMouseHovering = IsHoveringWindow();
            SetWindowSizes(isMouseHovering);

            if (Setting_MinimizeWhenNotHovering && !isMouseHovering) {
                RenderMinimized();
            } else {
                RenderWindowControls();

                UI::Separator();

                SetEffectivePlayerList();
                RenderPlayersTable();
            }
        }

        UI::End();
    }

    void RenderMinimized() {
        UI::Text(Icons::Users + " Too Many Players");
    }

    void RenderWindowControls() {
        if (UI::BeginTable("controls", 2)) {
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed, 0);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 0);

            UI::TableNextRow();

            UI::TableNextColumn();
            _autoUpdate = UI::Checkbox("", _autoUpdate);

            UI::TableNextColumn();

            if (_autoUpdate) {
                UI::Text("Auto Update");
                UpdatePlayers();
            } else {
                if (UI::Button(Icons::Refresh)) {
                    UpdatePlayers();
                }
            }

            UI::EndTable();
        }
    }

    void RenderPlayersTable() {
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
}

WidgetWindow widgetWindow;
