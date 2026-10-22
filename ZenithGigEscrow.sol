// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract ZenithGigEscrow {
    struct Gig {
        address payable client;
        address payable freelancer;
        uint256 lockedWei;
        bool isCompleted;
        bool isActive;
        bytes32 requirementHash;
    }

    address payable public immutable hubAdmin;
    string public hubDescriptor;
    uint256 public platformFeeBps; // 250 = 2.5%
    uint256 public gigCounter;
    uint256 public accumulatedFees;
    bool public isHubHalted;

    mapping(address => bool) public verifiedFreelancers;
    mapping(uint256 => Gig) public gigs;

    event FreelancerAdded(address indexed freelancer);
    event GigApprovedAndPaid(uint256 indexed gigId, address indexed freelancer, uint256 payout);
    event GigCanceled(uint256 indexed gigId, address indexed client);
    event TreasuryDeposited(address indexed funder, uint256 amount);
    event ReservesEmptied(address indexed admin, uint256 amount);
    event FeesGathered(address indexed admin, uint256 amount);
    event HubHaltToggled(bool isHalted);
    event GigRegistered(uint256 indexed gigId, address indexed client, address indexed freelancer, uint256 amount);
    event FreelancerRevoked(address indexed freelancer);
    event DescriptorUpdated(string newDescriptor);

    modifier onlyAdmin() {
        require(msg.sender == hubAdmin, "ZenithGig: Access denied");
        _;
    }

    modifier whenNotHalted() {
        require(!isHubHalted, "ZenithGig: Hub is halted");
        _;
    }

    constructor() {
        hubAdmin = payable(msg.sender);
        hubDescriptor = "Zenith Base Gig Escrow v1";
        platformFeeBps = 250; // 2.5%
        isHubHalted = false;
        verifiedFreelancers[msg.sender] = true;
    }

    // 1. addVerifiedFreelancer
    function addVerifiedFreelancer(address freelancer) external onlyAdmin {
        require(!verifiedFreelancers[freelancer], "ZenithGig: Already verified");
        verifiedFreelancers[freelancer] = true;
        emit FreelancerAdded(freelancer);
    }

    // 2. approveGigPayment
    function approveGigPayment(uint256 gigId) external whenNotHalted {
        Gig storage g = gigs[gigId];
        require(gigId > 0 && gigId <= gigCounter, "ZenithGig: Invalid ID");
        require(g.isActive && !g.isCompleted, "ZenithGig: Not active or already done");
        require(msg.sender == g.client, "ZenithGig: Only client can approve");

        g.isCompleted = true;
        g.isActive = false;

        uint256 fee = (g.lockedWei * platformFeeBps) / 10000;
        uint256 payout = g.lockedWei - fee;
        accumulatedFees += fee;

        (bool sent, ) = g.freelancer.call{value: payout}("");
        require(sent, "ZenithGig: Payout failed");

        emit GigApprovedAndPaid(gigId, g.freelancer, payout);
    }

    // 3. cancelGigRequest
    function cancelGigRequest(uint256 gigId) external {
        Gig storage g = gigs[gigId];
        require(gigId > 0 && gigId <= gigCounter, "ZenithGig: Invalid ID");
        require(g.isActive && !g.isCompleted, "ZenithGig: Cannot cancel");
        require(msg.sender == g.client || msg.sender == hubAdmin, "ZenithGig: Unauthorized");

        g.isActive = false;
        uint256 refundAmount = g.lockedWei;
        g.lockedWei = 0;

        (bool sent, ) = g.client.call{value: refundAmount}("");
        require(sent, "ZenithGig: Refund failed");

        emit GigCanceled(gigId, g.client);
    }

    // 4. depositPlatformTreasury
    function depositPlatformTreasury() external payable whenNotHalted {
        require(msg.value > 0, "ZenithGig: Zero deposit");
        accumulatedFees += msg.value;
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    // 5. emptyPlatformReserves
    function emptyPlatformReserves() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "ZenithGig: Zero balance");

        accumulatedFees = 0;
        (bool sent, ) = hubAdmin.call{value: balance}("");
        require(sent, "ZenithGig: Sweep failed");

        emit ReservesEmptied(hubAdmin, balance);
    }

    // 6. gatherPlatformFees
    function gatherPlatformFees() external onlyAdmin {
        uint256 amount = accumulatedFees;
        require(amount > 0, "ZenithGig: Zero fees");

        accumulatedFees = 0;
        (bool sent, ) = hubAdmin.call{value: amount}("");
        require(sent, "ZenithGig: Harvest failed");

        emit FeesGathered(hubAdmin, amount);
    }

    // 7. haltEscrowHub
    function haltEscrowHub(bool isHalted) external onlyAdmin {
        isHubHalted = isHalted;
        emit HubHaltToggled(isHalted);
    }

    // 8. registerNewGig
    function registerNewGig(address freelancer, bytes32 requirementHash) external payable whenNotHalted returns (uint256) {
        require(msg.value > 0, "ZenithGig: Zero payment");
        require(verifiedFreelancers[freelancer], "ZenithGig: Freelancer not verified");

        gigCounter++;
        gigs[gigCounter] = Gig({
            client: payable(msg.sender),
            freelancer: payable(freelancer),
            lockedWei: msg.value,
            isCompleted: false,
            isActive: true,
            requirementHash: requirementHash
        });

        emit GigRegistered(gigCounter, msg.sender, freelancer, msg.value);
        return gigCounter;
    }

    // 9. revokeFreelancerStatus
    function revokeFreelancerStatus(address freelancer) external onlyAdmin {
        require(verifiedFreelancers[freelancer], "ZenithGig: Not verified");
        require(freelancer != msg.sender, "ZenithGig: Cannot revoke self");
        verifiedFreelancers[freelancer] = false;
        emit FreelancerRevoked(freelancer);
    }

    // 10. updateHubDescriptor
    function updateHubDescriptor(string calldata newDescriptor) external onlyAdmin {
        require(bytes(newDescriptor).length > 0, "ZenithGig: Empty string");
        hubDescriptor = newDescriptor;
        emit DescriptorUpdated(newDescriptor);
    }
}