pragma solidity 0.8.19;

import {TestSuite} from "@test/TestSuite.t.sol";
import {TimelockProposalMock} from "@mocks/TimelockProposalMock.sol";
import "@forge-std/Test.sol";

contract TimelockProposalTest is Test {
    string public constant ADDRESSES_PATH = "./addresses/Addresses.json";
    TestSuite public proposals;
    uint256 public preProposalsSnapshot;
    uint256 public postProposalsSnapshot;

    function setUp() public {
        TimelockProposalMock timelockProposal = new TimelockProposalMock();

        address[] memory proposalsAddresses = new address[](1);
        proposalsAddresses[0] = address(timelockProposal);
        proposals = new TestSuite(ADDRESSES_PATH, proposalsAddresses);
    }

    function test_runPoposals() public virtual {
        preProposalsSnapshot = vm.snapshot();

        proposals.setDebug(true);
        proposals.testProposals();

        postProposalsSnapshot = vm.snapshot();
    }
}
