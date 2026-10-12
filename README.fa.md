<p align="center">
  <img src="./assets/readme/hero.png" width="100%" alt="VPNOpsNyx در یک نشست ایجنت: جدول مسیر داده رله به خروجی که با بایت واقعی سنجیده شده، سلامت پنل دو برند، و یک تغییر DNS که منتظر تأیید اپراتور است">
</p>

<h1 align="center">VPNOpsNyx</h1>

<p align="center">
  اسکیلی که به Claude، Codex و بقیهٔ ایجنت‌های هوش مصنوعی یاد می‌دهد یک ناوگان VPN را بگردانند:<br>
  پنل، نود، تونل، رله و DNS؛ با بایت واقعی سنجیده می‌شود و فقط با تأیید شما تغییر می‌کند.
</p>

<p align="center">
  <a href="https://github.com/nyxon-tech/vpnopsnyx/actions/workflows/quality.yml"><img src="https://img.shields.io/github/actions/workflow/status/nyxon-tech/vpnopsnyx/quality.yml?branch=main&style=flat-square&color=a8b2ff&labelColor=303345&label=checks" alt="Checks"></a>
  <img src="https://img.shields.io/badge/version-0.6.0-a8b2ff?style=flat-square&labelColor=303345" alt="Version 0.6.0">
  <img src="https://img.shields.io/badge/Claude%20%C2%B7%20Codex%20%C2%B7%20any%20agent-a8b2ff?style=flat-square&labelColor=303345" alt="Claude, Codex and any agent">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-a8b2ff?style=flat-square&labelColor=303345" alt="MIT license"></a>
</p>

<p align="center">
  <a href="README.md">English</a> · <b>فارسی</b> · <a href="README.ru.md">Русский</a> · <a href="README.zh-CN.md">简体中文</a>
</p>

یک ناوگان VPN طوری خراب می‌شود که هیچ صفحهٔ وضعیتی نشانش نمی‌دهد. رله `200` جواب می‌دهد و بعد از ۱۵ کیلوبایت می‌ایستد. تونل پینگ می‌دهد و هیچ دیتایی رد نمی‌کند. دیتاسنتر IP شما را عوض می‌کند و هر روشی که دیروز کار می‌کرد از دست می‌رود. پهنای باند یک خروجی روی ۲۰۰ مگابیت محدود می‌شود و تا کاربران شکایت نکنند کسی متوجه نمی‌شود.

**VPNOpsNyx** همان تجربه‌ای را که یک اپراتور باتجربه در ذهن دارد به ایجنت شما می‌دهد. ایجنت ناوگان را بررسی می‌کند، هر مسیر رله به خروجی را با بایت تحویل‌شده از پروب‌های داخل کشور می‌سنجد، علت را پیدا می‌کند، راه‌حل را همراه با راه برگشتش پیشنهاد می‌دهد، و پیش از دست زدن به DNS، پنل یا تونل منتظر شما می‌ماند. این پروژه نه VPN است، نه تونل و نه fork یک پنل؛ مجموعه‌ای از Markdown، JSON و اسکریپت‌های کوچک شل است که هر ایجنتی می‌تواند بخواند.

## نصب

**Claude Code**

```sh
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.claude/skills/vpnopsnyx
```

**Codex**

```sh
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.codex/skills/vpnopsnyx
```

**هر ایجنت دیگر:** مخزن را در پوشهٔ skill یا plugin ایجنت clone کنید و آن را به [`SKILL.md`](SKILL.md) ارجاع دهید. بقیهٔ فایل‌ها Markdown و JSON ساده‌اند و هر محیطی می‌خواندشان. [docs/agent-compatibility.md](docs/agent-compatibility.md) را ببینید.

بعد کافی است به هر زبانی بخواهید:

```text
همهٔ سرورهای هر دو برند را بررسی کن
پنل از ایران باز نمی‌شود، علتش را پیدا کن
آلمان را به سرور هتزنر جدیدم منتقل کن
رله‌ای که مدام قطع می‌شود را از DNS بردار
یک تیکت برای دیتاسنتر دربارهٔ افت بسته بنویس
```

