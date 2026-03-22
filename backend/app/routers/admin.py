import base64
import json
import os
import re
from datetime import datetime, timedelta, timezone

import httpx
from fastapi import APIRouter, Depends, Request, HTTPException, status
from fastapi.responses import HTMLResponse, RedirectResponse, Response

from pydantic import BaseModel
import jwt

from firebase_admin import auth as firebase_auth, firestore

from app.config import ADMIN_PASSWORD, ADMIN_USERNAME, SECRET_KEY
from app.dependencies import get_identity, require_admin


def _get_admin_creds():

    """Return admin credentials from config (validated at startup in production)."""
    return ADMIN_USERNAME, ADMIN_PASSWORD

router = APIRouter()


def _make_jwt() -> str:
    payload = {"sub": "admin", "exp": datetime.now(timezone.utc) + timedelta(days=7)}
    raw = jwt.encode(payload, SECRET_KEY, algorithm="HS256")
    return raw.decode("utf-8") if isinstance(raw, bytes) else str(raw)


class LoginBody(BaseModel):
    username: str
    password: str


@router.post("/login")
async def login(body: LoginBody):
    username = (body.username or "").strip()
    password = body.password or ""
    if username != ADMIN_USERNAME or password != ADMIN_PASSWORD:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid username or password")

    token = _make_jwt()
    return {"token": token, "username": username}


@router.get("/me")
async def admin_me(identity: str = Depends(get_identity)):
    if identity != "admin":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not admin")
    return {"username": "admin"}


