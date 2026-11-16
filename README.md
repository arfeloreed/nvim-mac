# Gabay sa Aking Neovim Setup

Huling inayos: 2026-11-16. Neovim 0.12.6 (naka-install gamit ang Homebrew), sa MacBook Pro na may WezTerm na terminal.

Ito ang listahan ng lahat ng naka-install sa Neovim ko, kung para saan ang bawat isa, at lahat ng shortcut na dapat kong tandaan.

---

## 1. Nasaan ang mga file

| Ano | Saan |
| --- | --- |
| Lahat ng setting ko (ito mismong folder) | `~/.config/nvim/` |
| Unang file na binabasa ng Neovim | `~/.config/nvim/init.lua` |
| Sarili kong shortcut | `~/.config/nvim/lua/reed/keymaps.lua` |
| Sarili kong setting (line number, tab, at iba pa) | `~/.config/nvim/lua/reed/settings.lua` |
| Isang file bawat plugin | `~/.config/nvim/lua/plugins/` |
| Mga test ng setting | `~/.config/nvim/tests/` |
| Mga tagubilin para kay Claude (wala sa git) | `~/.config/nvim/CLAUDE.md` |
| Listahan ng eksaktong bersyon ng bawat plugin | `~/.config/nvim/lazy-lock.json` |
| Mismong kopya ng mga plugin (dina-download dito) | `~/.local/share/nvim/lazy/` |
| Mga language server, formatter at linter (galing Mason) | `~/.local/share/nvim/mason/` |

Paalala: ang folder na ito ay **settings lang**. Ang mismong mga plugin ay nasa `~/.local/share/nvim/lazy/`. Pag binura ko iyon, kusang ida-download ulit ng Neovim sa susunod na bukas.

Para buksan ang folder na ito:

```
nvim ~/.config/nvim
```

---

## 2. Paano mag-update (pinakamahalagang paalala)

### 2.1 Mga plugin: ang Lazy window

Sa loob ng Neovim, i-type:

```
:Lazy
```

Lalabas ang window ng Lazy (ang tagapamahala ng mga plugin). Sa loob nito:

| Pindutin | Gagawin |
| --- | --- |
| `U` | **Update** ang lahat ng plugin |
| `S` | **Sync**: install ang kulang, burahin ang hindi na ginagamit, at update lahat |
| `I` | Install ang mga plugin na wala pa |
| `X` | Burahin (clean) ang mga plugin na wala na sa setting |
| `C` | Tingnan kung may bagong update, pero hindi pa ia-update |
| `L` | Tingnan ang log (ano ang nagbago sa bawat update) |
| `R` | **Ibalik** ang lahat ng plugin sa bersyong nakasulat sa `lazy-lock.json` |
| `H` | Bumalik sa home ng Lazy window |
| `?` | Ipakita ang tulong |
| `q` | Isara ang window |

**Kapag may nasira pagkatapos mag-update:** naka-git ang folder na ito, kaya nandoon pa ang dating listahan ng bersyon (`lazy-lock.json`). Sa terminal:

```
cd ~/.config/nvim
git restore lazy-lock.json
```

Tapos buksan ang `:Lazy` at pindutin ang `R`. Babalik ang lahat ng plugin sa dati. Kapag maayos ang update, i-commit ang bagong `lazy-lock.json`.

### 2.2 Mga language server, formatter at linter: ang Mason window

```
:Mason
```

| Pindutin | Gagawin |
| --- | --- |
| `U` | Update lahat |
| `u` | Update ang isang nakaturo |
| `i` | Install ang nakaturo |
| `X` | Uninstall ang nakaturo |
| `C` | Tingnan kung alin ang luma na |
| `Return` | Ipakita ang detalye ng nakaturo |
| `g?` | Ipakita ang tulong |
| `q` | Isara |

### 2.3 Iba pang update

| Command | Gagawin |
| --- | --- |
| `:TSUpdate` | Update ang Treesitter (ang tumutulong sa kulay ng code) |
| `:TSInstall <wika>` | Mag-install ng Treesitter parser para sa wikang wala pa sa listahan, hal. `:TSInstall rust`. Hindi na ito kusang nangyayari sa pagbukas ng file. |
| `:checkhealth` | Suriin kung may sira o kulang sa setup |
| `brew upgrade neovim` (sa terminal, hindi sa loob ng Neovim) | Update ang Neovim mismo |

### 2.4 Pagkatapos mag-update: patakbuhin ang mga test

May dalawang test sa `tests/` na sumusuri kung buo pa ang setup. Patakbuhin sa terminal, sa loob ng folder na ito (`cd ~/.config/nvim`):

| Command | Sinusuri |
| --- | --- |
| `nvim --headless -l tests/startup_test.lua` | Tamang language server sa bawat wika (isa lang, walang doble), walang dobleng babala sa Python, gumagana ang `]d`, `gd`, Visual `J`/`K`, ang autocomplete at ang markdown preview, may kulay ang code (pati code block sa markdown), gumagana ang `Control+Space`, ang pagsara ng HTML tag at ang comment sa JSX, kusang lumalabas ang mungkahi sa command line at sa paghahanap, may paliwanag ang bawat shortcut, at walang error o babala sa pagbukas. Mga isang minuto ito. |
| `nvim --headless -l tests/snippet_jump_test.lua` | Gumagana ang `Tab` / `Shift+Tab` sa snippet, at lumalabas ang `K`, `J` at Space kapag sila ang unang tinype |

