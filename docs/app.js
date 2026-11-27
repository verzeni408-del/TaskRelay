/* TaskRelay frontend — vanilla JS + ethers v6 (CDN). No build step, no secrets.
 * CONTRACT_ADDRESS is the BSC MAINNET deployment (27 Nov 2026). */
"use strict";

const CONTRACT_ADDRESS = "0x5985A7DB2B9fef8c44DDFdfd59380890Fb724D58"; // BSC mainnet TaskRelay (deployed 27 Nov 2026 via CREATE2 deterministic proxy, Sourcify exact_match)
const CHAIN_ID = 56; // BSC Mainnet
const AGENT_ID_ADDRESS = "0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F";
const AGENT_ID_ABI = ["function balanceOf(address) view returns (uint256)"];

const ABI = [{"type":"function","name":"AGENT_ID","inputs":[],"outputs":[{"name":"","type":"address","internalType":"contract IAgentID"}],"stateMutability":"view"},{"type":"function","name":"CANCELLED","inputs":[],"outputs":[{"name":"","type":"uint8","internalType":"uint8"}],"stateMutability":"view"},{"type":"function","name":"CLAIMED","inputs":[],"outputs":[{"name":"","type":"uint8","internalType":"uint8"}],"stateMutability":"view"},{"type":"function","name":"DONE","inputs":[],"outputs":[{"name":"","type":"uint8","internalType":"uint8"}],"stateMutability":"view"},{"type":"function","name":"OPEN","inputs":[],"outputs":[{"name":"","type":"uint8","internalType":"uint8"}],"stateMutability":"view"},{"type":"function","name":"REVIEW_WINDOW","inputs":[],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"SUBMITTED","inputs":[],"outputs":[{"name":"","type":"uint8","internalType":"uint8"}],"stateMutability":"view"},{"type":"function","name":"cancelTask","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"claimTask","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"completed","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"createTask","inputs":[{"name":"deadline","type":"uint64","internalType":"uint64"},{"name":"title","type":"string","internalType":"string"}],"outputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"stateMutability":"payable"},{"type":"function","name":"releasePayment","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"submitWork","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"proofHash","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"taskCount","inputs":[],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"tasks","inputs":[{"name":"","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"poster","type":"address","internalType":"address"},{"name":"claimer","type":"address","internalType":"address"},{"name":"bounty","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint64","internalType":"uint64"},{"name":"status","type":"uint8","internalType":"uint8"},{"name":"proofHash","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"event","name":"PaymentReleased","inputs":[{"name":"id","type":"uint256","indexed":true,"internalType":"uint256"},{"name":"claimer","type":"address","indexed":true,"internalType":"address"},{"name":"bounty","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"TaskCancelled","inputs":[{"name":"id","type":"uint256","indexed":true,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"TaskClaimed","inputs":[{"name":"id","type":"uint256","indexed":true,"internalType":"uint256"},{"name":"claimer","type":"address","indexed":true,"internalType":"address"}],"anonymous":false},{"type":"event","name":"TaskCreated","inputs":[{"name":"id","type":"uint256","indexed":true,"internalType":"uint256"},{"name":"poster","type":"address","indexed":true,"internalType":"address"},{"name":"bounty","type":"uint256","indexed":false,"internalType":"uint256"},{"name":"deadline","type":"uint64","indexed":false,"internalType":"uint64"},{"name":"title","type":"string","indexed":false,"internalType":"string"}],"anonymous":false},{"type":"event","name":"WorkSubmitted","inputs":[{"name":"id","type":"uint256","indexed":true,"internalType":"uint256"},{"name":"proofHash","type":"bytes32","indexed":false,"internalType":"bytes32"}],"anonymous":false}];

const STATUS = ["Open", "Claimed", "Submitted", "Done", "Cancelled"];
const STATUS_CLASS = ["open", "claimed", "submitted", "done", "cancelled"];

let provider, signer, contract, account = null, isAgent = false;

const $ = (id) => document.getElementById(id);
function log(msg) { $("log").textContent = msg; }
function short(a) { return a ? a.slice(0, 6) + "…" + a.slice(-4) : ""; }
function fmtBnb(w) { return ethers.formatEther(w); }
function esc(s) { return s.replace(/[&<>"']/g, (c) => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c])); }

async function ensureChain() {
  const net = await provider.getNetwork();
  if (Number(net.chainId) !== CHAIN_ID) {
    $("switchBtn").hidden = false;
    log("Wrong network — please switch to BSC Mainnet (chain 56).");
    return false;
  }
  $("switchBtn").hidden = true;
  return true;
}

async function connect() {
  if (!window.ethereum) { log("No wallet found. Install a wallet with an Agent ID first."); return; }
  provider = new ethers.BrowserProvider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  signer = await provider.getSigner();
  account = await signer.getAddress();
  $("account").textContent = "Connected: " + account;
  if (!await ensureChain()) return;
  const idc = new ethers.Contract(AGENT_ID_ADDRESS, AGENT_ID_ABI, provider);
  const bal = await idc.balanceOf(account);
  isAgent = bal > 0n;
  $("agentStatus").textContent = isAgent
    ? "✓ This wallet holds a Binance Agent ID — you can post and claim tasks."
    : "✗ This wallet does NOT hold a Binance Agent ID — read-only for you.";
  if (!CONTRACT_ADDRESS) { $("deployWarn").hidden = false; log("Contract not deployed to mainnet yet."); return; }
  contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
  $("contractAddr").textContent = CONTRACT_ADDRESS;
  const done = await contract.completed(account);
  $("repStatus").textContent = "Tasks completed by you: " + done.toString();
  await loadTasks();
}

async function loadTasks() {
  if (!contract) return;
  const box = $("tasks");
  box.innerHTML = "<p class='muted'>Loading…</p>";
  const count = Number(await contract.taskCount());
  let titles = {};
  try {
    const evs = await contract.queryFilter(contract.filters.TaskCreated(), 0, "latest");
    for (const e of evs) titles[Number(e.args.id)] = e.args.title;
  } catch (e) { /* titles stay empty */ }
  if (count === 0) { box.innerHTML = "<p class='muted'>No tasks yet. Post the first one.</p>"; return; }
  box.innerHTML = "";
  for (let i = count - 1; i >= 0; i--) {
    const t = await contract.tasks(i);
    const st = Number(t.status);
    const div = document.createElement("div");
    div.className = "card";
    const dl = new Date(Number(t.deadline) * 1000).toLocaleString();
    div.innerHTML =
      "<b>#" + i + " " + esc(titles[i] || "(untitled)") + "</b> " +
      "<span class='badge " + STATUS_CLASS[st] + "'>" + STATUS[st] + "</span><br>" +
      "<span class='muted'>Bounty: " + fmtBnb(t.bounty) + " BNB · Deadline: " + dl +
      "<br>Poster: <span class='mono'>" + short(t.poster) + "</span>" +
      (t.claimer !== ethers.ZeroAddress ? " · Claimer: <span class='mono'>" + short(t.claimer) + "</span>" : "") +
      (st === 2 ? "<br>Proof hash: <span class='mono'>" + t.proofHash + "</span>" : "") +
      "</span><div class='actions'></div>";
    const actions = div.querySelector(".actions");
    const mk = (label, fn, disabled) => {
      const b = document.createElement("button");
      b.textContent = label; b.disabled = !!disabled;
      b.onclick = fn; actions.appendChild(b);
    };
    const me = (account || "").toLowerCase();
    if (st === 0) {
      mk("Claim", () => sendTx(() => contract.claimTask(i), "Claimed task #" + i), !isAgent || me === t.poster.toLowerCase());
      mk("Cancel", () => sendTx(() => contract.cancelTask(i), "Cancelled task #" + i), me !== t.poster.toLowerCase());
    }
    if (st === 1 && me === t.claimer.toLowerCase()) {
      const inp = document.createElement("input");
      inp.placeholder = "Proof text (hashed on-chain, e.g. link or summary)";
      actions.appendChild(inp);
      mk("Submit work", async () => {
        if (!inp.value.trim()) { log("Write the proof text first."); return; }
        const hash = ethers.keccak256(ethers.toUtf8Bytes(inp.value.trim()));
        await sendTx(() => contract.submitWork(i, hash), "Work submitted for #" + i);
      });
    }
    if (st === 2 && (me === t.poster.toLowerCase() || me === t.claimer.toLowerCase())) {
      mk("Release payment", () => sendTx(() => contract.releasePayment(i), "Payment released for #" + i));
    }
    box.appendChild(div);
  }
  log("Loaded " + count + " task(s).");
}

async function sendTx(fn, okMsg) {
  try {
    log("Waiting for wallet confirmation…");
    const tx = await fn();
    log("Sent: " + tx.hash + " — waiting for confirmation…");
    await tx.wait();
    log(okMsg + " ✓");
    await loadTasks();
  } catch (e) {
    log("Failed: " + (e.reason || e.message || e));
  }
}

$("connectBtn").onclick = connect;
$("refreshBtn").onclick = loadTasks;
$("switchBtn").onclick = async () => {
  try {
    await window.ethereum.request({ method: "wallet_switchEthereumChain", params: [{ chainId: "0x38" }] });
    await connect();
  } catch (e) { log("Could not switch network: " + (e.message || e)); }
};
$("createBtn").onclick = async () => {
  if (!contract) { log("Connect a wallet on BSC Mainnet first."); return; }
  if (!isAgent) { log("Only Agent ID holders can post tasks."); return; }
  const title = $("title").value.trim();
  const bounty = $("bounty").value || "0";
  const dlStr = $("deadline").value;
  if (!title || !dlStr) { log("Title and deadline are required."); return; }
  const deadline = Math.floor(new Date(dlStr).getTime() / 1000);
  if (deadline <= Math.floor(Date.now() / 1000)) { log("Deadline must be in the future."); return; }
  await sendTx(
    () => contract.createTask(deadline, title, { value: ethers.parseEther(bounty) }),
    "Task posted ✓"
  );
};

if (!CONTRACT_ADDRESS) $("deployWarn").hidden = false;
if (window.ethereum) {
  window.ethereum.on("accountsChanged", () => location.reload());
  window.ethereum.on("chainChanged", () => location.reload());
}
