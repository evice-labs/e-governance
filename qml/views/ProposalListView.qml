import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Item {
    id: listViewRoot

    required property var store
    required property var theme

    ColumnLayout {
        anchors.fill: parent
        spacing: theme.spacingMedium

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: theme.spacingSmall

            Text {
                text: "Proposals"
                color: theme.textPrimary
                font.family: theme.fontFamily
                font.pixelSize: theme.panelTitleText
                font.weight: Font.Bold
                Layout.fillWidth: true
            }

            Text {
                text: store.proposals ? (store.proposals.length + " Active") : "0 Active"
                color: theme.textSecondary
                font.family: theme.fontMono
                font.pixelSize: theme.secondaryText
                font.weight: Font.DemiBold
            }
        }

        // 1px horizontal line separator
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // Proposal List
        ListView {
            id: proposalList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0
            model: store.proposals

            delegate: Item {
                id: itemDelegate
                width: proposalList.width
                implicitHeight: itemCol.implicitHeight + theme.spacingLarge

                readonly property bool isSelected: store.activeProposalIndex === index
                readonly property bool isVoted: store.hasVoted(modelData.id)

                Rectangle {
                    anchors.fill: parent
                    color: itemDelegate.isSelected ? theme.bgSurfaceElevated : (hoverArea.containsMouse ? theme.bgSurfaceSubtle : "transparent")
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        store.selectProposal(index);
                    }
                }

                ColumnLayout {
                    id: itemCol
                    anchors.fill: parent
                    anchors.margins: theme.spacingSmall
                    spacing: theme.spacingTiny

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: theme.spacingSmall

                        // ID: plain text with dot (e.g. "1.")
                        Text {
                            text: modelData.id + "."
                            color: theme.textPrimary
                            font.family: theme.fontMono
                            font.pixelSize: theme.primaryText
                            font.weight: Font.Bold
                        }

                        // Category: plain text secondary size
                        Text {
                            text: modelData.category
                            color: theme.textSecondary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.secondaryText
                            font.weight: Font.Medium
                        }

                        Item { Layout.fillWidth: true }

                        // Voted Indicator: plain text secondary size
                        Text {
                            visible: itemDelegate.isVoted
                            text: "VOTED"
                            color: theme.statusSuccess
                            font.family: theme.fontMono
                            font.pixelSize: theme.secondaryText
                            font.weight: Font.Bold
                        }
                    }

                    // Title
                    Text {
                        text: modelData.title
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.primaryText
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                // 1px bottom divider line separating list items
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: theme.borderSubtle
                }
            }
        }
    }
}
