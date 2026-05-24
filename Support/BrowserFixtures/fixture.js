const statusEl = document.getElementById("fixture-status");
const textarea = document.getElementById("fixture-textarea");
const composer = document.getElementById("fixture-composer");
const searchField = document.getElementById("fixture-search");
const passwordField = document.getElementById("fixture-password");
const iframeEl = document.querySelector("iframe");
const focusTextarea = document.getElementById("focus-textarea");
const focusComposer = document.getElementById("focus-composer");

function setStatus(message) {
  if (statusEl) {
    statusEl.textContent = message;
  }
}

focusTextarea?.addEventListener("click", () => {
  textarea?.focus();
  setStatus("Focused the textarea fixture.");
});

focusComposer?.addEventListener("click", () => {
  composer?.focus();
  setStatus("Focused the rich editor fixture.");
});

document.addEventListener("focusin", (event) => {
  const target = event.target;
  if (!(target instanceof HTMLElement)) {
    return;
  }

  const label =
    target.getAttribute("aria-label") ||
    target.getAttribute("placeholder") ||
    target.id ||
    target.tagName.toLowerCase();

  setStatus(`Focused: ${label}`);
});

function targetByFocusKey(key) {
  switch (key) {
    case "fixture-search":
      return searchField;
    case "fixture-textarea":
      return textarea;
    case "fixture-composer":
      return composer;
    case "fixture-password":
      return passwordField;
    default:
      return null;
  }
}

function focusShadowComposer() {
  const shadowHost = document.querySelector("headcanon-shadow-editor");
  const shadowComposer = shadowHost?.shadowRoot?.getElementById("shadow-composer");
  if (shadowComposer instanceof HTMLElement) {
    shadowComposer.focus();
    setStatus("Focused: Shadow Fixture Composer");
    return true;
  }
  return false;
}

function focusIframeComposer() {
  const iframeDocument = iframeEl?.contentDocument;
  const editor = iframeDocument?.getElementById("iframe-rich-editor");
  if (editor instanceof HTMLElement) {
    editor.focus();
    setStatus("Focused: Iframe Fixture Composer");
    return true;
  }
  return false;
}

function applyQueryFocus() {
  const url = new URL(window.location.href);
  const focusKey = url.searchParams.get("focus");
  if (!focusKey) {
    return;
  }

  const directTarget = targetByFocusKey(focusKey);
  if (directTarget instanceof HTMLElement) {
    directTarget.focus();
    return;
  }

  if (focusKey === "shadow-composer") {
    if (!focusShadowComposer()) {
      setStatus("Could not focus the shadow DOM fixture.");
    }
    return;
  }

  if (focusKey === "iframe-rich-editor") {
    const onLoad = () => {
      if (!focusIframeComposer()) {
        setStatus("Could not focus the iframe fixture.");
      }
      iframeEl?.removeEventListener("load", onLoad);
    };

    if (focusIframeComposer()) {
      return;
    }

    iframeEl?.addEventListener("load", onLoad);
    return;
  }

  setStatus(`Unknown focus target: ${focusKey}`);
}

window.addEventListener("load", () => {
  setTimeout(() => {
    applyQueryFocus();
  }, 200);
});
