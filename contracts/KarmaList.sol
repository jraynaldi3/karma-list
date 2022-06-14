//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


contract KarmaList is Ownable{

    event MemberAdded(address memberAddress, string name);
    event Punished(address punished, address punisher);
    event Redempted(address memberAddress);
    
    uint punishCount;
    uint costOfRedemption;
    enum Karma {
        Bad,
        Good
    }
    
    struct Member {
        address memberAddress;
        string name;
        Karma karma;
    }

    Member[] members;
    mapping(address => uint) punishment;
    mapping(address => address[]) punishedBy;


    function addMember(address _memberAddress, string memory _name) external onlyOwner{
        members.push(Member({
            memberAddress: _memberAddress,
            name: _name,
            karma: Karma.Good
        }));

        emit MemberAdded(_memberAddress, _name);
    }

    function isMember(address _memberAddress) internal view returns(bool){
        for(uint i = 0; i < members.length; i++){
            if (members[i].memberAddress == _memberAddress) return true;
        }
        return false;
    }

    function isGoodKarma(address _memberAddress) internal view returns(bool){
        for(uint i = 0; i < members.length; i++){
            if (members[i].memberAddress == _memberAddress){
                if (members[i].karma == Karma.Good) return true;
                break;
            }
        }
        return false;
    }

    function isAlreadyPunish(address _memberAddress, address _punisher) internal view returns(bool){
        address[] memory punisher = punishedBy[_memberAddress];
        for(uint i = 0; i < punisher.length; i ++){
            if(punisher[i]==_punisher){
                return true;
            }
        }
        return false;
    }

    function goodMemberCount() internal view returns(uint count){
        for(uint i = 0; i < members.length; i++ ){
            if(members[i].karma == Karma.Good){
                count++;
            }
        }
    }

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

    function punish(address _memberAddress) external{
        require(isMember(msg.sender),"Not a member");
        require(isGoodKarma(msg.sender),"You don't have a good karma");
        require(!isAlreadyPunish(_memberAddress, msg.sender),"Already punished");
        punishment[_memberAddress] ++;
        if (punishment[_memberAddress] > members.length/2){
            Member storage member = getMemberByAddress(_memberAddress);
            member.karma = Karma.Bad;
            punishment[_memberAddress] = 0;
        }
        punishedBy[_memberAddress].push(msg.sender);
        emit Punished(_memberAddress,msg.sender);
    }

    function redemption() external payable{
        require(isMember(msg.sender),"Not a member");
        require(!isGoodKarma(msg.sender),"Already have a good karma");
        require(msg.value >= costOfRedemption,"Not enought for redemption");
        Member storage member = getMemberByAddress(msg.sender);
        member.karma = Karma.Good;
        delete punishedBy[msg.sender];
        emit Redempted(msg.sender);
    }

    function setCostOfRedemption(uint cost) external onlyOwner{
        costOfRedemption = cost;
    }

    function setPunishCount(uint percentage) external onlyOwner{
        require(percentage<1 && percentage>0,"Invalid Input");
        punishCount = goodMemberCount() * percentage;
    }


}