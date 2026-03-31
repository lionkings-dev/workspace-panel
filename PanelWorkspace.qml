import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services.Compositor

Item {
  id: root

  property bool shown: true
  property string edge: "left"
  property var screen: null

  property int showAnimationMs: Style.animationNormal
  property int hideAnimationMs: Style.animationFast
  property real slideDistance: Math.max(10, Math.round(Style.marginL * 1.2))
  property real hiddenScale: 0.9
  property bool showBorder: true
  property int borderWidth: 1
  property string borderColorKey: "outline"
  property string workspaceDisplayMode: "index"
  property bool useCustomWorkspaceColor: false
  property string workspaceColorKey: "primary"

  property bool mounted: false
  property bool revealed: false
  property bool panelHovered: false
  property int lastFocusedWorkspaceId: -1
  property real masterProgress: 0.0
  property bool effectsActive: false

  readonly property bool vertical: root.edge === "left" || root.edge === "right"
  readonly property string screenName: root.screen?.name || ""
  readonly property real capsuleHeight: screenName ? Style.getCapsuleHeightForScreen(screenName) : Style.capsuleHeight
  readonly property real barHeight: screenName ? Style.getBarHeightForScreen(screenName) : Style.barHeight
  readonly property real barFontSize: screenName ? Style.getBarFontSizeForScreen(screenName) : Style.barFontSize

  readonly property real panelPadding: Style.marginXS
  readonly property real panelSpacing: Style.marginXS
  readonly property real pillCross: barHeight
  readonly property real pillBase: Style.toOdd(Math.max(15, Math.round(capsuleHeight * 0.74)))
  readonly property color focusedColor: useCustomWorkspaceColor ? Color.resolveColorKey(workspaceColorKey) : Color.mPrimary
  readonly property color focusedOnColor: useCustomWorkspaceColor ? Color.resolveOnColorKey(workspaceColorKey) : Color.mOnPrimary

  function workspaceLabel(idx, nameText) {
    if (workspaceDisplayMode === "none")
      return "";
    if (workspaceDisplayMode === "name")
      return (nameText && nameText.length > 0) ? nameText : idx.toString();
    return idx.toString();
  }

  property ListModel localWorkspaces: ListModel {}

  function screenMatchesWorkspace(ws) {
    if (!ws)
      return false;

    if (CompositorService.globalWorkspaces)
      return true;

    if (!root.screen || !root.screen.name)
      return false;

    if (!ws.output)
      return true;

    return ws.output.toLowerCase() === root.screen.name.toLowerCase();
  }

  function refreshWorkspaces() {
    localWorkspaces.clear();

    const allWorkspaces = CompositorService.workspaces;
    if (!allWorkspaces)
      return;

    for (var i = 0; i < allWorkspaces.count; i++) {
      const ws = allWorkspaces.get(i);
      if (!screenMatchesWorkspace(ws))
        continue;

      localWorkspaces.append({
        wsId: ws.id,
        idx: ws.idx,
        name: ws.name || "",
        output: ws.output || "",
        isFocused: ws.isFocused === true,
        isActive: ws.isActive === true,
        isUrgent: ws.isUrgent === true,
        isOccupied: ws.isOccupied === true
      });
    }

    updateFocusEffects();
  }

  function updateFocusEffects() {
    for (var i = 0; i < localWorkspaces.count; i++) {
      const ws = localWorkspaces.get(i);
      if (ws.isFocused !== true)
        continue;

      if (root.lastFocusedWorkspaceId !== -1 && root.lastFocusedWorkspaceId !== ws.wsId)
        focusBurstAnimation.restart();

      root.lastFocusedWorkspaceId = ws.wsId;
      return;
    }
  }

  function switchWorkspaceById(workspaceId) {
    for (var i = 0; i < CompositorService.workspaces.count; i++) {
      const ws = CompositorService.workspaces.get(i);
      if (ws && ws.id == workspaceId) {
        CompositorService.switchToWorkspace(ws);
        return;
      }
    }
  }

  function showAnimated() {
    hideFinalizeTimer.stop();
    mounted = true;
    revealed = true;
  }

  function hideAnimated() {
    revealed = false;
    hideFinalizeTimer.restart();
  }

  onShownChanged: {
    if (shown) {
      showAnimated();
    } else {
      hideAnimated();
    }
  }

  onScreenChanged: refreshWorkspaces()

  Component.onCompleted: {
    mounted = shown;
    revealed = shown;
    refreshWorkspaces();
  }

  Timer {
    id: hideFinalizeTimer
    interval: root.hideAnimationMs + 50
    repeat: false
    onTriggered: {
      if (!root.shown) {
        root.panelHovered = false;
        root.mounted = false;
      }
    }
  }

  Connections {
    target: CompositorService
    function onWorkspaceChanged() {
      root.refreshWorkspaces();
    }
    function onWorkspacesChanged() {
      root.refreshWorkspaces();
    }
  }

  PanelWindow {
    id: workspaceBar

    visible: root.mounted && root.screen !== null && root.localWorkspaces.count > 0
    focusable: false
    aboveWindows: true
    color: "transparent"
    screen: root.screen
    implicitWidth: root.vertical ? Math.max(44, panelCard.implicitWidth) : Math.max(120, panelCard.implicitWidth)
    implicitHeight: root.vertical ? Math.max(120, panelCard.implicitHeight) : Math.max(44, panelCard.implicitHeight)

    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
      left: root.edge === "left"
      right: root.edge === "right"
      top: root.edge === "top" || root.edge === "left" || root.edge === "right"
      bottom: root.edge === "bottom" || root.edge === "left" || root.edge === "right"
    }

    margins {
      left: 5
      right: 5
      top: 5
      bottom: 5
    }

    Item {
      id: animatedContainer
      width: parent.width
      height: parent.height
      opacity: root.revealed ? 1 : 0
      scale: root.revealed ? 1 : root.hiddenScale

      property real hiddenOffsetX: root.edge === "left" ? -root.slideDistance : (root.edge === "right" ? root.slideDistance : 0)
      property real hiddenOffsetY: root.edge === "top" ? -root.slideDistance : (root.edge === "bottom" ? root.slideDistance : 0)

      x: root.revealed ? 0 : hiddenOffsetX
      y: root.revealed ? 0 : hiddenOffsetY

      Behavior on x {
        NumberAnimation {
          duration: root.revealed ? root.showAnimationMs : root.hideAnimationMs
          easing.type: root.revealed ? Easing.OutBack : Easing.InQuad
          easing.overshoot: root.revealed ? 1.02 : 0
        }
      }

      Behavior on y {
        NumberAnimation {
          duration: root.revealed ? root.showAnimationMs : root.hideAnimationMs
          easing.type: root.revealed ? Easing.OutBack : Easing.InQuad
          easing.overshoot: root.revealed ? 1.02 : 0
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: root.revealed ? root.showAnimationMs : root.hideAnimationMs
          easing.type: Easing.InOutQuad
        }
      }

      Behavior on scale {
        NumberAnimation {
          duration: root.revealed ? root.showAnimationMs : root.hideAnimationMs
          easing.type: root.revealed ? Easing.OutBack : Easing.InQuad
          easing.overshoot: root.revealed ? 1.03 : 0
        }
      }

      Rectangle {
        id: panelCard
        anchors.centerIn: parent
        implicitWidth: (root.vertical ? columnLayout.implicitWidth : rowLayout.implicitWidth) + root.panelPadding * 2
        implicitHeight: (root.vertical ? columnLayout.implicitHeight : rowLayout.implicitHeight) + root.panelPadding * 2
        color: Qt.alpha(Color.mSurface, 0.82)
        radius: Style.radiusM
        border.color: showBorder ? Qt.alpha(Color.resolveColorKey(borderColorKey), 0.85) : "transparent"
        border.width: showBorder ? Math.max(0, borderWidth) : 0

        Behavior on color {
          enabled: !Color.isTransitioning
          ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.InOutQuad
          }
        }

        ColumnLayout {
          id: columnLayout
          visible: root.vertical
          spacing: root.panelSpacing
          anchors.centerIn: parent

          Repeater {
            model: root.localWorkspaces

            delegate: Item {
              required property var wsId
              required property int idx
              required property string name
              required property bool isFocused
              required property bool isActive
              required property bool isUrgent
              required property bool isOccupied

              readonly property bool accent: isFocused || isActive

              width: root.pillCross
              height: pillVisual.height

              Rectangle {
                id: pillVisual
                width: root.pillBase
                height: accent ? Math.round(root.pillBase * 2.1) : root.pillBase
                x: Style.pixelAlignCenter(parent.width, width)
                y: 0
                radius: Style.radiusS
                color: {
                  if (pillMouseArea.containsMouse)
                    return Color.mHover;
                  if (isFocused)
                    return root.focusedColor;
                  if (isUrgent)
                    return Color.mError;
                  if (isOccupied)
                    return Color.mSecondary;
                  return Qt.alpha(Color.mSurfaceVariant, 0.35);
                }

                Behavior on height {
                  NumberAnimation {
                    duration: Style.animationNormal
                    easing.type: Easing.OutBack
                  }
                }

                Behavior on color {
                  enabled: !Color.isTransitioning
                  ColorAnimation {
                    duration: Style.animationFast
                    easing.type: Easing.InOutQuad
                  }
                }

                Text {
                  visible: root.workspaceDisplayMode !== "none"
                  anchors.centerIn: parent
                  text: root.workspaceLabel(idx, name)
                  color: {
                    if (pillMouseArea.containsMouse)
                      return Color.mOnHover;
                    if (isFocused)
                      return root.focusedOnColor;
                    if (isUrgent)
                      return Color.mOnError;
                    if (isOccupied)
                      return Color.mOnSecondary;
                    return Color.mOnSurfaceVariant;
                  }
                  font.family: Settings.data.ui.fontFixed
                  font.pixelSize: Math.max(9, Math.round(root.barFontSize * 0.95))
                  font.bold: true
                }

                Rectangle {
                  anchors.centerIn: parent
                  width: pillVisual.width + Math.round(16 * root.masterProgress)
                  height: pillVisual.height + Math.round(16 * root.masterProgress)
                  radius: Math.min(width, height) / 2
                  color: "transparent"
                  border.color: root.focusedColor
                  border.width: Math.max(1, Math.round(4 * (1.0 - root.masterProgress)))
                  opacity: (root.effectsActive && isFocused) ? (1.0 - root.masterProgress) * 0.65 : 0
                  visible: root.effectsActive && isFocused
                }
              }

              MouseArea {
                id: pillMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.switchWorkspaceById(wsId)
              }
            }
          }
        }

        RowLayout {
          id: rowLayout
          visible: !root.vertical
          spacing: root.panelSpacing
          anchors.centerIn: parent

          Repeater {
            model: root.localWorkspaces

            delegate: Item {
              required property var wsId
              required property int idx
              required property string name
              required property bool isFocused
              required property bool isActive
              required property bool isUrgent
              required property bool isOccupied

              readonly property bool accent: isFocused || isActive

              width: pillVisual.width
              height: root.pillCross

              Rectangle {
                id: pillVisual
                width: accent ? Math.round(root.pillBase * 2.1) : root.pillBase
                height: root.pillBase
                x: 0
                y: Style.pixelAlignCenter(parent.height, height)
                radius: Style.radiusS
                color: {
                  if (pillMouseArea.containsMouse)
                    return Color.mHover;
                  if (isFocused)
                    return root.focusedColor;
                  if (isUrgent)
                    return Color.mError;
                  if (isOccupied)
                    return Color.mSecondary;
                  return Qt.alpha(Color.mSurfaceVariant, 0.35);
                }

                Behavior on width {
                  NumberAnimation {
                    duration: Style.animationNormal
                    easing.type: Easing.OutBack
                  }
                }

                Behavior on color {
                  enabled: !Color.isTransitioning
                  ColorAnimation {
                    duration: Style.animationFast
                    easing.type: Easing.InOutQuad
                  }
                }

                Text {
                  visible: root.workspaceDisplayMode !== "none"
                  anchors.centerIn: parent
                  text: root.workspaceLabel(idx, name)
                  color: {
                    if (pillMouseArea.containsMouse)
                      return Color.mOnHover;
                    if (isFocused)
                      return root.focusedOnColor;
                    if (isUrgent)
                      return Color.mOnError;
                    if (isOccupied)
                      return Color.mOnSecondary;
                    return Color.mOnSurfaceVariant;
                  }
                  font.family: Settings.data.ui.fontFixed
                  font.pixelSize: Math.max(9, Math.round(root.barFontSize * 0.95))
                  font.bold: true
                }

                Rectangle {
                  anchors.centerIn: parent
                  width: pillVisual.width + Math.round(16 * root.masterProgress)
                  height: pillVisual.height + Math.round(16 * root.masterProgress)
                  radius: Math.min(width, height) / 2
                  color: "transparent"
                  border.color: root.focusedColor
                  border.width: Math.max(1, Math.round(4 * (1.0 - root.masterProgress)))
                  opacity: (root.effectsActive && isFocused) ? (1.0 - root.masterProgress) * 0.65 : 0
                  visible: root.effectsActive && isFocused
                }
              }

              MouseArea {
                id: pillMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.switchWorkspaceById(wsId)
              }
            }
          }
        }

        HoverHandler {
          id: panelHoverHandler
          acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
          onHoveredChanged: root.panelHovered = hovered
        }
      }
    }
  }

  SequentialAnimation {
    id: focusBurstAnimation
    PropertyAction {
      target: root
      property: "effectsActive"
      value: true
    }
    NumberAnimation {
      target: root
      property: "masterProgress"
      from: 0
      to: 1
      duration: Style.animationSlow
      easing.type: Easing.OutQuint
    }
    PropertyAction {
      target: root
      property: "effectsActive"
      value: false
    }
    PropertyAction {
      target: root
      property: "masterProgress"
      value: 0
    }
  }
}
