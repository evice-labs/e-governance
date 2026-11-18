import QtQuick

Item {
    id: bridge

    required property var provider

    readonly property bool isHostAvailable: provider ? provider.isHostAvailable : false
    readonly property bool isConnected: provider ? provider.isConnected : false
    readonly property string sessionId: provider ? provider.sessionId : ""
    readonly property string voterCommitment: provider ? provider.voterCommitment : ""
    readonly property string activeAccountAddress: provider ? provider.activeAddress : ""
    property string statusMessage: provider ? provider.statusMessage : "Disconnected"
    property string pendingRequestId: ""

    Connections {
        target: provider
        function onCommitmentLoaded(c) {
            bridge.commitmentLoaded(c);
        }
        function onConnected(acc) {
            bridge.connectionChanged(true);
        }
        function onDisconnected() {
            bridge.connectionChanged(false);
        }
    }

    signal errorOccurred(string method, string message)
    signal connectionChanged(bool connected)
    signal commitmentLoaded(string commitment)
    signal approvalPending(string requestId)
    signal voteSubmitted(string proposalId, string txHash, string nullifier)

    function invoke(method, args, callback) {
        if (!provider || typeof provider.invoke !== "function") {
            var err = { ok: false, error: "WallezKit Provider is not initialized" };
            bridge.errorOccurred(method, err.error);
            if (callback)
                callback(err);
            return err;
        }
        return provider.invoke(method, args, callback);
    }

    function deriveNullifier(proposalId, callback) {
        if (!provider || !bridge.sessionId) {
            if (callback)
                callback({ ok: false, error: "No active wallet session" });
            return;
        }

        var scopeId = "dao.governance.lez/proposal/" + proposalId;
        provider.deriveNullifier(scopeId, callback);
    }

    function signBallot(proposalId, ballotPayload, callback) {
        if (!provider || !bridge.sessionId) {
            if (callback)
                callback({ ok: false, error: "No active wallet session" });
            return;
        }

        var scopeId = "dao.governance.lez/proposal/" + proposalId;
        provider.signAttestation(scopeId, ballotPayload, callback);
    }

    function encodeBorshBallotCalldata(nullifierHex, proposalId, voteOption, signatureHex) {
        var bytes = [];
        // Variant 0x00
        bytes.push(0x00);

        // 32-byte scoped nullifier / domain tag
        var cleanNull = String(nullifierHex || "").replace(/^0[xX]/, "");
        for (var i = 0; i < 32; i++) {
            var b = (i * 2 + 2 <= cleanNull.length) ? parseInt(cleanNull.substring(i * 2, i * 2 + 2), 16) : 0;
            bytes.push(isNaN(b) ? 0 : (b & 0xff));
        }

        // Ballot payload string (<= 280 bytes)
        var sigShort = String(signatureHex || "").substring(0, 32);
        var textStr = "DAO_BALLOT|prop=" + proposalId + "|vote=" + voteOption + "|sig=" + sigShort;
        var textBytes = [];
        for (var j = 0; j < textStr.length; j++) {
            textBytes.push(textStr.charCodeAt(j) & 0x7f);
        }
        var len = textBytes.length;
        bytes.push(len & 0xff, (len >> 8) & 0xff, (len >> 16) & 0xff, (len >> 24) & 0xff);
        for (var k = 0; k < textBytes.length; k++) {
            bytes.push(textBytes[k]);
        }

        // Option<String>: None (0x00) for anonymous ZK ballot
        bytes.push(0x00);

        var hex = "";
        for (var m = 0; m < bytes.length; m++) {
            var h = (bytes[m] & 0xff).toString(16);
            if (h.length === 1)
                hex += "0";
            hex += h;
        }
        return hex;
    }

    function cancelPendingVote(callback) {
        if (!bridge.pendingRequestId) {
            if (callback)
                callback({ ok: true });
            return;
        }
        var reqId = bridge.pendingRequestId;
        pollTimer.stop();
        bridge.pendingRequestId = "";
        if (provider && typeof provider.cancelRequest === "function") {
            provider.cancelRequest(reqId, callback);
        } else {
            invoke("cancelRequest", [reqId], callback);
        }
    }

    function broadcastVote(proposalId, voteOption, nullifier, signature, callback) {
        if (!bridge.sessionId) {
            if (callback)
                callback({ ok: false, error: "No active wallet session" });
            return;
        }

        // Canonical Program ID on LEZ Testnet (clean Base58 required by lee::AccountId::from_str)
        var daoProgramId = "D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV";
        var rawPayer = bridge.activeAccountAddress || "D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV";
        var payerId = rawPayer.replace(/^Public\//, "").replace(/^Private\//, "");

        var calldataHex = encodeBorshBallotCalldata(nullifier, proposalId, voteOption, signature);
        var mentions = [payerId, daoProgramId];
        var description = "Vote " + voteOption + " on DAO Proposal #" + proposalId + " (Nullifier: " + nullifier.substring(0, 10) + "...)";

        var handleProposalResult = function (res) {
            if (res && res.ok) {
                var reqId = res.request_id || "";
                if (res.status === "pending_approval" && reqId) {
                    bridge.pendingRequestId = reqId;
                    bridge.statusMessage = "Waiting for approval in Wallez...";
                    bridge.approvalPending(reqId);
                    pollTimer.targetReqId = reqId;
                    pollTimer.targetProposalId = proposalId;
                    pollTimer.targetNullifier = nullifier;
                    pollTimer.targetCallback = callback;
                    pollTimer.pollCount = 0;
                    pollTimer.approvedCount = 0;
                    pollTimer.start();
                } else {
                    bridge.pendingRequestId = "";
                    var txHash = res.tx_hash || res.request_id || "";
                    bridge.voteSubmitted(proposalId, txHash, nullifier);
                    if (callback)
                        callback({ ok: true, tx_hash: txHash, nullifier: nullifier });
                }
            } else {
                bridge.pendingRequestId = "";
                if (callback)
                    callback(res);
            }
        };

        if (provider && typeof provider.proposeContractCall === "function") {
            provider.proposeContractCall(daoProgramId, payerId, mentions, calldataHex, description, handleProposalResult);
        } else {
            invoke("proposeContractCall", [bridge.sessionId, daoProgramId, payerId, JSON.stringify(mentions), calldataHex, description], handleProposalResult);
        }
    }

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        property string targetReqId: ""
        property string targetProposalId: ""
        property string targetNullifier: ""
        property var targetCallback: null
        property int pollCount: 0
        property int approvedCount: 0

        onTriggered: {
            pollCount++;
            invoke("getRequestStatus", [targetReqId], function (statusRes) {
                var st = (statusRes && statusRes.status) ? statusRes.status : "";
                if (st === "submitted" || st === "approved" || st === "broadcast" || st === "completed" || st === "confirmed") {
                    if (st === "approved" && !statusRes.tx_hash && approvedCount < 60) {
                        approvedCount++;
                        bridge.statusMessage = "Vote approved in Wallez! Broadcasting transaction to LEZ...";
                        return;
                    }
                    pollTimer.stop();
                    bridge.pendingRequestId = "";
                    if (provider && typeof provider.cleanupApprovalEnvelope === "function") {
                        provider.cleanupApprovalEnvelope(targetReqId);
                    }
                    var txHash = (statusRes && statusRes.tx_hash) ? statusRes.tx_hash : targetReqId;
                    bridge.statusMessage = "Vote approved in Wallez! Tx: " + txHash;
                    bridge.voteSubmitted(targetProposalId, txHash, targetNullifier);
                    if (targetCallback)
                        targetCallback({ ok: true, tx_hash: txHash, nullifier: targetNullifier });
                } else if (st === "rejected" || st === "cancelled") {
                    pollTimer.stop();
                    bridge.pendingRequestId = "";
                    if (provider && typeof provider.cleanupApprovalEnvelope === "function") {
                        provider.cleanupApprovalEnvelope(targetReqId);
                    }
                    bridge.statusMessage = "Vote rejected by user in Wallez.";
                    if (targetCallback)
                        targetCallback({ ok: false, error: "Transaction rejected in Wallez wallet" });
                } else if (st === "failed") {
                    pollTimer.stop();
                    bridge.pendingRequestId = "";
                    if (provider && typeof provider.cleanupApprovalEnvelope === "function") {
                        provider.cleanupApprovalEnvelope(targetReqId);
                    }
                    var failReason = (statusRes && statusRes.reason) ? statusRes.reason : "Transaction execution failed on-chain";
                    bridge.statusMessage = "Vote broadcast failed: " + failReason;
                    if (targetCallback)
                        targetCallback({ ok: false, error: failReason });
                } else if (pollCount >= 180) {
                    pollTimer.stop();
                    bridge.pendingRequestId = "";
                    if (provider && typeof provider.cleanupApprovalEnvelope === "function") {
                        provider.cleanupApprovalEnvelope(targetReqId);
                    }
                    bridge.statusMessage = "Approval timed out after 180 seconds.";
                    if (targetCallback)
                        targetCallback({ ok: false, error: "Approval timed out in Wallez" });
                }
            });
        }
    }
}

