const extensionAPI = globalThis.browser ?? globalThis.chrome;
const PROTOCOL_VERSION = 1;
const BROWSER_HOST = "safari";
let lastPublishedFingerprint = null;
let lastPublishedAt = 0;

function nextOperationId() {
  return crypto.randomUUID();
}

function isElementVisible(element) {
  const rect = element.getBoundingClientRect();
  return rect.width > 0 && rect.height > 0;
}

function pathForFrame(framePath, childIndex) {
  if (framePath.length === 0) {
    return `${childIndex}`;
  }
  return `${framePath.join(".")}.${childIndex}`;
}

function editableDescriptor(element) {
  const tagName = element.tagName?.toLowerCase() ?? "";
  const role = (element.getAttribute("role") ?? "").toLowerCase();
  const ariaLabel = element.getAttribute("aria-label") ?? null;
  const placeholder = element.getAttribute("placeholder") ?? null;
  const id = element.id || null;
  const classes = Array.from(element.classList ?? []).join(" ");
  const fingerprintParts = [tagName, role, ariaLabel, placeholder, id, classes].filter(Boolean);

  const isTextInput = tagName === "input" && !["password", "hidden"].includes((element.type ?? "").toLowerCase());
  const isTextarea = tagName === "textarea";
  const isContentEditable = element.isContentEditable || role === "textbox";
  const looksLikeCode = role.includes("code") || classes.toLowerCase().includes("code");
  const looksFrameworkManaged =
    role.includes("textbox") ||
    classes.toLowerCase().includes("editor") ||
    classes.toLowerCase().includes("composer") ||
    classes.toLowerCase().includes("prosemirror") ||
    classes.toLowerCase().includes("slate") ||
    classes.toLowerCase().includes("lexical");

  let editorFamily = "unknown";
  let targetClass = "unknown";

  if (isTextInput && (element.type ?? "").toLowerCase() === "search") {
    editorFamily = "searchField";
    targetClass = "plainTextControl";
  } else if (isTextarea) {
    editorFamily = looksFrameworkManaged ? "frameworkManagedEditor" : "textAreaControl";
    targetClass = looksFrameworkManaged ? "richEditable" : "plainTextControl";
  } else if (isTextInput) {
    editorFamily = "textInputControl";
    targetClass = "plainTextControl";
  } else if (looksLikeCode) {
    editorFamily = "codeEditor";
    targetClass = "richEditable";
  } else if (isContentEditable) {
    editorFamily = looksFrameworkManaged ? "frameworkManagedEditor" : "contentEditable";
    targetClass = "richEditable";
  }

  return {
    tagName,
    role,
    ariaLabel,
    placeholder,
    id,
    fingerprint: fingerprintParts.join(" | ") || null,
    editorFamily,
    targetClass
  };
}

function activeElementDeep(root = document, framePath = []) {
  let active = root.activeElement;

  while (active?.shadowRoot?.activeElement) {
    active = active.shadowRoot.activeElement;
  }

  if (active?.tagName?.toLowerCase() === "iframe") {
    try {
      if (active.contentDocument) {
        const childFrameIndex = Array.from(root.querySelectorAll("iframe")).indexOf(active);
        return activeElementDeep(active.contentDocument, [...framePath, pathForFrame(framePath, childFrameIndex)]);
      }
    } catch (_error) {
      return { element: active, framePath };
    }
  }

  return { element: active, framePath };
}

function captureFocusedTargetSnapshot(operationID = nextOperationId()) {
  const { element, framePath } = activeElementDeep(document, []);
  if (!(element instanceof HTMLElement) || !isElementVisible(element)) {
    return {
      protocolVersion: PROTOCOL_VERSION,
      result: "unavailable",
      operationID,
      observedAt: new Date().toISOString(),
      target: null,
      message: "No visible editable target is focused."
    };
  }

  const descriptor = editableDescriptor(element);
  const framedEditable =
    framePath.length > 0 &&
    (descriptor.targetClass === "plainTextControl" || descriptor.targetClass === "richEditable");
  const editable =
    descriptor.targetClass === "plainTextControl" ||
    descriptor.targetClass === "richEditable";
  const secure =
    element instanceof HTMLInputElement &&
    (element.type ?? "").toLowerCase() === "password";

  return {
    protocolVersion: PROTOCOL_VERSION,
    result: "targetSnapshot",
    operationID,
    observedAt: new Date().toISOString(),
    target: {
      browser: BROWSER_HOST,
      pageOrigin: location.origin,
      pageTitle: document.title,
      framePath: framePath.join(" > ") || "0",
      frameIdentifier: window.frameElement?.id || null,
      targetClass: secure ? "unsupportedOrSecure" : (framedEditable ? "framedEditable" : descriptor.targetClass),
      editorFamily: secure ? "secureField" : descriptor.editorFamily,
      targetFingerprint: descriptor.fingerprint,
      editable,
      secure
    },
    message: editable ? "Focused browser target captured." : "Focused element is not currently recognized as editable."
  };
}

function publishFocusedTargetSnapshot() {
  const snapshot = captureFocusedTargetSnapshot(nextOperationId());
  const fingerprint = snapshot.target?.targetFingerprint ?? null;
  const now = Date.now();

  if (snapshot.result !== "targetSnapshot") {
    void extensionAPI.runtime.sendMessage({
      event: "focusedTargetUnavailable",
      snapshot
    }).catch(() => {});
    return;
  }

  if (fingerprint === lastPublishedFingerprint && now - lastPublishedAt < 1500) {
    return;
  }

  lastPublishedFingerprint = fingerprint;
  lastPublishedAt = now;
  void extensionAPI.runtime.sendMessage({
    event: "focusedTargetUpdate",
    snapshot
  }).catch(() => {});
}

