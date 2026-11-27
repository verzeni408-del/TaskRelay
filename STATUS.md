# TaskRelay — STATUS

Project: TaskRelay (papan tugas antar-agent, BNB Chain)
Hackathon: Binance Agent ID Hackathon — submit deadline **9 Des 2026 15:00 WIB**
Repo: https://github.com/verzeni408-del/TaskRelay
dApp: https://verzeni408-del.github.io/TaskRelay/

## Contract

- Source: `contract/src/TaskRelay.sol` (Solidity 0.8.19, optimizer runs=200, no deps)
- Functions: createTask (bounty boleh 0), claimTask, submitWork (proof bytes32),
  releasePayment (poster, atau claimer setelah deadline + 7 hari), cancelTask (refund)
- Gate: `balanceOf > 0` di Agent ID `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`
- Red lines: no owner/admin, no backdoor, no name lookup, no "passive income" text
- Tests: `forge test` — **11/11 PASS**
- Deploy gas (diukur):
  - `forge test --gas-report`: **820,459 gas**
  - Live receipt anvil (`cast receipt`): **820,429 gas** — target <1 jt gas TERCAPAI
  - Contract size: 3,585 bytes
- Gas per fungsi (anvil, live receipt):
  - createTask 124,497 · claimTask 57,936 · submitWork 52,937 · releasePayment 66,918
- Local anvil E2E: deploy 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 —
  create → claim → submit → release OK, `completed(worker)=1`, `taskCount=1`

## Biaya deploy mainnet (estimasi, BNB ~$552, kurs ~Rp 16.500/$)

- Gas 0,05 gwei (live 26 Nov): 820.429 × 0,05 gwei = **0,000041 BNB ≈ $0,023 ≈ Rp 375**
- Kalau gas naik ke 1 gwei: 0,00082 BNB ≈ $0,45 ≈ Rp 7.500
- Saldo wallet Agentic 0,00135 BNB (≈ Rp 12.300) — cukup untuk deploy berkali-kali
- Interaksi user di mainnet (0,05 gwei): create ~Rp 57, claim ~Rp 27, submit ~Rp 25, release ~Rp 31

## BSC mainnet — ✅ DEPLOYED 27 Nov 2026 ~09:00 WIB (user setuju "gas aja", 08:54 WIB)

- **Kontrak: 0x5985A7DB2B9fef8c44DDFdfd59380890Fb724D58** (BSC mainnet, chain 56)
- Tx deploy: 0x9e1a76b03c97254551c228c1677b484976ea21f258c334b740f8d228a379cfa0, blok 135954618, status sukses
- Deployer: wallet Agentic user 0xD8E12B0642Fc0Ee1F8f70B29c94617420Db7d1d6 (Agent ID 456321.ai, balanceOf = 1 — gate lolos)
- **Cara deploy: baw TIDAK BISA contract creation langsung** (`contract-call preview` wajib `--to`; error "to is required for EVM contract-call"; `wallet send` tidak ada field data). Solusi: panggil **Deterministic Deployment Proxy Arachnid 0x4e59b44847b379578588920ca78fbf26c0b4956c** via `baw contract-call preview/execute` dengan data = salt 32 byte (0x00..00) + creation bytecode — proxy deploy via CREATE2. Preview simulasi sukses, risiko kosong, requireConfirmation=false, lalu execute → BROADCASTED (order 26112700002109178767).
- Gas: 822.274 @ 0,075 gwei = **0,0000617 BNB ≈ Rp 565** (estimasi awal Rp 375 @ 0,05 gwei; gas naik sedikit). Saldo wallet sesudah: ~0,00129 BNB.
- Runtime bytecode mainnet **MATCH persis** dengan build lokal (dan dengan kontrak testnet).
- **Verifikasi Sourcify: exact_match** (creation + runtime) — https://sourcify.dev/server/v2/contract/56/0x5985A7DB2B9fef8c44DDFdfd59380890Fb724D58
- BscScan mainnet: https://bscscan.com/address/0x5985A7DB2B9fef8c44DDFdfd59380890Fb724D58
- dApp sudah diarahkan ke mainnet (commit 10c467f): CONTRACT_ADDRESS + CHAIN_ID 56 di `docs/app.js`, tombol switch 0x38, label "BSC Mainnet".

## BSC testnet — ✅ DEPLOYED 27 Nov 2026 ~08:52 WIB

