bool _joinedServer = false;

void RenderMenu() {
    if (UI::MenuItem(" Too Many Players", "", widgetWindow._isOpen)) {
        widgetWindow._isOpen = !widgetWindow._isOpen;
    }
}

void Render() {
    auto app = GetApp();

    if (app.CurrentPlayground !is null) {
        widgetWindow.Render();

        if (!_joinedServer) {
            widgetWindow.UpdatePlayers();
        }

        _joinedServer = true;
    } else {
        _joinedServer = false;
    }
}

void Main() {
    
}