library verilog;
use verilog.vl_types.all;
entity CompressionFunction_vlg_check_tst is
    port(
        addrout         : in     vl_logic_vector(3 downto 0);
        compressdone    : in     vl_logic;
        digest          : in     vl_logic_vector(255 downto 0);
        outmem          : in     vl_logic_vector(31 downto 0);
        sched           : in     vl_logic_vector(31 downto 0);
        sched1          : in     vl_logic_vector(31 downto 0);
        sched32         : in     vl_logic_vector(31 downto 0);
        sched63         : in     vl_logic_vector(31 downto 0);
        sampler_rx      : in     vl_logic
    );
end CompressionFunction_vlg_check_tst;
