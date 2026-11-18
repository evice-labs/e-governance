import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Item {
    id: detailRoot

    required property var store
    required property var bridge
    required property var theme

    property string selectedOption: "YES" // "YES" | "NO" | "ABSTAIN"
    property string activeNullifierPreview: ""

    readonly property var prop: store.activeProposal
    readonly property bool hasVotedCurrent: prop ? store.hasVoted(prop.id) : false
    readonly property var castData: prop ? store.getCastBallot(prop.id) : null

    onPropChanged: {
        updateNullifierPreview();
    }

    Connections {
        target: bridge
        function onCommitmentLoaded(c) {
            updateNullifierPreview();
        }
    }

    function updateNullifierPreview() {
        if (!prop || !bridge.isConnected) {
            activeNullifierPreview = "";
            return;
        }
        bridge.deriveNullifier(prop.id, function (res) {
            if (res && res.ok && res.nullifier) {
                activeNullifierPreview = res.nullifier;
            } else {
                activeNullifierPreview = "0x" + prop.id + "000000000000000000000000000000000000000000000000000000000000";
            }
        });
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: theme.spacingMedium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: theme.spacingSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: theme.spacingSmall

                // panelTitleText
                Text {
                    text: prop ? (prop.id + ".") : "-."
                    color: theme.textPrimary
                    font.family: theme.fontMono
                    font.pixelSize: theme.panelTitleText
                    font.weight: Font.Bold
                }

                // panelTitleText
                Text {
                    text: prop ? prop.title : "Select a Proposal"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.panelTitleText
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: prop ? prop.status.toUpperCase() : "PENDING"
                    color: (prop && prop.status === "Active") ? theme.statusSuccess : theme.textSecondary
                    font.family: theme.fontMono
                    font.pixelSize: theme.subtitleText
                    font.weight: Font.Bold
                }
            }

            // Subtitle: Category & Proposer
            RowLayout {
                Layout.fillWidth: true
                spacing: theme.spacingSmall

                Text {
                    text: "Category: " + (prop ? prop.category : "-")
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.secondaryText
                    font.weight: Font.Medium
                }

                Text {
                    text: "•"
                    color: theme.textMuted
                    font.pixelSize: theme.secondaryText
                }

                Text {
                    text: "Proposer: " + (prop ? prop.proposer : "-")
                    color: theme.textSecondary
                    font.family: theme.fontMono
                    font.pixelSize: theme.secondaryText
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: theme.spacingLarge

            ColumnLayout {
                Layout.preferredWidth: 300
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: theme.spacingSmall

                Text {
                    text: "Description"
                    color: theme.textMuted
                    font.family: theme.fontFamily
                    font.pixelSize: theme.secondaryText
                    font.weight: Font.Bold
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: descText.implicitHeight
                    clip: true

                    // Proposal Description Body
                    Text {
                        id: descText
                        width: parent.width
                        text: prop ? prop.description : "No proposal selected."
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.secondaryText
                        lineHeight: 1.4
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: theme.borderSubtle
            }

            ColumnLayout {
                Layout.preferredWidth: 360
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: theme.spacingMedium

                // Part A: QUORUM & TALLY METRICS
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: theme.spacingSmall

                    Text {
                        text: "Quorum & Tally Metrics"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.subtitleText
                        font.weight: Font.Bold
                    }

                    // Quorum Progress
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: theme.spacingTiny

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Quorum Progress"
                                color: theme.textSecondary
                                font.family: theme.fontFamily
                                font.pixelSize: theme.secondaryText
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: prop ? (Math.round((prop.totalVotes / prop.quorumRequired) * 100) + "%") : "0%"
                                color: theme.textPrimary
                                font.family: theme.fontMono
                                font.pixelSize: theme.secondaryText
                                font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 6
                            radius: theme.radiusTiny
                            color: theme.bgInsetTrough

                            Rectangle {
                                width: parent.width * Math.min(1.0, prop ? (prop.totalVotes / prop.quorumRequired) : 0)
                                height: parent.height
                                radius: theme.radiusTiny
                                color: theme.btnPrimaryTop
                            }
                        }

                        Text {
                            text: prop ? (prop.totalVotes.toLocaleString() + " / " + prop.quorumRequired.toLocaleString() + " LGO") : "-"
                            color: theme.textMuted
                            font.family: theme.fontMono
                            font.pixelSize: theme.badgeText
                        }
                    }

                    // Vote Tally
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: theme.spacingTiny

                        Text {
                            text: "Vote Tally"
                            color: theme.textSecondary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.secondaryText
                        }

                        RowLayout {
                            spacing: theme.spacingMedium

                            Text {
                                text: "YES: " + (prop ? prop.yesVotes.toLocaleString() : "0")
                                color: theme.statusSuccess
                                font.family: theme.fontMono
                                font.pixelSize: theme.primaryText
                                font.weight: Font.Bold
                            }
                            Text {
                                text: "NO: " + (prop ? prop.noVotes.toLocaleString() : "0")
                                color: theme.statusDanger
                                font.family: theme.fontMono
                                font.pixelSize: theme.primaryText
                                font.weight: Font.Bold
                            }
                            Text {
                                text: "ABS: " + (prop ? prop.abstainVotes.toLocaleString() : "0")
                                color: theme.textMuted
                                font.family: theme.fontMono
                                font.pixelSize: theme.primaryText
                            }
                        }
                    }
                }

                // 1px horizontal line separator
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: theme.borderSubtle
                }

                // Part B: IDENTITY ACCOUNTABILITY (ZK PROOF & SCOPED NULLIFIER)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: theme.spacingSmall

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: theme.spacingSmall

                        Text {
                            text: "Identity Accountability (Domain 6)"
                            color: theme.textPrimary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.subtitleText
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "ZK CITIZEN"
                            color: bridge.voterCommitment ? theme.statusShielded : theme.textMuted
                            font.family: theme.fontMono
                            font.pixelSize: theme.secondaryText
                            font.weight: Font.Bold
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "Unlinkable Per Proposal"
                            color: theme.textMuted
                            font.family: theme.fontFamily
                            font.pixelSize: theme.badgeText
                        }
                    }

                    // Master Commitment Readout
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: theme.spacingSmall

                        Text {
                            text: "Master Commitment:"
                            color: theme.textMuted
                            font.family: theme.fontMono
                            font.pixelSize: theme.secondaryText
                        }

                        Text {
                            text: bridge.voterCommitment ? bridge.voterCommitment : "Awaiting Wallet Provider SDK Handshake..."
                            color: bridge.voterCommitment ? theme.textPrimary : theme.textMuted
                            font.family: theme.fontMono
                            font.pixelSize: theme.secondaryText
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }

                    // Scoped Nullifier Readout
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: theme.spacingSmall

                        Text {
                            text: "Scoped Nullifier:"
                            color: theme.textMuted
                            font.family: theme.fontMono
                            font.pixelSize: theme.secondaryText
                        }

                        Text {
                            text: (hasVotedCurrent && castData) ? castData.nullifier : (activeNullifierPreview || "Deriving...")
                            color: theme.textPrimary
                            font.family: theme.fontMono
                            font.pixelSize: theme.secondaryText
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }
                }

                // 1px horizontal line separator
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: theme.borderSubtle
                }

                // Part C: VOTING BALLOT / RESULTS CONTAINER
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // STATE A: ALREADY VOTED ON THIS PROPOSAL
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: theme.spacingSmall
                        visible: hasVotedCurrent

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: theme.spacingSmall

                            Text {
                                text: "✓"
                                color: theme.statusSuccess
                                font.family: theme.fontFamily
                                font.pixelSize: theme.subtitleText
                                font.weight: Font.Bold
                            }

                            Text {
                                text: "Ballot Confirmed On-Chain (Option: " + (castData ? castData.option : "-") + ")"
                                color: theme.statusSuccess
                                font.family: theme.fontFamily
                                font.pixelSize: theme.subtitleText
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            text: "Your cryptographic vote has been permanently anchored to the LEZ State Tree. Because scoped nullifiers enforce strict Sybil resistance, you cannot cast a second ballot on Proposal " + (prop ? prop.id : "-") + "."
                            color: theme.textSecondary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.secondaryText
                            lineHeight: 1.4
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // Proof Receipt Data
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: theme.spacingTiny

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "BIP-340 Schnorr Sig:"; color: theme.textMuted; font.family: theme.fontMono; font.pixelSize: theme.secondaryText }
                                Text { text: castData ? castData.signature : "-"; color: theme.textPrimary; font.family: theme.fontMono; font.pixelSize: theme.secondaryText; elide: Text.ElideMiddle; Layout.fillWidth: true }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Sequencer Tx:"; color: theme.textMuted; font.family: theme.fontMono; font.pixelSize: theme.secondaryText }
                                Text { text: castData ? castData.txHash : "-"; color: theme.textPrimary; font.family: theme.fontMono; font.pixelSize: theme.secondaryText; elide: Text.ElideMiddle; Layout.fillWidth: true }
                            }
                        }
                    }

                    // STATE B: ACTIVE VOTING FORM
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: theme.spacingMedium
                        visible: !hasVotedCurrent

                        Text {
                            text: "Cast Anonymous Ballot"
                            color: theme.textPrimary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.subtitleText
                            font.weight: Font.Bold
                        }

                        // Choice Buttons Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: theme.spacingSmall

                            Repeater {
                                model: [
                                    { label: "YES", activeBg: Qt.rgba(0.0, 0.9, 0.46, 0.15), activeBorder: theme.statusSuccess, activeText: theme.statusSuccess, inactiveText: theme.textPrimary, weight: Font.Bold },
                                    { label: "NO", activeBg: Qt.rgba(0.94, 0.27, 0.27, 0.15), activeBorder: theme.statusDanger, activeText: theme.statusDanger, inactiveText: theme.textPrimary, weight: Font.Bold },
                                    { label: "ABSTAIN", activeBg: Qt.rgba(1.0, 1.0, 1.0, 0.12), activeBorder: theme.textSecondary, activeText: theme.textPrimary, inactiveText: theme.textMuted, weight: Font.Medium }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool isSel: detailRoot.selectedOption === modelData.label
                                    Layout.fillWidth: true
                                    implicitHeight: 38
                                    radius: theme.radiusSmall
                                    color: isSel ? modelData.activeBg : theme.bgSurfaceSubtle
                                    border.color: isSel ? modelData.activeBorder : "transparent"
                                    border.width: isSel ? 1 : 0

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: detailRoot.selectedOption = modelData.label
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: isSel ? modelData.activeText : modelData.inactiveText
                                        font.family: theme.fontFamily
                                        font.pixelSize: theme.primaryText
                                        font.weight: modelData.weight
                                    }
                                }
                            }
                        }

                        // Status readout
                        Text {
                            visible: store.lastVoteStatus.length > 0
                            text: store.lastVoteStatus
                            color: store.lastVoteSuccess ? theme.statusSuccess : theme.statusDanger
                            font.family: theme.fontFamily
                            font.pixelSize: theme.secondaryText
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }

                        // Action Row
                        RowLayout {
                            Layout.fillWidth: true
                            visible: bridge.isConnected
                            spacing: theme.spacingSmall

                            Item { Layout.fillWidth: true }

                            Button {
                                visible: store.isSubmittingVote && bridge.pendingRequestId.length > 0
                                text: "Cancel"
                                isPrimary: false
                                customHeight: 36
                                onClicked: store.cancelVote()
                            }

                            Button {
                                text: store.isSubmittingVote ? "Confirm in Wallez..." : ("Vote " + detailRoot.selectedOption)
                                isPrimary: true
                                customHeight: 36
                                enabled: !store.isSubmittingVote && prop !== null
                                onClicked: {
                                    if (prop) {
                                        store.castVote(prop.id, detailRoot.selectedOption);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
