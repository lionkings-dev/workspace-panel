pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io



Singleton {
  id: root
  property ListModel workspaces: ListModel {}
  signal workspaceChanged
  function send(sock, request) {
    sock.write(JSON.stringify(request) + "\n");
    sock.flush();
  }
  function setWorkspaces(wsList) {
    workspaces.clear();
    for (const ws of wsList) {
      workspaces.append({
        id: ws.id,
        idx: ws.idx,
        name: ws.name || "",
        output: ws.output || "",
        isFocused: ws.is_focused === true,
        isActive: ws.is_active === true,
        isUrgent: ws.is_urgent === true,
        isOccupied: !!ws.active_window_id
      });
    }
    workspaceChanged();
  }
  Component.onCompleted: {
    cmd.connected = true;
    ev.connected = true;
    send(ev, "EventStream");   // subscribe
    send(cmd, "Workspaces");   // initial snapshot
  }
  Socket {
    id: cmd
    path: Quickshell.env("NIRI_SOCKET")
    parser: SplitParser {
      onRead: function(line) {
        try {
          const msg = JSON.parse(line);
          if (msg?.Ok?.Workspaces) root.setWorkspaces(msg.Ok.Workspaces);
        } catch (_) {}
      }
    }
  }
  Socket {
    id: ev
    path: Quickshell.env("NIRI_SOCKET")
    parser: SplitParser {
      onRead: function(line) {
        try {
          const event = JSON.parse(line.trim());
          if (event.WorkspacesChanged) {
            root.setWorkspaces(event.WorkspacesChanged.workspaces);
          }
        } catch (_) {}
      }
    }
  }
  function focusWorkspace(ws) {
    Quickshell.execDetached([
      "niri", "msg", "action", "focus-workspace", ws.idx.toString()
    ]);
  }
}


