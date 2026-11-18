import QtQuick
import QtQuick.Layouts
import "theme"
import "controls"
import "state"
import "views"
import "WallezKit"

Rectangle {
    id: root

    width: 1024
    height: 720
    color: theme.bgSurface

    Theme {
        id: theme
    }

    Provider {
        id: wallet
        dappName: "Logos Governance"
        dappIcon: Qt.resolvedUrl("assets/daoLogo.png")
        requestedGrants: ["IdentityRead", "IdentityPropose"]
    }

    DaoBridge {
        id: bridge
        provider: wallet
    }

    DaoStore {
        id: store
        bridge: bridge
    }

    ConnectModal {
        id: connectModal
        provider: wallet
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: theme.spacingLarge
        spacing: theme.spacingMedium

        // TOP APPLICATION HEADER
        Item {
            Layout.fillWidth: true
            implicitHeight: 44

            RowLayout {
                anchors.fill: parent
                spacing: theme.spacingMedium

                Text {
                    text: "Logos DAO Governance"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.subtitleText
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                // Connection Area: Official WallezKit ConnectButton
                ConnectButton {
                    provider: wallet
                    connectModal: connectModal
                }
            }
        }

        // Horizontal line separator under header
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // MAIN CHAMBER SPLIT VIEW
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: theme.spacingLarge

            // Left: Proposals List
            ProposalListView {
                Layout.preferredWidth: 280
                Layout.fillHeight: true
                store: store
                theme: theme
            }

            // Vertical line separator between list and detail
            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: theme.borderSubtle
            }

            // Right: Proposal Detail & Voting Chamber
            ProposalDetailView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                store: store
                bridge: bridge
                theme: theme
            }
        }
    }
}
