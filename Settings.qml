import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string editEdge: cfg.edge ?? defaults.edge ?? "left"
  property bool editAutoHide: cfg.autoHide ?? defaults.autoHide ?? true
  property bool editShowOnWorkspaceSwitch: cfg.showOnWorkspaceSwitch ?? defaults.showOnWorkspaceSwitch ?? true
  property int editShowDurationMs: cfg.showDurationMs ?? defaults.showDurationMs ?? 1200
  property int editShowAnimationMs: cfg.showAnimationMs ?? defaults.showAnimationMs ?? 150
  property int editHideAnimationMs: cfg.hideAnimationMs ?? defaults.hideAnimationMs ?? 150
  property int editSlideDistance: cfg.slideDistance ?? defaults.slideDistance ?? 16
  property real editHiddenScale: cfg.hiddenScale ?? defaults.hiddenScale ?? 0.9
  property bool editShowBorder: cfg.showBorder ?? defaults.showBorder ?? true
  property int editBorderWidth: cfg.borderWidth ?? defaults.borderWidth ?? 1
  property string editBorderColorKey: cfg.borderColorKey ?? defaults.borderColorKey ?? "outline"
  property string editWorkspaceDisplayMode: cfg.workspaceDisplayMode ?? defaults.workspaceDisplayMode ?? "index"
  property bool editUseCustomWorkspaceColor: cfg.useCustomWorkspaceColor ?? defaults.useCustomWorkspaceColor ?? false
  property string editWorkspaceColorKey: cfg.workspaceColorKey ?? defaults.workspaceColorKey ?? "primary"

  spacing: Style.marginL

  NComboBox {
    Layout.fillWidth: true
    label: "Panel Edge"
    description: "Attach workspace panel to this side"
    model: [{
        key: "left",
        name: "Left"
      }, {
        key: "right",
        name: "Right"
      }, {
        key: "top",
        name: "Top"
      }, {
        key: "bottom",
        name: "Bottom"
      }]
    currentKey: root.editEdge
    onSelected: key => root.editEdge = key
  }

  NToggle {
    Layout.fillWidth: true
    label: "Auto Hide"
    description: "Hide the panel after the timeout"
    checked: root.editAutoHide
    onToggled: checked => root.editAutoHide = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: "Show On Workspace Switch"
    description: "Only show when current workspace changes"
    checked: root.editShowOnWorkspaceSwitch
    onToggled: checked => root.editShowOnWorkspaceSwitch = checked
  }

  NDivider {
    Layout.fillWidth: true
  }

  NComboBox {
    Layout.fillWidth: true
    label: "Workspace Label"
    description: "How each workspace is displayed"
    model: [{
        key: "index",
        name: "Index"
      }, {
        key: "name",
        name: "Name"
      }, {
        key: "none",
        name: "None"
      }]
    currentKey: root.editWorkspaceDisplayMode
    onSelected: key => root.editWorkspaceDisplayMode = key
  }

  NToggle {
    Layout.fillWidth: true
    label: "Use Custom Workspace Color"
    description: "Use a fixed color for focused workspace pill"
    checked: root.editUseCustomWorkspaceColor
    onToggled: checked => root.editUseCustomWorkspaceColor = checked
  }

  NColorChoice {
    Layout.fillWidth: true
    label: "Workspace Color"
    description: "Focused workspace color"
    currentKey: root.editWorkspaceColorKey
    onSelected: key => root.editWorkspaceColorKey = key
    enabled: root.editUseCustomWorkspaceColor
  }

  NToggle {
    Layout.fillWidth: true
    label: "Show Border"
    description: "Show panel border"
    checked: root.editShowBorder
    onToggled: checked => root.editShowBorder = checked
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NLabel {
        label: "Border Width"
        description: root.editBorderWidth + " px"
      }

      NSlider {
        Layout.fillWidth: true
        from: 0
        to: 6
        stepSize: 1
        value: root.editBorderWidth
        onValueChanged: root.editBorderWidth = Math.round(value)
        enabled: root.editShowBorder
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NColorChoice {
        Layout.fillWidth: true
        label: "Border Color"
        description: "Color key for panel border"
        currentKey: root.editBorderColorKey
        onSelected: key => root.editBorderColorKey = key
        enabled: root.editShowBorder
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: "Visible Time"
      description: root.editShowDurationMs + " ms"
    }

    NSlider {
      Layout.fillWidth: true
      from: 250
      to: 5000
      stepSize: 50
      value: root.editShowDurationMs
      onValueChanged: root.editShowDurationMs = Math.round(value)
      enabled: root.editAutoHide
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NLabel {
        label: "Show Animation"
        description: root.editShowAnimationMs + " ms"
      }

      NSlider {
        Layout.fillWidth: true
        from: 50
        to: 1000
        stepSize: 10
        value: root.editShowAnimationMs
        onValueChanged: root.editShowAnimationMs = Math.round(value)
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NLabel {
        label: "Hide Animation"
        description: root.editHideAnimationMs + " ms"
      }

      NSlider {
        Layout.fillWidth: true
        from: 50
        to: 1000
        stepSize: 10
        value: root.editHideAnimationMs
        onValueChanged: root.editHideAnimationMs = Math.round(value)
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NLabel {
        label: "Slide Distance"
        description: root.editSlideDistance + " px"
      }

      NSlider {
        Layout.fillWidth: true
        from: 6
        to: 72
        stepSize: 1
        value: root.editSlideDistance
        onValueChanged: root.editSlideDistance = Math.round(value)
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NLabel {
        label: "Hidden Scale"
        description: Math.round(root.editHiddenScale * 100) + "%"
      }

      NSlider {
        Layout.fillWidth: true
        from: 0.70
        to: 0.98
        stepSize: 0.01
        value: root.editHiddenScale
        onValueChanged: root.editHiddenScale = value
      }
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;

    pluginApi.pluginSettings.edge = root.editEdge;
    pluginApi.pluginSettings.autoHide = root.editAutoHide;
    pluginApi.pluginSettings.showOnWorkspaceSwitch = root.editShowOnWorkspaceSwitch;
    pluginApi.pluginSettings.showDurationMs = root.editShowDurationMs;
    pluginApi.pluginSettings.showAnimationMs = root.editShowAnimationMs;
    pluginApi.pluginSettings.hideAnimationMs = root.editHideAnimationMs;
    pluginApi.pluginSettings.slideDistance = root.editSlideDistance;
    pluginApi.pluginSettings.hiddenScale = root.editHiddenScale;
    pluginApi.pluginSettings.showBorder = root.editShowBorder;
    pluginApi.pluginSettings.borderWidth = root.editBorderWidth;
    pluginApi.pluginSettings.borderColorKey = root.editBorderColorKey;
    pluginApi.pluginSettings.workspaceDisplayMode = root.editWorkspaceDisplayMode;
    pluginApi.pluginSettings.useCustomWorkspaceColor = root.editUseCustomWorkspaceColor;
    pluginApi.pluginSettings.workspaceColorKey = root.editWorkspaceColorKey;
    pluginApi.saveSettings();
  }
}