Kapag walang `[FAIL]`, ayos ang lahat. Ang bawat `[FAIL]` ay nagsasabi kung ano ang mali.

---

## 3. Paano basahin ang mga shortcut (para sa MacBook)

Nakasulat ang lahat ng shortcut dito gamit ang pangalan ng key sa MacBook.

| Nakasulat dito | Key sa MacBook | Simbolo | Paalala |
| --- | --- | --- | --- |
| `Control` | control | ⌃ | Kaliwang ibaba ng keyboard, katabi ng fn. **Ito ang gamit ng Neovim, hindi ang Command.** |
| `Option` | option | ⌥ | Gamitin ang **kaliwang** Option. Ang kanang Option ay para sa espesyal na letra (gaya ng ñ). |
| `Command` | command | ⌘ | Hindi ito ginagamit ng Neovim. Para ito sa WezTerm (tingnan sa ibaba). |
| `Shift` | shift | ⇧ | |
| `Return` | return | ↩ | Ito ang "Enter" sa Windows. |
| `Delete` | delete | ⌫ | Nagbubura pakaliwa. Ito ang "Backspace" sa Windows. |
| `Esc` | esc | ⎋ | Kaliwang itaas ng keyboard. |
| `Tab` | tab | ⇥ | |
| `Space` | space bar | | Ito rin ang **leader key**. |

Paano basahin:

- `Control+s`: pindutin nang **sabay** ang control at `s`.
- `Option+1`: pindutin nang sabay ang kaliwang option at `1`.
- `Space ff`: **sunod-sunod**, hindi sabay. Pindutin ang Space, bitawan, tapos `f`, tapos `f`.
- `Control+w d`: pindutin nang sabay ang control at `w`, bitawan, tapos `d`.
- Ang malaking letra (`K`, `J`, `G`, `O`) ay may kasamang Shift.
- Ang mga nagsisimula sa `Space` ay mga sarili kong shortcut, dahil Space ang leader key.

Mga mode ng Neovim:

- **Normal mode**: para gumalaw at mag-utos. Dito ka pagbukas. `Esc` para bumalik dito.
- **Insert mode**: para mag-type. Pumasok gamit ang `i`.
- **Visual mode**: para pumili ng text. Pumasok gamit ang `v` (letra), `V` (buong linya), o `Control+v` (kahon).
- **Command mode**: nagsisimula sa `:`, halimbawa `:w`.

**Kapag nakalimutan ang shortcut:** pindutin lang ang `Space` at maghintay sandali. Lalabas ang **which-key** na nagpapakita ng lahat ng susunod na pwedeng pindutin, at may maikling paliwanag ang bawat isa. Pwede rin ang `:Telescope keymaps` para hanapin ang kahit anong shortcut ayon sa paliwanag nito.

### Mga key na hawak ng WezTerm

Ang terminal mo (WezTerm) ang sumasalo sa mga key na ito, kaya hindi sila umaabot sa Neovim:

| Key | Ginagawa ng WezTerm |
| --- | --- |
| `Command+C` / `Command+V` | Copy ng text na pinili gamit ang mouse / paste. Gumagana rin ang paste habang nasa Neovim. |
| `Command+T` / `Command+W` | Bagong tab / isara ang tab ng WezTerm |
| `Command+1` hanggang `Command+9` | Lumipat sa tab ng WezTerm |
| `Command+N` | Bagong window ng WezTerm |
| `Command+F` | Maghanap sa terminal |
| `Command+K` | Linisin ang lumang output ng terminal |
| `Command+=` / `Command+-` / `Command+0` | Palakihin / paliitin / ibalik ang laki ng letra |
| `Command+Q` | Isara ang WezTerm (magtatanong muna) |
| `Control+Tab` | Susunod na tab ng WezTerm |
| `Control+=` / `Control+-` / `Control+0` | Laki ng letra rin |
| `Control+Shift` at isang letra o numero | Iba pang utos ng WezTerm |

Kaya ang pag-save sa Neovim ay `Control+s`, hindi `Command+s`.

Gumagana ang `Control+Space` sa Neovim dahil naka-off sa Mac mo ang shortcut ng macOS na gumagamit din nito (ang pagpapalit ng keyboard language, sa System Settings, Keyboard, Keyboard Shortcuts, Input Sources).

---

## 4. Mga plugin at para saan ang bawat isa

### Pamamahala

| Plugin | Para saan |
| --- | --- |
| **lazy.nvim** | Tagapamahala ng lahat ng plugin. Siya ang nag-i-install, nag-a-update at naglo-load ng mga ito. |
| **mason.nvim** | Tagapag-install ng mga language server, formatter at linter (parang app store ng mga tool para sa code). |
| **mason-lspconfig.nvim** | Tulay ng Mason at ng LSP. Siniguradong naka-install ang `pylsp`, `lua_ls`, `ts_ls`, `html`, `cssls`, `tailwindcss`, `ruff`. Hindi nito pinapaandar ang mga server; ang `lspconfig.lua` ang pumipili kung alin ang tatakbo. |
| **mason-tool-installer.nvim** | Siniguradong naka-install ang `prettier`, `stylua`, `ruff`, `eslint_d`. |
| **plenary.nvim** | Library na kailangan ng ibang plugin (gaya ng Telescope). Walang sariling gamit. |

