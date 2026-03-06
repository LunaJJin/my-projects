// validator.js - 로컬 검증 로직 (content.js보다 먼저 로드됨)

window.FV = window.FV || {};

// ────────────────────────────────────────────────
// 필드 타입 상수
// ────────────────────────────────────────────────
FV.FieldType = {
  EMAIL:   'email',
  PHONE:   'phone',
  NAME:    'name',
  COMPANY: 'company',
  BIZNUM:  'biznum',
  UNKNOWN: 'unknown'  // 타입 불명 — 기본 DOM 검증만 적용
};

// ────────────────────────────────────────────────
// 필드 타입 감지
// input 요소의 여러 속성(type, name, id, placeholder, label 등)을 조합해서 판단
// ────────────────────────────────────────────────
FV.detectFieldType = function(input) {
  // 텍스트 입력이 아닌 타입 제외 (버튼, 체크박스, 파일 등)
  const NON_TEXT = ['hidden', 'submit', 'button', 'reset', 'image', 'checkbox', 'radio', 'file', 'color', 'range'];
  if (NON_TEXT.includes(input.type)) return null;

  // 날짜/시간 타입은 브라우저가 자체 검증하므로 제외
  const SELF_VALIDATED = ['date', 'time', 'datetime-local', 'month', 'week'];
  if (SELF_VALIDATED.includes(input.type)) return null;

  // 보조/장식 요소 제외
  if (input.getAttribute('aria-hidden') === 'true') return null;
  if (input.getAttribute('role') === 'presentation') return null;
  // 자동 높이 계산용 미러 textarea (readonly + tabindex="-1") 제외
  if (input.readOnly && input.getAttribute('tabindex') === '-1') return null;

  const labelEl = input.id
    ? document.querySelector(`label[for="${CSS.escape(input.id)}"]`)
    : null;

  const signals = [
    input.type        || '',
    input.name        || '',
    input.id          || '',
    input.placeholder || '',
    input.autocomplete || '',
    input.getAttribute('data-field') || '',
    input.getAttribute('aria-label') || '',
    input.getAttribute('wds-component') || '',
    input.getAttribute('data-type') || '',
    input.getAttribute('data-label') || '',
    labelEl ? labelEl.textContent : ''
  ].join(' ').toLowerCase();

  // 사업자등록번호 — 전화번호보다 먼저 체크 (숫자 패턴 겹침 방지)
  if (/사업자|biznum|business[\W_]?num|사업자등록/.test(signals)) {
    return FV.FieldType.BIZNUM;
  }

  // 이메일
  if (input.type === 'email' || /email|이메일|e-mail|메일주소/.test(signals)) {
    return FV.FieldType.EMAIL;
  }

  // 휴대폰 / 전화번호
  if (input.type === 'tel' || /phone|mobile|휴대|핸드폰|전화|연락처/.test(signals)) {
    return FV.FieldType.PHONE;
  }

  // 이름 — 단독 'name' 키워드 우선 매칭 (단, "company_name" 등 다른 타입의 name 속성은 제외)
  if (/성명|이름|fullname|firstname|lastname|성함/.test(signals) ||
      /\bname\b/.test(signals) && !/company|corp|회사|기업|업체|법인/.test(signals)) {
    return FV.FieldType.NAME;
  }

  // 회사명 / 기업명 — "회사 소개", "회사/직무 소개" 같은 소개글 필드 오탐 방지
  if (/company|corp|회사명|기업명|업체명|법인명|organization/.test(signals) ||
      /\b(회사|기업|업체|법인)\s*(이름|name|입력)/.test(signals)) {
    return FV.FieldType.COMPANY;
  }

  // 그 외 모든 텍스트 입력 필드 → AI가 타입 판단 + 검증
  return FV.FieldType.UNKNOWN;
};

// ────────────────────────────────────────────────
// 로컬 검증 디스패처
// 반환값: { valid, message, needsAI }
//   valid   : true | false | null(불확실)
//   needsAI : true → background.js로 AI 검증 요청
// ────────────────────────────────────────────────
FV.localValidate = function(fieldType, value) {
  const trimmed = value.trim();

  switch (fieldType) {
    case FV.FieldType.EMAIL:
      return FV._validateEmail(trimmed);

    case FV.FieldType.PHONE:
      return FV._validatePhone(trimmed);

    case FV.FieldType.BIZNUM:
      return FV._validateBizNum(trimmed);

    case FV.FieldType.NAME:
      return FV._validateName(trimmed);

    case FV.FieldType.COMPANY:
      return FV._validateCompany(trimmed);

    case FV.FieldType.UNKNOWN:
      return null; // 타입 불명 — 검증 생략

    default:
      return null;
  }
};

