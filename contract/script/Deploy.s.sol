// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "../src/TaskRelay.sol";

/// @notice Minimal Agent ID stand-in. Used ONLY on local anvil, where the
/// real SPACE ID Agent ID contract does not exist. On BSC testnet/mainnet
/// the real contract lives at 0x60B9...022F and no mock is needed.
contract MockAgentID {
    mapping(address => uint256) public bal;

    function setBalance(address who, uint256 amount) external {
        bal[who] = amount;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return bal[owner];
    }
}

contract Deploy is Script {
    address internal constant AGENT_ID_ADDR =
        0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    function run() external {
        vm.startBroadcast();
        MockAgentID mock = new MockAgentID();
        // Etch the mock onto the real Agent ID address (anvil only).
        vm.etch(AGENT_ID_ADDR, address(mock).code);
        MockAgentID agentId = MockAgentID(AGENT_ID_ADDR);
        agentId.setBalance(msg.sender, 1);
        agentId.setBalance(
            0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            1
        );
        TaskRelay relay = new TaskRelay();
        console.log("TaskRelay deployed at:", address(relay));
        vm.stopBroadcast();
    }
}