### Pag-unawa sa code (LSP at Treesitter)

| Plugin | Para saan |
| --- | --- |
| **nvim-lspconfig** | Nagbibigay ng handang setting para sa bawat "language server" (ang nagbibigay ng go to definition, error, rename, at iba pa). Pinapaandar ang mga ito gamit ang sariling `vim.lsp.config` / `vim.lsp.enable` ng Neovim 0.11. Naka-on para sa Python (`ruff`), JavaScript/TypeScript (`ts_ls`), HTML, CSS, Lua, at Tailwind. |
| **nvim-lsp-file-operations** | Tumutulong mag-update ng mga import kapag nag-rename ng file (gumagana lang kasama ng ilang file explorer plugin). |
| **nvim-treesitter** | Nag-i-install ng mga parser (ang bumabasa ng istruktura ng code) at nagbibigay ng mas tamang indent. Ang kulay ng code at ang pagpili ayon sa bahagi nito ay gawa na ng Neovim 0.12 mismo, gamit ang mga parser na ito. Naka-`main` branch, ang bersyon para sa Neovim 0.12. Kailangan ng `tree-sitter-cli` para makapag-install ng parser (`brew install tree-sitter-cli`). |
| **nvim-ts-autotag** | Sa HTML/JSX: kusang isinasara ang tag (`<div>` nagiging `<div></div>`), at kapag pinalitan ang pangalan ng bukas na tag, sumasabay ang pansara. |
| **nvim-ts-context-commentstring** | Tamang klase ng comment depende kung nasaan ka (halimbawa sa loob ng JSX). |

### Autocomplete at snippet

| Plugin | Para saan |
| --- | --- |
| **nvim-cmp** | Ang lumalabas na listahan ng mungkahi habang nagta-type. |
| **cmp-nvim-lsp** | Kumukuha ng mungkahi mula sa language server. |
| **cmp-buffer** | Kumukuha ng mungkahi mula sa mga salita sa file na bukas. |
| **cmp-path** | Mungkahi ng pangalan ng folder at file habang nagta-type ng path. |
| **LuaSnip** | Ang makina ng snippet (maikling salita na nagiging buong code). |
| **cmp_luasnip** | Ipinapakita ang mga snippet sa listahan ng mungkahi. |
| **friendly-snippets** | Handang koleksyon ng snippet para sa maraming wika. |
| **lspkind.nvim** | Ang mga icon sa listahan ng mungkahi, parang sa VS Code (ang nvim-cmp ang gumuguhit gamit ang listahan ng icon nito). Pinaiikli rin nito ang sobrang habang mungkahi, hanggang 50 letra. |
| **tailwindcss-colorizer-cmp.nvim** | Sa mungkahi ng Tailwind class, ipinapakita ang mismong kulay bilang maliit na kahon. |

### Pag-format at pagsuri ng code

| Plugin | Para saan |
| --- | --- |
| **conform.nvim** | Inaayos ang itsura ng code **tuwing nagse-save**. `prettier` para sa JS/TS/CSS/HTML/JSON, `stylua` para sa Lua, `ruff` para sa Python. |
| **nvim-lint** | Naghahanap ng mali sa code kapag nagbukas, nag-save, o umalis sa Insert mode. `eslint_d` para sa JS/TS. Ang Python ay sinusuri na ng `ruff` language server, kaya wala na ito rito (para hindi doble ang babala). |
| **trouble.nvim** | Magandang listahan ng lahat ng error at babala sa isang window. |

### Paghahanap at paglipat ng file

| Plugin | Para saan |
| --- | --- |
| **telescope.nvim** | Paghahanap ng file, salita, error, at kahit ano, sa isang popup. Kailangan ng `ripgrep` (`brew install ripgrep`). |
| **telescope-fzf-native.nvim** | Pinapabilis ang paghahanap ng Telescope. |
| **harpoon** | "Bookmark" ng hanggang 4 na file na madalas buksan, para lumipat sa isang pindot. |
| **vim-tmux-navigator** | Iisang shortcut para lumipat sa pagitan ng mga hati ng window. Gumagana rin ito sa tmux, pero walang tmux sa Mac mo ngayon, kaya para lang ito sa mga hati ng Neovim. |
| **auto-session** | Ini-save at ibinabalik ang mga bukas na file at ayos ng window para sa isang folder. **Kusang nagse-save** tuwing aalis sa Neovim, maliban kung nasa `~`, `~/Dev`, `~/Downloads`, `~/Documents` o `~/Desktop` mismo. Hindi kusang nagbabalik; `Space wr` ang pipindutin. |

### Itsura

| Plugin | Para saan |
| --- | --- |
| **rose-pine** | Ang kulay o theme (rose-pine main). Naka-transparent ang background. |
| **lualine.nvim** | Ang status bar sa ibaba (mode, file, git branch, at iba pa). |
| **alpha-nvim** | Ang welcome screen kapag binuksan ang `nvim` na walang file. |
| **indent-blankline.nvim** | Manipis na guhit na nagpapakita ng indent. |
| **nvim-web-devicons** | Mga icon ng file type. Kailangan ng Nerd Font sa terminal. |
| **dressing.nvim** | Mas magandang itsura ng mga popup na nagtatanong (halimbawa sa rename). |
| **which-key.nvim** | Nagpapakita ng listahan ng shortcut kapag pinindot ang Space at naghintay. |

