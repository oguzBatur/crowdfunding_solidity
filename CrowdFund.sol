// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";

contract CrowdFund {
    // Launch event, indicates that a new event is launched.
    event Launch(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );

    event Cancel(uint id);
    event Claim(uint id);

    event Pledged(uint indexed id, address indexed pledger, uint amount);
    event Unpledged(uint indexed id, address indexed pledger, uint amount);
    event Refund(uint indexed id, address indexed caller, uint amount);

    struct Campaign {
        address creator;
        uint goal;
        uint32 startAt;
        uint32 endAt;
        bool isClaimed;
        uint amountPledged;
    }

    IERC20 public immutable token;
    uint public count;
    mapping(uint => Campaign) public campaings;

    //      Campaign id     CallAddr   Amount
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    // Launches a new campaing with the given goal, start date and end date.
    function launchCampaign(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        // Start date must make sense.
        require(
            _startAt >= block.timestamp,
            "Start date must be ahead of the current time."
        );

        // End Date can't be equal or greater than the start date
        require(
            _endAt >= _startAt,
            "End Date can't be equal or less than the start date"
        );
        require(
            _endAt <= block.timestamp + 90 days,
            "End date must be mininum 90 days ahead of the start date."
        );
        count += 1;

        campaings[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            startAt: _startAt,
            endAt: _endAt,
            isClaimed: false,
            amountPledged: 0
        });

        emit Launch(count, msg.sender, goal, _startAt, _endAt);
    }

    function cancel(uint _id) external {
        Campaign memory campaign = campaings[_id];
        require(
            msg.sender = campaign.creator,
            "Only the campaign creator can cancel this event."
        );
        require(
            block.timestamp < campaign.startAt,
            "Campaign already started."
        );

        delete campaigns[_id];
        emit Cancel(_id);
    }

    // Pledge money to campaign
    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaings[_id];
        require(
            block.timestamp >= campaign.startAt,
            "Campaign not started yet."
        );
        require(block.timestamp <= campaign.endAt, "Campaign has ended.");
        campaign.amountPledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaings[_id];
        require(block.timestamp <= campaign.endAt, "Campaign has ended.");
        campaign.amountPledged -= amount;
        pledgedAmount[_id][msg.sender] -= amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

    // Claim the tokens pledged if the goal is reached.
    function claim(uint _id) external {
        Campaign storage campaign = campaings[_id];
        require(
            msg.sender == campaign.creator,
            "Only the creator can claim the pledged money."
        );
        require(
            block.timestamp > campaign.endAt,
            "Money can be claimed when the campaign is finished."
        );
        require(
            campaign.amountPledged >= campaing.goal,
            "Goal not reached, can't claim."
        );
        require(!campaign.claimed, "Money already claimed.");

        campaign.claimed = true;
        token.transfer(msg.sender, campaing.pledged);

        emit Claim(_id);
    }

    function refund(uint _id) external {
        Campaign storage campaign = campaings[_id];
        require(
            block.timestamp > campaign.endAt,
            "Campaign is not finished yet."
        );
        require(
            campaing.amountPledged < campaign.goal,
            "Goal has been reached, no refunds."
        );

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refunt(_id, msg.sender, bal);
    }
}
