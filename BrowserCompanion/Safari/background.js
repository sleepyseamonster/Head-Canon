const extensionAPI = globalThis.browser ?? globalThis.chrome;
const PROTOCOL_VERSION = 1;

function nextOperationId() {
  return crypto.randomUUID();
}

async function activeTabId() {
  const [tab] = await extensionAPI.tabs.query({
    active: true,
    lastFocusedWindow: true
  });
  return tab?.id ?? null;
}

async function sendToActiveTab(message) {
  const tabId = await activeTabId();
  if (tabId == null) {
    return {
      protocolVersion: PROTOCOL_VERSION,
      result: "unavailable",
      operationID: message.operationID ?? nextOperationId(),
      observedAt: new Date().toISOString(),
      target: null,
      message: "No active Safari tab is available."
    };
  }

  try {
    return await extensionAPI.tabs.sendMessage(tabId, message);
  } catch (error) {
    return {
      protocolVersion: PROTOCOL_VERSION,
      result: "failed",
      operationID: message.operationID ?? nextOperationId(),
      observedAt: new Date().toISOString(),
      target: null,
      message: error?.message ?? "Could not reach the Safari page content script."
    };
  }
}

async function persistLatestSnapshot(snapshotResponse) {
  if (snapshotResponse?.target == null) {
    return;
  }

  await extensionAPI.storage.local.set({
    headCanonLatestTargetSnapshot: snapshotResponse
  });
}

extensionAPI.action.onClicked.addListener(async () => {
  const response = await sendToActiveTab({
    protocolVersion: PROTOCOL_VERSION,
    command: "captureFocusedTarget",
    operationID: nextOperationId(),
    issuedAt: new Date().toISOString(),
    expiresAt: null,
    target: null,
    transcript: null
  });
  await persistLatestSnapshot(response);
  console.log("[HeadCanonSafariCompanion] Focused target snapshot", response);
});

extensionAPI.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message?.event === "focusedTargetUpdate") {
    void persistLatestSnapshot(message.snapshot).then(() => {
      sendResponse({ ok: true });
    });
    return true;
  }

  if (message?.event === "focusedTargetUnavailable") {
    sendResponse({ ok: true });
    return false;
  }

  if (message?.command === "captureFocusedTarget" || message?.command === "insertTranscript") {
    void sendToActiveTab(message).then((response) => {
      void persistLatestSnapshot(response).then(() => {
        sendResponse(response);
      });
    });
    return true;
  }

  return false;
});
