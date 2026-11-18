import QtQuick

Item {
    id: store

    required property var bridge

    property int activeProposalIndex: 0
    property var activeProposal: (proposals && proposals.length > activeProposalIndex) ? proposals[activeProposalIndex] : null

    // Cast ballots tracker: proposalId -> { nullifier, option, signature, txHash, timestamp }
    property var castBallots: ({})

    property bool isSubmittingVote: false
    property string lastVoteStatus: ""
    property bool lastVoteSuccess: true

    signal voteRecorded(string proposalId, string option, string txHash)

    Connections {
        target: store.bridge
        function onApprovalPending(reqId) {
            store.lastVoteStatus = "Step 3/3: Confirm in Wallez — Please open the Wallez tab to review and approve.";
            store.lastVoteSuccess = true;
        }
    }

    function cancelVote() {
        if (!store.isSubmittingVote)
            return;
        store.bridge.cancelPendingVote(function () {
            store.isSubmittingVote = false;
            store.lastVoteStatus = "Vote request cancelled.";
            store.lastVoteSuccess = false;
        });
    }

    property var proposals: [
        {
            id: "1",
            title: "Community Treasury Allocation & Ecosystem Seed",
            category: "Treasury",
            proposer: "Public/D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV",
            description: "Allocate 500,000 LEZ tokens from the community treasury to fund foundational developer tooling, documentation, and reference dApps demonstrating native Logos Execution Zone capabilities.",
            quorumRequired: 100000,
            yesVotes: 78500,
            noVotes: 12200,
            abstainVotes: 4100,
            totalVotes: 94800,
            status: "Active",
            deadlineBlocks: 14200,
            scopeId: "dao.governance.lez/proposal/1"
        },
        {
            id: "2",
            title: "EmPoWer Mining Difficulty Recalibration",
            category: "Protocol",
            proposer: "Public/4hN1gG...K5d8",
            description: "Adjust Argon2id / Blake3 mining difficulty thresholds to maintain steady 12-second block intervals across fluctuating network hashrate and CPU miner participation.",
            quorumRequired: 75000,
            yesVotes: 64000,
            noVotes: 5100,
            abstainVotes: 1800,
            totalVotes: 70900,
            status: "Active",
            deadlineBlocks: 9800,
            scopeId: "dao.governance.lez/proposal/2"
        },
        {
            id: "3",
            title: "LEZ Sequencer Decentralization Roadmap",
            category: "Infrastructure",
            proposer: "Public/9pLm2...K9vB",
            description: "Authorize phased migration of the canonical LEZ sequencer to a multi-operator BFT consensus ring with decentralized slashable stake and committee rotations.",
            quorumRequired: 150000,
            yesVotes: 112000,
            noVotes: 18400,
            abstainVotes: 7300,
            totalVotes: 137700,
            status: "Active",
            deadlineBlocks: 24500,
            scopeId: "dao.governance.lez/proposal/3"
        }
    ]

    function selectProposal(index) {
        if (index >= 0 && index < proposals.length) {
            activeProposalIndex = index;
        }
    }

    function hasVoted(proposalId) {
        return !!(castBallots[proposalId]);
    }

    function getCastBallot(proposalId) {
        return castBallots[proposalId] || null;
    }

    function castVote(proposalId, option, callback) {
        if (hasVoted(proposalId)) {
            lastVoteStatus = "Double-voting rejected: Scoped nullifier already recorded on-chain for Proposal #" + proposalId;
            lastVoteSuccess = false;
            if (callback)
                callback({ ok: false, error: lastVoteStatus });
            return;
        }

        isSubmittingVote = true;
        lastVoteStatus = "Step 1/3: Deriving deterministic scoped nullifier for proposal #" + proposalId + "...";
        lastVoteSuccess = true;

        // Step 1: Derive scoped nullifier
        bridge.deriveNullifier(proposalId, function (nullRes) {
            if (!nullRes || !nullRes.ok || !nullRes.nullifier) {
                isSubmittingVote = false;
                var err1 = (nullRes && nullRes.error) ? nullRes.error : "Failed to derive scoped nullifier";
                lastVoteStatus = "Derivation error: " + err1;
                lastVoteSuccess = false;
                if (callback)
                    callback({ ok: false, error: err1 });
                return;
            }

            var nullifier = nullRes.nullifier;
            lastVoteStatus = "Step 2/3: Signing BIP-340 Schnorr ballot attestation with scoped key...";

            // Step 2: Sign BIP-340 Schnorr ballot
            var ballotPayload = {
                app: "dao.governance.lez",
                proposal_id: proposalId,
                vote: option,
                nullifier: nullifier,
                timestamp: Date.now()
            };

            bridge.signBallot(proposalId, ballotPayload, function (sigRes) {
                if (!sigRes || !sigRes.ok || !sigRes.signature) {
                    isSubmittingVote = false;
                    var err2 = (sigRes && sigRes.error) ? sigRes.error : "Failed to sign BIP-340 Schnorr ballot";
                    lastVoteStatus = "Signing error: " + err2;
                    lastVoteSuccess = false;
                    if (callback)
                        callback({ ok: false, error: err2 });
                    return;
                }

                var signature = sigRes.signature;
                lastVoteStatus = "Step 3/3: Broadcasting anonymous ballot to zkVM DAO Program...";

                // Step 3: Broadcast transaction
                bridge.broadcastVote(proposalId, option, nullifier, signature, function (txRes) {
                    isSubmittingVote = false;
                    if (txRes && txRes.ok) {
                        var txHash = txRes.tx_hash || "0x00000000000000000000000000000000";
                        var ballotRecord = {
                            proposalId: proposalId,
                            option: option,
                            nullifier: nullifier,
                            signature: signature,
                            txHash: txHash,
                            timestamp: new Date().toLocaleTimeString()
                        };

                        var updated = Object.assign({}, castBallots);
                        updated[proposalId] = ballotRecord;
                        castBallots = updated;

                        // Increment local proposal counts
                        for (var i = 0; i < proposals.length; i++) {
                            if (proposals[i].id === proposalId) {
                                if (option === "YES")
                                    proposals[i].yesVotes += 1000;
                                else if (option === "NO")
                                    proposals[i].noVotes += 1000;
                                else if (option === "ABSTAIN")
                                    proposals[i].abstainVotes += 1000;
                                proposals[i].totalVotes += 1000;
                                break;
                            }
                        }

                        lastVoteStatus = "Vote successfully registered! Tx: " + (txHash.length > 18 ? (txHash.substring(0, 10) + "..." + txHash.substring(txHash.length - 6)) : txHash);
                        lastVoteSuccess = true;
                        store.voteRecorded(proposalId, option, txHash);
                        if (callback)
                            callback({ ok: true, tx_hash: txHash, nullifier: nullifier });
                    } else {
                        var err3 = (txRes && txRes.error) ? txRes.error : "Transaction broadcast failed";
                        lastVoteStatus = "Broadcast error: " + err3;
                        lastVoteSuccess = false;
                        if (callback)
                            callback({ ok: false, error: err3 });
                    }
                });
            });
        });
    }
}