def _admin_html(init_token: str | None = None, login_error: str | None = None) -> str:
    # 用 data 属性 + base64 传 token/错误信息，避免直接写入脚本导致 SyntaxError（如 JWT 含特殊字符）
    token_b64 = ""
    if init_token:
        token_b64 = base64.b64encode(init_token.encode("utf-8")).decode("ascii")
    err_b64 = ""
    if login_error:
        err_b64 = base64.b64encode(login_error.encode("utf-8")).decode("ascii")
    init_data_attrs = ""
    if token_b64:
        init_data_attrs += ' data-token-base64="' + token_b64 + '"'
    if err_b64:
        init_data_attrs += ' data-login-error-base64="' + err_b64 + '"'
    return """<!DOCTYPE html>

<html lang="zh-CN">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>MeowCare 后台管理</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: system-ui, -apple-system, "Segoe UI", sans-serif; margin: 0; background: #e8ecf0; }
    .container { max-width: 960px; margin: 0 auto; padding: 0; }
    .header { background: #2c3e50; color: #fff; padding: 14px 24px; display: flex; align-items: center; flex-wrap: wrap; gap: 16px; border-radius: 10px 10px 0 0; }
    .header h1 { margin: 0; font-size: 1.25rem; font-weight: 600; }
    .nav { display: flex; gap: 4px; flex-wrap: wrap; }
    .nav a { color: rgba(255,255,255,0.9); text-decoration: none; padding: 8px 14px; border-radius: 6px; font-size: 14px; }
    .nav a:hover { background: rgba(255,255,255,0.15); color: #fff; }
    .nav a.active { background: rgba(255,255,255,0.25); color: #fff; font-weight: 500; }
    .nav a.reddit-nav { background: rgba(255,255,255,0.18); }
    .logout { margin-left: auto; color: rgba(255,255,255,0.8); }
    .logout:hover { color: #fff; background: rgba(255,255,255,0.1); }
    .main { padding: 24px; }
    h1 { color: #333; }
    .card { background: #fff; border-radius: 10px; padding: 20px; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
    form { display: flex; flex-direction: column; gap: 12px; max-width: 320px; }
    input { padding: 10px 12px; border: 1px solid #ccc; border-radius: 6px; font-size: 14px; }
    button { padding: 10px 16px; background: #4A90D9; color: #fff; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; }
    button:hover { background: #357ABD; }
    button.danger { background: #c0392b; }
    button.danger:hover { background: #a02818; }
    button.primary { background: #27ae60; font-weight: 500; }
    button.primary:hover { background: #219a52; }
    table { width: 100%; border-collapse: collapse; }
    th, td { text-align: left; padding: 10px 12px; border-bottom: 1px solid #eee; }
    th { background: #f0f3f6; font-weight: 600; font-size: 13px; color: #444; }
    tbody tr:nth-child(even) { background: #fafbfc; }
    tbody tr:hover { background: #f0f7ff; }
    td.empty { text-align: center; color: #888; padding: 24px; font-size: 14px; }
    .badge { display: inline-block; padding: 2px 8px; font-size: 12px; background: #e8f5e9; color: #2e7d32; border-radius: 4px; }
    .err { color: #c0392b; margin-top: 8px; }
    .loading { color: #666; }
    .card-head { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px; margin-bottom: 16px; }
    .card-head h2 { margin: 0; font-size: 1.1rem; color: #333; }
    .toolbar { margin-bottom: 12px; }
    .toolbar button { margin-right: 8px; }
    .daily-form label { display: block; margin-top: 12px; font-weight: 500; font-size: 13px; color: #444; }
    .daily-form label.daily-check { display: flex; align-items: center; gap: 10px; margin-top: 0; flex-direction: row; }
    .daily-form input[type="text"], .daily-form input[type="number"] { width: 100%; max-width: 400px; }
    .daily-form select { padding: 10px 12px; border: 1px solid #ccc; border-radius: 6px; font-size: 14px; max-width: 320px; }
    .daily-topic-grid { display: flex; flex-wrap: wrap; gap: 10px 18px; margin-top: 8px; max-width: 720px; }
    .daily-topic-item { display: inline-flex; align-items: center; gap: 8px; font-weight: 400; font-size: 13px; color: #333; margin-top: 0; }
    .daily-section-title { margin: 16px 0 6px; font-size: 13px; font-weight: 600; color: #555; }
  </style>

</head>
<body>
  <div class="container">
  <div id="init-admin-data" style="display:none" """ + init_data_attrs + """></div>
    <div id="noAuthCard" class="card">
      <h1>MeowCare 后台管理</h1>
      <p>请使用账号密码登录。</p>
      <p id="loginErr" class="err"></p>
      <form id="loginForm">
        <input type="text" name="username" placeholder="用户名" required />
        <input type="password" name="password" placeholder="密码" required />
        <button type="submit">登录</button>
      </form>
    </div>
    <div id="dashboard" style="display:none;">
      <div class="header" style="border-radius:0;">
        <h1>MeowCare 后台管理</h1>
        <div class="nav">
          <a href="#" data-page="posts">最新/热门管理</a>
          <a href="#" data-page="ugc">待审内容</a>
          <a href="#" data-page="reports">举报</a>
          <a href="#" data-page="cats">宠物管理</a>
          <a href="#" data-page="users">用户管理</a>
          <a href="#" id="navDailyContent" onclick="event.preventDefault(); showTab('daily-content');">每日内容</a>
          <a href="#" data-page="reddit" class="reddit-nav">Reddit 导入</a>
        </div>
        <a href="#" class="logout" id="logout">退出</a>
      </div>
      <div class="main">
        <p id="dashErr" class="err"></p>
        <div id="content"></div>
      </div>
    </div>
  </div>
  <script>
    const API = '';
    (function() {
      var params = new URLSearchParams(location.search);
      var urlUser = params.get('username');
      var urlPass = params.get('password');
      if (urlUser != null && urlPass != null) {
        try {
          document.querySelector('input[name="username"]').value = decodeURIComponent(urlUser);
          document.querySelector('input[name="password"]').value = decodeURIComponent(urlPass);
          if (history.replaceState) history.replaceState({}, '', location.pathname);
          setTimeout(function() { document.getElementById('loginForm').requestSubmit(); }, 150);
        } catch (e) {}
      }
    })();
    function token() { return localStorage.getItem('adminToken'); }

    function setToken(t) { if (t) localStorage.setItem('adminToken', t); else localStorage.removeItem('adminToken'); }
    function headers() { return { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token() }; }
    function authHeaders() { return headers(); }
    function showTab(name) { loadPage(name); }
    function showEl(el, visible) { if (el) el.style.display = visible ? 'block' : 'none'; }
    function showLogin(visible) {
      showEl(document.getElementById('noAuthCard'), visible);
      showEl(document.getElementById('dashboard'), !visible);
    }
    document.getElementById('logout').onclick = function() {
      setToken(null);
      showLogin(true);
      document.getElementById('content').innerHTML = '';
      var de = document.getElementById('dashErr');
      if (de) de.textContent = '';
    };
    document.getElementById('loginForm').onsubmit = async function(e) {
      e.preventDefault();
      var fd = new FormData(e.target);
      var errEl = document.getElementById('loginErr');
      errEl.textContent = '';
      try {
        var r = await fetch(API + '/admin/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ username: (fd.get('username') || '').trim(), password: fd.get('password') || '' }) });
        var data = await r.json().catch(function() { return {}; });
        var tok = data.token;
        if (typeof tok !== 'string') tok = '';
        if (r.ok && tok) { setToken(tok); showLogin(false); loadPage('posts'); }
        else { errEl.textContent = (data && data.detail) ? data.detail : '登录失败，请重试'; }
      } catch (err) { errEl.textContent = err.message || '网络错误'; }
    };

    document.querySelectorAll('.nav a[data-page]').forEach(a => { a.onclick = (e) => { e.preventDefault(); loadPage(a.dataset.page); }; });
    function escHtml(t) {
      return String(t == null ? '' : t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }
    var REDDIT_SUBS = ['cats', 'catcare', 'CatAdvice', 'AskVet', 'kittens', 'catpics'];
    async function loadPage(page) {
      var content = document.getElementById('content');
      var errEl = document.getElementById('loginErr');
      var dashErr = document.getElementById('dashErr');
      function clearErrs() { errEl.textContent = ''; if (dashErr) dashErr.textContent = ''; }
      function authFail(r) {
        if (r.status === 401 || r.status === 403) {
          setToken(null);
          clearErrs();
          errEl.textContent = (r.status === 401) ? '登录已失效，请重新登录' : '无权访问：请使用后台管理员账号登录';
          showLogin(true);
          content.innerHTML = '';
          return true;
        }
        return false;
      }
      if (!token()) { clearErrs(); showLogin(true); return; }
      clearErrs();
      content.innerHTML = '<p class="loading">加载中…</p>';
      try {
        var r, list, url, data, i, rows, ord, sub, sort, items;
        if (page === 'posts') {
          ord = window._postsOrder || 'latest';
          url = API + '/posts?limit=50&order=' + encodeURIComponent(ord === 'hot' ? 'hot' : 'latest');
          r = await fetch(url, { headers: headers() });
          if (authFail(r)) return;
          if (!r.ok) { content.innerHTML = '<p class="err">请求失败 ' + r.status + '</p>'; return; }
          data = await r.json().catch(function() { return {}; });
          items = data.items;
          if (!Array.isArray(items)) items = [];
          rows = items.map(function(p) {
            var pid = p.postId || p.id || '';
            return '<tr><td>' + escHtml(pid) + '</td><td>' + escHtml(p.title) + '</td><td>' + escHtml(p.status) + '</td><td>' + escHtml(p.score) + '</td><td><button onclick="unpublishPost(\\\'' + pid + '\\\')">下架</button> <button class="danger" onclick="deletePostAdmin(\\\'' + pid + '\\\')">删除</button></td></tr>';
          }).join('');
          content.innerHTML = '<div class="card"><div class="card-head"><h2>最新 / 热门 帖子</h2><div class="toolbar"><button type="button" id="btnPostsLatest"' + (ord !== 'hot' ? ' class="primary"' : '') + '>最新</button><button type="button" id="btnPostsHot"' + (ord === 'hot' ? ' class="primary"' : '') + '>热门</button></div></div><table><thead><tr><th>ID</th><th>标题</th><th>状态</th><th>分数</th><th>操作</th></tr></thead><tbody>' + (items.length === 0 ? '<tr><td colspan="5" class="empty">暂无数据。</td></tr>' : rows) + '</tbody></table></div>';
          document.getElementById('btnPostsLatest').onclick = function() { window._postsOrder = 'latest'; loadPage('posts'); };
          document.getElementById('btnPostsHot').onclick = function() { window._postsOrder = 'hot'; loadPage('posts'); };
        } else if (page === 'ugc') {
          url = API + '/ugc/pending';
          r = await fetch(url, { headers: headers() });
          if (authFail(r)) return;
          if (!r.ok) { content.innerHTML = '<p class="err">请求失败 ' + r.status + '</p>'; return; }
          list = await r.json().catch(function() { return []; });
          if (!Array.isArray(list)) list = [];
          content.innerHTML = '<div class="card"><h2>待审 UGC</h2><table><thead><tr><th>postId</th><th>title</th><th>操作</th></tr></thead><tbody>' + (list.length === 0 ? '<tr><td colspan="3" class="empty">暂无待审内容。</td></tr>' : list.map(function(p) { var pid = p.postId || p.id; return '<tr><td>' + escHtml(pid) + '</td><td>' + escHtml(p.title) + '</td><td><button onclick="approve(\\\'' + pid + '\\\')">通过</button> <button class="danger" onclick="reject(\\\'' + pid + '\\\')">拒绝</button></td></tr>'; }).join('')) + '</tbody></table></div>';
        } else if (page === 'reports') {
          url = API + '/reports/open';
          r = await fetch(url, { headers: headers() });
          if (authFail(r)) return;
          if (!r.ok) { content.innerHTML = '<p class="err">请求失败 ' + r.status + '</p>'; return; }
          list = await r.json().catch(function() { return []; });
          if (!Array.isArray(list)) list = [];
          content.innerHTML = '<div class="card"><h2>待处理举报</h2><table><thead><tr><th>举报 ID</th><th>帖子 ID</th><th>原因</th><th>操作</th></tr></thead><tbody>' + (list.length === 0 ? '<tr><td colspan="4" class="empty">暂无待处理举报。</td></tr>' : (list.map(function(rr) { var rid = rr.reportId || rr.id; return '<tr><td>' + escHtml(rid) + '</td><td>' + escHtml(rr.postId) + '</td><td>' + escHtml(rr.reason) + '</td><td><button onclick="resolveReport(\\\'' + rid + '\\\')">已处理</button></td></tr>'; }).join(''))) + '</tbody></table></div>';
        } else if (page === 'cats') {
          url = API + '/admin/cats';
          r = await fetch(url, { headers: headers() });
          if (authFail(r)) return;
          if (!r.ok) { content.innerHTML = '<p class="err">请求失败 ' + r.status + '</p>'; return; }
          data = await r.json().catch(function() { return {}; });
          items = data.items;
          if (!Array.isArray(items)) items = [];
          content.innerHTML = '<div class="card"><h2>宠物列表</h2><table><thead><tr><th>catId</th><th>名称</th><th>主人</th><th>家庭</th><th>操作</th></tr></thead><tbody>' + (items.length === 0 ? '<tr><td colspan="5" class="empty">暂无数据。</td></tr>' : items.map(function(c) { var cid = c.catId || ''; return '<tr><td>' + escHtml(cid) + '</td><td>' + escHtml(c.name) + '</td><td>' + escHtml(c.ownerId) + '</td><td>' + escHtml(c.familyId) + '</td><td><button class="danger" onclick="deleteCatAdmin(\\\'' + cid + '\\\')">删除</button></td></tr>'; }).join('')) + '</tbody></table></div>';
        } else if (page === 'users') {
          url = API + '/admin/users';
          r = await fetch(url, { headers: headers() });
          if (authFail(r)) return;
          if (!r.ok) { content.innerHTML = '<p class="err">请求失败 ' + r.status + '</p>'; return; }
          data = await r.json().catch(function() { return {}; });
          items = data.items;
          if (!Array.isArray(items)) items = [];
          content.innerHTML = '<div class="card"><h2>用户列表</h2><table><thead><tr><th>uid</th><th>邮箱</th><th>显示名</th><th>家庭</th><th>操作</th></tr></thead><tbody>' + (items.length === 0 ? '<tr><td colspan="5" class="empty">暂无数据。</td></tr>' : items.map(function(u) { var uid = u.uid || ''; return '<tr><td>' + escHtml(uid) + '</td><td>' + escHtml(u.email) + '</td><td>' + escHtml(u.displayName) + '</td><td>' + escHtml(u.familyId) + '</td><td><button class="danger" onclick="deleteUserAdmin(\\\'' + uid + '\\\')">删除</button></td></tr>'; }).join('')) + '</tbody></table></div>';
        } else if (page === 'daily-content') {
          content.innerHTML = '<section id="tab-daily-content"><h2 style="margin-top:0;color:#333;">每日内容生成</h2>' +
            '<div class="card daily-form">' +
            '<p style="margin:0 0 8px;color:#666;font-size:14px;">配置写入 Firestore <code>settings/content_generation</code>，并与定时任务、立即生成接口一致。</p>' +
            '<label class="daily-check">启用自动生成（定时） <input type="checkbox" id="dailyEnabled" /></label>' +
            '<label>默认语言</label>' +
            '<select id="dailyLanguage">' +
            '<option value="en">en — English</option>' +
            '<option value="zh">zh — 简体中文</option>' +
            '<option value="ja">ja — 日本語</option>' +
            '<option value="es">es — Español</option>' +
            '<option value="fr">fr — Français</option>' +
            '<option value="de">de — Deutsch</option>' +
            '<option value="pt">pt — Português</option>' +
            '<option value="ru">ru — Русский</option>' +
            '<option value="ko">ko — 한국어</option>' +
            '</select>' +
            '<div class="daily-section-title">分类（多选）</div>' +
            '<div class="daily-topic-grid">' +
            '<label class="daily-topic-item"><input type="checkbox" id="topic_care" value="care" /> care</label>' +
            '<label class="daily-topic-item"><input type="checkbox" id="topic_behavior" value="behavior" /> behavior</label>' +
            '<label class="daily-topic-item"><input type="checkbox" id="topic_feeding" value="feeding" /> feeding</label>' +
            '<label class="daily-topic-item"><input type="checkbox" id="topic_health" value="health" /> health</label>' +
            '<label class="daily-topic-item"><input type="checkbox" id="topic_grooming" value="grooming" /> grooming</label>' +
            '<label class="daily-topic-item"><input type="checkbox" id="topic_kitten" value="kitten" /> kitten</label>' +
            '<label class="daily-topic-item"><input type="checkbox" id="topic_senior_cat" value="senior_cat" /> senior_cat</label>' +
            '<label class="daily-topic-item"><input type="checkbox" id="topic_indoor_cat" value="indoor_cat" /> indoor_cat</label>' +
            '<label class="daily-topic-item"><input type="checkbox" id="topic_hydration" value="hydration" /> hydration</label>' +
            '<label class="daily-topic-item"><input type="checkbox" id="topic_litter_box" value="litter_box" /> litter_box</label>' +
            '</div>' +
            '<label>每日生成条数（定时任务）</label><input type="number" id="dailyCount" min="1" max="20" value="5" />' +
            '<label>生成时间（UTC 小时 0–23）</label><input type="number" id="publishHourUtc" min="0" max="23" value="1" />' +
            '<label class="daily-check">使用 Gemini 生成正文 <input type="checkbox" id="dailyUseGemini" checked /></label>' +
            '<label class="daily-check">必须有图片（无图则存为草稿） <input type="checkbox" id="dailyImageRequired" /></label>' +
            '<div class="toolbar" style="margin-top:16px;">' +
            '<button type="button" class="primary" onclick="saveDailySettings()">保存设置</button> ' +
            '<button type="button" onclick="generateNow(1)">生成 1 条</button> ' +
            '<button type="button" onclick="generateNow(3)">生成 3 条</button>' +
            '</div></div>' +
            '<div class="card"><h3 style="margin-top:0;">今日生成记录（UTC）</h3><table id="dailyContentTable"><thead><tr><th>ID</th><th>标题</th><th>状态</th><th>时间</th></tr></thead><tbody></tbody></table></div></section>';
          loadDailySettings();
          loadLatestPosts();
        } else if (page === 'reddit') {
          sub = window._redditSub || 'CatAdvice';
          sort = window._redditSort || 'new';
          content.innerHTML = '<div class="card"><h2>Reddit 导入</h2><div class="toolbar">子版块 <select id="redditSub">' + REDDIT_SUBS.map(function(s) { return '<option value="' + s + '"' + (s === sub ? ' selected' : '') + '>' + s + '</option>'; }).join('') + '</select> 排序 <select id="redditSort"><option value="new"' + (sort === 'new' ? ' selected' : '') + '>最新</option><option value="hot"' + (sort === 'hot' ? ' selected' : '') + '>热门</option><option value="top_day"' + (sort === 'top_day' ? ' selected' : '') + '>日榜</option><option value="top_week"' + (sort === 'top_week' ? ' selected' : '') + '>周榜</option></select> <button type="button" id="btnRedditFetch">拉取列表</button> <button type="button" id="btnRedditImport" class="primary">导入选中</button></div><p id="redditErr" class="err"></p><div id="redditTableWrap"></div></div>';
          document.getElementById('btnRedditFetch').onclick = async function() {
            var subEl = document.getElementById('redditSub');
            var sortEl = document.getElementById('redditSort');
            var msg = document.getElementById('redditErr');
            var wrap = document.getElementById('redditTableWrap');
            window._redditSub = subEl.value;
            window._redditSort = sortEl.value;
            msg.textContent = '';
            wrap.innerHTML = '<p class="loading">拉取中…</p>';
            try {
              url = API + '/admin/reddit/fetch?subreddit=' + encodeURIComponent(window._redditSub) + '&sort=' + encodeURIComponent(window._redditSort);
              r = await fetch(url, { headers: headers() });
              if (authFail(r)) return;
              if (!r.ok) { var ed = await r.json().catch(function() { return {}; }); wrap.innerHTML = ''; msg.textContent = (ed.detail || ('请求失败 ' + r.status)); return; }
              data = await r.json();
              items = data.items || [];
              window._redditFetched = items;
              if (items.length === 0) { wrap.innerHTML = '<p class="empty">当前列表为空。</p>'; return; }
              wrap.innerHTML = '<table><thead><tr><th></th><th>ID</th><th>标题</th><th>分</th><th>已导入</th></tr></thead><tbody>' + items.map(function(it) {
                var rid = String(it.id || '').replace(/"/g, '');
                return '<tr><td><input type="checkbox" class="reddit-chk" value="' + rid + '"' + (it.alreadyImported ? ' disabled' : '') + ' /></td><td>' + escHtml(it.id) + '</td><td>' + escHtml(it.title) + '</td><td>' + escHtml(it.score) + '</td><td>' + (it.alreadyImported ? '是' : '否') + '</td></tr>';
              }).join('') + '</tbody></table>';
            } catch (e) { wrap.innerHTML = ''; msg.textContent = e.message || '加载失败'; }
          };
          document.getElementById('btnRedditImport').onclick = async function() {
            var msg = document.getElementById('redditErr');
            msg.textContent = '';
            var ids = [];
            document.querySelectorAll('input.reddit-chk:checked').forEach(function(ch) { ids.push(ch.value); });
            if (ids.length === 0) { msg.textContent = '请先勾选要导入的条目'; return; }
            try {
              r = await fetch(API + '/admin/reddit/import', { method: 'POST', headers: headers(), body: JSON.stringify({ reddit_ids: ids, subreddit: window._redditSub || 'CatAdvice', sort: window._redditSort || 'new' }) });
              if (authFail(r)) return;
              data = await r.json().catch(function() { return {}; });
              if (!r.ok) { msg.textContent = data.detail || '导入失败'; return; }
              alert('已导入 ' + (data.imported || 0) + ' 条，跳过 ' + (data.skipped || 0));
              document.getElementById('btnRedditFetch').click();
            } catch (e) { msg.textContent = e.message || '导入失败'; }
          };
        } else {
          content.innerHTML = '<p class="err">未知页面</p>';
        }
      } catch (e) { content.innerHTML = '<p class="err">加载失败: ' + (e.message || '') + '</p>'; }
      document.querySelectorAll('.nav a[data-page]').forEach(function(a) { a.classList.toggle('active', a.dataset.page === page); });
      var ndc = document.getElementById('navDailyContent');
      if (ndc) ndc.classList.toggle('active', page === 'daily-content');
    }

    var DAILY_TOPIC_IDS = ['care','behavior','feeding','health','grooming','kitten','senior_cat','indoor_cat','hydration','litter_box'];
    var DAILY_LANGS = ['en','zh','ja','es','fr','de','pt','ru','ko'];

    function dailyCollectTopics() {
      var topics = [];
      DAILY_TOPIC_IDS.forEach(function(id) {
        var el = document.getElementById('topic_' + id);
        if (el && el.checked) topics.push(id);
      });
      return topics;
    }

    async function loadDailySettings() {
      try {
        var res = await fetch(API + '/content-jobs/settings', { headers: authHeaders() });
        if (!res.ok) return;
        var data = await res.json();
        var en = document.getElementById('dailyEnabled');
        if (en) en.checked = !!data.enabled;
        var dc = document.getElementById('dailyCount');
        if (dc) dc.value = data.dailyCount || 5;
        var ph = document.getElementById('publishHourUtc');
        if (ph) ph.value = (data.publishHourUtc !== undefined && data.publishHourUtc !== null) ? data.publishHourUtc : 1;
        var langSel = document.getElementById('dailyLanguage');
        if (langSel) {
          var lv = (data.language || 'en').toLowerCase();
          langSel.value = (DAILY_LANGS.indexOf(lv) >= 0) ? lv : 'en';
        }
        var savedTopics = data.topics || [];
        DAILY_TOPIC_IDS.forEach(function(id) {
          var el = document.getElementById('topic_' + id);
          if (el) el.checked = savedTopics.indexOf(id) >= 0;
        });
        if (savedTopics.length === 0) {
          ['care','behavior','feeding','health'].forEach(function(id) {
            var el = document.getElementById('topic_' + id);
            if (el) el.checked = true;
          });
        }
        var ug = document.getElementById('dailyUseGemini');
        if (ug) ug.checked = (data.useGemini !== false);
        var ir = document.getElementById('dailyImageRequired');
        if (ir) ir.checked = !!data.imageRequired;
      } catch (e) {}
    }

    async function saveDailySettings() {
      var topics = dailyCollectTopics();
      if (topics.length === 0) { alert('请至少选择一个分类'); return; }
      var body = {
        enabled: document.getElementById('dailyEnabled').checked,
        dailyCount: parseInt(document.getElementById('dailyCount').value || '5', 10),
        publishHourUtc: parseInt(document.getElementById('publishHourUtc').value || '1', 10),
        language: (document.getElementById('dailyLanguage') && document.getElementById('dailyLanguage').value) || 'en',
        topics: topics,
        useGemini: document.getElementById('dailyUseGemini').checked,
        imageRequired: document.getElementById('dailyImageRequired').checked,
      };
      var res = await fetch(API + '/content-jobs/settings', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token() },
        body: JSON.stringify(body),
      });
      if (!res.ok) { alert('保存失败'); return; }
      alert('保存成功');
    }

    async function generateNow(count) {
      var topics = dailyCollectTopics();
      if (topics.length === 0) { alert('请至少选择一个分类'); return; }
      var res = await fetch(API + '/content-jobs/generate-now', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token() },
        body: JSON.stringify({
          count: count,
          topics: topics,
          language: (document.getElementById('dailyLanguage') && document.getElementById('dailyLanguage').value) || 'en',
          useGemini: document.getElementById('dailyUseGemini').checked,
          imageRequired: document.getElementById('dailyImageRequired').checked,
        }),
      });
      var data = await res.json().catch(function() { return {}; });
      if (!res.ok) { alert(data.detail || '生成失败'); return; }
      alert('已生成 ' + (data.created || 0) + ' 条内容');
      loadLatestPosts();
    }

    async function loadLatestPosts() {
      var tbody = document.querySelector('#dailyContentTable tbody');
      if (!tbody) return;
      try {
        var r = await fetch(API + '/posts?limit=80&order=latest', { headers: headers() });
        if (!r.ok) { tbody.innerHTML = '<tr><td colspan="4" class="empty">加载失败</td></tr>'; return; }
        var data = await r.json();
        var items = data.items || [];
        var todayUtc = new Date().toISOString().slice(0, 10);
        var rows = items.filter(function(p) {
          var c = p.createdAt;
          if (!c) return false;
          var s = typeof c === 'string' ? c : String(c);
          return s.indexOf(todayUtc) === 0;
        });
        if (rows.length === 0) {
          tbody.innerHTML = '<tr><td colspan="4" class="empty">今日暂无帖子（按 UTC 日期筛选）。</td></tr>';
          return;
        }
        tbody.innerHTML = rows.map(function(p) {
          var pid = p.postId || p.id || '';
          return '<tr><td>' + escHtml(pid) + '</td><td>' + escHtml(p.title) + '</td><td>' + escHtml(p.status) + '</td><td>' + escHtml(p.createdAt) + '</td></tr>';
        }).join('');
      } catch (e) {
        tbody.innerHTML = '<tr><td colspan="4" class="empty">加载失败</td></tr>';
      }
    }

    async function approve(postId) {
      try {
        const r = await fetch(API + '/ugc/' + postId + '/approve', { method: 'POST', headers: headers() });
        if (r.ok) loadPage('ugc'); else alert((await r.json()).detail || '操作失败');
      } catch (e) { alert(e.message); }
    }
    async function reject(postId) {
      try {
        const r = await fetch(API + '/ugc/' + postId + '/reject', { method: 'POST', headers: headers() });
        if (r.ok) loadPage('ugc'); else alert((await r.json()).detail || '失败');
      } catch (e) { alert(e.message); }
    }
    async function resolveReport(reportId) {
      try {
        const r = await fetch(API + '/reports/' + reportId + '/resolve', { method: 'POST', headers: headers(), body: JSON.stringify({ adminNote: '已处理' }) });
        if (r.ok) loadPage('reports'); else alert((await r.json()).detail || '操作失败');
      } catch (e) { alert(e.message); }
    }
    async function unpublishPost(postId) {
      try {
        const r = await fetch(API + '/posts/' + encodeURIComponent(postId) + '/unpublish', { method: 'POST', headers: headers() });
        if (r.ok) loadPage('posts'); else alert((await r.json()).detail || '操作失败');
      } catch (e) { alert(e.message); }
    }
    async function deletePostAdmin(postId) {
      if (!confirm('确定删除该帖子？')) return;
      try {
        const r = await fetch(API + '/posts/' + encodeURIComponent(postId), { method: 'DELETE', headers: headers() });
        if (r.ok) loadPage('posts'); else alert((await r.json()).detail || '操作失败');
      } catch (e) { alert(e.message); }
    }
    async function deleteCatAdmin(catId) {
      if (!confirm('确定删除该宠物？')) return;
      try {
        const r = await fetch(API + '/admin/cats/' + encodeURIComponent(catId), { method: 'DELETE', headers: headers() });
        if (r.ok) loadPage('cats'); else alert((await r.json()).detail || '操作失败');
      } catch (e) { alert(e.message); }
    }
    async function deleteUserAdmin(uid) {
      if (!confirm('确定删除该用户？将同时删除 Firebase Auth 账号。')) return;
      try {
        const r = await fetch(API + '/admin/users/' + encodeURIComponent(uid), { method: 'DELETE', headers: headers() });
        if (r.ok) loadPage('users'); else alert((await r.json()).detail || '操作失败');
      } catch (e) { alert(e.message); }
    }
    (function bootstrapAdminPage() {
      var el = document.getElementById('init-admin-data');
      if (!el) return;
      var tb64 = el.getAttribute('data-token-base64');
      if (tb64) {
        try { setToken(atob(tb64)); } catch (e) {}
      }
      var eb64 = el.getAttribute('data-login-error-base64');
      if (eb64) {
        try {
          var le = document.getElementById('loginErr');
          if (le) le.textContent = decodeURIComponent(Array.prototype.map.call(atob(eb64), function(c) { return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2); }).join(''));
        } catch (e2) {
          try { document.getElementById('loginErr').textContent = atob(eb64); } catch (e3) {}
        }
      }
    })();
    if (token()) { showLogin(false); loadPage('posts'); }


  </script>

</body>
</html>
"""


