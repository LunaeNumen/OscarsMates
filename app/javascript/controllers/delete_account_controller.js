import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "submit"];

  connect() {
    this.requiredPhrase = "I want to leave Oscars Mates";
    this.checkInput();
  }

  checkInput() {
    const inputValue = this.inputTarget.value;
    const matches = inputValue === this.requiredPhrase;

    if (matches) {
      // Enable button with danger styling
      this.submitTarget.disabled = false;
      this.submitTarget.className = "flex-1 inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg border-2 transition-all duration-200 bg-red-600 border-red-600 text-white hover:bg-red-700 hover:border-red-700 cursor-pointer";
    } else {
      // Disable button with gray styling
      this.submitTarget.disabled = true;
      this.submitTarget.className = "flex-1 inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg border-2 transition-all duration-200 bg-slate-100 border-slate-300 text-slate-400 cursor-not-allowed";
    }
  }
}
