---- this file is part of the ADS library

library ads;
use ads.ads_fixed.all;

package ads_complex_pkg is
	-- complex number in rectangular form
	type ads_complex is
	record
		re: ads_sfixed;
		im: ads_sfixed;
	end record ads_complex;

	---- functions

	-- make a complex number
	function ads_cmplx (
			re, im: in ads_sfixed
		) return ads_complex;

	-- returns l + r
	function "+" (
			l, r: in ads_complex
		) return ads_complex;

	-- returns l - r
	function "-" (
			l, r: in ads_complex
		) return ads_complex;

	-- returns l * r
	function "*" (
			l, r: in ads_complex
		) return ads_complex;

	-- returns the complex conjugate of arg
	function conj (
			arg: in ads_complex
		) return ads_complex;

	-- returns || arg || ** 2
	function abs2 (
			arg: in ads_complex
		) return ads_sfixed;

	-- returns arg * arg (saturating)
    function ads_square (
            arg: in ads_complex
        ) return ads_complex;

	-- constants
	constant complex_zero: ads_complex :=
					ads_cmplx(to_ads_sfixed(0), to_ads_sfixed(0));

end package ads_complex_pkg;

package body ads_complex_pkg is

	-- create complex number from two fixed-point values
    function ads_cmplx (
            re, im: in ads_sfixed
        ) return ads_complex
    is
        variable ret: ads_complex;
    begin
        ret.re := re;
        ret.im := im;
        return ret;
    end function ads_cmplx;

    -- Addition is (a + bi) + (c + di) = (a+c) + (b+d)i
    function "+" (
            l, r: in ads_complex
        ) return ads_complex
    is
        variable ret: ads_complex;
    begin
        ret.re := l.re + r.re;
        ret.im := l.im + r.im;
        return ret;
    end function "+";

    -- Subtraction is (a + bi) - (c + di) = (a-c) + (b-d)i
    function "-" (
            l, r: in ads_complex
        ) return ads_complex
    is
        variable ret: ads_complex;
    begin
        ret.re := l.re - r.re;
        ret.im := l.im - r.im;
        return ret;
    end function "-";

    -- Multiplication is (a + bi) * (c + di) = (ac - bd) + (ad + bc)i
    function "*" (
            l, r: in ads_complex
        ) return ads_complex
    is
        variable ret: ads_complex;
        variable ac, bd, ad, bc: ads_sfixed;
    begin
        -- Calculate all the products
        ac := l.re * r.re;  -- a*c
        bd := l.im * r.im;  -- b*d
        ad := l.re * r.im;  -- a*d
        bc := l.im * r.re;  -- b*c
        
        -- Real part: ac - bd
        ret.re := ac - bd;
        
        -- Imaginary part: ad + bc
        ret.im := ad + bc;
        
        return ret;
    end function "*";

    -- Complex conjugate: conj(a + bi) = a - bi
    function conj (
            arg: in ads_complex
        ) return ads_complex
    is
        variable ret: ads_complex;
    begin
        ret.re := arg.re;
        ret.im := -arg.im;  -- Negate imaginary part
        return ret;
    end function conj;

    -- Magnitude squared: |a + bi|^2 = a^2 + b^2
    function abs2 (
            arg: in ads_complex
        ) return ads_sfixed
    is
        variable re_squared: ads_sfixed;
        variable im_squared: ads_sfixed;
    begin
        re_squared := arg.re * arg.re;
        im_squared := arg.im * arg.im;
        return re_squared + im_squared;
    end function abs2;

    -- Square: (a + bi)^2 = a^2 - b^2 + 2abi
    -- More efficient than using multiplication operator
    function ads_square (
            arg: in ads_complex
        ) return ads_complex
    is
        variable ret: ads_complex;
        variable re_sq, im_sq, two_re_im: ads_sfixed;
    begin
        re_sq := arg.re * arg.re;      -- a^2
        im_sq := arg.im * arg.im;      -- b^2
        two_re_im := arg.re * arg.im;  -- ab
        two_re_im := two_re_im + two_re_im;  -- 2ab
        
        -- Real part: a^2 - b^2
        ret.re := re_sq - im_sq;
        
        -- Imaginary part: 2ab
        ret.im := two_re_im;
        
        return ret;
    end function ads_square;

end package body ads_complex_pkg;