def _verify_token_from_cookie(cookie_token: str) -> str | None:
    try:
        payload = jwt.decode(cookie_token, SECRET_KEY, algorithms=["HS256"])
        if payload.get("sub") == "admin":
            return cookie_token
    except Exception:
        pass
    return None


_db = firestore.client()


@router.get("/cats")
async def admin_list_cats(uid: str = Depends(require_admin)):
    """管理员：分页拉取宠物列表。"""
    docs = list(_db.collection("cats").limit(200).stream())
    items = []
    for d in docs:
        data = d.to_dict() or {}
        items.append({
            "catId": d.id,
            "name": data.get("name", ""),
            "ownerId": data.get("ownerId", ""),
            "familyId": data.get("familyId", ""),
        })
    return {"items": items}


@router.delete("/cats/{cat_id}")
async def admin_delete_cat(cat_id: str, uid: str = Depends(require_admin)):
    """管理员：删除宠物。"""
    ref = _db.collection("cats").document(cat_id.strip())
    if not ref.get().exists:
        raise HTTPException(status_code=404, detail="Not found")
    ref.delete()
    return {"ok": True}


@router.get("/users")
async def admin_list_users(uid: str = Depends(require_admin)):
    """管理员：拉取用户列表（Firestore users 集合）。"""
    docs = list(_db.collection("users").limit(200).stream())
    items = []
    for d in docs:
        data = d.to_dict() or {}
        items.append({
            "uid": d.id,
            "email": data.get("email", ""),
            "displayName": data.get("displayName", ""),
            "familyId": data.get("familyId", ""),
        })
    return {"items": items}


