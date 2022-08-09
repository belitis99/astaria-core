pragma solidity ^0.8.13;

import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {ILienToken} from "./ILienToken.sol";
import {ICollateralVault} from "./ICollateralVault.sol";
import {ITransferProxy} from "./ITransferProxy.sol";

interface IBrokerRouter {
    struct Terms {
        address broker;
        address token;
        bytes32[] proof;
        uint256 collateralVault;
        uint256 maxAmount;
        uint256 maxDebt;
        uint256 rate;
        uint256 maxRate;
        uint256 duration;
        uint256 schedule;
    }

    struct Commitment {
        address tokenContract;
        uint256 tokenId;
        bytes32[] depositProof;
        ILienToken.LienActionEncumber action;
    }

    struct BrokerParams {
        address appraiser;
        bytes32 root;
        uint256 expiration;
        uint256 deadline;
        uint256 buyout;
        bytes32 contentHash;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct RefinanceCheckParams {
        uint256 position;
        Terms incoming;
    }

    struct BorrowAndBuyParams {
        ILienToken.LienActionEncumber[] commitments;
        address invoker;
        uint256 purchasePrice;
        bytes purchaseData;
        address receiver;
    }

    struct BondVault {
        address appraiser; // address of the appraiser for the BondVault
        uint256 expiration; // expiration for lenders to add assets and expiration when borrowers cannot create new borrows
        address broker; //cloned proxy
    }

    function newBondVault(BrokerParams memory params) external;

    function feeTo() external returns (address);

    function encodeBondVaultHash(
        address appraiser,
        bytes32 root,
        uint256 expiration,
        uint256 appraiserNonce,
        uint256 deadline,
        uint256 buyout
    )
        external
        view
        returns (bytes memory);

    function commitToLoans(Commitment[] calldata commitments)
        external
        returns (uint256 totalBorrowed);

    function requestLienPosition(ILienToken.LienActionEncumber calldata params)
        external
        returns (uint256 lienId);

    function LIEN_TOKEN() external returns (ILienToken);

    function TRANSFER_PROXY() external returns (ITransferProxy);

    function COLLATERAL_VAULT() external returns (ICollateralVault);

    function getAppraiserFee() external view returns (uint256, uint256);

    function lendToVault(bytes32 bondVault, uint256 amount) external;

    function getBroker(bytes32 bondVault) external view returns (address);

    function liquidate(uint256 collateralVault, uint256 position)
        external
        returns (uint256 reserve);

    function canLiquidate(uint256 collateralVault, uint256 position)
        external
        view
        returns (bool);

    function isValidRefinance(RefinanceCheckParams memory params)
        external
        view
        returns (bool);

    event Liquidation(
        uint256 collateralVault, uint256 position, uint256 reserve
    );
    event NewBondVault(
        address appraiser,
        address broker,
        bytes32 bondVault,
        bytes32 contentHash,
        uint256 expiration
    );

    error InvalidAddress(address);
    error InvalidRefinanceRate(uint256);
    error InvalidRefinanceDuration(uint256);
}
