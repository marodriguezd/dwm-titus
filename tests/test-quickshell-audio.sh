#!/bin/sh
set -eu

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "$0")/.." && pwd
)
model=$repo/config/quickshell/controls/ControlsModel.qml
pane=$repo/config/quickshell/settings/AudioSettingsPane.qml
settings=$repo/config/quickshell/settings/SettingsModel.qml
shell=$repo/config/quickshell/shell.qml

grep -Fq 'property int audioSourceGeneration: 0' "$model"
grep -Fq 'readonly property bool useNativeAudioProvider: false' "$model"
grep -Fq 'property int mutationGeneration: 0' "$model"
grep -Fq 'property int appliedMutationGeneration: 0' "$model"
grep -Fq 'root.actionProcessGeneration !== root.mutationGeneration' "$model"
grep -Fq 'property string mutationOrigin: ""' "$model"
grep -Fq 'interval: 3000' "$model"
grep -Fq 'repeat: false' "$model"
grep -Fq 'root.fallbackProcessGeneration === root.audioSourceGeneration' "$model"
grep -Fq 'fallbackRestartTimer.restart()' "$model"
grep -Fq 'if (fallbackWatchProcess.running) fallbackWatchProcess.running = false;' "$model"
[ "$(grep -Fc 'Commands.controlsHelperCommand("audio-watch")' "$model")" -eq 1 ]
audio_provider=$(sed -n '/id: nativeGraceTimer/,/id: volumeStatusProcess/p' "$model")
if printf '%s\n' "$audio_provider" | grep -Fq 'repeat: true'; then
	exit 1
fi
grep -Fq 'function parseAudioSnapshot(text)' "$model"
grep -Fq 'fields[3] !== "yes" && fields[3] !== "no"' "$model"
grep -Fq 'fields[4] !== "yes" && fields[4] !== "no"' "$model"
grep -Fq 'function inputSetDefault(name, origin)' "$model"
grep -Fq 'function streamVolumeSet(index, percent, origin)' "$model"
grep -Fq 'property int pendingVolumePercent: -1' "$model"
grep -Fq 'root.pendingVolumePercent = target' "$model"
grep -Fq 'if (!volumeDragTimer.running) volumeDragTimer.start();' "$repo/config/quickshell/controls/ControlsWindow.qml"
grep -Fq 'interval: 100' "$repo/config/quickshell/controls/ControlsWindow.qml"
grep -A2 -F 'id: volumeDragTimer' "$repo/config/quickshell/controls/ControlsWindow.qml" | grep -Fq 'repeat: true'
grep -Fq 'enabled: !root.controlsModel.busy || dragging' "$repo/config/quickshell/controls/ControlsWindow.qml"
grep -Fq 'property var controlsModel: null' "$settings"
grep -Fq 'root.controlsModel.openSettings()' "$settings"
grep -Fq 'root.controlsModel.closeSettings()' "$settings"
grep -Fq 'controlsModel: controlsModel' "$shell"
grep -Fq 'root.controlsModel.inputSetDefault' "$pane"
grep -Fq 'root.controlsModel.inputToggleMute' "$pane"
grep -Fq 'root.controlsModel.streamVolumeSet' "$pane"
grep -Fq 'root.controlsModel.streamToggleMute' "$pane"

printf 'Quickshell audio provider and Settings contract: PASS\n'
