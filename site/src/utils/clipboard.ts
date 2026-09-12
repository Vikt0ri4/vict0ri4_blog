/**
 * 统一复制实现。
 *
 * 背景：`navigator.clipboard` 只在**安全上下文**（HTTPS 或 localhost）可用。
 * 本站常以 http://局域网IP 形式访问，此时异步剪贴板 API 不可用，
 * 必须退回 textarea + document.execCommand("copy")，否则复制按钮必然失败。
 */
export async function copyPlainText(text: string): Promise<boolean> {
	if (typeof document === "undefined") return false;

	// 1) 安全上下文：优先使用异步剪贴板 API
	if (window.isSecureContext && navigator.clipboard?.writeText) {
		try {
			await navigator.clipboard.writeText(text);
			return true;
		} catch {
			// 落到兜底方案
		}
	}

	// 2) 非安全上下文 / API 被拒：textarea + execCommand 兜底
	try {
		const textarea = document.createElement("textarea");
		textarea.value = text;
		textarea.setAttribute("readonly", "");
		textarea.style.position = "fixed";
		textarea.style.top = "-1000px";
		textarea.style.opacity = "0";
		textarea.setAttribute("aria-hidden", "true");
		document.body.append(textarea);
		textarea.select();
		textarea.setSelectionRange(0, textarea.value.length);
		const ok = document.execCommand("copy");
		textarea.remove();
		return ok;
	} catch {
		return false;
	}
}
