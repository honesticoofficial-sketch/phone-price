    // ==================== 통신 3사 수집 크롤링 플래그십 기종 풀 (88종) & 검색 자동완성 ====================
    let catActiveGroup = 'ALL';

    function filterCatalogGroup(group) {
      catActiveGroup = group;
      ['ALL', 'S', 'FOLD', 'IPHONE'].forEach(g => {
        const btn = document.getElementById('catGroupBtn-' + g);
        if (!btn) return;
        if (g === group) {
          btn.className = 'px-2.5 py-0.5 rounded-lg text-[10.5px] font-bold bg-indigo-600 text-white shadow-2xs';
        } else {
          btn.className = 'px-2.5 py-0.5 rounded-lg text-[10.5px] font-bold bg-white text-slate-600 hover:bg-slate-100 border border-slate-200';
        }
      });
      const q = (document.getElementById('catalogSearchInput')?.value || '');
      handleCatalogSearch(q);
    }

    function clearCatalogSearch() {
      const inp = document.getElementById('catalogSearchInput');
      if (inp) inp.value = '';
      const clearBtn = document.getElementById('btnCatalogClear');
      if (clearBtn) clearBtn.classList.add('hidden');
      const resultsDiv = document.getElementById('catalogSearchResults');
      if (resultsDiv) {
        resultsDiv.classList.add('hidden');
        resultsDiv.innerHTML = '';
      }
    }

    function handleCatalogSearch(query) {
      const q = (query || '').trim().toLowerCase().replace(/\s+/g, '');
      const resultsDiv = document.getElementById('catalogSearchResults');
      const clearBtn = document.getElementById('btnCatalogClear');
      if (clearBtn) clearBtn.classList.toggle('hidden', !query);

      if (!resultsDiv) return;

      if (!q && catActiveGroup === 'ALL') {
        resultsDiv.classList.add('hidden');
        resultsDiv.innerHTML = '';
        return;
      }

      // 검색어 동의어 정규화
      let qSyn = q;
      qSyn = qSyn.replace(/아이폰/g, 'iphone').replace(/플립/g, 'flip').replace(/폴드/g, 'fold')
                 .replace(/울트라/g, 'ultra').replace(/엣지/g, 'edge').replace(/프로/g, 'pro')
                 .replace(/프맥/g, 'promax').replace(/플러스/g, 'plus').replace(/에어/g, 'air');

      const matches = (typeof CRAWLED_CATALOG_POOL !== 'undefined' ? CRAWLED_CATALOG_POOL : []).filter(item => {
        if (catActiveGroup !== 'ALL' && item.group !== catActiveGroup) return false;
        if (!q) return true; // 필터만 선택되고 검색어가 없으면 해당 그룹 전체 표시

        const nameRaw = item.name.toLowerCase().replace(/\s+/g, '');
        const tagRaw = (item.tag || '').toLowerCase().replace(/\s+/g, '');
        
        let itemSyn = nameRaw;
        itemSyn = itemSyn.replace(/아이폰/g, 'iphone').replace(/플립/g, 'flip').replace(/폴드/g, 'fold')
                         .replace(/울트라/g, 'ultra').replace(/엣지/g, 'edge').replace(/프로/g, 'pro')
                         .replace(/프맥/g, 'promax').replace(/플러스/g, 'plus').replace(/에어/g, 'air');

        return nameRaw.includes(q) || tagRaw.includes(q) || itemSyn.includes(qSyn) || nameRaw.includes(qSyn) || itemSyn.includes(q);
      });

      if (matches.length === 0) {
        resultsDiv.classList.remove('hidden');
        resultsDiv.innerHTML = '<div class="p-3 text-center text-slate-400 font-bold text-xs">일치하는 크롤링 수집 기종이 없습니다.<br><span class="text-[11px] font-normal">아래 직접 입력창에 기종명과 출고가를 수동으로 입력하실 수 있습니다.</span></div>';
        return;
      }

      resultsDiv.classList.remove('hidden');
      resultsDiv.innerHTML = matches.slice(0, 20).map(item => {
        const groupBadge = item.group === 'S' ? '<span class="px-1.5 py-0.5 rounded text-[10px] font-black bg-blue-100 text-blue-700">갤럭시 S</span>' :
                           item.group === 'FOLD' ? '<span class="px-1.5 py-0.5 rounded text-[10px] font-black bg-amber-100 text-amber-800">폴더블</span>' :
                           '<span class="px-1.5 py-0.5 rounded text-[10px] font-black bg-purple-100 text-purple-700">아이폰</span>';
        
        const skPrice = (item.prices && item.prices.SK) ? item.prices.SK + '만' : '-';
        const ktPrice = (item.prices && item.prices.KT) ? item.prices.KT + '만' : '-';
        const lgPrice = (item.prices && item.prices.LG) ? item.prices.LG + '만' : '-';

        const formatSub = (subObj) => {
          if (!subObj) return '-';
          if (typeof subObj === 'number') return subObj + '만';
          if (subObj.mnp === subObj.chg) return subObj.mnp + '만';
          return `번이 ${subObj.mnp}만/기변 ${subObj.chg}만`;
        };

        const skSub = formatSub(item.subs?.SK);
        const ktSub = formatSub(item.subs?.KT);
        const lgSub = formatSub(item.subs?.LG);

        const isRegistered = (typeof devices !== 'undefined' && Array.isArray(devices)) && devices.some(d => d.name.trim().toLowerCase() === item.name.trim().toLowerCase());
        const regBadge = isRegistered ? '<span class="px-1.5 py-0.5 rounded text-[9.5px] font-bold bg-slate-100 text-slate-500 border border-slate-200">등록됨</span>' : '';

        return `
          <div class="flex items-center justify-between p-2.5 rounded-xl border border-slate-200 hover:border-indigo-400 hover:bg-indigo-50/50 transition gap-2 group bg-white shadow-2xs">
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-1.5 flex-wrap mb-1">
                ${groupBadge}
                <span class="font-bold text-slate-900 text-xs">${item.name}</span>
                <span class="text-[10.5px] font-bold text-indigo-600 bg-indigo-50 px-1 rounded">${item.tag || ''}</span>
                ${regBadge}
              </div>
              <div class="flex items-center gap-2 text-[10.5px] text-slate-500 font-medium flex-wrap">
                <span>출고가: <b class="text-rose-600">SK ${skPrice}</b> / <b class="text-blue-600">KT ${ktPrice}</b> / <b class="text-pink-600">LG ${lgPrice}</b></span>
                <span class="text-slate-300">|</span>
                <span>공시: <b class="text-rose-600">SK ${skSub}</b> / <b class="text-blue-600">KT ${ktSub}</b> / <b class="text-pink-600">LG ${lgSub}</b></span>
              </div>
            </div>
            <div class="flex items-center gap-1.5 shrink-0">
              <button type="button" onclick="selectCatalogModel('${item.id}')" class="px-2.5 py-1.5 rounded-lg bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-bold text-[11px] border border-indigo-200 transition" title="이 기종 정보를 아래 폼에 자동 입력합니다">
                입력폼 채우기
              </button>
              <button type="button" onclick="quickAddCatalogModel('${item.id}')" class="px-2.5 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-[11px] shadow-2xs transition flex items-center gap-1" title="폼 작성 없이 즉시 등록합니다">
                <span>⚡ 즉시 추가</span>
              </button>
            </div>
          </div>
        `;
      }).join('');
    }

    function selectCatalogModel(itemId) {
      if (typeof CRAWLED_CATALOG_POOL === 'undefined') return;
      const item = CRAWLED_CATALOG_POOL.find(x => x.id === itemId);
      if (!item) return;

      document.getElementById('newDevName').value = item.name;
      document.getElementById('newDevGroup').value = item.group;
      document.getElementById('newDevTag').value = item.tag || ('#' + item.name.replace(/갤럭시\s*|아이폰\s*/g, '').split(' ')[0]);

      document.getElementById('newDevPriceSK').value = (item.prices && item.prices.SK) ? item.prices.SK : '';
      document.getElementById('newDevPriceKT').value = (item.prices && item.prices.KT) ? item.prices.KT : '';
      document.getElementById('newDevPriceLG').value = (item.prices && item.prices.LG) ? item.prices.LG : '';

      const getSubVal = (carrier, type) => {
        if (!item.subs || !item.subs[carrier]) return 0;
        const c = item.subs[carrier];
        if (typeof c === 'number') return c;
        return c[type] !== undefined ? c[type] : (c.mnp || c.chg || 0);
      };

      document.getElementById('newDevSubSK_mnp').value = getSubVal('SK', 'mnp');
      document.getElementById('newDevSubSK_chg').value = getSubVal('SK', 'chg');
      document.getElementById('newDevSubKT_mnp').value = getSubVal('KT', 'mnp');
      document.getElementById('newDevSubKT_chg').value = getSubVal('KT', 'chg');
      document.getElementById('newDevSubLG_mnp').value = getSubVal('LG', 'mnp');
      document.getElementById('newDevSubLG_chg').value = getSubVal('LG', 'chg');

      const nameInput = document.getElementById('newDevName');
      nameInput.classList.add('ring-2', 'ring-emerald-500', 'bg-emerald-50');
      setTimeout(() => {
        nameInput.classList.remove('ring-2', 'ring-emerald-500', 'bg-emerald-50');
      }, 1200);
      nameInput.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    function quickAddCatalogModel(itemId) {
      if (typeof CRAWLED_CATALOG_POOL === 'undefined') return;
      const item = CRAWLED_CATALOG_POOL.find(x => x.id === itemId);
      if (!item) return;

      const alreadyExists = typeof devices !== 'undefined' && Array.isArray(devices) && devices.some(d => d.name.trim().toLowerCase() === item.name.trim().toLowerCase());
      if (alreadyExists) {
        if (!confirm(`⚠️ '${item.name}' 모델은 이미 등록되어 있는 기종입니다.\n그래도 추가로 등록하시겠습니까?`)) {
          return;
        }
      }

      selectCatalogModel(itemId);
      addNewDeviceSubmit();
    }