@router.delete("/users/{user_uid}")
async def admin_delete_user(user_uid: str, uid: str = Depends(require_admin)):
    """管理员：删除用户（Firestore 文档 + Firebase Auth 账号）。"""
    user_uid = user_uid.strip()
    ref = _db.collection("users").document(user_uid)
    if ref.get().exists:
        ref.delete()
    try:
        firebase_auth.delete_user(user_uid)
    except firebase_auth.UserNotFoundError:
        pass
    return {"ok": True}


REDDIT_SUBREDDITS = ["cats", "catcare", "CatAdvice", "AskVet", "kittens", "catpics"]
REDDIT_LIMIT = 25
REDDIT_USER_AGENT_DEFAULT = "MeowCare:meowcare-admin:1.0 (by /u/meowcare_app)"

# In-memory cache for Reddit OAuth token (client_credentials)
_reddit_token: str | None = None
_reddit_token_expires_at: datetime | None = None


def _reddit_oauth_configured() -> bool:
    cid = (os.environ.get("REDDIT_CLIENT_ID") or "").strip()
    secret = (os.environ.get("REDDIT_CLIENT_SECRET") or "").strip()
    return bool(cid and secret)


def _reddit_headers(access_token: str | None = None) -> dict[str, str]:
    user_agent = (os.environ.get("REDDIT_USER_AGENT") or "").strip() or REDDIT_USER_AGENT_DEFAULT
    headers = {"User-Agent": user_agent}
    if access_token:
        headers["Authorization"] = f"Bearer {access_token}"
    return headers


