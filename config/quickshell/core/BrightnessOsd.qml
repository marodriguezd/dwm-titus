import QtQuick
import Quickshell
import qs.core

pragma ComponentBehavior: Bound

// Overlay OSD for brightness feedback, shown via `quickshell ipc call osd showBrightness`.
// Floating centered near the bottom; never grabs focus or input.
PanelWindow {
    id: root

    required property var modelData

    readonly property int osdWidth: Theme.scaledSize(220)
    readonly property int osdHeight: Theme.scaledSize(64)
    readonly property int bottomMargin: Theme.scaledSize(90)

    function show(valuePercent, subtitleText) {
        const clamped = Math.max(0, Math.min(100, Math.round(valuePercent)));
        root.value = clamped;
        root.subtitle = subtitleText && subtitleText.length > 0 ? subtitleText : "Brillo";
        root.visibleState = true;
        hideTimer.restart();
    }

    property int value: 0
    property string subtitle: "Brillo"
    property bool visibleState: false

    screen: modelData
    visible: visibleState
    color: "transparent"

    anchors {
        top: false
        bottom: true
        left: true
        right: true
    }

    margins {
        bottom: bottomMargin
    }

    exclusionMode: ExclusionMode.Ignore

    // Empty input region: fully click-through.
    mask: Region {}

    Timer {
        id: hideTimer

        interval: 1500
        onTriggered: root.visibleState = false
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
        opacity: root.visibleState ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: root.visibleState ? 120 : 260
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
