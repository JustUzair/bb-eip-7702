// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {BatchCallAndSponsor} from "../src/BatchCallAndSponsor.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract BatchCallAndSponsorScript is Script {
    // Alice's address and private key (EOA with no initial contract code).
    uint256 ALICE_PK = vm.envUint("ALICE_PK");
    address payable ALICE_ADDRESS = payable(vm.addr(ALICE_PK));

    // Bob's address and private key (Bob will execute transactions on Alice's behalf).
    uint256 BOB_PK = vm.envUint("BOB_PK");
    address payable BOB_ADDRESS = payable(vm.addr(BOB_PK));

    address random_receiver = 0xD0F580942a9B3B52FE003348233F2dD859eb1b12;

    // The contract that Alice will delegate execution to.
    BatchCallAndSponsor public implementation;

    // ERC-20 token contract for minting test tokens.
    MockERC20 public token;

    function run() external {
        console.log("Alice's Address:", ALICE_ADDRESS); // 0x1E594012762B6AA8515e0B0d0de3Df2DAbA4C776
        console.log("Bob's Address:", BOB_ADDRESS); // 0x92F860dfF64E71025d9e8d798Aff126463e2F618
        // Start broadcasting transactions with Alice's private key.
        vm.startBroadcast(ALICE_PK);

        // Deploy the delegation contract (Alice will delegate calls to this contract).
        implementation = new BatchCallAndSponsor();

        // Deploy an ERC-20 token contract where Alice is the minter.
        token = new MockERC20();

        token.mint(ALICE_ADDRESS, 1000e18);

        vm.stopBroadcast();

        // Perform direct execution
        performDirectExecution();

        // Perform sponsored execution
        performSponsoredExecution();
    }

    // Send 1 ETH as well as 100 Mock Tokens to Bob's address.
    function performDirectExecution() internal {
        BatchCallAndSponsor.Call[] memory calls = new BatchCallAndSponsor.Call[](2);

        // ETH transfer
        calls[0] = BatchCallAndSponsor.Call({to: BOB_ADDRESS, value: 1 ether, data: ""});

        // Token transfer
        calls[1] = BatchCallAndSponsor.Call({
            to: address(token),
            value: 0,
            data: abi.encodeCall(ERC20.transfer, (BOB_ADDRESS, 100e18))
        });

        vm.startBroadcast(ALICE_ADDRESS);
        vm.signAndAttachDelegation(address(implementation), ALICE_PK);
        BatchCallAndSponsor(ALICE_ADDRESS).execute(calls);
        vm.stopBroadcast();

        console.log("Bob's balance after direct execution:", BOB_ADDRESS.balance);
        console.log("Bob's token balance after direct execution:", token.balanceOf(BOB_ADDRESS));
    }

    function performSponsoredExecution() internal {
        console.log("Sending 1 ETH from Alice to a random address, the transaction is sponsored by Bob");

        BatchCallAndSponsor.Call[] memory calls = new BatchCallAndSponsor.Call[](1);
        calls[0] = BatchCallAndSponsor.Call({to: random_receiver, value: 1 ether, data: ""});

        vm.startBroadcast(ALICE_PK);
        // Alice signs a delegation allowing `implementation` to execute transactions on her behalf.
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), ALICE_PK);
        vm.attachDelegation(signedDelegation);
        vm.stopBroadcast();
        // Bob attaches the signed delegation from Alice and broadcasts it.
        vm.startBroadcast(BOB_PK);
        // Verify that Alice's account now temporarily behaves as a smart contract.
        bytes memory code = address(ALICE_ADDRESS).code;
        require(code.length > 0, "no code written to Alice");
        console.log("Code on Alice's account:", vm.toString(code));

        bytes memory encodedCalls = "";
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }
        bytes32 digest = keccak256(abi.encodePacked(BatchCallAndSponsor(ALICE_ADDRESS).nonce(), encodedCalls));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        // As Bob, execute the transaction via Alice's temporarily assigned contract.
        BatchCallAndSponsor(ALICE_ADDRESS).execute(calls, signature);

        vm.stopBroadcast();

        console.log("Recipient balance after sponsored execution:", random_receiver);
    }
}
