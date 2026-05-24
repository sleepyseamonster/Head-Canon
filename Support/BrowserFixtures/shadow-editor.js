class HeadCanonShadowEditor extends HTMLElement {
  connectedCallback() {
    if (this.shadowRoot) {
      return;
    }

    const root = this.attachShadow({ mode: "open" });
    const wrapper = document.createElement("div");
    const style = document.createElement("style");
    const label = document.createElement("label");
    const editor = document.createElement("div");

    style.textContent = `
      :host {
        display: block;
      }

      label {
        display: block;
        margin-bottom: 8px;
        font: 600 1rem/1.4 "Avenir Next", "Helvetica Neue", sans-serif;
        color: #1f1d1a;
      }

      div[contenteditable="true"] {
        min-height: 144px;
        border: 1px solid #d8ccbf;
        border-radius: 14px;
        padding: 14px 16px;
        font: 1rem/1.45 "Avenir Next", "Helvetica Neue", sans-serif;
        color: #1f1d1a;
        background: #ffffff;
        outline: none;
      }
    `;

    label.textContent = "Shadow Composer";
    label.setAttribute("for", "shadow-composer");

    editor.id = "shadow-composer";
    editor.setAttribute("contenteditable", "true");
    editor.setAttribute("role", "textbox");
    editor.setAttribute("aria-label", "Shadow Fixture Composer");
    editor.className = "shadow-composer editor";
    editor.textContent = "Click here and dictate into the shadow DOM editor.";

    wrapper.append(label, editor);
    root.append(style, wrapper);
  }
}

customElements.define("headcanon-shadow-editor", HeadCanonShadowEditor);
