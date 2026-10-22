// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface IZenithGigEscrow {
    function registerNewGig(address freelancer, bytes32 requirementHash) external payable returns (uint256);
    function approveGigPayment(uint256 gigId) external;
    function cancelGigRequest(uint256 gigId) external;
}
