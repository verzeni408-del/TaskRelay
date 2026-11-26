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

## BSC testnet — PENDING (butuh persetujuan untuk retry)

- Throwaway wallet (testnet SAJA, key di `~/.agent-id-hackathon/testnet-key.json` 0600):
  **0x9b5ae5d908Ee85A4cFaF588df42a9B0E0c7e63d4** — saldo tBNB: 0 (belum didanai)
- Upaya faucet 27 Nov ~00:15 WIB: probe ke `testnet.bnbchain.org/faucet-smart`
  kena approval-timeout runtime (HTTP 301, kemungkinan faucet pindah URL) —
  **JANGAN retry tanpa persetujuan parent/user.**
- Langkah berikut: danai throwaway di atas dengan tBNB dari faucet resmi,
  lalu `forge create --broadcast` ke BSC testnet + verifikasi Sourcify,
  lalu isi `CONTRACT_ADDRESS` di `docs/app.js`.
- ⚠️ TIDAK ADA deploy mainnet. TIDAK ADA pemakaian wallet user (0xD8E12B...).

## Frontend

- `docs/index.html` + `docs/app.js` (vanilla JS, ethers 6.13.4 CDN, no build)
- Fitur: connect wallet, cek Agent ID, list tugas (+ judul dari event), buat/klaim/
  submit (proof text → keccak256)/rilis/cancel, ganti network ke BSC testnet
- Status: selesai, live di GitHub Pages (lihat link di atas).
  `CONTRACT_ADDRESS` masih kosong sampai deploy testnet — banner peringatan tampil.

## The Colony

- Akun: `udin-456321` (terdaftar 26 Nov, key di `~/.thecolony/credentials` 0600)
- Post intro: (status diisi setelah posting)
- Aturan: 1 post intro saja, jangan spam, jangan post lagi sebelum dApp live.

## Yang masih kurang sebelum layak deploy mainnet

1. Deploy + verifikasi di BSC testnet (butuh tBNB faucet — lihat blok testnet di atas).
2. Uji frontend melawan kontrak testnet dengan 2 wallet Agent ID (buat/klaim/submit/rilis).
3. Rekrut 30 alamat Agent ID berinteraksi (gerbang Innovation Award) via The Colony
   + Boltbook (Boltbook butuh signature wallet user — minta persetujuan dulu).
4. Submit form hackathon (nama proyek, website, alamat kontrak, deskripsi pemakaian
   Agent ID) — dilakukan parent, bukan koordinator.
5. Persetujuan user untuk deploy mainnet (biaya ~Rp 375) — belum diminta, bukan tugas ini.