### Iba pa

| Plugin | Para saan |
| --- | --- |
| **Comment.nvim** | Mabilis na paglalagay o pagtanggal ng comment. |
| **nvim-autopairs** | Kusang isinasara ang `(`, `[`, `{`, `"`, `'`. |
| **gitsigns.nvim** | Nagpapakita ng git changes sa gilid ng linya, at mga shortcut para sa git. |
| **todo-comments.nvim** | Kinukulayan ang `TODO`, `FIX`, `HACK`, `WARN`, `PERF`, `NOTE`, `TEST` sa comment, at mahahanap sila. |
| **markdown-preview.nvim** | Bubukas ng preview ng Markdown file sa browser. Tumatakbo lang ito sa loob ng computer mo, hindi bukas sa ibang computer. |

---

## 5. Mga shortcut na ako mismo ang gumawa

Galing ito sa `lua/reed/keymaps.lua`. Lahat ay sa Normal mode maliban kung nakasulat.

### Pangkalahatan

| Shortcut | Gagawin |
| --- | --- |
| `Control+s` | I-save ang file (Normal mode lang). Hindi `Command+s`, dahil para sa WezTerm ang Command. |
| `Space q` | **Isara nang hindi nagse-save.** Mag-ingat: mawawala ang hindi pa naka-save. |
| `Space z` | Buksan ang file explorer ng Neovim (netrw) sa folder ng file na ito |
| `Space nh` | Tanggalin ang highlight ng huling hinanap |

### Pag-comment

| Shortcut | Gagawin |
| --- | --- |
| `Space /` | Lagyan o tanggalan ng comment ang linyang ito |
| `Space /` (sa Visual mode) | Lagyan o tanggalan ng comment ang lahat ng napili |

### Paggalaw at pag-edit

| Shortcut | Gagawin |
| --- | --- |
| `J` (sa Visual mode) | Ibaba ang mga napiling linya |
| `K` (sa Visual mode) | Itaas ang mga napiling linya |
| `Control+d` | Bumaba ng kalahating screen, at nasa gitna ang cursor |
| `Control+u` | Umakyat ng kalahating screen, at nasa gitna ang cursor |
| `n` / `N` | Susunod / nakaraang resulta ng hinanap, at nasa gitna ng screen |
| `Space p` (sa Visual mode) | I-paste sa napili **nang hindi nawawala** ang kinopya mo. Pwedeng i-paste ulit nang paulit-ulit. |
| `Space rw` | Palitan ang salitang nasa cursor sa **buong file**. Lalabas ang command na may salita na; burahin ito, i-type ang bago, tapos `Return`. |

### Paghati ng window (split)

| Shortcut | Gagawin |
| --- | --- |
| `Space sv` | Hatiin pahaba (bagong window sa kanan) |
| `Space sh` | Hatiin pahiga (bagong window sa ibaba) |
| `Space se` | Gawing pantay ang laki ng lahat ng hati |
| `Space sx` | Isara ang hating ito |

### Mga tab

| Shortcut | Gagawin |
| --- | --- |
| `Space to` | Bagong tab |
| `Space tx` | Isara ang tab |
| `Space tn` | Susunod na tab |
| `Space tp` | Nakaraang tab |
| `Space tb` | Buksan ang file na ito sa bagong tab |

---

## 6. Mga shortcut ng bawat plugin

### Telescope (paghahanap)

| Shortcut | Gagawin |
| --- | --- |
| `Space ff` | Hanapin ang **file** ayon sa pangalan |
| `Space fg` | Hanapin ang file na kasama sa git |
| `Space fs` | Hanapin ang **salita sa lahat ng file** sa folder |
| `Space fc` | Hanapin ang salitang nasa cursor sa lahat ng file |
| `Space fb` | Hanapin sa mga file na bukas na |
| `Space fh` | Hanapin sa help ng Neovim |
| `Space ft` | Hanapin lahat ng `TODO`, `FIX` at iba pa |
| `Space gs` | Ipakita ang mga file na nabago o hindi pa nata-track ng git (tingnan sa ibaba) |

**Habang nakabukas ang Telescope popup:**

| Shortcut | Gagawin |
| --- | --- |
| `Control+j` / `Control+k` | Baba / taas sa resulta (sarili kong setting) |
| `↓` / `↑` | Baba / taas din sa resulta |
| `Return` | Buksan |
| `Control+v` | Buksan sa hating pahaba |
| `Control+x` | Buksan sa hating pahiga |
| `Control+t` | Buksan sa bagong tab |
| `Control+u` / `Control+d` | I-scroll ang preview pataas / pababa |
| `Tab` | Markahan ang maraming resulta |
| `Control+q` | Ipadala lahat ng resulta sa "quickfix list" (listahan na pwedeng balikan) |
| `Control+/` | Ipakita ang lahat ng shortcut sa popup |
| `Esc` | Lumipat sa Normal mode sa loob ng popup (pindutin ulit para isara) |
| `Control+c` | Isara agad |

**Sa listahan ng `Space gs` (git status):** may tanda sa tabi ng bawat file. Sa kanan, makikita kung ano ang nabago sa file na nakapili.

