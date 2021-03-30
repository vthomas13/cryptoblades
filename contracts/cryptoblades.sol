pragma solidity ^0.6.0;

import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "./ownable.sol";
import "./characters.sol";
import "./weapons.sol";
import "./util.sol";

contract CryptoBlades is Util {

    using ABDKMath64x64 for int256;
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for uint24;

    Characters public characters;
    Weapons public weapons;
    address public skillTokens;//0x154A9F9cbd3449AD22FDaE23044319D6eF2a1Fab;

    constructor(address tokenAddress) public /*Ownable()*/ {
        skillTokens = tokenAddress;
        characters = new Characters(address(this));
        weapons = new Weapons(address(this));
    }

    // prices when contract is at 100% load (50% of total skill)
    uint256 public mintCharacterFee = 50000 * 2;
    //uint256 public rerollTraitFee = 30000 * 2;
    //uint256 public rerollCosmeticsFee = 30000 * 2;
    uint256 public refillStaminaFee = 100000 * 2;

    uint256 public mintWeaponFee = 15000 * 2;
    uint256 public reforgeWeaponFee = 5000 * 2;

    event FightOutcome(uint256 character, uint256 weapon, uint32 target, uint24 playerRoll, uint24 enemyRoll);

    function getSkillTokensAddress() external view returns (address) {
        return skillTokens;
    }

    function getCharactersAddress() external view returns (address) {
        return address(characters);
    }

    function getWeaponsAddress() external view returns (address) {
        return address(weapons);
    }

    function getMySkill() external view returns (uint256) {
        return ERC20(skillTokens).balanceOf(msg.sender);
    }

    function giveMeSkill(uint256 amount) public {
        // TEMPORARY FUNCITON TO TEST WITH
        ERC20(skillTokens).approve(address(this), amount);
        ERC20(skillTokens).transferFrom(address(this), msg.sender, amount);
    }

    function getMyCharacters() public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](characters.balanceOf(msg.sender));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = characters.tokenOfOwnerByIndex(msg.sender, i);
        }
        return tokens;
    }

    function getMyWeapons() public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](weapons.balanceOf(msg.sender));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = weapons.tokenOfOwnerByIndex(msg.sender, i);
        }
        return tokens;
    }

    function fight(uint256 char, uint256 wep, uint32 target) external
        isCharacterOwner(char)
        isWeaponOwner(wep)
        isTargetValid(char, wep, target) {
        // avg xp gain from a fight is 9 xp

        uint24 playerRoll = getPlayerPowerRoll(char, wep, uint8((target >> 24) & 0xFF)/*monster trait*/);
        uint24 monsterRoll = getMonsterPowerRoll(getMonsterPower(target));

        if(playerRoll >= monsterRoll) {
            characters.gainXp(char, getXpGainForFight(char, wep, target));
            payPlayer(characters.ownerOf(char), getTokenGainForFight(target));
        }
        characters.drainStamina(char, 20);
        emit FightOutcome(char, wep, target, playerRoll, monsterRoll);
    }

    function getMonsterPower(uint32 target) public pure returns (uint24) {
        return uint24(target & 0xFFFFFF);
    }

    function getTokenGainForFight(uint32 target) internal view returns (uint256) {
        uint24 monsterPower = getMonsterPower(target);
        return getCost(monsterPower);
    }

    function getXpGainForFight(uint256 char, uint256 wep, uint32 target) internal view returns (uint16) {
        int128 basePowerDifference = getMonsterPower(target).divu(getPlayerPower(char, wep));
        // base XP gain is 16 for an equal fight
        return uint16((basePowerDifference * 16).toUInt());
    }

    function getPlayerPowerRoll(uint256 char, uint256 wep, uint8 monsterTrait) internal returns(uint24) {
        // roll for fights, non deterministic
        uint256 playerPower = getPlayerFinalPower(char, wep);
        playerPower = plusMinus10Percent(playerPower);
        uint8 playerTrait = characters.getTrait(char);

        int128 traitBonus = uint256(1).fromUInt();
        int128 oneBonus = uint256(75).divu(1000);
        if(playerTrait == weapons.getTrait(wep)) {
            traitBonus = traitBonus.add(oneBonus);
        }
        if(isTraitEffectiveAgainst(playerTrait, monsterTrait)) {
            traitBonus = traitBonus.add(oneBonus);
        }
        else if(isTraitWeakAgainst(playerTrait, monsterTrait)) {
            traitBonus = traitBonus.sub(oneBonus);
        }
        return uint24(playerPower.fromUInt().mul(traitBonus).toUInt());
    }

    function getMonsterPowerRoll(uint24 monsterPower) internal returns(uint24) {
        // roll for fights, non deterministic
        return uint24(plusMinus10Percent(monsterPower));
    }

    function getPlayerPower(uint256 char, uint256 wep) public view returns (uint24) {
        // does not account for trait matches
        return uint24((characters.getPower(char).fromUInt().mul(weapons.getPowerMultiplier(wep))).toUInt());
    }

    function getPlayerFinalPower(uint256 char, uint256 wep) internal view returns (uint24) {
        // accounts for trait matches
        return uint24((characters.getPower(char).fromUInt().mul(weapons.getPowerMultiplierForTrait(wep, characters.getTrait(char)))).toUInt());
    }

    function getTargets(uint256 char, uint256 wep) public view returns (uint32[4] memory) {
        // 4 targets, roll powers based on character + weapon power
        // trait bonuses not accounted for
        // targets expire on the hour
        uint24 playerPower = getPlayerPower(char, wep);

        uint[] memory seedArray = new uint[](5);
        seedArray[0] = char;
        seedArray[1] = playerPower;
        seedArray[2] = characters.getXp(char);
        seedArray[3] = characters.getStaminaTimestamp(char);
        seedArray[4] = getCurrentHour();
        uint256 baseSeed = combineSeeds(seedArray);

        uint32[4] memory targets;
        for(uint i = 0; i < targets.length; i++) {
            // we alter seed per-index or they would be all the same
            uint256 indexSeed = randomSeeded(combineSeeds(baseSeed, i));
            uint24 monsterPower = uint24(plusMinus10PercentSeeded(playerPower, indexSeed));
            uint256 monsterTrait = randomSeededMinMax(0,3, indexSeed);
            targets[i] = monsterPower | (uint32(monsterTrait) << 24);
        }

        return targets;
    }

    function isTraitEffectiveAgainst(uint8 attacker, uint8 defender) public pure returns (bool) {
        if(attacker == 0 && defender == 1) {
            return true;
        }
        if(attacker == 1 && defender == 2) {
            return true;
        }
        if(attacker == 2 && defender == 3) {
            return true;
        }
        if(attacker == 3 && defender == 0) {
            return true;
        }
        return false;
    }

    function isTraitWeakAgainst(uint8 attacker, uint8 defender) public pure returns (bool) {
        if(attacker == 1 && defender == 0) {
            return true;
        }
        if(attacker == 2 && defender == 1) {
            return true;
        }
        if(attacker == 3 && defender == 2) {
            return true;
        }
        if(attacker == 0 && defender == 3) {
            return true;
        }
        return false;
    }

    function mintCharacter() public requestPayFromPlayer(mintCharacterFee) returns (uint256) {
        require(characters.balanceOf(msg.sender) <= 1000, "You can only have 1000 characters!");
        payContract(msg.sender, mintCharacterFee);
        uint256 tokenID = characters.mint(msg.sender);
        if(weapons.balanceOf(msg.sender) == 0)
            weapons.mint(msg.sender, 0); // first weapon free with a character mint, max 1 star
        return tokenID;
    }

    function mintWeapon() public requestPayFromPlayer(mintWeaponFee) returns (uint256) {
        ERC20(skillTokens).approve(address(this), getCost(mintWeaponFee));
        payContract(msg.sender, mintWeaponFee);
        uint256 tokenID = weapons.mint(msg.sender, 4); // max 5 star
        return tokenID;
    }

    function fillStamina(uint256 character) public isCharacterOwner(character) requestPayFromPlayer(refillStaminaFee) {
        payContract(msg.sender, refillStaminaFee);
        characters.setStaminaTimestamp(character, characters.getStaminaTimestamp(character) - characters.getStaminaMaxWait());
    }

    function reforgeWeapon(uint256 reforgeID, uint256 burnID) public
            isWeaponOwner(reforgeID) isWeaponOwner(burnID) requestPayFromPlayer(reforgeWeaponFee) {
        require(weapons.getLevel(reforgeID) < 127, "Weapons cannot be improved beyond level 128!");
        payContract(msg.sender, reforgeWeaponFee);
        weapons.levelUp(reforgeID);
        weapons.transferFrom(weapons.ownerOf(burnID), address(0x0), burnID);
    }

    modifier isWeaponOwner(uint256 weapon) {
        require(weapons.ownerOf(weapon) == msg.sender, "Not the weapon owner");
        _;
    }

    modifier isCharacterOwner(uint256 character) {
        require(characters.ownerOf(character) == msg.sender, "Not the character owner");
        _;
    }

    modifier isTargetValid(uint256 character, uint256 weapon, uint32 target) {
        bool foundMatch = false;
        uint32[4] memory targets = getTargets(character, weapon);
        for(uint i = 0; i < targets.length; i++) {
            if(targets[i] == target) {
                foundMatch = true;
            }
        }
        require(foundMatch, "Target invalid");
        _;
    }

    modifier requestPayFromPlayer(uint256 baseAmount) {
        uint256 convertedAmount = getCost(baseAmount);
        require(ERC20(skillTokens).balanceOf(msg.sender) >= convertedAmount,
            string(abi.encodePacked("Not enough SKILL! Need ",convertedAmount)));
        ERC20(skillTokens).approve(address(this), convertedAmount);
        _;
    }

    function payContract(address playerAddress, uint256 baseAmount) internal {
        uint256 convertedAmount = getCost(baseAmount);
        // must use requestPayFromPlayer modifier to approve on the initial function!
        ERC20(skillTokens).transferFrom(playerAddress, address(this), convertedAmount);
    }

    function payPlayer(address playerAddress, uint256 baseAmount) internal {
        uint256 convertedAmount = getCost(baseAmount);
        ERC20(skillTokens).approve(address(this), convertedAmount);
        ERC20(skillTokens).transferFrom(address(this), playerAddress, convertedAmount);
    }

    function getContractSkillBalance() public view returns (uint256) {
        return ERC20(skillTokens).balanceOf(address(this));
    }

    function getCost(uint256 originalPrice) public view returns (uint256) {
        return getContractSkillBalance().divu(ERC20(skillTokens).totalSupply()).mul(originalPrice.fromUInt()).toUInt();
    }

    function getApprovedBalance() external view returns (uint256) {
        return ERC20(skillTokens).allowance(msg.sender, address(this));
    }

    function getCurrentHour() public view returns (uint256) {
        // "now" returns unix time since 1970 Jan 1, in seconds
        return now / (1 hours);
    }

}