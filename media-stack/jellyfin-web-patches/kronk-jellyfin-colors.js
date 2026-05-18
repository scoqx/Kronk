(function () {
  "use strict";

  var STORAGE_KEY = "kronk.jellyfin.colors.v1";
  var PAGE_ID = "kronkJellyfinColorPage";
  var STYLE_ID = "kronkJellyfinColorStyle";
  var MENU_CLASS = "lnkJellyfinColorPreferences";

  var targets = [
    {
      id: "player",
      title: "Player container",
      hint: ".videoPlayerContainer, #videoOsdPage, main player layers",
      color: "#000000",
      enabled: true,
      css: ".videoPlayerContainer,#videoOsdPage,.videoOsdPage,.videoContainer,.htmlVideoPlayerContainer{background:VAR!important;background-color:VAR!important}"
    },
    {
      id: "video",
      title: "Video element",
      hint: "video.htmlvideoplayer, canvas/libass layers",
      color: "#000000",
      enabled: true,
      css: "video,video.htmlvideoplayer,.htmlvideoplayer,canvas,.libassjs-canvas-parent{background:VAR!important;background-color:VAR!important}"
    },
    {
      id: "fullscreen",
      title: "Fullscreen/backdrop",
      hint: "::backdrop and WebKit fullscreen selectors",
      color: "#000000",
      enabled: true,
      css: "::backdrop{background:VAR!important} video:fullscreen,video:-webkit-full-screen,video::-webkit-media-controls-panel,video::-webkit-media-controls-enclosure{background:VAR!important;background-color:VAR!important}"
    },
    {
      id: "gray303030",
      title: "Gray #303030",
      hint: "skip-button, fab/raised, dialogs, toast, theme panels",
      color: "#000000",
      enabled: false,
      css: ".skip-button,.fab,.raised,.ui-corner-all,.ui-shadow,.wizardStartForm,.toast,.skinHeader-withBackground{background:VAR!important;background-color:VAR!important}"
    },
    {
      id: "gray282828",
      title: "Gray #282828",
      hint: "sliderBubble, footer/playlist panels",
      color: "#000000",
      enabled: false,
      css: ".sliderBubble,.appfooter,.playlistSectionButton{background:VAR!important;background-color:VAR!important}"
    },
    {
      id: "gray202020",
      title: "Gray #202020",
      hint: "theme/preload/dark base color",
      color: "#000000",
      enabled: false,
      css: "html,.preload,.skinBody,.backgroundContainer{background:VAR!important;background-color:VAR!important}"
    },
    {
      id: "gray333",
      title: "Gray #333 / rgba(51,51,51,.8)",
      hint: "itemProgressBar and similar indicators",
      color: "#000000",
      enabled: false,
      css: ".itemProgressBar{background:VAR!important;background-color:VAR!important}"
    },
    {
      id: "gray444",
      title: "Gray #444",
      hint: "videoIndicator badges",
      color: "#000000",
      enabled: false,
      css: ".videoIndicator{background:VAR!important;background-color:VAR!important}"
    },
    {
      id: "semiTransparentHeader",
      title: "Header rgba(0,0,0,.6)",
      hint: "semiTransparent header gradients",
      color: "#000000",
      enabled: false,
      css: ".skinHeader.semiTransparent{background:VAR!important;background-color:VAR!important}"
    }
  ];

  function readSettings() {
    var saved = {};
    try {
      saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}") || {};
    } catch (err) {
      saved = {};
    }

    return targets.map(function (target) {
      var item = saved[target.id] || {};
      return Object.assign({}, target, {
        color: typeof item.color === "string" ? item.color : target.color,
        enabled: typeof item.enabled === "boolean" ? item.enabled : target.enabled
      });
    });
  }

  function writeSettings(items) {
    var value = {};
    items.forEach(function (item) {
      value[item.id] = { color: item.color, enabled: item.enabled };
    });
    localStorage.setItem(STORAGE_KEY, JSON.stringify(value));
    applyStyles(items);
  }

  function applyStyles(items) {
    var style = document.getElementById(STYLE_ID);
    if (!style) {
      style = document.createElement("style");
      style.id = STYLE_ID;
      document.head.appendChild(style);
    }

    style.textContent = items.filter(function (item) {
      return item.enabled;
    }).map(function (item) {
      return item.css.split("VAR").join(item.color);
    }).join("\n");
  }

  function getUserIdFromMenu() {
    var link = document.querySelector(".lnkSubtitlePreferences[href*='userId=']");
    if (!link) return "";

    try {
      return new URL(link.href).hash.split("userId=")[1] || "";
    } catch (err) {
      return "";
    }
  }

  function insertMenuItem() {
    var subtitlesLink = document.querySelector(".lnkSubtitlePreferences");
    if (!subtitlesLink || document.querySelector("." + MENU_CLASS)) return;

    var href = "#/mypreferencesjellyfincolors";
    var userId = getUserIdFromMenu();
    if (userId) href += "?userId=" + encodeURIComponent(userId);

    var link = document.createElement("a");
    link.href = href;
    link.className = MENU_CLASS + " listItem-border";
    link.style.cssText = "display:block;margin:0;padding:0";
    link.innerHTML = "<div class=\"listItem\"><span class=\"material-icons listItemIcon listItemIcon-transparent palette\" aria-hidden=\"true\"></span><div class=\"listItemBody\"><div class=\"listItemBodyText\">Jellyfin colors</div></div></div>";
    subtitlesLink.parentNode.insertBefore(link, subtitlesLink.nextSibling);
  }

  function rowHtml(item) {
    return "<div class=\"kronk-color-row\" data-id=\"" + item.id + "\">" +
      "<label class=\"kronk-color-enabled\"><input type=\"checkbox\" " + (item.enabled ? "checked" : "") + "> enable</label>" +
      "<div class=\"kronk-color-main\"><div class=\"kronk-color-title\">" + item.title + "</div><div class=\"kronk-color-hint\">" + item.hint + "</div></div>" +
      "<input class=\"kronk-color-picker\" type=\"color\" value=\"" + item.color + "\">" +
      "<input class=\"kronk-color-text\" type=\"text\" value=\"" + item.color + "\" spellcheck=\"false\">" +
      "</div>";
  }

  function renderPage() {
    var isPage = location.hash.indexOf("#/mypreferencesjellyfincolors") === 0;
    var existing = document.getElementById(PAGE_ID);
    if (!isPage) {
      if (existing) existing.remove();
      return;
    }

    var items = readSettings();
    if (!existing) {
      existing = document.createElement("div");
      existing.id = PAGE_ID;
      document.body.appendChild(existing);
    }

    var userId = getUserIdFromMenu();
    var backHref = "#/mypreferencesmenu" + (userId ? "?userId=" + encodeURIComponent(userId) : "");
    existing.innerHTML = "<div class=\"kronk-color-page\">" +
      "<div class=\"kronk-color-header\"><a class=\"kronk-back\" href=\"" + backHref + "\">Back</a><h2>Jellyfin colors</h2></div>" +
      "<p class=\"kronk-color-desc\">Change suspicious gray groups and then check playback. These settings are saved in this browser/app.</p>" +
      "<div class=\"kronk-color-actions\"><button type=\"button\" data-action=\"allblack\">Enable all as black</button><button type=\"button\" data-action=\"disable\">Disable overrides</button><button type=\"button\" data-action=\"defaults\">Defaults</button></div>" +
      "<div class=\"kronk-color-list\">" + items.map(rowHtml).join("") + "</div>" +
      "</div>";

    existing.querySelectorAll(".kronk-color-row").forEach(function (row) {
      var id = row.getAttribute("data-id");
      var checkbox = row.querySelector("input[type='checkbox']");
      var picker = row.querySelector(".kronk-color-picker");
      var text = row.querySelector(".kronk-color-text");

      function update() {
        var current = readSettings();
        current.forEach(function (item) {
          if (item.id === id) {
            item.enabled = checkbox.checked;
            item.color = text.value || picker.value || item.color;
          }
        });
        writeSettings(current);
      }

      checkbox.addEventListener("change", update);
      picker.addEventListener("input", function () {
        text.value = picker.value;
        update();
      });
      text.addEventListener("change", function () {
        picker.value = text.value;
        update();
      });
    });

    existing.querySelector("[data-action='allblack']").addEventListener("click", function () {
      writeSettings(readSettings().map(function (item) {
        item.enabled = true;
        item.color = "#000000";
        return item;
      }));
      renderPage();
    });
    existing.querySelector("[data-action='disable']").addEventListener("click", function () {
      writeSettings(readSettings().map(function (item) {
        item.enabled = false;
        return item;
      }));
      renderPage();
    });
    existing.querySelector("[data-action='defaults']").addEventListener("click", function () {
      localStorage.removeItem(STORAGE_KEY);
      applyStyles(readSettings());
      renderPage();
    });
  }

  function addUiStyles() {
    if (document.getElementById("kronkJellyfinColorUiStyle")) return;

    var style = document.createElement("style");
    style.id = "kronkJellyfinColorUiStyle";
    style.textContent = "#kronkJellyfinColorPage{position:fixed;inset:0;z-index:999999;overflow:auto;background:#101010;color:rgba(255,255,255,.9);font-family:inherit}.kronk-color-page{max-width:820px;margin:0 auto;padding:max(24px,env(safe-area-inset-top)) 20px max(32px,env(safe-area-inset-bottom))}.kronk-color-header{display:flex;align-items:center;gap:16px}.kronk-color-header h2{margin:0;font-size:1.7rem}.kronk-back{color:#00a4dc;text-decoration:none}.kronk-color-desc{opacity:.78;line-height:1.45}.kronk-color-actions{display:flex;flex-wrap:wrap;gap:10px;margin:18px 0}.kronk-color-actions button{background:#303030;color:#fff;border:0;border-radius:8px;padding:10px 14px}.kronk-color-list{display:grid;gap:10px}.kronk-color-row{display:grid;grid-template-columns:auto 1fr auto 110px;gap:12px;align-items:center;background:#1b1b1b;border:1px solid rgba(255,255,255,.12);border-radius:12px;padding:12px}.kronk-color-enabled{white-space:nowrap}.kronk-color-title{font-weight:700}.kronk-color-hint{font-size:.9rem;opacity:.65;margin-top:2px}.kronk-color-picker{width:44px;height:38px;border:0;background:transparent}.kronk-color-text{width:110px;background:#000;color:#fff;border:1px solid rgba(255,255,255,.2);border-radius:8px;padding:8px}@media(max-width:640px){.kronk-color-row{grid-template-columns:1fr auto}.kronk-color-enabled,.kronk-color-main{grid-column:1/-1}.kronk-color-text{width:100%}}";
    document.head.appendChild(style);
  }

  function tick() {
    addUiStyles();
    applyStyles(readSettings());
    insertMenuItem();
    renderPage();
  }

  window.addEventListener("hashchange", function () {
    setTimeout(tick, 50);
  });
  new MutationObserver(function () {
    insertMenuItem();
  }).observe(document.documentElement, { childList: true, subtree: true });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", tick);
  } else {
    tick();
  }
  setTimeout(tick, 1000);
  setTimeout(tick, 3000);
})();
