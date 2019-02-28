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
		kval 			: out std_logic_vector(6 downto 0);
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
--Digest Signals
  signal Hdigest : std_logic_vector( 255 downto 0 ):= H0&H1&H2&H3&H4&H5&H6&H7;
  signal a : std_logic_vector( 31 downto 0 ):=H0; 
  signal b : std_logic_vector( 31 downto 0 ):=H1;
  signal c : std_logic_vector( 31 downto 0 ):=H2;
  signal d : std_logic_vector( 31 downto 0 ):=H3;
  signal e : std_logic_vector( 31 downto 0 ):=H4;
  signal f : std_logic_vector( 31 downto 0 ):=H5;
  signal g : std_logic_vector( 31 downto 0 ):=H6;
  signal h : std_logic_vector( 31 downto 0 ):=H7;
  
  --Compression Function Signals
  signal T1, T2, Sigma0, Sigma1, maj, ch : std_logic_vector( 31 downto 0 );
  signal compressed : std_logic := '0';
  signal lastB : boolean;
  signal j			 : std_logic_vector(6 downto 0):="0000000";
  signal memaddr 	: std_logic_vector(3 downto 0):= "0000";
  signal memout 	: std_logic_vector(31 downto 0);
  signal flag 	: std_logic:='0';
  
  --Message Scheduler Signals
  signal schedule : padded_message_block_array;
  signal k		  : std_logic_vector(6 downto 0) := "0000000";
  signal gateval1 : std_logic_vector(6 downto 0) := "1000000";
  signal gateval2 : std_logic_vector(6 downto 0) := "0010000";
  
  --FSM Signals
		type states is(
--	Idle,
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
	begin
	if(clock'Event and clock='1')then
		case current_state is
		
		--	when Idle =>
		--		k<="0000000";
		--		j<="0000000";
		--		current_state<=Idle;
		
			when Ready =>
				readyBlock <= '1';
				if (blockSet='1') then
					current_state<=ScheduleMessage;
				else
					current_state<=Ready;
				end if;
			
			when ScheduleMessage =>
					readyBlock <= '0';					
					if k < gateval2 then					-- If k < 16 then the message scheduler is the padded input message
						outmem <=memout;
						addrout <= memaddr;
						schedule(to_integer(unsigned(k))) <= memout;
						k <= std_logic_vector(unsigned(k) + 1);
						memaddr <= std_logic_vector(unsigned(memaddr) + 1);
					elsif(k < gateval1) then									-- Else, W_k = s1(W[k]-2) + W[k]-7 + s0(W[k]-15) + W[k]-16
						schedule(to_integer(unsigned(k))) <= std_logic_vector(unsigned(s1(schedule(to_integer(unsigned(k)) - 2))) + unsigned(schedule(to_integer(unsigned(k)) - 7)) + unsigned(s0(schedule(to_integer(unsigned(k)) - 15))) + unsigned(schedule(to_integer(unsigned(k)) - 16)));
						k <= std_logic_vector(unsigned(k) + 1);
					else
						current_state<=CompressBlock;
					end if;
				
				when CompressBlock =>
					readyBlock <= '0';
			
							 if j < gateval1 then
									sigma1   <= Z1(e);
									ch 	  <= (e and f) xor (not(e) and g);
									T1 <= std_logic_vector(unsigned(h)+ unsigned(schedule(to_integer(unsigned(j)))) + unsigned(sigma1) + unsigned(ch) + unsigned(constants(to_integer(unsigned(j)))));
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
									j <= std_logic_vector(unsigned(j) + 1);
							 else
									compressed <= '1';
							 end if;
							 
						  if (compressed = '1') then
									 Hdigest( 255 downto 224 ) <= std_logic_vector( unsigned ( Hdigest( 255 downto 224 ) ) + unsigned( a ) );
									 Hdigest( 223 downto 192 ) <= std_logic_vector( unsigned (  Hdigest( 223 downto 192 ) ) + unsigned( b ) );
									 Hdigest( 191 downto 160 ) <= std_logic_vector( unsigned ( Hdigest( 191 downto 160 ) ) + unsigned( c ) );
									 Hdigest( 159 downto 128 ) <= std_logic_vector( unsigned ( Hdigest( 159 downto 128 ) ) + unsigned( d ) ); 
									 Hdigest( 127 downto 96 ) <= std_logic_vector( unsigned( Hdigest( 127 downto 96 ) ) + unsigned( e ) );
									 Hdigest( 95 downto 64 ) <= std_logic_vector( unsigned( Hdigest( 95 downto 64 ) ) + unsigned( f ) );
									 Hdigest( 63 downto 32 ) <= std_logic_vector( unsigned( Hdigest( 63 downto 32 ) ) + unsigned( g ) );
									 Hdigest( 31 downto 0 ) <= std_logic_vector( unsigned( Hdigest( 31 downto 0 ) ) + unsigned( h ) );
						  end if; 
						  
						  if (lastBlock = '1') then
								current_state<=Append;
						  else
								current_state<=Ready;
						  end if;
								
				when Append =>
					readyBlock <= '0';
					
					digest( 31 downto 0 ) <= Hdigest( 31 downto 0 );
					digest( 63 downto 32 ) <= Hdigest( 63 downto 32 );
					digest( 95 downto 64 ) <= Hdigest( 95 downto 64 );
					digest( 127 downto 96 ) <= Hdigest( 127 downto 96 );
					digest( 159 downto 128 ) <= Hdigest( 159 downto 128 );
					digest( 191 downto 160 ) <= Hdigest( 191 downto 160 );
					digest( 223 downto 192 ) <= Hdigest( 223 downto 192 );
					digest( 255 downto 224 ) <= Hdigest( 255 downto 224 );
					
					current_state<=Ready;
									
						
	end case;
end if;

	sched <= a ;--schedule(0);
	sched1 <= b; --schedule(1);
	sched32 <= schedule(32);
	sched63 <= schedule(63);
	compressdone <= compressed;
	temp1 <= T1;
	kval <= k;

end process;

end architecture behaviour;