def _reddit_url(subreddit: str, sort: str, use_oauth: bool = False) -> str:
    """Build Reddit listing URL. sort: new | hot | top_day | top_week."""
    host = "https://oauth.reddit.com" if use_oauth else "https://www.reddit.com"
    base = f"{host}/r/{subreddit.strip() or 'CatAdvice'}"
    if sort == "hot":
        return f"{base}/hot.json"
    if sort == "top_day":
        return f"{base}/top.json?t=day"
    if sort == "top_week":
        return f"{base}/top.json?t=week"
    return f"{base}/new.json"


async def _get_reddit_token() -> str:
    """Get Reddit OAuth token (client_credentials). Uses in-memory cache until ~60s before expiry."""
    global _reddit_token, _reddit_token_expires_at
    now = datetime.now(timezone.utc)
    if _reddit_token and _reddit_token_expires_at and (now + timedelta(seconds=60)) < _reddit_token_expires_at:
        return _reddit_token
    cid = (os.environ.get("REDDIT_CLIENT_ID") or "").strip()
    secret = (os.environ.get("REDDIT_CLIENT_SECRET") or "").strip()
    if not cid or not secret:
        raise ValueError("REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET must be set for OAuth")
    basic = base64.b64encode(f"{cid}:{secret}".encode()).decode()
    async with httpx.AsyncClient(timeout=15.0) as client:
        r = await client.post(
            "https://www.reddit.com/api/v1/access_token",
            headers={
                "Authorization": f"Basic {basic}",
                "Content-Type": "application/x-www-form-urlencoded",
                "User-Agent": _reddit_headers()["User-Agent"],
            },
            data={"grant_type": "client_credentials"},
        )
    r.raise_for_status()
    data = r.json()
    _reddit_token = data.get("access_token")
    expires_in = int(data.get("expires_in", 3600))
    if not _reddit_token:
        raise ValueError("Reddit token response missing access_token")
    _reddit_token_expires_at = now + timedelta(seconds=expires_in)
    return _reddit_token


