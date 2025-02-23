pragma solidity ^0.8.0;

import {Addresses} from "@addresses/Addresses.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import {Test} from "@forge-std/Test.sol";
import "@forge-std/console.sol";

contract TypeChecker is Test {
    using Strings for string;

    Addresses public addresses;

    bytes constant IPFS = hex"69706673";

    bytes constant SOLC = hex"736f6c63";

    struct SavedTypeCheckAddresses {
        /// Artifact path
        string artifactPath;
        /// Constructor argument for the contract to be checked
        string constructorArgs;
        /// name of contract to store
        string name;
    }

    constructor(
        string memory addressesPath,
        string memory typeCheckAddressesPath,
        string memory libPath
    ) {
        addresses = new Addresses(addressesPath);

        string memory addressesData = string(
            abi.encodePacked(vm.readFile(typeCheckAddressesPath))
        );

        bytes memory parsedJson = vm.parseJson(addressesData);

        SavedTypeCheckAddresses[] memory savedTypeCheckAddresses = abi.decode(
            parsedJson,
            (SavedTypeCheckAddresses[])
        );

        for (uint256 i = 0; i < savedTypeCheckAddresses.length; i++) {
            string[] memory commands = new string[](5);

            /// note to future self, ffi absolutely flips out if you try to set env vars
            commands[0] = "npx";
            commands[1] = "ts-node";
            commands[2] = string(
                abi.encodePacked(libPath, "typescript/encode.ts")
            );
            commands[3] = savedTypeCheckAddresses[i].constructorArgs;
            commands[4] = savedTypeCheckAddresses[i].artifactPath;

            console.log("\nContract:", savedTypeCheckAddresses[i].name);

            bytes memory encodedConstructorArgs = vm.ffi(commands);
            console.log("Encoded contructor args :");
            emit log_bytes(encodedConstructorArgs);

            address contractAddress = deployCode(
                savedTypeCheckAddresses[i].artifactPath,
                encodedConstructorArgs
            );

            bytes memory deployedBytecode = addresses
                .getAddress(savedTypeCheckAddresses[i].name)
                .code;

            bytes memory localDeployedBytecode = contractAddress.code;

            if (
                matchPattern(localDeployedBytecode, IPFS) &&
                matchPattern(localDeployedBytecode, SOLC)
            ) {
                deployedBytecode = _removeMetadata(deployedBytecode);

                localDeployedBytecode = _removeMetadata(localDeployedBytecode);
            }

            console.log("Local deployed bytecode: ");
            emit log_bytes(localDeployedBytecode);
            console.log("Deployed bytecode: ");
            emit log_bytes(deployedBytecode);

            require(
                keccak256(deployedBytecode) == keccak256(localDeployedBytecode),
                "Deployed bytecode not matched"
            );
        }
    }

    function _removeMetadata(
        bytes memory data
    ) internal pure returns (bytes memory) {
        require(data.length >= 2, "Byte array must have at least 2 bytes");

        // Convert last two bytes to uint16
        uint16 metadataSize = uint16(uint8(data[data.length - 2])) *
            256 +
            uint16(uint8(data[data.length - 1]));

        require(
            data.length >= metadataSize,
            "Number of bytes to remove exceeds length of byte array"
        );

        // Subtracting 2 to remove last 2 bytes that stores the metadata size
        uint256 trimmedSize = data.length - metadataSize - 2;

        // Create a new byte array with the updated length
        bytes memory trimmedData = new bytes(trimmedSize);

        // Copy data except the last metadata bytes
        for (uint256 i = 0; i < trimmedSize; i++) {
            trimmedData[i] = data[i];
        }

        return trimmedData;
    }

    function matchPattern(
        bytes memory data,
        bytes memory pattern
    ) public pure returns (bool) {
        require(
            data.length >= pattern.length,
            "Data length is less than pattern length"
        );

        for (uint256 i = 0; i <= data.length - pattern.length; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < pattern.length; j++) {
                if (data[i + j] != pattern[j]) {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch) {
                return true;
            }
        }
        return false;
    }
}
