 pragma solidity 0.8.9;

import "./LoanEngine.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
 
 contract Pawnshop  is LoanEngine{
      

       function ConfigureNew (
        address _lender,
        address _token,
        uint256 _amount,
        uint256 _interestRate,
        uint256 _interestRatePunitory,
        uint256 _duesIn,
        uint256 _cancelableAt,
        uint256 _expirationRequest
    )
        public returns(uint256)
    {
        require(msg.sender == _lender);
        require(!deprecated);
        require(_cancelableAt <= _duesIn);
        require(_amount != 0);
        require(_interestRatePunitory != 0);
        require(_interestRate != 0);
        require(_expirationRequest > block.timestamp);

         Loan memory loan = Loan(
            Status.initial,
            _lender,
            address(0),
            _token,
            0x0, // chainlink oracle
            _amount,
            0,
            0,
            0,
            0,
            _interestRate,
            _interestRatePunitory,
            0,
            _duesIn,
            _cancelableAt,
            0,
            _expirationRequest
        );
    }

    function lend(uint index) public returns (bool) {
        Loan storage loan = loans[index];

        require(loan.status == Status.initial);
        require(isApproved(index));
        require(block.timestamp <= loan.expirationRequest);

        loan.lender = msg.sender;
        loan.dueTime = add(block.timestamp, loan.duesIn);
        loan.interestTimestamp = block.timestamp;
        loan.status = Status.lent;

        // ERC721, create new loan and transfer it to the lender
        emit Transfer(loan.lender, index);
        activeLoans += 1;
        lendersBalance[loan.lender] += 1;

        if (loan.cancelableAt > 0)
            internalAddInterest(loan, add(block.timestamp, loan.cancelableAt));

        // Transfer the money to the borrower before handling the cosigner
        // so the cosigner could require a specific usage for that money.
        require(a2z.transferFrom(msg.sender, loan.borrower, uint index))
        
        emit Lent(index, loan.lender);

        return true;
    }

 }