// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {MemoProcessor} from "../MemoProcessor.sol";

import "forge-std/console2.sol";
import {DSTest} from "ds-test/test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ve} from "../veALCX.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {Hevm} from "./utils/Hevm.sol";

interface Vm {
    function prank(address) external;
}

contract MemoProcessorTest is DSTestPlus {
    address listener = 0x000000000000000000000000000000000000dEaD;
    MemoProcessor memoProcessor;
    bytes4 testFunctionSig = 0x92d11b2d; // keccak256(receiveMemo(address))
    bytes4 failFunctionSig = 0xe49aa824; // keccak256(failMemo(address))

    address memoData;

    /// @dev Deploy the contract
    function setUp() public {
        memoProcessor = new MemoProcessor();
        memoProcessor.registerSource(address(this));
        memoProcessor.registerListener(testFunctionSig, address(this));
    }

    function receiveMemo(address _memoData) external {
        memoData = _memoData;
    }

    function failMemo(address _memoData) external {
        assert(false);
    }

    function testMemoReceived() public {
        address testAddress = 0x000000000000000000000000000000000000bEEF;
        memoProcessor.processMemo(abi.encodeWithSignature("receiveMemo(address)", testAddress));
        assertEq(testAddress, memoData);
    }

    function testFailMemoReceived() public {
        address testAddress = 0x000000000000000000000000000000000000bEEF;
        memoProcessor.registerListener(failFunctionSig, address(this));
        memoProcessor.processMemo(abi.encodeWithSignature("failMemo(address)", testAddress));
    }

    function testAddListener() public {
        address testAddress = 0x000000000000000000000000000000000000bEEF;
        memoProcessor.registerListener(testFunctionSig, testAddress);
        bool test = memoProcessor.isListener(testFunctionSig, testAddress);
        assertBoolEq(test, true);
    }

    function testRemoveListener() public {
        memoProcessor.deRegisterListener(testFunctionSig, address(this));
        bool test = memoProcessor.isListener(testFunctionSig, address(this));
        assertBoolEq(test, false);
    }

    function testGetListeners() public {
        address testAddress = 0x000000000000000000000000000000000000bEEF;
        memoProcessor.registerListener(testFunctionSig, testAddress);
        address[] memory listeners = memoProcessor.getListeners(testFunctionSig);
        uint[] memory _listeners = new uint[](listeners.length);
        for (uint256 i = 0; i < listeners.length; i++) {
            _listeners[i] = uint(uint160(listeners[i]));
        }
        uint[] memory testListeners = new uint[](2);
        testListeners[0] = uint(uint160(address(this)));
        testListeners[1] = uint(uint160(0x000000000000000000000000000000000000bEEF));
        assertUintArrayEq(_listeners, testListeners);
    }
}
