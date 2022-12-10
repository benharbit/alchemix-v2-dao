// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "src/interfaces/IBribe.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "src/interfaces/IVoter.sol";
import "src/interfaces/IVotingEscrow.sol";
import "src/BaseGauge.sol";

/// @title Passthrough Gauge
/// @notice Generic Gauge to handle distribution of rewards without pool specific passthrough logic
/// @dev If custom distribution logic is necessary create additional contract
abstract contract PassthroughGauge is BaseGauge {
    address public receiver;

    event Passthrough(address indexed from, address token, uint256 amount, address receiver);

    function updateReceiver(address _receiver) external {
        require(msg.sender == admin, "not admin");
        receiver = _receiver;
    }

    /// @notice Pass rewards to pool
    /// @param _amount Amount of rewards
    function passthroughRewards(uint256 _amount) public virtual {
        require(_amount > 0, "insufficient amount");
        require(msg.sender == voter, "not voter");

        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        require(rewardBalance >= _amount, "insufficient rewards");

        _updateRewardForAllTokens();

        _safeTransfer(rewardToken, receiver, _amount);

        emit Passthrough(msg.sender, rewardToken, _amount, receiver);
    }

    function notifyRewardAmount(address token, uint256 _amount) external override lock {
        require(_amount > 0, "insufficient amount");
        if (!isReward[token]) {
            require(rewards.length < MAX_REWARD_TOKENS, "too many rewards tokens");
        }
        // rewards accrue only during the bribe period
        uint256 bribeStart = block.timestamp - (block.timestamp % (7 days)) + BRIBE_LAG;
        uint256 adjustedTstamp = block.timestamp < bribeStart ? bribeStart : bribeStart + 7 days;
        if (rewardRate[token] == 0) _writeRewardPerTokenCheckpoint(token, 0, adjustedTstamp);
        (rewardPerTokenStored[token], lastUpdateTime[token]) = _updateRewardPerToken(token);

        if (block.timestamp >= periodFinish[token]) {
            _safeTransferFrom(token, msg.sender, address(this), _amount);
            rewardRate[token] = _amount / DURATION;
        } else {
            uint256 _remaining = periodFinish[token] - block.timestamp;
            uint256 _left = _remaining * rewardRate[token];
            require(_amount > _left);
            _safeTransferFrom(token, msg.sender, address(this), _amount);
            rewardRate[token] = (_amount + _left) / DURATION;
        }
        require(rewardRate[token] > 0);
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(rewardRate[token] <= balance / DURATION, "Provided reward too high");
        periodFinish[token] = adjustedTstamp + DURATION;
        if (!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
            IBribe(bribe).addRewardToken(token);
        }

        emit NotifyReward(msg.sender, token, _amount);

        passthroughRewards(_amount);
    }
}
