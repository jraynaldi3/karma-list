//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
/**
* @author Julius Raynaldi
* karma list inspired by ethhole.com/challenge
* KarmaList is smart contract about karma, member with good karma may punish each other
* member with bad karma can redemp their bad karma by paying to smartcontract
* smartcontract may be a trasury or bad karma redemption cost can splited to other good karma member
* Expansion posibility:
    - for DAO that can ban someone with bad reputation
    - for Defi game can ban someone too
 */

contract KarmaList is Ownable{

    event MemberAdded(address memberAddress, string name); 
    event Punished(address punished, address punisher);
    event Redempted(address memberAddress);
    
    uint punishCount; //Count that must be fullfilled that people need to have bad karma
    uint costOfRedemption; //cost that bad karma member pay to redempt their karma
    
    //there is 2 kind of karma good and bad
    enum Karma {
        Bad,
        Good
    }
    
    //member of community can be replaced with NFT or ERC20 token holder instead
    struct Member {
        address memberAddress;
        string name;
        Karma karma;
    }

    Member[] members;

    mapping(address => uint) punishment; //count of punishmen that address have
    mapping(address => address[]) punishedBy; //address that punished an address

    /**
    * @dev to add member to community
     */
    function addMember(address _memberAddress, string memory _name) external onlyOwner{
        members.push(Member({
            memberAddress: _memberAddress,
            name: _name,
            karma: Karma.Good
        }));

        emit MemberAdded(_memberAddress, _name);
    }

    /**
    * @dev to check if an address is member or not
     */
    function isMember(address _memberAddress) internal view returns(bool){
        for(uint i = 0; i < members.length; i++){
            if (members[i].memberAddress == _memberAddress) return true;
        }
        return false;
    }

    /**
    * @dev to check if member have good karma or not
     */
    function isGoodKarma(address _memberAddress) internal view returns(bool){
        for(uint i = 0; i < members.length; i++){
            if (members[i].memberAddress == _memberAddress){
                if (members[i].karma == Karma.Good) return true;
                break;
            }
        }
        return false;
    }

    /**
    * @dev to check if member already punished that address or not
    * @param _memberAddress address of member that punished
    * @param _punisher addres of member that punish
     */
    function isAlreadyPunish(address _memberAddress, address _punisher) internal view returns(bool){
        address[] memory punisher = punishedBy[_memberAddress];
        for(uint i = 0; i < punisher.length; i ++){
            if(punisher[i]==_punisher){
                return true;
            }
        }
        return false;
    }

    /**
    * @dev count the good karma member 
    */
    function goodMemberCount() internal view returns(uint count){
        for(uint i = 0; i < members.length; i++ ){
            if(members[i].karma == Karma.Good){
                count++;
            }
        }
    }

    /**
    * @dev to find that member data
     */
    function getMemberByAddress(address _memberAddress) internal view returns(Member storage) {
        Member storage member;
        uint index;
        for(uint i = 0; i < members.length; i++){
            if (members[i].memberAddress == _memberAddress){
                index = i;
                break;
            }
        }
        member =  members[index];
        return member;
    }

    /**
    * @dev punish a member 
    * @param _memberAddress member that want to be punished
    * require:
        - both punisher and punished address should be a member
        - punisher should be have good karma
        - punisher should be never punish that punished member before
    * emit a {Punished} event 
     */
    function punish(address _memberAddress) external{
        require(isMember(msg.sender) && isMember(_memberAddress),"Not a member");
        require(isGoodKarma(msg.sender),"You don't have a good karma");
        require(!isAlreadyPunish(_memberAddress, msg.sender),"Already punished");
        punishment[_memberAddress] ++;
        if (punishment[_memberAddress] > punishCount){
            Member storage member = getMemberByAddress(_memberAddress);
            member.karma = Karma.Bad;
            punishment[_memberAddress] = 0;
        }
        punishedBy[_memberAddress].push(msg.sender);
        emit Punished(_memberAddress,msg.sender);
    }

    /**
    * @dev redemp the punished member
    * require:
        - punished should be a member
        - punished should have a bad karma
        - punished should pay costOfRedemption
    * emit {Redempted} event
     */
    function redemption() external payable{
        require(isMember(msg.sender),"Not a member");
        require(!isGoodKarma(msg.sender),"Already have a good karma");
        require(msg.value >= costOfRedemption,"Not enought for redemption");
        Member storage member = getMemberByAddress(msg.sender);
        member.karma = Karma.Good;
        delete punishedBy[msg.sender];
        emit Redempted(msg.sender);
    }

    /**
    * @dev owner can set costOfRedemption
    */
    function setCostOfRedemption(uint cost) external onlyOwner{
        costOfRedemption = cost;
    }

    /**
    * @dev owner can set punishCount
    */
    function setPunishCount(uint percentage) external onlyOwner{
        require(percentage<1 && percentage>0,"Invalid Input");
        punishCount = goodMemberCount() * percentage;
    }


}