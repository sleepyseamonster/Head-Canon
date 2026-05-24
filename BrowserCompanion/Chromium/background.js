const NATIVE_HOST_NAME = "local.headcanon.browser_companion";
const PROTOCOL_VERSION = 1;
const COMPANION_BROWSER = "chrome";

let nativePort = null;
let reconnectTimer = null;

function log(...parts) {
  console.log("[HeadCanonBrowserCompanion]", ...parts);
}

function nextOperationId() {
  return crypto.randomUUID();
}

function forwardSnapshotToNative(snapshotResponse) {
  if (!nativePort || !snapshotResponse?.target) {
    return;
  }

  nativePort.postMessage({
    ...snapshotResponse,
    protocolVersion: PROTOCOL_VERSION,
    target: {
      ...snapshotResponse.target,
      browser: snapshotResponse.target.browser ?? COMPANION_BROWSER
    }
  });
}

function scheduleReconnect() {
  if (reconnectTimer !== null) {
    return;
  }

  reconnectTimer = setTimeout(() => {
    reconnectTimer = null;
    connectNativeHost();
  }, 3000);
}

async function activeTabId() {
  const [tab] = await chrome.tabs.query({
    active: true,
    lastFocusedWindow: true
  });
  return tab?.id ?? null;
}

async function sendToActiveTab(message) {
  const tabId = await activeTabId();
  if (tabId === null) {
    return {
      protocolVersion: PROTOCOL_VERSION,
      result: "unavailable",
      operationID: message.operationID ?? nextOperationId(),
      observedAt: new Date().toISOString(),
      target: null,
      message: "No active browser tab is available."
    };
  }

  try {
    return await chrome.tabs.sendMessage(tabId, message);
  } catch (error) {
    return {
      protocolVersion: PROTOCOL_VERSION,
      result: "failed",
      operationID: message.operationID ?? nextOperationId(),
      observedAt: new Date().toISOString(),
      target: null,
      message: error?.message ?? "Could not reach the page content script."
    };
  }
}

async function handleNativeMessage(message) {
  if (!message || typeof message !== "object") {
    return;
  }

  switch (message.command) {
    case "healthCheck":
      nativePort?.postMessage({
        protocolVersion: PROTOCOL_VERSION,
        result: "healthy",
        operationID: message.operationID ?? nextOperationId(),
        observedAt: new Date().toISOString(),
        target: null,
        message: "Chromium browser companion is connected."
      });
      return;
    case "captureFocusedTarget":
    case "insertTranscript": {
      const response = await sendToActiveTab(message);
      nativePort?.postMessage(response);
      return;
    }
    default:
      nativePort?.postMessage({
        protocolVersion: PROTOCOL_VERSION,
        result: "failed",
        operationID: message.operationID ?? nextOperationId(),
        observedAt: new Date().toISOString(),
        target: null,
        message: `Unsupported browser companion command: ${message.command ?? "unknown"}`
      });
    }
}

function connectNativeHost() {
  if (nativePort !== null) {
    return;
  }

  try {
    nativePort = chrome.runtime.connectNative(NATIVE_HOST_NAME);
    nativePort.onMessage.addListener((message) => {
      void handleNativeMessage(message);
    });
    nativePort.onDisconnect.addListener(() => {
      const lastError = chrome.runtime.lastError?.message;
      log("Native host disconnected.", lastError ?? "No additional detail.");
      nativePort = null;
      scheduleReconnect();
    });
    log("Native host connected.");
    void sendToActiveTab({
      protocolVersion: PROTOCOL_VERSION,
      command: "captureFocusedTarget",
      operationID: nextOperationId(),
      issuedAt: new Date().toISOString(),
      expiresAt: null,
      target: null,
      transcript: null
    }).then((response) => {
      forwardSnapshotToNative(response);
    });
  } catch (error) {
    log("Native host connection failed.", error?.message ?? String(error));
    nativePort = null;
    scheduleReconnect();
  }
}

chrome.runtime.onInstalled.addListener(() => {
  connectNativeHost();
});

chrome.runtime.onStartup.addListener(() => {
  connectNativeHost();
});

chrome.action.onClicked.addListener(async () => {
  const response = await sendToActiveTab({
    protocolVersion: PROTOCOL_VERSION,
    command: "captureFocusedTarget",
    operationID: nextOperationId(),
    issuedAt: new Date().toISOString(),
    expiresAt: null,
    target: null,
    transcript: null
  });
  forwardSnapshotToNative(response);
  log("Focused target snapshot", response);
});

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message?.event === "focusedTargetUpdate") {
    forwardSnapshotToNative(message.snapshot);
    sendResponse({ ok: true });
    return false;
  }

  if (message?.event === "focusedTargetUnavailable") {
    sendResponse({ ok: true });
    return false;
  }

  return false;
});

connectNativeHost();
