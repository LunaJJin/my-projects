// content.js - DOM 감지, 검증 UI 표시

(function () {
  'use strict';

  const BADGE_PREFIX = 'fv-badge-';
  let counter = 0;
  let isEnabled = true;
  let testModeRunning = false;

  // ──────────────────────────────────────────────
  // 초기화: 활성화 상태 불러오기
  // ──────────────────────────────────────────────
  chrome.storage.local.get(['enabled'], (result) => {
    isEnabled = result.enabled !== false;
    if (isEnabled) init();
  });

  // 팝업에서 토글 변경 시 실시간 반영
  chrome.storage.onChanged.addListener((changes) => {
    if ('enabled' in changes) {
      isEnabled = changes.enabled.newValue;
      if (!isEnabled) clearAll();
    }
  });

  // ──────────────────────────────────────────────
  // 초기화: 현재 페이지 인풋 처리 + MutationObserver
  // ──────────────────────────────────────────────
  // 네이티브 input/textarea + contenteditable + wds-component 같은 커스텀 컴포넌트 모두 포함
  const FIELD_SELECTOR = 'input, textarea, [contenteditable="true"], [wds-component]';

  function init() {
    processInputs(document.querySelectorAll(FIELD_SELECTOR));

    const observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        for (const node of mutation.addedNodes) {
          if (node.nodeType !== Node.ELEMENT_NODE) continue;
          const inputs = node.matches(FIELD_SELECTOR)
            ? [node]
            : [...node.querySelectorAll(FIELD_SELECTOR)];
          processInputs(inputs);
        }
      }
    });

    observer.observe(document.body, { childList: true, subtree: true });
  }

  // 네이티브 .value가 없는 커스텀 컴포넌트는 내부 편집 요소 또는 innerText로 값을 읽음
  function getFieldValue(el) {
    if (typeof el.value === 'string') return el.value;
    // wds-component 같은 래퍼 div: 내부의 실제 편집 요소에서 값 읽기
    const inner = el.querySelector('[contenteditable], textarea, input:not([type="hidden"]):not([type="submit"]):not([type="button"])');
    if (inner) return typeof inner.value === 'string' ? inner.value : (inner.innerText || '');
    return el.innerText || '';
  }

  // ──────────────────────────────────────────────
  // 인풋 처리: 필드 타입 감지 후 이벤트 바인딩
  // ──────────────────────────────────────────────
  function processInputs(inputs) {
    for (const input of inputs) {
      if (input.dataset.fvProcessed) continue;

      // [wds-component] 요소 처리
      if (input.hasAttribute('wds-component')) {
        const inner = input.querySelector('[contenteditable], textarea, input:not([type="hidden"]):not([type="submit"]):not([type="button"]):not([type="reset"])');
        if (inner) {
          // 내부에 실제 편집 요소가 있으면 래퍼는 건너뜀 (내부 요소가 별도로 처리됨)
          input.dataset.fvProcessed = 'skip';
          continue;
        }
        if (!input.hasAttribute('contenteditable')) {
          // 편집 불가 div (with-interaction, text-area-content, icon-button 등 UI 장식 요소) 제외
          input.dataset.fvProcessed = 'skip';
          continue;
        }
        // contenteditable div인 경우는 아래에서 계속 처리
      }

      const fieldType = FV.detectFieldType(input);
      if (!fieldType) continue; // null = 검증 대상 아님 (버튼, 체크박스 등)

      input.dataset.fvProcessed = 'true';
      input.dataset.fvType = fieldType;
      input.dataset.fvId = String(++counter);

      // div 래퍼(wds-component 등)는 blur가 발생하지 않으므로 focusout(버블링) 사용
      const isNativeInput = input.tagName === 'INPUT' || input.tagName === 'TEXTAREA';
      const blurEventName = isNativeInput || input.hasAttribute('contenteditable') ? 'blur' : 'focusout';
      input.addEventListener(blurEventName, () => onBlur(input, fieldType));

      // 재입력 시 이전 결과 초기화
      input.addEventListener('input', () => {
        clearBadge(input);
        clearInputState(input);
      });
    }
  }

  // ──────────────────────────────────────────────
  // blur 이벤트 핸들러
  // ──────────────────────────────────────────────
  // UI가 자동으로 추가한 천단위 쉼표 제거 (예: "3,466" → "3466")
  // 숫자 + 쉼표/점만으로 구성된 경우에만 적용
  function normalizeValue(raw) {
    if (!raw.includes(',')) return raw;
    const stripped = raw.replace(/,/g, '');
    if (/^\d+(\.\d+)?$/.test(stripped)) return stripped;
    return raw;
  }

  function onBlur(input, fieldType) {
    if (!isEnabled || testModeRunning) return;

    const value = normalizeValue(getFieldValue(input));

    if (!value.trim()) {
      clearBadge(input);
      clearInputState(input);
      return;
    }

    const result = FV.localValidate(fieldType, value);
    if (!result) return;
    renderResult(input, result);
  }

  // ──────────────────────────────────────────────
  // UI 헬퍼
  // ──────────────────────────────────────────────
  function renderResult(input, result) {
    if (result.valid === true) {
      setInputState(input, 'valid');
      renderBadge(input, `✓ ${result.message}`, 'valid');
    } else if (result.valid === false) {
      setInputState(input, 'invalid');
      renderBadge(input, `✗ ${result.message}`, 'invalid');
    } else {
      clearInputState(input);
      renderBadge(input, result.message, 'info');
    }
  }

  function renderBadge(input, text, type) {
    clearBadge(input);
    const badge = document.createElement('div');
    badge.id = BADGE_PREFIX + input.dataset.fvId;
    badge.className = `fv-badge fv-badge-${type}`;
    badge.textContent = text;
    // 커스텀 컴포넌트 래퍼 안에 있으면 래퍼 바깥에 배지 삽입 (래퍼의 overflow:hidden 회피)
    const anchor = input.closest('[wds-component]') || input;
    anchor.insertAdjacentElement('afterend', badge);
  }

  function clearBadge(input) {
    const el = document.getElementById(BADGE_PREFIX + input.dataset.fvId);
    if (el) el.remove();
  }

  function setInputState(input, state) {
    input.classList.remove('fv-input-valid', 'fv-input-invalid', 'fv-input-loading');
    if (state) input.classList.add(`fv-input-${state}`);
  }

  function clearInputState(input) {
    setInputState(input, '');
  }

  function clearAll() {
    document.querySelectorAll('.fv-badge').forEach((el) => el.remove());
    document.querySelectorAll('[data-fv-processed]')
      .forEach((el) => clearInputState(el));
  }

  // ──────────────────────────────────────────────
  // 테스트 모드
  // ──────────────────────────────────────────────
  const TestMode = (() => {
    let panel = null;
    let isRunning = false;
    let allResults = [];

    // 테스트 대상 인풋 스캔
    function scanInputs() {
      const EXCLUDE = new Set([
        'hidden', 'submit', 'button', 'reset', 'image',
        'checkbox', 'radio', 'file', 'color', 'range',
        'date', 'time', 'datetime-local', 'month', 'week'
      ]);
      return [...document.querySelectorAll('input, textarea')].filter(el => {
        if (EXCLUDE.has(el.type)) return false;
        if (el.disabled || el.readOnly) return false;
        if (el.getAttribute('aria-hidden') === 'true') return false;
        if (el.getAttribute('tabindex') === '-1' && el.readOnly) return false;
        const rect = el.getBoundingClientRect();
        if (rect.width === 0 || rect.height === 0) return false;
        return true;
      });
    }

    // 입력 분석
    function analyzeInput(input) {
      let isNumberOnly = FV.isNumberOnlyInput(input);

      // 정적 속성(type/inputmode/pattern)으로 감지 안 됐을 경우,
      // 비숫자 값을 넣어보고 JS 핸들러가 즉시 제거하면 숫자 전용으로 동적 감지
      if (!isNumberOnly) {
        const prev = input.value;
        input.value = 'xyz';
        input.dispatchEvent(new Event('input', { bubbles: true }));
        if (input.value !== 'xyz') isNumberOnly = true;
        input.value = prev;
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }

      const fieldType = FV.detectFieldType(input) || 'unknown';
      const label = FV.getInputLabel(input);
      const testCases = FV.getTestCases(fieldType, isNumberOnly);
      return { input, label, fieldType, isNumberOnly, testCases };
    }

    // 페이지 에러 텍스트 수집 (visible 요소만, before/after diff로 신규 텍스트 감지)
    function getErrorTexts(input) {
      const texts = new Set();
      const addIfVisible = (el) => {
        if (!el || el === input || el.contains(input) || input.contains(el)) return;
        const s = window.getComputedStyle(el);
        if (s.display === 'none' || s.visibility === 'hidden') return;
        const t = el.textContent.trim();
        if (t && t.length <= 200) texts.add(t);
      };
      // aria 참조 요소
      const desc = input.getAttribute('aria-describedby');
      if (desc) desc.split(/\s+/).forEach(id => addIfVisible(document.getElementById(id)));
      const errRef = input.getAttribute('aria-errormessage');
      if (errRef) addIfVisible(document.getElementById(errRef));
      // 전역 role=alert / aria-live 요소
      document.querySelectorAll('[role="alert"], [aria-live]').forEach(el => addIfVisible(el));
      // 가까운 3단계 컨테이너에서 오류·메시지 관련 텍스트 탐색
      const root = input.parentElement?.parentElement?.parentElement
        || input.parentElement?.parentElement
        || input.parentElement;
      const SKIP = 'input, textarea, select, button';
      if (root) {
        root.querySelectorAll(
          `[class*="error"]:not(${SKIP}), [class*="invalid"]:not(${SKIP}),` +
          `[class*="message"]:not(${SKIP}), [class*="msg"]:not(${SKIP}),` +
          `[class*="help"]:not(${SKIP}), [class*="hint"]:not(${SKIP}),` +
          `[class*="warning"]:not(${SKIP}), [class*="alert"]:not(${SKIP})`
        ).forEach(el => addIfVisible(el));
      }
      // CSS-in-JS 난수 클래스명 대응: 인풋·부모·조부모의 다음 형제 요소를 직접 탐색
      // (error span이 input 바로 아래에 오는 패턴 포착)
      const ANCHORS = [input, input.parentElement, input.parentElement?.parentElement].filter(Boolean);
      for (const anchor of ANCHORS) {
        let sib = anchor.nextElementSibling;
        while (sib) {
          addIfVisible(sib);
          sib.querySelectorAll(`span:not(${SKIP}), p:not(${SKIP}), small:not(${SKIP}), em:not(${SKIP})`).forEach(el => addIfVisible(el));
          sib = sib.nextElementSibling;
        }
      }
      return texts;
    }
    function snapErrors(input) { return getErrorTexts(input); }
    function findNewError(input, before) {
      for (const t of getErrorTexts(input)) {
        if (!before.has(t)) return t;
      }
      return null;
    }

    // 단일 케이스 검증 (input 요소 포함 — required·validity 활용)
    function validateCase(input, fieldType, isNumberOnly, value) {
      // ── 빈 값: 페이지 오류 없이 왔다면 "확인 필요"로 표시 (제출 시 검증하는 경우 대비) ──
      if (value === '') {
        if (input.required) return { valid: false, message: '필수 항목 — 빈 값으로 제출 불가' };
        return { valid: null, message: '빈 값 — 페이지 오류 없음 (제출 시 확인 필요)' };
      }

      // ── 브라우저 네이티브 검증 (pattern, type, min, max, maxlength 등) ──
      // input.validity는 현재 input.value 기준으로 계산됨 (이미 값이 세팅된 상태)
      if (input.validity && !input.validity.valid) {
        const v = input.validity;
        if (v.typeMismatch)    return { valid: false, message: '브라우저가 형식을 거부 (type 불일치)' };
        if (v.patternMismatch) return { valid: false, message: `pattern 속성 불일치 (${input.pattern})` };
        if (v.tooLong)         return { valid: false, message: `최대 ${input.maxLength}자 초과` };
        if (v.tooShort)        return { valid: false, message: `최소 ${input.minLength}자 이상 필요` };
        if (v.rangeOverflow)   return { valid: false, message: `최대값(${input.max}) 초과` };
        if (v.rangeUnderflow)  return { valid: false, message: `최소값(${input.min}) 미달` };
        if (v.stepMismatch)    return { valid: false, message: `step 단위(${input.step}) 불일치` };
        if (v.badInput)        return { valid: false, message: '브라우저가 해당 타입 입력을 거부' };
      }

      // ── 숫자 전용 필드 커스텀 검증 ──
      // (type=number는 브라우저가 'abc'를 ''로 sanitize해서 validity로 못 잡음)
      if (isNumberOnly) {
        if (/^-?\d+(\.\d+)?$/.test(value)) return { valid: true, message: '숫자 형식 OK' };
        return { valid: false, message: '숫자가 아닌 값 — 이 필드는 숫자만 허용' };
      }

      // ── name / company 로컬 규칙 ──
      if (fieldType === 'name' || fieldType === 'company') {
        if (/^[0-9]+$/.test(value)) return { valid: false, message: '숫자만으로 구성 — 이름/회사명 불가' };
        if (/^[!@#$%^&*()\-_=+\[\]{};:'",.<>/?\\|`~]+$/.test(value)) {
          return { valid: false, message: '특수문자만으로 구성 — 이름/회사명 불가' };
        }
        if (/^[ㄱ-ㅎㅏ-ㅣ]+$/.test(value)) return { valid: false, message: '자음/모음만으로 구성 — 올바른 한글 아님' };
        return { valid: true, message: '입력 가능한 형식' };
      }

      // ── 이메일·전화·사업자번호: 로컬 검증 ──
      if (fieldType !== 'unknown') {
        const result = FV.localValidate(fieldType, value);
        if (result && !result.needsAI) return result;
      }

      // ── 그 외: 브라우저가 허용한 값 ──
      return { valid: true, message: '브라우저가 허용하는 값' };
    }

    // HTML 이스케이프
    function esc(str) {
      return String(str)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;')
        .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    // ── 타입 표시 정보 ──────────────────────────────
    const TYPE_INFO = {
      email:   { label: '이메일',     cls: 'fv-tag-email'   },
      phone:   { label: '전화번호',   cls: 'fv-tag-phone'   },
      name:    { label: '이름',       cls: 'fv-tag-name'    },
      company: { label: '회사명',     cls: 'fv-tag-company' },
      biznum:  { label: '사업자번호', cls: 'fv-tag-biznum'  },
    };
    function getTypeInfo(analysis) {
      if (TYPE_INFO[analysis.fieldType]) return TYPE_INFO[analysis.fieldType];
      return analysis.isNumberOnly
        ? { label: '숫자', cls: 'fv-tag-number' }
        : { label: '텍스트', cls: 'fv-tag-text' };
    }

    // 패널 생성 (빈 껍데기 — 내용은 showDiscovery / runTests 가 채움)
    function createPanel() {
      if (panel) panel.remove();
      panel = document.createElement('div');
      panel.id = 'fv-test-panel';
      panel.innerHTML = `
        <div class="fv-tp-header">
          <span class="fv-tp-title">Form Validator</span>
          <div class="fv-tp-controls">
            <button id="fv-tp-close" title="닫기">✕</button>
          </div>
        </div>
        <div class="fv-tp-progress-wrap" id="fv-tp-progress-wrap" style="display:none">
          <div class="fv-tp-progress-bar" id="fv-tp-progress-bar"></div>
        </div>
        <div class="fv-tp-summary" id="fv-tp-summary">스캔 중...</div>
        <div class="fv-tp-body" id="fv-tp-body"></div>
        <div class="fv-tp-footer" id="fv-tp-footer"></div>
      `;
      document.body.appendChild(panel);
      document.getElementById('fv-tp-close').addEventListener('click', () => {
        panel.remove();
        panel = null;
        isRunning = false;
        clearHighlight();
      });
      return panel;
    }

    // 필드 선택 화면 (Discovery 단계)
    function showDiscovery(analyses) {
      const summaryEl = document.getElementById('fv-tp-summary');
      const body      = document.getElementById('fv-tp-body');
      const footer    = document.getElementById('fv-tp-footer');
      const progWrap  = document.getElementById('fv-tp-progress-wrap');
      if (!body || !footer) return;

      body.innerHTML = '';
      footer.innerHTML = '';
      if (progWrap) progWrap.style.display = 'none';

      if (analyses.length === 0) {
        if (summaryEl) summaryEl.textContent = '이 페이지에서 테스트 가능한 입력 필드를 찾지 못했습니다.';
        return;
      }

      if (summaryEl) summaryEl.textContent = `${analyses.length}개 입력 필드 발견 — 테스트할 필드를 선택하세요`;

      const list = document.createElement('div');
      list.className = 'fv-tp-disc-list';
      analyses.forEach((a, i) => {
        const ti  = getTypeInfo(a);
        const row = document.createElement('div');
        row.className = 'fv-tp-disc-row';
        row.innerHTML = `
          <label class="fv-tp-disc-label">
            <input type="checkbox" class="fv-tp-disc-cb" data-idx="${i}" checked>
            <span class="fv-tp-disc-name" title="${esc(a.label)}">${esc(a.label)}</span>
          </label>
          <span class="fv-tp-field-tag ${ti.cls}">${ti.label}</span>
          <button class="fv-tp-disc-solo" data-idx="${i}">▶ 단독</button>
        `;
        row.querySelector('.fv-tp-disc-solo').addEventListener('click', () => runTests([a]));
        list.appendChild(row);
      });
      body.appendChild(list);

      footer.innerHTML = `
        <button class="fv-btn-run" id="fv-tp-run-all">▶ 전체 테스트</button>
        <button class="fv-btn-sec" id="fv-tp-run-sel">▶ 선택 항목만</button>
      `;
      document.getElementById('fv-tp-run-all').addEventListener('click', () => runTests(analyses));
      document.getElementById('fv-tp-run-sel').addEventListener('click', () => {
        const checked = [...body.querySelectorAll('.fv-tp-disc-cb:checked')]
          .map(cb => analyses[+cb.dataset.idx]);
        if (checked.length > 0) runTests(checked);
      });
    }

    // 현재 테스트 중인 인풋 하이라이트
    function highlightInput(input) {
      clearHighlight();
      input.classList.add('fv-test-active');
      input.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
    function clearHighlight() {
      document.querySelectorAll('.fv-test-active').forEach(el => el.classList.remove('fv-test-active'));
    }

    // 케이스 목록 열기 / 닫기 (display:none이 CSS에 있어서 명시적 inline style 필요)
    function showCasesEl(index) {
      const el = document.getElementById(`fv-tp-cases-${index}`);
      const ch = document.querySelector(`[data-idx="${index}"] .fv-tp-chevron`);
      if (el) el.style.display = 'block';
      if (ch) ch.textContent = '▼';
    }
    function hideCasesEl(index) {
      const el = document.getElementById(`fv-tp-cases-${index}`);
      const ch = document.querySelector(`[data-idx="${index}"] .fv-tp-chevron`);
      if (el) el.style.display = 'none';
      if (ch) ch.textContent = '▶';
    }

    // 인풋 행 추가
    function addInputRow(analysis, index) {
      const body = document.getElementById('fv-tp-body');
      if (!body) return;
      const row = document.createElement('div');
      row.className = 'fv-tp-input-row';
      row.innerHTML = `
        <div class="fv-tp-input-header" data-idx="${index}">
          <span class="fv-tp-chevron">▶</span>
          <span class="fv-tp-input-name" title="${esc(analysis.label)}">${esc(analysis.label)}</span>
          <span class="fv-tp-input-status" id="fv-tp-status-${index}">대기 중</span>
        </div>
        <div class="fv-tp-cases" id="fv-tp-cases-${index}"></div>
      `;
      // 헤더 클릭 → 케이스 토글
      row.querySelector('.fv-tp-input-header').addEventListener('click', () => {
        const cases = document.getElementById(`fv-tp-cases-${index}`);
        if (!cases) return;
        const isVisible = cases.style.display === 'block';
        isVisible ? hideCasesEl(index) : showCasesEl(index);
      });
      body.appendChild(row);
    }

    // 케이스 결과 추가
    function addCaseResult(index, testCase, result, pageError) {
      const casesEl = document.getElementById(`fv-tp-cases-${index}`);
      if (!casesEl) return;
      const icon  = result.valid === true ? '✓' : result.valid === false ? '✗' : '?';
      const cls   = result.valid === true ? 'pass' : result.valid === false ? 'fail' : 'skip';
      const dispVal = testCase.value.length > 30
        ? testCase.value.slice(0, 30) + '…'
        : testCase.value || '(빈 값)';
      const el = document.createElement('div');
      el.className = `fv-tp-case fv-case-${cls}`;
      el.innerHTML = `
        <span class="fvc-icon">${icon}</span>
        <span class="fvc-label">${esc(testCase.label)}</span>
        <span class="fvc-value">"${esc(dispVal)}"</span>
        <span class="fvc-msg">${esc(result.message || '')}</span>
      `;
      casesEl.appendChild(el);
      if (pageError) {
        const pe = document.createElement('div');
        pe.className = 'fvc-page-error';
        pe.textContent = '🔴 페이지 오류: ' + pageError;
        casesEl.appendChild(pe);
      }
    }

    // 진행률 업데이트
    function updateProgress(done, total) {
      const wrap = document.getElementById('fv-tp-progress-wrap');
      const bar  = document.getElementById('fv-tp-progress-bar');
      if (wrap) wrap.style.display = 'block';
      if (bar)  bar.style.width = `${Math.round((done / total) * 100)}%`;
    }

    // 진입점: 스캔 후 필드 선택 화면 표시
    function run() {
      if (isRunning) return;
      createPanel();
      const inputs   = scanInputs();
      const analyses = inputs.map(analyzeInput);
      showDiscovery(analyses);
    }

    // 테스트 실행 (선택된 analyses 배열)
    async function runTests(analyses) {
      if (isRunning) return;
      isRunning = true;
      testModeRunning = true;
      allResults = [];

      const body      = document.getElementById('fv-tp-body');
      const footer    = document.getElementById('fv-tp-footer');
      const summaryEl = document.getElementById('fv-tp-summary');

      // 결과 뷰로 전환
      if (body) body.innerHTML = `
        <div class="fv-tp-legend">
          <span class="fvleg-pass">✓ 허용</span>
          <span class="fvleg-fail">✗ 오류</span>
          <span class="fvleg-skip">? 직접확인 — 규칙을 자동으로 알 수 없는 값</span>
        </div>
      `;
      if (footer) footer.innerHTML = '';
      if (summaryEl) summaryEl.textContent = `${analyses.length}개 필드 테스트 중...`;

      analyses.forEach((a, i) => addInputRow(a, i));

      let totalPass = 0, totalFail = 0, totalSkip = 0;

      for (let i = 0; i < analyses.length; i++) {
        const analysis = analyses[i];
        const statusEl = document.getElementById(`fv-tp-status-${i}`);
        if (statusEl) { statusEl.textContent = '테스트 중...'; statusEl.className = 'fv-tp-input-status st-testing'; }

        const input = analysis.input;
        const originalValue = input.value;

        const NEUTRAL_BY_TYPE = {
          biznum:  '1018687524',
          email:   'test@example.com',
          phone:   '01012345678',
          name:    '홍길동',
          company: '테스트회사',
        };
        const neutralVal = NEUTRAL_BY_TYPE[analysis.fieldType]
          || (analysis.isNumberOnly ? '12345' : 'aaaaaa');
        input.dispatchEvent(new FocusEvent('focus', { bubbles: true }));
        input.value = neutralVal;
        input.dispatchEvent(new Event('input', { bubbles: true }));
        await new Promise(r => setTimeout(r, 150));

        highlightInput(input);
        showCasesEl(i);

        const inputResults = [];

        for (let tcIdx = 0; tcIdx < analysis.testCases.length; tcIdx++) {
          const tc = analysis.testCases[tcIdx];

          if (tcIdx > 0) {
            input.dispatchEvent(new FocusEvent('focus', { bubbles: true }));
            input.value = neutralVal;
            input.dispatchEvent(new Event('input', { bubbles: true }));
            await new Promise(r => setTimeout(r, 150));
          }

          const beforeSnap = snapErrors(input);

          input.value = tc.value;
          input.dispatchEvent(new Event('input', { bubbles: true }));
          await new Promise(r => setTimeout(r, 120));

          const browserSanitized = tc.value !== '' && input.value !== tc.value;

          input.dispatchEvent(new FocusEvent('blur', { bubbles: true }));
          input.dispatchEvent(new FocusEvent('focusout', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
          await new Promise(r => setTimeout(r, 300));

          const pageError   = findNewError(input, beforeSnap);
          const localResult = browserSanitized ? null : validateCase(input, analysis.fieldType, analysis.isNumberOnly, tc.value);
          let result;
          if (browserSanitized) {
            const storedValue = input.value;
            if (storedValue === '') {
              const expectsError = tc.expect === 'invalid' || tc.expect === 'empty';
              if (expectsError) {
                result = { valid: true, message: '브라우저가 입력 차단 — 이 필드에 입력 불가 (정상)' };
              } else if (tc.expect === 'valid') {
                result = { valid: false, message: '브라우저가 유효한 값을 거부' };
              } else {
                result = { valid: null, message: '브라우저가 해당 값을 저장하지 않음' };
              }
            } else {
              const ml = input.maxLength;
              const isMaxLen = ml > 0 && storedValue === tc.value.slice(0, ml);
              if (pageError !== null) {
                const expectsError = tc.expect === 'invalid' || tc.expect === 'empty' || tc.expect === 'boundary';
                if (expectsError) {
                  result = { valid: true, message: `오류 정상 감지 — ${pageError}` };
                } else if (tc.expect === 'valid') {
                  result = { valid: false, message: `유효한 값인데 오류 발생 — ${pageError}` };
                } else {
                  result = { valid: null, message: `페이지 오류 표시 — ${pageError}` };
                }
              } else {
                result = { valid: null, message: isMaxLen
                  ? `최대 ${ml}자까지만 허용 (잘림)`
                  : '입력 불가 (허용되지 않는 값 자동 삭제됨)' };
              }
            }
          } else if (pageError !== null) {
            const expectsError = tc.expect === 'invalid' || tc.expect === 'empty' || tc.expect === 'boundary';
            if (expectsError) {
              result = { valid: true, message: `오류 정상 감지 — ${pageError}` };
            } else if (tc.expect === 'valid') {
              result = { valid: false, message: `유효한 값인데 오류 발생 — ${pageError}` };
            } else {
              result = { valid: null, message: `페이지 오류 표시 — ${pageError}` };
            }
          } else {
            result = localResult;
          }
          addCaseResult(i, tc, result, null);
          inputResults.push({ testCase: tc, result, pageError });

          if (result.valid === true)  totalPass++;
          else if (result.valid === false) totalFail++;
          else totalSkip++;

          await new Promise(r => setTimeout(r, 80));
        }

        input.value = originalValue;
        input.dispatchEvent(new Event('input', { bubbles: true }));

        allResults.push({ ...analysis, results: inputResults });
        updateProgress(i + 1, analyses.length);

        const passed = inputResults.filter(r => r.result.valid === true).length;
        const failed = inputResults.filter(r => r.result.valid === false).length;
        if (statusEl) {
          statusEl.textContent = `✓${passed} ✗${failed}`;
          statusEl.className = `fv-tp-input-status ${failed > 0 ? 'st-fail' : 'st-pass'}`;
        }
        if (i < analyses.length - 1) hideCasesEl(i);
      }

      clearHighlight();
      if (summaryEl) {
        summaryEl.innerHTML =
          `완료: <strong>${analyses.length}개 필드</strong> &nbsp;|&nbsp; ` +
          `<span style="color:#155724">✓ ${totalPass} 허용</span> &nbsp;|&nbsp; ` +
          `<span style="color:#721c24">✗ ${totalFail} 오류</span> &nbsp;|&nbsp; ` +
          `<span style="color:#495057">? ${totalSkip} 직접확인</span>`;
      }
      testModeRunning = false;
      isRunning = false;

      // 결과 뷰 footer
      if (footer) {
        footer.innerHTML = `
          <button class="fv-btn-sec" id="fv-tp-back">← 필드 선택</button>
          <button class="fv-btn-run" id="fv-tp-rerun">↺ 재실행</button>
          <button class="fv-btn-sec" id="fv-tp-copy">📋 복사</button>
          <button class="fv-btn-sec" id="fv-tp-download">⬇ CSV</button>
        `;
        document.getElementById('fv-tp-rerun').addEventListener('click', () => {
          allResults = [];
          isRunning = false;
          testModeRunning = false;
          clearHighlight();
          runTests(analyses);
        });
        document.getElementById('fv-tp-back').addEventListener('click', () => {
          allResults = [];
          isRunning = false;
          testModeRunning = false;
          clearHighlight();
          const progWrap = document.getElementById('fv-tp-progress-wrap');
          if (progWrap) progWrap.style.display = 'none';
          const inputs2   = scanInputs();
          const analyses2 = inputs2.map(analyzeInput);
          showDiscovery(analyses2);
        });
        document.getElementById('fv-tp-copy').addEventListener('click', copyTSV);
        document.getElementById('fv-tp-download').addEventListener('click', downloadCSV);
      }
    }

    // ── 내보내기 ──────────────────────────────────
    function buildRows() {
      const rows = [['필드명', '숫자전용', '테스트값', '테스트 설명', '예상', '결과', '메시지', '페이지 오류']];
      for (const r of allResults) {
        for (const { testCase, result, pageError } of r.results) {
          rows.push([
            r.label,
            r.isNumberOnly ? 'Y' : 'N',
            testCase.value,
            testCase.label,
            testCase.expect,
            result.valid === true ? 'PASS' : result.valid === false ? 'FAIL' : 'SKIP',
            result.message || '',
            pageError || ''
          ]);
        }
      }
      return rows;
    }

    function toTSV(rows) {
      return rows.map(row =>
        row.map(v => `"${String(v).replace(/"/g, '""')}"`).join('\t')
      ).join('\n');
    }

    function copyTSV() {
      if (allResults.length === 0) return;
      navigator.clipboard.writeText(toTSV(buildRows())).then(() => {
        const btn = document.getElementById('fv-tp-copy');
        if (btn) { btn.textContent = '✓ 복사됨!'; setTimeout(() => { btn.textContent = '📋 복사'; }, 2000); }
      });
    }

    function downloadCSV() {
      if (allResults.length === 0) return;
      const csv = buildRows()
        .map(row => row.map(v => `"${String(v).replace(/"/g, '""')}"`).join(','))
        .join('\n');
      const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
      const url  = URL.createObjectURL(blob);
      const a    = document.createElement('a');
      a.href     = url;
      a.download = `form-test-${new Date().toISOString().slice(0, 10)}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    }

    return { run };
  })();

  // 팝업에서 테스트 시작 메시지 수신
  chrome.runtime.onMessage.addListener((message) => {
    if (message.action === 'startTest') {
      TestMode.run();
    }
  });

})();