async def _fetch_reddit_children(subreddit: str = "CatAdvice", sort: str = "new"):
    """请求 Reddit API，返回 children 列表。已配置 OAuth 时使用 oauth.reddit.com + Bearer，否则 www.reddit.com；403 时返回明确提示。"""
    use_oauth = _reddit_oauth_configured()
    url = _reddit_url(subreddit, sort, use_oauth=use_oauth)
    if "?" in url:
        url += f"&limit={REDDIT_LIMIT}"
    else:
        url += f"?limit={REDDIT_LIMIT}"

    if use_oauth:
        token = await _get_reddit_token()
        headers = _reddit_headers(access_token=token)
    else:
        headers = _reddit_headers(access_token=None)

    async with httpx.AsyncClient(timeout=15.0) as client:
        r = await client.get(url, headers=headers)

    if r.status_code == 403:
        if use_oauth:
            raise HTTPException(
                status_code=502,
                detail="Reddit 返回 403。请确认 Reddit 应用 client_id/secret 正确，且请求已发往 oauth.reddit.com。",
            )
        raise HTTPException(
            status_code=503,
            detail="Reddit 已拦截未认证请求（403）。请在 Cloud Run 配置环境变量 REDDIT_CLIENT_ID 与 REDDIT_CLIENT_SECRET（Reddit 应用见 https://www.reddit.com/prefs/apps），并重新部署服务。",
        )

    r.raise_for_status()
    data = r.json()
    return (data.get("data") or {}).get("children") or []




