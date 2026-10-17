<p align="center">
  <img src="./assets/readme/hero.png" width="100%" alt="VPNOpsNyx 的一次智能体会话：以实际送达字节测量的中继到出口数据路径矩阵、两个品牌的面板健康状况，以及一项等待运维人员批准的 DNS 变更">
</p>

<h1 align="center">VPNOpsNyx</h1>

<p align="center">
  让 Claude、Codex 和其他 AI 智能体运维 VPN 集群的运维技能：<br>
  面板、节点、隧道、中继和 DNS，用真实字节验证，只在你批准后才改动。
</p>

<p align="center">
  <a href="https://github.com/nyxon-tech/vpnopsnyx/actions/workflows/quality.yml"><img src="https://img.shields.io/github/actions/workflow/status/nyxon-tech/vpnopsnyx/quality.yml?branch=main&style=flat-square&color=a8b2ff&labelColor=303345&label=checks" alt="Checks"></a>
  <img src="https://img.shields.io/badge/version-0.6.0-a8b2ff?style=flat-square&labelColor=303345" alt="Version 0.6.0">
  <img src="https://img.shields.io/badge/Claude%20%C2%B7%20Codex%20%C2%B7%20any%20agent-a8b2ff?style=flat-square&labelColor=303345" alt="Claude, Codex and any agent">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-a8b2ff?style=flat-square&labelColor=303345" alt="MIT license"></a>
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.fa.md">فارسی</a> · <a href="README.ru.md">Русский</a> · <b>简体中文</b>
</p>

VPN 集群出故障的方式，状态页永远看不出来。中继返回 `200`，传了 15 KB 就卡住。隧道能 ping 通，却一点数据也不走。机房换了你的 IP，昨天还能用的方式全部失效。某个出口被限速到 200 Mbit，直到用户投诉才有人发现。

**VPNOpsNyx** 把资深运维人员脑子里的经验交给你的 AI 智能体。智能体会检查整个集群，从国内探针用实际送达的字节测量每一条中继到出口的路径，找出原因，给出带回滚方法的修复方案，并在动 DNS、面板或隧道之前等你确认。它不是 VPN、不是隧道，也不是面板的分支：它是任何智能体都能读取的 Markdown、JSON 和小型 shell 脚本。

## 安装

**Claude Code**

```sh
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.claude/skills/vpnopsnyx
```

**Codex**

```sh
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.codex/skills/vpnopsnyx
```

**其他智能体：** 把仓库克隆到智能体的技能或插件目录，并让它读取 [`SKILL.md`](SKILL.md)。其余内容都是普通的 Markdown 和 JSON，任何运行环境都能读取。参见 [docs/agent-compatibility.md](docs/agent-compatibility.md)。

然后直接提要求，用任何语言都可以：

```text
检查两个品牌的所有服务器
面板在伊朗打不开，找出原因
把德国迁到我新的 Hetzner 服务器
把总是掉线的中继从 DNS 里移除
给机房写一份关于丢包的工单
```

## 它懂什么