## چه چیزهایی بلد است

| | |
| --- | --- |
| **پنل‌ها** | PasarGuard، 3x-ui / Sanaei، Marzban، Marzneshin، Hiddify، Remnawave، S-UI: نودها، گواهی‌ها، به‌روزرسانی، استخر اتصال دیتابیس، مسدودسازی ورود. |
| **Coreها** | Xray-core، sing-box، WireGuard، AmneziaWG، Hysteria2، TUIC، VLESS / VMess / Trojan، Shadowsocks، Reality و TLS. |
| **تونل‌ها** | GRE، [BackPack](https://github.com/AminMGMT/BackPack) xDi (مستقیم و معکوس)، Backhaul، Rathole، Paqet، FRP، DaggerConnect، SIT / 6to4، رلهٔ WireGuard. |
| **رله‌ها** | DNAT با nftables همراه با پیش‌نمایش و برگشت، کاربر واقعی به تفکیک رله، MSS clamp، حجم و ظرفیت، جدا نگه داشتن برندها. |
| **DNS** | رکوردهای Cloudflare به تفکیک لوکیشن و برند، جابه‌جایی و برگرداندن، ثبت همهٔ تغییرها. |
| **فیلترینگ ایران** | محدودسازی ترافیک حجیم، سیاه‌چالهٔ ترافیک ورودی از خارج، GRE وابسته به دیتاسنتر، لیست سیاه IP، تمام شدن حجم که شبیه قطعی است. |
| **عملیات** | تصویر سلامت، جدول مسیر داده، انتقال سرور، به‌روزرسانی و ری‌بوت امن، رسیدگی به حادثه، تیکت به میزبان. |

## چطور کار می‌کند

<p align="center">
  <img src="./assets/readme/how-it-works.svg" width="100%" alt="کاربران با یک نام DNS به رلهٔ ایران می‌رسند، رله از راه تونل به خروجی خارج می‌فرستد، و خروجی را یک پنل مدیریت می‌کند. VPNOpsNyx هر لایه را می‌سنجد و بدون تأیید اپراتور چیزی را تغییر نمی‌دهد">
</p>

- **بایت را بسنج، نه کد وضعیت را.** هر مسیر با مقدار دیتایی که واقعاً می‌رسد تست می‌شود (یک صفحهٔ کامل، نه فقط `HTTP 200`)، از پروب‌هایی در دیتاسنتر دیگر. رله‌ای که خودش را تست کند چیزی را ثابت نمی‌کند.
- **پیش از هر تغییر DNS، دو پروب.** یک نقطهٔ تست ممکن است خودش خراب باشد. اسکیل فقط وقتی کاربران را جابه‌جا می‌کند که دو پروب داخل کشور هم‌نظر باشند.
- **اول روی پورت آزمایشی، بعد سوییچ.** تونل تازه کنار تونل فعلی ساخته و سنجیده می‌شود. پورت اصلی فقط بعد از قبولی مسیر تازه جابه‌جا می‌شود و مسیر قدیمی برای برگشت سر جایش می‌ماند.
- **تا تأیید شما، فقط خواندن.** ایجنت هیچ رمز، کلید، توکن تونل یا لینک سابی را چاپ یا ذخیره نمی‌کند و راه برگشت هر تغییرش را ثبت می‌کند.

<details>
<summary><b>درس‌های میدانی، اکتبر ۲۰۲۶</b></summary>

درس‌های ناشناس‌شده و `operator-observed` از ناوگانی با دو برند و چند دیتاسنتر رلهٔ ایرانی:

۱. **لینک دائمی GRE بین رله و خروجی.** GRE ساده به‌همراه DNAT جایی که DNAT مستقیم و xDi شکست خوردند کاربر را رد کرد؛ تقریباً CPU مصرف نمی‌کند و محدودیت تعداد لینک برای هر خروجی ندارد، ولی بعضی دیتاسنترها آن را می‌بندند. `scripts/relay/greunit.sh` و `references/tunnels.md` بخش ۱۶.<br>
۲. **رله‌ای که IP تازه می‌گیرد، رلهٔ تازه است.** روی رنج جدید GRE و TCP حجیم از کار افتاد و فقط xDi که خروجی شماره می‌گیرد کار کرد، بعد آن هم مرد. همهٔ روش‌ها را دوباره بسنجید و چنین رله‌ای را هرگز تنها رلهٔ یک لوکیشن نکنید. `references/tunnels.md` بخش ۱۷.<br>
۳. **هر خروجی فقط یک لینک xDi شماره‌گیر، دوباره تأیید شد.** لینک دوم روی چهار خروجی اولین تست را رد کرد و چند دقیقه بعد مرد. خروجی مشترک بین دو برند هم در مجموع فقط یک لینک شماره‌گیر دارد. `references/tunnels.md` بخش ۱۵.<br>
۴. **رلهٔ xDi را پشت دامنهٔ پنل و ساب نگذارید.** خواندن کار کرد ولی بدنهٔ `POST`/`PUT` حدود ۱۶ دقیقه گیر کرد و تمدیدهای ربات شکست خورد. از هر آدرس دامنه یک `POST` تست کنید. `references/pasarguard.md` بخش ۱۶.<br>
۵. **لینک مرده هم CPU می‌خورد.** به محض قطعی قطعی، دو طرف آن را خاموش کنید.<br>
۶. **ورودهای ناموفق پنل را زیر نظر بگیرید و آگاهانه مسدود کنید.** `scripts/panel/auth_failures.sh`، `scripts/panel/blocklist.sh` و `references/pasarguard.md` بخش ۱۷.<br>
۷. **جدایی برندها را هم در DNS و هم روی رله‌ها بررسی کنید.** `scripts/local/dns_brand_audit.sh` برای رکوردها و `scripts/relay/forward_audit.sh` برای پورت‌های فورواردشده.<br>
۸. **دامنهٔ ساب را از همهٔ آدرس‌هایش و با دانلود واقعی تست کنید.** IP مستقیم پنل ورود را جواب داد ولی دانلود ۲۰۰ کیلوبایتی از بیشتر دیتاسنترهای داخل ایران گیر کرد. `scripts/relay/panel_path_check.sh` و `references/pasarguard.md` بخش ۱۶.<br>
۹. **هیچ‌وقت همهٔ رکوردهای یک دامنه را پاک نکنید.** DNSها جواب «وجود ندارد» را تا ۳۰ دقیقه نگه می‌دارند. `references/cloudflare.md`.<br>
۱۰. **اینباندی که در هیچ گروهی نیست به هیچ کاربری نمی‌رسد.** `scripts/panel/inbound_groups.py`، و ساختن اینباند، هاست و گروه تونل با API در `references/pasarguard.md` بخش ۱۸.<br>
۱۱. **رنج IP رله‌ها با هم فرق دارد، ترافیک تمام می‌شود، و خروجی ممکن است آپلود محدود داشته باشد.** وقتی رنج تازه در همهٔ تست‌ها شکست خورد رنج دیگری بخواهید؛ وقتی رله فقط از داخل ایران جواب می‌دهد، ترافیکش را چک کنید. `references/tunnels.md` بخش ۱۷ و `references/iran-filtering.md` بخش ۵.<br>
۱۲. **دو سرویس روی یک پورت ۴۴۳** با روتر SNI در nginx: `references/tunnels.md` بخش ۱۸.<br>
۱۳. **هیچ رله‌ای را با تست از یک نقطه برندارید.** اتصال خود اپراتور قطع شده بود، در حالی که حدود ۱۵۰۰ کاربر بی‌دردسر روی همان رله بودند. از دو پروب داخل کشور و از سمت خروجی تأیید بگیرید. `references/cloudflare.md` بخش ۴.<br>
۱۴. **در ایران پنل را پشت پروکسی Cloudflare نگذارید.** DNSهای داخلی نام‌های پروکسی‌شده را به دو آدرس کند می‌فرستادند. پورت پنل را روی رله‌های GRE بگذارید، برای نام گواهی بگیرید، بعد پروکسی را خاموش کنید. `references/pasarguard.md` بخش ۲۰.<br>
۱۵. **استخر اتصال دیتابیس PasarGuard را بزرگ کنید.** مقدار پیش‌فرض ۵+۵ خطاهای تصادفی پنل می‌ساخت؛ ۲۰+۴۰ و ساختن دوبارهٔ کانتینر درستش کرد. `references/pasarguard.md` بخش ۱۹.<br>
۱۶. **خروجی محدودشده را اول روی پورت آزمایشی منتقل کنید.** بعد از تست، DNAT همان رله را به سرور تازه برگردانید و conntrack را پاک نکنید؛ کاربران بدون قطعی منتقل می‌شوند. `references/node-lifecycle.md` بخش ۱۲.
۱۷. **فقط آدرس‌هایی که تست POST را رد می‌کنند در دامنهٔ پنل بمانند.** یک رله بدنهٔ خرید و تمدید را هم با xDi و هم با GRE گیر انداخت و یک هفته بعد کس دیگری دوباره اضافه‌اش کرد. `scripts/relay/panel_path_check.sh` و `references/pasarguard.md` بخش ۱۶.
۱۸. **بعد از هر نود تازه، گروه اینباندها را بررسی کنید.** دو خروجی تازه هاست و DNS داشتند ولی گروه نداشتند. `scripts/panel/inbound_groups.py`.
۱۹. **ربات در خارج، پنل در ایران:** پراکسی رمزدار روی رلهٔ داخلی‌ای که اتصال از خارج را قبول می‌کند، فقط برای IP ربات. `scripts/relay/bot_panel_proxy.sh`.

جزئیات بیشتر در [docs/field-observations-2026-10.md](docs/field-observations-2026-10.md).

</details>

<details>
<summary><b>داخل مخزن چه هست</b></summary>

| مسیر | محتوا |
| --- | --- |
| [`SKILL.md`](SKILL.md) | نقطهٔ ورود ایجنت: قوانین ایمنی، روند عیب‌یابی، ارجاع به مراجع. |
| [`scripts/`](scripts/README.md) | اسکریپت‌های آزموده در میدان: کاربر واقعی هر رله، سلامت، جدول تست xDi، DNAT بازبینی‌شده، لینک GRE، ویرایش نود و گواهی PasarGuard، DNS در Cloudflare و بررسی جدایی برندها. |
| [`references/`](references/README.md) | معماری، پنل‌ها، تونل‌ها، Cloudflare، حادثه‌ها، ظرفیت، فیلترینگ ایران، چرخهٔ عمر نود. |
| [`guides/panels/`](guides/panels/README.md) · [`guides/tunnels/`](guides/tunnels/README.md) | راهنمای عملیاتی هر پنل و هر خانوادهٔ تونل. |
| [`registries/`](registries/) | فهرست JSON پنل‌ها، coreها، تونل‌ها، ابزارها و ریپازیتوری‌های بررسی‌شدهٔ کامیونیتی. |
| [`docs/`](docs/) | دستورهای نصب، دستورهای شبکه، راهنمای اکوسیستم، ثبت منابع، مشاهدات میدانی، نگهداری و شرایط انتشار. |
| [`templates/fleet-inventory.example.md`](templates/fleet-inventory.example.md) | قالب فهرست خصوصی سرورها. نسخهٔ پرشده را هرگز commit نکنید. |
| `metadata.json` · `agents/openai.yaml` | متادیتای بسته برای محیط‌های غیر Claude و برای Codex. |
| `.github/workflows/` | بررسی ساختار، JSON، لینک‌ها، الگوهای اطلاعات محرمانه و بازبینی ماهانهٔ منابع. |

</details>

<details>
<summary><b>پرسش‌ها</b></summary>

**ایجنت خودسرانه سرورهایم را تغییر می‌دهد؟** نه. تا شما یک تغییر مشخص را تأیید نکنید فقط می‌خواند، و هر تغییر همراه راه برگشتش است. DNS، دیتابیس پنل، سابسکریپشن‌ها و رمزها هرگز بدون تأیید شما دست نمی‌خورند.

**در مخزن IP، کلید یا لینک ساب هست؟** نه. هیچ اطلاعات محرمانه، رمز، توکن API، کلید خصوصی یا فهرست سرور واقعی در آن نیست و CI هر commit را برای الگوهای اطلاعات محرمانه می‌گردد. فهرست سرورهای خودتان را خصوصی نگه دارید.

**اجرای دستورهای نصب امن است؟** فقط دستورهایی که با منبع عمومی اصلی تطبیق داده شده‌اند `verified` هستند. نصب‌کننده‌های شخص ثالث و اسکریپت‌های کامیونیتی همین‌طور برچسب می‌خورند و مثل اجرای کد از راه دور با آن‌ها رفتار می‌شود: ایجنت پیش از اجرا بازبینی‌شان می‌کند.

**با چه ایجنت‌هایی کار می‌کند؟** Claude Code و Codex بدون تنظیم اضافه. هر ایجنتی که Markdown بخواند و دستور شل اجرا کند، از راه `SKILL.md` می‌تواند از آن استفاده کند.

</details>

## کامیونیتی

VPNOpsNyx روی کار عمومی نگه‌دارندگانی بنا شده که ابزارهای VPN، پراکسی، مسیریابی و ضدسانسور را باز نگه می‌دارند. ریپازیتوری‌های آن‌ها پایهٔ فهرست کامیونیتی و بازبینی منابع بوده است:

[erfjabplus](https://github.com/erfjabplus) · [AsanFillter](https://github.com/AsanFillter) · [rezazoom](https://github.com/rezazoom) · [azavaxhuman](https://github.com/azavaxhuman) · [ircfspace](https://github.com/ircfspace) · [primeZdev](https://github.com/primeZdev) · [ppouria](https://github.com/ppouria) · [MHSanaei](https://github.com/MHSanaei)

و پنل‌ها، تونل‌ها و ابزارهایی که در سراسر پروژه به آن‌ها ارجاع شده:

[Azumi67](https://github.com/Azumi67) · [PasarGuard](https://github.com/PasarGuard) · [vpaneladmin](https://github.com/vpaneladmin) · [Gozargah](https://github.com/Gozargah) · [marzneshin](https://github.com/marzneshin) · [hiddify](https://github.com/hiddify) · [remnawave](https://github.com/remnawave) · [alireza0](https://github.com/alireza0) · [Musixal](https://github.com/Musixal) · [behzadea12](https://github.com/behzadea12) · [opiran-club](https://github.com/opiran-club) · [itsFLoKi](https://github.com/itsFLoKi) · [AminMGMT](https://github.com/AminMGMT)

آمدن نام در این فهرست قدردانی و ذکر منبع است، نه تأیید امنیتی. یادداشت‌های هر ریپازیتوری در [docs/community-review.md](docs/community-review.md) است.

## مشارکت

پنل‌ها و تونل‌های تازه، مراحل نصب تأییدشده، راه‌های برگشت امن‌تر، موارد عیب‌یابی، اصلاح منابع و ترجمه همه خوش‌آمدند. مخزن را fork کنید، تغییر را روی یک branch با لینک منابع معتبر انجام دهید و یک pull request به `nyxon-tech/vpnopsnyx` باز کنید. پیش از آن [CONTRIBUTING.md](CONTRIBUTING.md) را بخوانید و هرگز رمز، کلید خصوصی، لینک ساب، IP سرورهای واقعی یا اطلاعات کاربران را نگذارید.

مجوز MIT. غیررسمی است و به هیچ پنل، تونل یا پروژهٔ VPN که مستند می‌کند وابسته نیست.

<p align="center">
  <a href="https://github.com/nyxon-tech"><img src="./assets/readme/made-by-nyxon.svg" width="250" alt="Made by Nyxon"></a>
</p>
