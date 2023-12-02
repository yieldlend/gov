// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//            /$$           /$$       /$$
//           |__/          | $$      | $$
//  /$$   /$$ /$$  /$$$$$$ | $$  /$$$$$$$
// | $$  | $$| $$ /$$__  $$| $$ /$$__  $$
// | $$  | $$| $$| $$$$$$$$| $$| $$  | $$
// | $$  | $$| $$| $$_____/| $$| $$  | $$
// |  $$$$$$$| $$|  $$$$$$$| $$|  $$$$$$$
//  \____  $$|__/ \_______/|__/ \_______/
//  /$$  | $$
// |  $$$$$$/
//  \______/
//
// Website: https://yieldlend.xyz
// Telegram: https://t.me/yieldlend
// Twitter: https://twitter.com/yieldlend

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VestedYieldLend is ERC20, ERC20Burnable, Ownable {
    mapping(address => bool) public fromWhitelist;
    mapping(address => bool) public toBlacklist;
    bool public enableFromWhitelist;
    bool public enableToBlacklist;

    constructor() ERC20("Vested Yield Lend", "vYERN") {
        fromWhitelist[msg.sender] = true;
        fromWhitelist[address(this)] = true;
        fromWhitelist[address(0)] = true;

        enableFromWhitelist = true;
        enableToBlacklist = false;

        _mint(msg.sender, 100_000_000_000 ether);
    }

    function addToBlacklist(address who, bool what) external onlyOwner {
        toBlacklist[who] = what;
    }

    function addFromWhitelist(address who, bool what) external onlyOwner {
        fromWhitelist[who] = what;
    }

    function toggleWhitelist(bool from, bool to) external onlyOwner {
        enableFromWhitelist = from;
        enableToBlacklist = to;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        if (enableFromWhitelist) {
            require(fromWhitelist[from], "from address not in whitelist");
        }

        if (enableToBlacklist) {
            require(!toBlacklist[to], "to address not in whitelist");
        }
    }
}