| Tanda | Ibig sabihin |
| --- | --- |
| `~` | Nabago ang file |
| `+` | Bagong file na naidagdag na sa git |
| `?` | Hindi pa nata-track ng git |
| `-` | Binura ang file |

Dito, iba ang gamit ng `Tab`: i-stage ang file na nakapili, o i-unstage kung naka-stage na. `Return` para buksan ang file.

### LSP (gumagana lang kapag may language server sa file)

| Shortcut | Gagawin |
| --- | --- |
| `gd` | Pumunta sa **definition** (kung saan ginawa ang function o variable) |
| `gD` | Pumunta sa declaration |
| `gR` | Ipakita lahat ng **gumagamit** nito |
| `gi` | Ipakita ang implementation |
| `gt` | Ipakita ang type definition |
| `K` | Ipakita ang **paliwanag o docs** ng nasa cursor |
| `Space ca` | Ipakita ang mga mungkahing ayos (code action) |
| `Space rn` | **I-rename** ang variable o function sa lahat ng gamit nito |
| `Space d` | Ipakita ang error ng linyang ito |
| `Space D` | Ipakita lahat ng error sa file |
| `]d` / `[d` | Susunod / nakaraang error |
| `Space rs` | I-restart ang language server kapag nagloloko |
| `Control+o` | Bumalik sa dating lugar pagkatapos ng `gd` |

**Kasama na sa Neovim 0.11** (gumagana rin sa file na may language server):

| Shortcut | Gagawin |
| --- | --- |
| `grn` | I-rename (kapareho ng `Space rn`) |
| `grr` | Listahan ng lahat ng gumagamit nito |
| `gra` | Mga mungkahing ayos (kapareho ng `Space ca`) |
| `gri` / `grt` | Implementation / type definition |
| `gO` | Listahan ng lahat ng function at variable sa file |
| `[D` / `]D` | Unang / huling error sa file |
| `Control+w d` | Ipakita ang error sa cursor (kapareho ng `Space d`) |
| `Control+s` (Insert mode) | Ipakita ang parameters ng function habang nagta-type |

### Autocomplete (Insert mode, habang may listahan ng mungkahi)

| Shortcut | Gagawin |
| --- | --- |
| `Control+j` / `Control+k` | Susunod / nakaraang mungkahi |
| `↓` / `↑`, o `Control+n` / `Control+p` | Susunod / nakaraang mungkahi rin |
| `Return` | Piliin ang napiling mungkahi (kailangan munang pumili) |
| `Control+y` | Piliin din ang napiling mungkahi |
| `Control+Space` | Pilitin lumabas ang listahan ng mungkahi |
| `Control+e` | Isara ang listahan |
| `Control+f` / `Control+b` | I-scroll ang docs ng mungkahi |

### Snippet (Insert mode, pagkatapos lumabas ang snippet)

Kapag pumili ng snippet sa listahan ng mungkahi, may mga bahagi itong kailangang punan. Naka-highlight ang unang bahagi; mag-type lang para palitan ito. Lalabas ang kahit anong unang letra, pati malaking `K` at `J`, at ang Space.

| Shortcut | Gagawin |
| --- | --- |
| `Tab` | Tumalon sa **susunod** na bahaging pupunan |
| `Shift+Tab` | Bumalik sa **nakaraang** bahagi |

Kapag wala ka sa loob ng snippet, normal pa rin ang `Tab` (naglalagay ng indent).

Ang test para dito: `nvim --headless -l tests/snippet_jump_test.lua` (patakbuhin sa folder na ito).

### Pag-format at lint

| Shortcut | Gagawin |
| --- | --- |
| (kusa) | Inaayos ang code tuwing nagse-save |
| `Space mp` | Ayusin ang code ngayon (buong file, o ang napili sa Visual mode) |
| `Space l` | Suriin ngayon ang file para sa mali (JS/TS; ang Python ay kusang sinusuri ng language server) |

### Trouble (listahan ng error)

| Shortcut | Gagawin |
| --- | --- |
| `Space xw` | Lahat ng error sa buong project |
| `Space xd` | Mga error sa file na ito lang |
| `Space xq` | Buksan ang quickfix list |
| `Space xl` | Buksan ang location list |

**Sa loob ng Trouble window:** `Return` pumunta, `o` pumunta at isara, `p` preview, `q` isara, `?` tulong.

### Harpoon (bookmark ng file)

| Shortcut | Gagawin |
| --- | --- |
| `Space a` | Idagdag ang file na ito sa harpoon |
| `Option+e` (kaliwang Option) | Buksan ang listahan ng harpoon |
| `Option+1` hanggang `Option+4` (kaliwang Option) | Lumipat agad sa file 1, 2, 3 o 4 |

**Sa loob ng listahan:** `Return` buksan, `dd` tanggalin, ilipat ang linya para baguhin ang ayos, `q` o `Esc` isara.

### Git (gitsigns)