// ────────────────────────────────────────────────
// 이메일 검증 (RFC 5322 간이 regex)
// ────────────────────────────────────────────────
FV._validateEmail = function(value) {
  if (!value) {
    return { valid: false, message: '이메일을 입력해주세요.', needsAI: false };
  }
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
  if (!regex.test(value)) {
    return { valid: false, message: '이메일 형식이 아닙니다. (예: user@example.com)', needsAI: false };
  }
  return { valid: true, message: '올바른 이메일 형식입니다.', needsAI: false };
};

// ────────────────────────────────────────────────
// 휴대폰 번호 검증 (한국 기준: 010/011/016/017/018/019)
// ────────────────────────────────────────────────
FV._validatePhone = function(value) {
  if (!value) {
    return { valid: false, message: '휴대폰 번호를 입력해주세요.', needsAI: false };
  }
  const cleaned = value.replace(/[\s\-\.]/g, '');
  if (!/^01[016789]\d{7,8}$/.test(cleaned)) {
    return { valid: false, message: '올바른 휴대폰 번호 형식이 아닙니다. (예: 010-1234-5678)', needsAI: false };
  }
  return { valid: true, message: '올바른 휴대폰 번호입니다.', needsAI: false };
};

// ────────────────────────────────────────────────
// 테스트 모드 지원 함수
// ────────────────────────────────────────────────

