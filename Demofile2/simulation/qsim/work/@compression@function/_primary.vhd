library verilog;
use verilog.vl_types.all;
entity CompressionFunction is
    port(
        clock           : in     vl_logic;
        lastBlock       : in     vl_logic;
        digest          : out    vl_logic_vector(255 downto 0)
    );
end CompressionFunction;
