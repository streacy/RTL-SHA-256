library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sha256_datatypes.all;
use work.sha256_constants.all;
use work.sha256_msfunctions.all;

entity CompressionFunction is
port(
      clock 		: in std_logic;
		lastBlock   : in std_logic;
		blockSet 	: in std_logic;
		compressdone : out std_logic;
		readyBlock   :out std_logic;
      digest 		: out std_logic_vector( 255 downto 0);
		sched 		: out std_logic_vector(31 downto 0);
		sched1 		: out std_logic_vector(31 downto 0);
		sched32 		: out std_logic_vector(31 downto 0);
		sched63 		: out std_logic_vector(31 downto 0);
		outmem		: out std_logic_vector(31 downto 0);
		temp1		: out std_logic_vector(31 downto 0);
		addrout 		: out std_logic_vector(3 downto 0)
    );
end entity;

architecture behaviour of CompressionFunction is
  signal Hdigest : std_logic_vector( 255 downto 0 );
  signal a : std_logic_vector( 31 downto 0 ):=H0; 
  signal b : std_logic_vector( 31 downto 0 ):=H1;
  signal c : std_logic_vector( 31 downto 0 ):=H2;
  signal d : std_logic_vector( 31 downto 0 ):=H3;
  signal e : std_logic_vector( 31 downto 0 ):=H4;
  signal f : std_logic_vector( 31 downto 0 ):=H5;
  signal g : std_logic_vector( 31 downto 0 ):=H6;
  signal h : std_logic_vector( 31 downto 0 ):=H7;
  signal T1, T2, Sigma0, Sigma1, maj, ch : std_logic_vector( 31 downto 0 );
  signal compressed : std_logic := '0';
  signal lastB : boolean;
  signal j			 : integer range 0 to 63;
  signal memaddr 	: std_logic_vector(3 downto 0):= "0000";
  signal memout 	: std_logic_vector(31 downto 0);
  signal flag 	: std_logic:='0';
  signal schedule : padded_message_block_array;
  signal k		  : integer range 0 to 63;
  
  --FSM Signals
		type states is(
	Ready,
	ScheduleMessage,
	CompressBlock,
	Append
);
	signal current_state : states:=Ready;
	
	COMPONENT PaddedMessageRegFile IS
	PORT
	(clk : in  STD_LOGIC;
    wen : in  STD_LOGIC;
    addr : in  STD_LOGIC_VECTOR (3 downto 0);
    dataIn : in  STD_LOGIC_VECTOR (31 downto 0);
    dataOut : out  STD_LOGIC_VECTOR (31 downto 0)
	);
	END COMPONENT;


	
begin

	paddedmessage : PaddedMessageRegFile
	PORT MAP(
			clk => clock ,
			wen => '0',
			addr => memaddr,
			dataIn	=> x"00000000",
			dataOut	=> memout
	);


	
process(clock,lastBlock, blockSet)
		variable k : integer:=0;
		variable j : integer:=0; 

	begin
	if(clock'Event and clock='1')then
		case current_state is
		
			when Ready =>
				readyBlock <= '1';
				if (blockSet='1') then
					current_state<=ScheduleMessage;
				else
					current_state<=Ready;
				end if;
			
			when ScheduleMessage =>
					readyBlock <= '0';
			
					
					if k < 16 then					-- If k < 16 then the message scheduler is the padded input message
						outmem <=memout;
						addrout <= memaddr;
						schedule(k) <= memout;
						k := k + 1;
						memaddr <= std_logic_vector(unsigned(memaddr) + 1);
					elsif(k < 64) then									-- Else, W_k = s1(W[k]-2) + W[k]-7 + s0(W[k]-15) + W[k]-16
							schedule(k) <= std_logic_vector(unsigned(s1(schedule(k - 2))) + unsigned(schedule(k - 7)) + unsigned(s0(schedule(k - 15))) + unsigned(schedule(k - 16)));
							k := k + 1;
					else
					current_state<=CompressBlock;
					end if;
				
				when CompressBlock =>
					readyBlock <= '0';
			
							 if j < 64 then
									sigma1   <= Z1(e);
									ch 	  <= std_logic_vector((e and f) xor (not(e) and g));
									T1 <= std_logic_vector(unsigned(h)+ unsigned(schedule(j)) + unsigned(sigma1) + unsigned(ch) + unsigned(constants(j)));
									sigma0   <= Z0(a);
									maj 	  <= std_logic_vector((a and b) xor (a and c) xor (b and c));
									T2 <= std_logic_vector(unsigned(maj) + unsigned(sigma0));
									
									h <= g;
									g <= f;
									f <= e;
									e <= std_logic_vector( unsigned( d ) + unsigned( T1 ) );
									d <= c;
									c <= b;
									b <= a;
									a <= std_logic_vector( unsigned( T1 ) + unsigned( T2 ) );
									j := j + 1;
							 else
									compressed <= '1';
							 end if;
							 
						  if (compressed = '1') then
									 Hdigest( 31 downto 0 ) <= std_logic_vector( unsigned ( Hdigest( 31 downto 0 ) ) + unsigned( a ) );
									 Hdigest( 63 downto 32 ) <= std_logic_vector( unsigned (  Hdigest( 63 downto 32 ) ) + unsigned( b ) );
									 Hdigest( 95 downto 64 ) <= std_logic_vector( unsigned ( Hdigest( 95 downto 64 ) ) + unsigned( c ) );
									 Hdigest( 127 downto 96 ) <= std_logic_vector( unsigned ( Hdigest( 127 downto 96 ) ) + unsigned( d ) ); 
									 Hdigest( 159 downto 128 ) <= std_logic_vector( unsigned( Hdigest( 159 downto 128 ) ) + unsigned( e ) );
									 Hdigest( 191 downto 160 ) <= std_logic_vector( unsigned( Hdigest( 191 downto 160 ) ) + unsigned( f ) );
									 Hdigest( 223 downto 192 ) <= std_logic_vector( unsigned( Hdigest( 223 downto 192 ) ) + unsigned( g ) );
									 Hdigest( 255 downto 224 ) <= std_logic_vector( unsigned( Hdigest( 255 downto 224 ) ) + unsigned( h ) );
						  end if; 
						  
						  if (lastBlock = '1') then
								current_state<=Append;
						  else
								current_state<=Ready;
						  end if;
								
				when Append =>
					readyBlock <= '0';
					
					digest( 31 downto 0 ) <= Hdigest( 255 downto 224 );
					digest( 63 downto 32 ) <= Hdigest( 223 downto 192 );
					digest( 95 downto 64 ) <= Hdigest( 191 downto 160 );
					digest( 127 downto 96 ) <= Hdigest( 159 downto 128 );
					digest( 159 downto 128 ) <= Hdigest( 159 downto 128 );
					digest( 191 downto 160 ) <= Hdigest( 255 downto 224 );
					digest( 223 downto 192 ) <= Hdigest( 63 downto 32 );
					digest( 255 downto 224 ) <= Hdigest( 31 downto 0 );
					
					current_state<=Ready;
									
						
	end case;
end if;

	sched <= schedule(0);
	sched1 <= schedule(1);
	sched32 <= schedule(32);
	sched63 <= schedule(63);
	compressdone <= compressed;
	temp1 <= T1;

end process;

end architecture behaviour;