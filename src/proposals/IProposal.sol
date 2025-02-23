pragma solidity ^0.8.0;

import {Addresses} from "@addresses/Addresses.sol";

interface IProposal {
    /// @notice proposal name, e.g. "BIP15"
    /// @dev override this to set the proposal name
    function name() external view returns (string memory);

    /// @notice proposal description
    /// @dev override this to set the proposal description
    function description() external view returns (string memory);

    /// @notice actually run the proposal
    /// @dev review the implementation to determine which internal functions
    /// might need overriding for you proposal
    function run() external;

    /// @notice Print proposal actions
    function getProposalActions()
        external
        returns (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory arguments
        );

    /// @notice Print proposal calldata
    function getCalldata() external returns (bytes memory data);

    /// @notice set the debug flag
    function setDebug(bool debug) external;

    function addresses() external view returns (Addresses);
}
