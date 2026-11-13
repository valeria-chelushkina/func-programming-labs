{-# LANGUAGE OverloadedStrings #-}

module Web.Layout
  ( layout
  ) where

import Data.Text (Text)
import Lucid

layout :: Text -> Text -> Html () -> Html ()
layout title active content = do
  html_ [lang_ "uk"] $ do
    head_ $ do
      meta_ [charset_ "utf-8"]
      meta_ [name_ "viewport", content_ "width=device-width, initial-scale=1"]
      title_ (toHtml (title <> " · Department Resources"))
      style_ css
    body_ $ do
      div_ [class_ "app"] $ do
        aside_ [class_ "sidebar"] $ do
          div_ [class_ "brand"] $ do
            span_ [class_ "brand-mark"] "R"
            div_ $ do
              div_ [class_ "brand-title"] "Department"
              div_ [class_ "brand-sub"] "Resources"
          nav_ [class_ "nav"] $ do
            navItem active "dashboard" "Dashboard" "/"
            navItem active "resources" "Resources" "/resources"
            navItem active "authors" "Authors" "/authors"
            navItem active "users" "Users" "/users"
            navItem active "stats" "Statistics" "/stats"
          div_ [class_ "sidebar-foot"] "Haskell · MySQL"
        div_ [class_ "main"] $ do
          header_ [class_ "topbar"] $ do
            form_ [method_ "get", action_ "/resources", class_ "top-search"] $ do
              input_ [type_ "search", name_ "q", placeholder_ "Search resources…"]
              button_ [type_ "submit", class_ "btn btn-primary"] "Search"
          main_ [class_ "content"] content

navItem :: Text -> Text -> Text -> Text -> Html ()
navItem active key label href =
  a_ [href_ href, class_ ("nav-item" <> if key == active then " active" else "")]
     (toHtml label)

css :: Text
css = mconcat
  [ ":root{"
  , "  --bg:#f7f4ff; --surface:#ffffff; --surface-2:#fbf9ff;"
  , "  --border:#e7e0fb; --primary:#7c5cd6; --primary-dark:#6a4bc2;"
  , "  --primary-soft:#efe9ff; --text:#2f2a3d; --muted:#7b7392;"
  , "  --danger:#d9534f; --success:#2e9e6b; --radius:14px;"
  , "}"
  , "*{box-sizing:border-box}"
  , "body{margin:0;background:var(--bg);color:var(--text);"
  , "  font-family:'Segoe UI',system-ui,-apple-system,sans-serif;font-size:15px}"
  , "a{color:var(--primary);text-decoration:none}"
  , "a:hover{text-decoration:underline}"
  , ".app{display:flex;min-height:100vh}"
  , ".sidebar{width:240px;background:var(--surface);border-right:1px solid var(--border);"
  , "  padding:24px 18px;display:flex;flex-direction:column;gap:26px}"
  , ".brand{display:flex;align-items:center;gap:12px}"
  , ".brand-mark{width:40px;height:40px;border-radius:12px;background:var(--primary);"
  , "  color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:20px}"
  , ".brand-title{font-weight:700;font-size:16px;line-height:1.1}"
  , ".brand-sub{color:var(--muted);font-size:13px}"
  , ".nav{display:flex;flex-direction:column;gap:4px}"
  , ".nav-item{padding:10px 12px;border-radius:10px;color:var(--text);font-weight:500}"
  , ".nav-item:hover{background:var(--surface-2);text-decoration:none}"
  , ".nav-item.active{background:var(--primary-soft);color:var(--primary-dark)}"
  , ".sidebar-foot{margin-top:auto;color:var(--muted);font-size:12px}"
  , ".main{flex:1;display:flex;flex-direction:column;min-width:0}"
  , ".topbar{display:flex;justify-content:flex-end;padding:16px 32px;"
  , "  background:rgba(255,255,255,.65);border-bottom:1px solid var(--border)}"
  , ".top-search{display:flex;gap:8px;width:min(520px,100%)}"
  , ".top-search input{flex:1;padding:10px 14px;border:1px solid var(--border);border-radius:10px;"
  , "  background:var(--surface);font:inherit;outline:none}"
  , ".top-search input:focus{border-color:var(--primary);box-shadow:0 0 0 3px var(--primary-soft)}"
  , ".content{padding:28px 32px 48px;max-width:1240px;width:100%}"
  , ".page-title{font-size:28px;margin:0 0 6px}"
  , ".page-sub{color:var(--muted);margin:0 0 22px}"
  , ".page-head-row{display:flex;justify-content:space-between;align-items:flex-start;gap:16px}"
  , ".cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:14px;margin-bottom:22px}"
  , ".cards-4{grid-template-columns:repeat(auto-fit,minmax(150px,1fr))}"
  , ".card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);"
  , "  padding:18px 20px;box-shadow:0 8px 22px rgba(124,92,214,.05)}"
  , ".card-value{font-size:28px;font-weight:700;color:var(--primary-dark)}"
  , ".card-label{color:var(--muted);font-size:13px;margin-top:2px}"
  , ".panel{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);"
  , "  padding:20px 22px;margin-bottom:20px;box-shadow:0 8px 22px rgba(124,92,214,.04)}"
  , ".panel-title{font-size:16px;margin:0 0 14px}"
  , ".grid-2{display:grid;grid-template-columns:1fr 1fr;gap:20px}"
  , ".grid-3{display:grid;grid-template-columns:repeat(3,1fr);gap:14px}"
  , ".table{width:100%;border-collapse:collapse}"
  , ".table th,.table td{text-align:left;padding:11px 12px;border-bottom:1px solid var(--border);"
  , "  vertical-align:middle}"
  , ".table th{background:var(--surface-2);color:var(--muted);font-size:12px;text-transform:uppercase;"
  , "  letter-spacing:.04em}"
  , ".table tr:last-child td{border-bottom:none}"
  , ".table tbody tr:hover{background:var(--surface-2)}"
  , ".num{text-align:right}"
  , ".muted{color:var(--muted)}"
  , ".badge{display:inline-block;padding:3px 9px;border-radius:999px;background:var(--primary-soft);"
  , "  color:var(--primary-dark);font-size:12px;font-weight:600}"
  , ".badge-soft{background:#f1f0f7;color:var(--muted)}"
  , ".badges{display:flex;gap:8px;flex-wrap:wrap}"
  , ".btn{display:inline-block;padding:9px 16px;border-radius:10px;border:1px solid transparent;"
  , "  background:var(--surface);color:var(--text);font:inherit;font-weight:600;cursor:pointer}"
  , ".btn:hover{text-decoration:none}"
  , ".btn-primary{background:var(--primary);color:#fff}"
  , ".btn-primary:hover{background:var(--primary-dark)}"
  , ".btn-ghost{background:transparent;border-color:var(--border);color:var(--primary-dark)}"
  , ".btn-ghost:hover{background:var(--primary-soft)}"
  , ".btn-danger{background:#fdecec;color:var(--danger);border-color:#f6cfcf}"
  , ".btn-danger:hover{background:#f9dcdc}"
  , ".btn-sm{padding:6px 11px;font-size:13px;border-radius:8px}"
  , ".actions{display:flex;gap:10px;flex-wrap:wrap;align-items:center}"
  , ".actions-col{width:1%;white-space:nowrap;text-align:right}"
  , ".filters{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:18px}"
  , ".filters input,.filters select{padding:10px 12px;border:1px solid var(--border);"
  , "  border-radius:10px;background:var(--surface);font:inherit}"
  , ".filters input{flex:1;min-width:220px}"
  , ".form{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);"
  , "  padding:22px;max-width:920px}"
  , ".field{display:flex;flex-direction:column;gap:6px;margin-bottom:16px}"
  , ".field>span,.field>legend{font-weight:600;font-size:13px;color:var(--muted)}"
  , ".input{padding:10px 12px;border:1px solid var(--border);border-radius:10px;background:var(--surface);"
  , "  font:inherit;width:100%;outline:none}"
  , ".input:focus{border-color:var(--primary);box-shadow:0 0 0 3px var(--primary-soft)}"
  , "textarea.input{resize:vertical}"
  , "fieldset.field{border:none;padding:0;margin:0 0 16px}"
  , ".checks{display:flex;flex-wrap:wrap;gap:10px 16px}"
  , ".check{display:flex;align-items:center;gap:7px;font-weight:500}"
  , ".alert{background:#fff4f4;border:1px solid #f3c9c9;color:#a33;padding:12px 14px;"
  , "  border-radius:10px;margin-bottom:16px}"
  , ".prose{margin:0;line-height:1.6;white-space:pre-wrap}"
  , ".list{margin:0;padding-left:18px;line-height:1.8}"
  , ".meta{display:grid;grid-template-columns:130px 1fr;gap:8px 12px;margin:0}"
  , ".meta dt{color:var(--muted);font-size:13px}"
  , ".meta dd{margin:0}"
  , ".empty{color:var(--muted);margin:0}"
  , "@media (max-width:900px){"
  , "  .app{flex-direction:column}.sidebar{width:auto;flex-direction:row;align-items:center;"
  , "    gap:14px;overflow-x:auto;padding:14px 18px}.nav{flex-direction:row}.sidebar-foot{display:none}"
  , "  .content{padding:20px 18px 40px}.grid-2,.grid-3{grid-template-columns:1fr}"
  , "  .topbar{padding:12px 18px}"
  , "}"
  ]