def _reddit_item_to_preview(item: dict) -> dict | None:
    """从 Reddit 单项提取预览：id, title, summary, score, thumbnail, created_utc, permalink, alreadyImported 由调用方填。"""
    d = (item.get("data") or {})
    reddit_id = d.get("id") or ""
    if not reddit_id or d.get("stickied"):
        return None
    title = (d.get("title") or "").strip()
    if not title:
        return None
    selftext = (d.get("selftext") or "").strip()
    summary = (selftext[:200] + "…") if len(selftext) > 200 else selftext
    summary = re.sub(r"\s+", " ", summary).strip()
    score = int(d.get("score") or 0)
    created_utc = int(d.get("created_utc") or 0)
    permalink = (d.get("permalink") or "").strip()
    if permalink and not permalink.startswith("http"):
        permalink = "https://www.reddit.com" + permalink
    thumbnail = d.get("thumbnail") or ""
    return {
        "id": reddit_id,
        "title": title[:200],
        "summary": summary[:300],
        "score": score,
        "thumbnail": thumbnail if (thumbnail and thumbnail.startswith("http")) else "",
        "created_utc": created_utc,
        "permalink": permalink,
    }


@router.get("/reddit/fetch")
async def admin_reddit_fetch(
    subreddit: str = "CatAdvice",
    sort: str = "new",
    uid: str = Depends(require_admin),
):
    """拉取指定 subreddit 的列表，供后台勾选后选择性导入。sort: new | hot | top_day | top_week。"""
    if sort not in ("new", "hot", "top_day", "top_week"):
        sort = "new"
    try:
        children = await _fetch_reddit_children(subreddit=subreddit, sort=sort)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Reddit 请求失败: {e}")

    imported_coll = _db.collection("reddit_imported")
    items = []
    for item in children:
        preview = _reddit_item_to_preview(item)
        if not preview:
            continue
        reddit_id = preview["id"]
        preview["alreadyImported"] = imported_coll.document(reddit_id).get().exists
        items.append(preview)
    return {"ok": True, "items": items, "subreddit": subreddit, "sort": sort}


