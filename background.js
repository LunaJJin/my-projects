// background.js - Service Worker: Claude API 호출

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message.action === 'validate') {
    handleValidation(message)
      .then(sendResponse)
      .catch((err) => sendResponse({ error: err.message }));
    return true; // 비동기 sendResponse 유지
  }
});

// ──────────────────────────────────────────────────
// 메인 검증 핸들러
// ──────────────────────────────────────────────────
async function handleValidation({ fieldType, value, fieldContext }) {
  const { apiKey } = await chrome.storage.local.get('apiKey');

  if (!apiKey) {
    return { error: 'API 키 미설정. 익스텐션 팝업에서 Claude API 키를 입력해주세요.' };
  }

  const prompt = fieldType === 'unknown'
    ? buildUnknownPrompt(value, fieldContext)
    : buildPrompt(fieldType, value);

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
      'anthropic-dangerous-direct-browser-access': 'true'
    },
    body: JSON.stringify({
      model: 'claude-haiku-4-5-20251001', // 빠르고 저렴한 모델 사용
      max_tokens: 200,
      messages: [{ role: 'user', content: prompt }]
    })
  });

  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    const msg = body?.error?.message || `API 오류 (${response.status})`;
    throw new Error(msg);
  }

  const data = await response.json();
  const text = data.content?.[0]?.text?.trim() || '';

  // JSON 파싱
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) throw new Error('AI 응답 파싱 실패');

  return JSON.parse(match[0]);
}

// ──────────────────────────────────────────────────
// 알 수 없는 필드: AI가 타입 판단 + 검증
// ──────────────────────────────────────────────────
function buildUnknownPrompt(value, fieldContext) {
  const ctx = [
    fieldContext.label        && `레이블: "${fieldContext.label}"`,
    fieldContext.placeholder  && `플레이스홀더: "${fieldContext.placeholder}"`,
    fieldContext.ariaLabel    && `aria-label: "${fieldContext.ariaLabel}"`,
    fieldContext.wdsComponent && `컴포넌트 유형: "${fieldContext.wdsComponent}"`,
    fieldContext.name         && `name 속성: "${fieldContext.name}"`,
    fieldContext.id           && `id 속성: "${fieldContext.id}"`,
    fieldContext.nearbyText   && `주변 텍스트: "${fieldContext.nearbyText}"`,
    fieldContext.inputType && fieldContext.inputType !== 'text' && `input type: "${fieldContext.inputType}"`
  ].filter(Boolean).join('\n');

  return `당신은 웹 폼 입력값 검증 전문가입니다. 아래 필드 정보와 입력값을 분석하세요.

[필드 정보]
${ctx || '(속성 정보 없음)'}

[사용자 입력값]
"${value}"

판단 기준:
1. 필드가 요구하는 데이터 유형을 추론하세요 (이름/이메일/전화번호/주소/URL/제목/날짜/금액/기타).
2. 숫자만 입력 가능한 필드인지(acceptsNumberOnly) 판단하세요.
3. 입력값이 해당 필드에 적합한지 검증하세요.
4. 부적합하다면 구체적인 이유를 한국어로 설명하세요.

반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트는 절대 포함하지 마세요:
{"detectedType":"감지된 필드 유형(한국어)","acceptsNumberOnly":false,"valid":true,"message":"한국어 결과 메시지"}`;
}

// ──────────────────────────────────────────────────
// 알려진 필드 타입별 프롬프트 생성
// ──────────────────────────────────────────────────
function buildPrompt(fieldType, value) {
  const RULES = {
    name: `검증 기준:
- 한국인 이름: 한글 2~5자 (외자 허용)
- 외국인 이름: 영문·공백 2~50자, 악센트 문자 허용
- 혼합(한+영) 이름: 허용
- 숫자·특수문자로만 구성 → 무효
- 의미없는 키보드 연타(ㅁㄴㅇㄹ, asdf, qwer 등) → 무효
- 단순 반복 문자(aaaa, 가가가가) → 무효`,

    company: `검증 기준:
- 한국 또는 외국 법인명·브랜드명
- 2~100자
- (주), (유), Inc., Co., Ltd., LLC 등 법인 표기 포함 가능
- 숫자만으로 구성 → 무효
- 특수문자만으로 구성 → 무효
- 의미없는 키보드 연타 → 무효
- 실제 존재하지 않더라도 회사명으로 타당한 형식이면 유효`
  };

  const LABEL = { name: '이름(한국인 또는 외국인)', company: '회사명 또는 기업명' };

  return `당신은 폼 입력값 검증 전문가입니다.

필드: ${LABEL[fieldType]}
입력값: "${value}"

${RULES[fieldType]}

반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트는 절대 포함하지 마세요:
{"valid":true,"message":"한국어 결과 메시지"}
또는
{"valid":false,"message":"한국어 결과 메시지 (구체적인 사유 포함)"}`;
}
