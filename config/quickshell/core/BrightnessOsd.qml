import QtQuick
import Quickshell
import qs.core

pragma ComponentBehavior: Bound

// Overlay OSD for brightness feedback, shown via `quickshell ipc call osd showBrightness`.
// Uses PopupWindow (override-redirect on X11) so dwm never manages/tiles it:
// always on top, zero impact on the tiling layout.
PopupWindow {
    id: root

    required property var panelWindow

    property int value: 0
    property string subtitle: "Brillo"
    property bool shown: false

    readonly property int osdWidth: Theme.scaledSize(220)
    readonly property int osdHeight: Theme.scaledSize(64)
    readonly property int topOffset: Theme.scaledSize(80)

    function show(valuePercent, subtitleText) {
        if (!root.panelWindow) return;
        const clamped = Math.max(0, Math.min(100, Math.round(valuePercent)));
        root.value = clamped;
        root.subtitle = subtitleText && subtitleText.length > 0 ? subtitleText : "Brillo";
        root.shown = true;
        hideTimer.restart();
    }

    visible: shown
    color: Theme.transparent
    mask: Region {}
    implicitWidth: osdWidth
    implicitHeight: osdHeight

    anchor.window: root.panelWindow
    anchor.rect.x: Math.round((root.panelWindow.width - root.osdWidth) / 2)
    anchor.rect.y: Theme.panelHeight + root.topOffset
    // Fedora Quickshell qmltypes omit Edges::Flags. Keep these valid runtime flags.
    anchor.edges: Edges.Left | Edges.Top // qmllint disable missing-type
    anchor.gravity: Edges.Right | Edges.Bottom // qmllint disable missing-type

    Timer {
        id: hideTimer

        interval: 1500
        onTriggered: root.shown = false
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: root.osdWidth
        height: root.osdHeight

        color: Theme.bg
        border.color: Theme.borderStrong
        border.width: 1
        radius: Theme.scaledSize(10)
        opacity: root.shown ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: root.shown ? 120 : 260
                easing.type: Easing.OutCubic
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingLg

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰃟"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.scaledSize(22)
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingXs

                Text {
                    anchors.left: parent.left
                    text: root.value + "%"
                    color: Theme.textStrong
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.scaledSize(15)
                    font.bold: true
                }

                Text {
                    anchors.left: parent.left
                    text: root.subtitle
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.scaledSize(10)
                }
            }
        }

        // Progress track along the bottom edge of the card.
        Rectangle {
            id: track

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: Theme.spacingMd
            }

            height: Theme.spacingXs
            radius: height / 2
            color: Theme.surface

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * root.value / 100
                radius: height / 2
                color: Theme.accent
            }
        }
    }
}
