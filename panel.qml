import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  // Plugin API (injected by PluginPanelSlot)
  property var pluginApi: null

  // SmartPanel properties (required for panel behavior)
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  // Preferred dimensions
  property real contentPreferredWidth: 680 * Style.uiScaleRatio
  property real contentPreferredHeight: 540 * Style.uiScaleRatio

  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    // Your panel content here
    ColumnLayout {
      anchors {
        fill: parent
        margins: Style.marginL
      }
      spacing: Style.marginL

      // Header
      NText {
        text: "Panel Title"
        pointSize: Style.fontSizeL
        font.weight: Font.Bold
        color: Color.mOnSurface
      }

      // Content area
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        radius: Style.radiusL

        // Your content here
      }

      // Footer or actions
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NButton {
          text: "Action"
          onClicked: {
            // Handle action
          }
        }
      }
    }
  }
}
