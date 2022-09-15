// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SaleIVO is ERC20,Ownable{

    IERC20 public BUSD;

    constructor(address BUSDAddress) ERC20("WEA","WEA"){
        BUSD = IERC20(BUSDAddress);
    }

    uint256 public TokenPrice = 1000000;
    uint256 private BUSDdic = 1 ether;
    uint256 private Topfloor = 300 ether;

    uint256 public SaleBalance;

    address private WithDrawAddress = 0xbe0D2aFdA95a1F082724289CcabAA375F58917FF;

    bool public SaleState = false;
    bool public WithDrawState = false;
    event IVO(address,uint256,uint256);


    mapping(address => address)public AntiCommission;
    mapping(address => uint256)private AccumulationReward;
    mapping(address => uint32)private inviteUser;
    mapping(address => uint256)private remainingReward;
    mapping(address => uint256)private BusdReward;

    mapping(address => uint256)public BuyAmount;
    mapping(address => uint256)public WithDrawAmount;

    mapping(address => bool)public SpecialBuyer;

    function setSalestate(bool state)external onlyOwner{
        SaleState = state;
    }

    function setWithDrawState(bool state)external onlyOwner{
        WithDrawState = state;
    }


    function IVOsale(uint256 UsdBalance,address master)public{
        require(SaleState,"Sale not start");
        require(UsdBalance >= 20,"Input amount can't be under 20 ");
        require(BuyAmount[msg.sender] + UsdBalance <= 300 || SpecialBuyer[msg.sender],"Over the buy balance");

        if(master == msg.sender){
            master = address(0);
        }
        uint256 BUSDVal = UsdBalance * BUSDdic;
        require(BUSD.allowance(msg.sender,address(this)) >= BUSDVal,"Allowance insufficient");
        require(BUSD.balanceOf(msg.sender) >= BUSDVal,"Not enought USDC");

        SaleBalance += BUSDVal;

        BuyAmount[msg.sender] += UsdBalance;
        BUSD.transferFrom(msg.sender, WithDrawAddress, BUSDVal);

        uint256 IVOBalance = UsdBalance * TokenPrice * 1 ether;

        WithDrawAmount[msg.sender] += IVOBalance;

        setCommission(msg.sender,master);

        L1(IVOBalance,UsdBalance);
        L2(IVOBalance,UsdBalance);

        BusdReward[msg.sender] += UsdBalance;


        emit IVO(msg.sender,UsdBalance,IVOBalance);

    }

    function WithDrawIVO() external{
        require(WithDrawState ,"Withdraw Not Start");
        require(WithDrawAmount[msg.sender] > 0,"Withdraw under 1");

        _mint(msg.sender,WithDrawAmount[msg.sender]);
        WithDrawAmount[msg.sender] = 0;
        remainingReward[msg.sender] = 0;

    }

    function mintTokentoOwner(uint256 Amount)public onlyOwner{
        require(Amount > 0,"Input amount can't be 0 ");

        uint256 IVOBalance = Amount * 1e18;

        _mint(msg.sender,IVOBalance);

    }

    function AddMoinbuyer(address[] calldata account)external onlyOwner{

        for(uint i = 0;i<account.length;i++){
            SpecialBuyer[account[i]] = true;
        }
    }


    function setCommission(address user,address master)private{

        AntiCommission[user] = master;

    }

    function L1(uint256 val,uint256 UsdBalance)private{

        if(AntiCommission[msg.sender] != address(0)){
            uint256 tokenVal = (val/100) * 5;
            address reciver = AntiCommission[msg.sender];
            WithDrawAmount[reciver] += tokenVal;
            AccumulationReward[reciver] += tokenVal;
            remainingReward[reciver] += tokenVal;
            inviteUser[reciver]++;
            BusdReward[reciver] += UsdBalance;

        }
    }

    function L2(uint256 val,uint256 UsdBalance)private{

        if(AntiCommission[AntiCommission[msg.sender]] != address(0)){
            uint256 tokenVal = (val/100) * 3;
            address reciver = AntiCommission[AntiCommission[msg.sender]];
            WithDrawAmount[reciver] += tokenVal;
            AccumulationReward[reciver] += tokenVal;
            remainingReward[reciver] += tokenVal;
            inviteUser[reciver]++;
            BusdReward[reciver] += UsdBalance;
        }
    }


    function callCommission(address mast)public view returns(address){
        return AntiCommission[mast];
    }

    function NftWhiteList(address user)public view returns(uint32){
        uint32 inviter = inviteUser[user];

        return inviter % 10;
    }

    function GounpFundsReward(address user)public view returns(uint256){
        return AccumulationReward[user];
    }

    function GounpPeopleAmmount(address user)public view returns(uint256){
        return inviteUser[user];
    }

    function RemainingReward(address user)public view returns(uint256){
        return remainingReward[user];
    }

    function RemainingBUSD(address user)public view returns(uint256){
        return BusdReward[user];
    }

}
