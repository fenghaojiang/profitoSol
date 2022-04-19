//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IERC20.sol";
import "./lib/SafeMath.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapRouter02.sol";
import "./lib/UniswapV2Library.sol";


contract Profito {
    using SafeMath for uint256;

    address owner;
    address immutable borrowUniswapV2PairAddr = "";
    address immutable swapOnSushiSwapRouterAddr = "";
    ISwapRouter02 immutable sushiRouter = IV2SwapRouter(swapOnSushiSwapRouterAddr);


    //modifier 
    modifier onlyOwner() {
        require(address(msg.sender) == owner, "No authority");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    receive() external payable {}

    function getOwner() public view returns(address) {
        return owner;
    }

    function getTokenBalance(address token, address account) public view returns(uint256) {
        return IERC20(token).balanceOf(account);
    }

    function withdrawProfitETH(uint256 amount) public onlyOwner {
        payable(owner).transfer(amount);
    }

    function withdrawProfitToken(address token, uint256 amount) public onlyOwner {
        IERC20(token).transfer(owner, amount);
    }

    


    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external { //for uniswap callback
      address[] memory path = new address[](2);
      uint amountToken = _amount0 == 0 ? _amount1 : _amount0; //amount1
      
      address token0 = IUniswapV2Pair(msg.sender).token0();
      address token1 = IUniswapV2Pair(msg.sender).token1();

      require(msg.sender == UniswapV2Library.pairFor(factory, token0, token1), "Unauthorized"); 
      require(_amount0 == 0 || _amount1 == 0);

      path[0] = _amount0 == 0 ? token1 : token0; //amount1
      path[1] = _amount0 == 0 ? token0 : token1; //amount0

      IERC20 token = IERC20(_amount0 == 0 ? token1 : token0); //token1
      
      token.approve(address(sushiRouter), amountToken); //amount1

      // no need for require() check, if amount required is not sent sushiRouter will revert
      uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountToken, path)[0]; //path ---> {token1, token0} 返回需要的token0个数
      uint amountReceived = sushiRouter.swapExactTokensForTokens(amountToken, amountRequired, path, msg.sender, deadline)[1]; //用token1换尽可能多的token0

      // YEAHH PROFIT
      token.transfer(_sender, amountReceived - amountRequired);
    }

    struct NotEmptyData {
        string info;
    }

    function tryProfit() public onlyOwner {
        bytes memory _data = NotEmptyData("1"); //不设置进入不了uniswap v2
        IUniswapV2Pair(borrowUniswapV2PairAddr).swap(amount0Out, amount1Out, to, abi.encode(_data));
    }

}

// contract Greeter {
//     string private greeting;

//     constructor(string memory _greeting) {
//         console.log("Deploying a Greeter with greeting:", _greeting);
//         greeting = _greeting;
//     }

//     function greet() public view returns (string memory) {
//         return greeting;
//     }

//     function setGreeting(string memory _greeting) public {
//         console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
//         greeting = _greeting;
//     }
// }


