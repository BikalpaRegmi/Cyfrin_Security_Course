methods{
    function mathmastersSqrt(uint256) external returns uint256 envfree ;
    function uniSqrt(uint256) external returns uint256 envfree ;
    function mathMasterFirstHalf(uint256) external returns uint256 envfree ;
    function solMateFirstHalf(uint256) external returns uint256 envfree ;
}

rule solmateTopHalfMatchesMathMastersTopHalf(uint256 x)  {
    assert(mathMasterFirstHalf(x) == solMateFirstHalf(x)) ;
}

