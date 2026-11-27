// Vercel Serverless API: 실시간 통신사 공시지원금 변동내역 조회 및 Firestore 동기화
// 대상 범위: 갤럭시 S시리즈, FE시리즈, 아이폰, 폴더블류 모델 한정

const FIRESTORE_DOC_URL =
  'https://firestore.googleapis.com/v1/projects/phone-price-91c3c/databases/(default)/documents/global_config/subsidy_changes';

function getKstTodayStr() {
  const kstNow = new Date(Date.now() + 9 * 60 * 60 * 1000);
  return kstNow.toISOString().slice(0, 10);
}

function normalizeDateStr(raw) {
  if (!raw) return '';
  const digits = String(raw).replace(/[^0-9]/g, '');
  if (digits.length >= 8) {
    return `${digits.slice(0, 4)}-${digits.slice(4, 6)}-${digits.slice(6, 8)}`;
  }
  return '';
}

function isTargetFlagshipModel(name) {
  if (!name) return false;
  const s = String(name).trim();
  if (/워치|Watch|버즈|Buds|태블릿|Tab|패드|Pad|키즈|Kids|산리오|시나모롤|포켓몬|캐치티니핑|갤럭시\s*A|Galaxy\s*A|SM-A\d+|퀀텀|와이드|점프|버디|샤오미|홍미|Redmi|모토|Moto|ZTE|시니어|스타일|클래식\s*폴더|폴더2/i.test(s)) {
    return false;
  }
  return /(iPhone|아이폰|갤럭시\s*S|Galaxy\s*S|\bS2[0-9]|폴드|Fold|플립|Flip|듀오|Duo|\bFE\b|S\d+\s*FE|엣지|Edge)/i.test(s);
}

function fromFsValue(v) {
  if (!v || typeof v !== 'object') return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return Number(v.doubleValue);
  if ('booleanValue' in v) return Boolean(v.booleanValue);
  if ('nullValue' in v) return null;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(fromFsValue);
  if ('mapValue' in v) {
    const out = {};
    const fields = v.mapValue.fields || {};
    for (const k of Object.keys(fields)) out[k] = fromFsValue(fields[k]);
    return out;
  }
  return null;
}

function toFsValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    return Number.isInteger(val) ? { integerValue: String(val) } : { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(toFsValue) } };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const k of Object.keys(val)) {
      if (val[k] !== undefined) fields[k] = toFsValue(val[k]);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

async function fetchSktBest109() {
  const url = 'https://shop.tworld.co.kr/notice?scrbTypCd=20&prodId=NA00009800';
  const res = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
  });
  if (!res.ok) throw new Error(`SKT HTTP ${res.status}`);
  const html = await res.text();
  const m = html.match(/_this\.products\s*=\s*parseObject\((\[[\s\S]*?\])\);/);
  if (!m) throw new Error('SKT product payload not found');
  const raw = JSON.parse(m[1]);
  const map = {};
  for (const p of raw) {
    const fullName = `${p.productNm || ''} ${p.productMem || ''}`.trim();
    if (!isTargetFlagshipModel(fullName)) continue;
    const code = p.modelCd || fullName;
    map[code] = {
      modelName: fullName,
      modelCode: p.modelCd || '',
      factoryPriceWon: Number(p.factoryPrice) || 0,
      subsidyWon: Number(p.telecomSaleAmt) || 0,
      effDate: normalizeDateStr(p.effStaDt)
    };
  }
  return map;
}

module.exports = async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  try {
    // 1. Firestore 기존 문서 조회
    let existingChanges = [];
    let prevSktSnapshot = {};
    let docExists = false;

    const fsGet = await fetch(FIRESTORE_DOC_URL);
    if (fsGet.ok) {
      docExists = true;
      const fsJson = await fsGet.json();
      const parsed = fromFsValue({ mapValue: { fields: fsJson.fields || {} } }) || {};
      if (Array.isArray(parsed.changes)) existingChanges = parsed.changes;
      if (parsed.sktSnapshot && typeof parsed.sktSnapshot === 'object') prevSktSnapshot = parsed.sktSnapshot;
    }

    // 읽기 전용 조회 (사용자 확인 없이 Firestore에 자동 반영하지 않음)
    const todayCount = existingChanges.filter(c => normalizeDateStr(c.date) === todayStr && isTargetFlagshipModel(c.modelName)).length;
    res.status(200).json({
      ok: true,
      today: todayStr,
      todayCount,
      newDetectedCount: 0,
      totalCount: existingChanges.length,
      lastSyncedAt: new Date().toISOString(),
      changes: existingChanges
    });
  } catch (err) {
    res.status(200).json({
      ok: false,
      error: err.message || 'sync failed',
      changes: []
    });
  }
};