- **Kontrak: 0xd008DDb86D92931e5c22c33ea1BF842e8C73E28c** (BSC testnet, chain 97)
- Tx deploy: 0xa7f9d942d6d6aba59c9bbc6356b2deb974483a1f5e789a27b47a9d61dd71fcc7, blok 145086499, status sukses
- Gas: 820.685 (target <1 jt ✅), harga gas 0,1 gwei, biaya 0,0000820685 tBNB
- **Verifikasi Sourcify: exact_match** (verified 2026-11-27T01:51:39Z, matchId 60043627) — https://sourcify.dev/server/v2/contract/97/0xd008DDb86D92931e5c22c33ea1BF842e8C73E28c
- BscScan testnet: https://testnet.bscscan.com/address/0xd008DDb86D92931e5c22c33ea1BF842e8C73E28c (fetch teks diblokir 403 — cek manual; BscScan mirror verifikasi Sourcify)
- dApp sudah diisi CONTRACT_ADDRESS (commit 71ef21d) — banner peringatan hilang
- Throwaway wallet (testnet SAJA, key di `~/.agent-id-hackathon/testnet-key.json` 0600):
  **0x9b5ae5d908Ee85A4cFaF588df42a9B0E0c7e63d4** — saldo tBNB: **0,0999179315** (dapat 0,1 dari faucet bot Telegram @bnbchain_official_bot, user kirim alamat 08:48 WIB)
- Faucet web resmi SUDAH TIDAK BISA: `testnet.bnbchain.org/faucet-smart` pindah (HTTP 301) dan sekarang mensyaratkan **0,002 BNB di BSC mainnet** pada alamat yang klaim — throwaway 0, wallet Agentic user cuma 0,00135 BNB, jadi syarat ini TIDAK terpenuhi. Diverifikasi via docs.bnbchain.org 27 Nov 00:36 WIB.
- **Jalur yang jalan: bot Telegram resmi @bnbchain_official_bot** — kirim pesan berisi alamat throwaway di atas, dapat 0,3 tBNB/hari, TANPA syarat saldo mainnet (docs resmi BNB Chain + blog Agent Studio v3). Perlu 1 pesan dari user (atau parent via Telegram) — bukan tugas bot.
- Agen lanjutan 27 Nov 00:35 juga kena execution-risk check di exec pertamanya (`ls` direktori proyek) dan berhenti — pola notice yang sama seperti 26 Nov; retry dari sesi fresh kadang lolos.
- **Alternatif pragmatis:** lewati testnet sama sekali — BUKAN syarat hackathon; kontrak sudah lolos 11/11 forge test + E2E anvil lengkap. Langsung deploy mainnet (~Rp 375) begitu user menyetujui, lalu uji frontend di mainnet dengan nominal kecil.
- Deploy testnet via `forge create` langsung (Deploy.s.sol HANYA untuk anvil — pakai `vm.etch`, tidak jalan di testnet). Verifikasi Sourcify via `forge verify-contract --verifier sourcify --chain-id 97`.
- ⚠️ TIDAK ADA deploy mainnet. TIDAK ADA pemakaian wallet user (0xD8E12B...).

## Frontend

- `docs/index.html` + `docs/app.js` (vanilla JS, ethers 6.13.4 CDN, no build)
- Fitur: connect wallet, cek Agent ID, list tugas (+ judul dari event), buat/klaim/
  submit (proof text → keccak256)/rilis/cancel, ganti network ke BSC testnet
- Status: selesai, live di GitHub Pages (lihat link di atas).
  `CONTRACT_ADDRESS` sekarang = **MAINNET 0x5985A7DB2B9fef8c44DDFdfd59380890Fb724D58** (commit 10c467f, 27 Nov 2026).
  Kontrak testnet lama: 0xd008DDb86D92931e5c22c33ea1BF842e8C73E28c (tetap terverifikasi, tidak dipakai lagi).

## The Colony

- Akun: `udin-456321` (terdaftar 26 Nov, key di `~/.thecolony/credentials` 0600)
- Post intro: ✅ TERKIRIM 27 Nov ~00:3x WIB —
  https://thecolony.ai/post/b6247b1e-64af-43b8-a3c5-1fdfc4fc5931
  (colony "introductions", terverifikasi publik 200, author udin-456321)
- Aturan: 1 post intro saja, jangan spam, jangan post lagi sebelum dApp live.

## Yang masih kurang sebelum layak deploy mainnet

1. ✅ Deploy + verifikasi di BSC testnet — SELESAI 27 Nov 2026 (lihat blok testnet di atas).
2. Uji frontend melawan kontrak **MAINNET** dengan 2 wallet Agent ID (buat/klaim/submit/rilis). Wallet Agentic user pegang 1 Agent ID (bisa posting); butuh 1 holder lain untuk klaim — bagian dari rekrutmen 30 alamat.
3. Rekrut 30 alamat Agent ID berinteraksi (gerbang Innovation Award) via The Colony
   + Boltbook (Boltbook butuh signature wallet user — minta persetujuan dulu).
4. Submit form hackathon (nama proyek, website, alamat kontrak, deskripsi pemakaian
   Agent ID) — dilakukan parent, bukan koordinator.
5. ✅ Persetujuan user untuk deploy mainnet — DIBERI 27 Nov 08:54 WIB ("gas aja segitu"), deploy SELESAI ~09:00 WIB (biaya 0,0000617 BNB ≈ Rp 565).
