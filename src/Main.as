[Setting name="Visible" category=" Window" description="Show the widget while on a server."]
bool Setting_Visible = false;

[Setting name="Only In Spectator" category=" Window" description="Only show the widget while spectating."]
bool Setting_OnlyInSpec = false;

[Setting name="Minimize When Not Hovering" category=" Window" description="Minimize the window when the mouse is not hovering the window."]
bool Setting_MinimizeWhenNotHovering = false;

[Setting name="Lock Position" category=" Window" description="Disable the ability to move the window and lock it in place."]
bool Setting_LockPosition = false;

[Setting name="Enable Favorites" category=" Window" description="Enable the ability to favorite players and pin them to the top of the list."]
bool Setting_EnableFavorites = true;

[Setting name="Ignore Spectators" category=" Players" description="Don't show players that are in spectator mode."]
bool Setting_IgnoreSpectators = true;

[Setting name="Use Team Colors" category=" Players" description="When in teams mode, give players the color of their team."]
bool Setting_UseTeamColors = true;

[Setting hidden]
float Setting_Height = 285;

[Setting hidden]
float Setting_Width = 200;

[Setting hidden]
float Setting_PosX = 0;

[Setting hidden]
float Setting_PosY = 75;

[Setting hidden]
bool Setting_FirstTimeUse = true;

bool _joinedServer = false;

bool IsSpectating() {
    auto api = GetApp().CurrentPlayground.Interface.ManialinkScriptHandler;

    return api.IsSpectator || api.IsSpectatorClient;
}

void RenderMenu() {
    if (UI::MenuItem("\\$f00" + Icons::Users + "\\$z Too Many Players", "", Setting_Visible)) {
        Setting_Visible = !Setting_Visible;
    }
}

void Render() {
    auto app = GetApp();

    if (app.CurrentPlayground !is null && app.Network.IsMultiInternet) {
        if (Setting_OnlyInSpec && !IsSpectating()) return;

        widgetWindow.Render();

        _joinedServer = true;
    } else {
        _joinedServer = false;
    }
}

void Main() {}