// 숫자 전용 입력 여부 감지
FV.isNumberOnlyInput = function(input) {
  if (input.type === 'number') return true;
  const im = (input.inputMode || input.getAttribute('inputmode') || '').toLowerCase();
  if (im === 'numeric' || im === 'decimal') return true;
  const pattern = input.getAttribute('pattern') || '';
  if (pattern && /^\^?\[?[\\d0-9]/.test(pattern)) return true;
  const cls = (input.className || '').toLowerCase();
  if (/\bnumber\b|\bnumeric\b|\bdigit\b/.test(cls)) return true;
  return false;
};

// 입력 필드 레이블 수집 (우선순위 순)
FV.getInputLabel = function(input) {
  if (input.id) {
    const label = document.querySelector(`label[for="${CSS.escape(input.id)}"]`);
    if (label && label.textContent.trim()) return label.textContent.trim();
  }
  const ariaLabel = input.getAttribute('aria-label');
  if (ariaLabel) return ariaLabel;
  if (input.placeholder) return input.placeholder;
  if (input.name) return input.name;
  if (input.id) return `#${input.id}`;
  return '(알 수 없음)';
};

// 필드 타입별 테스트 케이스 반환
FV.getTestCases = function(fieldType, isNumberOnly) {
  if (isNumberOnly) {
    return [
      { value: '123',        label: '3자리 숫자',  expect: 'boundary' },
      { value: '2000',       label: '4자리 숫자',  expect: 'boundary' },
      { value: '20000',      label: '5자리 숫자',  expect: 'boundary' },
      { value: '1234567890', label: '10자리 숫자', expect: 'boundary' },
      { value: '0',          label: '0',           expect: 'boundary' },
      { value: '-1',         label: '음수',         expect: 'boundary' },
      { value: '1.5',        label: '소수',         expect: 'boundary' },
      { value: 'abc',        label: '영문자',       expect: 'invalid'  },
      { value: '!@#$',       label: '특수문자',     expect: 'invalid'  },
      { value: '',           label: '빈 값',        expect: 'empty'    },
    ];
  }

  const CASES = {
    email: [
      { value: 'test@example.com',           label: '정상 이메일',    expect: 'valid'    },
      { value: 'user.name+tag@domain.co.kr', label: '복잡한 이메일', expect: 'valid'    },
      { value: 'testexample.com',            label: '@ 없음',        expect: 'invalid'  },
      { value: 'test@',                      label: '도메인 없음',   expect: 'invalid'  },
      { value: '@example.com',               label: '로컬 없음',     expect: 'invalid'  },
      { value: 'test @example.com',          label: '공백 포함',     expect: 'invalid'  },
      { value: '',                           label: '빈 값',         expect: 'empty'    },
    ],
    phone: [
      { value: '010-1234-5678', label: '정상 (하이픈)',   expect: 'valid'    },
      { value: '01012345678',   label: '정상 (숫자만)',   expect: 'valid'    },
      { value: '011-9999-9999', label: '구형 번호',      expect: 'valid'    },
      { value: '010-1234',      label: '자릿수 부족',    expect: 'invalid'  },
      { value: '02-1234-5678',  label: '지역번호 형식',  expect: 'boundary' },
      { value: '010-abc-defg',  label: '문자 포함',      expect: 'invalid'  },
      { value: '',              label: '빈 값',          expect: 'empty'    },
    ],
    name: [
      { value: '홍길동',    label: '한국 이름 3자',  expect: 'valid'    },
      { value: '김수',      label: '한국 이름 2자',  expect: 'valid'    },
      { value: 'John Doe',  label: '영어 이름',      expect: 'valid'    },
      { value: 'María',     label: '특수문자 포함 영어', expect: 'valid' },
      { value: '1234',      label: '숫자만',          expect: 'invalid'  },
      { value: '!@#$',      label: '특수문자만',      expect: 'invalid'  },
      { value: 'ㅁㄴㅇㄹ', label: '자음만',          expect: 'invalid'  },
      { value: '',          label: '빈 값',           expect: 'empty'    },
    ],
    company: [
      { value: '(주)삼성전자',    label: '법인 형식',    expect: 'valid'    },
      { value: '네이버 주식회사', label: '주식회사 형식', expect: 'valid'   },
      { value: 'Google Inc.',     label: '영문 회사명',  expect: 'valid'    },
      { value: '1234',            label: '숫자만',       expect: 'invalid'  },
      { value: '!@#$%',           label: '특수문자만',   expect: 'invalid'  },
      { value: 'ㅁㄴㅇㄹ',        label: '자음만',       expect: 'invalid'  },
      { value: '',                label: '빈 값',        expect: 'empty'    },
    ],
    biznum: [
      { value: '101-86-87524',  label: '유효한 번호',  expect: 'valid'    },
      { value: '123-45-67890',  label: '체크섬 오류',  expect: 'invalid'  },
      { value: '123-45-678',    label: '자릿수 부족',  expect: 'invalid'  },
      { value: 'abc-de-fghij',  label: '문자 포함',    expect: 'invalid'  },
      { value: '',              label: '빈 값',        expect: 'empty'    },
    ],
  };

  return CASES[fieldType] || [
    { value: '안녕하세요',               label: '한국어 텍스트',    expect: 'valid'    },
    { value: 'Hello World',              label: '영어 텍스트',      expect: 'valid'    },
    { value: '12345',                    label: '숫자 텍스트',      expect: 'boundary' },
    { value: '!@#$%^&*()',              label: '특수문자',          expect: 'boundary' },
    { value: 'A'.repeat(200),           label: '200자 긴 텍스트',  expect: 'boundary' },
    { value: '<script>alert(1)</script>', label: 'XSS 패턴',       expect: 'boundary' },
    { value: "'; DROP TABLE users; --",  label: 'SQL 인젝션 패턴', expect: 'boundary' },
    { value: '',                         label: '빈 값',            expect: 'empty'    },
  ];
};

// ────────────────────────────────────────────────
// 이름 검증 (한국인 / 외국인 / 혼합)
// ────────────────────────────────────────────────
FV._validateName = function(value) {
  if (!value) return { valid: false, message: '이름을 입력해주세요.', needsAI: false };

  const hasKorean = /[가-힣]/.test(value);
  const hasLatin  = /[a-zA-ZÀ-ÖØ-öø-ÿ]/.test(value);

  // 자음/모음만 → 무효
  if (/^[ㄱ-ㅎㅏ-ㅣ]+$/.test(value)) {
    return { valid: false, message: '자음/모음만으로 구성된 값은 올바른 이름이 아닙니다.', needsAI: false };
  }
  // 글자(한글/영문)가 전혀 없으면 이름 불가
  if (!hasKorean && !hasLatin) {
    return { valid: false, message: '이름에 문자(한글 또는 영문)가 포함되어야 합니다.', needsAI: false };
  }
  // 키보드 연타 패턴 → 무효
  const SMASH = ['ㅁㄴㅇㄹ', 'ㅂㅈㄷㄱ', 'ㅅㅎㅊㅋ', 'asdf', 'qwer', 'zxcv', 'hjkl'];
  if (SMASH.some(s => value.toLowerCase().includes(s))) {
    return { valid: false, message: '의미 없는 키보드 연타로 보입니다.', needsAI: false };
  }
  // 동일 문자 3회 이상 반복 → 무효
  if (/(.)\1{2,}/.test(value)) {
    return { valid: false, message: '동일 문자가 3회 이상 반복된 값은 이름이 아닙니다.', needsAI: false };
  }
  // 순수 한글 이름 1~5자
  if (hasKorean && !hasLatin) {
    if (value.length > 5) {
      return { valid: false, message: '한국인 이름은 일반적으로 5자 이하입니다.', needsAI: false };
    }
    return { valid: true, message: '올바른 이름 형식입니다.', needsAI: false };
  }
  // 영문 이름 (악센트 포함): 2~50자, 글자·공백·하이픈·어포스트로피만 허용
  if (!hasKorean && hasLatin) {
    if (value.length < 2)  return { valid: false, message: '이름은 최소 2자 이상이어야 합니다.', needsAI: false };
    if (value.length > 50) return { valid: false, message: '이름은 50자 이하이어야 합니다.', needsAI: false };
    if (!/^[a-zA-ZÀ-ÖØ-öø-ÿ]+([\s\-'][a-zA-ZÀ-ÖØ-öø-ÿ]+)*$/.test(value)) {
      return { valid: false, message: '이름에 허용되지 않는 문자가 포함되어 있습니다.', needsAI: false };
    }
    return { valid: true, message: '올바른 이름 형식입니다.', needsAI: false };
  }
  // 한+영 혼합
  return { valid: true, message: '혼합 이름 형식입니다.', needsAI: false };
};

// ────────────────────────────────────────────────
// 회사명 검증
// ────────────────────────────────────────────────
FV._validateCompany = function(value) {
  if (!value) return { valid: false, message: '회사명을 입력해주세요.', needsAI: false };
  if (value.length < 2)   return { valid: false, message: '회사명은 최소 2자 이상이어야 합니다.', needsAI: false };
  if (value.length > 100) return { valid: false, message: '회사명은 100자 이하이어야 합니다.', needsAI: false };

  // 자음/모음만 → 무효
  if (/^[ㄱ-ㅎㅏ-ㅣ]+$/.test(value)) {
    return { valid: false, message: '자음/모음만으로 구성된 값은 회사명이 아닙니다.', needsAI: false };
  }
  // 숫자만 → 무효
  if (/^[0-9]+$/.test(value)) {
    return { valid: false, message: '숫자만으로 구성된 값은 회사명이 아닙니다.', needsAI: false };
  }
  // 글자(한글/영문/숫자)가 하나도 없으면 무효
  if (!/[가-힣a-zA-Z0-9]/.test(value)) {
    return { valid: false, message: '회사명에 문자 또는 숫자가 포함되어야 합니다.', needsAI: false };
  }
  // 키보드 연타 → 무효
  const SMASH = ['ㅁㄴㅇㄹ', 'ㅂㅈㄷㄱ', 'asdf', 'qwer', 'zxcv'];
  if (SMASH.some(s => value.toLowerCase().includes(s))) {
    return { valid: false, message: '의미 없는 키보드 연타로 보입니다.', needsAI: false };
  }
  // 동일 문자 4회 이상 반복 → 무효
  if (/(.)\1{3,}/.test(value)) {
    return { valid: false, message: '동일 문자가 4회 이상 반복된 값은 회사명이 아닙니다.', needsAI: false };
  }
  return { valid: true, message: '회사명 형식입니다.', needsAI: false };
};

// ────────────────────────────────────────────────
// 사업자등록번호 검증 (체크섬 포함)
// ────────────────────────────────────────────────
FV._validateBizNum = function(value) {
  if (!value) {
    return { valid: false, message: '사업자등록번호를 입력해주세요.', needsAI: false };
  }

  const cleaned = value.replace(/[^0-9]/g, '');

  if (cleaned.length !== 10) {
    return { valid: false, message: '사업자등록번호는 10자리입니다. (예: 123-45-67890)', needsAI: false };
  }

  // 체크섬 알고리즘 (국세청 기준)
  const weights = [1, 3, 7, 1, 3, 7, 1, 3, 5];
  let sum = 0;
  for (let i = 0; i < 9; i++) {
    sum += parseInt(cleaned[i]) * weights[i];
  }
  sum += Math.floor((parseInt(cleaned[8]) * 5) / 10);
  const checkDigit = (10 - (sum % 10)) % 10;

  if (checkDigit !== parseInt(cleaned[9])) {
    return { valid: false, message: '유효하지 않은 사업자등록번호입니다. (체크섬 불일치)', needsAI: false };
  }

  return { valid: true, message: '유효한 사업자등록번호입니다.', needsAI: false };
};