function insertIntoTextControl(element, text) {
  const start = element.selectionStart ?? element.value.length;
  const end = element.selectionEnd ?? start;
  element.focus();
  element.setRangeText(text, start, end, "end");
  element.dispatchEvent(new InputEvent("input", {
    bubbles: true,
    cancelable: false,
    data: text,
    inputType: "insertText"
  }));
}

function insertIntoContentEditable(element, text) {
  element.focus();
  const selection = element.ownerDocument.getSelection();
  if (!selection) {
    return false;
  }

  if (selection.rangeCount === 0) {
    const range = element.ownerDocument.createRange();
    range.selectNodeContents(element);
    range.collapse(false);
    selection.removeAllRanges();
    selection.addRange(range);
  }

  const range = selection.getRangeAt(0);
  range.deleteContents();
  const node = element.ownerDocument.createTextNode(text);
  range.insertNode(node);
  range.setStartAfter(node);
  range.setEndAfter(node);
  selection.removeAllRanges();
  selection.addRange(range);
  element.dispatchEvent(new InputEvent("input", {
    bubbles: true,
    cancelable: false,
    data: text,
    inputType: "insertText"
  }));
  return true;
}

function currentTargetMatchesExpected(snapshot, expectedTarget) {
  if (!expectedTarget?.targetFingerprint) {
    return true;
  }
  return snapshot?.target?.targetFingerprint === expectedTarget.targetFingerprint;
}

function insertTranscript(message) {
  const snapshot = captureFocusedTargetSnapshot(message.operationID ?? nextOperationId());
  if (snapshot.result !== "targetSnapshot") {
    return snapshot;
  }

  if (snapshot.target?.secure || snapshot.target?.targetClass === "unsupportedOrSecure") {
    return {
      protocolVersion: PROTOCOL_VERSION,
      result: "unsupported",
      operationID: message.operationID ?? nextOperationId(),
      observedAt: new Date().toISOString(),
      target: snapshot.target,
      message: "Secure browser targets remain blocked by the companion."
    };
  }

  if (!currentTargetMatchesExpected(snapshot, message.target)) {
    return {
      protocolVersion: PROTOCOL_VERSION,
      result: "expired",
      operationID: message.operationID ?? nextOperationId(),
      observedAt: new Date().toISOString(),
      target: snapshot.target,
      message: "The focused browser target changed before insertion could run."
    };
  }

  const { element } = activeElementDeep(document, []);
  if (!(element instanceof HTMLElement)) {
    return {
      protocolVersion: PROTOCOL_VERSION,
      result: "failed",
      operationID: message.operationID ?? nextOperationId(),
      observedAt: new Date().toISOString(),
      target: snapshot.target,
      message: "The focused browser element is no longer available."
    };
  }

  const text = message.transcript ?? "";

  try {
    if (element instanceof HTMLInputElement || element instanceof HTMLTextAreaElement) {
      insertIntoTextControl(element, text);
      return {
        protocolVersion: PROTOCOL_VERSION,
        result: "inserted",
        operationID: message.operationID ?? nextOperationId(),
        observedAt: new Date().toISOString(),
        target: snapshot.target,
        message: "Inserted into a plain browser text control."
      };
    }

    if (element.isContentEditable || element.getAttribute("role") === "textbox") {
      insertIntoContentEditable(element, text);
      return {
        protocolVersion: PROTOCOL_VERSION,
        result: "unverifiedInsert",
        operationID: message.operationID ?? nextOperationId(),
        observedAt: new Date().toISOString(),
        target: snapshot.target,
        message: "Inserted into a rich browser editor without exact value readback."
      };
    }

    return {
      protocolVersion: PROTOCOL_VERSION,
      result: "unsupported",
      operationID: message.operationID ?? nextOperationId(),
      observedAt: new Date().toISOString(),
      target: snapshot.target,
      message: "The focused browser target is not yet supported by the Safari companion scaffold."
    };
  } catch (error) {
    return {
      protocolVersion: PROTOCOL_VERSION,
      result: "failed",
      operationID: message.operationID ?? nextOperationId(),
      observedAt: new Date().toISOString(),
      target: snapshot.target,
      message: error?.message ?? "Browser insertion failed."
    };
  }
}

extensionAPI.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (!message || typeof message !== "object") {
    sendResponse(null);
    return false;
  }

  switch (message.command) {
    case "captureFocusedTarget":
      sendResponse(captureFocusedTargetSnapshot(message.operationID));
      return false;
    case "insertTranscript":
      sendResponse(insertTranscript(message));
      return false;
    default:
      sendResponse({
        protocolVersion: PROTOCOL_VERSION,
        result: "failed",
        operationID: message.operationID ?? nextOperationId(),
        observedAt: new Date().toISOString(),
        target: null,
        message: `Unsupported content command: ${message.command ?? "unknown"}`
      });
      return false;
  }
});

document.addEventListener("focusin", () => {
  publishFocusedTargetSnapshot();
}, true);

window.addEventListener("load", () => {
  setTimeout(() => {
    publishFocusedTargetSnapshot();
  }, 250);
});
