import QtQuick
import Quickshell.Io
import qs.Services.UI

Item {
  property var pluginApi: null

  IpcHandler {
    target: "plugin:workspace-panel"
    function openPanel(screen: screen) {
      if(pluginApi && screen){
        pluginApi.openPanel(screen);
        ToastService.showNotice("open Panel")
      // Your handler logic here
    }
    function closePanel(screen: screen) {
      if(pluginApi && screen){
        pluginApi.closePanel(screen);
        ToastService.showNotice("Close Panel")
      // Your handler logic here
    }
  }
}
