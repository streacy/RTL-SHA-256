library verilog;
use verilog.vl_types.all;
entity MessageScheduler_vlg_sample_tst is
    port(
        clk             : in     vl_logic;
        M               : in     vl_logic_vector(511 downto 0);
        sampler_tx      : out    vl_logic
    );
end MessageScheduler_vlg_sample_tst;