| Shortcut | Gagawin |
| --- | --- |
| `]h` / `[h` | Susunod / nakaraang binagong bahagi (hunk) |
| `Space hp` | Silipin ang binago sa bahaging ito |
| `Space hs` | I-stage ang bahaging ito (o ang napili sa Visual mode). Kapag naka-stage na, pindutin ulit para i-unstage. |
| `Space hr` | Ibalik sa dati ang bahaging ito (o ang napili sa Visual mode) |
| `Space hS` | I-stage ang buong file |
| `Space hR` | Ibalik sa dati ang buong file |
| `Space hb` | Sino ang huling nagbago ng linyang ito (blame) |
| `Space hB` | I-on o i-off ang blame sa bawat linya |
| `Space hd` | Ihambing ang file sa huling commit |
| `Space hD` | Ihambing ang file sa naunang commit |
| `ih` | Piliin ang buong hunk, halimbawa `vih` para i-highlight, `dih` para burahin |

### Paglipat sa pagitan ng hati ng window (tmux navigator)

| Shortcut | Gagawin |
| --- | --- |
| `Control+h` | Lumipat sa kaliwa |
| `Control+j` | Lumipat pababa |
| `Control+k` | Lumipat pataas |
| `Control+l` | Lumipat sa kanan |
| `Control+\` | Bumalik sa dating window |

### Comment.nvim (kasama na sa plugin)

| Shortcut | Gagawin |
| --- | --- |
| `gcc` | Comment o uncomment ang linya |
| `gc` + galaw | Halimbawa `gc3j` (linyang ito at 3 sa ibaba), `gcip` (buong talata) |
| `gbc` | Block comment (`/* */`) |
| `gco` / `gcO` | Bagong comment sa ilalim / ibabaw |
| `gcA` | Comment sa dulo ng linya |
| `gb` + galaw | Block comment ng galaw, halimbawa `gbip` (buong talata) |
| `gc` / `gb` (sa Visual mode) | Comment / block comment ng napili |

### Todo comments

| Shortcut | Gagawin |
| --- | --- |
| `]t` / `[t` | Susunod / nakaraang `TODO` |
| `Space ft` | Hanapin lahat ng `TODO` |

### Treesitter (pagpili ayon sa bahagi ng code)

| Shortcut | Gagawin |
| --- | --- |
| `Control+Space` (Normal o Visual mode) | Simulan pumili; pindutin ulit para lumaki ang napili (salita, tapos expression, tapos function...) |
| `Delete` (⌫) (Visual mode) | Paliitin ang napili, pabalik sa dating laki |

Gawa na ito ng Neovim 0.12 mismo. Pareho rin ang gawa ng `an` (palakihin) at `in` (paliitin) sa Visual mode. Sa file na walang parser, walang mangyayari.

### Session (auto-session)

| Shortcut | Gagawin |
| --- | --- |
| (kusa) | Sine-save ang session tuwing aalis sa Neovim |
| `Space ws` | I-save ngayon ang mga bukas na file para sa folder na ito |
| `Space wr` | Ibalik ang na-save na session ng folder na ito |

### Which-key

| Shortcut | Gagawin |
| --- | --- |
| `Space` (tapos maghintay) | Ipakita ang lahat ng shortcut na nagsisimula sa Space |
| `Space ?` | Ipakita ang mga shortcut na para lang sa file na ito |

### Welcome screen (alpha)

| Pindutin | Gagawin |
| --- | --- |
| `e` | Bagong file |
| `Space ff` | Hanapin ang file |
| `Space fs` | Hanapin ang salita |
| `Space wr` | Ibalik ang session |
| `q` | Isara ang Neovim |

### Markdown preview

| Command | Gagawin |
| --- | --- |
| `:MarkdownPreview` | Buksan ang preview sa browser |
| `:MarkdownPreviewToggle` | Buksan o isara |
| `:MarkdownPreviewStop` | Isara ang preview |

### File explorer (netrw, binubuksan ng `Space z`)

| Pindutin | Gagawin |
| --- | --- |
| `Return` | Buksan ang file o folder |
| `-` | Umakyat sa parent folder |
| `%` | Gumawa ng bagong file |
| `d` | Gumawa ng bagong folder |
| `D` | Burahin |
| `R` | I-rename |
| `i` | Palitan ang itsura ng listahan |

### Mga shortcut na pareho ang pindot pero iba ang gawa

| Shortcut | Saan | Gagawin |
| --- | --- | --- |
| `K` | Normal mode | Ipakita ang docs (LSP) |
| `K` | Visual mode | Itaas ang mga linya |
| `Control+j` / `Control+k` | Normal mode | Lumipat ng window |
| `Control+j` / `Control+k` | Insert mode na may mungkahi, o sa Telescope | Pumili sa listahan |
| `Control+Space` | Normal o Visual mode | Treesitter na pagpili |
| `Tab` | Command line (`:`, `/`, `?`) | Piliin ang susunod na mungkahi sa listahan |
| `Tab` | Insert mode | Tumalon sa susunod na bahagi ng snippet, o maglagay ng indent |
| `Control+Space` | Insert mode | Ipakita ang mungkahi |
| `Space rn` vs `Space rw` | Normal mode | `rn` ay rename gamit ang LSP (matalino); `rw` ay simpleng palit ng salita sa file |
| `Control+s` | Normal mode | I-save |
| `Control+s` | Insert mode | Ipakita ang parameters ng function (galing sa Neovim 0.11) |
| `gt` | Normal mode, file na may language server | Type definition. Sa ibang file, "susunod na tab" ito ng Vim; gamitin ang `Space tn` para sa tab. |
| `gi` | Normal mode, file na may language server | Implementation. Sa ibang file, bumabalik ito sa huling tinype-an mo at nagsisimulang mag-type. |
| `]t` / `[t` | Normal mode | Susunod / nakaraang TODO. Sa Neovim 0.11, para sana ito sa "tags". |

---

## 7. Mga setting na naka-on (para alam ko kung bakit ganito ang itsura)

- May line number, at **relative** ang iba (ilang linya ang layo sa cursor). Kaya `5j` ay baba ng 5 linya.
- Naka-highlight ang linyang kinatatayuan ng cursor.
- Ang Tab ay 2 space.
- Ang paghahanap ay hindi pinapansin ang laki ng letra, **maliban** kung may malaking letra sa hinanap.
- Ang kinopya (`y`) ay napupunta rin sa clipboard ng Mac. Pwede itong i-paste sa ibang app, at ang kinopya sa ibang app ay pwedeng i-paste sa Neovim gamit ang `p`. Gumagana rin ang `Command+V` ng WezTerm.
- Laging may 8 linya sa itaas at ibaba ng cursor habang nag-scroll.
- Bumabalot ang mahahabang linya, at hanggang 80 letra ang lapad ng sinusulat.
- Habang nagta-type ng command (`:`) o naghahanap (`/` o `?`), kusang lumalabas ang listahan ng mungkahi, hindi na kailangan ng `Tab`. Hindi nito pinapalitan ang tinype mo hangga't hindi ka pumipili. Gawa ito ng Neovim 0.12 mismo.

  | Pindutin | Gagawin |
  | --- | --- |
  | `Tab` o `Control+n` | Piliin ang susunod na mungkahi |
  | `Shift+Tab` o `Control+p` | Piliin ang nakaraang mungkahi |
  | `Control+y` | Tanggapin ang napili at isara ang listahan |
  | `Control+e` | Isara ang listahan at ibalik ang tinype mo |
  | Arrow pataas / pababa | Nakaraan / susunod na command sa history, kahit bukas ang listahan |
  | `Return` | Patakbuhin ang command |
- Ang bagong hati ay lumalabas sa kanan o sa ibaba.
- Walang swap file.
- Sandaling kumikislap ang text na kinopya.

---

## 8. Mga pangunahing shortcut ng Vim para bumilis

Ito ang mga shortcut na kasama na sa Vim mismo. Kapag kabisado ko ito, hindi ko na kailangan ng mouse.

### Paggalaw

| Shortcut | Gagawin |
| --- | --- |
| `h` `j` `k` `l` | Kaliwa, baba, taas, kanan |
| `5j`, `12k` | Baba ng 5, taas ng 12 (tingnan ang relative number sa gilid) |
| `w` / `b` | Susunod / nakaraang salita |
| `e` | Dulo ng salita |
| `0` / `^` / `$` | Simula ng linya / unang letra / dulo ng linya |
| `gg` / `G` | Itaas / ibaba ng file |
| `42G` o `:42` | Pumunta sa linya 42 |
| `f` + letra | Tumalon sa letrang iyon sa linyang ito (`fa` = susunod na `a`) |
| `t` + letra | Tumalon bago ang letrang iyon |
| `;` / `,` | Ulitin ang huling `f` o `t` pasulong / paatras |
| `%` | Tumalon sa kapares na `(`, `[`, `{` |
| `{` / `}` | Nakaraang / susunod na talata (blangkong linya) |
| `H` / `M` / `L` | Itaas / gitna / ibaba ng screen |
| `zz` | Ilagay sa gitna ng screen ang linyang ito |
| `Control+o` / `Control+i` | Bumalik / sumulong sa mga lugar na pinuntahan |
| `gx` | Buksan sa browser ang link na nasa cursor |

### Pagpasok sa Insert mode

| Shortcut | Gagawin |
| --- | --- |
| `i` / `a` | Mag-type bago / pagkatapos ng cursor |
| `I` / `A` | Mag-type sa simula / dulo ng linya |
| `o` / `O` | Bagong linya sa ilalim / ibabaw |
| `Esc` | Bumalik sa Normal mode |

### Pag-edit

| Shortcut | Gagawin |
| --- | --- |
| `x` | Burahin ang isang letra |
| `r` + letra | Palitan ang isang letra |
| `dd` | Burahin (cut) ang linya |
| `yy` | Kopyahin ang linya |
| `p` / `P` | I-paste sa ilalim / ibabaw |
| `u` | Undo |
| `Control+r` | Redo |
| `.` | **Ulitin ang huling ginawa.** Isa ito sa pinakamakapangyarihan. |
| `>>` / `<<` | Dagdagan / bawasan ang indent |
| `J` | Pagsamahin ang linyang ito at ang kasunod |
| `~` | Palitan ang laki ng letra |
| `[ Space` / `] Space` | Magdagdag ng blangkong linya sa ibabaw / ilalim (pindutin ang `[` o `]`, tapos Space) |

### Utos + bagay (ang sikreto ng Vim)

Ang Vim ay parang pangungusap: **utos** + **bagay**.

Mga utos: `d` (burahin), `c` (burahin at mag-type), `y` (kopyahin), `v` (piliin).

Mga bagay:

| Bagay | Ibig sabihin |
| --- | --- |
| `iw` / `aw` | Loob ng salita / salita kasama ang space |
| `i"` / `a"` | Loob ng `"..."` / kasama ang `"` |
| `i(` / `a(` | Loob ng `(...)` / kasama ang `()` |
| `i{` / `i[` | Loob ng `{}` / `[]` |
| `it` / `at` | Loob ng HTML tag / kasama ang tag |
| `ip` | Buong talata |

Mga halimbawa:

| Shortcut | Gagawin |
| --- | --- |
| `ciw` | Palitan ang buong salita kahit nasa gitna ka nito |
| `ci"` | Palitan ang laman ng string |
| `di(` | Burahin ang laman ng panaklong |
| `yi{` | Kopyahin ang laman ng `{}` |
| `cit` | Palitan ang laman ng HTML tag |
| `dap` | Burahin ang buong talata |
| `dw` / `d$` | Burahin hanggang susunod na salita / hanggang dulo ng linya |
| `dt)` | Burahin hanggang bago ang `)` |

### Paghahanap at pagpapalit sa isang file

| Shortcut | Gagawin |
| --- | --- |
| `/salita` + `Return` | Hanapin pababa |
| `?salita` + `Return` | Hanapin pataas |
| `n` / `N` | Susunod / nakaraang resulta |
| `*` / `#` | Hanapin ang salitang nasa cursor pababa / pataas |
| `:%s/luma/bago/g` | Palitan lahat ng `luma` ng `bago` sa buong file |
| `:%s/luma/bago/gc` | Pareho, pero tatanungin ka sa bawat isa (`y` oo, `n` hindi) |
| `Space nh` | Tanggalin ang highlight pagkatapos maghanap |

### Paghahanap at pagpapalit sa buong project

1. `Space fs`, i-type ang hinahanap.
2. `Control+q` para ipadala lahat ng resulta sa quickfix list.
3. I-type: `:cdo s/luma/bago/g | update`
4. Papalitan at ise-save lahat ng file na may resulta.

Para isa-isahin ang mga resulta: `]q` / `[q` (susunod / nakaraan sa quickfix list).

### Visual mode

| Shortcut | Gagawin |
| --- | --- |
| `v` | Pumili ng letra-letra |
| `V` | Pumili ng buong linya |
| `Control+v` | Pumili ng kahon (column) |
| `Control+v`, piliin pababa, `I`, mag-type, `Esc` | Mag-type sa maraming linya nang sabay |
| `gv` | Piliin ulit ang huling napili |

### Mga marka (bookmark sa loob ng file)

| Shortcut | Gagawin |
| --- | --- |
| `ma` | Markahan ang lugar bilang `a` |
| `'a` | Bumalik sa linya ng markang `a` |

### Macro (i-record at ulitin ang sunod-sunod na pindot)

| Shortcut | Gagawin |
| --- | --- |
| `qa` | Simulan i-record sa `a` |
| `q` | Itigil ang pag-record |
| `@a` | Patakbuhin ang macro `a` |
| `@@` | Ulitin ang huling macro |
| `10@a` | Patakbuhin nang 10 beses |

### File at buffer

| Shortcut | Gagawin |
| --- | --- |
| `:w` | I-save |
| `:q` | Isara (tatanggi kung may hindi naka-save) |
| `:wq` o `ZZ` | I-save at isara |
| `:e pangalan` | Buksan ang file |
| `Control+6` | Bumalik sa dating file na binuksan |
| `:bn` / `:bp` | Susunod / nakaraang bukas na file |
| `]b` / `[b` | Susunod / nakaraang bukas na file din, mas mabilis |

### Sa loob ng Insert mode

| Shortcut | Gagawin |
| --- | --- |
| `Control+w` | Burahin ang salita bago ang cursor |
| `Control+o` + utos | Gumawa ng isang Normal mode na utos tapos balik sa pag-type |

---

## 9. Karaniwang daloy ng trabaho

1. Sa terminal, pumunta sa project folder at i-type `nvim .`
2. `Space wr` kung gusto ibalik ang huling session.
3. `Space ff` para buksan ang file, o `Space fs` para hanapin ang salita.
4. `Space a` sa 2 hanggang 4 na file na madalas balikan, tapos `Option+1` hanggang `Option+4` para lumipat.
5. `gd` para tingnan kung saan ginawa ang function, `Control+o` para bumalik.
6. `Space rn` para mag-rename nang ligtas.
7. `Control+s` para mag-save (kusang naaayos ang code).
8. `Space xd` para tingnan lahat ng error sa file.
9. `]h` at `Space hp` para silipin ang mga binago bago mag-commit.
10. `Space ws` bago isara, para mabalikan bukas.

---

## 10. Paano maging bihasa

- I-type ang `:Tutor` sa loob ng Neovim. Ito ang opisyal na aralin, mga 30 minuto.
- Magdagdag ng isa o dalawang bagong shortcut lang bawat linggo. Huwag sabay-sabay.
- Kapag napansin kong pinipindot ko ang `j` nang maraming beses, gamitin ang relative number (`8j`) o `}`.
- Kapag paulit-ulit ang ginagawa, subukan ang `.` o gumawa ng macro.
- `:h salita` para basahin ang help ng kahit anong command, halimbawa `:h ciw`.
- `Space fh` para hanapin sa help gamit ang Telescope.
- `:Telescope keymaps` para hanapin ang kahit anong shortcut na nakalimutan.
