pragma solidity ^0.8.0;

import {Vault} from "@examples/Vault.sol";
import {MockToken} from "@examples/MockToken.sol";
import {GovernorBravoProposal} from "@proposals/GovernorBravoProposal.sol";
import {Proposal} from "@proposals/Proposal.sol";

/// @notice Mock proposal that withdraws MockToken from Vault
/// using the GovernorBravoProposal type.
contract BRAVO_04 is GovernorBravoProposal {
    string public override name = "BRAVO_04";

    string private constant ADDRESSES_PATH = "./addresses/Addresses.json";

    constructor() Proposal(ADDRESSES_PATH, "PROTOCOL_TIMELOCK") {}

    /// @notice Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "Withdraw tokens from Vault";
    }

    /// @notice Deploys a vault contract and an ERC20 token contract.
    function _deploy() internal override {
        if (!addresses.isAddressSet("TOKEN_2")) {
            MockToken token = new MockToken();
            addresses.addAddress("TOKEN_2", address(token), true);
        }
    }

    /// Sets up actions for the proposal, in this case, withdrawing MockToken into Vault.
    function _build() internal override {
        /// STATICALL -- not recorded for the run stage
        address token = addresses.getAddress("TOKEN_2");
        Vault timelockVault = Vault(addresses.getAddress("VAULT"));

        /// CALL - recorded
        timelockVault.whitelistToken(token, true);
    }

    // Executes the proposal actions.
    function _run() internal override {
        // Call parent _run function to check if there are actions to execute
        super._run();

        address governor = addresses.getAddress("PROTOCOL_GOVERNOR");
        address govToken = addresses.getAddress("PROTOCOL_GOVERNANCE_TOKEN");
        address proposer = addresses.getAddress("BRAVO_PROPOSER");

        // Simulate time passing, vault time lock is 1 week
        vm.warp(block.timestamp + 1 weeks + 1);

        _simulateActions(governor, govToken, proposer);
    }

    // Validates the post-execution state.
    function _validate() internal override {
        MockToken token = MockToken(addresses.getAddress("TOKEN_2"));
        Vault timelockVault = Vault(addresses.getAddress("VAULT"));

        assertTrue(
            timelockVault.tokenWhitelist(address(token)),
            "token not whitelisted"
        );
    }
}
