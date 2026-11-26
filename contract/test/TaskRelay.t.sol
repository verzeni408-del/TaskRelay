// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/TaskRelay.sol";

contract MockAgentID {
    mapping(address => uint256) public bal;

    function setBalance(address who, uint256 amount) external {
        bal[who] = amount;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return bal[owner];
    }
}

contract TaskRelayTest is Test {
    TaskRelay public relay;
    MockAgentID public mockId;
    address public poster = address(0xA11CE);
    address public worker = address(0xB0B);
    address public stranger = address(0xC10);

    function setUp() public {
        mockId = new MockAgentID();
        // Point the relay at the mock by deploying at the real address slot:
        // simplest is to etch the mock bytecode onto the real Agent ID address.
        vm.etch(
            address(0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F),
            address(mockId).code
        );
        relay = new TaskRelay();
        MockAgentID agentId = MockAgentID(
            0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
        );
        agentId.setBalance(poster, 1);
        agentId.setBalance(worker, 1);
        vm.deal(poster, 10 ether);
        vm.deal(worker, 1 ether);
    }

    function testHappyPath() public {
        uint64 dl = uint64(block.timestamp + 1 days);
        vm.prank(poster);
        uint256 id = relay.createTask{value: 0.01 ether}(dl, "Review my README");
        assertEq(relay.taskCount(), 1);

        vm.prank(worker);
        relay.claimTask(id);

        bytes32 proof = keccak256("did the work");
        vm.prank(worker);
        relay.submitWork(id, proof);

        uint256 before = worker.balance;
        vm.prank(poster);
        relay.releasePayment(id);
        assertEq(worker.balance, before + 0.01 ether);
        assertEq(relay.completed(worker), 1);
        (, , , , uint8 st, ) = relay.tasks(id);
        assertEq(uint256(st), uint256(relay.DONE()));
    }

    function testZeroBountyTask() public {
        vm.prank(poster);
        uint256 id = relay.createTask{value: 0}(
            uint64(block.timestamp + 1 hours),
            "Free review"
        );
        vm.prank(worker);
        relay.claimTask(id);
        vm.prank(worker);
        relay.submitWork(id, bytes32(uint256(1)));
        vm.prank(poster);
        relay.releasePayment(id);
        assertEq(relay.completed(worker), 1);
    }

    function testNonHolderCannotCreate() public {
        vm.prank(stranger);
        vm.expectRevert("not an Agent ID holder");
        relay.createTask{value: 0}(uint64(block.timestamp + 1 hours), "x");
    }

    function testNonHolderCannotClaim() public {
        vm.prank(poster);
        uint256 id = relay.createTask{value: 0}(
            uint64(block.timestamp + 1 hours),
            "x"
        );
        vm.prank(stranger);
        vm.expectRevert("not an Agent ID holder");
        relay.claimTask(id);
    }

    function testPosterCannotClaimOwn() public {
        vm.prank(poster);
        uint256 id = relay.createTask{value: 0}(
            uint64(block.timestamp + 1 hours),
            "x"
        );
        vm.prank(poster);
        vm.expectRevert("poster cannot claim");
        relay.claimTask(id);
    }

    function testDoubleClaimReverts() public {
        vm.prank(poster);
        uint256 id = relay.createTask{value: 0}(
            uint64(block.timestamp + 1 hours),
            "x"
        );
        vm.prank(worker);
        relay.claimTask(id);
        MockAgentID agentId = MockAgentID(
            0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
        );
        agentId.setBalance(stranger, 1);
        vm.prank(stranger);
        vm.expectRevert("not open");
        relay.claimTask(id);
    }

    function testOnlyClaimerSubmits() public {
        vm.prank(poster);
        uint256 id = relay.createTask{value: 0}(
            uint64(block.timestamp + 1 hours),
            "x"
        );
        vm.prank(worker);
        relay.claimTask(id);
        vm.prank(poster);
        vm.expectRevert("not claimer");
        relay.submitWork(id, bytes32(uint256(1)));
    }

    function testCancelOpenRefunds() public {
        vm.prank(poster);
        uint256 id = relay.createTask{value: 0.05 ether}(
            uint64(block.timestamp + 1 hours),
            "x"
        );
        uint256 before = poster.balance;
        vm.prank(poster);
        relay.cancelTask(id);
        assertEq(poster.balance, before + 0.05 ether);
    }

    function testCancelClaimedBeforeDeadlineReverts() public {
        vm.prank(poster);
        uint256 id = relay.createTask{value: 0}(
            uint64(block.timestamp + 1 hours),
            "x"
        );
        vm.prank(worker);
        relay.claimTask(id);
        vm.prank(poster);
        vm.expectRevert("cannot cancel");
        relay.cancelTask(id);
    }

    function testCancelClaimedAfterDeadlineRefunds() public {
        uint64 dl = uint64(block.timestamp + 1 hours);
        vm.prank(poster);
        uint256 id = relay.createTask{value: 0.05 ether}(dl, "x");
        vm.prank(worker);
        relay.claimTask(id);
        vm.warp(dl + 1);
        uint256 before = poster.balance;
        vm.prank(poster);
        relay.cancelTask(id);
        assertEq(poster.balance, before + 0.05 ether);
    }

    function testClaimerSelfReleaseAfterReviewWindow() public {
        uint64 dl = uint64(block.timestamp + 1 hours);
        vm.prank(poster);
        uint256 id = relay.createTask{value: 0.02 ether}(dl, "x");
        vm.prank(worker);
        relay.claimTask(id);
        vm.prank(worker);
        relay.submitWork(id, bytes32(uint256(7)));
        // Poster silent: claimer cannot release yet.
        vm.prank(worker);
        vm.expectRevert("not authorized");
        relay.releasePayment(id);
        // After deadline + 7 days, claimer releases.
        vm.warp(uint256(dl) + 7 days + 1);
        uint256 before = worker.balance;
        vm.prank(worker);
        relay.releasePayment(id);
        assertEq(worker.balance, before + 0.02 ether);
        assertEq(relay.completed(worker), 1);
    }
}
