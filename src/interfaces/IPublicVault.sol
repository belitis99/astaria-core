// SPDX-License-Identifier: BUSL-1.1

/**
 *  █████╗ ███████╗████████╗ █████╗ ██████╗ ██╗ █████╗
 * ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║██╔══██╗
 * ███████║███████╗   ██║   ███████║██████╔╝██║███████║
 * ██╔══██║╚════██║   ██║   ██╔══██║██╔══██╗██║██╔══██║
 * ██║  ██║███████║   ██║   ██║  ██║██║  ██║██║██║  ██║
 * ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
 *
 * Astaria Labs, Inc
 */

pragma solidity =0.8.17;

import {IERC165} from "core/interfaces/IERC165.sol";
import {IVaultImplementation} from "core/interfaces/IVaultImplementation.sol";
import {ILienToken} from "core/interfaces/ILienToken.sol";
import {IAstariaVaultBase} from "core/interfaces/IAstariaVaultBase.sol";
import {IWithdrawProxy} from "src/interfaces/IWithdrawProxy.sol";

interface IPublicVault is IVaultImplementation {
  struct EpochData {
    uint64 liensOpenForEpoch;
    address withdrawProxy;
  }

  struct VaultData {
    uint256 yIntercept;
    uint256 slope;
    uint40 last;
    uint64 currentEpoch;
    uint256 withdrawReserve;
    uint256 liquidationWithdrawRatio;
    uint256 strategistUnclaimedShares;
    mapping(uint64 => EpochData) epochData;
  }

  struct UpdateVaultParams {
    uint256 decreaseInSlope;
    uint256 interestPaid;
    uint256 decreaseInYIntercept;
    uint64 lienEnd;
  }

  struct AfterLiquidationParams {
    uint256 lienSlope;
    uint40 lienEnd;
  }

  /**
   * @notice Signal a withdrawal of funds (redeeming for underlying asset) in an arbitrary future epoch.
   * @param shares The number of VaultToken shares to redeem.
   * @param receiver The receiver of the WithdrawTokens (and eventual underlying asset)
   * @param owner The owner of the VaultTokens.
   * @param epoch The epoch to withdraw for.
   * @return assets The amount of the underlying asset redeemed.
   */
  function redeemFutureEpoch(
    uint256 shares,
    address receiver,
    address owner,
    uint64 epoch
  ) external returns (uint256 assets);

  /**
   * @notice Hook to update the slope and yIntercept of the PublicVault on payment.
   * The rate for the LienToken is subtracted from the total slope of the PublicVault, and recalculated in afterPayment().
   * @param params The params to adjust things
   */
  function updateVault(UpdateVaultParams calldata params) external;

  function getSlope() external view returns (uint256);

  function getWithdrawReserve() external view returns (uint256);

  function getLiquidationWithdrawRatio() external view returns (uint256);

  function getYIntercept() external view returns (uint256);

  /** @notice
   * hook to modify the liens open for then given epoch
   * @param epoch epoch to decrease liens of
   */
  function decreaseEpochLienCount(uint64 epoch) external;

  /** @notice
   * helper to return the LienEpoch for a given end date
   * @param end time to compute the end for
   */
  function getLienEpoch(uint64 end) external view returns (uint64);

  function getWithdrawProxy(
    uint64 epoch
  ) external view returns (IWithdrawProxy);

  /**
   * @notice Mints earned fees by the strategist to the strategist address.
   */
  function claim() external;

  /**
   * @return Seconds until the current epoch ends.
   */
  function timeToEpochEnd() external view returns (uint256);

  function epochEndTimestamp(uint epoch) external pure returns (uint256);

  /**
   * @notice Transfers funds from the PublicVault to the WithdrawProxy.
   */
  function transferWithdrawReserve() external;

  /**
   * @notice Rotate epoch boundary. This must be called before the next epoch can begin.
   */
  function processEpoch() external;

  /**
   * @notice Increase the PublicVault yIntercept.
   * @param amount newYIntercept The increase in yIntercept.
   */
  function increaseYIntercept(uint256 amount) external;

  /**
   * @notice Decrease the PublicVault yIntercept.
   * @param amount newYIntercept The decrease in yIntercept.
   */
  function decreaseYIntercept(uint256 amount) external;

  /** @notice
   * return the current epoch
   */
  function getCurrentEpoch() external view returns (uint64);

  function stopLien(
    uint256 auctionWindow,
    uint256 lienSlope,
    uint64 lienEnd,
    uint256 tokenId,
    uint256 owed
  ) external;

  function getPublicVaultState()
    external
    view
    returns (uint256, uint256, uint40, uint64, uint256, uint256, uint256);

  function getEpochData(uint64 epoch) external view returns (uint, address);

  // ERRORS

  error InvalidState(InvalidStates);

  enum InvalidStates {
    EPOCH_TOO_LOW,
    EPOCH_TOO_HIGH,
    EPOCH_NOT_OVER,
    WITHDRAW_RESERVE_NOT_ZERO,
    LIENS_OPEN_FOR_EPOCH_NOT_ZERO,
    LIQUIDATION_ACCOUNTANT_FINAL_AUCTION_OPEN,
    LIQUIDATION_ACCOUNTANT_ALREADY_DEPLOYED_FOR_EPOCH,
    DEPOSIT_CAP_EXCEEDED
  }

  event StrategistFee(uint256 feeInShares);
  event LiensOpenForEpochRemaining(uint64 epoch, uint256 liensOpenForEpoch);
  event YInterceptChanged(uint256 newYintercept);
  event WithdrawReserveTransferred(uint256 amount);
  event WithdrawProxyDeployed(uint256 epoch, address withdrawProxy);
  event LienOpen(uint256 lienId, uint256 epoch);
  event SlopeUpdated(uint256 newSlope);
}
