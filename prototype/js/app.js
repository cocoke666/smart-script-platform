/* 智能剧本创作平台 H5 原型 · 全局脚本：底部导航 / 轻提示 / 页面跳转管控 */
(function () {
  // 页面注册表：ready=false 的页面点击时提示"制作中"，做完一个页面把对应 ready 改为 true
  var PAGES = {
    bookstore:   { href: 'bookstore.html',   title: '书城',     ready: true  },
    comic:       { href: 'comic.html',       title: '漫剧',     ready: true  },
    category:    { href: 'category.html',    title: '分类',     ready: true  },
    category_detail: { href: 'category_detail.html', title: '分类详情', ready: true },
    upload:      { href: 'upload.html',      title: '剧本上传', ready: true  },
    create:      { href: 'upload_create.html', title: '上传和创作', ready: true },
    script_create: { href: 'script_create.html', title: '剧本大纲', ready: true },
    ai_write:    { href: 'ai_write.html',    title: 'AI 写作',  ready: true },
    polish:      { href: 'polish.html',      title: '辅助润色', ready: true },
    comic_upload: { href: 'comic_upload.html', title: '漫剧上传', ready: true },
    earn:        { href: 'earn.html',        title: '福利',     ready: true  },
    creator:     { href: 'creator.html',     title: '创作者后台', ready: true },
    profile:     { href: 'profile.html',     title: '我的',     ready: true  },
    profile_client: { href: 'profile_client.html', title: '我的（甲方）', ready: true },
    book_detail: { href: 'book_detail.html', title: '作品详情', ready: true },
    read:        { href: 'read.html',        title: '试读',     ready: true },
    login:       { href: 'login.html',       title: '登录/注册', ready: true }
  };

  window.go = function (key) {
    var p = PAGES[key];
    if (!p) return;
    if (p.ready) location.href = p.href;
    else toast('「' + p.title + '」页面制作中，敬请期待');
  };

  var toastTimer = null;
  window.toast = function (msg) {
    var app = document.querySelector('.app');
    var el = app.querySelector('.toast');
    if (!el) {
      el = document.createElement('div');
      el.className = 'toast';
      app.appendChild(el);
    }
    el.textContent = msg;
    el.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { el.classList.remove('show'); }, 1800);
  };

  /* ---------- AI 辅助创作次数（福利 - 积分商店兑换） ---------- */
  var QKEY = 'ai_quota';
  window.getQuota = function () {
    var def = { outline: 0, write: 0, polish: 0 };
    try { return JSON.parse(localStorage.getItem(QKEY)) || def; } catch (e) { return def; }
  };
  window.useQuota = function (k) {
    var q = getQuota();
    if (!q[k] || q[k] <= 0) return false;
    q[k] -= 1;
    localStorage.setItem(QKEY, JSON.stringify(q));
    return true;
  };
  window.addQuota = function (k, n) {
    var q = getQuota();
    q[k] = (q[k] || 0) + n;
    localStorage.setItem(QKEY, JSON.stringify(q));
  };

  /* ---------- 作品封面图映射（img/cv01-16.png） ---------- */
  var CVT = ['长风渡我', '春日宴迟', '夜航船记', '山海拾遗', '锦绣成灰', '星夜兼程', '风雪夜归人', '无间之名', '银河修理员', '楼下请回答', '巷尾早餐铺', '凤栖台', '雾港迷案', '心动信号塔', '山神娶亲', '重启2009'];
  window.cvSrc = function (t) {
    var i = CVT.indexOf(t);
    if (i < 0) i = 0;
    return 'img/cv' + (i + 1 < 10 ? '0' : '') + (i + 1) + '.png';
  };

  window.openDrawer = function (open) {
    document.getElementById('drawer').classList.toggle('open', open);
    document.getElementById('mask').classList.toggle('show', open);
  };

  function buildChrome() {
    var app = document.querySelector('.app');
    if (document.body.classList.contains('no-chrome')) return;
    var cur = document.body.dataset.tab || '';

    // 线性图标（24 viewBox · 描边风格 · 跟随 currentColor）
    function ico(paths) {
      return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' + paths + '</svg>';
    }
    var ICONS = {
      book:  ico('<path d="M12 6.6C10.4 5.1 8.3 4.5 4 4.5v13c4.3 0 6.4.6 8 2.1 1.6-1.5 3.7-2.1 8-2.1v-13c-4.3 0-6.4.6-8 2.1z"/><path d="M12 6.6v13"/>'),
      video: ico('<rect x="3" y="5" width="18" height="14" rx="3"/><path d="M10.2 9.4l4.6 2.6-4.6 2.6z"/>'),
      plus:  ico('<path d="M12 5.5v13M5.5 12h13"/>'),
      grid:  ico('<rect x="4" y="4" width="7" height="7" rx="1.6"/><rect x="13" y="4" width="7" height="7" rx="1.6"/><rect x="4" y="13" width="7" height="7" rx="1.6"/><rect x="13" y="13" width="7" height="7" rx="1.6"/>'),
      user:  ico('<circle cx="12" cy="8.6" r="3.8"/><path d="M4.8 20c1.4-3.7 4-5.4 7.2-5.4s5.8 1.7 7.2 5.4"/>')
    };

    var nav = document.createElement('nav');
    nav.className = 'tabbar';
    nav.innerHTML =
      '<button class="tab' + (cur === 'bookstore' ? ' active' : '') + '" data-k="bookstore">' + ICONS.book + '书城</button>' +
      '<button class="tab' + (cur === 'comic' ? ' active' : '') + '" data-k="comic">' + ICONS.video + '漫剧</button>' +
      '<button class="tab' + (cur === 'create' || cur === 'upload' ? ' active' : '') + '" data-k="create"><span class="big-plus">' + ICONS.plus + '</span></button>' +
      '<button class="tab' + (cur === 'category' ? ' active' : '') + '" data-k="category">' + ICONS.grid + '分类</button>' +
      '<button class="tab' + (cur === 'profile' ? ' active' : '') + '" data-k="profile">' + ICONS.user + '我的</button>';
    app.appendChild(nav);
    nav.addEventListener('click', function (e) {
      var b = e.target.closest('[data-k]');
      if (b) go(b.dataset.k);
    });

    var mask = document.createElement('div');
    mask.id = 'mask';
    mask.className = 'mask';
    mask.onclick = function () { openDrawer(false); };
    app.appendChild(mask);

    var drawer = document.createElement('aside');
    drawer.id = 'drawer';
    drawer.className = 'drawer';
    drawer.innerHTML = drawerHTML();
    app.appendChild(drawer);
    fillDrawerHead();

    var pm = document.createElement('div');
    pm.id = 'gPanelMask';
    pm.className = 'sheet-mask';
    pm.onclick = function () { closeTool(); };
    app.appendChild(pm);
    var sh = document.createElement('div');
    sh.id = 'gPanel';
    sh.className = 'sheet';
    sh.innerHTML = '<h3 id="gPanelTitle"></h3><div id="gPanelBody"></div>';
    app.appendChild(sh);
  }

  /* ---------- 侧边栏内容（工具与设置） ---------- */
  function getToolProf() {
    return JSON.parse(localStorage.getItem('prof') || 'null') || { nick: '青山客', bio: '原创编剧 · 从业三年' };
  }
  function drawerHTML() {
    var s = JSON.parse(localStorage.getItem('set_notify') || 'null') || { push: true, inq: true, trade: true };
    function sw(id, on) {
      return '<label class="sw"><input type="checkbox" id="' + id + '"' + (on ? ' checked' : '') + ' onchange="saveSet()"><span class="track"></span></label>';
    }
    return '<div class="dhead"><div class="ava" id="dAva"></div><div class="who"><b id="dNick"></b><p id="dBio"></p></div>' +
      '<button class="dswitch" onclick="location.href=\'login.html\'">切换</button></div>' +
      '<div class="dsec"><h3>我的消息</h3>' +
      '<div class="msgrow"><div class="t">询盘消息<span>09-06</span></div><div class="d">甲方「星川传媒」对《长风渡我》发起询盘</div></div>' +
      '<div class="msgrow"><div class="t">系统通知<span>09-05</span></div><div class="d">《夜航船记》已进入版权中心审核</div></div></div>' +
      '<div class="dsec">' +
      '<div class="srow" onclick="openTool(\'cert\')"><span>版权存证</span><span class="ar">›</span></div>' +
      '<div class="srow" onclick="openTool(\'help\')"><span>帮助中心</span><span class="ar">›</span></div>' +
      '<div class="srow" onclick="openTool(\'feedback\')"><span>意见反馈</span><span class="ar">›</span></div></div>' +
      '<div class="dsec"><h3>设置</h3>' +
      '<div class="srow" onclick="openTool(\'account\')"><span>账号与安全</span><span class="ar">›</span></div>' +
      '<div class="srow"><span>消息推送</span>' + sw('swPush', s.push) + '</div>' +
      '<div class="srow"><span>询盘提醒</span>' + sw('swInq', s.inq) + '</div>' +
      '<div class="srow"><span>交易提醒</span>' + sw('swTrade', s.trade) + '</div>' +
      '<div class="srow" onclick="clearCache()"><span>清除缓存</span><span><span class="sub" id="cacheSize">12.6 MB</span><span class="ar">›</span></span></div>' +
      '<div class="srow" onclick="openTool(\'about\')"><span>关于平台</span><span class="ar">›</span></div></div>' +
      '<div class="dsec"><button class="btn-danger" onclick="logout()">退出登录</button></div>';
  }
  function fillDrawerHead() {
    var p = getToolProf();
    document.getElementById('dNick').textContent = p.nick;
    document.getElementById('dBio').textContent = p.bio;
    document.getElementById('dAva').textContent = p.nick.slice(0, 1);
  }
  window.saveSet = function () {
    var s = {
      push: document.getElementById('swPush').checked,
      inq: document.getElementById('swInq').checked,
      trade: document.getElementById('swTrade').checked
    };
    localStorage.setItem('set_notify', JSON.stringify(s));
    toast('设置已保存');
  };
  window.clearCache = function () {
    document.getElementById('cacheSize').textContent = '0 MB';
    toast('缓存已清除');
  };
  window.logout = function () {
    toast('已退出登录');
    setTimeout(function () { location.href = 'login.html'; }, 600);
  };

  /* ---------- 侧边栏子面板 ---------- */
  var TOOLS = {
    cert: { title: '版权存证', html: function () {
      return '<div class="faq"><div class="q">《长风渡我》</div><div class="a">存证号 SC-2026-0812-001 · 2026-08-12 · 已上链</div></div>' +
        '<div class="faq"><div class="q">《夜航船记》</div><div class="a">存证号 SC-2026-0901-003 · 2026-09-01 · 审核中</div></div>' +
        '<button class="btn-solid" style="width:100%;margin-top:12px" onclick="toast(\'原型演示：已发起新的版权存证申请\')">申请新存证</button>';
    } },
    help: { title: '帮助中心', html: function () {
      return [['如何投稿剧本？', '在底部「剧本上传」填写信息、上传封面与正文后提交，进入审核流程。'],
        ['报价与资金托管怎么算？', '甲方对创作者询盘报价，甲方确认后款项进入资金托管，版权交割完成后释放给创作者。'],
        ['如何申请版权存证？', '在「版权存证」中对作品发起存证，平台生成链上存证证书，交易全程可溯。']]
        .map(function (x) { return '<div class="faq"><div class="q">' + x[0] + '</div><div class="a">' + x[1] + '</div></div>'; }).join('');
    } },
    feedback: { title: '意见反馈', html: function () {
      return '<div class="pfield"><label>反馈内容</label><textarea id="fbText" rows="4" placeholder="请描述你的问题或建议…"></textarea></div>' +
        '<div class="pfield"><label>联系方式（选填）</label><input id="fbContact" placeholder="手机号 / 邮箱"></div>' +
        '<button class="btn-solid" style="width:100%" onclick="sendToolFb()">提交反馈</button>';
    } },
    account: { title: '账号与安全', html: function () {
      return '<div class="srow" onclick="toast(\'原型演示：进入修改密码\')"><span>修改密码</span><span class="ar">›</span></div>' +
        '<div class="srow" onclick="toast(\'原型演示：进入绑定手机\')"><span>绑定手机</span><span><span class="sub">138****8888</span><span class="ar">›</span></span></div>' +
        '<div class="srow" onclick="go(\'profile\')"><span>实名认证</span><span><span class="sub">去认证</span><span class="ar">›</span></span></div>';
    } },
    about: { title: '关于平台', html: function () {
      return '<div class="faq"><div class="q">智能剧本创作平台</div><div class="a">版本 v1.0.0（H5 原型）<br>© 2026 智能剧本创作平台 · 仅作教学演示</div></div>';
    } }
  };
  window.openTool = function (key) {
    var t = TOOLS[key];
    if (!t) return;
    document.getElementById('gPanelTitle').textContent = t.title;
    document.getElementById('gPanelBody').innerHTML = t.html();
    document.getElementById('gPanelMask').classList.add('show');
    document.getElementById('gPanel').classList.add('show');
  };
  window.closeTool = function () {
    document.getElementById('gPanelMask').classList.remove('show');
    document.getElementById('gPanel').classList.remove('show');
  };
  window.sendToolFb = function () {
    var t = document.getElementById('fbText').value.trim();
    if (!t) { toast('请填写反馈内容'); return; }
    closeTool();
    toast('反馈已提交，感谢支持');
  };

  document.addEventListener('DOMContentLoaded', buildChrome);
})();
