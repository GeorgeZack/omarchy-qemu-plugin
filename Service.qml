import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var vms: []
  property bool busy: false
  readonly property string script: Quickshell.env("HOME") +
    "/.config/omarchy/plugins/dix.qemu/scripts/vm-status"
  readonly property int runningCount: {
    var count = 0
    for (var i = 0; i < vms.length; i++)
      if (vms[i].state === "running") count++
    return count
  }

  function refresh() {
    if (!statusProcess.running)
      statusProcess.running = true
  }

  function start(name) {
    if (busy) return
    busy = true
    actionProcess.command = ["virsh", "-c", "qemu:///system", "start", name]
    actionProcess.running = true
  }

  function stop(name) {
    if (busy) return
    busy = true
    actionProcess.command = ["virsh", "-c", "qemu:///system", "shutdown", name]
    actionProcess.running = true
  }

  function forceStop(name) {
    if (busy) return
    busy = true
    actionProcess.command = ["virsh", "-c", "qemu:///system", "destroy", name]
    actionProcess.running = true
  }
  
  function open(name) {
  Quickshell.execDetached(["virt-manager", "--connect", "qemu:///system",
    "--show-domain-console", name])
}

  Process {
    id: statusProcess
    command: [root.script]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
  var lines = text.split("\n")
  var list = []
  var vmMap = {}
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (line === "") continue
    var parts = line.split(/\s+/)
    var key = parts[0]
    if (key === "vm" && parts.length >= 3) {
      var state = parts[parts.length - 1]
      var name = parts.slice(1, parts.length - 1).join(" ")
      vmMap[name] = { name: name, state: state, ram: "", ramTotal: "", ip: "", disk: "", diskTotal: "" }
      list.push(name)
    } else if (key === "vm_ram" && parts.length >= 4) {
      var vmName = parts[1]
      if (vmMap[vmName]) {
        var ramMb = Math.round(parseInt(parts[2]) / 1024)
        var ramTotalMb = Math.round(parseInt(parts[3]) / 1024)
        vmMap[vmName].ram = ramMb
        vmMap[vmName].ramTotal = ramTotalMb
      }
    } else if (key === "vm_ip" && parts.length >= 3) {
      if (vmMap[parts[1]]) vmMap[parts[1]].ip = parts[2]
    } else if (key === "vm_disk" && parts.length >= 4) {
      if (vmMap[parts[1]]) {
        vmMap[parts[1]].disk = Math.round(parseInt(parts[2]) / 1073741824 * 10) / 10
        vmMap[parts[1]].diskTotal = Math.round(parseInt(parts[3]) / 1073741824 * 10) / 10
      }
    }
  }
  var result = []
  for (var j = 0; j < list.length; j++) result.push(vmMap[list[j]])
  root.vms = result
}
    }
    onExited: running = false
  }

  Process {
    id: actionProcess
    running: false
    stdout: StdioCollector { waitForEnd: true }
    onExited: function(exitCode) {
      running = false
      root.busy = false
      Qt.callLater(root.refresh)
    }
  }

  Timer {
    interval: 5000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
