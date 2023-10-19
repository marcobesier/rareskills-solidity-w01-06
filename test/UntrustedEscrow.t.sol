// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {UntrustedEscrow} from "../src/UntrustedEscrow.sol";

contract UntrustedEscrowTest is Test {
    UntrustedEscrow public untrustedEscrowDAI;
    address public buyer;
    address public constant DAI_ADDRESS = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    event BuyerDeposit(address indexed buyer, uint256 amount, uint256 time);
    event SellerWithdraw(address indexed buyer, uint256 amount, uint256 time);

    function setUp() public {
        buyer = address(0x123);
        untrustedEscrowDAI = new UntrustedEscrow(DAI_ADDRESS, 10**18);
    }
}
