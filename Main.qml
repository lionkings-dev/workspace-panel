import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Compositor

Item {
  id: root

  property var pluginApi: null

  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property bool shown: false
  property string edge: (cfg.edge ?? defaults.edge ?? "left")
  property var screen: null
  property bool autoHide: (cfg.autoHide ?? defaults.autoHide ?? true)
  property bool showOnWorkspaceSwitch: (cfg.showOnWorkspaceSwitch ?? defaults.showOnWorkspaceSwitch ?? true)
  property int showDurationMs: Math.max(250, (cfg.showDurationMs ?? defaults.showDurationMs ?? 1200))
  property int showAnimationMs: Math.max(50, (cfg.showAnimationMs ?? defaults.showAnimationMs ?? Style.animationFast))
  property int hideAnimationMs: Math.max(50, (cfg.hideAnimationMs ?? defaults.hideAnimationMs ?? Style.animationFast))
  property real slideDistance: Math.max(6, (cfg.slideDistance ?? defaults.slideDistance ?? Math.round(Style.marginL * 1.2)))
  property real hiddenScale: Math.max(0.7, Math.min(0.98, (cfg.hiddenScale ?? defaults.hiddenScale ?? 0.9)))
  property bool showBorder: (cfg.showBorder ?? defaults.showBorder ?? true)
  property int borderWidth: Math.max(0, Math.min(6, (cfg.borderWidth ?? defaults.borderWidth ?? 1)))
  property string borderColorKey: (cfg.borderColorKey ?? defaults.borderColorKey ?? "outline")
  property string workspaceDisplayMode: (cfg.workspaceDisplayMode ?? defaults.workspaceDisplayMode ?? "index")
  property bool useCustomWorkspaceColor: (cfg.useCustomWorkspaceColor ?? defaults.useCustomWorkspaceColor ?? false)
  property string workspaceColorKey: (cfg.workspaceColorKey ?? defaults.workspaceColorKey ?? "primary")
  property bool panelHovered: false
  property var lastWorkspaceId: null

  function screenForOutput(outputName) {
    if (!outputName)
      return null;

    const needle = outputName.toString().toLowerCase();
    const screens = Quickshell.screens || [];
    for (var i = 0; i < screens.length; i++) {
      const candidate = screens[i];
      if (!candidate || !candidate.name)
        continue;
      if (candidate.name.toLowerCase() === needle)
        return candidate;
    }

    return null;
  }

  function showOnScreen(targetScreen) {
    if (!targetScreen)
      return;

    root.screen = targetScreen;
    root.shown = true;

    if (root.autoHide) {
      hideTimer.restart();
    }
  }

  function handleWorkspaceChanged() {
    if (!root.showOnWorkspaceSwitch)
      return;

    const ws = CompositorService.getCurrentWorkspace();
    if (!ws || ws.id === undefined || ws.id === null)
      return;

    if (ws.id === root.lastWorkspaceId)
      return;

    root.lastWorkspaceId = ws.id;

    const screenFromOutput = root.screenForOutput(ws.output);
    if (screenFromOutput) {
      root.showOnScreen(screenFromOutput);
      return;
    }

    root.withScreen(currentScreen => {
      root.showOnScreen(currentScreen);
    });
  }

  function withScreen(callback) {
    if (!pluginApi || !pluginApi.withCurrentScreen) {
      const fallbackScreen = Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
      if (fallbackScreen)
        callback(fallbackScreen);
      return;
    }

    if (screen) {
      callback(screen);
      return;
    }

    pluginApi.withCurrentScreen(currentScreen => {
      screen = currentScreen;
      callback(currentScreen);
    });
  }

  Component.onCompleted: {
    const ws = CompositorService.getCurrentWorkspace();
    if (ws && ws.id !== undefined && ws.id !== null)
      root.lastWorkspaceId = ws.id;
  }

  IpcHandler {
    target: "plugin:workspace-panel"

    function togglePanel() {
      if (!pluginApi) return;

      root.withScreen(currentScreen => {
        root.screen = currentScreen;
        root.shown = !root.shown;
        if (root.shown && root.autoHide)
          hideTimer.restart();
      });
    }
  }

  Timer {
    id: hideTimer
    interval: root.showDurationMs
    repeat: false
    onTriggered: {
      if (root.autoHide && !root.panelHovered)
        root.shown = false;
    }
  }

  Connections {
    target: CompositorService
    function onWorkspaceChanged() {
      root.handleWorkspaceChanged();
    }
  }

  PanelWorkspace {
    id: panel
    shown: root.shown
    edge: root.edge
    screen: root.screen
    showAnimationMs: root.showAnimationMs
    hideAnimationMs: root.hideAnimationMs
    slideDistance: root.slideDistance
    hiddenScale: root.hiddenScale
    showBorder: root.showBorder
    borderWidth: root.borderWidth
    borderColorKey: root.borderColorKey
    workspaceDisplayMode: root.workspaceDisplayMode
    useCustomWorkspaceColor: root.useCustomWorkspaceColor
    workspaceColorKey: root.workspaceColorKey
  }

  Connections {
    target: panel
    function onPanelHoveredChanged() {
      root.panelHovered = panel.panelHovered;
      if (!root.autoHide || !root.shown)
        return;

      if (panel.panelHovered)
        hideTimer.stop();
      else
        hideTimer.restart();
    }
  }

}