class RedditImportBody(BaseModel):
    reddit_ids: list[str] = []
    subreddit: str = "CatAdvice"
    sort: str = "new"


@router.post("/reddit/import")
async def admin_reddit_import(body: RedditImportBody, uid: str = Depends(require_admin)):
    """仅导入指定的 Reddit 帖子 ID；需传 subreddit+sort 以便再拉一次完整 data 并写入 redditPermalink。"""
    if not body.reddit_ids:
        return {"ok": True, "imported": 0, "skipped": 0, "total": 0}
    if body.sort not in ("new", "hot", "top_day", "top_week"):
        body = RedditImportBody(reddit_ids=body.reddit_ids, subreddit=body.subreddit, sort="new")
    try:
        children = await _fetch_reddit_children(subreddit=body.subreddit, sort=body.sort)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Reddit 请求失败: {e}")
    want = set(body.reddit_ids)
    posts_coll = _db.collection("posts")
    imported_coll = _db.collection("reddit_imported")
    imported = 0
    skipped = 0
    for item in children:
        d = (item.get("data") or {})
        reddit_id = d.get("id") or ""
        if reddit_id not in want:
            continue
        if not reddit_id or d.get("stickied"):
            skipped += 1
            continue
        if imported_coll.document(reddit_id).get().exists:
            skipped += 1
            continue
        title = (d.get("title") or "").strip()
        selftext = (d.get("selftext") or "").strip()
        if not title:
            skipped += 1
            continue
        permalink = (d.get("permalink") or "").strip()
        if permalink and not permalink.startswith("http"):
            permalink = "https://www.reddit.com" + permalink
        else:
            permalink = permalink or ""
        summary = (selftext[:300] + "…") if len(selftext) > 300 else selftext
        summary = re.sub(r"\s+", " ", summary).strip()
        score = float(d.get("score") or 0)
        created_utc = int(d.get("created_utc") or 0)
        created_dt = datetime.fromtimestamp(created_utc, tz=timezone.utc) if created_utc else datetime.now(timezone.utc)
        thumbnail = d.get("thumbnail") or ""
        cover_url = thumbnail if (thumbnail and thumbnail.startswith("http")) else ""
        ref = posts_coll.document()
        now_utc = datetime.now(timezone.utc)
        ref.set({
            "type": "official",
            "status": "published",
            "title": title[:200],
            "summary": summary[:500],
            "content": selftext[:50000],
            "coverUrl": cover_url[:2000],
            "breedIds": [],
            "topics": ["care"],
            "authorId": "reddit",
            "likeCount": 0,
            "commentCount": 0,
            "score": score,
            "countryCode": "US",
            "redditId": reddit_id,
            "redditPermalink": permalink[:2000],
            "createdAt": created_dt,
            "updatedAt": now_utc,
            "publishedAt": now_utc,
        })
        imported_coll.document(reddit_id).set({"postId": ref.id})
        imported += 1
    return {"ok": True, "imported": imported, "skipped": skipped, "total": len(body.reddit_ids)}




@router.get("")

async def admin_page(request: Request) -> Response:

    # 1) URL 带账号密码且校验通过：302 重定向到 /admin 并设置 Cookie，避免首屏 HTML 被缓存导致 token 不生效
    username = request.query_params.get("username")
    password = request.query_params.get("password")
    if username is not None and password is not None:
        u = (username or "").strip()
        p = (password or "").strip()
        admin_user, admin_pass = _get_admin_creds()
        if u == admin_user and p == admin_pass:
            token = _make_jwt()
            if isinstance(token, bytes):
                token = token.decode("utf-8")
            base = str(request.base_url).rstrip("/")
            if base.startswith("http://"):
                base = "https://" + base[7:]
            redirect_url = f"{base}/admin"

            resp = RedirectResponse(url=redirect_url, status_code=302)
            resp.set_cookie(key="admin_token", value=token, httponly=True, secure=True, samesite="lax", path="/", max_age=604800)
            resp.headers["X-Admin-Login"] = "ok"
            resp.headers["X-Admin-Action"] = "redirect"
            resp.headers["Cache-Control"] = "no-store, no-cache"
            return resp

        return Response(
            content=_admin_html(login_error="账号或密码错误，请确认 URL 或环境变量 ADMIN_USERNAME / ADMIN_PASSWORD"),
            media_type="text/html",
            headers={"X-Admin-Login": "fail"},
        )
    # 2) 请求带 Cookie admin_token：从 Cookie 取 token 注入页面，然后清除 Cookie（一次性）
    cookie_token = request.cookies.get("admin_token")
    if cookie_token and _verify_token_from_cookie(cookie_token):
        html = _admin_html(init_token=cookie_token)
        resp = Response(content=html, media_type="text/html")
        resp.delete_cookie(key="admin_token", path="/")
        resp.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
        resp.headers["Pragma"] = "no-cache"
        resp.headers["X-Admin-Action"] = "cookie-login"
        return resp
    # 2) 无有效 Cookie：显示登录页（表单需 POST /admin/login 获取 token）
    return Response(content=_admin_html(), media_type="text/html", headers={"X-Admin-Action": "form"})








