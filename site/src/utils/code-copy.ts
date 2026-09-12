import I18nKey from "@i18n/i18nKey";
import { i18n } from "@i18n/translation";
import { copyPlainText } from "@utils/clipboard";
import { showSnackbar } from "@utils/snackbar";

const BOUND_KEY = "codeCopyBound";

function readCode(button: Element): string {
	const code = button.closest(".frame")?.querySelector("pre code");
	return Array.from(code?.querySelectorAll(".code:not(summary *)") ?? [])
		.map((line) => line.textContent)
		.map((text) => (text === "\n" ? "" : text))
		.join("\n");
}

export function initCodeCopyButtons(): void {
	if (typeof document === "undefined") return;
	if (document.documentElement.dataset[BOUND_KEY] === "true") return;
	document.documentElement.dataset[BOUND_KEY] = "true";

	document.addEventListener("click", async (event) => {
		const target = event.target;
		if (!(target instanceof Element)) return;
		const button = target.closest<HTMLButtonElement>(".copy-btn");
		if (!button) return;

		// copyPlainText 兼容非安全上下文(http 局域网访问)
		const ok = await copyPlainText(readCode(button));
		if (ok) {
			button.classList.add("success");
			showSnackbar(i18n(I18nKey.copySuccess));

			const previousTimeout = Number(button.dataset.timeoutId);
			if (Number.isFinite(previousTimeout))
				window.clearTimeout(previousTimeout);
			const timeoutId = window.setTimeout(() => {
				button.classList.remove("success");
				delete button.dataset.timeoutId;
			}, 1000);
			button.dataset.timeoutId = String(timeoutId);
		} else {
			showSnackbar(i18n(I18nKey.copyFailed));
		}
	});
}
