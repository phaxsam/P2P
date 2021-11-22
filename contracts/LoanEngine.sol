// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol"; 
import "./SafeMath.sol";

contract p2pLoan is Ownable, IERC20  {
using SafeMath for uint256;
IERC20 public token;
bool public deprecated;
uint256 public activeLoans = 0;
 //Loan private loan = lend;

enum Status { initial, lent, paid, destroyed }
           Status status;
           Status constant defaultStatus = Status.initial;


constructor(IERC20 _a2z) public {
    owner = msg.sender;
    token = _a2z;
    loan.length++;
}

struct Loan {
Status status;
address token; 
address  lender;
address  borrower;
uint256 amount;
uint256 dueTime;
uint256 duesIn;
uint256 interest;
uint256 interestRate;
uint256 punitoryInterest;
uint256 interestTimestamp;
uint256 paid;
uint256 interestRatePunitory;
uint256 expirationRequest;
uint256 cancelableAt;
}
Loan[] private loans;


function calculateInterest(uint256 timeDelta, uint256 interestRate,uint256 amount) internal pure returns (uint256 realDelta, uint256 interest){
if (amount == 0) {
    interest = 0;
    realDelta = timeDelta;
} else {
    interest = mul(mul(1000, amount), timeDelta) / interestRate;
    realDelta = mul(interest, interestRate) / (amount * 1000); 
}
}

function internalAddInterest(Loan storage lend, uint256 timestamp ) internal{
    if(timestamp > loan.interestTimestamp){
        uint256 newInterest = loan.interest;
        uint256 newPunitoryInterest = loan.punitoryInterest;

        uint256 newTimestamp;
        uint256 realDelta;
        uint256 calculatedInterest;
        
        uint256 deltatime;
        uint256 pending;
        
        uint256 endNonPunitory = minimum(timestamp, loan.dueTime);
        if(endNonPunitory > loan.interestTimestamp) {
            deltatime = endNonPunitory - loan.interestTimestamp;

            if(loan.paid < loan.amount) {
                pending = loan.amount - loan.paid;
            } else {
                pending = 0;
            }
            (realDelta, calculatedInterest) = calculateInterest(deltatime, loan.interestRate, pending);
            newInterest = add(calculatedInterest, newInterest);
            newTimestamp = loan.interestTimestamp + realDelta;
        }

        if (timestamp > loan.dueTime) {
            uint256 startPunitory = maximum(loan.dueTime, loan.interestTimestamp);
            deltatime = timestamp - startPunitory;

            uint256 debt = add(loan.amount,newInterest);
            pending = minimum(debt, sub(add(debt, newPunitoryInterest), loan.paid));

            (realDelta, calculatedInterest) = calculateInterest(deltatime, loan.interestRatePunitory, pending);
            newPunitoryInterest = add(newPunitoryInterest, calculatedInterest);
            newTimestamp = startPunitory + realDelta;
        }

        if( newInterest != loan.interest || newPunitoryInterest != loan.punitoryInterest) {
            loan.interestTimestamp = newTimestamp;
            loan.interest = newInterest;
            loan.punitoryInterest = newPunitoryInterest;

        }
    }
}

function addInterest(uint256 index) public returns (bool) {
    Loan storage lend = loan[index];
    require(loan.status == Status.lent);
    internalAddInterest(loan, block.timestamp);
}

 function payLoan(uint256 index, uint256 _amount, address _from) public returns(bool) {
     Loan storage lend = loan[index];

     require(loan.Status == status.lent);
     addInterest(index);
     uint256 toPay = minimum(getPendingAmount(index), _amount);
     emit PartialPayment(index, msg.sender, _from, toPay);

     loan.paid = add(loan.paid, toPay);

     if(getRawPendingAmount(index)==0) {
         emit TotalPayment(index);
         loan.status = Status.paid;

         lendersBalance[loan.lender] -= 1;
         activeLoans -= 1;
     }

 }

 function getPendingAmount(uint256 index) public returns(uint256){
     addInterest(index);
     return getRawPendingAmount(index);
 }
 
 function getRawPendingAmount(uint256 index) public view returns(uint256){
     Loan storage lend = loan[index];
     return sub(add(add(loan.amount, loan.interest),loan.punitoryInterest), loan.paid);
 }


   function destroy(uint index) public returns (bool) {
        Loan storage loan = loans[index];
        require(loan.status != Status.destroyed);
        require(msg.sender == loan.lender || (msg.sender == loan.borrower && loan.status == Status.initial));
        emit DestroyedBy(index, msg.sender);

        // ERC721, remove loan from circulation
        if (loan.status != Status.initial) {
            lendersBalance[loan.lender] -= 1;
            activeLoans -= 1;
            emit Transfer(loan.lender, address(0), index);
        }

        loan.status = Status.destroyed;
        return true;
    }

    /**
        @notice Destroys a loan using the signature and not the Index
        @param identifier Identifier of the loan
        @return true if the destroy was done successfully
    */
    function destroyIdentifier(bytes32 identifier) public returns (bool) {
        uint256 index = identifierToIndex[identifier];
        require(index != 0);
        return destroy(index);
    }
}

