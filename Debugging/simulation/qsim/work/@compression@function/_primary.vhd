library verilog;
use verilog.vl_types.all;
entity CompressionFunction is
    port(
        clock           : in     vl_logic;
        lastBlock       : in     vl_logic;
        compressdone    : out    vl_logic;
        digest          : out    vl_logic_vector(255 downto 0);
        sched           : out    vl_logic_vector(31 downto 0);
        sched1          : out    vl_logic_vector(31 downto 0);
        sched32         : out    vl_logic_vector(31 downto 0);
        sched63         : out    vl_logic_vector(31 downto 0);
        outmem          : out    vl_logic_vector(31 downto 0);
        addrout         : out    vl_logic_vector(3 downto 0)
    );
end CompressionFunction;