| | |
| --- | --- |
| **面板** | PasarGuard、3x-ui / Sanaei、Marzban、Marzneshin、Hiddify、Remnawave、S-UI：节点、证书、升级、数据库连接池、登录封禁。 |
| **内核** | Xray-core、sing-box、WireGuard、AmneziaWG、Hysteria2、TUIC、VLESS / VMess / Trojan、Shadowsocks、Reality 与 TLS。 |
| **隧道** | GRE、[BackPack](https://github.com/AminMGMT/BackPack) xDi（正向与反向）、Backhaul、Rathole、Paqet、FRP、DaggerConnect、SIT / 6to4、WireGuard 中继。 |
| **中继** | 带演练和回滚的 nftables DNAT、按中继统计真实用户、MSS clamping、流量配额与容量、品牌隔离。 |
| **DNS** | 按位置和品牌管理 Cloudflare 记录，故障切换与恢复，每次变更都有记录。 |
| **伊朗过滤** | 大流量限速、境外入站黑洞、因机房而异的 GRE、IP 黑名单、看起来像故障的流量配额耗尽。 |
| **运维** | 健康快照、数据路径矩阵、迁移、安全升级与重启、事件排查、向服务商提交工单。 |

## 工作原理

<p align="center">
  <img src="./assets/readme/how-it-works.svg" width="100%" alt="用户通过 DNS 名称到达伊朗中继，中继经隧道转发到境外出口，出口由面板管理。VPNOpsNyx 测量每一层，未经运维人员批准不做任何改动">
</p>

- **测字节，不测状态码。** 每条路径都按实际到达的数据量来测试（完整的测试页面，而不只是 `HTTP 200`），并且从另一个机房的探针发起。中继自己测自己什么也证明不了。
- **改 DNS 前要有两个探针。** 单一测量点本身就可能出问题。只有两个国内探针结论一致时，技能才会调度用户。
- **先用备用端口测试，再切换。** 新隧道在现有隧道旁边建立并测量；新路径通过后才迁移正式端口，旧路径保留以便回滚。
- **你批准之前只读。** 智能体从不打印或保存密码、密钥、隧道令牌和订阅链接，并记录如何撤销它做的每一项改动。

<details>
<summary><b>现场经验，2026 年 10 月</b></summary>

来自一个双品牌、多个伊朗中继机房的运维现场，已脱敏，均为 `operator-observed`：

1. **持久化 GRE 中继链路。** 在 TCP DNAT 和 xDi 都失败的路径上，普通 GRE 加 DNAT 仍能承载用户，几乎不占 CPU，且每个出口没有链路数量限制；但部分机房会封锁 GRE。`scripts/relay/greunit.sh`，`references/tunnels.md` §16。
2. **换了 IP 的中继要当作新中继。** 新网段上 GRE 和大流量 TCP 失效，只有出口主动拨号的 xDi 可用，之后连它也失效。需重新测量所有方式，且不要让这类中继成为某个位置的唯一中继。`references/tunnels.md` §17。
3. **每个出口只能有一条主动拨号的 xDi 链路（再次确认）。** 四个出口上的第二条链路首测通过，几分钟后失效。两个品牌共用的出口合计也只有一条。`references/tunnels.md` §15。
4. **不要把 xDi 中继放到面板和订阅域名后面。** 读取正常，但 `POST`/`PUT` 请求体卡住约 16 分钟，导致机器人续费失败。请对域名的每个地址测试一次 `POST`。`references/pasarguard.md` §16。
5. **失效链路仍然消耗 CPU。** 确认失效后立即在两端停用。
6. **监控面板登录失败并有依据地封禁。** `scripts/panel/auth_failures.sh`、`scripts/panel/blocklist.sh`、`references/pasarguard.md` §17。
7. **在 DNS 和中继两侧都检查品牌隔离。** 记录用 `scripts/local/dns_brand_audit.sh`，转发端口用 `scripts/relay/forward_audit.sh`。
8. **通过每个地址并用真实下载测试订阅域名。** 面板直连 IP 能响应登录，但在国内多数机房下载 200 KB 页面会卡住。`scripts/relay/panel_path_check.sh`，`references/pasarguard.md` §16。
9. **不要让 DNS 名称没有记录。** 解析器会缓存 NXDOMAIN 最多 30 分钟。`references/cloudflare.md`。
10. **不属于任何组的 inbound 不会下发给任何用户。** `scripts/panel/inbound_groups.py`；通过 API 添加隧道 inbound、主机和组见 `references/pasarguard.md` §18。
11. **中继的 IP 段各不相同，流量配额会用完，出口可能限制上行。** 新 IP 段所有测试都失败时请换段；中继只在国内可达时先查配额。`references/tunnels.md` §17，`references/iran-filtering.md` §5。
12. **一个 443 端口承载两个服务**：nginx SNI 路由，见 `references/tunnels.md` §18。
13. **不要凭单一测量点移除中继。** 当时是运维人员自己的网络出了问题，而约 1500 名用户正在该中继上正常使用。请用两个国内探针和出口侧数据确认。`references/cloudflare.md` §4。
14. **在伊朗不要把面板放在 Cloudflare 代理后面。** 国内解析器把被代理的名称解析到两个很慢的地址；把面板端口放到 GRE 中继上，为该名称申请证书，然后再改为仅 DNS。`references/pasarguard.md` §20。
15. **调大 PasarGuard 的数据库连接池。** 默认的 5+5 导致面板随机出错；改为 20+40 并重建容器后恢复正常。`references/pasarguard.md` §19。
16. **被限速的出口先用备用端口迁移。** 测试通过后改一台中继的 DNAT 目标，不要清空 conntrack，用户会无中断地迁移过去。`references/node-lifecycle.md` §12。
17. **面板域名只保留通过 POST 测试的地址。** 某个中继无论走 xDi 还是 GRE 都会卡住下单和续费请求体，一周后又被别人加了回去。`scripts/relay/panel_path_check.sh`，`references/pasarguard.md` §16。
18. **每新增一个节点就检查 inbound 的组。** 两个新出口有主机和 DNS，却没有组。`scripts/panel/inbound_groups.py`。
19. **机器人在境外、面板在境内：** 在能接受境外连接的境内中继上建带密码的代理，只允许机器人 IP。`scripts/relay/bot_panel_proxy.sh`。
20. **出口重启后检查其端口，而不是面板状态。** 两个节点在 Xray 停止的情况下显示 `connected` 达 1.5 小时；重新保存节点后恢复。`references/pasarguard.md` §12。
21. **逐条为中继添加 xDi 链路。** 同时添加多条后，20 分钟内境外到该中继的 ICMP 被封，该中继上的所有 xDi 链路失效。`references/tunnels.md` §15。
22. **从两端 ping GRE 链路。** 一条链路从出口端有响应、从中继端无响应，经过它的端口全部关闭；在中继上重启 GRE 单元后恢复。`references/tunnels.md` §16。

更多内容见 [docs/field-observations-2026-10.md](docs/field-observations-2026-10.md)。

</details>

<details>
<summary><b>仓库里有什么</b></summary>

| 路径 | 内容 |
| --- | --- |
| [`SKILL.md`](SKILL.md) | 智能体入口：安全规则、排查流程、参考资料导航。 |
| [`scripts/`](scripts/README.md) | 经过现场验证的脚本：按中继统计真实用户、健康检查、xDi 测试矩阵、经审核的 DNAT、GRE 链路、PasarGuard 节点与证书修改、Cloudflare DNS 与品牌审计。 |
| [`references/`](references/README.md) | 架构、面板、隧道、Cloudflare、事件、容量、伊朗过滤、节点生命周期。 |
| [`guides/panels/`](guides/panels/README.md) · [`guides/tunnels/`](guides/tunnels/README.md) | 各主要面板和隧道家族的运维手册。 |
| [`registries/`](registries/) | 面板、内核、隧道、工具以及已审查社区仓库的 JSON 清单。 |
| [`docs/`](docs/) | 安装与网络方案、生态指南、来源记录、现场观察、维护与发布条件。 |
| [`templates/fleet-inventory.example.md`](templates/fleet-inventory.example.md) | 私有资产清单模板。切勿提交填写后的副本。 |
| `metadata.json` · `agents/openai.yaml` | 面向非 Claude 运行环境和 Codex 的包元数据。 |
| `.github/workflows/` | 结构、JSON、链接、密钥模式检查和每月来源审查。 |

</details>

<details>
<summary><b>常见问题</b></summary>

**智能体会自行修改我的服务器吗？** 不会。在你批准具体改动之前它只读，每项改动都附带回滚方法。DNS、面板数据库、订阅和凭据未经你同意绝不触碰。

**仓库里有 IP、密钥或订阅链接吗？** 没有。仓库不含任何密钥、凭据、API 令牌、私钥或真实资产清单，CI 会对每次提交扫描密钥模式。请把你自己的清单保持私密。

**安装命令可以放心运行吗？** 只有与公开上游来源核对过的命令才标记为 `verified`。第三方安装程序和社区脚本会如实标注，并被视为远程代码执行：智能体在使用前会先审查。

**支持哪些智能体？** Claude Code 和 Codex 开箱即用。任何能读取 Markdown 并执行 shell 命令的智能体都可以通过 `SKILL.md` 使用它。

</details>

## 社区

VPNOpsNyx 建立在许多维护者的公开工作之上，他们让 VPN、代理、路由和反审查工具保持开放。他们的仓库是社区清单和来源审查的基础：

[erfjabplus](https://github.com/erfjabplus) · [AsanFillter](https://github.com/AsanFillter) · [rezazoom](https://github.com/rezazoom) · [azavaxhuman](https://github.com/azavaxhuman) · [ircfspace](https://github.com/ircfspace) · [primeZdev](https://github.com/primeZdev) · [ppouria](https://github.com/ppouria) · [MHSanaei](https://github.com/MHSanaei)

以及本项目中引用的面板、隧道和工具：

[Azumi67](https://github.com/Azumi67) · [PasarGuard](https://github.com/PasarGuard) · [vpaneladmin](https://github.com/vpaneladmin) · [Gozargah](https://github.com/Gozargah) · [marzneshin](https://github.com/marzneshin) · [hiddify](https://github.com/hiddify) · [remnawave](https://github.com/remnawave) · [alireza0](https://github.com/alireza0) · [Musixal](https://github.com/Musixal) · [behzadea12](https://github.com/behzadea12) · [opiran-club](https://github.com/opiran-club) · [itsFLoKi](https://github.com/itsFLoKi) · [AminMGMT](https://github.com/AminMGMT)

列入名单表示致谢和来源标注，而非安全背书。各仓库的说明见 [docs/community-review.md](docs/community-review.md)。

## 参与贡献

欢迎贡献新的面板和隧道、经过验证的安装步骤、更安全的回滚方法、排障案例、来源更正和翻译。Fork 本仓库，在分支上附带权威来源链接完成修改，然后向 `nyxon-tech/vpnopsnyx` 提交 pull request。提交前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)，并且切勿包含凭据、私钥、订阅链接、真实 IP 或用户数据。

MIT 许可证。非官方项目，与其记录的任何面板、隧道或 VPN 项目均无关联。

<p align="center">
  <a href="https://github.com/nyxon-tech"><img src="./assets/readme/made-by-nyxon.svg" width="250" alt="Made by Nyxon"></a>
</p>
