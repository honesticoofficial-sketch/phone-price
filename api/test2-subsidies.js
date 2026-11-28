// Vercel Serverless API: 테스트매장2 전용 통신 3사 전체 기종(A시리즈 포함) · 요금제별 공통지원금 실시간 수집
// 주의: 실매장 공용 global_config(devices_master / subsidy_changes)는 절대 수정하지 않고, 조회 JSON만 반환합니다.

const SMARTCHOICE_UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
const SMARTCHOICE_BASE = 'https://www.smartchoice.or.kr';

const CARRIER_META = {
  SK: {
    telCode: 'SKT',
    svcField: 'planSKTService',
    pnField: 'skt_Pn',
    phone5g: 'PHONE_5G',
    phoneLte: 'PHONE_LTE'
  },
  KT: {
    telCode: 'KT',
    svcField: 'planKTService',
    pnField: 'kt_Pn',
    phone5g: 'PHONE_5G',
    phoneLte: 'PHONE_LTE'
  },
  LG: {
    telCode: 'LGU',
    svcField: 'planLGUService',
    pnField: 'lg_Pn',
    phone5g: 'PHONE_5G',
    phoneLte: 'PHONE_LTE'
  }
};

// 몽키컨설팅 공식 요금제 지급구간표 기준 (SK v7.1 / KT v8.1 / LG v7.9)
function classifyPlanTier(carrier, planName = '', feeWon = 0) {
  const n = String(planName || '').replace(/\s+/g, ' ').trim();
  const low = n.toLowerCase();
  const fee = Number(feeWon) || 0;

  if (carrier === 'SK') {
    if (/베스트\s*(109|pro|프로|max|맥스)|5gx\s*(프리미엄|플래티넘)/i.test(n) || fee >= 109000) return 'P_119';
    if (/베스트\s*99|5gx\s*프라임\s*플러스|0\s*청년\s*99/i.test(n) || (fee >= 99000 && fee < 109000)) return 'I_100';
    if (/베스트\s*89|5gx\s*프라임(?!\s*플러스)|0\s*청년\s*89/i.test(n) || (fee >= 79000 && fee < 99000 && !/라이트\s*79|5gx\s*레귤러|0\s*청년\s*79/i.test(n))) return 'F_79';
    if (/(라이트\s*59|베이직플러스|0\s*청년\s*59)\s*(50gb|60gb|75gb|100gb)업|라이트\s*(69|79)|5gx\s*레귤러|0\s*청년\s*(69|79)|easy\s*xl/i.test(low)) return 'L_69';
    if (/라이트\s*(39|45|49|55)|슬림(?!\s*요금제)|^베이직$|컴팩트|0\s*청년\s*(43|49)|0틴\s*5g|zem\s*플랜\s*베스트|zem플랜\s*베스트/i.test(low)) return 'R_43';
    if (/easy\s*[ml]\b|라이트\s*59|베이직플러스|0\s*청년\s*59|zem\s*플랜\s*퍼[펙팩]트|zem플랜\s*퍼[펙팩]트/i.test(low)) return 'M_50';
    if (/t\s*플랜\s*세이브|t플랜\s*세이브|손누리\s*3|소리누리\s*2\.4|easy\s*s\b|zem\s*플랜\s*스마트|zem플랜\s*스마트|0\s*청년\s*37/i.test(low)) return 'S_33';
    if (/표준요금제|복지\s*150|복지\s*210|소리누리\s*1\.2|손누리\s*1\.5|t끼리\s*맞춤/i.test(low)) return '기본구간';
    if (fee >= 69000) return 'L_69';
    if (fee >= 50000) return 'M_50';
    if (fee >= 39000) return 'R_43';
    if (fee >= 33000) return 'S_33';
    return '기본구간';
  }

  if (carrier === 'KT') {
    if (/초이스\s*(110|더블|130|스페셜|프리미엄)|초이스110|초이스130/i.test(n) || fee >= 110000) return '110K 이상';
    if (/베이[직지]\s*100|베이[직지]100|^스페셜$|y\s*스페셜/i.test(low) || (fee >= 100000 && fee < 110000)) return '100K 이상';
    if (/초이스\s*(90|베이직)|초이스90/i.test(n) || (fee >= 90000 && fee < 100000)) return '90K 이상';
    if (/베이[직지]\s*(110gb|80)|5g\s*심플\s*(110gb|복지)|^베이직$|5g\s*베이직\s*복지|y\s*베이직|웰컴\s*5/i.test(low) || (fee >= 69000 && fee < 90000)) return '69K 이상';
    if (/베이[직지]\s*(30gb|50gb|70gb|90gb)|5g\s*심플\s*(30gb|50gb|70gb|90gb)|키즈\s*38|5g\s*주니어(?!.*슬림)|베이[직지]\s*(10gb|14gb|21gb)\s*\(?(스쿨덤|65\+|75\+)/i.test(low) || (fee >= 61000 && fee < 69000)) {
      return '61K 이상';
    }
    if (/베이[직지]\s*(14gb|21gb)|5g\s*슬림\s*(14gb|21gb|복지)|5g\s*y슬림|베이[직지]\s*7gb\s*\(?(스쿨덤|65\+|75\+)|웰컴\s*3/i.test(low) || (fee >= 55000 && fee < 61000)) {
      return '55K 이상';
    }
    if (/베이[직지]\s*(4gb|7gb|10gb)|5g\s*슬림\s*(4gb|7gb|10gb)|5g\s*y틴|5g\s*시니어|키즈\s*28|5g\s*주니어\s*슬림|베이[직지]\s*(600mb|1\.4gb)\s*\(?(스쿨덤|65\+|75\+)|웰컴\s*1/i.test(low) || (fee >= 37000 && fee < 55000)) {
      return '37K 이상';
    }
    return '37K 미만';
  }

  // LG U+ (13개 요금제 군)
  if (fee >= 115000 || /플러스\s*플?렌\s*(115|130)/i.test(n)) return '115군';
  if (fee >= 105000 || /플러스\s*플?렌\s*105/i.test(n)) return '105군';
  if (fee >= 95000 || /플러스\s*플?렌\s*95/i.test(n)) return '95군';
  if (fee >= 85000 || /8max|데이터플랜\s*max/i.test(low)) return '85군';
  if (fee >= 75000 || /데이터플랜\s*150gb/i.test(low)) return '75군';
  if (fee >= 70000 || /데이터플랜\s*125gb/i.test(low)) return '70군';
  if (fee >= 61000 || /데이터플랜\s*(31gb|50gb|80gb|95gb)/i.test(low)) return '61군';
  if (fee >= 55000 || /데이터플랜\s*(14gb|24gb)/i.test(low)) return '55군';
  if (fee >= 47000 || /데이터플랜\s*9gb/i.test(low)) return '47군';
  if (fee >= 37000 || /데이터플랜\s*5gb/i.test(low)) return '37군';
  if (fee >= 33000 || /데이터플랜\s*1\.5gb|현역병사/i.test(low)) return '33군';
  if (fee >= 28000 || /데이터플랜\s*(300mb|750mb)/i.test(low)) return '28군';
  return '28군 미만';
}

function decodeHtmlText(str) {
  return String(str || '')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function toNumWon(raw) {
  const digits = String(raw || '').replace(/[^0-9]/g, '');
  return digits ? Number(digits) : 0;
}

function wonToMan(won) {
  return Math.round((Number(won || 0) / 10000) * 100) / 100;
}

function inferModelGroup(name, code = '') {
  const s = `${name} ${code}`;
  if (/유심|USIM/i.test(s)) return 'USIM';
  if (/iPhone|아이폰/i.test(s)) return 'IPHONE';
  if (/폴드|플립|Fold|Flip/i.test(s)) return 'FOLD';
  if (/갤럭시\s*S|Galaxy\s*S|SM-S\d+/i.test(s)) return 'S';
  return 'A';
}

async function fetchProductNameMap(carrierMeta, serviceCode) {
  const map = {};
  const svcParam = `${carrierMeta.svcField}=${encodeURIComponent(serviceCode)}`;
  const makers = ['SS', 'AP', 'ETC'];

  await Promise.all(
    makers.map(async mau => {
      try {
        const body = `dan_Company=${carrierMeta.telCode}&${svcParam}&p_Group=&p_Group2=&dan_Service=&dan_Service2=&dan_Mau=${mau}&searchType=danTelSearch`;
        const res = await fetch(`${SMARTCHOICE_BASE}/smc/mobile/getTelProductList.do`, {
          method: 'POST',
          headers: {
            'User-Agent': SMARTCHOICE_UA,
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            Referer: `${SMARTCHOICE_BASE}/smc/mobile/dantongTelList.do`
          },
          body
        });
        if (!res.ok) return;
        const json = await res.json();
        const list = (json && json[0] && Array.isArray(json[0].listProductData)) ? json[0].listProductData : [];
        list.forEach(item => {
          const code = item[carrierMeta.pnField] || item.skt_Pn || item.kt_Pn || item.lg_Pn || item.productName;
          const name = decodeHtmlText(item.dan_Pc_Name || '');
          if (code && name) {
            map[code] = {
              name,
              maker: mau === 'SS' ? '삼성' : (mau === 'AP' ? '애플' : '기타'),
              releaseDate: item.used_Phone_Release || ''
            };
          }
        });
      } catch (_) {}
    })
  );
  return map;
}

function parseDantongHtml(html, carrier, codeMetaMap, serviceLabel) {
  const startIdx = html.indexOf('<tbody id="planTelTable">');
  if (startIdx < 0) return {};
  const endIdx = html.indexOf('</tbody>', startIdx);
  const tbody = endIdx > startIdx ? html.slice(startIdx, endIdx) : html.slice(startIdx);
  const models = {};

  const rows = tbody.split(/<\/tr>/i);
  for (let i = 0; i < rows.length; i++) {
    const rowChunk = rows[i];
    const openMatch = rowChunk.match(/<tr class="dan ([^"]*)"[^>]*>/i);
    if (!openMatch) continue;
    const classStr = openMatch[1] || '';
    const inner = rowChunk.slice(openMatch.index + openMatch[0].length);
    const codeTokens = classStr.trim().split(/\s+/);
    const danCodeToken = codeTokens.find(t => t.startsWith('dan') && t !== 'dan' && t !== 'danSS' && t !== 'danAP' && t !== 'danETC');
    if (!danCodeToken) continue;
    const modelCode = danCodeToken.slice(3);

    const tdMatches = inner.split(/<\/td>/i).map(seg => {
      const m = seg.match(/<td\b[^>]*>([\s\S]*)$/i);
      return m ? m[1] : '';
    }).filter((_, idx, arr) => idx < arr.length - 1);
    if (tdMatches.length < 4) continue;

    // 0: 요금제명 + 월정액
    const col0 = tdMatches[0];
    const spans = [...col0.matchAll(/<span[^>]*>([\s\S]*?)<\/span>/gi)].map(m => decodeHtmlText(m[1]));
    const planName = spans[0] || decodeHtmlText(col0.replace(/<[^>]+>/g, ' '));
    const planFeeWon = toNumWon(spans[1] || col0);

    // 1: 출고가, 2: 기기변경 공통지원금, 3: 번호이동 공통지원금
    const factoryWon = toNumWon(tdMatches[1].replace(/<[^>]+>/g, ''));
    const subChgWon = toNumWon(tdMatches[2].replace(/<[^>]+>/g, ''));
    const subMnpWon = toNumWon(tdMatches[3].replace(/<[^>]+>/g, ''));
    const effDateRaw = tdMatches[tdMatches.length - 1] ? decodeHtmlText(tdMatches[tdMatches.length - 1].replace(/<[^>]+>/g, '')) : '';

    if (!factoryWon && !subChgWon && !subMnpWon) continue;

    if (!models[modelCode]) {
      const meta = codeMetaMap[modelCode] || {};
      const modelName = meta.name || modelCode;
      models[modelCode] = {
        code: modelCode,
        name: modelName,
        maker: meta.maker || (modelCode.startsWith('IP') ? '애플' : '삼성'),
        group: inferModelGroup(modelName, modelCode),
        service: serviceLabel,
        factoryPriceMan: wonToMan(factoryWon),
        effDate: effDateRaw,
        tiers: {}
      };
    }

    const tierId = classifyPlanTier(carrier, planName, planFeeWon);
    const curTier = models[modelCode].tiers[tierId];
    const mnpMan = wonToMan(subMnpWon);
    const chgMan = wonToMan(subChgWon);

    // 동일 요금제 구간 내에서는 대표 메인 요금제(더 높은 지원금 또는 표준 구간 요금제) 우선 저장
    if (!curTier || mnpMan > curTier.mnp || (mnpMan === curTier.mnp && chgMan > curTier.chg)) {
      models[modelCode].tiers[tierId] = {
        mnp: mnpMan,
        chg: chgMan,
        planName,
        planFeeMan: wonToMan(planFeeWon)
      };
    }
  }
  return models;
}

async function fetchCarrierFullCatalog(carrier, includeLte = true) {
  const meta = CARRIER_META[carrier];
  if (!meta) throw new Error(`Unsupported carrier: ${carrier}`);

  const fetchService = async (serviceCode, svcTag, mauList) => {
    const codeMetaMap = await fetchProductNameMap(meta, serviceCode);
    const mauChunks = await Promise.all(
      mauList.map(async mau => {
        try {
          const tableRes = await fetch(`${SMARTCHOICE_BASE}/smc/mobile/dantongTelList.do`, {
            method: 'POST',
            headers: {
              'User-Agent': SMARTCHOICE_UA,
              'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
              Referer: `${SMARTCHOICE_BASE}/smc/mobile/dantongTelList.do`
            },
            body: `searchType=danTelSearch&searchOrder=orderASC&p_Group=PHONE&dan_Service=${svcTag}&p_Group2=&dan_Service2=&dan_Company=${meta.telCode}&${meta.svcField}=${encodeURIComponent(serviceCode)}&dan_Mau=${mau}&productName=all&dan_Plan_Code=all`
          });
          if (!tableRes.ok) return {};
          const html = await tableRes.text();
          return parseDantongHtml(html, carrier, codeMetaMap, svcTag);
        } catch (_) {
          return {};
        }
      })
    );
    const svcMerged = {};
    mauChunks.forEach(chunk => {
      Object.keys(chunk).forEach(code => {
        if (!svcMerged[code]) svcMerged[code] = chunk[code];
        else Object.assign(svcMerged[code].tiers, chunk[code].tiers);
      });
    });
    return svcMerged;
  };

  const tasks = [fetchService(meta.phone5g, '5G', ['SS', 'AP', 'ETC'])];
  if (includeLte) tasks.push(fetchService(meta.phoneLte, 'LTE', ['SS', 'ETC']));

  const chunks = await Promise.all(tasks);
  const merged = {};
  chunks.forEach(chunk => {
    Object.keys(chunk).forEach(code => {
      if (!merged[code]) {
        merged[code] = chunk[code];
      } else {
        Object.assign(merged[code].tiers, chunk[code].tiers);
      }
    });
  });

  // SKT 4G/LTE 보완: 스마트초이스에서 빠지는 T다이렉트샵 4G 공시 단말(갤럭시 A17 등) 병합
  if (carrier === 'SK' && includeLte) {
    try {
      const fetchTwPhone = async (scrbTypCd) => {
        const res = await fetch(`https://shop.tworld.co.kr/notice?modelNwType=PHONE&scrbTypCd=${scrbTypCd}`, {
          headers: { 'User-Agent': SMARTCHOICE_UA }
        });
        if (!res.ok) return [];
        const html = await res.text();
        const m = html.match(/_this\.products\s*=\s*parseObject\((\[[\s\S]*?\])\);/);
        return m ? JSON.parse(m[1]) : [];
      };
      const [mnpRows, chgRows] = await Promise.all([fetchTwPhone('20'), fetchTwPhone('31')]);
      const normKey = s => String(s || '').toLowerCase().replace(/\s+/g, '').replace(/\d+(g|gb|t|tb)$/i, '');
      const existingByName = new Set(Object.values(merged).map(v => normKey(v.name)));
      const twMap = {};
      const ingest = (rows, field) => {
        (Array.isArray(rows) ? rows : []).forEach(p => {
          if (!p || !p.productNm) return;
          const k = normKey(p.productNm);
          if (!k || existingByName.has(k)) return;
          if (!twMap[k]) {
            const fullName = `${p.productNm || ''}`.trim();
            const canonicalCode = /갤럭시\s*a17/i.test(fullName) ? 'SM-A175N' : `TW-${p.modelCd || k}`;
            twMap[k] = {
              code: canonicalCode,
              name: fullName,
              maker: p.companyNm || '삼성',
              group: inferModelGroup(fullName, canonicalCode),
              service: 'LTE',
              factoryPriceMan: wonToMan(p.factoryPrice),
              effDate: String(p.effStaDt || '').replace(/(\d{4})(\d{2})(\d{2})/, '$1-$2-$3'),
              tiers: {},
              tierId: classifyPlanTier('SK', p.prodNm || '베스트 89', Number(p.basicCharge) || 89000),
              mnp: 0,
              chg: 0
            };
          }
          const subMan = wonToMan(p.telecomSaleAmt);
          if (subMan > twMap[k][field]) twMap[k][field] = subMan;
        });
      };
      ingest(mnpRows, 'mnp');
      ingest(chgRows, 'chg');
      Object.values(twMap).forEach(item => {
        const tierId = item.tierId || 'F_79';
        item.tiers[tierId] = {
          mnp: item.mnp || item.chg || 0,
          chg: item.chg || item.mnp || 0,
          planName: '베스트 89(T 우주)',
          planFeeMan: 8.9
        };
        delete item.tierId; delete item.mnp; delete item.chg;
        if (!merged[item.code]) merged[item.code] = item;
      });
    } catch (_) {}
  }

  return merged;
}

module.exports = async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Access-Control-Allow-Origin', '*');
  const carrierParam = String((req.query && req.query.carrier) || 'SK').toUpperCase();
  const includeLte = String((req.query && req.query.lte) || '1') !== '0';

  if (!CARRIER_META[carrierParam]) {
    res.status(400).json({ ok: false, error: 'carrier must be SK, KT, or LG' });
    return;
  }

  try {
    const modelsMap = await fetchCarrierFullCatalog(carrierParam, includeLte);
    const modelsList = Object.values(modelsMap);
    res.status(200).json({
      ok: true,
      carrier: carrierParam,
      source: 'smartchoice.or.kr',
      syncedAt: new Date().toISOString(),
      modelsCount: modelsList.length,
      models: modelsMap
    });
  } catch (err) {
    res.status(200).json({
      ok: false,
      carrier: carrierParam,
      error: err.message || 'crawl failed',
      models: {}
    });
  }
};
