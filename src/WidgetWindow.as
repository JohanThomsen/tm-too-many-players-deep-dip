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
        UI::Text(Icons::Users + " Too Many Players");
    }

    void RenderWindowControls() {
        _autoUpdate = UI::Checkbox("", _autoUpdate);

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

            UI::EndPopup();
        }
    }

    void RenderPlayersTable() {
        UI::BeginChild("playerlist");

        if (UI::BeginTable("players", 2)) {
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 0);

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
                UI::Text(player.Name);

                UI::TableNextColumn();

                if (!player.IsSpectator && UI::Button(Icons::Eye + "##"+i)) {
                    _playerList.Spectate(player.Login);
                }

                Tooltip("Spectate " + player.Name);
            }

            UI::EndTable();
        }

        UI::EndChild();
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
