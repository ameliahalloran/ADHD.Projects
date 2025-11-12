library ads;
use ads.ads_fixed.all;
use ads.ads_complex_pkg.all;

package julia_constants is
    -- Collection of interesting Julia set c values
    
    -- dendrite (looks like lightning)
    constant julia_c_0: ads_complex := ads_cmplx(
        to_ads_sfixed(-0.7),
        to_ads_sfixed(0.27)
    );
    
    -- San Marco fractal
    constant julia_c_1: ads_complex := ads_cmplx(
        to_ads_sfixed(-0.75),
        to_ads_sfixed(0.1)
    );
    
    -- Douady's rabbit
    constant julia_c_2: ads_complex := ads_cmplx(
        to_ads_sfixed(-0.123),
        to_ads_sfixed(0.745)
    );
    
    -- Siegel disk
    constant julia_c_3: ads_complex := ads_cmplx(
        to_ads_sfixed(-0.391),
        to_ads_sfixed(-0.587)
    );
    
    -- Function to select Julia constant based on switches
    function get_julia_c(sel: natural range 0 to 3) return ads_complex;
    
end package julia_constants;

package body julia_constants is
    
    function get_julia_c(sel: natural range 0 to 3) return ads_complex is
    begin
        case sel is
            when 0 => return julia_c_0;
            when 1 => return julia_c_1;
            when 2 => return julia_c_2;
            when 3 => return julia_c_3;
        end case;
    end function get_julia_c;
    
end package body julia_constants;