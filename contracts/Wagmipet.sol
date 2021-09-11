// SPDX-License-Identifier: Unlicense

/*
    WAGMIpet NFT, inspired by dhof.eth's wagmipet contract (mainnet:0xecb504d39723b0be0e3a9aa33d646642d1051ee1)

    By m1guelpf.eth
*/

pragma solidity ^0.8.7;

import "base64-sol/base64.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";


contract WAGMIpet is OwnableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2771ContextUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    event CaretakerLoved(address indexed caretaker, uint256 indexed amount);

    mapping (uint256 => uint256) internal _lastFeedBlock;
    mapping (uint256 => uint256) internal _lastCleanBlock;
    mapping (uint256 => uint256) internal _lastPlayBlock;
    mapping (uint256 => uint256) internal _lastSleepBlock;

    mapping (uint256 => string) internal _names;
    mapping (uint256 => uint8) internal _hunger;
    mapping (uint256 => uint8) internal _uncleanliness;
    mapping (uint256 => uint8) internal _boredom;
    mapping (uint256 => uint8) internal _sleepiness;

    mapping (address => uint256) public love;

    function initialize(address trustedForwarder) public initializer {
        __Ownable_init();
        __ERC721_init("WagmiPet", "PET");
        __ERC2771Context_init(trustedForwarder);
     }

    function adopt(string memory name) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _lastFeedBlock[newTokenId] = block.number;
        _lastCleanBlock[newTokenId] = block.number;
        _lastPlayBlock[newTokenId] = block.number;
        _lastSleepBlock[newTokenId] = block.number;
        _names[newTokenId] = name;
        _hunger[newTokenId] = 0;
        _uncleanliness[newTokenId] = 0;
        _boredom[newTokenId] = 0;
        _sleepiness[newTokenId] = 0;
        _mint(_msgSender(), newTokenId);

        return newTokenId;
    }

    function addLove(address caretaker, uint256 amount) internal {
        love[caretaker] += amount;
        emit CaretakerLoved(caretaker, amount);
    }

    function feed(uint256 tokenId) public {
        require(_exists(tokenId), "pet does not exist");
        require(ownerOf(tokenId) == _msgSender(), "not your pet");
        require(getHunger(tokenId) > 0, "i dont need to eat");
        require(getAlive(tokenId), "no longer with us");
        require(getBoredom(tokenId) < 80, "im too tired to eat");
        require(getUncleanliness(tokenId) < 80, "im feeling too gross to eat");
        require(getHunger(tokenId) > 0, "i dont need to eat");

        _lastFeedBlock[tokenId] = block.number;

        _hunger[tokenId] = 0;
        _boredom[tokenId] += 10;
        _uncleanliness[tokenId] += 3;

        addLove(_msgSender(), 1);
    }

    function clean(uint256 tokenId) public {
        require(_exists(tokenId), "pet does not exist");
        require(ownerOf(tokenId) == _msgSender(), "not your pet");
        require(getAlive(tokenId), "no longer with us");
        require(getUncleanliness(tokenId) > 0, "i dont need a bath");

        _lastCleanBlock[tokenId] = block.number;
        _uncleanliness[tokenId] = 0;

        addLove(_msgSender(), 1);
    }

    function play(uint256 tokenId) public {
        require(_exists(tokenId), "pet does not exist");
        require(ownerOf(tokenId) == _msgSender(), "not your pet");
        require(getAlive(tokenId), "no longer with us");
        require(getHunger(tokenId) < 80, "im too hungry to play");
        require(getSleepiness(tokenId) < 80, "im too sleepy to play");
        require(getUncleanliness(tokenId) < 80, "im feeling too gross to play");
        require(getBoredom(tokenId) > 0, "i dont wanna play");

        _lastPlayBlock[tokenId] = block.number;

        _boredom[tokenId] = 0;
        _hunger[tokenId] += 10;
        _sleepiness[tokenId] += 10;
        _uncleanliness[tokenId] += 5;

        addLove(_msgSender(), 1);
    }

    function sleep(uint256 tokenId) public {
        require(_exists(tokenId), "pet does not exist");
        require(ownerOf(tokenId) == _msgSender(), "not your pet");
        require(getAlive(tokenId), "no longer with us");
        require(getUncleanliness(tokenId) < 80, "im feeling too gross to sleep");
        require(getSleepiness(tokenId) > 0, "im not feeling sleepy");

        _lastSleepBlock[tokenId] = block.number;

        _sleepiness[tokenId] = 0;
        _uncleanliness[tokenId] += 5;

        addLove(_msgSender(), 1);
    }

    function getName(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "pet does not exist");

        return _names[tokenId];
    }

    function getStatus(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "pet does not exist");

        uint256 mostNeeded = 0;

        string[4] memory goodStatus = ["gm", "im feeling great", "all good", "i love u"];

        string memory status = goodStatus[block.number % 4];

        uint256 hunger = getHunger(tokenId);
        uint256 uncleanliness = getUncleanliness(tokenId);
        uint256 boredom = getBoredom(tokenId);
        uint256 sleepiness = getSleepiness(tokenId);

        if (getAlive(tokenId) == false) {
            return "no longer with us";
        }

        if (hunger > 50 && hunger > mostNeeded) {
            mostNeeded = hunger;
            status = "im hungry";
        }

        if (uncleanliness > 50 && uncleanliness > mostNeeded) {
            mostNeeded = uncleanliness;
            status = "i need a bath";
        }

        if (boredom > 50 && boredom > mostNeeded) {
            mostNeeded = boredom;
            status = "im bored";
        }

        if (sleepiness > 50 && sleepiness > mostNeeded) {
            mostNeeded = sleepiness;
            status = "im sleepy";
        }

        return status;
    }

    function getAlive(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "pet does not exist");

        return getHunger(tokenId) < 101 && getUncleanliness(tokenId) < 101 && getBoredom(tokenId) < 101 && getSleepiness(tokenId) < 101;
    }

    function getHunger(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "pet does not exist");

        return _hunger[tokenId] + ((block.number - _lastFeedBlock[tokenId]) / 400);
    }

    function getUncleanliness(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "pet does not exist");

        return _uncleanliness[tokenId] + ((block.number - _lastCleanBlock[tokenId]) / 400);
    }

    function getBoredom(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "pet does not exist");

        return _boredom[tokenId] + ((block.number - _lastPlayBlock[tokenId]) / 400);
    }

    function getSleepiness(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "pet does not exist");

        return _sleepiness[tokenId] + ((block.number - _lastSleepBlock[tokenId]) / 400);
    }

    function getStats(uint256 tokenId) public view returns (uint256[5] memory) {
        return [getAlive(tokenId) ? 1 : 0, getHunger(tokenId), getUncleanliness(tokenId), getBoredom(tokenId), getSleepiness(tokenId)];
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        require(_exists(tokenId), "pet does not exist");

        string[3] memory parts;
        // solhint-disable-next-line quotes
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        parts[1] = getStatus(tokenId);
        parts[2] = "</text></svg>";

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));

        // solhint-disable-next-line quotes
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', getName(tokenId), '", "WAGMIpets are virtual pets living on the blockchain.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        ERC721EnumerableUpgradeable._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return ERC721EnumerableUpgradeable.supportsInterface(interfaceId);
    }

    function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}
