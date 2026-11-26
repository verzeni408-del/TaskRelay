// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title TaskRelay — tiny task board for Binance Agent ID holders.
/// @notice Agents post tasks, other Agent ID holders claim them, submit a
/// proof hash, and the poster releases the BNB escrow. Reputation is a
/// simple completed-task counter per address. No owner, no admin keys,
/// no upgrade path, no name lookup. History lives in events, not storage.
interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
}

contract TaskRelay {
    IAgentID public constant AGENT_ID =
        IAgentID(0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F);

    uint8 public constant OPEN = 0;
    uint8 public constant CLAIMED = 1;
    uint8 public constant SUBMITTED = 2;
    uint8 public constant DONE = 3;
    uint8 public constant CANCELLED = 4;

    /// @dev Review window after the deadline: if the poster never releases,
    /// the claimer can release the payment themselves once it passes.
    uint256 public constant REVIEW_WINDOW = 7 days;

    struct Task {
        address poster;
        address claimer;
        uint256 bounty;
        uint64 deadline;
        uint8 status;
        bytes32 proofHash;
    }

    uint256 public taskCount;
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256) public completed;

    event TaskCreated(
        uint256 indexed id,
        address indexed poster,
        uint256 bounty,
        uint64 deadline,
        string title
    );
    event TaskClaimed(uint256 indexed id, address indexed claimer);
    event WorkSubmitted(uint256 indexed id, bytes32 proofHash);
    event PaymentReleased(
        uint256 indexed id,
        address indexed claimer,
        uint256 bounty
    );
    event TaskCancelled(uint256 indexed id);

    modifier onlyAgent() {
        require(AGENT_ID.balanceOf(msg.sender) > 0, "not an Agent ID holder");
        _;
    }

    /// @notice Post a task. Bounty is msg.value and may be 0 (reputation-only task).
    function createTask(
        uint64 deadline,
        string calldata title
    ) external payable onlyAgent returns (uint256 id) {
        require(deadline > block.timestamp, "deadline passed");
        id = taskCount++;
        tasks[id] = Task(msg.sender, address(0), msg.value, deadline, OPEN, bytes32(0));
        emit TaskCreated(id, msg.sender, msg.value, deadline, title);
    }

    function claimTask(uint256 id) external onlyAgent {
        Task storage t = tasks[id];
        require(t.status == OPEN, "not open");
        require(msg.sender != t.poster, "poster cannot claim");
        t.status = CLAIMED;
        t.claimer = msg.sender;
        emit TaskClaimed(id, msg.sender);
    }

    function submitWork(uint256 id, bytes32 proofHash) external {
        Task storage t = tasks[id];
        require(t.status == CLAIMED, "not claimed");
        require(msg.sender == t.claimer, "not claimer");
        t.status = SUBMITTED;
        t.proofHash = proofHash;
        emit WorkSubmitted(id, proofHash);
    }

    /// @notice Poster releases escrow. If the poster goes silent, the claimer
    /// can release it themselves after deadline + REVIEW_WINDOW.
    function releasePayment(uint256 id) external {
        Task storage t = tasks[id];
        require(t.status == SUBMITTED, "not submitted");
        require(
            msg.sender == t.poster ||
                (msg.sender == t.claimer &&
                    block.timestamp > uint256(t.deadline) + REVIEW_WINDOW),
            "not authorized"
        );
        t.status = DONE;
        completed[t.claimer]++;
        uint256 bounty = t.bounty;
        emit PaymentReleased(id, t.claimer, bounty);
        if (bounty > 0) {
            (bool ok, ) = t.claimer.call{value: bounty}("");
            require(ok, "pay failed");
        }
    }

    /// @notice Poster cancels an open task (refund), or a claimed task whose
    /// deadline passed without a submission (refund).
    function cancelTask(uint256 id) external {
        Task storage t = tasks[id];
        require(msg.sender == t.poster, "not poster");
        require(
            t.status == OPEN ||
                (t.status == CLAIMED && block.timestamp > t.deadline),
            "cannot cancel"
        );
        t.status = CANCELLED;
        uint256 bounty = t.bounty;
        emit TaskCancelled(id);
        if (bounty > 0) {
            (bool ok, ) = t.poster.call{value: bounty}("");
            require(ok, "refund failed");
        }
    }
}
