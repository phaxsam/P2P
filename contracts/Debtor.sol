pragma solidity 0.8.9;

import "./LoanEngine.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";



contract debtorProfile is LoanEngine, Ownable, IERC20 {
   
    function LoanRequest(
        address _borrower,
        address _token,
        uint256 _amount,
        uint256 _interestRate,
        uint256 _interestRatePunitory,
        uint256 _duesIn,
        uint256 _cancelableAt,
        uint256 _expirationRequest
    ) public returns (uint256) {
        require(msg.sender == _borrower);
        require(!deprecated);
        require(_cancelableAt <= _duesIn);
        require(_amount != 0);
        require(_interestRatePunitory != 0);
        require(_interestRate != 0);
        require(_expirationRequest > block.timestamp);

           Loan memory loan = Loan(
            Status.initial,
            _borrower,
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
   
      uint256 index = loans.push(loan) - 1;
        emit CreatedLoan(index, _borrower);

        bytes32 identifier = getIdentifier(index);
        require(identifierToIndex[identifier] == 0);
        identifierToIndex[identifier] = index;
      
        return index;
     
    function getIdentifier(uint256 index) public view returns (bytes32) {
        signature memory sign = loans[index];
        return buildIdentifier(
            loan.oracle, loan.borrower,  loan.token, loan.amount, loan.interestRate,
            loan.interestRatePunitory, loan.duesIn, loan.cancelableAt, loan.expirationRequest 
        );
    }
      
        
        function buildIdentifier(
         address borrower, address token, uint256 amount, uint256 interestRate,
         uint256 interestRatePunitory, uint256 duesIn, uint256 cancelableAt, uint256 expirationRequest
         ) public view returns (bytes32) {
            return keccak256(
            abi.encodePacked(
                this,
                borrower,
                token,
                amount,
                interestRate,
                interestRatePunitory,
                duesIn,
                cancelableAt,
                expirationRequest
            )
        );
     }

        function approveLoan(uint index) public returns(bool) {
         Loan storage loan = loans[index];
         require(loan.status == Status.initial);
        //loan.approbations[msg.sender] = true;
         emit ApprovedBy(index, msg.sender);
         return true;
     }


     function isApproved(uint index) public view returns (bool) {
        Loan storage loan = loans[index];
        return loan.approbations[loan.borrower];
     }

     
}