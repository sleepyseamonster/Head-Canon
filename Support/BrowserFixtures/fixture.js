const statusEl = document.getElementById("fixture-status");
const textarea = document.getElementById("fixture-textarea");
const composer = document.getElementById("fixture-composer");
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
