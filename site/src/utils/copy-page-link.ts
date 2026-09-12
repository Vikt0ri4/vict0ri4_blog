import I18nKey from "@i18n/i18nKey";
import { i18n } from "@i18n/translation";
import { copyPlainText } from "@utils/clipboard";
import { showSnackbar } from "@utils/snackbar";

/** Copy the current URL and keep link-button feedback consistent everywhere. */
export async function copyPageLink(): Promise<boolean> {
	if (typeof window === "undefined") return false;

	// copyPlainText 自带非安全上下文(http 局域网访问)兜底，不再直接调用 clipboard API
	const ok = await copyPlainText(window.location.href);
	if (ok) {
		showSnackbar(i18n(I18nKey.copySuccess), {
			icon: "material-symbols:link-rounded",
		});
		return true;
	}
	showSnackbar(i18n(I18nKey.copyFailed));
	return false;
}
