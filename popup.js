// popup.js

document.addEventListener('DOMContentLoaded', async () => {
  const enableToggle = document.getElementById('enableToggle');

  // ── 저장된 값 불러오기 ──────────────────────
  const { enabled } = await chrome.storage.local.get(['enabled']);
  if (enabled === false) enableToggle.checked = false;

  // ── 활성화 토글 ─────────────────────────────
  enableToggle.addEventListener('change', () => {
    chrome.storage.local.set({ enabled: enableToggle.checked });
  });

  // ── 테스트 모드 시작 ──────────────────────────
  const testBtn = document.getElementById('testBtn');
  testBtn.addEventListener('click', async () => {
    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      await chrome.tabs.sendMessage(tab.id, { action: 'startTest' });
      window.close();
    } catch {
      alert('페이지에 접근할 수 없습니다. (확장 미지원 URL)');
    }
  });
});
