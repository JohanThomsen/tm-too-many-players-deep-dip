class WidgetWindow {
    bool _autoUpdate = true;
    string searchPattern = "";
    float _effectiveHeight = Setting_Height;
    bool _firstHover = true;
    uint64 _lastHover = 0;
    PlayerListHandler _playerList;
    bool _minimized = false;

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
                _effectiveHeight = 40;
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

        if (_minimized) {
            windowFlags |= UI::WindowFlags::NoResize;
        }

        if (Setting_LockPosition) {
            windowFlags |= UI::WindowFlags::NoMove;
        }

        if (UI::Begin(Icons::Users + " Too Many Players", Setting_Visible, windowFlags)) {
            bool isMouseHovering = IsHoveringWindow();
            _minimized = Setting_MinimizeWhenNotHovering && !isMouseHovering;

            SetWindowSizes(isMouseHovering);

            AddOptionsMenu();

            if (_minimized) {
                RenderMinimized();
                UI::SetCursorPos(vec2(0, 8));
                RenderOptionsButton();
            } else {
                RenderWindowControls();

                UI::Separator();

                RenderSearch();
                RenderPlayersTable();
            }
        }

        UI::End();
    }

    void RenderSearch() {
        auto newPattern = UI::InputText("Search", searchPattern);

        if (newPattern != searchPattern) {
            searchPattern = TrimString(newPattern);
        }

        _playerList.SetSearchPattern(searchPattern);
    }

    void RenderMinimized() {
        UI::SetCursorPos(vec2(10, 12));
        UI::Text(Icons::Users + " Players");
    }

    void RenderWindowControls() {
        _autoUpdate = UI::Checkbox("##", _autoUpdate);

        Tooltip("Auto-Update");

        if (_autoUpdate) {
            _playerList.Update();
        } else {
            UI::SameLine();
            if (UI::Button(Icons::Refresh)) {
                _playerList.Update();
            }

            Tooltip("Update Now");
        }

        UI::SameLine();
        RenderOptionsButton();
    }

    void RenderOptionsButton() {
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 40, UI::GetCursorPos().y));
        UI::PushStyleColor(UI::Col::Button, vec4(0, 0, 0, 0));
        UI::PushStyleColor(UI::Col::ButtonHovered, vec4(1, 1, 1, 0.02));
        UI::PushStyleColor(UI::Col::ButtonActive, vec4(1, 1, 1, 0.03));
        UI::PushStyleVar(UI::StyleVar::FrameRounding, 0);
        if (UI::Button(Icons::Cog)) {
            UI::OpenPopup("OptionsMenu");
        }

        UI::PopStyleVar();
        UI::PopStyleColor(3);

        Tooltip("Options");
    }

    void AddOptionsMenu() {
        if (UI::BeginPopup("OptionsMenu", UI::WindowFlags::NoMove)) {
            
            UI::PushFont(fontBold);
            UI::Text("Options");
            UI::PopFont();

            UI::Separator();

            if (UI::MenuItem("Auto-Minimize", "", Setting_MinimizeWhenNotHovering)) {
                Setting_MinimizeWhenNotHovering = !Setting_MinimizeWhenNotHovering;
            }

            if (UI::MenuItem("Ignore Spectators", "", Setting_IgnoreSpectators)) {
                Setting_IgnoreSpectators = !Setting_IgnoreSpectators;
            }

            if (UI::MenuItem("Enable Favorites", "", Setting_EnableFavorites)) {
                Setting_EnableFavorites = !Setting_EnableFavorites;
            }

            UI::Separator();

            if (UI::MenuItem("Team Colors", "", Setting_UseTeamColors)) {
                Setting_UseTeamColors = !Setting_UseTeamColors;
            }

            UI::Separator();

            if (UI::MenuItem("Lock Position", "", Setting_LockPosition)) {
                Setting_LockPosition = !Setting_LockPosition;
            }

            UI::EndPopup();
        }
    }

    void RenderPlayersTable() {
        UI::BeginChild("playerlist");

        if (Setting_EnableFavorites) {
            RenderPlayersList();
        } else {
            RenderPlayersListSimple();
        }

        UI::EndChild();
    }

    void RenderPlayersListSimple() {
        auto players = _playerList.GetPlayerList();
        for (uint i = 0; i < players.Length; i++) {
            Player player = players[i];

            if (player is null) {
                continue;
            }

            if (Setting_IgnoreSpectators && player.IsSpectator) {
                continue;
            }

            RenderPlayer(player);
        }
    }

    void RenderPlayersList() {
        if (UI::BeginTable("players", 2)) {
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 14);

            auto players = _playerList.GetPlayerList();
            for (uint i = 0; i < players.Length; i++) {
                Player player = players[i];

                if (player is null) {
                    continue;
                }

                if (Setting_IgnoreSpectators && player.IsSpectator) {
                    continue;
                }

                UI::TableNextRow();

                UI::TableNextColumn();

                RenderPlayer(player);
                RenderFavoriteButton(player, i);
            }

            UI::EndTable();
        }
    }

    void RenderPlayer(Player@ player) {
        vec3 nameTextColor;

        if (Setting_UseTeamColors && IsTeamsMode()) {
            nameTextColor = vec3(
                player.Team == 2 ? 1 : 0.3,
                0.3,
                player.Team == 1 ? 1 : 0.3);
        } else {
            nameTextColor = vec3(1, 1, 1);
        }

        UI::PushStyleColor(UI::Col::Text, vec4(
            nameTextColor.x,
            nameTextColor.y,
            nameTextColor.z,
            player.IsSpectator ? 0.1 : 0.5
        ));

        if (UI::MenuItem(player.Name) && !player.IsSpectator) {
            _playerList.Spectate(player.Login);
        }

        UI::PopStyleColor();

        if (!player.IsSpectator) {
            Tooltip("Spectate " + player.Name);
        }
    }

    void RenderFavoriteButton(Player@ player, uint id) {
        UI::TableNextColumn();

        UI::SetCursorPos(vec2(UI::GetWindowSize().x - (UI::GetScrollMaxY() > 0 ? 40 : 24), UI::GetCursorPos().y-1));
        UI::PushStyleColor(UI::Col::Button, vec4(0, 0, 0, 0));
        UI::PushStyleColor(UI::Col::ButtonHovered, vec4(1, 1, 1, 0.01));
        UI::PushStyleColor(UI::Col::ButtonActive, vec4(1, 1, 1, 0.01));
        UI::PushStyleVar(UI::StyleVar::FrameRounding, 0);

        if (UI::Button((player.IsFavorited ? Icons::Star : Icons::StarO) + "##"+id, vec2(24, 19))) {
            _playerList.ToggleFavorite(player.Login);
            if (!_autoUpdate) _playerList.Update();
        }

        Tooltip("Favorite " + player.Name);

        UI::PopStyleVar();
        UI::PopStyleColor(3);
    }

    void Tooltip(string text) {
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::Text(text);
            UI::EndTooltip();
        }
    }
}

WidgetWindow widgetWindow;
