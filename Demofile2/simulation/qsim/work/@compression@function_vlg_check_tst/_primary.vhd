library verilog;
use verilog.vl_types.all;
entity CompressionFunction_vlg_check_tst is
    port(
        digest          : in     vl_logic_vector(255 downto 0);
        sampler_rx      : in     vl_logic
    );
end CompressionFunction_vlg_check_tst;
