void RenderMenu() {
    if (UI::MenuItem(" Too Many Players", "", widgetWindow._isOpen)) {
        widgetWindow._isOpen = !widgetWindow._isOpen;
    }
}

void Render() {
    auto app = GetApp();

    if (app.CurrentPlayground !is null) {
        widgetWindow.Render();
    }
}

void Main() {
    

    /* for (int i = 0; i < pg.Players.Length; i++) {
        CGamePlayer@ player = pg.Players[i];
        print(player.User.Name);
    } */
}