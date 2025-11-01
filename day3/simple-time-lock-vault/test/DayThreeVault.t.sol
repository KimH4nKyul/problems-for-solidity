// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {DayThreeVault} from "../src/DayThreeVault.sol";

contract DayThreeVaultTest is Test {
    DayThreeVault sut;

    function setUp() public {
        sut = new DayThreeVault();
    }

    function test_() public {}
}
